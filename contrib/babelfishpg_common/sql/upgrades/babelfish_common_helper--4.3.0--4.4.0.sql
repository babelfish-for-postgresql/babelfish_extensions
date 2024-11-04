------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.4.0"" to load this file. \quit

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
    when undefined_function then --if 'Deprecated function does not exist'
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- (sys.VARCHAR AS pg_catalog.TIME)
DROP CAST (sys.VARCHAR AS pg_catalog.TIME);

DO $$    
DECLARE	
    exception_message text;	
BEGIN	
    ALTER FUNCTION sys.varchar2time(sys.VARCHAR) RENAME TO varchar2time_deprecated_4_4_0;	

EXCEPTION WHEN OTHERS THEN	
    GET STACKED DIAGNOSTICS	
    exception_message = MESSAGE_TEXT;	
    RAISE WARNING '%', exception_message;	
END;	
$$;

CREATE OR REPLACE FUNCTION sys.varchar2time(sys.VARCHAR, INT4)
RETURNS pg_catalog.TIME
AS 'babelfishpg_common', 'varchar2time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS pg_catalog.TIME)
WITH FUNCTION sys.varchar2time(sys.VARCHAR, INT4) AS IMPLICIT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'varchar2time_deprecated_4_4_0');

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) RETURNS TEXT
AS 'babelfishpg_tsql', 'babelfish_concat_wrapper'
LANGUAGE C STABLE PARALLEL SAFE;

-- bool bit cast
DO $$
DECLARE 
    sys_oid Oid;
    pg_catalog_oid Oid;
    bool_oid Oid;
    bit_oid Oid;
BEGIN
  sys_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='sys');
  pg_catalog_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='pg_catalog');
  bool_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bool' AND pg_type.typnamespace = pg_catalog_oid);
  bit_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bit' AND pg_type.typnamespace = sys_oid);
  IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = bool_oid AND pg_cast.casttarget = bit_oid) = 0 THEN
      CREATE CAST (bool AS sys.BIT)
      WITHOUT FUNCTION AS IMPLICIT;
  END IF;
END $$;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
