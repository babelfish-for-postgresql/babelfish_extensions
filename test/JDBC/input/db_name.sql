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

USE master;
GO

--dropping databases
DROP DATABASE DB_NAME_test;
GO