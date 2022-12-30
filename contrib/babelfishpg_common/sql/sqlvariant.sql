CREATE TYPE sys.SQL_VARIANT;

CREATE OR REPLACE FUNCTION sys.sqlvariantin(cstring, oid, integer)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sqlvariantin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantout(sys.SQL_VARIANT)
RETURNS cstring
AS 'babelfishpg_common', 'sqlvariantout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantrecv(internal, oid, integer)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sqlvariantrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantsend(sys.SQL_VARIANT)
RETURNS bytea
AS 'babelfishpg_common', 'sqlvariantsend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.SQL_VARIANT (
    INPUT          = sys.sqlvariantin,
    OUTPUT         = sys.sqlvariantout,
    RECEIVE        = sys.sqlvariantrecv,
    SEND           = sys.sqlvariantsend,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT      = 'int4',
    STORAGE        = 'extended',
    CATEGORY       = 'U',
    PREFERRED      = false,
    COLLATABLE     = true
);

-- DATALENGTH function for SQL_VARIANT
CREATE OR REPLACE FUNCTION sys.datalength(sys.SQL_VARIANT)
RETURNS integer
AS 'babelfishpg_common', 'datalength_sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- CAST FUNCTIONS to SQL_VARIANT

-- cast functions from domain types are overloaded such that we support casts both in pg and tsql:
-- money/smallmoney, smallint/tinyint, varchar/nvarchar, char/nchar
-- in pg, we will have minimal support of casts since domains are not distinguished
-- in tsql, we will allow domain casts in coerce.sql such that exact type info are saved
-- this is required for sql_variant since we may call sql_variant_property() to retrieve base type

