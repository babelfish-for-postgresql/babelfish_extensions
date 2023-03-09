USE master;
GO

SELECT COUNT(*) FROM sys.sysobjects s where s.name = 'sys_sysobjects_vu_prepare_table'
GO

-- sysobjects should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT COUNT(*) FROM dbo.    SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

-- In case of cross-db, sysobjects should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT COUNT(*) FROM db1.sys.     SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table_t1';
go

SELECT COUNT(*) FROM db1.dbo.     SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table_t1';
go

-- should not be visible here
SELECT COUNT(*) FROM db1.sys.     SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

SELECT COUNT(*) FROM db1.dbo.     SySObJEctS s where s.name = 'sys_sysobjects_vu_prepare_table';
go

SELECT * FROM sys_sysobjects_vu_prepare_view
GO

EXEC sys_sysobjects_vu_prepare_proc
GO

SELECT dbo.sys_sysobjects_vu_prepare_func()
GO