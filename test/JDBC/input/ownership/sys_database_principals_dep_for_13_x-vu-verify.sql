SELECT * FROM database_principals_dep_for_13_x_vu_prepare_view
GO

EXEC database_principals_dep_for_13_x_vu_prepare_proc
GO

SELECT database_principals_dep_for_13_x_vu_prepare_func()
GO

SELECT name FROM sys.database_principals
WHERE name LIKE '%database_principals_dep_for_13_x_vu_prepare_%'
ORDER BY name
GO

