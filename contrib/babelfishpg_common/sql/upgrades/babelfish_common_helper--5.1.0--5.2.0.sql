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

CREATE CAST (INT4 AS sys.BBF_VARBINARY)
WITH FUNCTION sys.int4varbinary (INT4, integer, boolean) AS IMPLICIT;

CREATE CAST (REAL AS sys.BBF_VARBINARY)
WITH FUNCTION sys.float4varbinary (REAL, integer, boolean) AS IMPLICIT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
