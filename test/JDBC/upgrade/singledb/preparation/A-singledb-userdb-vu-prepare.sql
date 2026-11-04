-- User database present during the single-db upgrade; its sysdatabases wrapper lives in plain dbo.
-- Single-db allows one user database, so verify/cleanup of this test must run (and drop it)
-- before BABEL-1444-vu-verify creates its own; files run in name order, hence the A- prefix.
CREATE DATABASE singledb_userdb
GO

USE singledb_userdb
GO

CREATE VIEW singledb_userdb_v1 AS SELECT name FROM sysdatabases WHERE name = 'singledb_userdb'
GO

USE master
GO
