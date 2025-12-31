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

CREATE OR REPLACE FUNCTION sys.varchar2datetimeoffset(sys.VARCHAR)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'varchar_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
  exception_message text;
BEGIN
  CREATE CAST (sys.VARCHAR AS sys.DATETIMEOFFSET)
  WITH FUNCTION sys.varchar2datetimeoffset (sys.VARCHAR) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.varchar2datetimeoffset(pg_catalog.VARCHAR)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'varchar_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
  exception_message text;
BEGIN
  CREATE CAST (pg_catalog.VARCHAR AS sys.DATETIMEOFFSET)
  WITH FUNCTION sys.varchar2datetimeoffset (pg_catalog.VARCHAR) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.char2datetimeoffset(CHAR)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'char_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
  exception_message text;
BEGIN
  CREATE CAST (CHAR AS sys.DATETIMEOFFSET)
  WITH FUNCTION sys.char2datetimeoffset (CHAR) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.bpchar2datetimeoffset(sys.BPCHAR)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'char_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
  exception_message text;
BEGIN
  CREATE CAST (sys.BPCHAR AS sys.DATETIMEOFFSET)
  WITH FUNCTION sys.bpchar2datetimeoffset (sys.BPCHAR) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
  GET STACKED DIAGNOSTICS
  exception_message = MESSAGE_TEXT;
  RAISE WARNING '%', exception_message;
END;
$$;
