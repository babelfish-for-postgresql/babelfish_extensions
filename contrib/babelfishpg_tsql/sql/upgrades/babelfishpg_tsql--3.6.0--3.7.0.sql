-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.6.0'" to load this file. \quit

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
end
$$
LANGUAGE plpgsql;

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Update deprecated object_id function(s) since left function now restricts TEXT datatype
DO $$
BEGIN
    -- Update body of object_id_deprecated_in_2_4_0 to use PG_CATALOG.LEFT instead, if function exists
    IF EXISTS(SELECT count(*) 
                FROM pg_proc p 
                JOIN pg_namespace nsp 
                    ON p.pronamespace = nsp.oid 
                WHERE p.proname='object_id_deprecated_in_2_4_0' AND nsp.nspname='sys') THEN
        
        CREATE OR REPLACE FUNCTION sys.object_id_deprecated_in_2_4_0(IN object_name TEXT, IN object_type char(2) DEFAULT '')
        RETURNS INTEGER AS
        $BODY$
        DECLARE
            id oid;
            db_name text collate "C";
            bbf_schema_name text collate "C";
            schema_name text collate "C";
            schema_oid oid;
            obj_name text collate "C";
            is_temp_object boolean;
            obj_type char(2) collate "C";
            cs_as_object_name text collate "C" := object_name;
        BEGIN
            obj_type = object_type;
            id = null;
            schema_oid = NULL;

            SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, obj_name 
            FROM babelfish_split_object_name(cs_as_object_name) s;

            -- Invalid object_name
            IF obj_name IS NULL OR obj_name = '' collate sys.database_default THEN
                RETURN NULL;
            END IF;

            IF bbf_schema_name IS NULL OR bbf_schema_name = '' collate sys.database_default THEN
                bbf_schema_name := sys.schema_name();
            END IF;

            schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

            -- Check if looking for temp object.
            is_temp_object = PG_CATALOG.left(obj_name, 1) = '#' collate sys.database_default;

            -- Can only search in current database. Allowing tempdb for temp objects.
            IF db_name IS NOT NULL AND db_name collate sys.database_default <> db_name() AND db_name collate sys.database_default <> 'tempdb' THEN
                RAISE EXCEPTION 'Can only do lookup in current database.';
            END IF;

            IF schema_name IS NULL OR schema_name = '' collate sys.database_default THEN
                RETURN NULL;
            END IF;

            -- Searching within a schema. Get schema oid.
            schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
            IF schema_oid IS NULL THEN
                RETURN NULL;
            END IF;

            if obj_type <> '' then
                case
                    -- Schema does not apply as much to temp objects.
                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);

                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                    id := (select oid from pg_class where lower(relname) collate sys.database_default = obj_name 
                                and relnamespace = schema_oid limit 1);

                    when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                    id := (select oid from pg_constraint where lower(conname) collate sys.database_default = obj_name 
                                and connamespace = schema_oid limit 1);

                    when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                    id := (select oid from pg_proc where lower(proname) collate sys.database_default = obj_name 
                                and pronamespace = schema_oid limit 1);

                    when upper(object_type) in ('TR', 'TA') then
                    id := (select oid from pg_trigger where lower(tgname) collate sys.database_default = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported obj_type
                    else id := null;
                end case;
            else
                if not is_temp_object then 
                    id := (
                        select oid from pg_class where lower(relname) = obj_name
                            and relnamespace = schema_oid
                        union
                        select oid from pg_constraint where lower(conname) = obj_name
                            and connamespace = schema_oid
                        union
                        select oid from pg_proc where lower(proname) = obj_name
                            and pronamespace = schema_oid
                        union
                        select oid from pg_trigger where lower(tgname) = obj_name
                        limit 1
                    );
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);
                end if;
            end if;

            RETURN id::integer;
        END;
        $BODY$
        LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;
    END IF;

    -- Update body of object_id_deprecated_in_3_1_0 to use PG_CATALOG.LEFT instead, if function exists
    IF EXISTS(SELECT count(*) 
                FROM pg_proc p 
                JOIN pg_namespace nsp 
                    ON p.pronamespace = nsp.oid 
                WHERE p.proname='object_id_deprecated_in_3_1_0' AND nsp.nspname='sys') THEN
        
        CREATE OR REPLACE FUNCTION sys.object_id_deprecated_in_3_1_0(IN object_name TEXT, IN object_type char(2) DEFAULT '')
        RETURNS INTEGER AS
        $BODY$
        DECLARE
            id oid;
            db_name text collate "C";
            bbf_schema_name text collate "C";
            schema_name text collate "C";
            schema_oid oid;
            obj_name text collate "C";
            is_temp_object boolean;
            obj_type char(2) collate "C";
            cs_as_object_name text collate "C" := object_name;
        BEGIN
            obj_type = object_type;
            id = null;
            schema_oid = NULL;

            SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, obj_name 
            FROM babelfish_split_object_name(cs_as_object_name) s;

            -- Invalid object_name
            IF obj_name IS NULL OR obj_name = '' collate sys.database_default THEN
                RETURN NULL;
            END IF;

            IF bbf_schema_name IS NULL OR bbf_schema_name = '' collate sys.database_default THEN
                bbf_schema_name := sys.schema_name();
            END IF;

            schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

            -- Check if looking for temp object.
            is_temp_object = PG_CATALOG.left(obj_name, 1) = '#' collate sys.database_default;

            -- Can only search in current database. Allowing tempdb for temp objects.
            IF db_name IS NOT NULL AND db_name collate sys.database_default <> db_name() AND db_name collate sys.database_default <> 'tempdb' THEN
                RAISE EXCEPTION 'Can only do lookup in current database.';
            END IF;

            IF schema_name IS NULL OR schema_name = '' collate sys.database_default THEN
                RETURN NULL;
            END IF;

            -- Searching within a schema. Get schema oid.
            schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
            IF schema_oid IS NULL THEN
                RETURN NULL;
            END IF;

            if obj_type <> '' then
                case
                    -- Schema does not apply as much to temp objects.
                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);

                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                    id := (select oid from pg_class where lower(relname) collate sys.database_default = obj_name 
                                and relnamespace = schema_oid limit 1);

                    when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                    id := (select oid from pg_constraint where lower(conname) collate sys.database_default = obj_name 
                                and connamespace = schema_oid limit 1);

                    when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                    id := (select oid from pg_proc where lower(proname) collate sys.database_default = obj_name 
                                and pronamespace = schema_oid limit 1);

                    when upper(object_type) in ('TR', 'TA') then
                    id := (select oid from pg_trigger where lower(tgname) collate sys.database_default = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported obj_type
                    else id := null;
                end case;
            else
                if not is_temp_object then 
                    id := (
                        select oid from pg_class where lower(relname) = obj_name
                            and relnamespace = schema_oid
                        union
                        select oid from pg_constraint where lower(conname) = obj_name
                            and connamespace = schema_oid
                        union
                        select oid from pg_proc where lower(proname) = obj_name
                            and pronamespace = schema_oid
                        union
                        select oid from pg_trigger where lower(tgname) = obj_name
                        limit 1
                    );
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);
                end if;
            end if;

            RETURN id::integer;
        END;
        $BODY$
        LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;
    END IF;
END;
$$;

-- wrapper functions for TRIM
CREATE OR REPLACE FUNCTION sys.TRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS 
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for trim function
    IF string_arg_datatype NOT IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of Trim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.btrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Additional handling is added for TRIM function with 2 arguments, 
-- hence only following two definitions are required.
CREATE OR REPLACE FUNCTION sys.TRIM(characters sys.VARCHAR, string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string, characters);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.TRIM(characters sys.VARCHAR, string sys.VARCHAR)
RETURNS sys.VARCHAR
AS 
$BODY$
BEGIN
    RETURN PG_CATALOG.btrim(string, characters);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for LTRIM
