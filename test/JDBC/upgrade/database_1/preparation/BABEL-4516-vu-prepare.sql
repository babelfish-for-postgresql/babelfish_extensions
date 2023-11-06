USE master;
GO

-- CREATE a user defined database
CREATE DATABASE [DATABASE_1];
GO

-- Populate the database
-- Schemas
USE [DATABASE_1];
GO

CREATE SCHEMA [DB1_Schema_1];
GO

CREATE SCHEMA [db1_SCHEMA_2];
GO

CREATE SCHEMA [DB1_My_Schema];
GO

-- Create few logins and users
CREATE LOGIN [DB1_Login_1] WITH PASSWORD = '12345678';
GO

CREATE USER [DB1_User_1] FOR LOGIN [DB1_Login_1];
GO

CREATE LOGIN [DB1_Login_2] WITH PASSWORD = 'abc';
GO

CREATE LOGIN [DB1_User_3] WITH PASSWORD = 'abc';
GO

CREATE USER [DB1_User_3] WITH DEFAULT_SCHEMA = [DB1_Schema_1];
GO

-- Tables
USE [DATABASE_1];
GO

CREATE TABLE [Table_1] ([Col_1] INT NOT NULL, [COL 2] INT NOT NULL, PRIMARY KEY ([Col_1], [COL 2]));
GO

INSERT INTO [Table_1] SELECT x, x + 1 FROM generate_series(1, 1000) x;
GO

CREATE TABLE [DB1_My_Schema].[Table_2] ([Col_1] INT NOT NULL, [COL 2] INT NOT NULL, FOREIGN KEY ([Col_1], [COL 2]) REFERENCES [Table_1]([Col_1], [COL 2]));
GO

INSERT INTO [DB1_My_Schema].[Table_2] SELECT x, x + 1 FROM generate_series(1, 1000) x;
GO

-- Views
CREATE view [db1_SCHEMA_2].[DB1 My View] AS SELECT * FROM [Table_1];
GO

-- Procedures
CREATE PROC [db1_SCHEMA_2].[babel_user_ext] AS
BEGIN 
	SELECT rolname, login_name, type, orig_username, database_name
	FROM sys.babelfish_authid_user_ext
	WHERE orig_username LIKE 'DB1_User_%'
	ORDER BY rolname, orig_username
END
GO

-- Functions
CREATE FUNCTION [db1_SCHEMA_2].[Func_2] (@a INT)
RETURNS @tab table(a INT, b INT) AS
BEGIN
	INSERT INTO @tab SELECT * FROM [DB1_My_Schema].[Table_2] WHERE Col_1 = @a;
	RETURN;
END;
GO
