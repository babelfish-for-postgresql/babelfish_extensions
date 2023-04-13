CREATE DATABASE sys_sysobjects_vu_prepare_db1;
GO

USE sys_sysobjects_vu_prepare_db1;
GO

CREATE TABLE sys_sysobjects_vu_prepare_table_t1(c1 int)
GO

USE master;
GO

SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table'
GO

-- sysobjects should also exist in dbo schema
SELECT COUNT(*) FROM dbo.SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

-- In case of cross-db, sysobjects should also exist in dbo schema
SELECT COUNT(*) FROM sys_sysobjects_vu_prepare_db1.sys.SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table_t1';
go

SELECT COUNT(*) FROM sys_sysobjects_vu_prepare_db1.dbo.SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table_t1';
go

-- should not be visible here
SELECT COUNT(*) FROM sys_sysobjects_vu_prepare_db1.sys.SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

SELECT COUNT(*) FROM sys_sysobjects_vu_prepare_db1.dbo.SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

SELECT * FROM sys_sysobjects_vu_prepare_view
GO

EXEC sys_sysobjects_vu_prepare_proc
GO

SELECT dbo.sys_sysobjects_vu_prepare_func()
GO