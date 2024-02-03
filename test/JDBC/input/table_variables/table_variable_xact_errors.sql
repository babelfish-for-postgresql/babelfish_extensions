-- Test how Table Variables behave during implicit rollback due to error

SELECT transaction_isolation_level from sys.dm_exec_sessions WHERE session_id = @@SPID
GO

-------------------------------------------------------------------------------
-- Test 1: Table Variables inside TRY-CATCH block with error
-------------------------------------------------------------------------------
BEGIN TRY
    DECLARE @tv TABLE(c1 INT PRIMARY KEY, c2 INT)
    INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
    SELECT 1 / 0    -- error
END TRY
BEGIN CATCH
    BEGIN TRANSACTION
        SELECT * FROM @tv                  -- 3 records
        DELETE FROM @tv
    ROLLBACK
END CATCH;

-- Table and index should still be accessible here
INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
UPDATE @tv SET c1 = 1 WHERE c1 = 3 -- duplicate key
SELECT * FROM @tv                  -- 3 records
GO

-------------------------------------------------------------------------------
-- Test 2: Procedure with Table Variables and THROW
--         Test with PROC + Table Variable and error while relation is open
-------------------------------------------------------------------------------
CREATE PROC table_variable_throw_proc1 AS
BEGIN
    DECLARE @tv TABLE (a INT PRIMARY KEY, b CHAR(8))
    INSERT INTO @tv VALUES (1, 'First');
    SELECT * FROM @tv;
    THROW 51000, 'Throw error', 1;
    INSERT INTO @tv VALUES (2, 'Second');
END
GO

EXEC table_variable_throw_proc1
GO

SELECT * FROM @tv
GO

DROP PROCEDURE table_variable_throw_proc1
GO

CREATE PROCEDURE tv_function_1
AS
BEGIN TRY
    DECLARE @tv TABLE(c1 INT PRIMARY KEY, c2 INT)
    INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
    INSERT INTO @tv VALUES(3, 30) -- duplicate key, fail while table and index are open
END TRY
BEGIN CATCH
    INSERT INTO @tv VALUES(3, 30) -- duplicate key, fail while table and index are open
    SELECT * FROM @tv
END CATCH;
GO

EXEC tv_function_1
GO

DROP PROCEDURE tv_function_1
GO

-------------------------------------------------------------------------------
-- Test 3: ROLLBACK due to RAISE
-------------------------------------------------------------------------------
CREATE PROCEDURE table_variable_throw_proc1
AS
BEGIN TRY
    DECLARE @tv TABLE (a INT PRIMARY KEY, b CHAR(8))
    INSERT INTO @tv VALUES (1, 'First');
    RAISERROR ('raiserror 16', 16, 1);
END TRY
BEGIN CATCH
    SELECT 'CATCH in Procedure 1';
    INSERT INTO @tv VALUES (2, 'Second');
    SELECT * FROM @tv; -- return 2 rows
    THROW;
END CATCH
GO

EXEC table_variable_throw_proc1
GO

DROP PROCEDURE table_variable_throw_proc1
GO

-------------------------------------------------------------------------------
-- Test 4: Batch termination
-------------------------------------------------------------------------------
CREATE TYPE empDates AS TABLE (start_date DATE, end_date DATE);
GO

DECLARE @empJobHist empDates;
INSERT INTO @empJobHist VALUES ('1973-01-01', '1973-11-01');
INSERT INTO @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988', '1988-06-30');
INSERT INTO @empJobHist VALUES ('1993-01-01', '1993-11-01'); -- should not get here
SELECT * FROM @empJobHist
GO

DECLARE @empJobHist empDates;
insert into @empJobHist VALUES ('1983-01-01', '1988-11-01'), ('1982-11-29', '1988-06-30');
SELECT * FROM @empJobHist
GO

DROP TYPE empDates
GO

-------------------------------------------------------------------------------
-- BABEL-4225: Error inside function should not cause crash
-------------------------------------------------------------------------------
CREATE SCHEMA [Control]
GO

