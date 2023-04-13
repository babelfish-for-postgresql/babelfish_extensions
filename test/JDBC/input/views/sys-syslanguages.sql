SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.syslanguages');
GO

SELECT * FROM sys.syslanguages WHERE langid = 1;
GO

-- syslanguages should also exist in dbo schema
select * from dbo.SySLanGUAgeS WHERE langid = 1;
go

CREATE DATABASE DB1;
GO

-- In case of cross-db, syslanguages should also exist in dbo schema
SELECT * FROM db1.sys.SySLanGUAgeS WHERE langid = 1;
GO

SELECT * FROM db1.dbo.SySLanGUAgeS WHERE langid = 1;
GO

-- These below test cases are just to validate the schema rewrite from dbo to sys in different scenarios.
select * from DbO.SySLanGUAgeS where langid = (SELECT count(*) FROM DbO.syslanguages WHERE langid = 1);
go

DROP DATABASE DB1;
GO
