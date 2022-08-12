DROP TABLE IF EXISTS sys_index_columns_vu_prepare_t1
GO

CREATE TABLE sys_index_columns_vu_prepare_t1 (
	sic_name VARCHAR (50),
	sic_surname VARCHAR (50)
)
GO

CREATE INDEX sys_index_columns_vu_prepare_i1
ON sys_index_columns_vu_prepare_t1 (sic_name)
GO

CREATE DATABASE sys_index_columns_vu_prepare_db1;
GO

USE sys_index_columns_vu_prepare_db1
GO

CREATE TABLE sys_index_columns_vu_prepare_t2(rand_col1 int DEFAULT 1);
GO

CREATE INDEX sys_index_columns_vu_prepare_i2 ON sys_index_columns_vu_prepare_t2(rand_col1);
GO

USE master;
GO

CREATE TABLE sys_index_columns_vu_prepare_t3(rand_col2 int DEFAULT 1);
GO

CREATE INDEX sys_index_columns_vu_prepare_i3 ON sys_index_columns_vu_prepare_t3(rand_col2);
GO
