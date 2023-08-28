-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.4.0'" to load this file. \quit

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

ALTER FUNCTION sys.power(IN arg1 BIGINT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 INT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 SMALLINT, IN arg2 NUMERIC) STRICT;

ALTER FUNCTION sys.power(IN arg1 TINYINT, IN arg2 NUMERIC) STRICT;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Matches and returns column length of the corresponding column of the given table
CREATE OR REPLACE FUNCTION sys.COL_LENGTH(IN object_name TEXT, IN column_name TEXT)
RETURNS SMALLINT AS $BODY$
    DECLARE
        col_name TEXT;
        object_id oid;
        column_id INT;
        column_length INT;
        column_data_type TEXT;
        column_precision INT;
    BEGIN
        -- Get the object ID for the provided object_name
        object_id = sys.OBJECT_ID(object_name);
        IF object_id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Truncate and normalize the column name
        col_name = sys.babelfish_truncate_identifier(sys.babelfish_remove_delimiter_pair(lower(column_name)));

        -- Get the column ID for the provided column_name
        SELECT attnum INTO column_id FROM pg_attribute 
        WHERE attrelid = object_id AND lower(attname) = col_name 
        COLLATE sys.database_default;

        IF column_id IS NULL THEN
            RETURN NULL;
        END IF;

        -- Retrieve the data type, precision, scale, and column length in characters
        SELECT a.atttypid::regtype, 
               CASE 
                   WHEN a.atttypmod > 0 THEN ((a.atttypmod - 4) >> 16) & 65535
                   ELSE NULL
               END,
               CASE
                   WHEN a.atttypmod > 0 THEN ((a.atttypmod - 4) & 65535)
                   ELSE a.atttypmod
               END
        INTO column_data_type, column_precision, column_length
        FROM pg_attribute a
        WHERE a.attrelid = object_id AND a.attnum = column_id;

        -- Remove delimiters
        column_data_type := sys.babelfish_remove_delimiter_pair(column_data_type);

        IF column_data_type IS NOT NULL THEN
            column_length := CASE
                -- Columns declared with max specifier case
                WHEN column_length = -1 AND column_data_type IN ('varchar', 'nvarchar', 'varbinary')
                THEN -1
                WHEN column_data_type = 'xml'
                THEN -1
                WHEN column_data_type IN ('tinyint', 'bit') 
                THEN 1
                WHEN column_data_type = 'smallint'
                THEN 2
                WHEN column_data_type = 'date'
                THEN 3
                WHEN column_data_type IN ('int', 'integer', 'real', 'smalldatetime', 'smallmoney') 
                THEN 4
                WHEN column_data_type IN ('time', 'time without time zone')
                THEN 5
                WHEN column_data_type IN ('double precision', 'bigint', 'datetime', 'datetime2', 'money') 
                THEN 8
                WHEN column_data_type = 'datetimeoffset'
                THEN 10
                WHEN column_data_type IN ('uniqueidentifier', 'text', 'image', 'ntext')
                THEN 16
                WHEN column_data_type = 'sysname'
                THEN 256
                WHEN column_data_type = 'sql_variant'
                THEN 8016
                WHEN column_data_type IN ('bpchar', 'char', 'varchar', 'binary', 'varbinary') 
                THEN column_length
                WHEN column_data_type IN ('nchar', 'nvarchar') 
                THEN column_length * 2
                WHEN column_data_type IN ('numeric', 'decimal')
                THEN 
                    CASE
                        WHEN column_precision IS NULL 
                        THEN NULL
                        ELSE ((column_precision + 8) / 9 * 4 + 1)
                    END
                ELSE NULL
            END;
        END IF;

        RETURN column_length::SMALLINT;
    END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE

-- Matches and returns column name of the corresponding table
CREATE OR REPLACE FUNCTION sys.COL_NAME(IN table_id INT, IN column_id INT)
RETURNS sys.SYSNAME AS $$
    DECLARE
        column_name TEXT;
    BEGIN
        SELECT attname INTO STRICT column_name 
        FROM pg_attribute 
        WHERE attrelid = table_id AND attnum = column_id AND attnum > 0;
        
        RETURN column_name::sys.SYSNAME;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END; 
$$
LANGUAGE plpgsql IMMUTABLE
STRICT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
