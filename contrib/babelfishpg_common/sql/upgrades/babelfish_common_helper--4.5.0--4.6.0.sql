------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.6.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- For JSON Functions
SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.NVARCHAR_JSON AS sys.NVARCHAR;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.varbinary2datetime(sys.BBF_VARBINARY)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'varbinary_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE 
	sys_oid Oid;
	pg_catalog_oid Oid;
	bbf_varbinary_oid Oid;
	datetime_oid Oid;
BEGIN
	sys_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='sys');
	bbf_varbinary_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bbf_varbinary' AND pg_type.typnamespace = sys_oid);
	datetime_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='datetime' AND pg_type.typnamespace = sys_oid);
	IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = bbf_varbinary_oid AND pg_cast.casttarget = datetime_oid) = 0 THEN
		CREATE CAST (sys.BBF_VARBINARY AS sys.DATETIME)
		WITH FUNCTION sys.varbinary2datetime(sys.BBF_VARBINARY) AS IMPLICIT;
	END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