CREATE OR REPLACE FUNCTION sys.LTRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for ltrim function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of ltrim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.ltrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LTRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that ltrim with text input
-- will use following definition instead of PG ltrim
CREATE OR REPLACE FUNCTION sys.LTRIM(string TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that ltrim with ntext input
-- will use following definition instead of PG ltrim
CREATE OR REPLACE FUNCTION sys.LTRIM(string NTEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.ltrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for RTRIM
CREATE OR REPLACE FUNCTION sys.RTRIM(string ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for rtrim function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of rtrim function.', string_arg_datatype;
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.rtrim(string::sys.varchar);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.BPCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.VARCHAR)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.NCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RTRIM(string sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that rtrim with text input
-- will use following definition instead of PG rtrim
CREATE OR REPLACE FUNCTION sys.RTRIM(string TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Adding following definition will make sure that rtrim with ntext input
-- will use following definition instead of PG rtrim
CREATE OR REPLACE FUNCTION sys.RTRIM(string NTEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    RETURN PG_CATALOG.rtrim(string);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


-- wrapper functions for LEFT
CREATE OR REPLACE FUNCTION sys.LEFT(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for left function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of left function.', string_arg_datatype;
    END IF;

    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.BPCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.VARCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.LEFT(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that left with text input
-- will use following definition instead of PG left
CREATE OR REPLACE FUNCTION sys.LEFT(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that left with ntext input
-- will use following definition instead of PG left
CREATE OR REPLACE FUNCTION sys.LEFT(string NTEXT, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the left function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.left(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;


-- wrapper functions for RIGHT
CREATE OR REPLACE FUNCTION sys.RIGHT(string ANYELEMENT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
    string_arg_datatype text;
    string_basetype oid;
BEGIN
    string_arg_datatype := sys.translate_pg_type_to_tsql(pg_typeof(string)::oid);
    IF string_arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        string_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(string)::oid);
        string_arg_datatype := sys.translate_pg_type_to_tsql(string_basetype);
    END IF;

    -- restricting arguments with invalid datatypes for right function
    IF string_arg_datatype IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of right function.', string_arg_datatype;
    END IF;

    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN PG_CATALOG.right(string::sys.varchar, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.BPCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.VARCHAR, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.NCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.RIGHT(string sys.NVARCHAR, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that right with text input
-- will use following definition instead of PG right
CREATE OR REPLACE FUNCTION sys.RIGHT(string TEXT, i INTEGER)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Adding following definition will make sure that right with ntext input
-- will use following definition instead of PG right
CREATE OR REPLACE FUNCTION sys.RIGHT(string NTEXT, i INTEGER)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    IF i IS NULL THEN
        RETURN NULL;
    END IF;

    IF i < 0 THEN
        RAISE EXCEPTION 'Invalid length parameter passed to the right function.';
    END IF;

    IF string IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN PG_CATALOG.right(string, i);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.sp_who(
	IN "@loginame" sys.sysname DEFAULT NULL,
	IN "@option"   sys.VARCHAR(30) DEFAULT NULL)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET NOCOUNT ON
	DECLARE @msg sys.VARCHAR(200)
	DECLARE @show_pg BIT = 0
	DECLARE @hide_col sys.VARCHAR(50) 
	
	IF @option IS NOT NULL
	BEGIN
		IF LOWER(TRIM(@option)) <> 'postgres' 
		BEGIN
			RAISERROR('Parameter @option can only be ''postgres''', 16, 1)
			RETURN			
		END
	END
	
	-- Take a copy of sysprocesses so that we reference it only once
	SELECT DISTINCT * INTO #sp_who_sysprocesses FROM sys.sysprocesses

	-- Get the executing statement for each spid and extract the main stmt type
	-- This is for informational purposes only
	SELECT pid, CAST(query AS sys.VARCHAR(MAX)) INTO #sp_who_tmp FROM pg_stat_activity pgsa
	
	UPDATE #sp_who_tmp SET query = ' ' + TRIM(CAST(UPPER(query) AS sys.VARCHAR(MAX)))
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(9), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(10), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(13), ' ')
	WHILE (SELECT count(*) FROM #sp_who_tmp WHERE sys.CHARINDEX('  ',query)>0) > 0 
	BEGIN
		UPDATE #sp_who_tmp SET query = sys.REPLACE(query, '  ', ' ')
	END

	-- Determine type of stmt to report by sp_who: very basic only
	-- NB: not handling presence of comments in the query string
	UPDATE #sp_who_tmp 
	SET query = 
	    CASE 
			WHEN PATINDEX('%[^a-zA-Z0-9_]UPDATE[^a-zA-Z0-9_]%', query) > 0 THEN 'UPDATE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]DELETE[^a-zA-Z0-9_]%', query) > 0 THEN 'DELETE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]INSERT[^a-zA-Z0-9_]%', query) > 0 THEN 'INSERT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]SELECT[^a-zA-Z0-9_]%', query) > 0 THEN 'SELECT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]WAITFOR[^a-zA-Z0-9_]%', query) > 0 THEN 'WAITFOR'
			WHEN PATINDEX('%[^a-zA-Z0-9_]CREATE ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('CREATE ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]ALTER ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('ALTER ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]DROP ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('DROP ', query))
			ELSE sys.SUBSTRING(query, 1, sys.CHARINDEX(' ', query))
		END

	UPDATE #sp_who_tmp 
	SET query = sys.SUBSTRING(query,1, 8-1 + sys.CHARINDEX(' ', sys.SUBSTRING(query,8,99)))
	WHERE query LIKE 'CREATE %' OR query LIKE 'ALTER %' OR query LIKE 'DROP %'	

	-- The executing spid is always shown as doing a SELECT
	UPDATE #sp_who_tmp SET query = 'SELECT' WHERE pid = @@spid
	UPDATE #sp_who_tmp SET query = TRIM(query)

	-- Get all current connections
	SELECT 
		spid, 
		MAX(blocked) AS blocked, 
		0 AS ecid, 
		CAST('' AS sys.VARCHAR(100)) AS status,
		CAST('' AS sys.VARCHAR(100)) AS loginname,
		CAST('' AS sys.VARCHAR(100)) AS hostname,
		0 AS dbid,
		CAST('' AS sys.VARCHAR(100)) AS cmd,
		0 AS request_id,
		CAST('TDS' AS sys.VARCHAR(20)) AS connection,
		hostprocess
	INTO #sp_who_proc
	FROM #sp_who_sysprocesses
		GROUP BY spid, status, hostprocess
		
	-- Add attributes to each connection
	UPDATE #sp_who_proc
	SET ecid = sp.ecid,
		status = sp.status,
		loginname = sp.loginname,
		hostname = sp.hostname,
		dbid = sp.dbid,
		request_id = sp.request_id
	FROM #sp_who_sysprocesses sp
		WHERE #sp_who_proc.spid = sp.spid				

	-- Identify PG connections: the hostprocess PID comes from the TDS login packet 
	-- and therefore PG connections do not have a value here
	UPDATE #sp_who_proc
	SET connection = 'PostgreSQL'
	WHERE hostprocess IS NULL 

	-- Keep or delete PG connections
	IF (LOWER(@loginame) = 'postgres' OR LOWER(@option) = 'postgres')
	begin    
		-- Show PG connections; these have dbid = 0
		-- This is a Babelfish-specific enhancement, since PG connections may also be active in the Babelfish DB
		-- and it may be useful to see these displayed
		SET @show_pg = 1
		
		-- blank out the loginame parameter for the tests below
		IF LOWER(@loginame) = 'postgres' SET @loginame = NULL
	END
	
	-- By default, do not show the column indicating the connection type since SQL Server does not have this column
	SET @hide_col = 'connection' 
	
	IF (@show_pg = 1) 
	BEGIN
		SET @hide_col = ''
	END
	ELSE 
	BEGIN
		-- Delete PG connections
		DELETE #sp_who_proc
		WHERE dbid = 0
	END
			
	-- Apply filter if specified
	IF (@loginame IS NOT NULL)
	BEGIN
		IF (TRIM(@loginame) = '')
		BEGIN
			-- Raise error
			SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
			RAISERROR(@msg, 16, 1)
			RETURN
		END
		
		IF (sys.ISNUMERIC(@loginame) = 1)
		BEGIN
			-- Remove all connections except the specified one
			DELETE #sp_who_proc
			WHERE spid <> CAST(@loginame AS INT)
		END
		ELSE 
		BEGIN	
			IF (LOWER(@loginame) = 'active')
			BEGIN
				-- Remove all 'idle' connections 
				DELETE #sp_who_proc
				WHERE status = 'idle'
			END
			ELSE 
			BEGIN
				-- Verify the specified login name exists
				IF (sys.SUSER_ID(@loginame) IS NULL)
				BEGIN
					SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
					RAISERROR(@msg, 16, 1)
					RETURN					
				END
				ELSE 
				BEGIN
					-- Keep only connections for the specified login
					DELETE #sp_who_proc
					WHERE sys.SUSER_ID(loginname) <> sys.SUSER_ID(@loginame)
				END
			END
		END
	END			
			
	-- Create final result set; use DISTINCT since there are usually duplicate rows from the PG catalogs
	SELECT distinct 
		p.spid AS spid, 
		p.ecid AS ecid, 
		CAST(LEFT(p.status,20) AS sys.VARCHAR(20)) AS status,
		CAST(LEFT(p.loginname,40) AS sys.VARCHAR(40)) AS loginame,
		CAST(LEFT(p.hostname,60) AS sys.VARCHAR(60)) AS hostname,
		p.blocked AS blk, 
		CAST(LEFT(db_name(p.dbid),40) AS sys.VARCHAR(40)) AS dbname,
		CAST(LEFT(#sp_who_tmp.query,30)as sys.VARCHAR(30)) AS cmd,
		p.request_id AS request_id,
		connection
	INTO #sp_who_tmp2
	FROM #sp_who_proc p, #sp_who_tmp
		WHERE p.spid = #sp_who_tmp.pid
		ORDER BY spid		
	
	-- Patch up remaining cases
	UPDATE #sp_who_tmp2
	SET cmd = 'AWAITING COMMAND'
	WHERE TRIM(ISNULL(cmd,'')) = '' AND status = 'idle'
	
	UPDATE #sp_who_tmp2
	SET cmd = 'UNKNOWN'
	WHERE TRIM(cmd) = ''	
	
	-- Format the result set as narrow as possible for readability
	SET @hide_col += ',hostprocess'
	EXECUTE sys.sp_babelfish_autoformat @tab='#sp_who_tmp2', @orderby='ORDER BY spid', @hiddencols=@hide_col, @printrc=0
	RETURN
END	
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_who(IN sys.sysname, IN sys.VARCHAR(30)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_stored_procedures(
    "@sp_name" sys.nvarchar(390) = '',
    "@sp_owner" sys.nvarchar(384) = '',
    "@sp_qualifier" sys.sysname = '',
    "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
	IF (@sp_qualifier != '') AND LOWER(sys.db_name()) != LOWER(@sp_qualifier)
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	-- If @sp_name or @sp_owner = '%', it gets converted to NULL or '' regardless of @fusepattern 
	IF @sp_name = '%'
	BEGIN
		SELECT @sp_name = ''
	END
	
	IF @sp_owner = '%'
	BEGIN
		SELECT @sp_owner = ''
	END
	
	-- Changes fusepattern to 0 if no wildcards are used. NOTE: Need to add [] wildcard pattern when it is implemented. Wait for BABEL-2452
	IF @fusepattern = 1
	BEGIN
		IF (CHARINDEX('%', @sp_name) != 0 AND CHARINDEX('_', @sp_name) != 0 AND CHARINDEX('%', @sp_owner) != 0 AND CHARINDEX('_', @sp_owner) != 0 )
		BEGIN
			SELECT @fusepattern = 0;
		END
	END
	
	-- Condition for when sp_name argument is not given or is null, or is just a wildcard (same order)
	IF COALESCE(@sp_name, '') = ''
	BEGIN
		IF @fusepattern=1 
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
		ELSE
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END
	-- When @sp_name is not null
	ELSE
	BEGIN
		-- When sp_owner is null and fusepattern = 0
		IF (@fusepattern = 0 AND  COALESCE(@sp_owner,'') = '') 
		BEGIN
			IF EXISTS ( -- Search in the sys schema 
					SELECT * FROM sys.sp_stored_procedures_view
					WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
						AND (LOWER(procedure_owner) = 'sys'))
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
					)
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE -- Search in the dbo schema (if nothing exists it should just return nothing). 
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'dbo')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			
		END
		ELSE IF (@fusepattern = 0 AND  COALESCE(@sp_owner,'') != '')
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE (LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) = LOWER(@sp_name))
				AND (LOWER(procedure_owner) = LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
		ELSE -- fusepattern = 1
		BEGIN
			SELECT 
			PROCEDURE_QUALIFIER,
			PROCEDURE_OWNER,
			PROCEDURE_NAME,
			NUM_INPUT_PARAMS,
			NUM_OUTPUT_PARAMS,
			NUM_RESULT_SETS,
			REMARKS,
			PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
			WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, LEN(procedure_name)-2)) LIKE LOWER(@sp_name))
				AND ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT,
                                                                 IN p_dateval DATE,
                                                                 IN p_style NUMERIC DEFAULT 20)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_dateval DATE;
    v_style SMALLINT;
    v_month SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 13) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 113) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF (v_style IN (8, 24, 108)) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_dateval := CASE
                    WHEN (v_style NOT IN (130, 131)) THEN p_dateval
                    ELSE sys.babelfish_conv_greg_to_hijri(p_dateval) + 1
                 END;

    v_day := PG_CATALOG.ltrim(to_char(v_dateval, 'DD'), '0');
    v_month := to_char(v_dateval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
 RAISE NOTICE 'v_language=[%]', v_language;		  
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    v_resmask := CASE
                    WHEN (v_style IN (1, 22)) THEN 'MM/DD/YY'
                    WHEN (v_style = 101) THEN 'MM/DD/YYYY'
                    WHEN (v_style = 2) THEN 'YY.MM.DD'
                    WHEN (v_style = 102) THEN 'YYYY.MM.DD'
                    WHEN (v_style = 3) THEN 'DD/MM/YY'
                    WHEN (v_style = 103) THEN 'DD/MM/YYYY'
                    WHEN (v_style = 4) THEN 'DD.MM.YY'
                    WHEN (v_style = 104) THEN 'DD.MM.YYYY'
                    WHEN (v_style = 5) THEN 'DD-MM-YY'
                    WHEN (v_style = 105) THEN 'DD-MM-YYYY'
                    WHEN (v_style = 6) THEN 'DD $mnme$ YY'
                    WHEN (v_style IN (13, 106, 113)) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 7) THEN '$mnme$ DD, YY'
                    WHEN (v_style = 107) THEN '$mnme$ DD, YYYY'
                    WHEN (v_style = 10) THEN 'MM-DD-YY'
                    WHEN (v_style = 110) THEN 'MM-DD-YYYY'
                    WHEN (v_style = 11) THEN 'YY/MM/DD'
                    WHEN (v_style = 111) THEN 'YYYY/MM/DD'
                    WHEN (v_style = 12) THEN 'YYMMDD'
                    WHEN (v_style = 112) THEN 'YYYYMMDD'
                    WHEN (v_style IN (20, 21, 23, 25, 120, 121, 126, 127)) THEN 'YYYY-MM-DD'
                    WHEN (v_style = 130) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 131) THEN pg_catalog.format('%s/MM/YYYY', lpad(v_day, 2, ' '))
                    WHEN (v_style IN (0, 9, 100, 109)) THEN pg_catalog.format('$mnme$ %s YYYY', lpad(v_day, 2, ' '))
                 END;

    v_resstring := to_char(v_dateval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from DATE to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type DATE to %s.', trim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr,
                                     lower(v_res_datatype),
                                     v_maxlength),
                   DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT -1)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_hour VARCHAR COLLATE "C";
    v_month SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_fractsep VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^(?:DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    v_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE;
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;

        v_src_datatype := PG_CATALOG.rtrim(split_part(v_src_datatype, '(', 1));

        IF (v_src_datatype <> 'DATETIME2' AND v_scale IS NOT NULL) THEN
            RAISE invalid_indicator_parameter_value;
        ELSIF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;

        v_scale := coalesce(v_scale, 7);
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (-1, 120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4)
        THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_datetimeval := CASE
                        WHEN (v_style NOT IN (130, 131)) THEN p_datetimeval
                        ELSE sys.babelfish_conv_greg_to_hijri(p_datetimeval) + INTERVAL '1 day'
                     END;

    v_day := PG_CATALOG.ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := PG_CATALOG.ltrim(to_char(v_datetimeval, 'HH12'), '0');
    v_month := to_char(v_datetimeval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    IF (v_src_datatype IN ('DATETIME', 'SMALLDATETIME')) THEN
        v_fseconds := sys.babelfish_round_fractseconds(to_char(v_datetimeval, 'MS'));

        IF (v_fseconds::INTEGER = 1000) THEN
            v_fseconds := '000';
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        ELSE
            v_fseconds := lpad(v_fseconds, 3, '0');
        END IF;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(v_datetimeval, 'US'), v_scale);

        IF (v_scale = 7) THEN
            v_fseconds := concat(v_fseconds, '0');
        END IF;
    END IF;

    v_fractsep := CASE v_src_datatype
                     WHEN 'DATETIME2' THEN '.'
                     ELSE ':'
                  END;

    IF ((v_style = -1 AND v_src_datatype <> 'DATETIME2') OR
        v_style IN (0, 9, 100, 109))
    THEN
        v_resmask := pg_catalog.format('$mnme$ %s YYYY %s:MI%s',
                            lpad(v_day, 2, ' '),
                            lpad(v_hour, 2, ' '),
                            CASE
                               WHEN (v_style IN (-1, 0, 100)) THEN 'AM'
                               ELSE pg_catalog.format(':SS:%sAM', v_fseconds)
                            END);
    ELSIF (v_style = 1) THEN
        v_resmask := 'MM/DD/YY';
    ELSIF (v_style = 101) THEN
        v_resmask := 'MM/DD/YYYY';
    ELSIF (v_style = 2) THEN
        v_resmask := 'YY.MM.DD';
    ELSIF (v_style = 102) THEN
        v_resmask := 'YYYY.MM.DD';
    ELSIF (v_style = 3) THEN
        v_resmask := 'DD/MM/YY';
    ELSIF (v_style = 103) THEN
        v_resmask := 'DD/MM/YYYY';
    ELSIF (v_style = 4) THEN
        v_resmask := 'DD.MM.YY';
    ELSIF (v_style = 104) THEN
        v_resmask := 'DD.MM.YYYY';
    ELSIF (v_style = 5) THEN
        v_resmask := 'DD-MM-YY';
    ELSIF (v_style = 105) THEN
        v_resmask := 'DD-MM-YYYY';
    ELSIF (v_style = 6) THEN
        v_resmask := 'DD $mnme$ YY';
    ELSIF (v_style = 106) THEN
        v_resmask := 'DD $mnme$ YYYY';
    ELSIF (v_style = 7) THEN
        v_resmask := '$mnme$ DD, YY';
    ELSIF (v_style = 107) THEN
        v_resmask := '$mnme$ DD, YYYY';
    ELSIF (v_style IN (8, 24, 108)) THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style = 10) THEN
        v_resmask := 'MM-DD-YY';
    ELSIF (v_style = 110) THEN
        v_resmask := 'MM-DD-YYYY';
    ELSIF (v_style = 11) THEN
        v_resmask := 'YY/MM/DD';
    ELSIF (v_style = 111) THEN
        v_resmask := 'YYYY/MM/DD';
    ELSIF (v_style = 12) THEN
        v_resmask := 'YYMMDD';
    ELSIF (v_style = 112) THEN
        v_resmask := 'YYYYMMDD';
    ELSIF (v_style IN (13, 113)) THEN
        v_resmask := pg_catalog.format('DD $mnme$ YYYY HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (14, 114)) THEN
        v_resmask := pg_catalog.format('HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (20, 120)) THEN
        v_resmask := 'YYYY-MM-DD HH24:MI:SS';
    ELSIF ((v_style = -1 AND v_src_datatype = 'DATETIME2') OR
           v_style IN (21, 25, 121))
    THEN
        v_resmask := pg_catalog.format('YYYY-MM-DD HH24:MI:SS.%s', v_fseconds);
    ELSIF (v_style = 22) THEN
        v_resmask := pg_catalog.format('MM/DD/YY %s:MI:SS AM', lpad(v_hour, 2, ' '));
    ELSIF (v_style = 23) THEN
        v_resmask := 'YYYY-MM-DD';
    ELSIF (v_style IN (126, 127)) THEN
        v_resmask := CASE v_src_datatype
                        WHEN 'SMALLDATETIME' THEN 'YYYY-MM-DDT$rem$HH24:MI:SS'
                        ELSE pg_catalog.format('YYYY-MM-DDT$rem$HH24:MI:SS.%s', v_fseconds)
                     END;
    ELSIF (v_style IN (130, 131)) THEN
        v_resmask := concat(CASE p_style
                               WHEN 131 THEN pg_catalog.format('%s/MM/YYYY ', lpad(v_day, 2, ' '))
                               ELSE pg_catalog.format('%s $mnme$ YYYY ', lpad(v_day, 2, ' '))
                            END,
                            pg_catalog.format('%s:MI:SS%s%sAM', lpad(v_hour, 2, ' '), v_fractsep, v_fseconds));
    END IF;

    v_resstring := to_char(v_datetimeval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := pg_catalog.replace(v_resstring, '$rem$', '');

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2'' or ''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "srcdatatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_src_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from %s to a character string.',
                                      v_style, v_src_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                      v_lengthexpr, lower(v_res_datatype), v_maxlength),
                    DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                    HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT,
                                                                 IN p_src_datatype TEXT,
                                                                 IN p_timeval TIME(6) WITHOUT TIME ZONE,
                                                                 IN p_style NUMERIC DEFAULT 25)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_hours VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_res_length SMALLINT;
    v_res_datatype VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_maxlength SMALLINT;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    -- We use the regex below to make sure input p_datatype is one of them
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    -- We use the regex below to get the length of the datatype, if specified
    -- For example, to get the '10' out of 'varchar(10)'
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^\s*(?:TIME)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := coalesce(substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT, 7);

        IF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP)
    THEN
        v_res_datatype := PG_CATALOG.rtrim(split_part(v_datatype, '(', 1));

        v_res_maxlength := CASE
                              WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                              ELSE NVARCHAR_MAX
                           END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_res_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF ((v_style BETWEEN 1 AND 7) OR
           (v_style BETWEEN 10 AND 12) OR
           (v_style BETWEEN 101 AND 107) OR
           (v_style BETWEEN 110 AND 112) OR
           v_style = 23)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_hours := PG_CATALOG.ltrim(to_char(p_timeval, 'HH12'), '0');
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(p_timeval, 'US'), v_scale);

    IF (v_scale = 7) THEN
        v_fseconds := concat(v_fseconds, '0');
    END IF;

    IF (v_style IN (0, 100))
    THEN
        v_resmask := concat(v_hours, ':MIAM');
    ELSIF (v_style IN (8, 20, 24, 108, 120))
    THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style IN (9, 109))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(v_hours, ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
        v_resmask := pg_catalog.format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
                     END;
    END IF;

    v_resstring := to_char(p_timeval, v_resmask);

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "src_datatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr, lower(v_res_datatype), v_res_maxlength),
                   DETAIL := 'Use of incorrect size value of target data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from TIME to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type TIME to %s.',
                                      PG_CATALOG.rtrim(split_part(trim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION babelfish_remove_delimiter_pair(IN name TEXT)
RETURNS TEXT AS
$BODY$
BEGIN
    IF name IN('[' COLLATE "C", ']' COLLATE "C", '"' COLLATE "C") THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) = '[' COLLATE "C" AND PG_CATALOG.right(name, 1) = ']' COLLATE "C" THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) = '[' COLLATE "C" AND PG_CATALOG.right(name, 1) != ']' COLLATE "C" THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) != '[' COLLATE "C" AND PG_CATALOG.right(name, 1) = ']' COLLATE "C" THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) = '"' COLLATE "C" AND PG_CATALOG.right(name, 1) = '"' COLLATE "C" THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) = '"' COLLATE "C" AND PG_CATALOG.right(name, 1) != '"' COLLATE "C" THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND PG_CATALOG.left(name, 1) != '"' COLLATE "C" AND PG_CATALOG.right(name, 1) = '"' COLLATE "C" THEN
        RETURN NULL;
    
    END IF;
    RETURN name;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_job (
  par_job_name varchar,
  par_enabled smallint = 1,
  par_description varchar = NULL::character varying,
  par_start_step_id integer = 1,
  par_category_name varchar = NULL::character varying,
  par_category_id integer = NULL::integer,
  par_owner_login_name varchar = NULL::character varying,
  par_notify_level_eventlog integer = 2,
  par_notify_level_email integer = 0,
  par_notify_level_netsend integer = 0,
  par_notify_level_page integer = 0,
  par_notify_email_operator_name varchar = NULL::character varying,
  par_notify_netsend_operator_name varchar = NULL::character varying,
  par_notify_page_operator_name varchar = NULL::character varying,
  par_delete_level integer = 0,
  inout par_job_id integer = NULL::integer,
  par_originating_server varchar = NULL::character varying,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_retval INT DEFAULT 0;
  var_notify_email_operator_id INT DEFAULT 0;
  var_notify_email_operator_name VARCHAR(128);
  var_notify_netsend_operator_id INT DEFAULT 0;
  var_notify_page_operator_id INT DEFAULT 0;
  var_owner_sid CHAR(85) ;
  var_originating_server_id INT DEFAULT 0;
BEGIN
  /* Remove any leading/trailing spaces from parameters (except @owner_login_name) */
  SELECT UPPER(PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_originating_server))) INTO par_originating_server;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_job_name)) INTO par_job_name;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_description)) INTO par_description;
  SELECT '[Uncategorized (Local)]' INTO par_category_name;
  SELECT 0 INTO par_category_id;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_email_operator_name)) INTO par_notify_email_operator_name;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_netsend_operator_name)) INTO par_notify_netsend_operator_name;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_page_operator_name)) INTO par_notify_page_operator_name;
  SELECT NULL INTO var_originating_server_id; /* Turn [nullable] empty string parameters into NULLs */
  SELECT NULL INTO par_job_id;

  IF (par_originating_server = '')
  THEN
    SELECT NULL INTO par_originating_server;
  END IF;

  IF (par_description = '')
  THEN
    SELECT NULL INTO par_description;
  END IF;

  IF (par_category_name = '')
  THEN
    SELECT NULL INTO par_category_name;
  END IF;

  IF (par_notify_email_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_email_operator_name;
  END IF;

  IF (par_notify_netsend_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_netsend_operator_name;
  END IF;

  IF (par_notify_page_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_page_operator_name;
  END IF;

  /* Check parameters */
  SELECT t.par_owner_sid
       , t.par_notify_level_email
       , t.par_notify_level_netsend
       , t.par_notify_level_page
       , t.par_category_id
       , t.par_notify_email_operator_id
       , t.par_notify_netsend_operator_id
       , t.par_notify_page_operator_id
       , t.par_originating_server
       , t.returncode
    FROM sys.babelfish_sp_verify_job(
         par_job_id /* NULL::integer */
       , par_job_name
       , par_enabled
       , par_start_step_id
       , par_category_name
       , var_owner_sid /* par_owner_sid */
       , par_notify_level_eventlog
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , par_notify_email_operator_name
       , par_notify_netsend_operator_name
       , par_notify_page_operator_name
       , par_delete_level
       , par_category_id
       , var_notify_email_operator_id /* par_notify_email_operator_id */
       , var_notify_netsend_operator_id /* par_notify_netsend_operator_id */
       , var_notify_page_operator_id /* par_notify_page_operator_id */
       , par_originating_server
       ) t
    INTO var_owner_sid
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , par_category_id
       , var_notify_email_operator_id
       , var_notify_netsend_operator_id
       , var_notify_page_operator_id
       , par_originating_server
       , var_retval;

  IF (var_retval <> 0)  /* Failure */
  THEN
    returncode := 1;
    RETURN;
  END IF;

  var_notify_email_operator_name := par_notify_email_operator_name;

  /* Default the description (if not supplied) */
  IF (par_description IS NULL)
  THEN
    SELECT 'No description available.' INTO par_description;
  END IF;

  var_originating_server_id := 0;
  var_owner_sid := '';

  INSERT
    INTO sys.sysjobs (
         originating_server_id
       , name
       , enabled
       , description
       , start_step_id
       , category_id
       , owner_sid
       , notify_level_eventlog
       , notify_level_email
       , notify_level_netsend
       , notify_level_page
       , notify_email_operator_id
       , notify_email_operator_name
       , notify_netsend_operator_id
       , notify_page_operator_id
       , delete_level
       , version_number
    )
  VALUES (
         var_originating_server_id
       , par_job_name
       , par_enabled
       , par_description
       , par_start_step_id
       , par_category_id
       , var_owner_sid
       , par_notify_level_eventlog
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , var_notify_email_operator_id
       , var_notify_email_operator_name
       , var_notify_netsend_operator_id
       , var_notify_page_operator_id
       , par_delete_level
       , 1);

  /* scope_identity() */
  SELECT LASTVAL() INTO par_job_id;

  /* Version number 1 */
  /* SELECT @retval = @@error */
  /* 0 means success */
  returncode := var_retval;
  RETURN;

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_schedule (
  par_schedule_name varchar,
  par_enabled smallint = 1,
  par_freq_type integer = 0,
  par_freq_interval integer = 0,
  par_freq_subday_type integer = 0,
  par_freq_subday_interval integer = 0,
  par_freq_relative_interval integer = 0,
  par_freq_recurrence_factor integer = 0,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = 99991231,
  par_active_start_time integer = 0,
  par_active_end_time integer = 235959,
  par_owner_login_name varchar = NULL::character varying,
  inout par_schedule_uid char = NULL::bpchar,
  inout par_schedule_id integer = NULL::integer,
  par_originating_server varchar = NULL::character varying,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_owner_sid CHAR(85);
  var_orig_server_id INT;
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_schedule_name))
       , PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_owner_login_name))
       , UPPER(PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_originating_server)))
       , 0
    INTO par_schedule_name
       , par_owner_login_name
       , par_originating_server
       , par_schedule_id;

  /* Check schedule (frequency and owner) parameters */
  SELECT t.par_freq_interval
       , t.par_freq_subday_type
       , t.par_freq_subday_interval
       , t.par_freq_relative_interval
       , t.par_freq_recurrence_factor
       , t.par_active_start_date
       , t.par_active_start_time
       , t.par_active_end_date
       , t.par_active_end_time
       , t.returncode
    FROM sys.babelfish_sp_verify_schedule(
         NULL::integer /* @schedule_id  -- schedule_id does not exist for the new schedule */
       , par_schedule_name /* @name */
       , par_enabled /* @enabled */
       , par_freq_type /* @freq_type */
       , par_freq_interval /* @freq_interval */
       , par_freq_subday_type /* @freq_subday_type */
       , par_freq_subday_interval /* @freq_subday_interval */
       , par_freq_relative_interval /* @freq_relative_interval */
       , par_freq_recurrence_factor /* @freq_recurrence_factor */
       , par_active_start_date /* @active_start_date */
       , par_active_start_time /* @active_start_time */
       , par_active_end_date /* @active_end_date */
       , par_active_end_time /* @active_end_time */
       , var_owner_sid
       ) t
    INTO par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_start_time
       , par_active_end_date
       , par_active_end_time
       , var_retval /* @owner_sid */;

  IF (var_retval <> 0) THEN /* Failure */
    returncode := 1;
        RETURN;
    END IF;

  IF (par_schedule_uid IS NULL)
  THEN /* Assign the GUID */
    /* uuid without extensions uuid-ossp (cheat) */
    SELECT uuid_in(md5(random()::text || clock_timestamp()::text)::cstring) INTO par_schedule_uid;
  END IF;

  var_orig_server_id := 0;
  var_owner_sid := uuid_in(md5(random()::text || clock_timestamp()::text)::cstring);


  INSERT
    INTO sys.sysschedules (
         schedule_uid
       , originating_server_id
       , name
       , owner_sid
       , enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
   )
  VALUES (
         par_schedule_uid
       , var_orig_server_id
       , par_schedule_name
       , var_owner_sid
       , par_enabled
       , par_freq_type
       , par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_end_date
       , par_active_start_time
       , par_active_end_time
  );

  /* ZZZ */
  SELECT 0 /* @@ERROR, */, LASTVAL()
    INTO var_retval, par_schedule_id;

  /* 0 means success */
  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_delete_jobschedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_name varchar = NULL::character varying,
  par_keep_schedule integer = 0,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_sched_count INT;
  var_schedule_id INT;
  var_job_owner_sid CHAR(85);
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name)) INTO par_name;

  /* Check that we can uniquely identify the job */
  SELECT t.par_job_name
       , t.par_job_id
       , t.par_owner_sid
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers(
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'
       , var_job_owner_sid
       ) t
    INTO par_job_name
       , par_job_id
       , var_job_owner_sid
       , var_retval;

  IF (var_retval <> 0) THEN /* Failure */
    returncode := 1;
    RETURN;
  END IF;

  IF (LOWER(UPPER(par_name)) = LOWER('ALL'))
  THEN
    SELECT - 1 INTO var_schedule_id;

    /* We use this in the call to sp_sqlagent_notify */
    /* Delete the schedule(s) if it isn't being used by other jobs */
    CREATE TEMPORARY TABLE "#temp_schedules_to_delete" (schedule_id INT NOT NULL)
    /* If user requests that the schedules be removed (the legacy behavoir) */
    /* make sure it isnt being used by other jobs */;

    IF (par_keep_schedule = 0)
    THEN
      /* Get the list of schedules to delete */
      INSERT INTO "#temp_schedules_to_delete"
      SELECT DISTINCT schedule_id
        FROM sys.sysschedules
       WHERE (schedule_id IN (SELECT schedule_id
                                FROM sys.sysjobschedules
                               WHERE (job_id = par_job_id)));
      /* make sure no other jobs use these schedules */
      IF (EXISTS (SELECT *
                    FROM sys.sysjobschedules
                   WHERE (job_id <> par_job_id)
                     AND (schedule_id IN (SELECT schedule_id
                                            FROM "#temp_schedules_to_delete"))))
      THEN /* Failure */
        RAISE 'One or more schedules were not deleted because they are being used by at least one other job. Use "sp_detach_schedule" to remove schedules from a job.' USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;

    /* OK to delete the jobschedule */
    DELETE FROM sys.sysjobschedules
     WHERE (job_id = par_job_id);

    /* OK to delete the schedule - temp_schedules_to_delete is empty if @keep_schedule <> 0 */
    DELETE FROM sys.sysschedules
     WHERE schedule_id IN (SELECT schedule_id FROM "#temp_schedules_to_delete");
  ELSE ---- IF (LOWER(UPPER(par_name)) = LOWER('ALL'))

    -- Need to use sp_detach_schedule to remove this ambiguous schedule name
    IF(var_sched_count > 1) /* Failure */
    THEN
      RAISE 'More than one schedule named "%" is attached to job "%". Use "sp_detach_schedule" to remove schedules from a job.', par_name, par_job_name  USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;

    --If user requests that the schedule be removed (the legacy behavoir)
    --make sure it isnt being used by another job
    IF (par_keep_schedule = 0)
    THEN
      IF(EXISTS(SELECT *
                  FROM sys.sysjobschedules
                 WHERE (schedule_id = var_schedule_id)
                   AND (job_id <> par_job_id)))
      THEN /* Failure */
        RAISE 'Schedule "%" was not deleted because it is being used by at least one other job. Use "sp_detach_schedule" to remove schedules from a job.', par_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;

    /* Delete the job schedule link first */
    DELETE FROM sys.sysjobschedules
     WHERE (job_id = par_job_id)
       AND (schedule_id = var_schedule_id);

    /* Delete schedule if required */
    IF (par_keep_schedule = 0)
    THEN
      /* Now delete the schedule if required */
      DELETE FROM sys.sysschedules
       WHERE (schedule_id = var_schedule_id);
    END IF;

    SELECT t.returncode
    FROM sys.babelfish_sp_aws_del_jobschedule(par_job_id, var_schedule_id) t
    INTO var_retval;


  END IF;

  /* Update the job's version/last-modified information */
  UPDATE sys.sysjobs
     SET version_number = version_number + 1
       -- , date_modified = GETDATE() /
   WHERE job_id = par_job_id;

  DROP TABLE IF EXISTS "#temp_schedules_to_delete";


  /* 0 means success */
  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_job (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_description varchar = NULL::character varying,
  par_start_step_id integer = NULL::integer,
  par_category_name varchar = NULL::character varying,
  par_owner_login_name varchar = NULL::character varying,
  par_notify_level_eventlog integer = NULL::integer,
  par_notify_level_email integer = NULL::integer,
  par_notify_level_netsend integer = NULL::integer,
  par_notify_level_page integer = NULL::integer,
  par_notify_email_operator_name varchar = NULL::character varying,
  par_notify_netsend_operator_name varchar = NULL::character varying,
  par_notify_page_operator_name varchar = NULL::character varying,
  par_delete_level integer = NULL::integer,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_category_id INT;
    var_notify_email_operator_id INT;
    var_notify_netsend_operator_id INT;
    var_notify_page_operator_id INT;
    var_owner_sid CHAR(85);
    var_alert_id INT;
    var_cached_attribute_modified INT;
    var_is_sysadmin INT;
    var_current_owner VARCHAR(128);
    var_enable_only_used INT;
    var_x_new_name VARCHAR(128);
    var_x_enabled SMALLINT;
    var_x_description VARCHAR(512);
    var_x_start_step_id INT;
    var_x_category_name VARCHAR(128);
    var_x_category_id INT;
    var_x_owner_sid CHAR(85);
    var_x_notify_level_eventlog INT;
    var_x_notify_level_email INT;
    var_x_notify_level_netsend INT;
    var_x_notify_level_page INT;
    var_x_notify_email_operator_name VARCHAR(128);
    var_x_notify_netsnd_operator_name VARCHAR(128);
    var_x_notify_page_operator_name VARCHAR(128);
    var_x_delete_level INT;
    var_x_originating_server_id INT;
    var_x_master_server SMALLINT;
BEGIN
    /* Not updatable */
    /* Remove any leading/trailing spaces from parameters (except @owner_login_name) */
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_job_name))
        INTO par_job_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_new_name))
        INTO par_new_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_description))
        INTO par_description;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_category_name))
        INTO par_category_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_email_operator_name))
        INTO par_notify_email_operator_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_netsend_operator_name))
        INTO par_notify_netsend_operator_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_notify_page_operator_name))
        INTO par_notify_page_operator_name
    /* Are we modifying an attribute which tsql agent caches? */;

    IF ((par_new_name IS NOT NULL) OR (par_enabled IS NOT NULL) OR (par_start_step_id IS NOT NULL) OR (par_owner_login_name IS NOT NULL) OR (par_notify_level_eventlog IS NOT NULL) OR (par_notify_level_email IS NOT NULL) OR (par_notify_level_netsend IS NOT NULL) OR (par_notify_level_page IS NOT NULL) OR (par_notify_email_operator_name IS NOT NULL) OR (par_notify_netsend_operator_name IS NOT NULL) OR (par_notify_page_operator_name IS NOT NULL) OR (par_delete_level IS NOT NULL)) THEN
        SELECT
            1
            INTO var_cached_attribute_modified;
    ELSE
        SELECT
            0
            INTO var_cached_attribute_modified;
    END IF
    /* Is @enable the only parameter used beside jobname and jobid? */;

    IF ((par_enabled IS NOT NULL) AND (par_new_name IS NULL) AND (par_description IS NULL) AND (par_start_step_id IS NULL) AND (par_category_name IS NULL) AND (par_owner_login_name IS NULL) AND (par_notify_level_eventlog IS NULL) AND (par_notify_level_email IS NULL) AND (par_notify_level_netsend IS NULL) AND (par_notify_level_page IS NULL) AND (par_notify_email_operator_name IS NULL) AND (par_notify_netsend_operator_name IS NULL) AND (par_notify_page_operator_name IS NULL) AND (par_delete_level IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
    /* Fill out the values for all non-supplied parameters from the existing values */;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_new_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_description IS NULL) THEN
        SELECT
            var_x_description
            INTO par_description;
    END IF;

    IF (par_start_step_id IS NULL) THEN
        SELECT
            var_x_start_step_id
            INTO par_start_step_id;
    END IF;

    IF (par_category_name IS NULL) THEN
        SELECT
            var_x_category_name
            INTO par_category_name;
    END IF;

    IF (var_owner_sid IS NULL) THEN
        SELECT
            var_x_owner_sid
            INTO var_owner_sid;
    END IF;

    IF (par_notify_level_eventlog IS NULL) THEN
        SELECT
            var_x_notify_level_eventlog
            INTO par_notify_level_eventlog;
    END IF;

    IF (par_notify_level_email IS NULL) THEN
        SELECT
            var_x_notify_level_email
            INTO par_notify_level_email;
    END IF;

    IF (par_notify_level_netsend IS NULL) THEN
        SELECT
            var_x_notify_level_netsend
            INTO par_notify_level_netsend;
    END IF;

    IF (par_notify_level_page IS NULL) THEN
        SELECT
            var_x_notify_level_page
            INTO par_notify_level_page;
    END IF;

    IF (par_notify_email_operator_name IS NULL) THEN
        SELECT
            var_x_notify_email_operator_name
            INTO par_notify_email_operator_name;
    END IF;

    IF (par_notify_netsend_operator_name IS NULL) THEN
        SELECT
            var_x_notify_netsnd_operator_name
            INTO par_notify_netsend_operator_name;
    END IF;

    IF (par_notify_page_operator_name IS NULL) THEN
        SELECT
            var_x_notify_page_operator_name
            INTO par_notify_page_operator_name;
    END IF;

    IF (par_delete_level IS NULL) THEN
        SELECT
            var_x_delete_level
            INTO par_delete_level;
    END IF
    /* Turn [nullable] empty string parameters into NULLs */;

    IF (LOWER(par_description) = LOWER('')) THEN
        SELECT
            NULL
            INTO par_description;
    END IF;

    IF (par_category_name = '') THEN
        SELECT
            NULL
            INTO par_category_name;
    END IF;

    IF (par_notify_email_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_email_operator_name;
    END IF;

    IF (par_notify_netsend_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_netsend_operator_name;
    END IF;

    IF (par_notify_page_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_page_operator_name;
    END IF
    /* Check new values */;
    SELECT
        t.par_owner_sid, t.par_notify_level_email, t.par_notify_level_netsend, t.par_notify_level_page,
        t.par_category_id, t.par_notify_email_operator_id, t.par_notify_netsend_operator_id, t.par_notify_page_operator_id, t.par_originating_server, t.ReturnCode
        FROM sys.babelfish_sp_verify_job(par_job_id, par_new_name, par_enabled, par_start_step_id, par_category_name, var_owner_sid, par_notify_level_eventlog, par_notify_level_email, par_notify_level_netsend, par_notify_level_page, par_notify_email_operator_name, par_notify_netsend_operator_name, par_notify_page_operator_name, par_delete_level, var_category_id, var_notify_email_operator_id, var_notify_netsend_operator_id, var_notify_page_operator_id, NULL) t
        INTO var_owner_sid, par_notify_level_email, par_notify_level_netsend, par_notify_level_page, var_category_id, var_notify_email_operator_id, var_notify_netsend_operator_id, var_notify_page_operator_id, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* BEGIN TRANSACTION */
    /* If the job is being re-assigned, modify sysjobsteps.database_user_name as necessary */;

    IF (par_owner_login_name IS NOT NULL) THEN
        IF (EXISTS (SELECT
            1
            FROM sys.sysjobsteps
            WHERE (job_id = par_job_id) AND (LOWER(subsystem) = LOWER('TSQL')))) THEN
            /* The job is being re-assigned to an non-SA */
            UPDATE sys.sysjobsteps
            SET database_user_name = NULL
                WHERE (job_id = par_job_id) AND (LOWER(subsystem) = LOWER('TSQL'));
        END IF;
    END IF;
    UPDATE sys.sysjobs
    SET name = par_new_name, enabled = par_enabled, description = par_description, start_step_id = par_start_step_id, category_id = var_category_id
    /* Returned from sp_verify_job */, owner_sid = var_owner_sid, notify_level_eventlog = par_notify_level_eventlog, notify_level_email = par_notify_level_email, notify_level_netsend = par_notify_level_netsend, notify_level_page = par_notify_level_page, notify_email_operator_id = var_notify_email_operator_id
    /* Returned from sp_verify_job */, notify_netsend_operator_id = var_notify_netsend_operator_id
    /* Returned from sp_verify_job */, notify_page_operator_id = var_notify_page_operator_id
    /* Returned from sp_verify_job */, delete_level = par_delete_level, version_number = version_number + 1
    /* ,  -- Update the job's version */
    /* date_modified              = GETDATE()            -- Update the job's last-modified information */
        WHERE (job_id = par_job_id);
    SELECT
        0
        INTO var_retval
    /* @@error */
    /* COMMIT TRANSACTION */;
    ReturnCode := (var_retval);
    RETURN
    /* 0 means success */;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_jobschedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_freq_type integer = NULL::integer,
  par_freq_interval integer = NULL::integer,
  par_freq_subday_type integer = NULL::integer,
  par_freq_subday_interval integer = NULL::integer,
  par_freq_relative_interval integer = NULL::integer,
  par_freq_recurrence_factor integer = NULL::integer,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = NULL::integer,
  par_active_start_time integer = NULL::integer,
  par_active_end_time integer = NULL::integer,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_sched_count INT;
    var_schedule_id INT;
    var_job_owner_sid CHAR(85);
    var_enable_only_used INT;
    var_x_name VARCHAR(128);
    var_x_enabled SMALLINT;
    var_x_freq_type INT;
    var_x_freq_interval INT;
    var_x_freq_subday_type INT;
    var_x_freq_subday_interval INT;
    var_x_freq_relative_interval INT;
    var_x_freq_recurrence_factor INT;
    var_x_active_start_date INT;
    var_x_active_end_date INT;
    var_x_active_start_time INT;
    var_x_active_end_time INT;
    var_owner_sid CHAR(85);
BEGIN
    /* Remove any leading/trailing spaces from parameters */
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name))
        INTO par_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_new_name))
        INTO par_new_name
    /* Turn [nullable] empty string parameters into NULLs */;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
    /* Check that we can uniquely identify the job */;
    SELECT
        t.par_job_name, t.par_job_id, t.par_owner_sid, t.ReturnCode
        FROM sys.babelfish_sp_verify_job_identifiers('@job_name', '@job_id', par_job_name, par_job_id, 'TEST', var_job_owner_sid) t
        INTO par_job_name, par_job_id, var_job_owner_sid, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* Is @enable the only parameter used beside jobname and jobid? */;

    IF ((par_enabled IS NOT NULL) AND (par_name IS NULL) AND (par_new_name IS NULL) AND (par_freq_type IS NULL) AND (par_freq_interval IS NULL) AND (par_freq_subday_type IS NULL) AND (par_freq_subday_interval IS NULL) AND (par_freq_relative_interval IS NULL) AND (par_freq_recurrence_factor IS NULL) AND (par_active_start_date IS NULL) AND (par_active_end_date IS NULL) AND (par_active_start_time IS NULL) AND (par_active_end_time IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_freq_type IS NULL) THEN
        SELECT
            var_x_freq_type
            INTO par_freq_type;
    END IF;

    IF (par_freq_interval IS NULL) THEN
        SELECT
            var_x_freq_interval
            INTO par_freq_interval;
    END IF;

    IF (par_freq_subday_type IS NULL) THEN
        SELECT
            var_x_freq_subday_type
            INTO par_freq_subday_type;
    END IF;

    IF (par_freq_subday_interval IS NULL) THEN
        SELECT
            var_x_freq_subday_interval
            INTO par_freq_subday_interval;
    END IF;

    IF (par_freq_relative_interval IS NULL) THEN
        SELECT
            var_x_freq_relative_interval
            INTO par_freq_relative_interval;
    END IF;

    IF (par_freq_recurrence_factor IS NULL) THEN
        SELECT
            var_x_freq_recurrence_factor
            INTO par_freq_recurrence_factor;
    END IF;

    IF (par_active_start_date IS NULL) THEN
        SELECT
            var_x_active_start_date
            INTO par_active_start_date;
    END IF;

    IF (par_active_end_date IS NULL) THEN
        SELECT
            var_x_active_end_date
            INTO par_active_end_date;
    END IF;

    IF (par_active_start_time IS NULL) THEN
        SELECT
            var_x_active_start_time
            INTO par_active_start_time;
    END IF;

    IF (par_active_end_time IS NULL) THEN
        SELECT
            var_x_active_end_time
            INTO par_active_end_time;
    END IF
    /* Check schedule (frequency and owner) parameters */;
    SELECT
        t.par_freq_interval, t.par_freq_subday_type, t.par_freq_subday_interval, t.par_freq_relative_interval, t.par_freq_recurrence_factor, t.par_active_start_date, t.par_active_start_time,
        t.par_active_end_date, t.par_active_end_time, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule(var_schedule_id
        /* @schedule_id */, par_new_name
        /* @name */, par_enabled
        /* @enabled */, par_freq_type
        /* @freq_type */, par_freq_interval
        /* @freq_interval */, par_freq_subday_type
        /* @freq_subday_type */, par_freq_subday_interval
        /* @freq_subday_interval */, par_freq_relative_interval
        /* @freq_relative_interval */, par_freq_recurrence_factor
        /* @freq_recurrence_factor */, par_active_start_date
        /* @active_start_date */, par_active_start_time
        /* @active_start_time */, par_active_end_date
        /* @active_end_date */, par_active_end_time
        /* @active_end_time */, var_owner_sid) t
        INTO par_freq_interval, par_freq_subday_type, par_freq_subday_interval, par_freq_relative_interval, par_freq_recurrence_factor, par_active_start_date, par_active_start_time, par_active_end_date, par_active_end_time, var_retval /* @owner_sid */;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* Update the JobSchedule */;
    UPDATE sys.sysschedules
    SET name = par_new_name, enabled = par_enabled, freq_type = par_freq_type, freq_interval = par_freq_interval, freq_subday_type = par_freq_subday_type, freq_subday_interval = par_freq_subday_interval, freq_relative_interval = par_freq_relative_interval, freq_recurrence_factor = par_freq_recurrence_factor, active_start_date = par_active_start_date, active_end_date = par_active_end_date, active_start_time = par_active_start_time, active_end_time = par_active_end_time
    /* date_modified          = GETDATE(), */, version_number = version_number + 1
        WHERE (schedule_id = var_schedule_id);
    SELECT
        0
        INTO var_retval
    /* @@error */
    /* Update the job's version/last-modified information */;
    UPDATE sys.sysjobs
    SET version_number = version_number + 1
    /* date_modified = GETDATE() */
        WHERE (job_id = par_job_id);
    ReturnCode := (var_retval);
    RETURN
    /* 0 means success */;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_jobstep (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_step_id integer = NULL::integer,
  par_step_name varchar = NULL::character varying,
  par_subsystem varchar = NULL::character varying,
  par_command text = NULL::text,
  par_additional_parameters text = NULL::text,
  par_cmdexec_success_code integer = NULL::integer,
  par_on_success_action smallint = NULL::smallint,
  par_on_success_step_id integer = NULL::integer,
  par_on_fail_action smallint = NULL::smallint,
  par_on_fail_step_id integer = NULL::integer,
  par_server varchar = NULL::character varying,
  par_database_name varchar = NULL::character varying,
  par_database_user_name varchar = NULL::character varying,
  par_retry_attempts integer = NULL::integer,
  par_retry_interval integer = NULL::integer,
  par_os_run_priority integer = NULL::integer,
  par_output_file_name varchar = NULL::character varying,
  par_flags integer = NULL::integer,
  par_proxy_id integer = NULL::integer,
  par_proxy_name varchar = NULL::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_os_run_priority_code INT;
    var_step_id_as_char VARCHAR(10);
    var_new_step_name VARCHAR(128);
    var_x_step_name VARCHAR(128);
    var_x_subsystem VARCHAR(40);
    var_x_command TEXT;
    var_x_flags INT;
    var_x_cmdexec_success_code INT;
    var_x_on_success_action SMALLINT;
    var_x_on_success_step_id INT;
    var_x_on_fail_action SMALLINT;
    var_x_on_fail_step_id INT;
    var_x_server VARCHAR(128);
    var_x_database_name VARCHAR(128);
    var_x_database_user_name VARCHAR(128);
    var_x_retry_attempts INT;
    var_x_retry_interval INT;
    var_x_os_run_priority INT;
    var_x_output_file_name VARCHAR(200);
    var_x_proxy_id INT;
    var_x_last_run_outcome SMALLINT;
    var_x_last_run_duration INT;
    var_x_last_run_retries INT;
    var_x_last_run_date INT;
    var_x_last_run_time INT;
    var_new_proxy_id INT;
    var_subsystem_id INT;
    var_auto_proxy_name VARCHAR(128);
    var_job_owner_sid CHAR(85);
    var_step_uid CHAR(85);
BEGIN
    SELECT NULL INTO var_new_proxy_id;
    /* Remove any leading/trailing spaces from parameters */
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_step_name)) INTO par_step_name;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_subsystem)) INTO par_subsystem;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_command)) INTO par_command;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_server)) INTO par_server;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_database_name)) INTO par_database_name;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_database_user_name)) INTO par_database_user_name;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_output_file_name)) INTO par_output_file_name;
    SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_proxy_name)) INTO par_proxy_name;
    /* Make sure Dts is translated into new subsystem's name SSIS */
    /* IF (@subsystem IS NOT NULL AND UPPER(@subsystem collate SQL_Latin1_General_CP1_CS_AS) = N'DTS') */
    /* BEGIN */
    /* SET @subsystem = N'SSIS' */
    /* END */
    SELECT
        t.par_job_name, t.par_job_id, t.par_owner_sid, t.ReturnCode
        FROM sys.babelfish_sp_verify_job_identifiers('@job_name'
        /* @name_of_name_parameter */, '@job_id'
        /* @name_of_id_parameter */, par_job_name
        /* @job_name */, par_job_id
        /* @job_id */, 'TEST'
        /* @sqlagent_starting_test */, var_job_owner_sid)
        INTO par_job_name, par_job_id, var_job_owner_sid, var_retval
    /* @owner_sid */;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF;
    /* Failure */
    /* Check that the step exists */

    IF (NOT EXISTS (SELECT
        *
        FROM sys.sysjobsteps
        WHERE (job_id = par_job_id) AND (step_id = par_step_id))) THEN
        SELECT
            CAST (par_step_id AS VARCHAR(10))
            INTO var_step_id_as_char;
        RAISE 'Error %, severity %, state % was raised. Message: %. Argument: %. Argument: %', '50000', 0, 0, 'The specified %s ("%s") does not exist.', '@step_id', var_step_id_as_char USING ERRCODE := '50000';
        ReturnCode := (1);
        RETURN;
        /* Failure */
    END IF;
    /* Set the x_ (existing) variables */
    SELECT
        step_name, subsystem, command, flags, cmdexec_success_code, on_success_action, on_success_step_id, on_fail_action, on_fail_step_id, server, database_name, database_user_name, retry_attempts, retry_interval, os_run_priority, output_file_name, proxy_id, last_run_outcome, last_run_duration, last_run_retries, last_run_date, last_run_time
        INTO var_x_step_name, var_x_subsystem, var_x_command, var_x_flags, var_x_cmdexec_success_code, var_x_on_success_action, var_x_on_success_step_id, var_x_on_fail_action, var_x_on_fail_step_id, var_x_server, var_x_database_name, var_x_database_user_name, var_x_retry_attempts, var_x_retry_interval, var_x_os_run_priority, var_x_output_file_name, var_x_proxy_id, var_x_last_run_outcome, var_x_last_run_duration, var_x_last_run_retries, var_x_last_run_date, var_x_last_run_time
        FROM sys.sysjobsteps
        WHERE (job_id = par_job_id) AND (step_id = par_step_id);

    IF ((par_step_name IS NOT NULL) AND (par_step_name <> var_x_step_name)) THEN
        SELECT
            par_step_name
            INTO var_new_step_name;
    END IF;
    /* Fill out the values for all non-supplied parameters from the existing values */

    IF (par_step_name IS NULL) THEN
        SELECT var_x_step_name INTO par_step_name;
    END IF;

    IF (par_subsystem IS NULL) THEN
        SELECT var_x_subsystem INTO par_subsystem;
    END IF;

    IF (par_command IS NULL) THEN
        SELECT var_x_command INTO par_command;
    END IF;

    IF (par_flags IS NULL) THEN
        SELECT var_x_flags INTO par_flags;
    END IF;

    IF (par_cmdexec_success_code IS NULL) THEN
        SELECT var_x_cmdexec_success_code INTO par_cmdexec_success_code;
    END IF;

    IF (par_on_success_action IS NULL) THEN
        SELECT var_x_on_success_action INTO par_on_success_action;
    END IF;

    IF (par_on_success_step_id IS NULL) THEN
        SELECT var_x_on_success_step_id INTO par_on_success_step_id;
    END IF;

    IF (par_on_fail_action IS NULL) THEN
        SELECT var_x_on_fail_action INTO par_on_fail_action;
    END IF;

    IF (par_on_fail_step_id IS NULL) THEN
        SELECT var_x_on_fail_step_id INTO par_on_fail_step_id;
    END IF;

    IF (par_server IS NULL) THEN
        SELECT var_x_server INTO par_server;
    END IF;

    IF (par_database_name IS NULL) THEN
        SELECT var_x_database_name INTO par_database_name;
    END IF;

    IF (par_database_user_name IS NULL) THEN
        SELECT var_x_database_user_name INTO par_database_user_name;
    END IF;

    IF (par_retry_attempts IS NULL) THEN
        SELECT var_x_retry_attempts INTO par_retry_attempts;
    END IF;

    IF (par_retry_interval IS NULL) THEN
        SELECT var_x_retry_interval INTO par_retry_interval;
    END IF;

    IF (par_os_run_priority IS NULL) THEN
        SELECT var_x_os_run_priority INTO par_os_run_priority;
    END IF;

    IF (par_output_file_name IS NULL) THEN
        SELECT var_x_output_file_name INTO par_output_file_name;
    END IF;

    IF (par_proxy_id IS NULL) THEN
        SELECT var_x_proxy_id INTO var_new_proxy_id;
    END IF;
    /* if an empty proxy_name is supplied the proxy is removed */

    IF par_proxy_name = '' THEN
        SELECT NULL INTO var_new_proxy_id;
    END IF;
    /* Turn [nullable] empty string parameters into NULLs */

    IF (LOWER(par_command) = LOWER('')) THEN
        SELECT NULL INTO par_command;
    END IF;

    IF (par_server = '') THEN
        SELECT NULL INTO par_server;
    END IF;

    IF (par_database_name = '') THEN
        SELECT NULL INTO par_database_name;
    END IF;

    IF (par_database_user_name = '') THEN
        SELECT NULL INTO par_database_user_name;
    END IF;

    IF (LOWER(par_output_file_name) = LOWER('')) THEN
        SELECT NULL INTO par_output_file_name;
    END IF
    /* Check new values */;
    SELECT
        t.par_database_name, t.par_database_user_name, t.ReturnCode
        FROM sys.babelfish_sp_verify_jobstep(par_job_id, par_step_id, var_new_step_name, par_subsystem, par_command, par_server, par_on_success_action, par_on_success_step_id, par_on_fail_action, par_on_fail_step_id, par_os_run_priority, par_database_name, par_database_user_name, par_flags, par_output_file_name, var_new_proxy_id) t
        INTO par_database_name, par_database_user_name, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* Update the job's version/last-modified information */;
    UPDATE sys.sysjobs
    SET version_number = version_number + 1
    /* date_modified = GETDATE() */
        WHERE (job_id = par_job_id)
    /* Update the step */;
    UPDATE sys.sysjobsteps
    SET step_name = par_step_name, subsystem = par_subsystem, command = par_command, flags = par_flags, additional_parameters = par_additional_parameters, cmdexec_success_code = par_cmdexec_success_code, on_success_action = par_on_success_action, on_success_step_id = par_on_success_step_id, on_fail_action = par_on_fail_action, on_fail_step_id = par_on_fail_step_id, server = par_server, database_name = par_database_name, database_user_name = par_database_user_name, retry_attempts = par_retry_attempts, retry_interval = par_retry_interval, os_run_priority = par_os_run_priority, output_file_name = par_output_file_name, last_run_outcome = var_x_last_run_outcome, last_run_duration = var_x_last_run_duration, last_run_retries = var_x_last_run_retries, last_run_date = var_x_last_run_date, last_run_time = var_x_last_run_time, proxy_id = var_new_proxy_id
        WHERE (job_id = par_job_id) AND (step_id = par_step_id);

    SELECT step_uid
    FROM sys.sysjobsteps
    WHERE job_id = par_job_id AND step_id = par_step_id
    INTO var_step_uid;

    -- PERFORM sys.sp_jobstep_create_proc (var_step_uid);

    ReturnCode := (0);
    RETURN
    /* Success */;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_schedule (
  par_schedule_id integer = NULL::integer,
  par_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_freq_type integer = NULL::integer,
  par_freq_interval integer = NULL::integer,
  par_freq_subday_type integer = NULL::integer,
  par_freq_subday_interval integer = NULL::integer,
  par_freq_relative_interval integer = NULL::integer,
  par_freq_recurrence_factor integer = NULL::integer,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = NULL::integer,
  par_active_start_time integer = NULL::integer,
  par_active_end_time integer = NULL::integer,
  par_owner_login_name varchar = NULL::character varying,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_owner_sid CHAR(85);
    var_cur_owner_sid CHAR(85);
    var_x_name VARCHAR(128);
    var_enable_only_used INT;
    var_x_enabled SMALLINT;
    var_x_freq_type INT;
    var_x_freq_interval INT;
    var_x_freq_subday_type INT;
    var_x_freq_subday_interval INT;
    var_x_freq_relative_interval INT;
    var_x_freq_recurrence_factor INT;
    var_x_active_start_date INT;
    var_x_active_end_date INT;
    var_x_active_start_time INT;
    var_x_active_end_time INT;
    var_schedule_uid CHAR(38);
BEGIN
    /* Remove any leading/trailing spaces from parameters */
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name))
        INTO par_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_new_name))
        INTO par_new_name;
    SELECT
        PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_owner_login_name))
        INTO par_owner_login_name
    /* Turn [nullable] empty string parameters into NULLs */;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
    /* Check that we can uniquely identify the schedule. This only returns a schedule that is visible to this user */;
    SELECT
        t.par_schedule_name, t.par_schedule_id, t.par_owner_sid, t.par_orig_server_id, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule_identifiers('@name'
        /* @name_of_name_parameter */, '@schedule_id'
        /* @name_of_id_parameter */, par_name
        /* @schedule_name */, par_schedule_id
        /* @schedule_id */, var_cur_owner_sid
        /* @owner_sid */, NULL
        /* @orig_server_id */, NULL) t
        INTO par_name, par_schedule_id, var_cur_owner_sid, var_retval
    /* @job_id_filter */;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* Is @enable the only parameter used beside jobname and jobid? */;

    IF ((par_enabled IS NOT NULL) AND (par_new_name IS NULL) AND (par_freq_type IS NULL) AND (par_freq_interval IS NULL) AND (par_freq_subday_type IS NULL) AND (par_freq_subday_interval IS NULL) AND (par_freq_relative_interval IS NULL) AND (par_freq_recurrence_factor IS NULL) AND (par_active_start_date IS NULL) AND (par_active_end_date IS NULL) AND (par_active_start_time IS NULL) AND (par_active_end_time IS NULL) AND (par_owner_login_name IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF
    /* If the param @owner_login_name is null or doesn't get resolved by SUSER_SID() set it to the current owner of the schedule */;

    IF (var_owner_sid IS NULL) THEN
        SELECT
            var_cur_owner_sid
            INTO var_owner_sid;
    END IF
    /* Set the x_ (existing) variables */;
    SELECT
        name, enabled, freq_type, freq_interval, freq_subday_type, freq_subday_interval, freq_relative_interval, freq_recurrence_factor, active_start_date, active_end_date, active_start_time, active_end_time
        INTO var_x_name, var_x_enabled, var_x_freq_type, var_x_freq_interval, var_x_freq_subday_type, var_x_freq_subday_interval, var_x_freq_relative_interval, var_x_freq_recurrence_factor, var_x_active_start_date, var_x_active_end_date, var_x_active_start_time, var_x_active_end_time
        FROM sys.sysschedules
        WHERE (schedule_id = par_schedule_id)
    /* Fill out the values for all non-supplied parameters from the existing values */;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_freq_type IS NULL) THEN
        SELECT
            var_x_freq_type
            INTO par_freq_type;
    END IF;

    IF (par_freq_interval IS NULL) THEN
        SELECT
            var_x_freq_interval
            INTO par_freq_interval;
    END IF;

    IF (par_freq_subday_type IS NULL) THEN
        SELECT
            var_x_freq_subday_type
            INTO par_freq_subday_type;
    END IF;

    IF (par_freq_subday_interval IS NULL) THEN
        SELECT
            var_x_freq_subday_interval
            INTO par_freq_subday_interval;
    END IF;

    IF (par_freq_relative_interval IS NULL) THEN
        SELECT
            var_x_freq_relative_interval
            INTO par_freq_relative_interval;
    END IF;

    IF (par_freq_recurrence_factor IS NULL) THEN
        SELECT
            var_x_freq_recurrence_factor
            INTO par_freq_recurrence_factor;
    END IF;

    IF (par_active_start_date IS NULL) THEN
        SELECT
            var_x_active_start_date
            INTO par_active_start_date;
    END IF;

    IF (par_active_end_date IS NULL) THEN
        SELECT
            var_x_active_end_date
            INTO par_active_end_date;
    END IF;

    IF (par_active_start_time IS NULL) THEN
        SELECT
            var_x_active_start_time
            INTO par_active_start_time;
    END IF;

    IF (par_active_end_time IS NULL) THEN
        SELECT
            var_x_active_end_time
            INTO par_active_end_time;
    END IF
    /* Check schedule (frequency and owner) parameters */;
    SELECT
        t.par_freq_interval, t.par_freq_subday_type, t.par_freq_subday_interval, t.par_freq_relative_interval, t.par_freq_recurrence_factor, t.par_active_start_date,
        t.par_active_start_time, t.par_active_end_date, t.par_active_end_time, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule(par_schedule_id
        /* @schedule_id */, par_new_name
        /* @name */, par_enabled
        /* @enabled */, par_freq_type
        /* @freq_type */, par_freq_interval
        /* @freq_interval */, par_freq_subday_type
        /* @freq_subday_type */, par_freq_subday_interval
        /* @freq_subday_interval */, par_freq_relative_interval
        /* @freq_relative_interval */, par_freq_recurrence_factor
        /* @freq_recurrence_factor */, par_active_start_date
        /* @active_start_date */, par_active_start_time
        /* @active_start_time */, par_active_end_date
        /* @active_end_date */, par_active_end_time
        /* @active_end_time */, var_owner_sid) t
        INTO par_freq_interval, par_freq_subday_type, par_freq_subday_interval, par_freq_relative_interval, par_freq_recurrence_factor, par_active_start_date, par_active_start_time, par_active_end_date, par_active_end_time, var_retval /* @owner_sid */;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF
    /* Failure */
    /* Update the sysschedules table */;
    UPDATE sys.sysschedules
    SET name = par_new_name, owner_sid = var_owner_sid, enabled = par_enabled, freq_type = par_freq_type, freq_interval = par_freq_interval, freq_subday_type = par_freq_subday_type, freq_subday_interval = par_freq_subday_interval, freq_relative_interval = par_freq_relative_interval, freq_recurrence_factor = par_freq_recurrence_factor, active_start_date = par_active_start_date, active_end_date = par_active_end_date, active_start_time = par_active_start_time, active_end_time = par_active_end_time
    /* date_modified          = GETDATE(), */, version_number = version_number + 1
        WHERE (schedule_id = par_schedule_id);
    SELECT
        0
        INTO var_retval;

    ReturnCode := (var_retval);
    RETURN
    /* 0 means success */;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job (
  par_job_id integer,
  par_name varchar,
  par_enabled smallint,
  par_start_step_id integer,
  par_category_name varchar,
  inout par_owner_sid char,
  par_notify_level_eventlog integer,
  inout par_notify_level_email integer,
  inout par_notify_level_netsend integer,
  inout par_notify_level_page integer,
  par_notify_email_operator_name varchar,
  par_notify_netsend_operator_name varchar,
  par_notify_page_operator_name varchar,
  par_delete_level integer,
  inout par_category_id integer,
  inout par_notify_email_operator_id integer,
  inout par_notify_netsend_operator_id integer,
  inout par_notify_page_operator_id integer,
  inout par_originating_server varchar,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_job_type INT;
  var_retval INT;
  var_current_date INT;
  var_res_valid_range VARCHAR(200);
  var_max_step_id INT;
  var_valid_range VARCHAR(50);
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name)) INTO par_name;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_category_name)) INTO par_category_name;
  SELECT UPPER(PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_originating_server))) INTO par_originating_server;

  IF (
    EXISTS (
      SELECT *
        FROM sys.sysjobs AS job
       WHERE (name = par_name)
      /* AND (job_id <> ISNULL(@job_id, 0x911)))) -- When adding a new job @job_id is NULL */
    )
  )
  THEN /* Failure */
    RAISE 'The specified % ("%") already exists.', 'par_name', par_name USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  /* Check enabled state */
  IF (par_enabled <> 0) AND (par_enabled <> 1) THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'par_enabled', '0, 1' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  /* Check start step */

  IF (par_job_id IS NULL) THEN /* New job */
    IF (par_start_step_id <> 1) THEN /* Failure */
      RAISE 'The specified "%" is invalid (valid values are: %).', 'par_start_step_id', '1' USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
    END IF;
  ELSE /* Existing job */
    /* Get current maximum step id */
    SELECT COALESCE(MAX(step_id), 0)
      INTO var_max_step_id
      FROM sys.sysjobsteps
     WHERE (job_id = par_job_id);

    IF (par_start_step_id < 1) OR (par_start_step_id > var_max_step_id + 1) THEN /* Failure */
      SELECT '1..' || CAST (var_max_step_id + 1 AS VARCHAR(1))
        INTO var_valid_range;
      RAISE 'The specified "%" is invalid (valid values are: %).', 'par_start_step_id', var_valid_range USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  /* Get the category_id, handling any special-cases as appropriate */
  SELECT NULL INTO par_category_id;

  IF (par_category_name = '[DEFAULT]') /* User wants to revert to the default job category */
  THEN
    SELECT
      CASE COALESCE(var_job_type, 1)
        WHEN 1 THEN 0 /* [Uncategorized (Local)] */
        WHEN 2 THEN 2 /* [Uncategorized (Multi-Server)] */
      END
      INTO par_category_id;
  ELSE
    SELECT 0 INTO par_category_id;
  END IF;

  returncode := (0); /* Success */
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_date (
  par_date integer,
  par_date_name varchar = 'date'::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_date_name)) INTO par_date_name;

  /* Success */
  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_job_name varchar,
  inout par_job_id integer,
  par_sqlagent_starting_test varchar = 'TEST'::character varying,
  inout par_owner_sid char = NULL::bpchar,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_retval INT;
  var_job_id_as_char VARCHAR(36);
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name_of_name_parameter)) INTO par_name_of_name_parameter;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name_of_id_parameter)) INTO par_name_of_id_parameter;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_job_name)) INTO par_job_name;

  IF (par_job_name = '')
  THEN
    SELECT NULL INTO par_job_name;
  END IF;

  IF ((par_job_name IS NULL) AND (par_job_id IS NULL)) OR ((par_job_name IS NOT NULL) AND (par_job_id IS NOT NULL))
  THEN /* Failure */
    RAISE 'Supply either % or % to identify the job.', par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check job id */
  IF (par_job_id IS NOT NULL)
  THEN
    SELECT name
         , owner_sid
      INTO par_job_name
         , par_owner_sid
      FROM sys.sysjobs
     WHERE (job_id = par_job_id);

    /* the view would take care of all the permissions issues. */
    IF (par_job_name IS NULL)
    THEN /* Failure */
      SELECT CAST (par_job_id AS VARCHAR(36))
        INTO var_job_id_as_char;

      RAISE 'The specified % ("%") does not exist.', 'job_id', var_job_id_as_char USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  ELSE
    /* Check job name */
    IF (par_job_name IS NOT NULL)
    THEN
      /* Check if the job name is ambiguous */
      IF (SELECT COUNT(*) FROM sys.sysjobs WHERE name = par_job_name) > 1
      THEN /* Failure */
        RAISE 'There are two or more jobs named "%". Specify % instead of % to uniquely identify the job.', par_job_name, par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;

      /* The name is not ambiguous, so get the corresponding job_id (if the job exists) */
      SELECT job_id
           , owner_sid
        INTO par_job_id
           , par_owner_sid
        FROM sys.sysjobs
       WHERE (name = par_job_name);

      /* the view would take care of all the permissions issues. */
      IF (par_job_id IS NULL)
      THEN /* Failure */
        RAISE 'The specified % ("%") does not exist.', 'job_name', par_job_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;
  END IF;

  /* Success */
  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_time (
  par_time integer,
  par_time_name varchar = 'time'::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_hour INT;
  var_minute INT;
  var_second INT;
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_time_name)) INTO par_time_name;

  IF ((par_time < 0) OR (par_time > 235959))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', par_time_name, '000000..235959' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  SELECT (par_time / 10000) INTO var_hour;
  SELECT (par_time % 10000) / 100 INTO var_minute;
  SELECT (par_time % 100) INTO var_second;

  /* Check hour range */
  IF (var_hour > 23) THEN
    RAISE 'The "%" supplied has an invalid %.', par_time_name, 'hour' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check minute range */
  IF (var_minute > 59) THEN
    RAISE 'The "%" supplied has an invalid %.', par_time_name, 'minute' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check second range */
  IF (var_second > 59) THEN
     RAISE 'The "%" supplied has an invalid %.', par_time_name, 'second' USING ERRCODE := '50000';
     returncode := 1;
     RETURN;
  END IF;

  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_jobstep (
  par_job_id integer,
  par_step_id integer,
  par_step_name varchar,
  par_subsystem varchar,
  par_command text,
  par_server varchar,
  par_on_success_action smallint,
  par_on_success_step_id integer,
  par_on_fail_action smallint,
  par_on_fail_step_id integer,
  par_os_run_priority integer,
  par_flags integer,
  par_output_file_name varchar,
  par_proxy_id integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_max_step_id INT;
  var_retval INT;
  var_valid_values VARCHAR(50);
  var_database_name_temp VARCHAR(258);
  var_database_user_name_temp VARCHAR(256);
  var_temp_command TEXT;
  var_iPos INT;
  var_create_count INT;
  var_destroy_count INT;
  var_is_olap_subsystem SMALLINT;
  var_owner_sid CHAR(85);
  var_owner_name VARCHAR(128);
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_subsystem)) INTO par_subsystem;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_server)) INTO par_server;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_output_file_name)) INTO par_output_file_name;

  /* Get current maximum step id */
  SELECT COALESCE(MAX(step_id), 0)
    INTO var_max_step_id
    FROM sys.sysjobsteps
   WHERE (job_id = par_job_id);

  /* Check step id */
  IF (par_step_id < 1) OR (par_step_id > var_max_step_id + 1)  /* Failure */
  THEN
    SELECT '1..' || CAST (var_max_step_id + 1 AS VARCHAR(1)) INTO var_valid_values;
      RAISE 'The specified "%" is invalid (valid values are: %).', '@step_id', var_valid_values USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  /* Check step name */
  IF (
    EXISTS (
      SELECT *
        FROM sys.sysjobsteps
       WHERE (job_id = par_job_id) AND (step_name = par_step_name)
    )
  )
  THEN /* Failure */
    RAISE 'The specified % ("%") already exists.', 'step_name', par_step_name USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check on-success action/step */
  IF (par_on_success_action <> 1) /* Quit Qith Success */
    AND (par_on_success_action <> 2) /* Quit Qith Failure */
    AND (par_on_success_action <> 3) /* Goto Next Step */
    AND (par_on_success_action <> 4) /* Goto Step */
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'on_success_action', '1, 2, 3, 4' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_on_success_action = 4) AND ((par_on_success_step_id < 1) OR (par_on_success_step_id = par_step_id))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are greater than 0 but excluding %ld).', 'on_success_step', par_step_id USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check on-fail action/step */
  IF (par_on_fail_action <> 1) /* Quit With Success */
    AND (par_on_fail_action <> 2) /* Quit With Failure */
    AND (par_on_fail_action <> 3) /* Goto Next Step */
    AND (par_on_fail_action <> 4) /* Goto Step */
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'on_failure_action', '1, 2, 3, 4' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_on_fail_action = 4) AND ((par_on_fail_step_id < 1) OR (par_on_fail_step_id = par_step_id))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are greater than 0 but excluding %).', 'on_failure_step', par_step_id USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Warn the user about forward references */
  IF ((par_on_success_action = 4) AND (par_on_success_step_id > var_max_step_id))
  THEN
    RAISE 'Warning: Non-existent step referenced by %.', 'on_success_step_id' USING ERRCODE := '50000';
  END IF;

  IF ((par_on_fail_action = 4) AND (par_on_fail_step_id > var_max_step_id))
  THEN
    RAISE 'Warning: Non-existent step referenced by %.', '@on_fail_step_id' USING ERRCODE := '50000';
  END IF;

  /* Check run priority: must be a valid value to pass to SetThreadPriority: */
  /* [-15 = IDLE, -1 = BELOW_NORMAL, 0 = NORMAL, 1 = ABOVE_NORMAL, 15 = TIME_CRITICAL] */
  IF (par_os_run_priority NOT IN (- 15, - 1, 0, 1, 15))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', '@os_run_priority', '-15, -1, 0, 1, 15' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check flags */
  IF ((par_flags < 0) OR (par_flags > 114)) THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', '@flags', '0..114' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (LOWER(UPPER(par_subsystem)) <> LOWER('TSQL')) THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', '@subsystem', 'TSQL' USING ERRCODE := '50000';
    returncode := (1);
    RETURN;
  END IF;

  /* Success */
  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_schedule (
  par_schedule_id integer,
  par_name varchar,
  par_enabled smallint,
  par_freq_type integer,
  inout par_freq_interval integer,
  inout par_freq_subday_type integer,
  inout par_freq_subday_interval integer,
  inout par_freq_relative_interval integer,
  inout par_freq_recurrence_factor integer,
  inout par_active_start_date integer,
  inout par_active_start_time integer,
  inout par_active_end_date integer,
  inout par_active_end_time integer,
  par_owner_sid char,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_return_code INT;
  var_isAdmin INT;
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name)) INTO par_name;

  /* Make sure that NULL input/output parameters - if NULL - are initialized to 0 */
  SELECT COALESCE(par_freq_interval, 0) INTO par_freq_interval;
  SELECT COALESCE(par_freq_subday_type, 0) INTO par_freq_subday_type;
  SELECT COALESCE(par_freq_subday_interval, 0) INTO par_freq_subday_interval;
  SELECT COALESCE(par_freq_relative_interval, 0) INTO par_freq_relative_interval;
  SELECT COALESCE(par_freq_recurrence_factor, 0) INTO par_freq_recurrence_factor;
  SELECT COALESCE(par_active_start_date, 0) INTO par_active_start_date;
  SELECT COALESCE(par_active_start_time, 0) INTO par_active_start_time;
  SELECT COALESCE(par_active_end_date, 0) INTO par_active_end_date;
  SELECT COALESCE(par_active_end_time, 0) INTO par_active_end_time;

  /* Verify name (we disallow schedules called 'ALL' since this has special meaning in sp_delete_jobschedules) */
  SELECT 0 INTO var_isAdmin;

  IF (
    EXISTS (
      SELECT *
        FROM sys.sysschedules
       WHERE (name = par_name)
    )
  )
  THEN /* Failure */
    RAISE 'The specified % ("%") already exists.', 'par_name', par_name USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  IF (UPPER(par_name) = 'ALL')
  THEN /* Failure */
    RAISE 'The specified "%" is invalid.', 'name' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Verify enabled state */
  IF (par_enabled <> 0) AND (par_enabled <> 1)
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', '@enabled', '0, 1' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Verify frequency type */
  IF (par_freq_type = 2) /* OnDemand is no longer supported */
  THEN /* Failure */
    RAISE 'Frequency Type 0x2 (OnDemand) is no longer supported.' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_freq_type NOT IN (1, 4, 8, 16, 32, 64, 128))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'freq_type', '1, 4, 8, 16, 32, 64, 128' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Verify frequency sub-day type */
  IF (par_freq_subday_type <> 0) AND (par_freq_subday_type NOT IN (1, 2, 4, 8))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'freq_subday_type', '1, 2, 4, 8' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Default active start/end date/times (if not supplied, or supplied as NULLs or 0) */
  IF (par_active_start_date = 0)
  THEN
    SELECT date_part('year', NOW()::TIMESTAMP) * 10000 + date_part('month', NOW()::TIMESTAMP) * 100 + date_part('day', NOW()::TIMESTAMP)
      INTO par_active_start_date;
  END IF;

  /* This is an ISO format: "yyyymmdd" */
  IF (par_active_end_date = 0)
  THEN
    /* December 31st 9999 */
    SELECT 99991231 INTO par_active_end_date;
  END IF;

  IF (par_active_start_time = 0)
  THEN
    /* 12:00:00 am */
    SELECT 000000 INTO par_active_start_time;
  END IF;

  IF (par_active_end_time = 0)
  THEN
    /* 11:59:59 pm */
    SELECT 235959 INTO par_active_end_time;
  END IF;

  /* Verify active start/end dates */
  IF (par_active_end_date = 0)
  THEN
    SELECT 99991231 INTO par_active_end_date;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_date(par_active_end_date, 'active_end_date') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN /* Failure */
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_date(par_active_start_date, '@active_start_date') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN /* Failure */
    returncode := 1;
    RETURN;
  END IF;

  IF (par_active_end_date < par_active_start_date)
  THEN /* Failure */
    RAISE '% cannot be before %.', 'active_end_date', 'active_start_date' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_time(par_active_end_time, '@active_end_time') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN /* Failure */
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_time(par_active_start_time, '@active_start_time') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN /* Failure */
    returncode := 1;
    RETURN;
  END IF;

  IF (par_active_start_time = par_active_end_time AND (par_freq_subday_type IN (2, 4, 8)))
  THEN /* Failure */
    RAISE 'The specified "%" is invalid (valid values are: %).', 'active_end_time', 'before or after active_start_time' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF ((par_freq_type = 1) /* FREQTYPE_ONETIME */
    OR (par_freq_type = 64) /* FREQTYPE_AUTOSTART */
    OR (par_freq_type = 128)) /* FREQTYPE_ONIDLE */
  THEN /* Set standard defaults for non-required parameters */
    SELECT 0 INTO par_freq_interval;
    SELECT 0 INTO par_freq_subday_type;
    SELECT 0 INTO par_freq_subday_interval;
    SELECT 0 INTO par_freq_relative_interval;
    SELECT 0 INTO par_freq_recurrence_factor;
    /* Success */
    returncode := 0;
    RETURN;
  END IF;

  IF (par_freq_subday_type = 0) /* FREQSUBTYPE_ONCE */
  THEN
    SELECT 1 INTO par_freq_subday_type;
  END IF;

  IF ((par_freq_subday_type <> 1) /* FREQSUBTYPE_ONCE */
    AND (par_freq_subday_type <> 2) /* FREQSUBTYPE_SECOND */
    AND (par_freq_subday_type <> 4) /* FREQSUBTYPE_MINUTE */
    AND (par_freq_subday_type <> 8)) /* FREQSUBTYPE_HOUR */
  THEN /* Failure */
    RAISE 'The schedule for this job is invalid (reason: The specified @freq_subday_type is invalid (valid values are: 0x1, 0x2, 0x4, 0x8).).' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF ((par_freq_subday_type <> 1) AND (par_freq_subday_interval < 1)) /* FREQSUBTYPE_ONCE and less than 1 interval */
    OR ((par_freq_subday_type = 2) AND (par_freq_subday_interval < 10)) /* FREQSUBTYPE_SECOND and less than 10 seconds (see MIN_SCHEDULE_GRANULARITY in SqlAgent source code) */
  THEN /* Failure */
    RAISE 'The schedule for this job is invalid (reason: The specified @freq_subday_interval is invalid).' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_freq_type = 4) /* FREQTYPE_DAILY */
  THEN
    SELECT 0 INTO par_freq_recurrence_factor;

    IF (par_freq_interval < 1) THEN /* Failure */
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be at least 1 for a daily job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 8) /* FREQTYPE_WEEKLY */
  THEN
    IF (par_freq_interval < 1) OR (par_freq_interval > 127) /* (2^7)-1 [freq_interval is a bitmap (Sun=1..Sat=64)] */
    THEN /* Failure */
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be a valid day of the week bitmask [Sunday = 1 .. Saturday = 64] for a weekly job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 16) /* FREQTYPE_MONTHLY */
  THEN
    IF (par_freq_interval < 1) OR (par_freq_interval > 31)
    THEN /* Failure */
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be between 1 and 31 for a monthly job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 32) /* FREQTYPE_MONTHLYRELATIVE */
  THEN
    IF (par_freq_relative_interval <> 1) /* RELINT_1ST */
      AND (par_freq_relative_interval <> 2) /* RELINT_2ND */
      AND (par_freq_relative_interval <> 4) /* RELINT_3RD */
      AND (par_freq_relative_interval <> 8) /* RELINT_4TH */
      AND (par_freq_relative_interval <> 16) /* RELINT_LAST */
    THEN /* Failure */
      RAISE 'The schedule for this job is invalid (reason: @freq_relative_interval must be one of 1st (0x1), 2nd (0x2), 3rd [0x4], 4th (0x8) or Last (0x10).).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 32) /* FREQTYPE_MONTHLYRELATIVE */
  THEN
    IF (par_freq_interval <> 1) /* RELATIVE_SUN */
      AND (par_freq_interval <> 2) /* RELATIVE_MON */
      AND (par_freq_interval <> 3) /* RELATIVE_TUE */
      AND (par_freq_interval <> 4) /* RELATIVE_WED */
      AND (par_freq_interval <> 5) /* RELATIVE_THU */
      AND (par_freq_interval <> 6) /* RELATIVE_FRI */
      AND (par_freq_interval <> 7) /* RELATIVE_SAT */
      AND (par_freq_interval <> 8) /* RELATIVE_DAY */
      AND (par_freq_interval <> 9) /* RELATIVE_WEEKDAY */
      AND (par_freq_interval <> 10) /* RELATIVE_WEEKENDDAY */
    THEN /* Failure */
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be between 1 and 10 (1 = Sunday .. 7 = Saturday, 8 = Day, 9 = Weekday, 10 = Weekend-day) for a monthly-relative job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF ((par_freq_type = 8) /* FREQTYPE_WEEKLY */
    OR (par_freq_type = 16) /* FREQTYPE_MONTHLY */
    OR (par_freq_type = 32)) /* FREQTYPE_MONTHLYRELATIVE */
    AND (par_freq_recurrence_factor < 1)
  THEN /* Failure */
    RAISE 'The schedule for this job is invalid (reason: @freq_recurrence_factor must be at least 1.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;
  /* Success */
  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_schedule_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_schedule_name varchar,
  inout par_schedule_id integer,
  inout par_owner_sid char,
  inout par_orig_server_id integer,
  par_job_id_filter integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_schedule_id_as_char VARCHAR(36);
  var_sch_name_count INT;
