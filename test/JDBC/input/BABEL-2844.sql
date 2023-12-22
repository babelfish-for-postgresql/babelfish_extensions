-- parallel_query_expected
use master;
go

select current_setting('babelfishpg_tsql.explain_costs');
go

-- CREATE TABLE should not be executed
set BABELFISH_SHOWPLAN_ALL oN;
go
create table babel_2844_t1 (a1 int, b1 int);
go
select * from babel_2844_t1 where b1 = 1;
go

-- SELECT should not be executed
select * from set_config('babelfishpg_tsql.explain_costs', 'off', false);
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select current_setting('babelfishpg_tsql.explain_costs');
go

-- Create tables
create table babel_2844_t1 (a1 int, b1 int);
go
insert babel_2844_t1 values (1, 1);
go
create table babel_2844_t2 (a2 int, b2 int);
go

-- INSERT should not be executed
set BABELFISH_SHOWPLAN_ALL ON;
go
insert babel_2844_t1 values (2, 2);
go
insert into babel_2844_t2 select * from babel_2844_t1 where a1 = 1;
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select * from babel_2844_t1;
go
select * from babel_2844_t2;
go

-- single statement
set BABELFISH_SHOWPLAN_ALL ON;
go
select 1;
go
select * from babel_2844_t1 where b1 = 1;
go

-- Other formats
set BABELFISH_SHOWPLAN_ALL OFF;
go
select set_config('babelfishpg_tsql.explain_format', 'xml', false);
go
set BABELFISH_SHOWPLAN_ALL ON;
go
select * from babel_2844_t1 where b1 = 1;
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select set_config('babelfishpg_tsql.explain_format', 'json', false);
go
set BABELFISH_SHOWPLAN_ALL ON;
go
select * from babel_2844_t1 where b1 = 1;
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select set_config('babelfishpg_tsql.explain_format', 'yaml', false);
go
set BABELFISH_SHOWPLAN_ALL ON;
select * from babel_2844_t1 where b1 = 1;
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select set_config('babelfishpg_tsql.explain_format', 'text', false);
go

-- multiple statements
set BABELFISH_SHOWPLAN_ALL ON;
insert babel_2844_t1 values (2, 2);
insert into babel_2844_t2 select * from babel_2844_t1 where a1 in (1, 2);
select * from babel_2844_t1;
select * from babel_2844_t2;
go

set BABELFISH_SHOWPLAN_ALL OFF;
go
select * from babel_2844_t1;
go
select * from babel_2844_t2;
go

-- pltsql procedure
create procedure babel_2844_proc @param int
as
    insert babel_2844_t1 values (3, 3);
    select * from babel_2844_t1 where a1 = @param;
go
set BABELFISH_SHOWPLAN_ALL ON;
go
execute babel_2844_proc 3;
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
select * from babel_2844_t1;
go
drop procedure babel_2844_proc;
go

-- C procedure
set BABELFISH_SHOWPLAN_ALL ON;
go
declare @handle int;
EXEC SP_PREPARE @handle OUT, NULL, 'select * from babel_2844_t1';
go
set BABELFISH_SHOWPLAN_ALL OFF;
go

-- ITVF (Inline Table-Valued Function)
create function babel_2844_itvf(@param int)
returns table
    as return (
        select * from babel_2844_t1 where a1 = @param
    );
go
set BABELFISH_SHOWPLAN_ALL ON;
go
select * from babel_2844_itvf(1);
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
drop function babel_2844_itvf;
go

-- MSTVF (Multi-Statement Table-Valued Function)
create function babel_2844_mstvf(@param int)
returns @tab table (a int, b int)
as begin
    insert into @tab select * from babel_2844_t1 where a1 = @param;
    insert into @tab select * from babel_2844_t2 where a2 = @param;
    return;
end;
go
set BABELFISH_SHOWPLAN_ALL ON;
go
select * from babel_2844_mstvf(1);
go
set BABELFISH_SHOWPLAN_ALL OFF;
go
drop function babel_2844_mstvf;
go

-- Control structure
set BABELFISH_SHOWPLAN_ALL ON;
go
if (select a1 from babel_2844_t1 where b1 = 1) = 1
    select 1
else
    select 2
;
go

-- sp_executesql
EXECUTE sp_executesql N'select * from babel_2844_t1 where a1 = @param', N'@param int',
        @param = 2;
go

-- Temp tables
create table #babel_2844_tt1 (a int, b int);
select * from #babel_2844_tt1 where a = 1;
go

-- SET EXPLAIN ANALYZE
set BABELFISH_STATISTICS PROFILE ON;
go

set BABELFISH_SHOWPLAN_ALL OfF;
go

-- Should not return a query plan
select * from babel_2844_t1;
go

drop table babel_2844_t1;
go
drop table babel_2844_t2;
go

-- BABEL-3677: SELECT INTO
CREATE TABLE t1 (a INT PRIMARY KEY, b INT);
GO

SET BABELFISH_SHOWPLAN_ALL ON;
GO

-- should not crash
SELECT * INTO t3 FROM t1 WHERE t1.b = 1;
GO

-- should fail with t3 does not exist because previous query was not executed
INSERT INTO t3 VALUES (1, 1), (2, 1), (3, 1);
GO

-- DMLs should also not be executed
INSERT INTO t1 VALUES (1, 1), (2, 1), (3, 1);
GO

DELETE FROM t1 WHERE a = 3;
GO

UPDATE t1 SET a = 2 WHERE a = 1;
GO

-- also create function just for the sake of testing it
CREATE FUNCTION [dbo].[WOSQL_BuildRevenueDetailOLUQuery]  ()
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @TSQL NVARCHAR(MAX)
    RETURN @TSQL
END
GO

-- function should not be created but should not crash
SELECT dbo.WOSQL_BuildRevenueDetailOLUQuery()
GO

SET BABELFISH_SHOWPLAN_ALL OFF;
GO

-- should be empty
SELECT * FROM t1;
GO

DROP TABLE t1;
GO