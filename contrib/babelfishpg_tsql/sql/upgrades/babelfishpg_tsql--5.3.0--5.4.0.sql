-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.4.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

----------------------------------------------------------------
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
        IF p_style != 0 AND pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.varchar'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
            RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
        ELSE
            IF typmod = -1 THEN
                CASE pg_typeof(arg)
					WHEN 'sys.nvarchar'::regtype THEN
						RETURN sys.nvarcharvarbinary(arg, typmod, true);
					WHEN 'sys.nchar'::regtype THEN
						RETURN sys.ncharvarbinary(arg, typmod, true);
					WHEN 'sys.bpchar'::regtype THEN
						RETURN sys.bpcharvarbinary(arg, typmod, true);
					WHEN 'sys.varchar'::regtype THEN
						RETURN sys.varcharvarbinary(arg, typmod, true);
					ELSE
						-- For other types, just cast to varbinary
						RETURN CAST(arg as sys.varbinary);
				END CASE;
            ELSE
				CASE pg_typeof(arg)
					WHEN 'sys.nvarchar'::regtype THEN
						RETURN sys.nvarcharvarbinary(arg, -1, true);
					WHEN 'sys.nchar'::regtype THEN
						RETURN sys.ncharvarbinary(arg, -1, true);
					WHEN 'sys.bpchar'::regtype THEN
						RETURN sys.bpcharvarbinary(arg, -1, true);
					WHEN 'sys.varchar'::regtype THEN
						RETURN sys.varcharvarbinary(arg, -1, true);
					ELSE
						-- For other types, execute the cast with the specified typmod
                		EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
               			RETURN result;
                END CASE;
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
    IF p_style != 0 AND pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.varchar'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
        RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
    ELSE
        IF typmod = -1 THEN
            CASE pg_typeof(arg)
				WHEN 'sys.nvarchar'::regtype THEN
					RETURN sys.nvarcharvarbinary(arg, typmod, true);
				WHEN 'sys.nchar'::regtype THEN
					RETURN sys.ncharvarbinary(arg, typmod, true);
				WHEN 'sys.bpchar'::regtype THEN
					RETURN sys.bpcharvarbinary(arg, typmod, true);
				WHEN 'sys.varchar'::regtype THEN
					RETURN sys.varcharvarbinary(arg, typmod, true);
				ELSE
					-- For other types, just cast to varbinary
					RETURN CAST(arg as sys.varbinary);
			END CASE;
        ELSE
			CASE pg_typeof(arg)
				WHEN 'sys.nvarchar'::regtype THEN
					RETURN sys.nvarcharvarbinary(arg, -1, true);
				WHEN 'sys.nchar'::regtype THEN
					RETURN sys.ncharvarbinary(arg, -1, true);
				WHEN 'sys.bpchar'::regtype THEN
					RETURN sys.bpcharvarbinary(arg, -1, true);
				WHEN 'sys.varchar'::regtype THEN
					RETURN sys.varcharvarbinary(arg, -1, true);
				ELSE
					-- For other types, execute the cast with the specified typmod
            		EXECUTE format('SELECT CAST($1 as sys.varbinary(%s))', typmod) INTO result USING arg;
           			RETURN result;
            END CASE;
        END IF;
    END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;  

-- Helper function to convert to binary or varbinary
CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_varbinary(IN input_value sys.VARCHAR, IN style NUMERIC DEFAULT 0) 
RETURNS sys.varbinary 
AS 
$BODY$
DECLARE
    result bytea; 
BEGIN
    IF style = 0 THEN
        RETURN CAST(input_value AS sys.varbinary);
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
        RETURN sys.babelfish_try_conv_string_to_varbinary(arg::sys.varchar, p_style);
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
----------------------------------------------------------------
-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
