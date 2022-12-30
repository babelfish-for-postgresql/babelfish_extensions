-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.4.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int8(In arg sys.fixeddecimal)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT8);
END;
$$ LANGUAGE plpgsql STABLE;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int4(In arg sys.fixeddecimal)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT4);
END;
$$ LANGUAGE plpgsql STABLE;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int2(In arg sys.fixeddecimal)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT2);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int8
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int8(In arg numeric)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT8);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int4
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int4(In arg numeric)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT4);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int2
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int2(In arg numeric)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT2);
END;
$$ LANGUAGE plpgsql STABLE;

create or replace function sys.CHAR(x in int)returns char
AS
$body$
BEGIN
/***************************************************************
EXTENSION PACK function CHAR(x)
***************************************************************/
    if x between 1 and 255 then
        return chr(x);
    else
        return null;
    end if;
END;
$body$
language plpgsql STABLE;

-- Wrap built-in CONCAT function to accept two text arguments.
-- This is necessary because CONCAT accepts arguments of type VARIADIC "any". 
-- CONCAT also automatically handles NULL which || does not.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) RETURNS TEXT AS
$$
  SELECT
    CASE WHEN (current_setting('babelfishpg_tsql.concat_null_yields_null') = 'on') THEN
      CASE
        WHEN leftarg IS NULL OR rightarg IS NULL THEN NULL
        ELSE CONCAT(leftarg, rightarg)
      END
      ELSE
        CONCAT(leftarg, rightarg)
    END
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper_outer(leftarg text, rightarg text) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = sys.babelfish_concat_wrapper_outer
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.varchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.varchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.bpchar, rightarg sys.bpchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.bpchar,
    RIGHTARG = sys.bpchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nchar, rightarg sys.nchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nchar,
    RIGHTARG = sys.nchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

-- if one of input is nvarchar, resolve it as nvarchar. as varchar is a base type of nvarchar, we need to define this function explictly.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.varchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.varchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.tinyintxor(leftarg sys.tinyint, rightarg sys.tinyint)
RETURNS sys.tinyint
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS sys.tinyint);
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = sys.tinyint,
    RIGHTARG = sys.tinyint,
    FUNCTION = sys.tinyintxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int2xor(leftarg int2, rightarg int2)
RETURNS int2
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS int2);
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int2,
    RIGHTARG = int2,
    FUNCTION = sys.int2xor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.intxor(leftarg int4, rightarg int4)
RETURNS int4
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(32)),
                    CAST(rightarg AS pg_catalog.bit(32))) AS int4)
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int4,
    RIGHTARG = int4,
    FUNCTION = sys.intxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int8xor(leftarg int8, rightarg int8)
RETURNS int8
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(64)),
                    CAST(rightarg AS pg_catalog.bit(64))) AS int8)
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int8,
    RIGHTARG = int8,
    FUNCTION = sys.int8xor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.bitxor(leftarg pg_catalog.bit, rightarg pg_catalog.bit)
RETURNS pg_catalog.bit
AS $$
SELECT (leftarg & ~rightarg) | (~leftarg & rightarg);
$$
LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION sys.newid()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4' -- uuid-ossp was added as dependency
LANGUAGE C STABLE STRICT PARALLEL SAFE;

/*
 * in tsql, NEWSEQUENTIALID() produces a new unique value
 * greater than a sequence of previous values. Since PG does not
 * have this capability, we will reuse the NEWID() functionality and be
 * aware of the functional shortcoming
 */
CREATE OR REPLACE FUNCTION sys.NEWSEQUENTIALID()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4'
LANGUAGE C STABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.datetime_sqlvariant(sys.DATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetime2sqlvariant'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetime_sqlvariant (sys.DATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smalldatetime_sqlvariant(sys.SMALLDATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smalldatetime2sqlvariant'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.SMALLDATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.smalldatetime_sqlvariant (sys.SMALLDATETIME) AS IMPLICIT;

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

CREATE OR REPLACE FUNCTION sys.babelfish_typecode_list()
RETURNS table (
  oid int,
  pg_namespace text,
  pg_typname text,
  tsql_typname text,
  type_family_priority smallint,
  priority smallint,
  sql_variant_hdr_size smallint
) AS 'babelfishpg_common', 'typecode_list' LANGUAGE C STABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);