CREATE FUNCTION [Control].[csf_script_delete_row] (
   @SetIDLocal  INT,
   @InternalID  VARCHAR(64)
) RETURNS VARCHAR(MAX)
AS
BEGIN
   DECLARE @Template          VARCHAR(MAX);
   DECLARE @Results           VARCHAR(MAX);
   DECLARE @DeletePredicates  VARCHAR(MAX);
   DECLARE @Ordinal           INT;   -- NOTE: In this circumstance, each column is either an update or a predicate but not both.
   DECLARE @Columns
   TABLE   ( Ordinal          INT IDENTITY(1, 1) NOT NULL,
             ColumnPredicate  VARCHAR(MAX)           NULL,
             PRIMARY KEY ( Ordinal )
           );
   SET @Template = 'DELETE [SchemaName].[TableName] WHERE DeleteConditionPredicates;';
   INSERT INTO @Columns (ColumnPredicate )
   SELECT '[' + LRV.ColumnName + '] ' + ISNULL(('= ' + NULLIF(LRV.Expression, 'NULL')), 'IS NULL')
   FROM   [Control].[DataRow] AS RLR
          INNER JOIN [Control].[DataRowValue] AS LRV
          ON (RLR.SetID      = LRV.SetID         AND
              RLR.InternalID = LRV.InternalIDRow    )
          INNER JOIN [Control].[cvw_local_column_base] AS STC
          ON (RLR.SchemaName = STC.SchemaName AND
              RLR.TableName  = STC.TableName  AND
              LRV.ColumnName = STC.ColumnName    )
   WHERE  RLR.SetID      =  @SetIDLocal
   AND    RLR.InternalID =  @InternalID
   AND    LRV.MatchType  != 'N'
   ORDER BY STC.ColumnID ASC;END; -- [Control].[csf_script_delete_row]
go

SELECT Control.csf_script_delete_row('1', ' ')
GO

DROP FUNCTION [Control].[csf_script_delete_row]
GO

DROP SCHEMA [Control]
GO

-------------------------------------------------------------------------------
-- BABEL-4226: Error while table and index are open.
-------------------------------------------------------------------------------

CREATE FUNCTION dbo.foo() RETURNS @tab TABLE (a INT, b VARCHAR(MAX) NOT NULL) AS
BEGIN
        INSERT @tab(a, b) VALUES (1, NULL)
        RETURN
END
GO

SELECT * FROM dbo.foo()
GO

DROP FUNCTION dbo.foo()
GO

CREATE FUNCTION dbo.foo() RETURNS @tab TABLE (a INT PRIMARY KEY, b VARCHAR(MAX) NOT NULL) AS
BEGIN
        INSERT @tab(a, b) VALUES (1, NULL)
        RETURN
END
GO

SELECT * FROM dbo.foo()
GO

DROP FUNCTION dbo.foo()
GO

CREATE FUNCTION [dbo].[tv_function_1]() RETURNS @tab TABLE(a int, b int PRIMARY KEY) AS
BEGIN
    DECLARE @tv TABLE(c1 INT PRIMARY KEY, c2 INT)
    INSERT INTO @tv VALUES(1, 10), (2, 20), (3, 30)
    INSERT INTO @tab(a, b) SELECT c1, c2 FROM @tv
    INSERT INTO @tab VALUES(4, 30) -- duplicate key, fail while table and index are open
    INSERT INTO @tab VALUES(1, 2)
    RETURN
END
GO

SELECT * FROM [dbo].[tv_function_1]()
GO

DROP FUNCTION [dbo].[tv_function_1]
GO

-------------------------------------------------------------------------------
-- BABEL-4227: Error should not cause crash
-------------------------------------------------------------------------------
CREATE FUNCTION LevenschteinDifference
(
@FirstString nVarchar(255), @SecondString nVarchar(255)
)
RETURNS int
as begin
Declare @PseudoMatrix table
     (location int identity primary key,
      firstorder int not null,
      Firstch nchar(1),
      secondorder int not null,
      Secondch nchar(1),
      Thevalue int not null default 0,
      PreviousRowValues varchar(200)
      )

