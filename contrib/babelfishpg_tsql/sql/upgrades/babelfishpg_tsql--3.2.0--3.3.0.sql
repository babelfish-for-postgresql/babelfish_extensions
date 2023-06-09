-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.3.0'" to load this file. \quit

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

ALTER FUNCTION sys.parsename(VARCHAR,INT) RENAME TO parsename_deprecated_in_3_3_0;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.VARCHAR, object_piece int)
RETURNS sys.SYSNAME
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_3_0');


CREATE OR REPLACE FUNCTION typeproperty(
    typename sys.VARCHAR,
    property sys.VARCHAR
    )
RETURNS INT
AS $$
DECLARE
    var_sc int;
    schemaid int;
    preci int;
    schema_name VARCHAR;
    type_name VARCHAR;
    type_namee VARCHAR;
    sys_id int;
    testt VARCHAR;
BEGIN

    property := RTRIM(LOWER(COALESCE(property COLLATE "C",'')));

    IF typename LIKE '%.%'  THEN
    schema_name := RTRIM(lower(split_part(typename COLLATE "C", '.', 1)));
    type_name :=  RTRIM(lower((split_part(typename COLLATE "C",'.', 2))));
    ELSE
    schema_name := 'dbo';
    type_name := RTRIM(LOWER(typename));
    END IF;


    IF NOT EXISTS (SELECT ao.name FROM sys.types ao WHERE ao.name = type_name COLLATE sys.database_default)
    THEN
        RETURN NULL;
    END IF;

    IF NOT EXISTS (SELECT ao.name FROM sys.schemas ao WHERE ao.name = schema_name COLLATE sys.database_default OR schema_name = 'sys' OR schema_name = 'pg_catalog')
    THEN
        RETURN NULL ;
    END IF;

    IF NOT EXISTS (SELECT ty.name FROM sys.types ty WHERE ty.name = type_name COLLATE sys.database_default AND ty.is_user_defined = 0) THEN
    schemaid := (SELECT sc.schema_id FROM sys.schemas sc WHERE sc.name = schema_name COLLATE sys.database_default);
    ELSE
        schemaid := (SELECT sc.schema_id FROM sys.types sc WHERE sc.name = type_name COLLATE sys.database_default);
        IF schema_name = 'dbo'
        THEN
        schema_name := schema_name(schemaid);
        END IF;
    END IF;


    if (SELECT schema_id(schema_name)) <> schemaid
    THEN
    RETURN NULL;
    END IF;

    sys_id := (SELECT CAST(dc.system_type_id AS INT) FROM sys.types dc WHERE dc.name = type_name COLLATE sys.database_default AND dc.schema_id = schemaid);
    type_namee := (SELECT CAST(dc.name AS VARCHAR) FROM sys.types dc WHERE dc.system_type_id = sys_id AND dc.is_user_defined = 0);

    IF property = 'allowsnull'
    THEN
        RETURN (
            SELECT CAST( t1.is_nullable AS INT)
            FROM sys.types t1
            WHERE t1.name = type_name COLLATE sys.database_default AND t1.schema_id = schemaid );

    ELSEIF property = 'precision'
    THEN
        preci := (SELECT CAST(dc.precision AS INT) FROM sys.types dc WHERE dc.name = type_name COLLATE sys.database_default AND dc.schema_id = schemaid);
        IF sys_id = 0
        THEN
            RETURN preci;
        END IF;

        IF preci = 0
        THEN
            preci = (SELECT CAST(dc.prec AS INT) FROM sys.systypes dc WHERE dc.name = type_name COLLATE sys.database_default AND dc.uid = schemaid);
            IF preci IS NULL
            THEN
                IF type_namee = 'image' or type_namee = 'text'
                THEN
                RETURN 2147483647;
                ELSEIF type_namee = 'ntext'
                THEN
                RETURN 1073741823;
                END IF;
            END IF;
            RETURN preci;
        ELSE
            RETURN preci;
        END IF;        

    ELSEIF property = 'scale'
    THEN
        preci := (SELECT CAST(dc.precision AS INT) FROM sys.types dc WHERE dc.name = type_namee COLLATE sys.database_default AND dc.system_type_id = sys_id);
        IF sys_id = 0
        THEN
            RETURN preci;
        END IF;
        IF preci = 0 or type_namee = 'float' or type_namee = 'real' or type_namee = 'bit'
        THEN
            RETURN NULL;
        ELSE
            RETURN(SELECT CAST(dc.scale AS INT) FROM sys.types dc WHERE dc.name = type_name COLLATE sys.database_default AND dc.schema_id = schemaid);
        END IF;
    ELSEIF property = 'ownerid'
    THEN
        IF NOT EXISTS (SELECT ty.name FROM sys.types ty WHERE ty.name = type_name COLLATE sys.database_default AND ty.is_user_defined = 0) THEN
        RETURN(SELECT CAST(dc.nspowner AS INT) FROM  pg_catalog.pg_namespace dc WHERE dc.oid = schemaid);
        ELSE
        RETURN 10;
        END IF;

    ELSEIF property = 'usesansitrim'
    THEN
        IF type_name::regtype IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'tinyint'::regtype,
            'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'money'::regtype)
        THEN
            RETURN NULL;
        ELSE
            RETURN 1;
        END IF;

    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql STABLE;



-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
