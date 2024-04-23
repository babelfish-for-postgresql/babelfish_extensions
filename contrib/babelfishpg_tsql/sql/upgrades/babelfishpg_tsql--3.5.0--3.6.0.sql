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

-- BABELFISH_SCHEMA_PERMISSIONS
CREATE TABLE IF NOT EXISTS sys.babelfish_schema_permissions (
  dbid smallint NOT NULL,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  permission INT CHECK(permission > 0),
  grantee sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_type CHAR(1) NOT NULL COLLATE sys.database_default,
  function_args TEXT COLLATE "C",
  grantor sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, object_name, grantee, object_type)
);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_schema_permissions', '');

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


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  value_type text;
  enum_value text[];
  cnt int;
  cur refcursor;
  guc_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' collate "C" THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  IF cnt = 0 THEN 
    IF LOWER(normalized_name) = 'babelfishpg_tsql.escape_hatch_unique_constraint' COLLATE C THEN
      CALl sys.printarg('Config option babelfishpg_tsql.escape_hatch_unique_constraint has been deprecated, babelfish now supports unique constraints on nullable columns');
    ELSE
      RAISE EXCEPTION 'unknown configuration: %', normalized_name;
    END IF;
  ELSIF cnt > 1 AND (lower("@option_value") != 'ignore' AND lower("@option_value") != 'strict' 
                AND lower("@option_value") != 'default') THEN
    RAISE EXCEPTION 'unvalid option: %', lower("@option_value");
  END IF;

  OPEN cur FOR SELECT name FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  LOOP
    FETCH NEXT FROM cur into guc_name;
    exit when not found;

    SELECT boot_val, vartype, enumvals INTO default_value, value_type, enum_value FROM pg_catalog.pg_settings WHERE name = guc_name;
    IF lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(guc_name, default_value, 'false');
    ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
      IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
      ELSE
        CONTINUE;
      END IF;
    ELSE
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, default_value);
      ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
        IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
          EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
        ELSE
          CONTINUE;
        END IF;
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
      END IF;
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(
	IN varchar(128), IN varchar(128), IN varchar(128)
) TO PUBLIC;

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
    v_datatype := pg_catalog.upper(trim(p_datatype));
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
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

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

    v_day := ltrim(to_char(v_dateval, 'DD'), '0');
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
                                     pg_catalog.lower(v_res_datatype),
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
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

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
    v_datatype := pg_catalog.upper(trim(p_datatype));
    v_src_datatype := pg_catalog.upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;

        v_src_datatype := rtrim(split_part(v_src_datatype, '(', 1));

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
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

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

    v_day := ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := ltrim(to_char(v_datetimeval, 'HH12'), '0');
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
                                      v_lengthexpr, pg_catalog.lower(v_res_datatype), v_maxlength),
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
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

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
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    DIGITREPRESENT_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\-?\d+\.?(?:\d+)?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{6}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{8}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := pg_catalog.upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' AND v_scale IS NOT NULL)
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
             (v_style IN (120, 121, 126, 127, 130, 131))) AND
             v_res_datatype = 'DATETIME2')
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_timepart := trim(substring(v_datetimestring, HHMMSSFS_PART_REGEXP));
    v_datestring := trim(regexp_replace(v_datetimestring, HHMMSSFS_PART_REGEXP, '', 'gi'));

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
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
        IF ((v_style IN (127, 130, 131) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
            (v_style IN (130, 131) AND v_res_datatype = 'DATETIME2'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF ((v_datestring ~* pg_catalog.replace(DEFMASK1_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK2_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK3_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK4_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK5_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK6_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK7_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        END IF;

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
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11, 12) AND v_res_datatype = 'DATETIME2'))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10) AND v_date_format <> 'MDY' AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10, 22) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                (v_style IN (1, 10, 22) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   (v_style IN (0, 2, 11) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   (v_style IN (0, 3, 4, 5) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF (v_style = 0 AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'YDM')
            THEN
                IF (v_res_datatype = 'DATETIME2') THEN
                    RAISE character_not_in_repertoire;
                END IF;

                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            ELSE
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
                v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME') THEN
                RAISE invalid_character_value_for_cast;
            END IF;

            v_year := v_rightpart;
            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;

                ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (101, 110) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                       (v_style IN (0, 101, 110) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSE
                    IF (v_res_datatype = 'DATETIME2') THEN
                        RAISE invalid_datetime_format;
                    END IF;

                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
            v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT <= 12) OR v_res_datatype = 'DATETIME2')
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 23, 25, 101, 102, 110, 111, 120, 121, 126, 127) AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM'))
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
            END IF;
        ELSIF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT > 12)
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM')) OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                   (v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_res_datatype <> 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{6}$')
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
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* DIGITREPRESENT_REGEXP)
    THEN
        v_resdatetime = CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + v_datetimestring::NUMERIC;
        RETURN v_resdatetime;
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datetimestring ~* HHMMSSFS_PART_REGEXP AND v_res_datatype = 'DATETIME2') OR
        (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP OR
          v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP OR v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR1_0_REGEXP)) AND
        v_style IN (130, 131))
    THEN
        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
    v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
    v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
    v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

    IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') OR
         (v_res_datatype = 'DATETIME2' AND v_timepart !~* HHMMSSFS_DOT_PART_REGEXP)) AND
        char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        IF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                                 v_hours, v_minutes, v_seconds,
                                                                 rpad(v_fseconds, 3, '0'));
            IF (v_res_datatype = 'SMALLDATETIME' AND
                to_char(v_resdatetime, 'SS') <> '00')
            THEN
                IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
                    v_resdatetime := v_resdatetime + INTERVAL '1 minute';
                END IF;

                v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSIF (v_res_datatype = 'DATETIME2')
        THEN
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);
            v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN datetime_field_overflow THEN
            RAISE invalid_datetime_format;
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_character_value_for_cast;
        END IF;
    END;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_datetime function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to %s.', v_style, v_res_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to SMALLDATETIME data type.'
                                  ELSE 'Conversion failed when converting date and time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a VARCHAR data type to a DATETIME data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date and time.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT,
                                                                 IN p_timestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hours SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_daypart VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_minutes SMALLINT;
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
BEGIN
    v_datatype := trim(regexp_replace(p_datatype, 'DATETIME', 'TIME', 'gi'));
    v_timestring := pg_catalog.upper(trim(p_timestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_src_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_src_datatype IS NULL) THEN
        RAISE datatype_mismatch;
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
             v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_daypart := substring(v_timestring, 'AM|PM');
    v_timestring := trim(regexp_replace(v_timestring, coalesce(v_daypart, ''), ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timestring ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timestring ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timestring ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timestring ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timestring ~* HH_REGEXP) THEN HH_REGEXP
        END;

    IF (v_timeunit_mask IS NULL) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_regmatch_groups := regexp_matches(v_timestring, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1]::SMALLINT;
    v_minutes := v_regmatch_groups[2]::SMALLINT;

    IF (v_timestring ~* HHMMFS_REGEXP) THEN
        v_fseconds := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fseconds := v_regmatch_groups[4];
    END IF;

   IF (v_daypart IS NOT NULL) THEN
      IF ((v_daypart = 'AM' AND v_hours NOT BETWEEN 0 AND 12) OR
          (v_daypart = 'PM' AND v_hours NOT BETWEEN 1 AND 23))
      THEN
          RAISE numeric_value_out_of_range;
      ELSIF (v_daypart = 'PM' AND v_hours < 12) THEN
          v_hours := v_hours + 12;
      ELSIF (v_daypart = 'AM' AND v_hours = 12) THEN
          v_hours := v_hours - 12;
      END IF;
   END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    RETURN make_time(v_hours, v_minutes, v_seconds::NUMERIC);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_time function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

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
    v_datatype := pg_catalog.upper(trim(p_datatype));
    v_src_datatype := pg_catalog.upper(trim(p_src_datatype));
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
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

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

    v_hours := ltrim(to_char(p_timeval, 'HH12'), '0');
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
                                     v_lengthexpr, pg_catalog.lower(v_res_datatype), v_res_maxlength),
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
                                      rtrim(split_part(trim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_lang_metadata_json(IN p_lang_spec_culture TEXT)
RETURNS JSONB
AS
$BODY$
DECLARE
    v_locale_parts TEXT[] COLLATE "C";
    v_lang_data_jsonb JSONB;
    v_lang_spec_culture VARCHAR COLLATE "C";
    v_is_cached BOOLEAN := FALSE;
BEGIN
    v_lang_spec_culture := pg_catalog.upper(trim(p_lang_spec_culture));

    IF (char_length(v_lang_spec_culture) > 0)
    THEN
        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s',
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            v_lang_spec_culture := pg_catalog.upper(regexp_replace(v_lang_spec_culture, '-\s*', '_', 'gi'));
            IF (v_lang_spec_culture IN ('AR', 'FI') OR
                v_lang_spec_culture ~ '_')
            THEN
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.babelfish_syslanguages
                 WHERE spec_culture = v_lang_spec_culture;
            ELSE
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.babelfish_syslanguages
                 WHERE lang_name_mssql = v_lang_spec_culture
                    OR lang_alias_mssql = v_lang_spec_culture;
            END IF;
        ELSE
            v_is_cached := TRUE;
        END IF;
    ELSE
        v_lang_spec_culture := current_setting('LC_TIME');

        v_lang_spec_culture := CASE
                                  WHEN (v_lang_spec_culture !~ '\.') THEN v_lang_spec_culture
                                  ELSE substring(v_lang_spec_culture, '(.*)(?:\.)')
                               END;

        v_lang_spec_culture := pg_catalog.upper(regexp_replace(v_lang_spec_culture, ',\s*', '_', 'gi'));

        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s',
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            BEGIN
                IF (char_length(v_lang_spec_culture) = 5)
                THEN
                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
                ELSE
                    v_locale_parts := string_to_array(v_lang_spec_culture, '-');

                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE lang_name_pg = v_locale_parts[1]
                       AND territory = v_locale_parts[2];
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_lang_spec_culture := 'EN_US';

                    SELECT lang_data_jsonb
                      INTO v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
            END;
        ELSE
            v_is_cached := TRUE;
        END IF;
    END IF;

    IF (NOT v_is_cached) THEN
        PERFORM set_config(format('sys.lang_metadata_json.%s',
                                  v_lang_spec_culture),
                           v_lang_data_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_lang_data_jsonb;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE USING MESSAGE := pg_catalog.format('The language metadata JSON value extracted from chache is not a valid JSON object.',
                                      p_lang_spec_culture),
                    HINT := 'Drop the current session, fix the appropriate record in "sys.babelfish_syslanguages" table, and try again after reconnection.';

    WHEN OTHERS THEN
        RAISE USING MESSAGE := pg_catalog.format('"%s" is not a valid special culture or language name parameter.',
                                      p_lang_spec_culture),
                    DETAIL := 'Use of incorrect "lang_spec_culture" parameter value during conversion process.',
                    HINT := 'Change "lang_spec_culture" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_get_monthnum_by_name(IN p_monthname TEXT,
                                                                  IN p_lang_metadata_json JSONB)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_monthname TEXT;
    v_monthnum SMALLINT;
BEGIN
    v_monthname := pg_catalog.lower(trim(p_monthname));

    v_monthnum := array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_shortnames'))), v_monthname);

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_names'))), v_monthname));

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_extrashortnames'))), v_monthname));

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_extranames'))), v_monthname));

    IF (v_monthnum IS NULL) THEN
        RAISE datetime_field_overflow;
    END IF;

    RETURN v_monthnum;
EXCEPTION
    WHEN datetime_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Can not convert value "%s" to a correct month number.',
                                      trim(p_monthname)),
                    DETAIL := 'Supplied month name is not valid.',
                    HINT := 'Correct supplied month name value and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
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
    v_daypart VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_timeunit VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
BEGIN
    v_timepart := pg_catalog.upper(trim(p_timepart));
    v_timeunit := pg_catalog.upper(trim(p_timeunit));

    v_daypart := substring(v_timepart, 'AM|PM');
    v_timepart := trim(regexp_replace(v_timepart, coalesce(v_daypart, ''), ''));

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
    END IF;

    RETURN CASE v_timeunit
              WHEN 'HOURS' THEN v_hours
              WHEN 'MINUTES' THEN v_minutes
              WHEN 'SECONDS' THEN v_seconds
              WHEN 'FRACTSECONDS' THEN v_fractsecs
           END;
EXCEPTION
    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_weekdaynum_by_name(IN p_weekdayname TEXT,
                                                                    IN p_lang_metadata_json JSONB)
RETURNS SMALLINT
AS
$BODY$
DECLARE
    v_weekdayname TEXT;
    v_weekdaynum SMALLINT;
BEGIN
    v_weekdayname := pg_catalog.lower(trim(p_weekdayname));

    v_weekdaynum := array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_names'))), v_weekdayname);

    v_weekdaynum := coalesce(v_weekdaynum,
                             array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_shortnames'))), v_weekdayname));

    v_weekdaynum := coalesce(v_weekdaynum,
                             array_position(ARRAY(SELECT pg_catalog.lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_extrashortnames'))), v_weekdayname));

    IF (v_weekdaynum IS NULL) THEN
        RAISE datetime_field_overflow;
    END IF;

    RETURN v_weekdaynum;
EXCEPTION
    WHEN datetime_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Can not convert value "%s" to a correct weekday number.',
                                      trim(p_weekdayname)),
                    DETAIL := 'Supplied weekday name is not valid.',
                    HINT := 'Correct supplied weekday name value and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_time(IN p_datatype TEXT,
                                                           IN p_srctimestring TEXT,
                                                           IN p_culture TEXT DEFAULT '')
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_srctimestring VARCHAR COLLATE "C";
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR COLLATE "C";
    v_error_message VARCHAR COLLATE "C";
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_seconds VARCHAR COLLATE "C" := '0';
    v_fseconds VARCHAR COLLATE "C" := '0';
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_time TIME WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
BEGIN
    v_datatype := trim(p_datatype);
    v_srctimestring := pg_catalog.upper(trim(p_srctimestring));
    v_culture := coalesce(nullif(pg_catalog.upper(trim(p_culture)), ''), 'EN-US');

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    v_dayparts := ARRAY(SELECT pg_catalog.upper(array_to_string(regexp_matches(v_srctimestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_srctimestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_srctimestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_srctimestring := pg_catalog.replace(v_srctimestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_srctimestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_srctimestring := regexp_replace(v_srctimestring,
                                          ANNO_DOMINI_COMPREGEXP,
                                          regexp_replace(array_to_string(regexp_matches(v_srctimestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                         ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                          'gi');
    END IF;

    v_date_format := coalesce(nullif(pg_catalog.upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_srctimestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_srctimestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                     CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                     AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                     '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                     CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask1_fi_regexp
                                                                ELSE v_defmask1_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_srctimestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                      '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                      '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask6_fi_regexp
                                                                ELSE v_defmask6_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                      '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                      '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask2_fi_regexp
                                                                ELSE v_defmask2_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_srctimestring ~* v_defmask4_1_regexp OR
           (v_srctimestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_srctimestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                     '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_srctimestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_srctimestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_srctimestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_srctimestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                      TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask3_fi_regexp
                                                                ELSE v_defmask3_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                      '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_srctimestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                      MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                      '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask7_fi_regexp
                                                                ELSE v_defmask7_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                     MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                     TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                     '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                     TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                     '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask8_fi_regexp
                                                                ELSE v_defmask8_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_srctimestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_srctimestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                    WHEN 'FI' THEN v_resmask_fi
                                                                    ELSE v_resmask
                                                                 END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
	            v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (date_part('dow', v_res_date)::SMALLINT <> v_weekdaynum) THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');

        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_dayparts[1] = 'PM' AND v_hours < 12) THEN
                v_hours := v_hours + 12;
            ELSIF (v_dayparts[1] = 'AM' AND v_hours = 12) THEN
                v_hours := v_hours - 12;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), ''), '0');

            IF (v_seconds ~ '\.') THEN
                v_fseconds := split_part(v_seconds, '.', 2);
                v_seconds := split_part(v_seconds, '.', 1);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(rpad(v_fseconds, 9, '0'), v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    v_res_time := make_time(v_hours, v_minutes, v_seconds::NUMERIC);

    RETURN v_res_time;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_srctimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_date(IN p_datestring TEXT,
                                                           IN p_culture TEXT DEFAULT '')
RETURNS DATE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_seconds NUMERIC := 0;
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
BEGIN
    v_datestring := pg_catalog.upper(trim(p_datestring));
    v_culture := coalesce(nullif(pg_catalog.upper(trim(p_culture)), ''), 'EN-US');

    v_dayparts := ARRAY(SELECT pg_catalog.upper(array_to_string(regexp_matches(v_datestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_datestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_datestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_datestring := pg_catalog.replace(v_datestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_datestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_datestring := regexp_replace(v_datestring,
                                       ANNO_DOMINI_COMPREGEXP,
                                       regexp_replace(array_to_string(regexp_matches(v_datestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                      ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                       'gi');
    END IF;

    v_date_format := coalesce(nullif(pg_catalog.upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_datestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_datestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                  CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                  AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                  '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                  CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask1_fi_regexp
                                                             ELSE v_defmask1_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_datestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                   '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                   '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                   '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask6_fi_regexp
                                                             ELSE v_defmask6_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                   '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                   '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                   AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask2_fi_regexp
                                                             ELSE v_defmask2_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_datestring ~* v_defmask4_1_regexp OR
           (v_datestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_datestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                  '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_datestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_datestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_datestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                   TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask3_fi_regexp
                                                             ELSE v_defmask3_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                   '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_datestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                   MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                   '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask7_fi_regexp
                                                             ELSE v_defmask7_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                  MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                  TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                  '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                  TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                  '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask8_fi_regexp
                                                             ELSE v_defmask8_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_datestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_datestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_resmask_fi
                                                                 ELSE v_resmask
                                                              END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
	            v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), '')::NUMERIC, 0);
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    v_res_date := make_timestamp(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                 v_hours, v_minutes, v_seconds);

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (CASE date_part('dow', v_res_date)::SMALLINT
               WHEN 0 THEN 7
               ELSE date_part('dow', v_res_date)::SMALLINT
            END <> v_weekdaynum)
        THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    RETURN v_res_date;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type DATE using culture ''%s''.',
                                      p_datestring, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_datetime(IN p_datatype TEXT,
                                                               IN p_datetimestring TEXT,
                                                               IN p_culture TEXT DEFAULT '')
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR COLLATE "C";
    v_error_message VARCHAR COLLATE "C";
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_datetimestring VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C" := '0';
    v_fseconds VARCHAR COLLATE "C" := '0';
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_datetime TIMESTAMP(6) WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := pg_catalog.upper(trim(p_datetimestring));
    v_culture := coalesce(nullif(pg_catalog.upper(trim(p_culture)), ''), 'EN-US');

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    v_dayparts := ARRAY(SELECT pg_catalog.upper(array_to_string(regexp_matches(v_datetimestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_datetimestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_datetimestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_datetimestring := pg_catalog.replace(v_datetimestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_datetimestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_datetimestring := regexp_replace(v_datetimestring,
                                           ANNO_DOMINI_COMPREGEXP,
                                           regexp_replace(array_to_string(regexp_matches(v_datetimestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                          ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                           'gi');
    END IF;

    v_date_format := coalesce(nullif(pg_catalog.upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_datetimestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_datetimestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                      AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask1_fi_regexp
                                                                 ELSE v_defmask1_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_datetimestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                       '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                       '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                       '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask6_fi_regexp
                                                                 ELSE v_defmask6_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                       '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                       '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                       AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask2_fi_regexp
                                                                 ELSE v_defmask2_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_datetimestring ~* v_defmask4_1_regexp OR
           (v_datetimestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_datetimestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                      '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datetimestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_datetimestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_datetimestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_datetimestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                       TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask3_fi_regexp
                                                                 ELSE v_defmask3_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                       '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_datetimestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                       MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                       '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask7_fi_regexp
                                                                 ELSE v_defmask7_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                      MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask8_fi_regexp
                                                                 ELSE v_defmask8_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_datetimestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_datetimestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                     WHEN 'FI' THEN v_resmask_fi
                                                                     ELSE v_resmask
                                                                  END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
	            v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_dayparts[1] = 'PM' AND v_hours < 12) THEN
                v_hours := v_hours + 12;
            ELSIF (v_dayparts[1] = 'AM' AND v_hours = 12) THEN
                v_hours := v_hours - 12;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), ''), '0');

            IF (v_seconds ~ '\.') THEN
                v_fseconds := split_part(v_seconds, '.', 2);
                v_seconds := split_part(v_seconds, '.', 1);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    BEGIN
        IF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_res_datetime := sys.datetimefromparts(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                                                  v_hours, v_minutes, v_seconds::SMALLINT,
                                                                  rpad(v_fseconds, 3, '0')::NUMERIC);
            IF (v_res_datatype = 'SMALLDATETIME' AND
                to_char(v_res_datetime, 'SS') <> '00')
            THEN
                IF (to_char(v_res_datetime, 'SS')::SMALLINT >= 30) THEN
                    v_res_datetime := v_res_datetime + INTERVAL '1 minute';
                END IF;

                v_res_datetime := to_timestamp(to_char(v_res_datetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSE
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(rpad(v_fseconds, 9, '0'), v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);

            v_res_datetime := make_timestamp(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                             v_hours, v_minutes, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_datetime_format;
        END IF;
    END;

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (CASE date_part('dow', v_res_date)::SMALLINT
               WHEN 0 THEN 7
               ELSE date_part('dow', v_res_date)::SMALLINT
            END <> v_weekdaynum)
        THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    RETURN v_res_datetime;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_datetimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

-- Update deprecated object_id function(s) since upper and lower functions now changes return type for TEXT input
DO $$
BEGIN
    -- Update body of object_id_deprecated_in_2_4_0 to use PG_CATALOG.UPPER and PG_CATALOG.LOWER instead, if function exists
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
            is_temp_object = left(obj_name, 1) = '#' collate sys.database_default;

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
                    when pg_catalog.upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                    id := (select reloid from sys.babelfish_get_enr_list() where pg_catalog.lower(relname) collate sys.database_default = obj_name limit 1);

                    when pg_catalog.upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                    id := (select oid from pg_class where pg_catalog.lower(relname) collate sys.database_default = obj_name 
                                and relnamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                    id := (select oid from pg_constraint where pg_catalog.lower(conname) collate sys.database_default = obj_name 
                                and connamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                    id := (select oid from pg_proc where pg_catalog.lower(proname) collate sys.database_default = obj_name 
                                and pronamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('TR', 'TA') then
                    id := (select oid from pg_trigger where pg_catalog.lower(tgname) collate sys.database_default = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when pg_catalog.upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported obj_type
                    else id := null;
                end case;
            else
                if not is_temp_object then 
                    id := (
                        select oid from pg_class where pg_catalog.lower(relname) = obj_name
                            and relnamespace = schema_oid
                        union
                        select oid from pg_constraint where pg_catalog.lower(conname) = obj_name
                            and connamespace = schema_oid
                        union
                        select oid from pg_proc where pg_catalog.lower(proname) = obj_name
                            and pronamespace = schema_oid
                        union
                        select oid from pg_trigger where pg_catalog.lower(tgname) = obj_name
                        limit 1
                    );
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where pg_catalog.lower(relname) collate sys.database_default = obj_name limit 1);
                end if;
            end if;

            RETURN id::integer;
        END;
        $BODY$
        LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;
    END IF;
    
    -- Update body of object_id_deprecated_in_3_1_0 to use PG_CATALOG.UPPER and PG_CATALOG.LOWER instead, if function exists
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
            is_temp_object = left(obj_name, 1) = '#' collate sys.database_default;

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
                    when pg_catalog.upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                    id := (select reloid from sys.babelfish_get_enr_list() where pg_catalog.lower(relname) collate sys.database_default = obj_name limit 1);

                    when pg_catalog.upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                    id := (select oid from pg_class where pg_catalog.lower(relname) collate sys.database_default = obj_name 
                                and relnamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                    id := (select oid from pg_constraint where pg_catalog.lower(conname) collate sys.database_default = obj_name 
                                and connamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                    id := (select oid from pg_proc where pg_catalog.lower(proname) collate sys.database_default = obj_name 
                                and pronamespace = schema_oid limit 1);

                    when pg_catalog.upper(object_type) in ('TR', 'TA') then
                    id := (select oid from pg_trigger where pg_catalog.lower(tgname) collate sys.database_default = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when pg_catalog.upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported obj_type
                    else id := null;
                end case;
            else
                if not is_temp_object then 
                    id := (
                        select oid from pg_class where pg_catalog.lower(relname) = obj_name
                            and relnamespace = schema_oid
                        union
                        select oid from pg_constraint where pg_catalog.lower(conname) = obj_name
                            and connamespace = schema_oid
                        union
                        select oid from pg_proc where pg_catalog.lower(proname) = obj_name
                            and pronamespace = schema_oid
                        union
                        select oid from pg_trigger where pg_catalog.lower(tgname) = obj_name
                        limit 1
                    );
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where pg_catalog.lower(relname) collate sys.database_default = obj_name limit 1);
                end if;
            end if;

            RETURN id::integer;
        END;
        $BODY$
        LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;
    END IF;
END;
$$;

-- wrapper functions for upper --
-- Function to handle datatypes which are implicitly convertable to VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    type_oid oid;
    typ_base_oid oid;
    typnam text;
BEGIN
    typnam := NULL;
    type_oid := pg_typeof($1);
    typnam := sys.translate_pg_type_to_tsql(type_oid);
    IF typnam IS NULL THEN
        typ_base_oid := (SELECT typbasetype FROM pg_type WHERE oid = type_oid);
        typnam := sys.translate_pg_type_to_tsql(typ_base_oid);
    END IF;
    IF typnam IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of upper function.', typnam;
    END IF;
    IF $1 IS NULL THEN
        RETURN NULL;
    END IF;
    -- Call the underlying function after preprocessing
    RETURN pg_catalog.upper($1::sys.varchar);
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.upper(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle TEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(TEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NTEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.upper(NTEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.upper($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- wrapper functions for lower --
-- Function to handle datatypes which are implicitly convertable to VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(ANYELEMENT)
RETURNS sys.VARCHAR
AS $$
DECLARE
    type_oid oid;
    typ_base_oid oid;
    typnam text;
BEGIN
    typnam := NULL;
    type_oid := pg_typeof($1);
    typnam := sys.translate_pg_type_to_tsql(type_oid);
    IF typnam IS NULL THEN
        typ_base_oid := (SELECT typbasetype FROM pg_type WHERE oid = type_oid);
        typnam := sys.translate_pg_type_to_tsql(typ_base_oid);
    END IF;
    IF typnam IN ('image', 'sql_variant', 'xml', 'geometry', 'geography') THEN
        RAISE EXCEPTION 'Argument data type % is invalid for argument 1 of upper function.', typnam;
    END IF;
    IF $1 IS NULL THEN
        RETURN NULL;
    END IF;
    -- Call the underlying function after preprocessing
    RETURN pg_catalog.lower($1::sys.varchar);
END;
$$ LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

-- Function to handle NCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NVARCHAR because of return type NVARCHAR
CREATE OR REPLACE FUNCTION sys.lower(sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle TEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(TEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Function to handle NTEXT because of return type VARCHAR
CREATE OR REPLACE FUNCTION sys.lower(NTEXT)
RETURNS sys.VARCHAR
AS $$
BEGIN
    RETURN pg_catalog.lower($1);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
