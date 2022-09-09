-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime2(sys.SQL_VARIANT)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'sqlvariant2datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarchar(sys.nvarchar, integer, boolean)
RETURNS sys.nvarchar
AS 'babelfishpg_common', 'nvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar(sys.nchar, integer, boolean)
RETURNS sys.nchar
AS 'babelfishpg_common', 'nchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- cast BIT to DATETIME
CREATE OR REPLACE FUNCTION sys.bit2datetime(IN num sys.BIT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS sys.DATETIME)
WITH FUNCTION sys.bit2datetime (sys.BIT) AS IMPLICIT;

-- cast NUMERIC to DATETIME & cast DECIMAL to DATETIME
CREATE OR REPLACE FUNCTION sys.numeric2datetime(IN num NUMERIC)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.DATETIME)
WITH FUNCTION sys.numeric2datetime (NUMERIC) AS IMPLICIT;

-- cast FLOAT to DATETIME
CREATE OR REPLACE FUNCTION sys.float8datetime(IN num FLOAT8)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT8 AS sys.DATETIME)
WITH FUNCTION sys.float8datetime (FLOAT8) AS IMPLICIT;

-- cast REAL to DATETIME
CREATE OR REPLACE FUNCTION sys.float4datetime(IN num FLOAT4)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT4 AS sys.DATETIME)
WITH FUNCTION sys.float4datetime (FLOAT4) AS IMPLICIT;

-- cast INT to DATETIME
CREATE OR REPLACE FUNCTION sys.int2datetime(IN num INT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT AS sys.DATETIME)
WITH FUNCTION sys.int2datetime (INT) AS IMPLICIT;

-- cast BIGINT to DATETIME
CREATE OR REPLACE FUNCTION sys.bigint2datetime(IN num BIGINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (BIGINT AS sys.DATETIME)
WITH FUNCTION sys.bigint2datetime (BIGINT) AS IMPLICIT;

-- cast SMALLINT to DATETIME & cast TINYINT to DATETIME
CREATE OR REPLACE FUNCTION sys.smallint2datetime(IN num SMALLINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (SMALLINT AS sys.DATETIME)
WITH FUNCTION sys.smallint2datetime (SMALLINT) AS IMPLICIT;

-- cast MONEY to DATETIME & cast SMALLMONEY to DATETIME
CREATE OR REPLACE FUNCTION sys.money2datetime(IN num FIXEDDECIMAL)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS sys.DATETIME)
WITH FUNCTION sys.money2datetime (FIXEDDECIMAL) AS IMPLICIT;

-- Problem: Nullable DATETIME column does not store NULL
-- Solution: Setting typdefault to NULL for datetime, smalldatetime,
-- datetime2, datetimeoffset datatypes in pg_type table

UPDATE pg_type SET typdefault = null WHERE typname = 'smalldatetime' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime2' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetimeoffset' AND typname IN (SELECT name FROM sys.types);

CREATE OPERATOR sys.~ (
    RIGHTARG   = sys.BIT,
    PROCEDURE  = sys.bitneg
);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
