--creating database
CREATE DATABASE DB_NAME_CHANGE_test_vu_db ON
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

USE db_name_change_test_vu_db;
GO

CREATE PROCEDURE DB_NAME_CHANGE_test_vu_proc1 (
    @a int, @b int = 20, @c int = 30, @d int
) AS 
BEGIN 
    SELECT @a + @b + @c + @d; 
END;
GO

CREATE TABLE db_name_change_test_vu_table1(db_name_change_test_vu_t1_col1 int, db_name_change_test_vu_t1_col2 int);
GO

CREATE TABLE db_name_change_test_vu_table2(db_name_change_test_vu_t2_col1 int, db_name_change_test_vu_t2_col2 int);
GO

CREATE SCHEMA db_name_change_test_vu_schema1;
GO

CREATE TABLE db_name_change_test_vu_schema1.db_name_change_test_vu_table2(db_name_change_test_vu_s1_t2_col1 int, db_name_change_test_vu_s1_t2_col2 int);
GO

SELECT DB_NAME();
GO

--showing name column storing lowercase dbname and newly added column with original_case_dbname
SELECT name, orig_name FROM sys.babelfish_sysdatabases where name LIKE 'db_name_change%';
GO

SELECT name FROM sys.sysdatabases where name = DB_NAME();
GO

SELECT dbname FROM sys.pg_namespace_ext where dbname = DB_NAME();
GO

SELECT name FROM sys.databases where name = DB_NAME();
GO

--testing these objects behaviour

SELECT PROCEDURE_QUALIFIER FROM sys.sp_stored_procedures_view where PROCEDURE_NAME LIKE 'DB_NAME_CHANGE_test_vu%';
GO

SELECT PROCEDURE_QUALIFIER FROM sys.sp_sproc_columns_view where PROCEDURE_NAME LIKE 'DB_NAME_CHANGE_test_vu%';
GO

SELECT * from information_schema_tsql.schemata;
GO

SELECT * FROM information_schema.tables WHERE TABLE_NAME LIKE '%db_name_change%' 
ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME
GO

EXEC sp_rename 'db_name_change_test_vu_schema1.db_name_change_test_vu_table2', 'db_name_change_test_vu_table2_new', 'OBJECT';
GO

EXEC sp_rename 'db_name_change_test_vu_schema1.db_name_change_test_vu_table2_new.db_name_change_test_vu_s1_t2_col1', 'db_name_change_test_vu_s1_t2_col1_new', 'COLUMN';
GO

DECLARE @sp_rename_helperfunc_out1 nvarchar(776);
DECLARE @sp_rename_helperfunc_out2 nvarchar(776);
DECLARE @sp_rename_helperfunc_out3 nvarchar(776);
DECLARE @sp_rename_helperfunc_out4 nvarchar(776);

EXEC sys.babelfish_sp_rename_word_parse 'db_name_change_test_vu_schema1.db_name_change_test_vu_table2_new.db_name_change_test_vu_s1_t2_col1_new', 'COLUMN', @sp_rename_helperfunc_out1 OUT, @sp_rename_helperfunc_out2 OUT, @sp_rename_helperfunc_out3 OUT, @sp_rename_helperfunc_out4 OUT;
SELECT @sp_rename_helperfunc_out1, @sp_rename_helperfunc_out2, @sp_rename_helperfunc_out3, @sp_rename_helperfunc_out4;
GO

DROP PROCEDURE DB_NAME_CHANGE_test_vu_proc1;
GO

DROP TABLE db_name_change_test_vu_table2;
GO

DROP TABLE db_name_change_test_vu_table1;
GO

DROP TABLE db_name_change_test_vu_schema1.db_name_change_test_vu_table2_new;
GO

DROP SCHEMA db_name_change_test_vu_schema1;
GO

USE master;
GO

--dropping databases
DROP DATABASE DB_NAME_CHANGE_test_vu_db;
GO