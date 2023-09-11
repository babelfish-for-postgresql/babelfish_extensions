USE babel_3489_test_db;
GO

DROP TABLE IF EXISTS sys_column_length_test_table;
GO

DROP TABLE IF EXISTS sys_col_length_test_schema.test_table;
GO

DROP SCHEMA IF EXISTS sys_col_length_test_schema;
GO

USE master;
GO

DROP DATABASE IF EXISTS babel_3489_test_db;
GO

-- Drop views
DROP VIEW IF EXISTS col_length_prepare_v1;
DROP VIEW IF EXISTS col_length_prepare_v2;
DROP VIEW IF EXISTS col_length_prepare_v3;
DROP VIEW IF EXISTS col_length_prepare_v4;
DROP VIEW IF EXISTS col_length_prepare_v5;
DROP VIEW IF EXISTS col_length_prepare_v6;
DROP VIEW IF EXISTS col_length_prepare_v7;
DROP VIEW IF EXISTS col_length_prepare_v8;
DROP VIEW IF EXISTS col_length_prepare_v9;
DROP VIEW IF EXISTS col_length_prepare_v10;
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS col_length_prepare_p1;
DROP PROCEDURE IF EXISTS col_length_prepare_p2;
DROP PROCEDURE IF EXISTS col_length_prepare_p3;
DROP PROCEDURE IF EXISTS col_length_prepare_p4;
DROP PROCEDURE IF EXISTS col_length_prepare_p5;
DROP PROCEDURE IF EXISTS col_length_prepare_p6;
DROP PROCEDURE IF EXISTS col_length_prepare_p7;
DROP PROCEDURE IF EXISTS col_length_prepare_p8;
DROP PROCEDURE IF EXISTS col_length_prepare_p9;
DROP PROCEDURE IF EXISTS col_length_prepare_p10;
GO

-- Drop functions
DROP FUNCTION IF EXISTS col_length_prepare_f1();
DROP FUNCTION IF EXISTS col_length_prepare_f2();
DROP FUNCTION IF EXISTS col_length_prepare_f3();
DROP FUNCTION IF EXISTS col_length_prepare_f4();
DROP FUNCTION IF EXISTS col_length_prepare_f5();
DROP FUNCTION IF EXISTS col_length_prepare_f6();
DROP FUNCTION IF EXISTS col_length_prepare_f7();
DROP FUNCTION IF EXISTS col_length_prepare_f8();
DROP FUNCTION IF EXISTS col_length_prepare_f9();
DROP FUNCTION IF EXISTS col_length_prepare_f10();
DROP FUNCTION IF EXISTS col_length_prepare_f11();
DROP FUNCTION IF EXISTS col_length_prepare_f12();
DROP FUNCTION IF EXISTS col_length_prepare_f13();
DROP FUNCTION IF EXISTS col_length_prepare_f14();
DROP FUNCTION IF EXISTS col_length_prepare_f15();
DROP FUNCTION IF EXISTS col_length_prepare_f16();
GO