CREATE OR REPLACE FUNCTION sys.datetime_sqlvariant(sys.DATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetime2sqlvariant'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetime_sqlvariant (sys.DATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.datetime2_sqlvariant(sys.DATETIME2)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetime22sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME2 AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetime2_sqlvariant (sys.DATETIME2) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.datetimeoffset_sqlvariant(sys.DATETIMEOFFSET)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetimeoffset2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIMEOFFSET AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetimeoffset_sqlvariant (sys.DATETIMEOFFSET) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smalldatetime_sqlvariant(sys.SMALLDATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smalldatetime2sqlvariant'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SMALLDATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.smalldatetime_sqlvariant (sys.SMALLDATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.date_sqlvariant(DATE)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'date2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS sys.SQL_VARIANT)
WITH FUNCTION sys.date_sqlvariant (DATE) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.time_sqlvariant(TIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'time2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (TIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.time_sqlvariant (TIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.float_sqlvariant(FLOAT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'float2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT AS sys.SQL_VARIANT)
WITH FUNCTION sys.float_sqlvariant (FLOAT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.real_sqlvariant(REAL)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'real2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (REAL AS sys.SQL_VARIANT)
WITH FUNCTION sys.real_sqlvariant (REAL) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.numeric_sqlvariant(NUMERIC)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'numeric2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.SQL_VARIANT)
WITH FUNCTION sys.numeric_sqlvariant (NUMERIC) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.money_sqlvariant(FIXEDDECIMAL)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'money2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.money_sqlvariant(sys.money)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'money2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smallmoney_sqlvariant(sys.smallmoney)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallmoney2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS sys.SQL_VARIANT)
WITH FUNCTION sys.money_sqlvariant (FIXEDDECIMAL) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bigint_sqlvariant(BIGINT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bigint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (BIGINT AS sys.SQL_VARIANT)
WITH FUNCTION sys.bigint_sqlvariant (BIGINT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.int_sqlvariant(INT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'int2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT AS sys.SQL_VARIANT)
WITH FUNCTION sys.int_sqlvariant (INT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smallint_sqlvariant(SMALLINT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smallint_sqlvariant(smallint)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tinyint_sqlvariant(sys.tinyint)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'tinyint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (SMALLINT AS sys.SQL_VARIANT)
WITH FUNCTION sys.smallint_sqlvariant (SMALLINT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit_sqlvariant(sys.BIT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bit2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS sys.SQL_VARIANT)
WITH FUNCTION sys.bit_sqlvariant (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar_sqlvariant(sys.varchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'varchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarchar_sqlvariant(sys.nvarchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'nvarchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.varchar_sqlvariant (sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar_sqlvariant(pg_catalog.varchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'varchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.varchar_sqlvariant (pg_catalog.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.char_sqlvariant(CHAR)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'char2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar_sqlvariant(sys.nchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'nchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.char_sqlvariant (CHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.char_sqlvariant(sys.BPCHAR)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'char2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.char_sqlvariant (sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bbfvarbinary_sqlvariant(sys.BBF_VARBINARY)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bbfvarbinary2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.SQL_VARIANT)
WITH FUNCTION sys.bbfvarbinary_sqlvariant (sys.BBF_VARBINARY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bbfbinary_sqlvariant(sys.BBF_BINARY)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bbfbinary2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.SQL_VARIANT)
WITH FUNCTION sys.bbfbinary_sqlvariant (sys.BBF_BINARY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.uniqueidentifier_sqlvariant(sys.UNIQUEIDENTIFIER)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'uniqueidentifier2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER AS sys.SQL_VARIANT)
WITH FUNCTION sys.uniqueidentifier_sqlvariant (sys.UNIQUEIDENTIFIER) AS IMPLICIT;

-- CAST functions from SQL_VARIANT

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime(sys.SQL_VARIANT)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'sqlvariant2timestamp'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIME)
WITH FUNCTION sys.sqlvariant_datetime (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime2(sys.SQL_VARIANT)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'sqlvariant2datetime2'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIME2)
WITH FUNCTION sys.sqlvariant_datetime2 (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetimeoffset(sys.SQL_VARIANT)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'sqlvariant2datetimeoffset'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.sqlvariant_datetimeoffset (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smalldatetime(sys.SQL_VARIANT)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'sqlvariant2timestamp'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.SMALLDATETIME)
WITH FUNCTION sys.sqlvariant_smalldatetime (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_date(sys.SQL_VARIANT)
RETURNS DATE
AS 'babelfishpg_common', 'sqlvariant2date'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS DATE)
WITH FUNCTION sys.sqlvariant_date (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_time(sys.SQL_VARIANT)
RETURNS TIME
AS 'babelfishpg_common', 'sqlvariant2time'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS TIME)
WITH FUNCTION sys.sqlvariant_time (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_float(sys.SQL_VARIANT)
RETURNS FLOAT
AS 'babelfishpg_common', 'sqlvariant2float'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS FLOAT)
WITH FUNCTION sys.sqlvariant_float (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_real(sys.SQL_VARIANT)
RETURNS REAL
AS 'babelfishpg_common', 'sqlvariant2real'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS REAL)
WITH FUNCTION sys.sqlvariant_real (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_numeric(sys.SQL_VARIANT)
RETURNS NUMERIC
AS 'babelfishpg_common', 'sqlvariant2numeric'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS NUMERIC)
WITH FUNCTION sys.sqlvariant_numeric (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_money(sys.SQL_VARIANT)
RETURNS sys.MONEY
AS 'babelfishpg_common', 'sqlvariant2fixeddecimal'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smallmoney(sys.SQL_VARIANT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'sqlvariant2fixeddecimal'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS FIXEDDECIMAL)
WITH FUNCTION sys.sqlvariant_money (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bigint(sys.SQL_VARIANT)
RETURNS BIGINT
AS 'babelfishpg_common', 'sqlvariant2bigint'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS BIGINT)
WITH FUNCTION sys.sqlvariant_bigint (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_int(sys.SQL_VARIANT)
RETURNS INT
AS 'babelfishpg_common', 'sqlvariant2int'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS INT)
WITH FUNCTION sys.sqlvariant_int (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smallint(sys.SQL_VARIANT)
RETURNS SMALLINT
AS 'babelfishpg_common', 'sqlvariant2smallint'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_tinyint(sys.SQL_VARIANT)
RETURNS sys.TINYINT
AS 'babelfishpg_common', 'sqlvariant2smallint'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS SMALLINT)
WITH FUNCTION sys.sqlvariant_smallint (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bit(sys.SQL_VARIANT)
RETURNS sys.BIT
AS 'babelfishpg_common', 'sqlvariant2bit'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BIT)
WITH FUNCTION sys.sqlvariant_bit (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_sysvarchar(sys.SQL_VARIANT)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.VARCHAR)
WITH FUNCTION sys.sqlvariant_sysvarchar (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_varchar(sys.SQL_VARIANT)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS pg_catalog.VARCHAR)
WITH FUNCTION sys.sqlvariant_varchar (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_nvarchar(sys.SQL_VARIANT)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_char(sys.SQL_VARIANT)
RETURNS CHAR
AS 'babelfishpg_common', 'sqlvariant2char'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_nchar(sys.SQL_VARIANT)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'sqlvariant2char'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS CHAR)
WITH FUNCTION sys.sqlvariant_char (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bbfvarbinary(sys.SQL_VARIANT)
RETURNS sys.VARBINARY
AS 'babelfishpg_common', 'sqlvariant2bbfvarbinary'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BBF_VARBINARY)
WITH FUNCTION sys.sqlvariant_bbfvarbinary (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bbfbinary(sys.SQL_VARIANT)
RETURNS sys.BINARY
AS 'babelfishpg_common', 'sqlvariant2bbfbinary'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BBF_BINARY)
WITH FUNCTION sys.sqlvariant_bbfbinary (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_uniqueidentifier(sys.SQL_VARIANT)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'sqlvariant2uniqueidentifier'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.sqlvariant_uniqueidentifier (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.SQL_VARIANT_PROPERTY(sys.SQL_VARIANT, sys.VARCHAR(20))
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sql_variant_property'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvarianteq(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvarianteq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantne(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantlt(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantle(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantgt(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantgt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantge(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.sqlvarianteq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.sqlvariantne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.sqlvariantlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.sqlvariantle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.sqlvariantgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.SQL_VARIANT,
    RIGHTARG   = sys.SQL_VARIANT,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.sqlvariantge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE FUNCTION  sqlvariant_cmp(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS INT4
AS 'babelfishpg_common', 'sqlvariant_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION  sqlvariant_hash(sys.SQL_VARIANT)
RETURNS INT4
AS 'babelfishpg_common', 'sqlvariant_hash'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.sqlvariant_ops
DEFAULT FOR TYPE sys.SQL_VARIANT USING btree AS
    OPERATOR    1   <  (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR    2   <= (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR    3   =  (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR    4   >= (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR    5   >  (sys.SQL_VARIANT, sys.SQL_VARIANT),
    FUNCTION    1   sqlvariant_cmp(sys.SQL_VARIANT, sys.SQL_VARIANT);

CREATE OPERATOR CLASS sys.sqlvariant_ops
DEFAULT FOR TYPE sys.SQL_VARIANT USING hash AS
    OPERATOR    1   =  (sys.SQL_VARIANT, sys.SQL_VARIANT),
    FUNCTION    1   sqlvariant_hash(sys.SQL_VARIANT);
