-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '1.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.byteavarbinary(pg_catalog.BYTEA, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'byteavarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BYTEA AS sys.BBF_VARBINARY)
WITH FUNCTION sys.byteavarbinary(pg_catalog.BYTEA, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinarybytea(sys.BBF_VARBINARY, integer, boolean)
RETURNS pg_catalog.BYTEA
AS 'babelfishpg_common', 'byteavarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS pg_catalog.BYTEA)
WITH FUNCTION sys.varbinarybytea(sys.BBF_VARBINARY, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- typmod cast for sys.BBF_VARBINARY
CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_VARBINARY)
WITH FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, BOOLEAN) AS ASSIGNMENT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