BEGIN
  /* Remove any leading/trailing spaces from parameters */
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name_of_name_parameter)) INTO par_name_of_name_parameter;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_name_of_id_parameter)) INTO par_name_of_id_parameter;
  SELECT PG_CATALOG.LTRIM(PG_CATALOG.RTRIM(par_schedule_name)) INTO par_schedule_name;
  SELECT 0 INTO var_sch_name_count;

  IF (par_schedule_name = '')
  THEN
    SELECT NULL INTO par_schedule_name;
  END IF;

  IF ((par_schedule_name IS NULL) AND (par_schedule_id IS NULL)) OR ((par_schedule_name IS NOT NULL) AND (par_schedule_id IS NOT NULL))
  THEN /* Failure */
    RAISE 'Supply either % or % to identify the schedule.', par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  /* Check schedule id */
  IF (par_schedule_id IS NOT NULL)
  THEN
    /* Look at all schedules */
    SELECT name
         , owner_sid
         , originating_server_id
      INTO par_schedule_name
         , par_owner_sid
         , par_orig_server_id
      FROM sys.sysschedules
     WHERE (schedule_id = par_schedule_id);

    IF (par_schedule_name IS NULL)
    THEN /* Failure */
      SELECT CAST (par_schedule_id AS VARCHAR(36))
        INTO var_schedule_id_as_char;

      RAISE 'The specified % ("%") does not exist.', 'schedule_id', var_schedule_id_as_char USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  ELSE
    IF (par_schedule_name IS NOT NULL)
    THEN
      /* Check if the schedule name is ambiguous */
      IF (SELECT COUNT(*) FROM sys.sysschedules WHERE name = par_schedule_name) > 1
      THEN /* Failure */
        RAISE 'There are two or more sysschedules named "%". Specify % instead of % to uniquely identify the sysschedules.', par_job_name, par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;

      /* The name is not ambiguous, so get the corresponding job_id (if the job exists) */
      SELECT schedule_id
           , owner_sid
        INTO par_schedule_id, par_owner_sid
        FROM sys.sysschedules
       WHERE (name = par_schedule_name);

      /* the view would take care of all the permissions issues. */
      IF (par_schedule_id IS NULL)
      THEN /* Failure */
        RAISE 'The specified % ("%") does not exist.', 'par_schedule_name', par_schedule_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;
  END IF;

  /* Success */
  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION babelfish_get_name_delimiter_pos(name TEXT)
