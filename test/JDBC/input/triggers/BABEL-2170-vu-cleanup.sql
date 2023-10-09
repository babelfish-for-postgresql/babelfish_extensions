-- clean  all objects in first database
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

DROP TABLE IF EXISTS babel_2170_vu_employees;
GO

-- schema_2170 object cleanup
DROP TRIGGER IF EXISTS schema_2170.babel_2170_vu_employees_view_iot_update;
GO

DROP VIEW IF EXISTS schema_2170.babel_2170_vu_employees_view;
GO

DROP TABLE IF EXISTS schema_2170.babel_2170_vu_employees;
GO
-- clean  all objects in second database
USE db2_BABEL2170;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_insert;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_update;
GO

DROP TRIGGER IF EXISTS babel_2170_vu_employees_view_iot_delete;
GO

DROP VIEW IF EXISTS babel_2170_vu_employees_view;
GO

DROP TABLE IF EXISTS babel_2170_vu_employees;
GO

USE MASTER; 
GO

DROP DATABASE db1_BABEL2170;
GO

DROP DATABASE db2_BABEL2170;
GO

SELECT name FROM sys.sysobjects WHERE name LIKE 'babel_2170%' ORDER BY name;
GO