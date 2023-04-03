-- sla 13000
create database db1;
go

use db1;
go

-- create helper function to get datatype name given oid
CREATE FUNCTION OidToDataType(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @datatype VARCHAR(50);
        SET @datatype = (SELECT typname from pg_type where oid = @Oid);
        RETURN @datatype;
END;
GO

-- create helper function to get procedure/table name given oid
CREATE FUNCTION OidToObject(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @object_name VARCHAR(50);

        SET @object_name = (SELECT relname from pg_class where oid = @Oid);

        IF (@object_name is null)
        BEGIN
                SET @object_name = (SELECT proname from pg_proc where oid = @Oid);
        END

        RETURN @object_name
END;
GO

-- create helper function to get collation name given oid
CREATE FUNCTION OidToCollation(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @collation VARCHAR(50);
        SET @collation = (SELECT collname from pg_collation where oid = @Oid);
        RETURN @collation;
END;
GO

-- Setup some procedures and tables
create procedure syscolumns_demo_proc1 @firstparam NVARCHAR(50) as select 1
GO

create procedure syscolumns_demo_proc2 @firstparam NVARCHAR(50), @secondparam VARCHAR(50) OUT as select 2
GO

create table syscolumns_demo_table (col_a int, col_b bigint, col_c char(10), col_d numeric(5,4))
GO

select name, OidToObject(id), OidToDataType(xtype), typestat, length from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select name, OidToObject(id), OidToDataType(xtype), typestat, length from dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select colid, cdefault, domain, number from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select colid, cdefault, domain, number from dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select OidToCollation(collationid), status, OidToDataType(type), prec, scale from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select OidToCollation(collationid), status, OidToDataType(type), prec, scale from dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select iscomputed, isoutparam, isnullable, collation from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select iscomputed, isoutparam, isnullable, collation from dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

SELECT COUNT(*) FROM dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

use master;
go

create procedure syscolumns_demo_proc3 @thirdparam NVARCHAR(50) as select 3;
go

SELECT COUNT(*) FROM sys.syscolumns where name = '@thirdparam'
go

-- syscolumns should also exist in dbo schema
SELECT COUNT(*) FROM dbo.SySCOluMNs where name = '@thirdparam';
go

SELECT COUNT(*) FROM db1.sys.SySCOluMNs where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

-- In case of cross-db, syscolumns should also exist in dbo schema
-- Cross-DB view query is not supported yet in Babelfish.
SELECT COUNT(*) FROM db1.DbO.SySCOluMNs where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

-- should not be visible here
SELECT COUNT(*) FROM db1.sys.SySCOluMNs where name = '@thirdparam';
GO

SELECT COUNT(*) FROM db1.dbo.SySCOluMNs where name = '@thirdparam';
GO

-- should not be visible here
SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

SELECT COUNT(*) FROM dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

use db1;
go

SELECT COUNT(*) FROM sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

SELECT COUNT(*) FROM dbo.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c'
go

-- should not be visible here
SELECT COUNT(*) FROM sys.syscolumns where name = '@thirdparam'
go

SELECT COUNT(*) FROM dbo.syscolumns where name = '@thirdparam'
go

-- Cleanup
DROP FUNCTION OidToDataType
DROP FUNCTION OidToObject
DROP FUNCTION OidToCollation
DROP PROCEDURE syscolumns_demo_proc1
DROP PROCEDURE syscolumns_demo_proc2
DROP TABLE syscolumns_demo_table
GO

use master;
go

drop database db1;
go

DROP PROCEDURE syscolumns_demo_proc3
go

-- Tests for sys.columns catalog view
-- Test precision and scale for all numeric datatypes
create table t1(a int, b float, c bigint, d numeric, e smallint, f tinyint, g decimal, h money, i smallmoney);
go
select name, column_id, precision, scale from sys.columns where object_id=OBJECT_ID('t1') order by name;
go

-- Test identity and computed columns
create table t2(a int, b int IDENTITY(1,1), c as a * b);
go
select name, column_id, is_identity, is_computed from sys.columns where object_id=OBJECT_ID('t2') order by name;
go

-- Test ansi padded columns
create table t3(a char(10), b nchar(10), c binary(10));
go
select name, column_id, is_ansi_padded from sys.columns where object_id=OBJECT_ID('t3') order by name;
go

-- Test collation name
create table t4(
        c1 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AI,
        c2 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS,
        c3 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CS_AI,
        c4 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CS_AS,
        c5 char(10) COLLATE SQL_LATIN1_GENERAL_CP1250_CI_AS
);
go
select name, column_id, collation_name from sys.columns where object_id=OBJECT_ID('t4') order by name;
go

-- Cleanup
drop table t1;
drop table t2;
drop table t3;
drop table t4;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

CREATE TABLE test_columns (
    c1  bigint  NOT NULL
    , c2    binary(123) NOT NULL
    , c3    bit NOT NULL
    , c4    char(123)   NOT NULL
    , c5    date    NOT NULL
    , c6    datetime    NOT NULL
    , c7    datetime2   NOT NULL
    , c8    datetimeoffset  NOT NULL
    , c9    decimal(8,4)    NOT NULL
    , c10   float   NOT NULL
    , c11   image   NOT NULL
    , c12   int NOT NULL
    , c13   money   NOT NULL
    , c14   nchar(123)  NOT NULL
    , c15   ntext   NOT NULL
    , c16   numeric(8,4)    NOT NULL
    , c17   nvarchar(123)   NOT NULL
    , c18   real    NOT NULL
    , c19   smalldatetime   NOT NULL
    , c20   smallint    NOT NULL
    , c21   smallmoney  NOT NULL
    , c22   sql_variant NOT NULL
    , c23   sysname NOT NULL
    , c24   text    NOT NULL
    , c25   time    NOT NULL
    , c27   tinyint NOT NULL
    , c28   uniqueidentifier    NOT NULL
    , c29   varbinary(123)  NOT NULL
    , c30   varchar(123)    NOT NULL
    , c31   xml NOT NULL
    , c32   rowversion)
GO

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('test_columns') order by name;
GO

drop table test_columns;
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

CREATE TABLE t1(c1 datetime2(0)
                , c2 datetime2(7)
                , c3 datetimeoffset(0)
                , c4 datetimeoffset(7)
                , c5 time(0)
                , c6 time(7))

select name,max_length,precision,scale from sys.columns where object_id = OBJECT_ID('t1') order by name;
GO

drop table t1;
GO

CREATE TYPE type1 FROM INT NOT NULL
GO
CREATE TABLE t1( c1 type1, c2 int)
GO

select count(*) from sys.columns where object_id = OBJECT_ID('t1') and system_type_id <> user_type_id
GO

select object_name(system_type_id), object_name(user_type_id) from sys.columns where object_id = OBJECT_ID('t1') order by object_name(user_type_id);
GO

drop table t1;
GO

drop type type1
GO

create type varchar_max from varchar(max)
create type nvarchar_max from nvarchar(max)
create type varbinary_max from varbinary(max)
GO

create table babel_2947 (a varchar_max
                        , b varchar(max)
                        , c varchar(10)
                        , d nvarchar_max
                        , e nvarchar(max)
                        , f nvarchar(10)
                        , g varbinary_max
                        , h varbinary(max)
                        , i varbinary(10))
GO

select name, max_length from sys.columns where object_id = OBJECT_ID('babel_2947') order by name;
GO

drop table babel_2947
GO

drop type varchar_max 
drop type nvarchar_max 
drop type varbinary_max 
GO

create table babel_2947 (a varchar(max)
                        , b varchar(10)
                        , c nvarchar(max)
                        , d nvarchar(10)
                        , e varbinary(max)
                        , f varbinary(10))
GO

exec sys.sp_describe_undeclared_parameters N'insert into babel_2947 (a,b,c,d,e,f) values (@a,@b,@c,@d,@e,@f)'
GO

drop table babel_2947
GO

