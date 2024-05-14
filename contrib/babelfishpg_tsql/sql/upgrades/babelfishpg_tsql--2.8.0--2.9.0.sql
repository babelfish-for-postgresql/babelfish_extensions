-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.9.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- This is a temporary procedure which is called during upgrade to update guest schema
-- for the guest users in the already existing databases
CREATE OR REPLACE PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema()
LANGUAGE C
AS 'babelfishpg_tsql', 'update_user_catalog_for_guest_schema';

CALL sys.babelfish_update_user_catalog_for_guest_schema();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema();

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


CREATE OR REPLACE VIEW sys.index_columns
AS
WITH index_id_map AS MATERIALIZED (
  SELECT
    indexrelid,
    CASE
      WHEN indisclustered THEN 1
      ELSE 1+row_number() OVER(PARTITION BY indrelid ORDER BY indexrelid)
    END AS index_id
  FROM pg_index
)
SELECT
    CAST(i.indrelid AS INT) AS object_id,
    -- should match index_id of sys.indexes 
    CAST(imap.index_id AS INT) AS index_id,
    CAST(a.index_column_id AS INT) AS index_column_id,
    CAST(a.attnum AS INT) AS column_id,
    CAST(CASE
            WHEN a.index_column_id <= i.indnkeyatts THEN a.index_column_id
            ELSE 0
         END AS SYS.TINYINT) AS key_ordinal,
    CAST(0 AS SYS.TINYINT) AS partition_ordinal,
    CAST(CASE
            WHEN i.indoption[a.index_column_id-1] & 1 = 1 THEN 1
            ELSE 0 
         END AS SYS.BIT) AS is_descending_key,
    CAST(CASE
            WHEN a.index_column_id > i.indnkeyatts THEN 1
            ELSE 0
         END AS SYS.BIT) AS is_included_column
FROM
    pg_index i
    INNER JOIN index_id_map imap ON imap.indexrelid = i.indexrelid
    INNER JOIN pg_class c ON i.indrelid = c.oid
    INNER JOIN pg_namespace nsp ON nsp.oid = c.relnamespace
    LEFT JOIN sys.babelfish_namespace_ext ext ON (nsp.nspname = ext.nspname AND ext.dbid = sys.db_id())
    LEFT JOIN unnest(i.indkey) WITH ORDINALITY AS a(attnum, index_column_id) ON true
WHERE
    has_schema_privilege(c.relnamespace, 'USAGE') AND
    has_table_privilege(c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') AND
    (nsp.nspname = 'sys' OR ext.nspname is not null) AND
    i.indislive;
GRANT SELECT ON sys.index_columns TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE STRICT
AS $$
DECLARE
    extra_bytes CONSTANT INTEGER := 4;
    return_value INTEGER;
BEGIN
	return_value:=
        CASE LOWER(property_name)
            WHEN 'charmaxlen' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes
                    ELSE NULL
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'allowsnull' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attnotnull THEN 0
                    ELSE 1
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'iscomputed' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attgenerated != '' THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            WHEN 'columnid' COLLATE sys.database_default THEN
                (SELECT a.attnum FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'ordinal' COLLATE sys.database_default THEN
                (SELECT b.count FROM (SELECT attname, row_number() OVER () AS count FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND attisdropped = false AND attnum > 0 ORDER BY a.attnum) AS b WHERE b.attname = property COLLATE sys.database_default)
            WHEN 'isidentity' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN char_length(a.attidentity) > 0 THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            ELSE
                NULL
        END;
    RETURN return_value::INTEGER;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT) TO PUBLIC;

CREATE OR REPLACE VIEW sys.computed_columns
AS
SELECT out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar(4000)) AS definition
  , 1::sys.bit AS uses_database_collation
  , 1::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_object_id = a.attrelid AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;


