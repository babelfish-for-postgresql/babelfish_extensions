-- For TDS backends, the dbid is the logical database id, so db_name(dbid)
-- should show us the logical database name of the process.
-- We are showing multiple rows in sys.sysprocesses for the
-- current SPID (BABEL-2828), so doing a SELECT DISTINCT
SELECT DISTINCT db_name(dbid), loginname FROM sys.sysprocesses WHERE spid = @@SPID
GO

SELECT DISTINCT db_name(dbid), loginname FROM dbo.sysprocesses WHERE spid = @@SPID
GO

SELECT DISTINCT db_name(dbid), loginname FROM [sys].[sysprocesses] WHERE spid = @@SPID
GO

SELECT DISTINCT db_name(dbid), loginname FROM [DbO].[SySProcESSeS] WHERE spid = @@SPID
GO

CREATE DATABASE db_2829
GO
USE db_2829
GO
SELECT DISTINCT db_name(dbid), loginname FROM sys.sysprocesses WHERE spid = @@SPID
GO
SELECT DISTINCT db_name(dbid), loginname FROM dbo.sysprocesses WHERE spid = @@SPID
GO
USE master
GO

SELECT DISTINCT db_name(dbid), loginname FROM db_2829.sys.sysprocesses WHERE spid = @@SPID
GO
SELECT DISTINCT db_name(dbid), loginname FROM db_2829.dbo.sysprocesses WHERE spid = @@SPID
GO

-- These below test cases are just to validate the schema rewrite from dbo to sys in different scenarios.
select (select DISTINCT db_name(dbid) from dbo.sysprocesses WHERE spid = @@SPID) as a, count(*) from (select * from (select DISTINCT * from [DbO].[SySProcESSeS] WHERE spid = @@SPID) as a) as b;
go

create procedure procedure_2829 as select DISTINCT db_name(dbid), loginname from [DbO].[SySProcESSeS] WHERE spid = @@SPID;
go

exec procedure_2829
go

create table table_2829 ( a int,  b int);
go

insert into table_2829 select 1,2;
go

select * from table_2829;
go

insert into table_2829 select DISTINCT spid, kpid from sys.sysprocesses WHERE spid = @@SPID;
go

DROP PROCEDURE procedure_2829
GO

DROP TABLE table_2829
GO

DROP DATABASE db_2829
GO

-- test case-sementics of sys.sysprocesses catalog.
-- lastwaittype, waitresource column can not be test as these  are NULL.
-- hostprocess colum is ID in char
-- cmd, nt_domain, nt_username, net_address, net_library testing can't be done as these are NULL.
SELECT CASE WHEN (select count(status) from sys.sysprocesses where status='active') = (select count(status) from sys.sysprocesses where status='ACTIVE') THEN 1 ELSE 0 END AS result;
GO
SELECT CASE WHEN (select count(program_name) from sys.sysprocesses where program_name='sqlcmd') = (select count(program_name) from sys.sysprocesses where program_name='SQLCMD') THEN 1 ELSE 0 END AS result;
GO
SELECT CASE WHEN (select count(loginname) from sys.sysprocesses where loginname='jdbc_user') = (select count(loginname) from sys.sysprocesses where loginname='JDBC_user') THEN 1 ELSE 0 END AS result;
GO
