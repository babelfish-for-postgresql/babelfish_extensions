-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '1.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE CAST (sys.VARCHAR as pg_catalog.xml)
WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2date(sys.VARCHAR)
RETURNS pg_catalog.DATE
AS 'babelfishpg_common', 'varchar2date'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS pg_catalog.DATE)
WITH FUNCTION sys.varchar2date(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2time(sys.VARCHAR)
RETURNS pg_catalog.TIME
AS 'babelfishpg_common', 'varchar2time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS pg_catalog.TIME)
WITH FUNCTION sys.varchar2time(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2money(sys.VARCHAR)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_common', 'varchar2money'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.FIXEDDECIMAL)
WITH FUNCTION sys.varchar2money(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2numeric(sys.VARCHAR)
RETURNS pg_catalog.NUMERIC
AS 'babelfishpg_common', 'varchar2numeric'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS pg_catalog.NUMERIC)
WITH FUNCTION sys.varchar2numeric(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2bit(sys.VARCHAR)
RETURNS sys.BIT
AS 'babelfishpg_common', 'varchar2bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.BIT)
WITH FUNCTION sys.varchar2bit(sys.VARCHAR) AS IMPLICIT;

/* This helper function would only be useful and strickly be used during 1.x to 2.3 upgrade. */
CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

SELECT sys.babelfish_update_server_collation_name();

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