create or replace view sys.indexes as
-- Get all indexes from all system and user tables
with index_id_map as MATERIALIZED(
  select
    indexrelid,
    case
      when indisclustered then 1
      else 1+row_number() over(partition by indrelid order by indexrelid)
    end as index_id
  from pg_index
)
select
  cast(X.indrelid as int) as object_id
  , cast(I.relname as sys.sysname) as name
  , cast(case when X.indisclustered then 1 else 2 end as sys.tinyint) as type
  , cast(case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as sys.nvarchar(60)) as type_desc
  , cast(case when X.indisunique then 1 else 0 end as sys.bit) as is_unique
  , cast(I.reltablespace as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(case when X.indisprimary then 1 else 0 end as sys.bit) as is_primary_key
  , cast(case when const.oid is null then 0 else 1 end as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(case when X.indpred is null then 0 else 1 end as sys.bit) as is_padded
  , cast(case when X.indisready then 0 else 1 end as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(imap.index_id as int) as index_id
from pg_index X 
inner join index_id_map imap on imap.indexrelid = X.indexrelid
inner join pg_class I on I.oid = X.indexrelid and I.relkind = 'i'
inner join pg_namespace nsp on nsp.oid = I.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
-- check if index is a unique constraint
left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
where has_schema_privilege(I.relnamespace, 'USAGE')
-- index is active
and X.indislive 
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)

union all 
-- Create HEAP entries for each system and user table
select
  cast(t.oid as int) as object_id
  , cast(null as sys.sysname) as name
  , cast(0 as sys.tinyint) as type
  , cast('HEAP' as sys.nvarchar(60)) as type_desc
  , cast(0 as sys.bit) as is_unique
  , cast(1 as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(0 as sys.bit) as is_primary_key
  , cast(0 as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(0 as sys.bit) as is_padded
  , cast(0 as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(0 as int) as index_id
from pg_class t
inner join pg_namespace nsp on nsp.oid = t.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
where t.relkind = 'r'
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_tables_internal(
	in_table_name sys.nvarchar(384) = '',
	in_table_owner sys.nvarchar(384) = '', 
	in_table_qualifier sys.sysname = '',
	in_table_type sys.varchar(100) = '',
	in_fusepattern sys.bit = '1')
	RETURNS TABLE (
		out_table_qualifier sys.sysname,
		out_table_owner sys.sysname,
		out_table_name sys.sysname,
		out_table_type sys.varchar(32),
		out_remarks sys.varchar(254)
	)
	AS $$
		DECLARE opt_table sys.varchar(16) = '';
		DECLARE opt_view sys.varchar(16) = '';
		DECLARE cs_as_in_table_type varchar COLLATE "C" = in_table_type;
	BEGIN
		IF upper(cs_as_in_table_type) LIKE '%''TABLE''%' THEN
			opt_table = 'TABLE';
		END IF;
		IF upper(cs_as_in_table_type) LIKE '%''VIEW''%' THEN
			opt_view = 'VIEW';
		END IF;
		IF in_fusepattern = 1 THEN
			RETURN query
			SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(remarks AS sys.varchar(254)) AS REMARKS
			FROM sys.sp_tables_view
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name LIKE in_table_name collate sys.database_default)
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner LIKE in_table_owner collate sys.database_default)
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier LIKE in_table_qualifier collate sys.database_default)
			AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
			    OR table_type = opt_table
			    OR table_type = opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		ELSE 
			RETURN query
			SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(remarks AS sys.varchar(254)) AS REMARKS
			FROM sys.sp_tables_view
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name = in_table_name collate sys.database_default)
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner = in_table_owner collate sys.database_default)
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier = in_table_qualifier collate sys.database_default)
			AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
			    OR table_type = opt_table
			    OR table_type = opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		END IF;
	END;
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.check_for_inconsistent_metadata()
RETURNS BOOLEAN AS $$
DECLARE
    has_inconsistent_metadata BOOLEAN;
    num_rows INT;
BEGIN
    has_inconsistent_metadata := FALSE;

    -- Count the number of inconsistent metadata rows from Babelfish catalogs
    SELECT COUNT(*) INTO num_rows
    FROM sys.babelfish_inconsistent_metadata();

    has_inconsistent_metadata := num_rows > 0;

    -- Additional checks can be added here to update has_inconsistent_metadata accordingly

    RETURN has_inconsistent_metadata;
