DROP FUNCTION IF EXISTS net
GO
CREATE FUNCTION net(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END
GO

DROP DATABASE IF EXISTS db1
GO
CREATE DATABASE db1
GO
USE db1
GO

DROP TABLE IF EXISTS t1
GO
CREATE TABLE t1(a INT)
GO

DROP PROCEDURE IF EXISTS select_all
GO
CREATE PROCEDURE select_all
AS
SELECT * FROM t1
GO

DROP PROCEDURE IF EXISTS select_all_with_parameter
GO
CREATE PROCEDURE select_all_with_parameter @id int
AS
BEGIN
SELECT * FROM t1 WHERE a = @id
END
GO

DROP PROCEDURE IF EXISTS Mixed_Parameters_Select_All
GO
CREATE PROCEDURE Mixed_Parameters_Select_All @MyId int, @MyVarChar varchar(256)
AS
BEGIN
SELECT * FROM t1 WHERE a = @id
END
GO

CREATE SCHEMA s1
GO

DROP FUNCTION IF EXISTS s1.positive_or_negative
GO

CREATE FUNCTION s1.positive_or_negative (
@long DECIMAL(9,6)
)
RETURNS CHAR(4) AS
BEGIN
DECLARE @return_value CHAR(10);
SET @return_value = 'zero';
    IF (@long > 0.00) SET @return_value = 'positive';
    IF (@long < 0.00) SET @return_value = 'negative';

    RETURN @return_value
END;
GO

DROP FUNCTION IF EXISTS net
GO
CREATE FUNCTION net(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END
GO

DROP FUNCTION IF EXISTS no_param_name
GO
CREATE FUNCTION no_param_name(
    @ INT
)
RETURNS INT
AS 
BEGIN
    RETURN @
END
GO

DROP FUNCTION IF EXISTS table_value_func
GO
CREATE FUNCTION table_value_func (
    @num INT
)
RETURNS TABLE
AS 
RETURN
SELECT a as b FROM t1 WHERE a > @num
GO

CREATE TYPE eyedees FROM int not NULL
go
CREATE TYPE Phone_Num FROM varchar(11) NOT NULL
go

CREATE PROCEDURE eyedees_proc @id eyedees
AS
SELECT  1
GO

CREATE PROCEDURE Phone_num_proc @num Phone_num
AS
SELECT  1
GO

CREATE FUNCTION eyedees_func (
    @id eyedees
)
RETURNS eyedees AS
BEGIN
return @id
END
GO

CREATE FUNCTION PhoneNum_func (
    @Pn Phone_Num
)
RETURNS Phone_Num AS
BEGIN
return @Pn
END
GO

-- error: provided name of database we are not currently in
EXEC sp_sproc_columns @procedure_qualifier = 'master'
GO

EXEC sp_sproc_columns @procedure_name = 'select_all'
GO

-- pattern matching is default to be ON
EXEC sp_sproc_columns @procedure_name = 'select_%'
GO

-- pattern matching set to OFF
EXEC sp_sproc_columns @procedure_name = 'select_%', @fUsePattern = '0'
GO

EXEC sp_sproc_columns @procedure_name = 'positive_or_negative', @procedure_owner = 's1', @column_name = '@long'
GO

-- unnamed invocation
EXEC sp_sproc_columns 'select_all_with_parameter', 'dbo', 'db1'
GO

-- case-insensitive invocation
EXEC SP_SPROC_COLUMNS @PROCEDURE_NAME = 'positive_or_negative', @PROCEDURE_OWNER = 's1', @PROCEDURE_QUALIFIER = 'db1'
GO

-- delimiter invocation
exec [sys].[sp_sproc_columns] 'select_all_with_parameter'
GO

exec [sp_sproc_columns] 'select_all_with_parameter'
GO

-- case-insensitive invocation
EXEC SP_SPROC_COLUMNS 'SELECT_ALL_WITH_PARAMETER', 'DBO', 'DB1'
GO

-- mixed-parameters procedure
exec sp_sproc_columns 'mixed_parameters_select_all', 'dbo', 'db1'
GO

exec sp_sproc_columns 'MIXED_PARAMETERS_SELECT_ALL', 'dbo', 'db1'
GO

exec sp_sproc_columns 'mixed_parameters_select_all', 'dbo', 'db1', '@myid'
GO

exec sp_sproc_columns 'mixed_parameters_select_all', 'dbo', 'db1', '@MYID'
GO

exec sp_sproc_columns 'mixed_parameters_select_all', 'dbo', 'db1', '@myvarchar'
GO

exec sp_sproc_columns 'mixed_parameters_select_all', 'dbo', 'db1', '@MYVARCHAR'
GO

-- no parameter name procedure
exec sp_sproc_columns 'no_param_name'
GO

-- table-value function 
exec sp_sproc_columns 'table_value_func'
GO

-- only get procedure existing within current database context
EXEC sp_sproc_columns @procedure_name = 'net'
GO

-- Test with user-defined datatypes
EXEC sp_sproc_columns @procedure_name = 'eyedees_proc'
GO
EXEC sp_sproc_columns @procedure_name = 'eyedees_func'
GO
EXEC sp_sproc_columns @procedure_name = 'PhoneNum_func'
GO
EXEC sp_sproc_columns @procedure_name = 'Phone_num_proc'
GO

DROP FUNCTION table_value_func
GO
DROP FUNCTION no_param_name
GO
DROP FUNCTION net
GO
DROP FUNCTION PhoneNum_func
GO
DROP FUNCTION eyedees_func
GO
DROP FUNCTION s1.positive_or_negative
GO
DROP PROCEDURE select_all
GO
DROP PROCEDURE select_all_with_parameter
GO
DROP PROCEDURE Mixed_Parameters_Select_All
GO
DROP PROCEDURE eyedees_proc
GO
DROP PROCEDURE Phone_num_proc
GO
DROP TYPE eyedees
GO
DROP TYPE Phone_Num
GO
DROP TABLE t1
GO
DROP SCHEMA s1
GO
USE master
GO
DROP FUNCTION net
GO
DROP DATABASE db1
GO