-- schema id is not a stable value, test nullability instead
USE master
GO

SELECT CASE WHEN schema_id('dbo') IS NULL then 'is null' ELSE 'not null' END;
GO

USE tempdb
GO

SELECT CASE WHEN schema_id('dbo') IS NULL then 'is null' ELSE 'not null' END;
GO

USE msdb
GO

SELECT CASE WHEN schema_id('dbo') IS NULL then 'is null' ELSE 'not null' END;
GO

USE master
GO
