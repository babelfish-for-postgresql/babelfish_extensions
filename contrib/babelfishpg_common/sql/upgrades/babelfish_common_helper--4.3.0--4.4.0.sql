------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.4.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- (sys.VARCHAR AS pg_catalog.TIME)
DROP CAST (sys.VARCHAR AS pg_catalog.TIME);

DROP FUNCTION sys.varchar2time(sys.VARCHAR);

CREATE OR REPLACE FUNCTION sys.varchar2time(sys.VARCHAR, INT4 DEFAULT -1)
RETURNS pg_catalog.TIME
AS 'babelfishpg_common', 'varchar2time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS pg_catalog.TIME)
WITH FUNCTION sys.varchar2time(sys.VARCHAR, INT4) AS IMPLICIT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