END;
$$
LANGUAGE plpgsql STABLE;


-- Folllowing functions are no longer in use
DROP FUNCTION IF EXISTS sys.babelfish_conv_string_to_date(TEXT, NUMERIC);
DROP FUNCTION IF EXISTS sys.babelfish_conv_string_to_time(TEXT, TEXT, NUMERIC);
DROP FUNCTION IF EXISTS sys.babelfish_try_conv_string_to_date(TEXT, NUMERIC);
DROP FUNCTION IF EXISTS sys.babelfish_try_conv_string_to_time(TEXT, TEXT, NUMERIC);

-- For following functions, number of arguments got updated, hence need to drop and recreate
DROP FUNCTION IF EXISTS sys.babelfish_conv_helper_to_time(TEXT, BOOL, NUMERIC);
DROP FUNCTION IF EXISTS sys.babelfish_conv_helper_to_datetime(TEXT, BOOL, NUMERIC);

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime2(IN p_datatype TEXT,
                                                                        IN p_datetimestring TEXT,
                                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_sign VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offhours VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offminutes VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_language VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATE|TIME|DATETIME2|DATETIMEOFFSET)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('\s*((\-|\+)\s*(', TIMEUNIT_REGEXP, ')\s*\:\s*(', TIMEUNIT_REGEXP, ')|Z)\s*');
    HHMMSSFSOFF_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFSOFF_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');    
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', SHORTYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*\,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', SHORTYEAR_REGEXP, '$');
    DEFMASK9_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*\,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', COMPYEAR_REGEXP, '$');
    SLASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', COMPYEAR_REGEXP, '$');
    DOT_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    DASH_FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    SLASH_FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    DOT_FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{4}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{6}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{8}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    W3C_XML_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, '(', '(\-|\+)', '(\d{2})', '\:', '(\d{2})', '|', 'Z', ')','$');                                                        
    W3C_XML_Z_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'Z','$');
    ISO_8601_DATETIMEOFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'T', '\d{2}', '\:', '\d{1,2}', '\:', '\d{1,2}', '(?:\.', '\d{1,9}', ')?', '((\-|\+)', '\d{2}', '\:', '\d{2}','|Z)?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype = 'DATE' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    -- For W3C_XML_REGEXP, there is no need of maintaining v_timepart and v_datestring
    IF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_timepart := NULL;
        v_datestring := NULL;
    ELSE
        v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFSOFF_PART_REGEXP, ')')));
        v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFSOFF_PART_REGEXP, ')'), '', 'gi'));
    END IF;

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    -- If datetime string has some part as 'AMZ' or 'PMZ' then its invalid datetime format
    IF (v_datetimestring ~* pg_catalog.concat(AMPM_REGEXP, 'Z'))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp))
            THEN
                RAISE invalid_datetime_format;      
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[1]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
                    (v_datestring !~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) AND
                     v_datestring !~* pg_catalog.replace(DEFMASK9_3_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);
        ELSE
            IF ((v_datestring !~* pg_catalog.replace(DEFMASK10_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_3_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_4_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* SLASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* DOT_COMPYEAR1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                    RAISE character_not_in_repertoire;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (101, 110)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        -- DATEFORMAT 'YDM' is not supported hence only applicable dateformat can be used here is YMD
        v_year := v_regmatch_groups[1];
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* SLASH_FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* DOT_FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 20, 21, 22, 23, 25, 101, 102, 103, 104, 105, 110, 111, 120, 121, 126, 127, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF ((v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP))
    THEN
        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFSOFF_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, W3C_XML_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

        IF (v_datetimestring !~* W3C_XML_Z_REGEXP)
        THEN
            v_sign := v_regmatch_groups[5];
            v_offhours := v_regmatch_groups[6];
            v_offminutes := v_regmatch_groups[7];
            IF ((v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
                (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
                (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
            THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_sign := '+';
            v_offhours := '0';
            v_offminutes := '0';
        END IF;
    ELSIF (v_datetimestring ~* ISO_8601_DATETIMEOFFSET_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIMEOFFSET_REGEXP, 'gi');
        
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');
        
        -- v_offhours and v_offminutes will be already set for W3C_XML datetime string format
        v_sign := coalesce(v_sign, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFSIGN'), '+');
        v_offhours := coalesce(v_offhours, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFHOURS'), '0');
        v_offminutes := coalesce(v_offminutes, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFMINUTES'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;

    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;
    
    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$') AND char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a ':'
        v_fseconds := lpad(v_fseconds, 3, '0');
    END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                        v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of conv_string_to_datetime2 function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATE'', ''TIME''/''TIME(n)'', ''DATETIME2''/''DATETIME2(n)'', ''DATETIMEOFFSET''/''DATETIMEOFFSET(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for type ''%s''', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE :=  pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'This session''s YDM date format is not supported when converting from this character string format to date, time, datetime2 or datetimeoffset. Change the session''s date format or provide a style to the explicit conversion.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

-- Following function can be used to convert string literal to DATETIME or SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_language VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,3}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');

    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
  
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{4}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{6}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{8}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    ISO_8601_DATETIME_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', '(\d{2})', '-', '(\d{2})', 'T', '\d{2}', '\:', '\d{2}', '\:', '\d{2}', '(?:\.', FRACTSECS_REGEXP, ')?','$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    END IF;

    v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFS_PART_REGEXP, ')')));
    v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFS_PART_REGEXP, ')'), '', 'gi'));

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF (v_style = 127) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[2]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 130, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
            ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
        THEN
            v_day := v_rightpart;
            v_month := v_middlepart;

        ELSIF ((v_style IN (103, 104, 105, 130, 131)) OR
               ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
        THEN
            v_day := v_middlepart;
            v_month := v_rightpart;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style IS NOT NULL AND v_style != 0)
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_date_format IN ('MYD', 'MDY', 'YMD'))
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF (v_date_format IN ('DYM', 'DMY', 'YDM'))
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_datestring !~* '^\d{4}$')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* ISO_8601_DATETIME_REGEXP)
    THEN
        IF (v_style IN (130, 131))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIME_REGEXP, 'gi');

        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    -- DATETIME/SMALLDATETIME supports time part in either left or right side of date part, 
    -- but having time on both side of date part should throw error
    IF (regexp_count(v_datetimestring, HHMMSSFS_PART_REGEXP) > 1)
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF ((v_datetimestring !~* HHMMSSFS_REGEXP AND
         length(v_datetimestring) != 0) AND
        v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;
    
    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)) OR
        ((v_res_datatype = 'DATETIME') AND (v_year::SMALLINT NOT BETWEEN 1753 AND 9999)) OR
        ((v_res_datatype = 'SMALLDATETIME') AND 
            ((v_year::SMALLINT NOT BETWEEN 1900 AND 2079) OR
             (v_year::SMALLINT = 2079 AND 
                ((v_month::SMALLINT NOT BETWEEN 1 AND 6) OR (v_day::SMALLINT NOT BETWEEN 1 AND 6))))))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;

    IF (v_timepart ~* PG_CATALOG.concat('^(', HHMMSSFS_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a '.'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            rpad(v_fseconds, 3, '0'));
    ELSE
        -- if before fractional seconds there is a ':'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            lpad(v_fseconds, 3, '0'));
    END IF;

    IF (v_res_datatype = 'SMALLDATETIME' AND
        to_char(v_resdatetime, 'SS') <> '00')
    THEN
        IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
            v_resdatetime := v_resdatetime + INTERVAL '1 minute';
        END IF;

        v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
    END IF;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for type ''%s''', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to smalldatetime data type.'
                                  ELSE 'Conversion failed when converting date and/or time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

-- Following function can be used to convert string literal to DATETIMEOFFSET
CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetimeoffset(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_sign VARCHAR COLLATE "C";
    v_offhours VARCHAR COLLATE "C";
    v_offminutes VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_resdatetime_string VARCHAR COLLATE "C";
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('\s*((\-|\+)\s*(', TIMEUNIT_REGEXP, ')\s*\:\s*(', TIMEUNIT_REGEXP, ')|Z)\s*');
    HHMMSSFSOFF_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    W3C_XML_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, '(', '(\-|\+)', '\s*(\d{2})\s*', '\:', '\s*(\d{2})\s*', '|', 'Z', ')','$');
    W3C_XML_Z_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'Z','$');
BEGIN
    v_datetimestring := upper(trim(p_datetimestring));
    -- datetimestring validation and conversion will be done in babelfish_conv_string_to_datetime2 function and a timestamp will be returned 
    v_resdatetime := sys.babelfish_conv_string_to_datetime2(p_datatype, p_datetimestring, p_style);

    v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFSOFF_PART_REGEXP, ')')));
    v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFSOFF_PART_REGEXP, ')'), '', 'gi'));

    -- Get the time offset value
    IF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, W3C_XML_REGEXP, 'gi');

        IF (v_datetimestring !~* W3C_XML_Z_REGEXP)
        THEN
            v_sign := v_regmatch_groups[5];
            v_offhours := v_regmatch_groups[6];
            v_offminutes := v_regmatch_groups[7];
        ELSE
            v_sign := '+';
            v_offhours := '0';
            v_offminutes := '0';
        END IF; 
    ELSE
        BEGIN
            v_sign := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFSIGN'), '+');
            v_offhours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFHOURS'), '0');
            v_offminutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFMINUTES'), '0');
        EXCEPTION
            WHEN OTHERS THEN
                RAISE invalid_character_value_for_cast;
        END;
    END IF;

    v_resdatetime_string := PG_CATALOG.concat(v_resdatetime::PG_CATALOG.TEXT,v_sign,v_offhours,':',v_offminutes);

    RETURN CAST(v_resdatetime_string AS sys.datetimeoffset);
EXCEPTION
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a varchar data type to a datetimeoffset data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_timeunit_from_string(IN p_timepart TEXT,
                                                                      IN p_timeunit TEXT)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_hours VARCHAR COLLATE "C";
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fractsecs VARCHAR COLLATE "C";
    v_sign VARCHAR COLLATE "C";
    v_offhours VARCHAR COLLATE "C";
    v_offminutes VARCHAR COLLATE "C";
    v_daypart VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_offset VARCHAR COLLATE "C";
    v_timeunit VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('((\-|\+)', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|Z)');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
BEGIN
    v_timepart := upper(trim(p_timepart));
    v_timeunit := upper(trim(p_timeunit));

    v_daypart := substring(v_timepart, AMPM_REGEXP);
    v_offset := substring(v_timepart, TIME_OFFSET_REGEXP);
    v_timepart := trim(regexp_replace(v_timepart, AMPM_REGEXP, ''));
    v_timepart := trim(regexp_replace(v_timepart, TIME_OFFSET_REGEXP, ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timepart ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timepart ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timepart ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timepart ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timepart ~* HH_REGEXP) THEN HH_REGEXP
        END;

    v_regmatch_groups := regexp_matches(v_timepart, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1];
    v_minutes := v_regmatch_groups[2];

    IF (v_timepart ~* HHMMFS_REGEXP) THEN
        v_fractsecs := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fractsecs := v_regmatch_groups[4];
    END IF;
    
    v_regmatch_groups := regexp_matches(v_offset, TIME_OFFSET_REGEXP, 'gi');

    v_sign := coalesce(v_regmatch_groups[2], '+');
    v_offhours := coalesce(v_regmatch_groups[3], '0');
    v_offminutes := coalesce(v_regmatch_groups[4], '0');

    IF ((v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
        (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF (v_timeunit = 'HOURS' AND v_daypart IS NOT NULL)
    THEN
        IF ((v_daypart = 'AM' AND v_hours::SMALLINT NOT BETWEEN 0 AND 12) OR
            (v_daypart = 'PM' AND v_hours::SMALLINT NOT BETWEEN 1 AND 23))
        THEN
            RAISE numeric_value_out_of_range;
        ELSIF (v_daypart = 'PM' AND v_hours::SMALLINT < 12) THEN
            v_hours := (v_hours::SMALLINT + 12)::VARCHAR;
        ELSIF (v_daypart = 'AM' AND v_hours::SMALLINT = 12) THEN
            v_hours := (v_hours::SMALLINT - 12)::VARCHAR;
        END IF;
    ELSIF ((v_timeunit = 'HOURS' AND v_hours::SMALLINT NOT BETWEEN 0 AND 23) OR
        (v_timeunit = 'MINUTES' AND v_minutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_timeunit = 'SECONDS' AND v_seconds::SMALLINT NOT BETWEEN 0 AND 59))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    RETURN CASE v_timeunit
              WHEN 'HOURS' THEN v_hours
              WHEN 'MINUTES' THEN v_minutes
              WHEN 'SECONDS' THEN v_seconds
              WHEN 'FRACTSECONDS' THEN v_fractsecs
              WHEN 'OFFHOURS' THEN v_offhours
              WHEN 'OFFMINUTES' THEN v_offminutes
              WHEN 'OFFSIGN' THEN v_sign
           END;
EXCEPTION
    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a VARCHAR data type to a TIME data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

-- DROP function babelfish_try_conv_string_to_date
-- DROP function babelfish_try_conv_string_to_time

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetime2(IN p_datestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetime2(p_datestring,
                                                 p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetimeoffset(IN p_datatype TEXT,
                                                                         IN p_datetimestring TEXT,
                                                                         IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetimeoffset(p_datatype,
                                                        p_datetimestring ,
                                                        p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_datetime2('DATE', arg, p_style);
    ELSE
	    RETURN sys.babelfish_conv_string_to_datetime2('DATE', arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.VARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.NVARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg anyelement,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
DECLARE
    resdate DATE;
BEGIN
    IF try THEN
        resdate := sys.babelfish_try_conv_to_date(arg); 
    ELSE
        BEGIN
            resdate := CAST(arg AS DATE);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to date is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type date.';
        END;
    END IF;

    RETURN resdate;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg TEXT,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
DECLARE
    v_res_datatype VARCHAR COLLATE "C";
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'TIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('TIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    ELSE
	    RETURN sys.babelfish_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.VARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.NVARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg anyelement,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
DECLARE
    restime TIME;
BEGIN
    IF try THEN
        restime := sys.babelfish_try_conv_to_time(arg);
    ELSE
        BEGIN
            restime := CAST(arg AS TIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to time is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type time.';
        END;
    END IF;

    RETURN restime;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
DECLARE
    v_res_datatype VARCHAR COLLATE "C";
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
DECLARE
    resdatetime sys.DATETIME;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_datetime(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.DATETIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetime.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIME);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

-- convertion to datetime2
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    v_res_datatype VARCHAR COLLATE "C";
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIME2';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIME2(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    resdatetime sys.DATETIME2;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_datetime2(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.DATETIME2);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime2 is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetime2.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime2(IN arg anyelement)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIME2);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

-- convertion to datetimeoffset
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_res_datatype VARCHAR COLLATE "C";
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIMEOFFSET';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIMEOFFSET(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetimeoffset(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetimeoffset(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    resdatetimeoffset sys.DATETIMEOFFSET;
BEGIN
    IF try THEN
        resdatetimeoffset := sys.babelfish_try_conv_to_datetimeoffset(arg);
    ELSE
        BEGIN
            resdatetimeoffset := CAST(arg AS sys.DATETIMEOFFSET);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetimeoffset is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetimeoffset.';
        END;
    END IF;

    RETURN resdatetimeoffset;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetimeoffset(IN arg anyelement)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIMEOFFSET);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

-- convertion to smalldatetime
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
DECLARE
    v_res_datatype VARCHAR COLLATE "C";
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'SMALLDATETIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('SMALLDATETIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
DECLARE
    resdatetime sys.SMALLDATETIME;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_smalldatetime(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.SMALLDATETIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to smalldatetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type smalldatetime.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_smalldatetime(IN arg anyelement)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.SMALLDATETIME);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
