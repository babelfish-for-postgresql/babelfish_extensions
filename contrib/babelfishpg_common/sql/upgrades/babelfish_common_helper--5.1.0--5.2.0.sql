------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

-- TODO : We need to fix this in BABEL-5597
CREATE OR REPLACE FUNCTION sys.varbinaryadd(leftarg sys.bbf_varbinary,rightarg sys.bbf_varbinary)
RETURNS int8
AS $$
	select sys.varbinaryadd_helper(varbinaryint8(leftarg), varbinaryint8(rightarg))
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinaryadd_helper(int8, int8)
RETURNS int8
AS 'int8pl'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'sys.BBF_VARBINARY'::pg_catalog.regtype and oprright = 'sys.BBF_VARBINARY'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN
CREATE OPERATOR sys.+ (
	LEFTARG    = sys.BBF_VARBINARY,
	RIGHTARG   = sys.BBF_VARBINARY,
	PROCEDURE  = sys.varbinaryadd
);
END IF;
END $$;

CREATE OR REPLACE FUNCTION sys.varbinarysub(leftarg sys.bbf_varbinary,rightarg sys.bbf_varbinary)
RETURNS int8
AS $$
	select sys.varbinarysub_helper(varbinaryint8(leftarg), varbinaryint8(rightarg))
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysub_helper(int8, int8)
RETURNS int8
AS 'int8mi'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'sys.BBF_VARBINARY'::pg_catalog.regtype and oprright = 'sys.BBF_VARBINARY'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '-' and oprresult != 0) THEN
CREATE OPERATOR sys.- (
	LEFTARG    = sys.BBF_VARBINARY,
	RIGHTARG   = sys.BBF_VARBINARY,
	PROCEDURE  = sys.varbinarysub
);
END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);