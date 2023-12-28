USE MASTER;
GO

DECLARE @usr CHAR(30)
DECLARE @cur_usr CHAR(30)
SET @usr = user
SET @cur_usr = current_user
SELECT 'user: '+ @usr
SELECT 'current_user: '+ @cur_usr
GO

CREATE TABLE dbo.t1
(id INT IDENTITY(100, 1) NOT NULL,
 description VARCHAR(30) NOT NULL,
 usr VARCHAR(30) NOT NULL DEFAULT USER,
 cur_usr VARCHAR(30) NOT NULL DEFAULT CURRENT_USER);
GO

INSERT INTO dbo.t1 (description) VALUES ('Orange');
INSERT INTO dbo.t1 (description) VALUES ('Blue');
INSERT INTO dbo.t1 (description, usr) VALUES ('Green', 'Bob');
INSERT INTO dbo.t1 (description, cur_usr) VALUES ('Purple', 'Alice');
INSERT INTO dbo.t1 (description, usr, cur_usr) VALUES ('Red', 'Mike', 'Dave');
GO

SELECT * FROM dbo.t1 ORDER BY id;  
GO

DROP TABLE dbo.t1;
GO

-- Test properties after USE
CREATE DATABASE db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

USE db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Error: Test DROP
DROP DATABASE db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Test DROP when using another database
USE MASTER;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

DROP DATABASE db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Test CREATE
CREATE DATABASE db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Clean up
DROP DATABASE db1;
GO
