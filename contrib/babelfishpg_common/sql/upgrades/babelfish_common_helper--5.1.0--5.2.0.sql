------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.2.0'" to load this file. \quit
-- For JSON Functions
DO
$body$
BEGIN
    IF NOT EXISTS (
        SELECT  *
            FROM pg_type 
        WHERE typname = 'nvarchar_json')
    THEN
        SET enable_domain_typmod = TRUE;
        CREATE DOMAIN sys.NVARCHAR_JSON AS sys.NVARCHAR;
        RESET enable_domain_typmod;
    END IF;
END
$body$;

CREATE OR REPLACE FUNCTION sys.int4varbinary(INT4, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'int4varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.float4varbinary(REAL, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'float4varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- (INT4 AS sys.BBF_VARBINARY)
DROP CAST (INT4 AS sys.BBF_VARBINARY);

-- (REAL AS sys.BBF_VARBINARY)
DROP CAST (REAL AS sys.BBF_VARBINARY);

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (INT4 AS sys.BBF_VARBINARY)
    WITH FUNCTION sys.int4varbinary (INT4, integer, boolean) AS IMPLICIT;

    CREATE CAST (REAL AS sys.BBF_VARBINARY)
    WITH FUNCTION sys.float4varbinary (REAL, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
