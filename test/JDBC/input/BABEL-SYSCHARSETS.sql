USE master
go

select * from sys.syscharsets;
go

select * from dbo.SySChaRSets;
go

CREATE DATABASE DB1;
GO

-- In case of cross-db, syscharsets should also exist in dbo schema
SELECT * FROM db1.sys.SySChaRSets;
GO

SELECT * FROM db1.dbo.SySChaRSets;
GO

DROP DATABASE DB1;
GO