RETURNS INTEGER
AS $$
DECLARE
    pos int;
BEGIN
    IF (length(name) <= 2 AND (position('"' IN name) != 0 OR position(']' IN name) != 0 OR position('[' IN name) != 0))
        -- invalid name
        THEN RETURN 0;
    ELSIF PG_CATALOG.left(name, 1) = '[' THEN
        pos = position('].' IN name);
        IF pos = 0 THEN 
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 1;
        END IF;
    ELSIF PG_CATALOG.left(name, 1) = '"' THEN
        -- search from position 1 in case name starts with a double quote.
        pos = position('".' IN PG_CATALOG.right(name, length(name) - 1));
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 2;
        END IF;
    ELSE
        RETURN position('.' IN name);
    END IF;
END;
$$
LANGUAGE plpgsql
STABLE;

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
    lower_object_name = lower(PG_CATALOG.rtrim(name));

    counter = 1;
    cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);

    -- Parse user input into names split by '.'
    WHILE cur_pos > 0 LOOP
        IF counter > 3 THEN
            -- Too many names provided
            RETURN;
        END IF;

        names[counter] = babelfish_remove_delimiter_pair(PG_CATALOG.rtrim(PG_CATALOG.left(lower_object_name, cur_pos - 1)));
        
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
    object_name = sys.babelfish_truncate_identifier(babelfish_remove_delimiter_pair(PG_CATALOG.rtrim(lower_object_name)));
