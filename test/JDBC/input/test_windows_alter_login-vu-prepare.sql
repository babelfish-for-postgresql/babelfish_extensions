-- create login for windows
CREATE LOGIN [BAbel\aDUser] from windows;
GO

-- create login for password
CREATE LOGIN passWORduser with password='123';
GO

CREATE LOGIN [aduser@BBF] with password='123';
GO

-- create a database to test alter login with default database
CREATE DATABASE alter_db;
GO