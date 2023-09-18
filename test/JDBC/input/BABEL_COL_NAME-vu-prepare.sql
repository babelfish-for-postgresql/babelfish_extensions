CREATE DATABASE babel_3172_test_db;
GO

USE babel_3172_test_db;
GO

CREATE TABLE sys_column_name_vu_t_column_name(
    id int,
    names char
)
GO

CREATE SCHEMA sys_col_name_test_schema;
GO

CREATE TABLE sys_col_name_test_schema.test_table(
    firstName varchar(30)
)
GO

CREATE VIEW col_name_prepare_v1 AS (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name')) AS INT), 1))
GO

-- Invalid column, should return NULL
CREATE VIEW col_name_prepare_v2 AS (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name')) AS INT), 3))
GO

-- Invalid table, should return NULL
CREATE VIEW col_name_prepare_v3 AS (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name_invalid')) AS INT), 1))
GO

-- Invalid column, should return NULL
CREATE VIEW col_name_prepare_v4 AS (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name')) AS INT), NULL))
GO

-- Invalid table, should return NULL
CREATE PROCEDURE col_name_prepare_p1 AS (SELECT COL_NAME(NULL, 1));
GO

-- Invalid column, should return NULL
CREATE PROCEDURE col_name_prepare_p2 AS (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name')) AS INT), -1))
GO

-- Invalid table, should return NULL
CREATE PROCEDURE col_name_prepare_p3 AS (SELECT COL_NAME(-1, 1))
GO

-- Invalid table and column, should return NULL
CREATE PROCEDURE col_name_prepare_p4 AS (SELECT COL_NAME(-1, -1))
GO

-- Invalid column, should return NULL
CREATE FUNCTION col_name_prepare_f1()
RETURNS sys.SYSNAME AS
BEGIN
RETURN (SELECT COL_NAME(CAST((SELECT OBJECT_ID('sys_column_name_vu_t_column_name')) AS INT), 'invalid test expression'))
END
GO

-- Invalid table, should return NULL
CREATE FUNCTION col_name_prepare_f2()
RETURNS sys.SYSNAME AS
BEGIN
RETURN (SELECT COL_NAME('invalid test expression', 1))
END
GO