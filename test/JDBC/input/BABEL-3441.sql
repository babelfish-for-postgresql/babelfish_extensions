-- Ensure that sys.databases.compatibilty_level and sysdatabases.cmptlevel is equal
USE master
GO

SELECT compatibility_level FROM sys.databases WHERE name = 'master'
GO

SELECT cmptlevel FROM sys.sysdatabases WHERE name = 'master'
GO

SELECT cmptlevel FROM master.dbo.sysdatabases WHERE name = 'master'
GO

