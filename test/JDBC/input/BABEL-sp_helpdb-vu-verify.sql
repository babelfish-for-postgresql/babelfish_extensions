SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb() WHERE name IN ('master', 'babel_sp_helpdb_db');
GO

-- Executing sp_helpdb with already existing dbname as an input
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('master');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('babel_sp_helpdb_db');
GO

-- Executing sp_helpdb with wrong input
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('abc');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('  wrongInput');
GO

-- Executing sp_helpdb with a existing dbname but in mixed upper, lower cases as an input
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('MaSteR');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('bAbeL_sP_helPdb_Db');
GO

-- Executing sp_helpdb with a existing dbname but end with trailing spaces as an input
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('MaSteR        ');
GO
SELECT name, db_size, owner, status, compatibility_level FROM sys.babelfish_helpdb('bAbeL_sP_helPdb_Db ');
GO

