-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '6.2.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar, arg_types varchar DEFAULT '') AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
    full_object_name text;
BEGIN
    -- Construct full object name with argument types if provided (for aggregates)
    IF arg_types <> '' THEN
        full_object_name := pg_catalog.format('%s.%s(%s)', schema_name, object_name, arg_types);
    ELSE
        full_object_name := pg_catalog.format('%s.%s', schema_name, object_name);
    END IF;

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', object_type, full_object_name);
    query2 := pg_catalog.format('drop %s %s', object_type, full_object_name);
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

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

DO
LANGUAGE plpgsql
$$
BEGIN
    -- Check if the GUC is empty
    IF current_setting('babelfishpg_tsql.restored_server_collation_name', true) <> '' THEN
        -- Call the function to update the collation
        EXECUTE 'SELECT sys.babelfish_update_server_collation_name()';
    END IF;
END;
$$;

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- reset babelfishpg_tsql.restored_server_collation_name GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
    end;
$$;

-- helper function for XML QUERY(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlquery(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS XML
AS
$BODY$
DECLARE
    temp_datatype text;
    temp_basetype oid;
    result_set xml[];
    result xml;
    pltsql_quoted_identifier text;
BEGIN
    temp_datatype := sys.translate_pg_type_to_tsql(pg_typeof(xml_element)::oid);
    IF temp_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for xml_element datatype validation
        temp_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(xml_element)::oid);
        temp_datatype := sys.translate_pg_type_to_tsql(temp_basetype);
    END IF;

    IF (temp_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', temp_datatype;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;

    result_set := xpath(xpath_pattern, xml_element);
    IF (cardinality(result_set) = 0) THEN
        RETURN ''::xml;
    ELSE
        result := array_to_string(result_set, '')::xml;
        RETURN result;
    END IF;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
