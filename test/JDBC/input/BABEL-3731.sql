SELECT (case when count(*)>=0 THEN 1 END) FROM dbo.sysprocesses;
GO

-- ignore white space between schema name and view name
SELECT (case when count(*)>=0 THEN 1 END) FROM dbo. sysprocesses;
GO

-- case-insensitive
SELECT (case when count(*)>=0 THEN 1 END) FROM DBo.SySObjEcTS
GO

CREATE DATABASE DB1;
GO

-- cross-db
SELECT (case when count(*)>=0 THEN 1 END) FROM db1.dbo.sysforeignkeys;
GO

-- multiple select statements
select (select (case when count(*)>=0 THEN 1 END) from dbo.sysprocesses) as x, (select (case when count(*)>=0 THEN 1 END) from db1.dbo.sysobjects) as y, (select (case when count(*)>=0 THEN 1 END) from dbo.syscharsets) as z;
GO

DROP DATABASE DB1;
GO
