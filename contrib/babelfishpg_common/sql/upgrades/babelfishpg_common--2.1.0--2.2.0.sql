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

-- [BABEL-2769] Nullable DATETIME column does not store NULL
-- Solution: Setting typdefault to NULL for datetime, smalldatetime,
-- datetime2, datetimeoffset datatypes in pg_type table

UPDATE pg_type SET typdefault = null WHERE typname = 'smalldatetime' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime2' AND typname IN (SELECT name FROM sys.types);

UPDATE pg_type SET typdefault = null WHERE typname = 'datetimeoffset' AND typname IN (SELECT name FROM sys.types);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
