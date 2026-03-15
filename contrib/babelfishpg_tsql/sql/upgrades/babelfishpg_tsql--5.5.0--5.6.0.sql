-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.6.0'" to load this file. \quit
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.datetime2fromparts(NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC, NUMERIC) RENAME TO datetime2fromparts_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datetime2fromparts_deprecated_in_5_6_0');

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year INT,
                                                                IN p_month INT,
                                                                IN p_day INT,
                                                                IN p_hour INT,
                                                                IN p_minute INT,
                                                                IN p_seconds INT,
                                                                IN p_fractions INT,
                                                                IN p_precision INT)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
   v_fractions VARCHAR;
   v_precision SMALLINT;
   v_err_message VARCHAR;
   v_calc_seconds NUMERIC;
   v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
   v_string pg_catalog.text;
BEGIN
   IF p_precision IS NULL THEN
      RAISE invalid_parameter_value USING 
         MESSAGE := 'Precision argument cannot be null.',
         DETAIL := 'The precision parameter is mandatory for DATETIME2.',
         HINT := 'Provide a valid precision value between 0 and 7.';
   END IF;

   IF p_year IS NULL OR p_month IS NULL OR p_day IS NULL OR 
      p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR 
      p_fractions IS NULL THEN
      RETURN NULL;
   END IF;

   v_fractions := p_fractions::VARCHAR;
   v_precision := p_precision::SMALLINT;

   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year NOT BETWEEN 1 AND 9999) OR
       (p_month NOT BETWEEN 1 AND 12) OR
       (p_day NOT BETWEEN 1 AND 31) OR
       (p_hour NOT BETWEEN 0 AND 23) OR
       (p_minute NOT BETWEEN 0 AND 59) OR
       (p_seconds NOT BETWEEN 0 AND 59) OR
       (p_fractions NOT BETWEEN 0 AND 9999999) OR
       (p_fractions != 0 AND char_length(v_fractions) > v_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := pg_catalog.format('%s.%s',
                            p_seconds,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, v_precision))::NUMERIC;

   v_resdatetime := make_timestamp(p_year,
                         p_month,
                         p_day,
                         p_hour,
                         p_minute,
                         v_calc_seconds);

   v_string := v_resdatetime::pg_catalog.text;

   RETURN CAST(v_string AS sys.DATETIME2);
EXCEPTION
   WHEN most_specific_type_mismatch THEN
      RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_parameter_value THEN
      RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';

   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := pg_catalog.upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                  HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.datetime2fromparts(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) RENAME TO datetime2fromparts_text_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datetime2fromparts_text_deprecated_in_5_6_0');

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    IF p_precision IS NULL THEN
        RAISE invalid_parameter_value USING 
            MESSAGE := 'Precision argument cannot be null.',
            DETAIL := 'The precision parameter is mandatory for DATETIME2.',
            HINT := 'Provide a valid precision value between 0 and 7.';
    END IF;

    IF p_year IS NULL OR p_month IS NULL OR p_day IS NULL OR 
       p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR 
       p_fractions IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN sys.datetime2fromparts(p_year::INT, p_month::INT, p_day::INT,
                                                p_hour::INT, p_minute::INT, p_seconds::INT,
                                                p_fractions::INT, p_precision::INT);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

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

-- Please add your SQLs here

-- Deprecate and drop old aggregates first (they depend on the function)

-- Deprecate and drop old aggregate (6 args) - tsql_select_for_xml_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_agg(anyelement, integer, text, boolean, text)
    RENAME TO tsql_select_for_xml_agg_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_agg_deprecated_in_5_6_0', 'anyelement, integer, text, boolean, text');
-- Deprecate and drop old aggregate (6 args) - tsql_select_for_xml_text_agg
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER AGGREGATE sys.tsql_select_for_xml_text_agg(anyelement, integer, text, boolean, text)
    RENAME TO tsql_select_for_xml_text_agg_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('aggregate', 'sys', 'tsql_select_for_xml_text_agg_deprecated_in_5_6_0', 'anyelement, integer, text, boolean, text');
