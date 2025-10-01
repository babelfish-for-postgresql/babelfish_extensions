-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.4.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
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

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE FUNCTION sys.sqrt(number PG_CATALOG.NUMERIC)
RETURNS sys.float
AS $$
BEGIN
    RETURN PG_CATALOG.SQRT(number::float8);
END;
$$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_xmlvalue(xpath_pattern TEXT, datatype TEXT, xml_element ANYELEMENT)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    temp_datatype text;
    temp_basetype oid;
    result_set xml[];
    result sys.NVARCHAR;
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
    IF (cardinality(result_set) > 1) THEN
        RAISE EXCEPTION 'XML Value result is not a single value.';
    ELSIF (cardinality(result_set) = 0) THEN
        RETURN NULL;
    ELSE
        result := (xpath('string(' + xpath_pattern + ')', xml_element))[1];
        result := pg_catalog.replace(result, '&lt;', '<');
        result := pg_catalog.replace(result, '&gt;', '>');
        result := pg_catalog.replace(result, '&apos;', '''');
        result := pg_catalog.replace(result, '&quot;', '"');
        result := pg_catalog.replace(result, '&amp;', '&');
        return result;
    END IF; 
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, false) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CAST(CREATE_PARAMS AS CHAR(20)), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.degrees(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 sys.fixeddecimal)
RETURNS sys.MONEY
AS $$
BEGIN
    RETURN sys.radians(arg1::PG_CATALOG.NUMERIC);
END;
$$
LANGUAGE plpgsql STRICT IMMUTABLE PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_sp_xml_preparedocument RENAME TO babelfish_sp_xml_preparedocument_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_sp_xml_preparedocument_deprecated_in_5_4_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_sp_xml_removedocument RENAME TO babelfish_sp_xml_removedocument_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_sp_xml_removedocument_deprecated_in_5_4_0');

CREATE OR REPLACE PROCEDURE sys.sp_xml_preparedocument(
    INOUT "@hdoc"  INTEGER,                 
    IN "@xmltext" sys.VARCHAR DEFAULT NULL,    
    IN "@xpath_namespaces" sys.VARCHAR DEFAULT NULL 
) 
AS 'babelfishpg_tsql', 'sp_xml_preparedocument'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_xml_preparedocument(
	INOUT INTEGER, IN sys.varchar, IN sys.varchar
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_xml_removedocument(
    IN "@hdoc" INTEGER
) 
AS 'babelfishpg_tsql', 'sp_xml_removedocument'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_xml_removedocument(
	IN INTEGER
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_openxml_get_xmldoc(int)
RETURNS xml
AS 'babelfishpg_tsql', 'tsql_openxml_get_xmldoc'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_openxml_get_colpattern(text,int)
RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'tsql_openxml_get_colpattern'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.openxml_simple(document_id INT, 
                                       rowpattern TEXT, 
                                       flags INTEGER DEFAULT 0)
RETURNS table (
  id sys.BIGINT,
  parentid sys.BIGINT,
  nodetype sys.INT,
  localname sys.NVARCHAR,
  prefix sys.NVARCHAR,
  namespaceuri sys.NVARCHAR,
  datatype sys.NVARCHAR,
  prev sys.BIGINT,
  text sys.NTEXT
) 
AS 'babelfishpg_tsql', 'openxml_simple'
LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.ascii(ANYELEMENT)
RETURNS INTEGER
AS $$
DECLARE
    arg_datatype text;
    basetype oid;
BEGIN
    arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof($1)::oid);
    IF arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof($1)::oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    -- restricting arguments with invalid datatypes for ascii function
    IF arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of ascii function.', arg_datatype;
    END IF;
    
    IF arg_datatype IN ('binary', 'varbinary') THEN
        IF len($1) = 0 THEN
            RETURN NULL;
        END IF;
    ELSE
        IF length($1::TEXT) = 0 THEN
            RETURN NULL;
        END IF;
    END IF;
    RETURN pg_catalog.ascii(CAST($1 AS sys.VARCHAR));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ascii(TEXT)
RETURNS INTEGER
AS $$
BEGIN
    IF length($1) = 0 THEN
        RETURN NULL;
    END IF;
    RETURN pg_catalog.ascii(CAST($1 AS sys.VARCHAR));
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_openxml RENAME TO babelfish_openxml_deprecated_in_5_4_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_openxml_deprecated_in_5_4_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

-- valid names are db_name.schema_name.object_name or schema_name.object_name or object_name
CREATE OR REPLACE FUNCTION sys.babelfish_split_object_name(
    name TEXT, 
    OUT db_name TEXT, 
    OUT schema_name TEXT, 
    OUT object_name TEXT)
AS $$
DECLARE
    lower_object_name text;
    names text[2];
    counter int;
    cur_pos int;
BEGIN
    lower_object_name = pg_catalog.lower(name);

    counter = 1;
    cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);

    -- Parse user input into names split by '.'
    WHILE cur_pos > 0 LOOP
        IF counter > 3 THEN
            -- Too many names provided
            RETURN;
        END IF;

        names[counter] = babelfish_remove_delimiter_pair(PG_CATALOG.left(lower_object_name, cur_pos - 1));
        
        -- invalid name
        IF names[counter] IS NULL THEN
            RETURN;
        END IF;

        lower_object_name = substring(lower_object_name from cur_pos + 1);
        counter = counter + 1;
        cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);
    END LOOP;

    CASE counter
        WHEN 1 THEN
            db_name = NULL;
            schema_name = NULL;
        WHEN 2 THEN
            db_name = NULL;
            schema_name = sys.babelfish_truncate_identifier(names[1]);
        WHEN 3 THEN
            db_name = sys.babelfish_truncate_identifier(names[1]);
            schema_name = sys.babelfish_truncate_identifier(names[2]);
        ELSE
            RETURN;
    END CASE;

    -- Assign each name accordingly
    object_name = sys.babelfish_truncate_identifier(babelfish_remove_delimiter_pair(lower_object_name));
END;
$$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    db_name text COLLATE sys.database_default; 
    bbf_schema_name text COLLATE sys.database_default;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    is_cross_db boolean := false;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    userid oid;
    object_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
    cs_as_securable text COLLATE "C" := securable;
    cs_as_securable_class text COLLATE "C" := securable_class;
    cs_as_permission text COLLATE "C" := permission;
    cs_as_sub_securable text COLLATE "C" := sub_securable;
    cs_as_sub_securable_class text COLLATE "C" := sub_securable_class;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    cs_as_securable = pg_catalog.lower(cs_as_securable);
    cs_as_securable_class = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_securable_class));
    cs_as_permission = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_permission));
    cs_as_sub_securable = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, user must be evaluating column privileges.
    -- Check that inputs are valid for column privileges: sub_securable_class must 
    -- be column, securable_class must be object, and permission cannot be any.
    ELSIF cs_as_sub_securable_class IS NOT NULL 
            AND (cs_as_sub_securable_class != 'column' 
                    OR cs_as_securable_class IS NULL 
                    OR cs_as_securable_class != 'object' 
                    OR cs_as_permission = 'any') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null
    ELSIF cs_as_securable IS NULL AND cs_as_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If securable_class is null, securable must be null
    ELSIF cs_as_securable IS NOT NULL AND cs_as_securable_class IS NULL THEN
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'server' THEN
        -- SQL Server does not permit a securable_class value of 'server'.
        -- securable_class should be NULL to evaluate server permissions.
        RETURN NULL;
    ELSIF cs_as_securable_class IS NULL THEN
        -- NULL indicates a server permission. Set this variable so that we can
        -- search for the matching entry in babelfish_has_perms_by_name_permissions
        cs_as_securable_class = 'server';
    END IF;

    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported 
    INTO implied_dbo_permissions,fully_supported 
    FROM babelfish_has_perms_by_name_permissions p 
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;
    
    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name COLLATE sys.database_default) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
                    AND ext.dbid = sys.db_id()) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND
		(SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) = 'dbo' THEN
        RETURN CAST(implied_dbo_permissions AS integer);
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable class.
    -- The block above has dealt with all permissions that are not fully supported, so 
    -- if we reach this point we know the securable class is OBJECT.
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name 
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    -- If schema was not specified, use the default
    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE 
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

	IF database_id <> sys.db_id() THEN
        is_cross_db = true;
	END IF;

	userid := (
        SELECT CASE
            WHEN is_cross_db THEN sys.suser_id()
            ELSE sys.user_id()
        END);
  
    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname 
                    FROM sys.babelfish_namespace_ext ext 
                    WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := PG_CATALOG.concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(a.attname)
                        FROM pg_attribute a
                        INNER JOIN pg_class c ON c.oid = a.attrelid
                        INNER JOIN pg_namespace s ON s.oid = c.relnamespace
                        WHERE
                        a.attname = cs_as_sub_securable COLLATE sys.database_default
                        AND c.relname = object_name COLLATE sys.database_default
                        AND s.nspname = pg_schema COLLATE sys.database_default
                        AND NOT a.attisdropped
                        AND (s.nspname IN (SELECT nspname FROM sys.babelfish_namespace_ext) OR s.nspname = 'sys')
                        -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
                        AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
                        AND a.attnum > 0) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname) 
                    FROM pg_catalog.pg_class 
                    WHERE relname = object_name COLLATE sys.database_default
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default 
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'
                
            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );
    
    -- Object was not found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;
  
    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT CAST(oid AS regprocedure) 
            INTO function_signature 
            FROM pg_catalog.pg_proc 
            WHERE proname = object_name COLLATE sys.database_default
                AND pronamespace = namespace_id;
    END IF;

    return_value := (
        SELECT CASE
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(userid, object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(userid, qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(userid, qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
        END
    );

    RETURN return_value;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;