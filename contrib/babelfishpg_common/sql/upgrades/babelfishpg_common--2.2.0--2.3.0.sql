-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.babelfishpg_common_get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_common', 'get_babel_server_collation_oid';

update pg_catalog.pg_type set typcollation = sys.babelfishpg_common_get_babel_server_collation_oid()
where typname in ('varchar', 'bpchar', 'nvarchar', 'nchar', 'sql_variant', '_ci_sysname', 'sysname', '_varchar', '_bpchar', '_nvarchar', '_nchar', '_sql_variant', '__ci_sysname', '_sysname') and typnamespace = (select oid from pg_namespace where nspname = 'sys');

CREATE OR REPLACE FUNCTION sys.bigint_sum(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_sum(BIGINT)
RETURNS INT
AS 'babelfishpg_common' , 'int4int2_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.sum(BIGINT) (
SFUNC = int8_avg_accum,
FINALFUNC = bigint_sum,
STYPE = INTERNAL,
COMBINEFUNC = int8_avg_combine,
SERIALFUNC = int8_avg_serialize,
DESERIALFUNC = int8_avg_deserialize,
PARALLEL = SAFE
);


CREATE OR REPLACE AGGREGATE sys.sum(INT)(
SFUNC = int4_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.sum(SMALLINT)(
SFUNC = int2_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.sum(TINYINT)(
SFUNC = int2_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

-- int8 -> money
CREATE FUNCTION sys.int8_to_money(INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int8_to_money'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- int8 -> smallmoney
CREATE FUNCTION sys.int8_to_smallmoney(INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8_to_smallmoney'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- datetime +/- operators (datetime, int4, float8)
CREATE OR REPLACE FUNCTION sys.datetime_add(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime_minus(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.datetime_add
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.datetime_minus
);

-- smalldatetime +/- operators (smalldatetime, int4, float8
CREATE OR REPLACE FUNCTION sys.smalldatetime_add(sys.smalldatetime, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_pl_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime_minus(sys.smalldatetime, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_mi_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = sys.smalldatetime,
    PROCEDURE  = sys.smalldatetime_add
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = sys.smalldatetime,
    PROCEDURE  = sys.smalldatetime_minus
);

-- cast to DATETIME
-- cast BIT to DATETIME
CREATE OR REPLACE FUNCTION sys.bit2datetime(IN num sys.BIT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + (CASE WHEN num != 0 THEN 1 ELSE 0 END);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast NUMERIC to DATETIME & cast DECIMAL to DATETIME
CREATE OR REPLACE FUNCTION sys.numeric2datetime(IN num NUMERIC)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast REAL to DATETIME
CREATE OR REPLACE FUNCTION sys.float4datetime(IN num FLOAT4)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast BIGINT to DATETIME
CREATE OR REPLACE FUNCTION sys.bigint2datetime(IN num BIGINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast SMALLINT to DATETIME & cast TINYINT to DATETIME
CREATE OR REPLACE FUNCTION sys.smallint2datetime(IN num SMALLINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast MONEY to DATETIME & cast SMALLMONEY to DATETIME
CREATE OR REPLACE FUNCTION sys.money2datetime(IN num FIXEDDECIMAL)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- cast to SMALLDATETIME
-- cast BIT to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.bit2smalldatetime(IN num sys.BIT)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + (CASE WHEN num != 0 THEN 1 ELSE 0 END);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS sys.SMALLDATETIME)
WITH FUNCTION sys.bit2smalldatetime (sys.BIT) AS IMPLICIT;

-- cast NUMERIC to SMALLDATETIME & cast DECIMAL to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.numeric2smalldatetime(IN num NUMERIC)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.SMALLDATETIME)
WITH FUNCTION sys.numeric2smalldatetime (NUMERIC) AS IMPLICIT;

-- cast FLOAT to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.float8smalldatetime(IN num FLOAT8)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT8 AS sys.SMALLDATETIME)
WITH FUNCTION sys.float8smalldatetime (FLOAT8) AS IMPLICIT;

-- cast REAL to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.float4smalldatetime(IN num FLOAT4)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT4 AS sys.SMALLDATETIME)
WITH FUNCTION sys.float4smalldatetime (FLOAT4) AS IMPLICIT;

-- cast INT to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.int2smalldatetime(IN num INT)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT AS sys.SMALLDATETIME)
WITH FUNCTION sys.int2smalldatetime (INT) AS IMPLICIT;

-- cast BIGINT to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.bigint2smalldatetime(IN num BIGINT)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (BIGINT AS sys.SMALLDATETIME)
WITH FUNCTION sys.bigint2smalldatetime (BIGINT) AS IMPLICIT;

-- cast SMALLINT to DATETIME & cast TINYINT to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.smallint2smalldatetime(IN num SMALLINT)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (SMALLINT AS sys.SMALLDATETIME)
WITH FUNCTION sys.smallint2smalldatetime (SMALLINT) AS IMPLICIT;

-- cast MONEY to DATETIME & cast SMALLMONEY to SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.money2smalldatetime(IN num FIXEDDECIMAL)
RETURNS sys.SMALLDATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00' AS sys.SMALLDATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS sys.SMALLDATETIME)
WITH FUNCTION sys.money2smalldatetime (FIXEDDECIMAL) AS IMPLICIT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
