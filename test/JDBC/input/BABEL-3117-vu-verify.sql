USE BABEL_3117_prepare_db1
GO

SELECT count(*) FROM BABEL_3117_prepare_db1_employeeData;
GO

DROP TRIGGER BABEL_3117_prepare_trigger1
GO

USE BABEL_3117_prepare_db2
GO
SELECT count(*) FROM BABEL_3117_prepare_db2_employeeData;
GO

USE master
GO

DROP DATABASE BABEL_3117_prepare_db1
DROP DATABASE BABEL_3117_prepare_db2
GO
