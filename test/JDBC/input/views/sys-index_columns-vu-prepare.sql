DROP TABLE IF EXISTS sys_index_columns
GO

CREATE TABLE sys_index_columns (
	sic_name VARCHAR (50),
	sic_surname VARCHAR (50)
)
GO

CREATE INDEX sic_test_index
ON sys_index_columns (sic_name)
GO

CREATE DATABASE db1_sys_index_columns;
GO

USE db1_sys_index_columns
GO

CREATE TABLE rand_name1_sys_index_columns(rand_col1 int DEFAULT 1);
GO

CREATE INDEX idx_rand_name1_sys_index_columns ON rand_name1_sys_index_columns(rand_col1);
GO

USE master;
GO

CREATE TABLE rand_name2_sys_index_columns(rand_col2 int DEFAULT 1);
GO

CREATE INDEX idx_rand_name2_sys_index_columns ON rand_name2_sys_index_columns(rand_col2);
GO
