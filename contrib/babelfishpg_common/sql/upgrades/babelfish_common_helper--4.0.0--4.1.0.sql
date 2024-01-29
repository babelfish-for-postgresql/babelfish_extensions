------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.1.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_common drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.varbinarybinary (sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- (sys.BBF_BINARY AS sys.VARCHAR)
DROP CAST IF EXISTS(sys.BBF_BINARY AS sys.VARCHAR);

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.binarysysvarchar(sys.BBF_BINARY) RENAME TO binarysysvarchar_deprecated_4_1_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binarysysvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.VARCHAR)
WITH FUNCTION sys.binarysysvarchar (sys.BBF_BINARY, integer, boolean) AS ASSIGNMENT;

DO $$
DECLARE
    exception_message text;
BEGIN
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'binarysysvarchar_deprecated_4_1_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- (sys.BBF_BINARY AS pg_catalog.VARCHAR)
DROP CAST IF EXISTS(sys.BBF_BINARY AS pg_catalog.VARCHAR);

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.binaryvarchar(sys.BBF_BINARY) RENAME TO binaryvarchar_deprecated_4_1_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binaryvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS pg_catalog.VARCHAR)
WITH FUNCTION sys.binaryvarchar (sys.BBF_BINARY, integer, boolean) AS ASSIGNMENT;

DO $$
DECLARE
    exception_message text;
BEGIN
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'binaryvarchar_deprecated_4_1_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- (sys.ROWVERSION AS sys.VARCHAR)
DROP CAST IF EXISTS(sys.ROWVERSION AS sys.VARCHAR);

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.rowversionsysvarchar(sys.ROWVERSION) RENAME TO rowversionsysvarchar_deprecated_4_1_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.rowversionsysvarchar(sys.ROWVERSION, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS sys.VARCHAR)
WITH FUNCTION sys.rowversionsysvarchar (sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

DO $$
DECLARE
    exception_message text;
BEGIN
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'rowversionsysvarchar_deprecated_4_1_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

-- (sys.BBF_BINARY AS pg_catalog.VARCHAR)
DROP CAST IF EXISTS(sys.ROWVERSION AS pg_catalog.VARCHAR);

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.rowversionvarchar(sys.ROWVERSION) RENAME TO rowversionvarchar_deprecated_4_1_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.rowversionvarchar(sys.ROWVERSION, integer, boolean)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS pg_catalog.VARCHAR)
WITH FUNCTION sys.rowversionvarchar (sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

DO $$
DECLARE
    exception_message text;
BEGIN
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'rowversionvarchar_deprecated_4_1_0');

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.date2datetime(DATE)
RETURNS DATETIME
AS 'babelfishpg_common', 'date_datetime'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date2datetime2(DATE)
RETURNS DATETIME2
AS 'babelfishpg_common', 'date_datetime2'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
