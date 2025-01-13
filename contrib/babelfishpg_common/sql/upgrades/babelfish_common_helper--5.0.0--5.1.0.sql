------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.1.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.nvarcharvarbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'nvarcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysysnvarchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'varbinarynvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarysysnvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'varbinarynvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarcharbinary(sys.NVARCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'nvarcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
CREATE OR REPLACE FUNCTION sys.fixeddecimal2varchar(sys.FIXEDDECIMAL, integer, BOOLEAN)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'fixeddecimal2varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimal2pgvarchar(sys.FIXEDDECIMAL, integer, BOOLEAN)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'fixeddecimal2varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimal2bpchar(sys.FIXEDDECIMAL, integer, BOOLEAN)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'fixeddecimal2bpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.FIXEDDECIMAL AS sys.VARCHAR)
    WITH FUNCTION sys.fixeddecimal2varchar(sys.FIXEDDECIMAL, integer, BOOLEAN) AS IMPLICIT;

    CREATE CAST (sys.FIXEDDECIMAL AS pg_catalog.VARCHAR)
    WITH FUNCTION sys.fixeddecimal2pgvarchar(sys.FIXEDDECIMAL, integer, BOOLEAN) AS IMPLICIT;

    CREATE CAST (sys.FIXEDDECIMAL AS sys.BPCHAR)
    WITH FUNCTION sys.fixeddecimal2bpchar(sys.FIXEDDECIMAL, integer, BOOLEAN) AS IMPLICIT;

    CREATE CAST (sys.FIXEDDECIMAL AS pg_catalog.BPCHAR)
    WITH FUNCTION sys.fixeddecimal2bpchar(sys.FIXEDDECIMAL, integer, BOOLEAN) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
