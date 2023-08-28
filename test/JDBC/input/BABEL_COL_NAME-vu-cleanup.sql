USE babel_3172_test_db;
GO

DROP TABLE IF EXISTS sys_column_name_vu_t_column_name;
GO

DROP TABLE IF EXISTS sys_col_name_test_schema.test_table;
GO

DROP SCHEMA IF EXISTS sys_col_name_test_schema;
GO

USE master;
GO

DROP DATABASE IF EXISTS babel_3172_test_db;
GO

-- Drop views
DROP VIEW IF EXISTS col_name_prepare_v1;
DROP VIEW IF EXISTS col_name_prepare_v2;
DROP VIEW IF EXISTS col_name_prepare_v3;
DROP VIEW IF EXISTS col_name_prepare_v4;
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS col_name_prepare_p1;
DROP PROCEDURE IF EXISTS col_name_prepare_p2;
DROP PROCEDURE IF EXISTS col_name_prepare_p3;
DROP PROCEDURE IF EXISTS col_name_prepare_p4;
GO

-- Drop functions
DROP FUNCTION IF EXISTS col_name_prepare_f1();
DROP FUNCTION IF EXISTS col_name_prepare_f2();
GO