insert into @PseudoMatrix (firstorder, firstch, secondorder, secondch, TheValue )
SELECT TheFirst.number,TheFirst.ch, TheSecond.number,TheSecond.ch,0
  FROM
   (SELECT number, SUBSTRING(@FirstString,number,1) AS ch
    FROM numbers WHERE number <= LEN(@FirstString) union all Select 0,Char(0)) TheFirst
  cross JOIN
   (SELECT number, SUBSTRING(@SecondString,number,1) AS ch
    FROM numbers WHERE number <= LEN(@SecondString) union all Select 0,Char(0)) TheSecond

order by TheFirst.number, TheSecond.number

Declare @current Varchar(255)
Declare @previous Varchar(255)
Declare @TheValue int
Declare @Deletion int, @Insertion int, @Substitution int, @minim int
Select @current='', @previous=''
Update @PseudoMatrix
    Set
    @Deletion=@TheValue+1,
    @Insertion=ascii(substring(@previous,secondorder+1,1))+1,
    @Substitution=ascii(substring(@previous,(secondorder),1)) +1,
    @minim=case when @Deletion<@Insertion then @Deletion else @insertion end,
    @TheValue = Thevalue = case
 when SecondOrder=0 then FirstOrder
 When FirstOrder=0 then Secondorder
     when FirstCh=SecondCh then ascii(substring(@previous,(secondorder),1))
     else case when @Minim<@Substitution then @Minim else @Substitution end
   end,
    @Previous=PreviousRowValues=case when secondorder =0 then @current else @Previous end,
    @current= case when secondorder =0 then char(@TheValue) else @Current+char(@TheValue) end
return @TheValue
End
go

SELECT dbo.LevenschteinDifference(NULL, NULL)
GO

SELECT dbo.LevenschteinDifference(' ', ' ')
GO

DROP FUNCTION dbo.LevenschteinDifference
GO

-------------------------------------------------------------------------------
-- Other errors with sp_executesql
-------------------------------------------------------------------------------

CREATE procedure temp_table_sp_exec AS
BEGIN
    DECLARE @SQLString NVARCHAR(500);
    SET @SQLString = N'declare @table_t1 table(a int); INSERT INTO @table_t1 values(1);SELECT * FROM @table_t1';
    EXECUTE sp_executesql @SQLString;

    SET @SQLString = N'declare @table_t1 table(a int NOT NULL); INSERT INTO @table_t1 values(NULL);SELECT * FROM @table_t1';
    EXECUTE sp_executesql @SQLString;
END;
GO

EXEC temp_table_sp_exec
GO

DROP PROCEDURE temp_table_sp_exec
GO

-------------------------------------------------------------------------------
-- Drop type used by table variable
-------------------------------------------------------------------------------

CREATE TYPE typa FROM int
GO

CREATE TYPE typb FROM nvarchar(100)
GO

DECLARE @tv_3 TABLE(a typa, b typb)
DROP TYPE typb

INSERT INTO @tv_3 VALUES(1, 'Hello')
SELECT * FROM @tv_3
GO

DROP TYPE typa
GO

DROP TYPE typb
GO

-------------------------------------------------------------------------------
-- Cursor not explicitly closed
-------------------------------------------------------------------------------

DECLARE @STATION_INTS_TABLE TABLE (STATION_INT INT)
DECLARE @v INT

DECLARE CUR_NETWORK CURSOR LOCAL FOR SELECT STATION_INT FROM @STATION_INTS_TABLE
OPEN CUR_NETWORK
FETCH NEXT  FROM CUR_NETWORK INTO @v
GO

select 123
GO

CREATE FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]  ()
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @TSQL NVARCHAR(MAX)
    DECLARE @STATION_INTS_TABLE TABLE (STATION_INT INT)
    DECLARE @STATION_INT INT     SET @TSQL = ''
    DECLARE CUR_NETWORK CURSOR LOCAL FOR
        SELECT STATION_INT FROM @STATION_INTS_TABLE    OPEN CUR_NETWORK
    FETCH NEXT FROM CUR_NETWORK INTO @STATION_INT

    RETURN @TSQL
