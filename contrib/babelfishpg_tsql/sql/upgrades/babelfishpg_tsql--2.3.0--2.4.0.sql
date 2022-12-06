-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.4.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(
	object_type varchar, schema_name varchar, object_name varchar
) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := format('drop %s %s.%s', object_type, schema_name, object_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view/function/procedure' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;


-- please add your SQL here
CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 INT)
RETURNS int AS 'babelfishpg_tsql','int_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 SMALLINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 TINYINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(TINYINT) TO PUBLIC;

-- deprecate old FOR XML/JSON functions
ALTER FUNCTION sys.tsql_query_to_xml(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_deprecated_in_2_4_0');

ALTER FUNCTION sys.tsql_query_to_xml_text(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_text_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_deprecated_in_2_4_0');

ALTER FUNCTION sys.tsql_query_to_json_text(text, int, boolean, boolean, text) RENAME TO tsql_query_to_json_text_deprecated_in_2_4_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_deprecated_in_2_4_0');

-- SELECT FOR XML
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state TEXT,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text
) RETURNS TEXT
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C COST 100;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_ffunc(
    state TEXT
)
RETURNS XML AS
$$
DECLARE
    rootname TEXT;
BEGIN
IF (left(state, 1) = '{')
THEN
    -- '{' indicates that root was specified
    rootname = (regexp_match(state, '<([^\/>]+)[\/]*>' COLLATE C))[1];
    RETURN (substr(state, 2) || '</' || rootname || '>')::XML;
ELSE 
    RETURN state::XML;
END IF;
END;
$$
LANGUAGE PLPGSQL STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text_ffunc(
    state TEXT
)
RETURNS NTEXT AS
$$
DECLARE
    rootname TEXT;
BEGIN
IF (left(state, 1) = '{')
THEN
    -- '{' indicates that root was specified
    rootname = (regexp_match(state, '<([^\/>]+)[\/]*>' COLLATE C))[1];
    RETURN substr(state, 2) || '</' || rootname || '>';
ELSE 
    RETURN state;
END IF;
END;
$$
LANGUAGE PLPGSQL STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = TEXT,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = TEXT,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

-- SELECT FOR JSON
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_sfunc(
    state TEXT,
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT
) RETURNS TEXT
AS 'babelfishpg_tsql', 'tsql_query_to_json_sfunc'
LANGUAGE C COST 100;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_ffunc(
    state TEXT
)
RETURNS sys.NVARCHAR AS
$$
BEGIN
-- check for array wrapper
IF (left(state, 1) = '[') 
THEN 
    RETURN state || ']';
ELSIF (left(state, 1) = '<')
THEN
    -- '<' indicates that root was specified
    RETURN substr(state, 2) || ']}';
ELSE 
    RETURN state;
END IF;
END;
$$
LANGUAGE PLPGSQL STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_json_agg(
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT)
(
    STYPE = TEXT,
    SFUNC = tsql_query_to_json_sfunc,
    FINALFUNC = tsql_query_to_json_ffunc
);


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);