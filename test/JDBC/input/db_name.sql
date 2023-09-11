--creating database
CREATE DATABASE DB_NAME_test ON
(NAME = data_one,
    FILENAME = 'C:\print.pdf',
    SIZE = 10,
    MAXSIZE = 50,
    FILEGROWTH = 5)
LOG ON
(NAME = data_two,
    FILENAME = 'print.pdf',
    SIZE = 5 MB,
    MAXSIZE = 25 MB,
    FILEGROWTH = 5 MB);
GO

USE db_name_test;
GO

CREATE TABLE sp_rename_vu_table1(sp_rename_vu_t1_col1 int, sp_rename_vu_t1_col2 int);
GO

CREATE TABLE sp_rename_vu_table2(sp_rename_vu_t2_col1 int, sp_rename_vu_t2_col2 int);
GO

CREATE SCHEMA sp_rename_vu_schema1;
GO

CREATE TABLE sp_rename_vu_schema1.sp_rename_vu_table2(sp_rename_vu_s1_t2_col1 int, sp_rename_vu_s1_t2_col2 int);
GO

SELECT DB_NAME();
GO

--showing name column storing lowercase dbname and newly added column with original_case_dbname
SELECT name, orig_name FROM sys.babelfish_sysdatabases;
GO

--testing these objects behaviour
SELECT PROCEDURE_QUALIFIER FROM sys.sp_stored_procedures_view where PROCEDURE_NAME LIKE 'sp_special_columns_length_helper%';
GO

SELECT PROCEDURE_QUALIFIER FROM sys.sp_sproc_columns_view where COLUMN_NAME LIKE 'money';
GO

SELECT * from information_schema_tsql.schemata;
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%sp_rename_vu%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_table2', 'sp_rename_vu_table2_new', 'OBJECT';
GO

EXEC sp_rename 'sp_rename_vu_schema1.sp_rename_vu_table2_new.sp_rename_vu_s1_t2_col1', 'sp_rename_vu_s1_t2_col1_new', 'COLUMN';
GO

DECLARE @sp_rename_helperfunc_out1 nvarchar(776);
DECLARE @sp_rename_helperfunc_out2 nvarchar(776);
DECLARE @sp_rename_helperfunc_out3 nvarchar(776);
DECLARE @sp_rename_helperfunc_out4 nvarchar(776);

EXEC sys.babelfish_sp_rename_word_parse 'sp_rename_vu_schema1.sp_rename_vu_table2_new.sp_rename_vu_s1_t2_col1_new', 'COLUMN', @sp_rename_helperfunc_out1 OUT, @sp_rename_helperfunc_out2 OUT, @sp_rename_helperfunc_out3 OUT, @sp_rename_helperfunc_out4 OUT;
SELECT @sp_rename_helperfunc_out1, @sp_rename_helperfunc_out2, @sp_rename_helperfunc_out3, @sp_rename_helperfunc_out4;
GO

DROP TABLE sp_rename_vu_table2;
GO

DROP TABLE sp_rename_vu_table1;
GO

DROP TABLE sp_rename_vu_schema1.sp_rename_vu_table2_new;
GO

DROP SCHEMA sp_rename_vu_schema1;
GO

USE master;
GO

--dropping databases
DROP DATABASE DB_NAME_test;
GO