-- tsql

USE master
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

EXEC sp_rename 'sp_rename_table1', 'sp_rename_table1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_schema1.sp_rename_table2', 'sp_rename_table2_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_view1', 'sp_rename_view1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_schema1.sp_rename_view1', 'sp_rename_view1_new2', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

EXEC sp_rename_internal 'sp_rename_view1_new2', 'sp_rename_view1_new', 'sp_rename_schema1', 'V';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

SELECT ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE 
FROM information_schema.routines WHERE ROUTINE_NAME LIKE '%sp_rename%' 
ORDER BY ROUTINE_NAME
GO

SELECT nspname, funcname, orig_name, funcsignature 
FROM sys.babelfish_function_ext WHERE funcname LIKE '%sp_rename%'
ORDER BY funcname
GO

EXEC sp_rename 'sp_rename_proc1', 'sp_rename_proc1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_func1', 'sp_rename_func1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_schema1.sp_rename_proc2', 'sp_rename_proc2_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_schema1.sp_rename_func3', 'sp_rename_func3_new', 'OBJECT';
GO

SELECT ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE 
FROM information_schema.routines WHERE ROUTINE_NAME LIKE '%sp_rename%'
ORDER BY ROUTINE_NAME
GO

SELECT nspname, funcname, orig_name, funcsignature 
FROM sys.babelfish_function_ext WHERE funcname LIKE '%sp_rename%' 
ORDER BY funcname
GO

-- Null input for objname
SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

EXEC sp_rename '', 'sp_rename_view1_new', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO


-- Null input for newname: error, requiring input for newname
EXEC sp_rename 'sp_rename_view1_new', '', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

-- Null input for objtype: executes properly, when there is a matching object
EXEC sp_rename 'sp_rename_view1_new', 'sp_rename_view1';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

-- Non-matching objname input
EXEC sp_rename 'aaaa', 'sp_rename_view1', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO


-- Non-matching objtype input: error, objtype not supported
EXEC sp_rename 'sp_rename_view1_new', 'sp_rename_view1', 'AAAA';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO

-- case-insensitive
EXEC sp_rename 'SP_RENAME_table1_new', 'sp_rename_table1_case_insensitive1', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

EXEC sp_rename 'sp_rename_table1_case_insensitive1', 'SP_RENAME_TABLE1_case_insensitive2', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

EXEC sp_rename 'sp_rename_view1', 'sp_REName_view1_CASE_insensitive1', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename%' 
ORDER BY TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename%' 
ORDER BY object_name
GO