SELECT * FROM sys_babelfish_sysdatabases_vu_prepare_view
GO

EXEC sys_babelfish_sysdatabases_vu_prepare_proc
GO

SELECT sys_babelfish_sysdatabases_vu_prepare_func()
GO

SELECT dbid, status, status2, default_collation, name, properties, cmptlevel FROM sys.babelfish_sysdatabases WHERE name = 'master'
GO

-- BABEL-3441: Ensure that sys.databases.compatibilty_level and sysdatabases.cmptlevel is equal 
SELECT compatibility_level FROM sys.databases WHERE name = 'master'
GO

SELECT cmptlevel FROM sys.sysdatabases WHERE name = 'master'
GO

SELECT cmptlevel FROM master.dbo.sysdatabases WHERE name = 'master'
GO

SELECT cmptlevel FROM msdb.dbo.sysdatabases WHERE name = 'master'
GO

SELECT cmptlevel FROM tempdb.dbo.sysdatabases WHERE name = 'master'
GO
