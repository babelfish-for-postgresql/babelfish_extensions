-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime2(sys.SQL_VARIANT)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'sqlvariant2datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