END;
$$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.timezone(IN tzzone PG_CATALOG.TEXT , IN input_expr anyelement)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    tz_offset PG_CATALOG.TEXT;
    tz_name PG_CATALOG.TEXT;
    lower_tzn PG_CATALOG.TEXT;
    prev_res PG_CATALOG.TEXT;
    result PG_CATALOG.TEXT;
    is_dstt bool;
    tz_diff PG_CATALOG.TEXT;
    input_expr_tx PG_CATALOG.TEXT;
    input_expr_tmz TIMESTAMPTZ;
BEGIN
    IF input_expr IS NULL OR tzzone IS NULL THEN 
    	RETURN NULL;
    END IF;

    lower_tzn := lower(tzzone);
    IF lower_tzn <> 'utc' THEN
        tz_name := sys.babelfish_timezone_mapping(lower_tzn);
    ELSE
        tz_name := 'utc';
    END IF;

    IF tz_name = 'NULL' THEN
        RAISE USING MESSAGE := format('Argument data type or the parameter %s provided to AT TIME ZONE clause is invalid.', tzzone);
    END IF;

    IF pg_typeof(input_expr) IN ('sys.smalldatetime'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype) THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;

        result := (SELECT input_expr_tmz AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        input_expr_tx := concat(input_expr_tx,tz_offset);
        return cast(input_expr_tx as sys.datetimeoffset);
    ELSIF  pg_typeof(input_expr) = 'sys.DATETIMEOFFSET'::regtype THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;
        result := (SELECT input_expr_tmz  AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        result := concat(result,tz_offset);
        return cast(result as sys.datetimeoffset);
    ELSE
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
    END IF;
       
END;
$BODY$
LANGUAGE 'plpgsql' STABLE;

create or replace function sys.PATINDEX(in pattern varchar, in expression varchar) returns bigint as
$body$
declare
  v_find_result VARCHAR;
  v_pos bigint;
  v_regexp_pattern VARCHAR;
begin
  if pattern is null or expression is null then
    return null;
  end if;
  if PG_CATALOG.left(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"', 'i');
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if PG_CATALOG.right(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%', 'i');
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
  end if;
  v_find_result := substring(expression, v_regexp_pattern, '#');
  if v_find_result <> '' collate sys.database_default then
    v_pos := strpos(expression, v_find_result);
  else
    v_pos := 0;
  end if;
  return v_pos;
end;
$body$
language plpgsql immutable returns null on null input;

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
    bbf_schema_name text;
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
    cs_as_securable = lower(PG_CATALOG.rtrim(cs_as_securable));
    cs_as_securable_class = lower(PG_CATALOG.rtrim(cs_as_securable_class));
    cs_as_permission = lower(PG_CATALOG.rtrim(cs_as_permission));
    cs_as_sub_securable = lower(PG_CATALOG.rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(PG_CATALOG.rtrim(cs_as_sub_securable_class));

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
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name 
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
                    WHERE ext.orig_name = bbf_schema_name 
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

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

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(
    id INT,
    property SYS.VARCHAR
)
RETURNS SYS.SQL_VARIANT
AS $$
BEGIN
	property := PG_CATALOG.RTRIM(LOWER(COALESCE(property, '')));
	
	IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
	THEN
		RETURN NULL;
	END IF;

	IF property = 'basetype' -- BaseType
	THEN
		RETURN (SELECT CAST(ao.type AS SYS.SQL_VARIANT) 
                FROM sys.all_objects ao
                WHERE ao.object_id = id
                LIMIT 1
                );
    END IF;

    RETURN CAST(OBJECTPROPERTY(id, property) AS SYS.SQL_VARIANT);
END
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date ANYELEMENT, IN origin ANYELEMENT default NULL) RETURNS ANYELEMENT 
AS 
$body$
DECLARE
    required_bucket INT;
    years_diff INT;
    quarters_diff INT;
    months_diff INT;
    hours_diff INT;
    minutes_diff INT;
    seconds_diff INT;
    milliseconds_diff INT;
    timezone INT;
    result_time time;
    result_date timestamp;
    offset_string PG_CATALOG.text;
    date_difference_interval INTERVAL;
    millisec_trunc_diff_interval INTERVAL;
    date_arg_datatype regtype;
    is_valid boolean;
BEGIN
    BEGIN
        date_arg_datatype := pg_typeof(date);
        is_valid := sys.date_bucket_internal_helper(datepart, number, true, true, date);

        -- If optional argument origin's value is not provided by user then set it's default value of valid datatype.
        IF origin IS NULL THEN
                IF date_arg_datatype = 'sys.datetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF date_arg_datatype = 'sys.datetime2'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF date_arg_datatype = 'sys.smalldatetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSIF date_arg_datatype = 'date'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSIF date_arg_datatype = 'time'::regtype THEN
                    origin := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        END IF;
    END;

    /* support of date_bucket() for different kinds of date datatype starts here */
    -- support of date_bucket() when date is of 'time' datatype
    IF date_arg_datatype = 'time'::regtype THEN
        -- Find interval between date and origin and extract hour, minute, second, millisecond from the interval
        date_difference_interval := date_trunc('millisecond', date) - date_trunc('millisecond', origin);
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := FLOOR(EXTRACT('millisecond' from date_difference_interval))::INT;
        CASE datepart
            WHEN 'hour' THEN
                -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                -- For Ex. 'date_bucket(hour, 2, '01:00:00', '08:00:00')' hence check if the result_time is greater then date
                -- For comparision we are trunceting the result_time to milliseconds
                required_bucket := hours_diff/number;
                result_time := origin + make_interval(hours => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(hours => number);
                END IF;
                RETURN result_time;

            WHEN 'minute' THEN
                required_bucket := (hours_diff * 60 + minutes_diff)/number;
                result_time := origin + make_interval(mins => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(mins => number);
                END IF;
                RETURN result_time;

            WHEN 'second' THEN
                required_bucket := ((hours_diff * 60 + minutes_diff) * 60 + seconds_diff)/number;
                result_time := origin + make_interval(secs => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => number);
                END IF;
                RETURN result_time;

            WHEN 'millisecond' THEN
                required_bucket := (((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff)/number;
                result_time := origin + make_interval(secs => ((required_bucket * number)::numeric) * 0.001);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => (number::numeric) * 0.001);
                END IF;
                RETURN result_time;
        END CASE;

    -- support of date_bucket() when date is of {'datetime2', 'datetimeoffset'} datatype
    -- handling separately because both the datatypes have precision in milliseconds
    ELSIF date_arg_datatype IN ('sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype) THEN
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Ex. date_bucket(year, 2, '2010-01-01', '2019-01-01')) hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number*3);
                    END IF;
            END CASE;  
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function. 
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            millisec_trunc_diff_interval := (origin::timestamp - date_trunc('millisecond', origin::timestamp))::interval;
            result_date = date_bin(date_difference_interval, date::timestamp, date_trunc('millisecond', origin::timestamp)) + millisec_trunc_diff_interval;

            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result.
            IF result_date + date_difference_interval <= date::timestamp THEN
                result_date = result_date + date_difference_interval;
            END IF;
        END IF;

        -- All the above operations are performed by converting every date datatype into TIMESTAMPS. 
        -- datetimeoffset is typecasted into TIMESTAMPS that changes the value. 
        -- Ex. '2023-02-23 09:19:21.23 +10:12'::sys.datetimeoffset::timestamp => '2023-02-22 23:07:21.23'
        -- The output of date_bucket() for datetimeoffset datatype will always be in the same time-zone as of provided date argument. 
        -- Here, converting TIMESTAMP into datetimeoffset datatype with the same timezone as of date argument.
        IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = PG_CATALOG.right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            RETURN concat(result_date, ' ', offset_string)::sys.datetimeoffset;
        ELSE
            RETURN result_date;
        END IF;

    -- support of date_bucket() when date is of {'date', 'datetime', 'smalldatetime'} datatype
    ELSE
        -- Round datetime to fixed bins (e.g. .000, .003, .007)
        IF date_arg_datatype = 'sys.datetime'::regtype THEN
            date := sys.babelfish_conv_string_to_datetime('DATETIME', date::TEXT)::sys.datetime;
            origin := sys.babelfish_conv_string_to_datetime('DATETIME', origin::TEXT)::sys.datetime;
        END IF;
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Example. date_bucket(year, 2, '2010-01-01', '2019-01-01') hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number * 3);
                    END IF;
            END CASE;
            RETURN result_date;
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function.
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            result_date = date_bin(date_difference_interval, date::TIMESTAMP, origin::TIMESTAMP);
            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result. 
            IF result_date + date_difference_interval <= date::TIMESTAMP THEN
                result_date = result_date + date_difference_interval;
            END IF;
            RETURN result_date;
        END IF;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.DATETRUNC(IN datepart PG_CATALOG.TEXT, IN date ANYELEMENT) RETURNS ANYELEMENT AS
$body$
DECLARE
    days_offset INT;
    v_day INT;
    result_date timestamp;
    input_expr_timestamp timestamp;
    date_arg_datatype regtype;
    offset_string PG_CATALOG.TEXT;
    datefirst_value INT;
BEGIN
    BEGIN
        /* perform input validation */
        date_arg_datatype := pg_typeof(date);
        IF datepart NOT IN ('year', 'quarter', 'month', 'week', 'tsql_week', 'hour', 'minute', 'second', 'millisecond', 'microsecond', 
                            'doy', 'day', 'nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION '''%'' is not a recognized datetrunc option.', datepart;
        ELSIF date_arg_datatype NOT IN ('date'::regtype, 'time'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype,
                                        'sys.datetimeoffset'::regtype, 'sys.smalldatetime'::regtype) THEN
            RAISE EXCEPTION 'Argument data type ''%'' is invalid for argument 2 of datetrunc function.', date_arg_datatype;
        ELSIF datepart IN ('nanosecond', 'tzoffset') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''%''.',datepart, date_arg_datatype;
        ELSIF datepart IN ('dow') THEN
            RAISE EXCEPTION 'The datepart ''weekday'' is not supported by date function datetrunc for data type ''%''.', date_arg_datatype;
        ELSIF date_arg_datatype = 'date'::regtype AND datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''date''.', datepart;
        ELSIF date_arg_datatype = 'datetime'::regtype AND datepart IN ('microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''datetime''.', datepart;
        ELSIF date_arg_datatype = 'smalldatetime'::regtype AND datepart IN ('millisecond', 'microsecond') THEN
            RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''smalldatetime''.', datepart;
        ELSIF date_arg_datatype = 'time'::regtype THEN
            IF datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'tsql_week') THEN
                RAISE EXCEPTION 'The datepart ''%'' is not supported by date function datetrunc for data type ''time''.', datepart;
            END IF;
            -- Limitation in determining if the specified fractional scale (if provided any) for time datatype is 
            -- insufficient to support provided datepart (millisecond, microsecond) value
        ELSIF date_arg_datatype IN ('datetime2'::regtype, 'datetimeoffset'::regtype) THEN
            -- Limitation in determining if the specified fractional scale (if provided any) for the above datatype is
            -- insufficient to support for provided datepart (millisecond, microsecond) value
        END IF;

        /* input validation is complete, proceed with result calculation. */
        IF date_arg_datatype = 'time'::regtype THEN
            RETURN date_trunc(datepart, date);
        ELSE
            input_expr_timestamp = date::timestamp;
            -- preserving offset_string value in the case of datetimeoffset datatype before converting it to timestamps 
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                offset_string = PG_CATALOG.RIGHT(date::PG_CATALOG.TEXT, 6);
                input_expr_timestamp := PG_CATALOG.LEFT(date::PG_CATALOG.TEXT, -6)::timestamp;
            END IF;
            CASE
                WHEN datepart IN ('year', 'quarter', 'month', 'week', 'hour', 'minute', 'second', 'millisecond', 'microsecond')  THEN
                    result_date := date_trunc(datepart, input_expr_timestamp);
                WHEN datepart IN ('doy', 'day') THEN
                    result_date := date_trunc('day', input_expr_timestamp);
                WHEN datepart IN ('tsql_week') THEN
                -- sql server datepart 'iso_week' is similar to postgres 'week' datepart
                -- handle sql server datepart 'week' here based on the value of set variable 'DATEFIRST'
                    v_day := EXTRACT(dow from input_expr_timestamp)::INT;
                    datefirst_value := current_setting('babelfishpg_tsql.datefirst')::INT;
                    IF v_day = 0 THEN
                        v_day := 7;
                    END IF;
                    result_date := date_trunc('day', input_expr_timestamp);
                    days_offset := (7 + v_day - datefirst_value)%7;
                    result_date := result_date - make_interval(days => days_offset);
            END CASE;
            -- concat offset_string to result_date in case of datetimeoffset before converting it to datetimeoffset datatype.
            IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                RETURN concat(result_date, ' ', offset_string)::sys.datetimeoffset;
            ELSE
                RETURN result_date;
            END IF;
        END IF;
    END;
END;
$body$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.bbf_get_immediate_base_type_of_UDT(OID)
RETURNS OID
AS 'babelfishpg_tsql', 'get_immediate_base_type_of_UDT'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME()
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'guest') -- system users should always be visible
  OR pg_has_role(Ext.rolname, 'MEMBER')) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(-1 AS INT) AS principal_id,
CAST(type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN type = 'S' THEN 'SQL_USER'
    WHEN type = 'R' THEN 'DATABASE_ROLE'
    WHEN type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_schema_name,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(-1 AS INT) AS owning_principal_id,
CAST(CAST(0 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(0 AS SYS.BIT) AS is_fixed_role,
CAST(-1 AS INT) AS authentication_type,
CAST(NULL AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(-1 AS INT) AS default_language_lcid,
CAST(0 AS SYS.BIT) AS allow_encrypted_value_modifications
FROM (VALUES ('public', 'R'), ('sys', 'S'), ('INFORMATION_SCHEMA', 'S')) as dummy_principals(name, type);

CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.orig_username AS SYS.NVARCHAR(128)) AS NAME,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
WHEN Ext.type = 'R' THEN 'ROLE'
ELSE 'SQL USER' END
AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = sys.DB_NAME()
AND ((Ext.rolname = CURRENT_USER AND Ext.type in ('S','U')) OR
((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo' AND Ext.type = 'R' AND pg_has_role(current_user, Ext.rolname, 'MEMBER')))
UNION ALL
SELECT
CAST(-1 AS INT) AS principal_id,
CAST(CAST(-1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
DECLARE
    is_windows_grp boolean := (CHARINDEX('\', role) != 0);
BEGIN
    -- Always return 1 for 'public'
    IF (role = 'public')
    THEN RETURN 1;
    END IF;
    IF EXISTS (SELECT orig_loginname FROM sys.babelfish_authid_login_ext WHERE orig_loginname = role AND type != 'S') -- do not consider sql logins
    THEN
        IF ((EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type IN ('SERVER ROLE', 'SQL LOGIN'))) OR is_windows_grp) -- do not consider sql logins, server roles
        THEN RETURN NULL; -- Also return NULL if session is not a windows auth session but argument is a windows group
        ELSIF EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type NOT IN ('SERVER ROLE', 'SQL LOGIN'))
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSIF EXISTS (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE orig_username = role)
    THEN
        IF EXISTS (SELECT name FROM sys.user_token WHERE name = role)
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSIF (is_windows_grp)
        THEN RETURN NULL; -- Return NULL if session is not a windows auth session but argument is a windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSE RETURN NULL; -- Return NULL if role/group does not exist
    END IF;
END;
$$
LANGUAGE plpgsql STRICT STABLE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
