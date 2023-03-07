SELECT (case when count(*)>=0 THEN 1 END) FROM dbo.sysprocesses;
GO

-- should ignore white space between schema name and view name
SELECT (case when count(*)>=0 THEN 1 END) FROM dbo. sysconfigures;
GO

SELECT (case when count(*)>=0 THEN 1 END) FROM dbo.             syscurconfigs;
GO

-- case-insensitive
SELECT (case when count(*)>=0 THEN 1 END) FROM DBo.SySObjEcTS
GO

-- should ignore case-insensitive and whitespaces
SELECT (case when count(*)>=0 THEN 1 END) FROM DBo.                  sYsLANGuAgEs
GO

CREATE DATABASE DB1;
GO

-- cross-db
SELECT (case when count(*)>=0 THEN 1 END) FROM db1.dbo.sysforeignkeys;
GO

-- ignore case-sensitive and white space between schema name and view name
SELECT (case when count(*)>=0 THEN 1 END) FROM db1.dbo.       sYspROceSSes;
GO

-- multiple select statements
select (select (case when count(*)>=0 THEN 1 END) from dbo.sysprocesses) as x, (select (case when count(*)>=0 THEN 1 END) from db1.dbo.sysobjects) as y, (select (case when count(*)>=0 THEN 1 END) from dbo.syscharsets) as z;
GO

-- multiple select stataments with white-spaces and case-sensitive
select (select (case when count(*)>=0 THEN 1 END) from dbo.sysprocesses) as x, (select (case when count(*)>=0 THEN 1 END) from db1.dbo.SySproCESses) as y, (select (case when count(*)>=0 THEN 1 END) from dbo.    sysprocesses) as z;
GO

DROP DATABASE DB1;
GO
