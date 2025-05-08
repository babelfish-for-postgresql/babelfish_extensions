CREATE DATABASE db1;
GO

USE db1;
GO

CREATE LOGIN login1 WITH PASSWORD = '123';
GO

ALTER LOGIN login1 disable;
GO

SELECT is_disabled FROM sys.server_principals WHERE name = 'login1';
GO

ALTER LOGIN login1 enable;
GO

USE MASTER;
GO

DROP DATABASE db1;
GO

DROP LOGIN login1;
GO

-- Tests for db level collation
CREATE DATABASE db1 COLLATE BBF_Unicode_CP1_CI_AI;
GO

USE db1;
GO

CREATE LOGIN login1 WITH PASSWORD = '123';
GO

ALTER LOGIN login1 disable;
GO

SELECT is_disabled FROM sys.server_principals WHERE name = 'login1';
GO

ALTER LOGIN login1 enable;
GO

USE MASTER;
GO

DROP DATABASE db1;
GO

DROP LOGIN login1;
GO
