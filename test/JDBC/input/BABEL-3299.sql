SELECT COUNT(*) FROM ::fn_helpcollations() where [Name] = DATABASEPROPERTYEX(DB_NAME(), 'Collation')
GO

SELECT * FROM ::isnull(NULL, 0)
GO

SELECT * FROM isnull(NULL, 0)
GO

SELECT * FROM ::
GO
