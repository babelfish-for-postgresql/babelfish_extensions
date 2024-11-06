USE master
GO

CREATE TABLE myschema.t(a int)
GO

EXEC dbo.myproc
GO

SELECT * FROM dbo.t14
GO

DROP USER smith
GO

CREATE DATABASE TestDB2961
GO

USE TestDB2961
GO

CREATE TABLE myschema.t(a int)
GO

EXEC dbo.myproc
GO

SELECT * FROM dbo.t14
GO

DROP USER smith
GO

USE master
GO

DROP DATABASE TestDB2961
GO