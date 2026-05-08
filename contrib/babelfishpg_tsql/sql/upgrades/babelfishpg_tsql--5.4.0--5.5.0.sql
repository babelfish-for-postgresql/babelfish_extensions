-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.5.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

-- Rename the varchar overloads to mark as deprecated in 5.5.0
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_varbinary(typmod integer, arg sys."varchar", try boolean, p_style numeric) RENAME TO babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_string_to_varbinary(arg sys."varchar", p_style numeric) RENAME TO babelfish_try_conv_string_to_varbinary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_varbinary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_string_to_varbinary(IN input_value sys.VARCHAR, IN p_style NUMERIC) RENAME TO babelfish_conv_string_to_varbinary_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_varbinary_deprecated_in_5_5_0');

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_varbinary(IN input_value anyelement,
																	IN style NUMERIC DEFAULT 0)
RETURNS sys.varbinary 
AS 
$BODY$
DECLARE
    result bytea; 
BEGIN
    IF style = 0 THEN
        CASE pg_typeof(input_value)
			WHEN 'sys.nvarchar'::regtype THEN
				RETURN sys.nvarcharvarbinary(input_value, -1, true);
			WHEN 'sys.nchar'::regtype THEN
				RETURN sys.ncharvarbinary(input_value, -1, true);
			ELSE
                RETURN CAST(input_value AS sys.varbinary);
        END CASE;
    ELSIF style = 1 THEN
        -- Handle hexadecimal conversion
        IF (PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" AND PG_CATALOG.length(input_value) % 2 = 0) THEN
            result := decode(substring(input_value from 3), 'hex');
        ELSE
            RAISE EXCEPTION 'Error converting data type varchar to varbinary.';
        END IF;
    ELSIF style = 2 THEN
        IF PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" THEN
            RAISE EXCEPTION 'Error converting data type varchar to varbinary.';
        ELSE
            result := decode(input_value, 'hex');
        END IF;
    ELSE
        RAISE EXCEPTION 'The style % is not supported for conversions from varchar to varbinary.', style;
    END IF;

	RETURN CAST(result AS sys.varbinary);
END;
$BODY$ 
LANGUAGE plpgsql
IMMUTABLE
STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(IN typmod INTEGER,
																	IN arg anyelement,
																	IN try BOOL,
																	IN p_style NUMERIC DEFAULT 0)
RETURNS sys.varbinary
AS
$BODY$
DECLARE result sys.varbinary;
BEGIN
	IF try THEN
		RETURN sys.babelfish_try_conv_to_varbinary(typmod, arg, p_style);
	ELSE
		IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
			RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
		ELSE
			IF typmod = -1 THEN
				RETURN CAST(arg as sys.varbinary);
			ELSE
				EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
				RETURN result;
			END IF;
		END IF;
	END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE; 


CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varbinary(IN typmod INTEGER,
																IN arg anyelement,
																IN p_style NUMERIC DEFAULT 0)
RETURNS sys.varbinary
AS
$BODY$
DECLARE result sys.varbinary;
BEGIN
	IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
		RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
	ELSE
		IF typmod = -1 THEN
			RETURN CAST(arg as sys.varbinary);
		ELSE
			EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
			RETURN result;
		END IF;
	END IF;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;  

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(
    IN typmod INTEGER,
    IN arg TEXT,
    IN try BOOL,
    IN p_style NUMERIC DEFAULT 0
)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_varbinary(arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_varbinary(arg::sys.varchar, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_varbinary(
    IN arg TEXT,
    IN p_style NUMERIC DEFAULT 0
)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_varbinary(arg::sys.varchar, p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

-- Rename the varchar overloads to mark as deprecated in 5.5.0
DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_binary(typmod integer, arg sys."varchar", try boolean, p_style numeric) RENAME TO babelfish_conv_helper_to_binary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_binary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_try_conv_string_to_binary(arg sys."varchar", p_style numeric) RENAME TO babelfish_try_conv_string_to_binary_varchar_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_binary_varchar_deprecated_in_5_5_0');

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_string_to_binary(IN input_value sys.VARCHAR, IN p_style NUMERIC) RENAME TO babelfish_conv_string_to_binary_deprecated_in_5_5_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_binary_deprecated_in_5_5_0');

-- Binary conversion helper functions
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg anyelement,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_binary(typmod, arg, p_style);
    ELSE
        IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
            RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
        ELSE
            IF typmod = -1 THEN
                RETURN CAST(arg as sys.binary);
            ELSE
                EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
                RETURN result;
            END IF;
        END IF;
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_binary(IN typmod INTEGER,
                                                               IN arg TEXT,
                                                               IN try BOOL,
                                                               IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_binary(arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_binary(arg::sys.varchar, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_binary(IN arg TEXT,
                                                                   IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_binary(arg::sys.varchar, p_style);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_binary(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN p_style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE result sys.binary;
BEGIN
    IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype, 'sys.varchar'::regtype) THEN
        RETURN sys.babelfish_conv_string_to_binary(arg, p_style);
    ELSE
        IF typmod = -1 THEN
            RETURN CAST(arg as sys.binary);
        ELSE
            EXECUTE format('SELECT CAST($1 as sys.binary(%s))', typmod) INTO result USING arg;
            RETURN result;
        END IF;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_binary(IN input_value ANYELEMENT, IN style NUMERIC DEFAULT 0)
RETURNS sys.binary
AS
$BODY$
DECLARE
    result bytea;
BEGIN
    IF style = 0 THEN
        CASE pg_typeof(input_value)
			WHEN 'sys.nvarchar'::regtype THEN
				RETURN sys.nvarcharbinary(input_value, -1, true);
			WHEN 'sys.nchar'::regtype THEN
				RETURN sys.ncharbinary(input_value, -1, true);
			ELSE
                RETURN CAST(input_value AS sys.binary);
        END CASE;
    ELSIF style = 1 THEN
        IF (PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" AND PG_CATALOG.length(input_value) % 2 = 0) THEN
            result := decode(substring(input_value from 3), 'hex');
        ELSE
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        END IF;
    ELSIF style = 2 THEN
        IF PG_CATALOG.left(input_value, 2) = '0x' COLLATE "C" THEN
            RAISE EXCEPTION 'Error converting data type varchar to binary.';
        ELSE
            result := decode(input_value, 'hex');
        END IF;
    ELSE
        RAISE EXCEPTION 'The style % is not supported for conversions from varchar to binary.', style;
    END IF;

    RETURN CAST(result AS sys.binary);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
STRICT;

-- conversion to varchar
CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
	v_style SMALLINT;
BEGIN
	v_style := floor(p_style)::SMALLINT;

	CASE pg_typeof(arg)
	WHEN 'date'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg, p_style);
		END IF;
	WHEN 'time'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg);
		ELSE
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg, p_style);
		END IF;
	WHEN 'sys.datetime'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp);
		ELSE
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp, p_style);
		END IF;
	WHEN 'float'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg, p_style);
		END IF;
	WHEN 'sys.money'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4));
		ELSE
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4), p_style);
		END IF;
	WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.varbinarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
	WHEN 'sys.binary'::regtype THEN
		IF lower(typename) LIKE 'nvarchar%' THEN
			RETURN (sys.binarysysnvarchar(arg, -1, true));
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END IF;
	ELSE
		RETURN CAST(arg AS sys.VARCHAR);
	END CASE;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.varbinarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		WHEN 'sys.binary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.binarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.VARCHAR);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg ANYELEMENT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'sys.nvarchar'::regtype THEN
			RETURN sys.nvarcharvarbinary(arg, -1, true);
		WHEN 'sys.nchar'::regtype THEN
			RETURN sys.ncharvarbinary(arg, -1, true);
		ELSE
			RETURN CAST(arg AS sys.varbinary);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg TEXT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.varbinary);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.fn_varbintohexstr(expression sys.varbinary)
RETURNS sys.nvarchar AS 
$$ 
BEGIN 
    IF sys.len(expression) = 0 THEN
        RETURN NULL;
    END IF;
    RETURN pg_catalog.lower(expression::PG_CATALOG.TEXT);
END;
$$ 
LANGUAGE plpgsql IMMUTABLE STRICT;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
	WITH tt_internal AS MATERIALIZED (
		SELECT * FROM sys.table_types_internal
	)
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
				c.relname)
			AS sys._ci_sysname) AS "TABLE_NAME",

		   CAST(
			 CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
				  WHEN c.relkind = 'v' THEN 'VIEW'
				  ELSE null END
			 AS sys.varchar(10)) COLLATE sys.database_default AS "TABLE_TYPE"

	FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
		   LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
		   LEFT JOIN tt_internal tt ON c.oid = tt.typrelid

	WHERE c.relkind IN ('r', 'v', 'p')
		AND c.relispartition = false
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid IS NULL
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
