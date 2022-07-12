USE db1_sys_indexes
GO

USE master
GO

DROP INDEX i_sys_index_test1 ON t_sys_index_test1;
DROP INDEX i_sys_index_test1a ON t_sys_index_test1;
GO

DROP TABLE IF EXISTS t_unique_index
GO

DROP TABLE IF EXISTS t_sys_index_test1
GO

DROP TABLE IF EXISTS t_sys_no_index
GO

DROP TABLE IF EXISTS t_fkey_table
GO

DROP TABLE IF EXISTS t_pkey_table
GO

DROP TABLE IF EXISTS t_unique_index
GO

DROP DATABASE db1_sys_indexes
GO