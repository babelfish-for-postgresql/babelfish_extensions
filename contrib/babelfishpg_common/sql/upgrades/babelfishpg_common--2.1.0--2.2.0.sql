-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime2(sys.SQL_VARIANT)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'sqlvariant2datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

-- [BABEL-2769] Nullable DATETIME column does not store NULL
-- Solution: Setting typdefault to NULL for datetime, smalldatetime,
-- datetime2, datetimeoffset datatypes in pg_type table

UPDATE pg_type SET typdefault = null WHERE typname = 'smalldatetime';

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime';

UPDATE pg_type SET typdefault = null WHERE typname = 'datetime2';

UPDATE pg_type SET typdefault = null WHERE typname = 'datetimeoffset';

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
