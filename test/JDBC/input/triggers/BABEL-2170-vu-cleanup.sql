-- clean all objects in first database
USE db1_BABEL2170;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_insert;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_update;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_delete;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_bulkinsert;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view_bulkinsert;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view_2;
GO

DROP TABLE IF EXISTS babel_2170_vu_employees;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view_txn;
GO

DROP TABLE IF EXISTS babel_2170_vu_employees_txn;
GO

USE MASTER; 
GO

DROP DATABASE IF EXISTS db1_BABEL2170;
GO