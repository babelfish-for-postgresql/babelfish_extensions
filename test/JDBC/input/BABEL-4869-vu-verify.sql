-- Basic Case: No parameters
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1'
GO

-- Single Parameter Case: WHERE clause with a single parameter
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 WHERE Column1 = @Param1'
GO

-- Multiple Parameters Case: WHERE clause with multiple parameters
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 WHERE Column1 = @Param1 AND Column2 = @Param2'
GO

-- Nested Queries Case: Subquery in WHERE clause
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 WHERE Column1 IN (SELECT Column3 FROM babel_4869_vu_prepare_t2 WHERE Column2 = @Param)'
GO

-- Join Conditions Case: JOIN with a parameter in the condition
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 JOIN babel_4869_vu_prepare_t2 ON babel_4869_vu_prepare_t1.Column2 = babel_4869_vu_prepare_t2.Column2 WHERE babel_4869_vu_prepare_t1.Column1 = @Param'
GO

-- Error Handling Case: Syntax error
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 WHERE Column1 = @Param AND'
GO

-- Boundary Case: No rows returned
EXEC sp_describe_undeclared_parameters 'SELECT * FROM babel_4869_vu_prepare_t1 WHERE 1 = 0'
GO

-- Update Query with Parameters
DECLARE @P0 INT = 100;
DECLARE @P1 VARCHAR(50) = 'NewValue';
EXEC sp_describe_undeclared_parameters 'UPDATE babel_4869_vu_prepare_t1 SET Column1 = @P1 WHERE Column2 = @P0'
GO

-- Delete Query with Parameters
DECLARE @P0 INT = 100;
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column2 = @P0'
GO

-- Error Handling Case: Syntax error in the query
DECLARE @P0 VARCHAR(64);
SET @P0 = N'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column1 = @Param AND';
EXEC sp_describe_undeclared_parameters @P0;
GO

-- Empty Parameters Case: No parameters declared
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1';
GO

-- Integer Parameter Case: Parameter declared as INT
DECLARE @P0 INT;
EXEC sp_describe_undeclared_parameters @P0;
GO

DECLARE @P0 FLOAT;
EXEC sp_describe_undeclared_parameters @P0;
GO

DECLARE @P0 VARCHAR(11);
EXEC sp_describe_undeclared_parameters @P0;
GO

DECLARE @P0 NVARCHAR(11);
EXEC sp_describe_undeclared_parameters @P0;
GO

DECLARE @P0 CHAR(11);
EXEC sp_describe_undeclared_parameters @P0;
GO

-- Update Query with Mixed Data Types
DECLARE @Param1 INT = 100;
DECLARE @Param2 VARCHAR(50) = 'NewValue';
EXEC sp_describe_undeclared_parameters 'UPDATE babel_4869_vu_prepare_t1 SET Column1 = @Param2 WHERE Column2 = @Param1'
GO

-- Delete Query with Invalid Input
DECLARE @P0 INT;
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column1 = @P0 AND Column2 = ''InvalidString'''
GO

-- Invalid Syntax Case: Missing WHERE clause
DECLARE @P0 INT = 100;
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1'
GO

-- Empty Parameters Case: No parameters declared
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1'
GO

-- Numeric and String Parameters
DECLARE @P0 INT = 100;
DECLARE @P1 VARCHAR(50) = 'StringValue';
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column1 = @P1 AND Column2 = @P0'
GO

-- Date Parameter
DECLARE @P0 DATE = '2022-05-15';
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column1 = @P0'
GO

-- Invalid Data Type Case: Using FLOAT parameter in WHERE clause
DECLARE @P0 FLOAT = 10.5;
EXEC sp_describe_undeclared_parameters 'DELETE FROM babel_4869_vu_prepare_t1 WHERE Column1 = @P0'
GO

-- Should return 0 rows
DECLARE @P0 VARCHAR(64) 
SET @P0 = N'DELETE FROM babel_4869_vu_prepare_t1' 
exec sys.sp_describe_undeclared_parameters @P0 
GO

DECLARE @P0 VARCHAR(64)
SET @P0 = N'DELETE FROM babel_4869_vu_prepare_t1 WHERE id < 2 and id > 3'
exec sys.sp_describe_undeclared_parameters @P0
GO

EXEC sp_describe_undeclared_parameters @tsql = N'update babel_4869_vu_prepare_t3 set bitValue=0 where tenantId = 1 and stringValue = ''initial'''; 
GO

EXEC sp_describe_undeclared_parameters @tsql = N'SELECT bitValue FROM babel_4869_vu_prepare_t3 where tenantId = 1 and stringValue = ''initial'''; 
GO
