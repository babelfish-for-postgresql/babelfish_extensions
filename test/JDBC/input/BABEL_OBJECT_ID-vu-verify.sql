-- test table, procedure, function, views
SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_t1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_proc1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_func1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_v1'))
GO

-- We can also specify object_type as parameter
SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_t1', 'U'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_proc1', 'P'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_func1', 'FN'))
GO

SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_v1', 'V'))
GO


-- traling spaces
SELECT OBJECT_NAME(OBJECT_ID('babel_object_id_t1    '))
GO

-- Case insensitive
SELECT OBJECT_NAME(OBJECT_ID('Babel_Object_ID_t1'))
GO

-- leading spaces should fail
SELECT (CASE WHEN OBJECT_NAME(OBJECT_ID('   babel_object_id_t1')) = 'babel_object_id_t1' THEN 'true' ELSE 'false' END) result;
GO

-- testing different scenarios of 3-part name 
SELECT OBJECT_NAME(OBJECT_ID('dbo.babel_object_id_t1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('..babel_object_id_t1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('master.dbo.babel_object_id_t1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('[master]."dbo".[babel_object_id_t1]'))
GO

SELECT OBJECT_NAME(OBJECT_ID('"master".[dbo]."babel_object_id_t1"'))
GO

SELECT OBJECT_NAME(OBJECT_ID('master..babel_object_id_t1'))
GO

-- schema and object name containing spaces and dots
SELECT OBJECT_NAME(OBJECT_ID('[babel_object_id_t2 .with .dot_an_spaces]'));
GO

SELECT OBJECT_NAME(OBJECT_ID('master.."babel_object_id_t2 .with .dot_an_spaces"'));
GO

SELECT OBJECT_NAME(OBJECT_ID('[babel_object_id_schema .with .dot_and_spaces]."babel_object_id_t3 .with .dot_and_spaces"'));
GO

-- Can only do lookup in current database, following should fail
SELECT OBJECT_ID('babel_object_id_db..babel_object_id_t1')
GO

SELECT OBJECT_ID('non_existing_db..babel_object_id_t1')
GO

-- To test temp object
CREATE TABLE #babel_object_id_temp_t1 (a int);
GO

SELECT OBJECT_NAME(OBJECT_ID('#babel_object_id_temp_t1'))
GO

SELECT OBJECT_NAME(OBJECT_ID('tempdb..#babel_object_id_temp_t1'))
GO

-- We can also specify object_type as parameter
SELECT OBJECT_NAME(OBJECT_ID('#babel_object_id_temp_t1', 'U'))
GO
 
DROP TABLE #babel_object_id_temp_t1;
go