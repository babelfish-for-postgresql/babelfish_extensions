-- sla 200000

-- tsql

USE master
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

EXEC sp_rename 'sp_rename_vu_table1', 'sp_rename_vu_table1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_table2', 'sp_rename_vu_table2_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_view1', 'sp_rename_vu_view1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_view1', 'sp_rename_vu_view1_new2', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_view1_new2', 'sp_rename_vu_view1_new', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

SELECT ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE 
FROM information_schema.routines WHERE ROUTINE_NAME LIKE '%sp_rename_vu%' 
ORDER BY ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME
GO

SELECT nspname, funcname, orig_name, funcsignature 
FROM sys.babelfish_function_ext WHERE funcname LIKE '%sp_rename_vu%'
ORDER BY nspname, funcname, orig_name, funcsignature
GO

EXEC sp_rename 'sp_rename_vu_proc1', 'sp_rename_vu_proc1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_func1', 'sp_rename_vu_func1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_proc2', 'sp_rename_vu_proc2_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_func3', 'sp_rename_vu_func3_new', 'OBJECT';
GO

SELECT ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE 
FROM information_schema.routines WHERE ROUTINE_NAME LIKE '%sp_rename_vu%'
ORDER BY ROUTINE_CATALOG, ROUTINE_SCHEMA, ROUTINE_NAME
GO

SELECT nspname, funcname, orig_name, funcsignature 
FROM sys.babelfish_function_ext WHERE funcname LIKE '%sp_rename_vu%' 
ORDER BY nspname, funcname, orig_name, funcsignature
GO

-- Null input for objname
SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

EXEC sp_rename NULL, 'sp_rename_vu_view1_new', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO


-- Null input for newname: error, requiring input for newname
EXEC sp_rename 'sp_rename_vu_view1_new', NULL, 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

EXEC sp_rename 'sp_rename_vu_view1_new', 'sp_rename_vu_view1', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

-- Non-matching objname input
EXEC sp_rename 'aaaa', 'sp_rename_vu_view1', 'OBJECT';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO


-- Non-matching objtype input: error, objtype not supported
EXEC sp_rename 'sp_rename_vu_view1_new', 'sp_rename_vu_view1', 'AAAA';
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

-- case-insensitive
EXEC sp_rename 'SP_RENAME_vu_table1_new', 'sp_rename_vu_table1_case_insensitive1', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

EXEC sp_rename 'sp_rename_vu_table1_case_insensitive1', 'SP_RENAME_vu_TABLE1_case_insensitive2', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

EXEC sp_rename 'sp_rename_vu_view1', 'sp_REName_vu_view1_CASE_insensitive1', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

-- Null input for objtype: Error temporarily, as only OBJECT type is supported
EXEC sp_rename 'sp_rename_vu_view1_new', 'sp_rename_vu_view1';
GO

-- When objname input is in db.schema.subname format
EXEC sp_rename 'master.dbo.sp_rename_vu_view1_case_insensitive1', 'sp_rename_vu_view1', 'OBJECT';
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

SELECT schema_name, object_name 
FROM sys.babelfish_view_def WHERE object_name LIKE '%sp_rename_vu%' 
ORDER BY schema_name, object_name
GO

-- When objname input is in more than 3 part format(db.schema.subname): Error
EXEC sp_rename 'master.dbo.dbo2.sp_rename_vu_view1', 'sp_rename_vu_view12', 'OBJECT';
GO

-- checking if procedure/function orig_names are updated correctly
EXEC sp_rename 'sp_rename_vu_func2', 'sp_rename_vu_FUNC2_neW', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_proc1_new', 'sp_rename_vu_PRoc1_new2', 'OBJECT';
GO

SELECT nspname, funcname, orig_name, funcsignature 
FROM sys.babelfish_function_ext WHERE funcname LIKE '%sp_rename_vu%' 
ORDER BY nspname, funcname, orig_name, funcsignature
GO

-- SEQUENCE
SELECT SEQUENCE_CATALOG, SEQUENCE_SCHEMA, SEQUENCE_NAME 
FROM information_schema.sequences WHERE SEQUENCE_NAME LIKE '%sp_rename_vu%' 
ORDER BY SEQUENCE_CATALOG, SEQUENCE_SCHEMA, SEQUENCE_NAME
GO

EXEC sp_rename 'sp_rename_vu_seq1', 'sp_rename_vu_seq1_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_seq1', 'sp_rename_vu_seq1_new2', 'OBJECT';
GO

SELECT SEQUENCE_CATALOG, SEQUENCE_SCHEMA, SEQUENCE_NAME 
FROM information_schema.sequences WHERE SEQUENCE_NAME LIKE '%sp_rename_vu%' 
ORDER BY SEQUENCE_CATALOG, SEQUENCE_SCHEMA, SEQUENCE_NAME
GO

-- ****Given objtype is valid but not supported yet****
-- Column
EXEC sp_rename 'sp_rename_vu_table1_case_insensitive2', 'sp_rename_vu_table1', 'OBJECT';
GO

SELECT COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sp_rename_vu_table1' 
ORDER BY COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME;
GO

EXEC sp_rename 'sp_rename_vu_table1.sp_rename_vu_t1_col1', 'sp_rename_vu_t1_col1_new', 'COLUMN';
GO

SELECT COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sp_rename_vu_table1' 
ORDER BY COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME;
GO

SELECT COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sp_rename_vu_table2_new'
ORDER BY COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME;
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_table2_new.sp_rename_vu_s1_t2_col1', 'sp_rename_vu_s1_t2_col1_new', 'COLUMN';
GO

SELECT COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'sp_rename_vu_table2_new'
ORDER BY COLUMN_NAME, TABLE_SCHEMA, TABLE_NAME;
GO

-- COLUMN: error-case
EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_table2_new.sp_rename_vu_s1_t2_wrong_col', 'sp_rename_vu_s1_t2_col1_new', 'COLUMN';
GO

-- Index
EXEC sp_rename N'sp_rename_vu_index1', N'sp_rename_vu_index2', N'INDEX';
GO

-- Statistics
EXEC sp_rename 'sp_rename_vu_stat1', 'sp_rename_vu_stat2', 'STATISTICS';
GO

-- USERDATATYPE
EXEC sp_rename 'sp_rename_vu_alias1', 'sp_rename_vu_alias2', 'USERDATATYPE';
GO

-- Trigger
EXEC sp_rename 'sp_rename_vu_trig1', 'sp_rename_vu_trig2', 'OBJECT';
GO