-- Deprecate and drop old function (6 args) - after aggregates are gone
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.tsql_query_to_xml_sfunc(internal, anyelement, integer, text, boolean, text)
    RENAME TO tsql_query_to_xml_sfunc_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_sfunc_deprecated_in_5_6_0');

-- Create new function with ELEMENTS parameters (8 args)
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

-- Create new aggregate with ELEMENTS parameters (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

-- Create new aggregate with ELEMENTS parameters (8 args)
CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text,
    elements boolean,
    xsinil boolean)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

 DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.fn_varbintohexsubstring(set_prefix INT, expression sys.varbinary(128), start_offset INT, length_to_return INT) RENAME TO fn_varbintohexsubstring_deprecated_in_5_6_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_varbintohexsubstring_deprecated_in_5_6_0');

-- Add sys.textsize() function for @@textsize support
CREATE OR REPLACE FUNCTION sys.textsize()
RETURNS integer
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value integer;
begin
    return_value := current_setting('babelfishpg_tsql.textsize');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.textsize() TO PUBLIC;

-- Function to get pg_attribute rows for temp tables (ENR and non-ENR)
CREATE OR REPLACE FUNCTION sys.babelfish_get_enr_attributes(IN table_name sys.varchar(4000))
RETURNS SETOF pg_catalog.pg_attribute
AS 'babelfishpg_tsql', 'get_enr_attributes'
LANGUAGE C STABLE PARALLEL UNSAFE;
GRANT EXECUTE ON FUNCTION sys.babelfish_get_enr_attributes(IN sys.varchar(4000)) TO PUBLIC;

-- Wrapper function for sp_tablecollations_100 that uses the babelfish_get_enr_attributes function
CREATE OR REPLACE FUNCTION sys.sp_tablecollations_100_enr(IN table_name sys.varchar(4000))
RETURNS TABLE(colid INT, name sys.varchar, collation_name sys.nvarchar(128))
AS $$
    SELECT 
        CAST(a.attnum AS INT) AS colid,
        CAST(a.attname AS sys.varchar) AS name,
        CAST(c.collname AS sys.nvarchar(128)) AS collation_name
    FROM sys.babelfish_get_enr_attributes(table_name) a
    LEFT JOIN pg_catalog.pg_collation c ON a.attcollation = c.oid
    WHERE a.attnum > 0 AND NOT a.attisdropped
    ORDER BY a.attnum;
$$
LANGUAGE SQL STABLE PARALLEL UNSAFE;
GRANT EXECUTE ON FUNCTION sys.sp_tablecollations_100_enr(IN sys.varchar(4000)) TO PUBLIC;

-- Modify sys.sp_tablecollations_100 to handle temp tables (starting with #)
-- This enables SqlBulkCopy to work with temp tables by providing column collation metadata.
CREATE OR REPLACE PROCEDURE sys.sp_tablecollations_100
(
    IN "@object" nvarchar(4000)
)
AS $$
BEGIN
    -- Check if this is a temp table (starts with # or [# or contains .# or .[#)
    IF LEFT(@object, 1) = '#' OR LEFT(@object, 2) = '[#' OR @object LIKE '%.#%' OR @object LIKE '%.[[]#%'
    BEGIN
        -- Use ENR function for temp tables
        SELECT
            t.colid AS colid,
            t.name AS name,
            CAST(CollationProperty(t.collation_name, 'tdscollation') AS sys.binary(5)) AS tds_collation,
            t.collation_name AS collation
        FROM sys.sp_tablecollations_100_enr(@object) t
        ORDER BY t.colid;
    END
    ELSE
    BEGIN
        -- Existing logic for regular tables
        SELECT
            s_tcv.colid AS colid,
            s_tcv.name AS name,
            s_tcv.tds_collation_100 AS tds_collation,
            s_tcv.collation_100 AS collation
        FROM sys.spt_tablecollations_view s_tcv
        WHERE s_tcv.object_id = (SELECT sys.object_id(@object))
        ORDER BY colid;
    END
END;
$$
LANGUAGE 'pltsql';

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
