------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.binaryadd(leftarg sys.BBF_BINARY, rightarg sys.BBF_BINARY)
RETURNS sys.BBF_BINARY
AS 'byteacat'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'sys.BBF_BINARY'::pg_catalog.regtype and oprright = 'sys.BBF_BINARY'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN
CREATE OPERATOR sys.+ (
	LEFTARG    = sys.BBF_BINARY,
	RIGHTARG   = sys.BBF_BINARY,
	PROCEDURE  = sys.binaryadd
);
END IF;
END $$;
