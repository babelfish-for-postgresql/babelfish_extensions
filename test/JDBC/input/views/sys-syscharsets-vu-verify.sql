USE master
go

select * from sys.syscharsets;
go

-- syscharsets should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
select * from dbo.    SySChaRSets;
go

CREATE DATABASE DB1;
GO

-- In case of cross-db, syscharsets should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT * FROM db1.dbo.     SySChaRSets;
GO

DROP DATABASE DB1;
GO
