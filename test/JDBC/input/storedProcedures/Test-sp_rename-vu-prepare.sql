-- tsql
USE master
GO

CREATE TABLE sp_rename_table1(sp_rename_t1_col1 int, sp_rename_t1_col2 int);
GO

CREATE TABLE sp_rename_table2(sp_rename_t2_col1 int, sp_rename_t2_col2 int);
GO

CREATE SCHEMA sp_rename_schema1;
GO

CREATE TABLE sp_rename_schema1.sp_rename_table1(sp_rename_s1_t1_col1 int, sp_rename_s1_t1_col2 int);
GO

CREATE TABLE sp_rename_schema1.sp_rename_table2(sp_rename_s1_t2_col1 int, sp_rename_s1_t2_col2 int);
GO

CREATE VIEW sp_rename_view1 as SELECT sp_rename_t1_col1 FROM sp_rename_table1;
GO

CREATE VIEW sp_rename_schema1.sp_rename_view1 as SELECT sp_rename_s1_t1_col1 FROM sp_rename_table1;
GO

CREATE PROCEDURE sp_rename_proc1
AS
SELECT 1;
GO

CREATE PROCEDURE sp_rename_schema1.sp_rename_proc2
AS
SELECT 1;
GO

CREATE FUNCTION sp_rename_func1() 
RETURNS INT
AS 
BEGIN
    RETURN 1;
END
GO

CREATE FUNCTION sp_rename_func2(@id INT) 
RETURNS INT
AS 
BEGIN
    RETURN 1;
END
GO

CREATE FUNCTION sp_rename_schema1.sp_rename_func3(@id INT) 
RETURNS INT
AS 
BEGIN
    RETURN 1;
END
GO