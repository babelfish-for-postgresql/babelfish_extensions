SELECT * FROM sys.configurations;
GO

SELECT * FROM sys.syscurconfigs;
GO

CREATE DATABASE DB1;
GO

-- syscurconfigs should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
select * from dbo.    SySCuRConFIgS;
go

-- In case of cross-db, syscurconfigs should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT * FROM db1.sys.     SySCuRConFIgS;
GO

SELECT * FROM db1.dbo.     SySCuRConFIgS;
GO

SELECT * FROM sys.sysconfigures;
GO

-- sysconfigures should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
select * from dbo.    SySConFIGuReS;
go

-- In case of cross-db, sysconfigures should also exist in dbo schema
-- If there are white spaces between schema name and catalog name then those need to be ignored
-- case insensitive check
SELECT * FROM db1.sys.     SySConFIGuReS;
GO

SELECT * FROM db1.dbo.     SySConFIGuReS;
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

DROP DATABASE DB1;
GO
