------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.varchar2datetimeoffset(sys.VARCHAR)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'varchar_datetimeoffset'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

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
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

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
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

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
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

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