USE master;
GO

SELECT nspname FROM sys.babelfish_namespace_ext where dbid in (1,2,4) and nspname like '%dbo' order by 1;
GO
