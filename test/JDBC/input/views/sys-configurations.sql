SELECT * FROM sys.configurations;
GO

SELECT * FROM sys.syscurconfigs;
GO

-- syscurconfigs should also exist in dbo schema
select * from dbo.SySCuRConFIgS;
go

CREATE DATABASE DB1;
GO

-- In case of cross-db, syscurconfigs should also exist in dbo schema
SELECT * FROM db1.sys.SySCuRConFIgS;
GO

SELECT * FROM db1.dbo.SySCuRConFIgS;
GO

SELECT * FROM sys.sysconfigures;
GO

-- sysconfigures should also exist in dbo schema
select * from dbo.SySConFIGuReS;
go

-- In case of cross-db, sysconfigures should also exist in dbo schema
SELECT * FROM db1.sys.SySConFIGuReS;
GO

SELECT * FROM db1.dbo.SySConFIGuReS;
GO

SELECT * FROM sys.babelfish_configurations;
GO

INSERT INTO sys.babelfish_configurations
     VALUES (1234,
             'testing',
             1,
             0,
             0,
             1,
             'asdf',
             sys.bitin('1'),
             sys.bitin('0'),
             'testing',
             'testing'
             );
GO

-- These below test cases are just to validate the schema rewrite from dbo to sys in different scenarios.
select (select count(*) from DbO.SySConFIGuReS) as x, (select count(*) from [DbO].SySCuRConFIgS) as y;
go

select count(*) from DbO.SySConFIGuReS x inner join [DbO].SySCuRConFIgS y on x.value=y.value;
go

DROP DATABASE DB1;
GO
