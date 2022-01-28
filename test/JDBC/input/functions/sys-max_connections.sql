SELECT * FROM sys.max_connections() 
GO

SET MAX_CONNECTIONS 3 --Should error out. Not possible for user to change.
GO

SELECT @@MAX_CONNECTIONS
GO

SELECT sys.max_connections() 
GO