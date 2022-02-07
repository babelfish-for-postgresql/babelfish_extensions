CREATE DATABASE db1;
GO

USE db1
GO

CREATE TABLE rand_name1(rand_col1 int DEFAULT 1);
GO

SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name1';
GO

SELECT COUNT(*) FROM sys.columns WHERE name = 'rand_col1';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1%';
GO

USE master;
GO

#table rand_name1 should not be visible in master database.
SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name1';
GO

#column rand_col1 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name = 'rand_col1';
GO

#default constrain on rand_name1 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name1%';
GO

CREATE TABLE rand_name2(rand_col2 int DEFAULT 2);
GO

SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name2';
GO

SELECT COUNT(*) FROM sys.columns WHERE name = 'rand_col2';
GO

SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2%';
GO

USE db1
GO

#table rand_name2 should not be visible in db1 database.
SELECT COUNT(*) FROM sys.tables WHERE name = 'rand_name2';
GO

#column rand_col2 should not be visible here
SELECT COUNT(*) FROM sys.columns WHERE name = 'rand_col2';
GO

#default constrain on rand_name2 should not be visible here
SELECT COUNT(*) FROM sys.default_constraints WHERE name like '%rand_name2%';
GO

DROP TABLE rand_name1;
GO

USE master;
GO

DROP DATABASE db1;
GO

DROP TABLE rand_name2;
GO