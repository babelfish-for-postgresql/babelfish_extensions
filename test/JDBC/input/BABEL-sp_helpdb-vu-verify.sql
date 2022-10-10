SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb();
GO

-- Executing sp_helpdb with already existing dbname as an input
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('master');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('tempdb');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('msdb');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('test_db1');
GO