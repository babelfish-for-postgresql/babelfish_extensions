------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.ncharvarbinary(sys.NCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'ncharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysysbpchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_VARBINARY AS sys.BPCHAR)
    WITH FUNCTION sys.varbinarysysbpchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.varbinarybpchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS pg_catalog.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_VARBINARY AS pg_catalog.BPCHAR)
    WITH FUNCTION sys.varbinarybpchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.varbinarysysnchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'varbinarynchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ncharbinary(sys.NCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'ncharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarysysbpchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_BINARY AS sys.BPCHAR)
    WITH FUNCTION sys.binarysysbpchar (sys.BBF_BINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binarybpchar(sys.BBF_BINARY, integer, boolean)
RETURNS pg_catalog.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_BINARY AS pg_catalog.BPCHAR)
    WITH FUNCTION sys.binarybpchar (sys.BBF_BINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binarysysnchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'varbinarynchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.varchar2float4(pg_catalog.VARCHAR)
RETURNS FLOAT4
AS 'babelfishpg_common', 'varchar2float4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS FLOAT4)
WITH FUNCTION sys.varchar2float4(pg_catalog.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2float8(pg_catalog.VARCHAR)
RETURNS FLOAT8
AS 'babelfishpg_common', 'varchar2float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS FLOAT8)
WITH FUNCTION sys.varchar2float8(pg_catalog.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2float4(pg_catalog.BPCHAR)
RETURNS FLOAT4
AS 'babelfishpg_common', 'bpchar2float4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BPCHAR AS FLOAT4)
WITH FUNCTION sys.bpchar2float4(pg_catalog.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2float8(pg_catalog.BPCHAR)
RETURNS FLOAT8
AS 'babelfishpg_common', 'bpchar2float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BPCHAR AS FLOAT8)
WITH FUNCTION sys.bpchar2float8(pg_catalog.BPCHAR) AS IMPLICIT;
