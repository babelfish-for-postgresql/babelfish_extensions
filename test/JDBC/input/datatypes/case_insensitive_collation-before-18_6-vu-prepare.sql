-- BABEL-3094
-- sys table and view columns need to have the correct output type and collation
create table t_rcv15 ([Test] varchar);
go

CREATE TABLE CaMeLtAbLe(cAmElCoLuMn VARCHAR(100) NOT NULL);
go

CREATE VIEW CaMeLvIeW AS SELECT 'VIEW' + cAmElCoLuMn + 'VIEW' AS CaMeLcOlUmNiNvIeW FROM CaMeLtAbLe;
go

-- BABEL-3165
-- sys.databases.name should have case-insensitive collation
create database TEST;
go

-- BABEL-3323
-- When any sys view contains collatable constants
create view vB as ( SELECT CASE WHEN 'b' = 'B' THEN 'case-insensitive' ELSE 'case-sensitive' END);
go

-- [BABEL-3217]
-- The T-SQL version of information_schema.tables needs to display TABLE_NAME
-- as lowercase for matching with sys.objects
CREATE TABLE [MyTable] ( [Col1] INT, [Col2] INT );
go

-- [BABEL-526]
-- When creating an UDD and then using it for a column datatype,
-- before fix, it used to show error 'type "dbo.mytyp6" does not exist
create type [dbo].[myTyp6] from int;
go
