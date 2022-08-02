SELECT HAS_DBACCESS('master');
GO

SELECT HAS_DBACCESS('does_not_exist');
GO

SELECT HAS_DBACCESS('has_dbaccess_prepare_db1');
GO

SELECT HAS_DBACCESS('has_dbaccess_prepare_db1   ');
GO

SELECT HAS_DBACCESS('   has_dbaccess_prepare_db1');
GO

DROP DATABASE has_dbaccess_prepare_db1;
GO

SELECT HAS_DBACCESS('has_dbaccess_prepare_db1');
GO

SELECT HAS_DBACCESS('babelfish_db');
GO
