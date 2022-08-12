-- Tests for sys.columns catalog view
-- Test precision and scale for all numeric datatypes
create table sys_columns_vu_prepare_t1(a int, b float, c bigint, d numeric, e smallint, f tinyint, g decimal, h money, i smallmoney);
go

-- Test identity and computed columns
create table sys_columns_vu_prepare_t2(a int, b int IDENTITY(1,1), c as a * b);
GO

-- Test ansi padded columns
create table sys_columns_vu_prepare_t3(a char(10), b nchar(10), c binary(10));
go

-- Test collation name
create table sys_columns_vu_prepare_t4(
        c1 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AI,
        c2 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS,
        c3 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CS_AI,
        c4 char(10) COLLATE SQL_LATIN1_GENERAL_CP1_CS_AS,
        c5 char(10) COLLATE SQL_LATIN1_GENERAL_CP1250_CI_AS
);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

CREATE TABLE sys_columns_vu_prepare_test_columns (
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


EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

CREATE TABLE sys_columns_vu_prepare_t5(c1 datetime2(0)
                , c2 datetime2(7)
                , c3 datetimeoffset(0)
                , c4 datetimeoffset(7)
                , c5 time(0)
                , c6 time(7))

CREATE TYPE sys_columns_vu_prepare_type1 FROM INT NOT NULL
GO

CREATE TABLE sys_columns_vu_prepare_t6( c1 sys_columns_vu_prepare_type1, c2 int)
GO

create type sys_columns_vu_prepare_varchar_max from varchar(max)
create type sys_columns_vu_prepare_nvarchar_max from nvarchar(max)
create type sys_columns_vu_prepare_varbinary_max from varbinary(max)
GO

create table sys_columns_vu_prepare_babel_2947 (a sys_columns_vu_prepare_varchar_max
                        , b varchar(max)
                        , c varchar(10)
                        , d sys_columns_vu_prepare_nvarchar_max
                        , e nvarchar(max)
                        , f nvarchar(10)
                        , g sys_columns_vu_prepare_varbinary_max
                        , h varbinary(max)
                        , i varbinary(10))
GO
