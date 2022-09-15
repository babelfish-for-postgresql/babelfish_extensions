CREATE DATABASE sys_tables_vu_prepare_db1;
GO

USE sys_tables_vu_prepare_db1
GO

CREATE TABLE sys_tables_vu_prepare_t1(rand_col1 int DEFAULT 1, CHECK (rand_col1 > 0));
GO

USE master;
GO

CREATE TABLE sys_tables_vu_prepare_t2(rand_col2 int DEFAULT 2, CHECK (rand_col2 > 0));
GO
