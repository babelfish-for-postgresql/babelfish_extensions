-- BABEL-3094
-- sys table and view columns need to have the correct output type and collation
create table test ([Test] varchar);
go

select name from sys.columns where name = 'Test';
go

select name from sys.columns where name = 'TesT';
go

DROP table if exists test;
go

CREATE TABLE CaMeLtAbLe(cAmElCoLuMn VARCHAR(100) NOT NULL);
go

CREATE VIEW CaMeLvIeW AS SELECT 'VIEW' + cAmElCoLuMn + 'VIEW' AS CaMeLcOlUmNiNvIeW FROM CaMeLtAbLe;
go

select COUNT(*) FROM sys.tables WHERE name = 'cameltable';
go

select COUNT(*) FROM sys.tables WHERE name = 'CAMELTABLE';
go

select COUNT(*) FROM sys.tables WHERE name = 'CaMeLtAbLe';
go

SELECT COUNT(*) FROM sys.columns WHERE name = 'cAmElCoLuMn';
go

select COUNT(*) FROM sys.views WHERE name = 'CAMELview';
go

DROP view if exists CaMeLvIeW;
go

DROP table if exists CaMeLtAbLe;
go

-- BABEL-3165
-- sys.databases.name should have case-insensitive collation
create database TEST;
go

select name from sys.databases where name = 'test';
go

select name from sys.databases where name = 'TEST';
go

drop database if exists TEST;
go

-- BABEL-3323
-- When any sys view contains collatable constants
create view vB as ( SELECT CASE WHEN 'b' = 'B' THEN 'case-insensitive' ELSE 'case-sensitive' END);
go

select * from vB;
go

drop view if exists vB;
go

-- [BABEL-526]
-- When creating an UDD and then using it for a column datatype,
-- before fix, it used to show error 'type "dbo.mytyp6" does not exist
create type [dbo].[myTyp6] from int;
go

create table t_rcv16 (a [dbo].[myTyp6]);
go

create table t_rcv17(a dbo.myTyp6);
go

drop table if exists t_rcv17;
go

drop table if exists t_rcv16;
go

drop type if exists [dbo].[myTyp6];
go

-- [BABEL-3217]
-- The T-SQL version of information_schema.tables needs to display TABLE_NAME
-- as lowercase for matching with sys.objects
CREATE TABLE [MyTable] ( [Col1] INT, [Col2] INT );
go

SELECT t.TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES AS t
JOIN sys.objects o ON t.TABLE_NAME = o.name where o.name = 'mytable' AND o.object_id != 0;
go

drop table if exists [MyTable];
go

-- [BABEL-2981]
-- sys.sysname and other string types in Babelfish need to have the correct collation
select typ.typname, coll.collname from pg_type typ join pg_collation coll on typ.typcollation = coll.oid where typnamespace = (select oid from pg_namespace where nspname = 'sys');
go
