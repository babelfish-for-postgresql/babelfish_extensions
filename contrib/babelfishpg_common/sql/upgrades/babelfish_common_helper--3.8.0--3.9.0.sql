------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "3.9.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '|| current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.varbinary2datetime(sys.BBF_VARBINARY)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'varbinary_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.DATETIME)
WITH FUNCTION sys.varbinary2datetime(sys.BBF_VARBINARY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varbinaryadd(leftarg sys.BBF_VARBINARY, rightarg sys.BBF_VARBINARY)
RETURNS sys.BBF_VARBINARY
AS 'byteacat'
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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
