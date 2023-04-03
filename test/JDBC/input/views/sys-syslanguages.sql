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

DROP DATABASE DB1;
GO
