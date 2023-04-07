-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '3.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

DROP CAST IF EXISTS(NUMERIC AS sys.BIT);
CREATE CAST (NUMERIC AS sys.BIT) WITH FUNCTION sys.numeric_bit (NUMERIC) AS IMPLICIT;

DROP CAST IF EXISTS(sys.VARCHAR AS sys.MONEY);

DROP FUNCTION IF EXISTS sys.varchar2money(sys.VARCHAR) CASCADE;

CREATE OR REPLACE FUNCTION sys.varchar2money(sys.VARCHAR)
RETURNS sys.MONEY
AS 'babelfishpg_common', 'varchar2money'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.MONEY)
WITH FUNCTION sys.varchar2money(sys.VARCHAR) AS IMPLICIT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