END
GO

SELECT dbo.WOSQL_BuildRevenueDetailOLUQuery()
GO

SELECT dbo.WOSQL_BuildRevenueDetailOLUQuery()
GO

DROP FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]
GO

CREATE FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]  ()
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @TSQL NVARCHAR(MAX)
    DECLARE @STATION_INTS_TABLE TABLE (STATION_INT INT)
    DECLARE @STATION_INT INT     SET @TSQL = ''
    DECLARE CUR_NETWORK CURSOR LOCAL FOR
        SELECT STATION_INT FROM @STATION_INTS_TABLE    OPEN CUR_NETWORK
    FETCH NEXT FROM CUR_NETWORK INTO @STATION_INT

    THROW 51000, 'Throw error', 1;

    RETURN @TSQL
END
GO

SELECT dbo.WOSQL_BuildRevenueDetailOLUQuery()
GO

DROP FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]
GO

CREATE FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]  ()
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @TSQL NVARCHAR(MAX)
    DECLARE @STATION_INTS_TABLE TABLE (STATION_INT INT PRIMARY KEY, C2 INT)
    DECLARE @STATION_INT INT     SET @TSQL = ''

    INSERT INTO @STATION_INTS_TABLE VALUES(1, 1)

    DECLARE CUR_NETWORK CURSOR LOCAL FOR
        SELECT STATION_INT FROM @STATION_INTS_TABLE

    OPEN CUR_NETWORK
    FETCH NEXT FROM CUR_NETWORK INTO @STATION_INT

    INSERT INTO @STATION_INTS_TABLE VALUES(1, 1) -- duplicate key
    RETURN @TSQL
END
GO

SELECT dbo.WOSQL_BuildRevenueDetailOLUQuery()
GO

DROP FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]
GO

-------------------------------------------------------------------------------
-- BABEL-4267: Error should not cause crash
-------------------------------------------------------------------------------

CREATE PROCEDURE usp_PopulateDiscount
AS
    DECLARE @Lookup TABLE (StartDate DATETIME NOT NULL)
    INSERT INTO @Lookup SELECT GETDATE()
    BEGIN TRANSACTION
    DELETE trgt FROM Discount trgt           -- Discount does not exist
    COMMIT
go

EXECUTE usp_PopulateDiscount
go

CREATE PROCEDURE test
AS
BEGIN TRY
    DECLARE @tv1 TABLE(c1 INT PRIMARY KEY, b INT IDENTITY, c CHAR(15) DEFAULT 'Whoops!')
    SELECT 1/0
END TRY
BEGIN CATCH
    BEGIN TRANSACTION
    INSERT INTO @tv1 VALUES(1, 3, 'Three')          -- invalid syntax, should do a clean shutdown
    COMMIT
END CATCH;
GO

exec test
go

DROP PROCEDURE usp_PopulateDiscount
GO

DROP PROCEDURE test
GO

-------------------------------------------------------------------------------
-- BABEL-4737: Error during subtxn should not cause crash
-------------------------------------------------------------------------------
DROP TABLE IF EXISTS mytab
GO

CREATE TABLE mytab(a VARCHAR(30) NULL) 
GO

CREATE PROC myproc
AS
BEGIN
    DECLARE @tv TABLE(a int)

    BEGIN TRANSACTION
    SAVE TRANSACTION savept1

    UPDATE mytab
    SET a = 'x'
    OUTPUT i.Item INTO @tv
    FROM
    (SELECT 'b' AS Item) AS i

     COMMIT
END
go

CREATE PROC myproc2
AS
BEGIN
	BEGIN TRANSACTION
	SAVE TRANSACTION savept0
		EXEC myproc
	COMMIT
END
GO

EXECUTE myproc
GO

EXECUTE myproc
GO

EXECUTE myproc2
GO

EXECUTE myproc2
GO

DROP PROCEDURE myproc
GO

DROP PROCEDURE myproc2
GO

