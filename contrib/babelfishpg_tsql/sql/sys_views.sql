/* Tsql system catalog views */

/*
 * Note: this view, although written efficiently might cause perfomance degradation when
 * joined with other system objects. One should try to use them as part of a materialized CTE.
 */
create or replace view sys.table_types_internal as
SELECT pt.typrelid
    FROM pg_catalog.pg_type pt
    INNER join sys.schemas sch on pt.typnamespace = sch.schema_id
    INNER JOIN pg_catalog.pg_depend dep ON pt.typrelid = dep.objid
    INNER JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i'  AND pc.relkind = 'r';

create or replace view sys.tables as
select
  CAST(t.relname as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(t.relnamespace  as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as CHAR(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , CAST(NULL as int) as filestream_data_space_id
  , CAST(relnatts as int) as max_column_id_used
  , CAST(0 as sys.bit) as lock_on_bulk_load
  , CAST(1 as sys.bit) as uses_ansi_nulls
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as has_replication_filter
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_sync_tran_subscribed
  , CAST(0 as sys.bit) as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , CAST(0 as sys.bit) as large_value_types_out_of_row
  , CAST(0 as sys.bit) as is_tracked_by_cdc
  , CAST(0 as sys.tinyint) as lock_escalation
  , CAST('TABLE' as sys.nvarchar(60)) as lock_escalation_desc
  , CAST(0 as sys.bit) as is_filetable
  , CAST(0 as sys.tinyint) as durability
  , CAST('SCHEMA_AND_DATA' as sys.nvarchar(60)) as durability_desc
  , CAST(0 as sys.bit) is_memory_optimized
  , case relpersistence when 't' then CAST(2 as sys.tinyint) else CAST(0 as sys.tinyint) end as temporal_type
  , case relpersistence when 't' then CAST('SYSTEM_VERSIONED_TEMPORAL_TABLE' as sys.nvarchar(60)) else CAST('NON_TEMPORAL_TABLE' as sys.nvarchar(60)) end as temporal_type_desc
  , CAST(null as integer) as history_table_id
  , CAST(0 as sys.bit) as is_remote_data_archive_enabled
  , CAST(0 as sys.bit) as is_external
from pg_class t 
where t.relnamespace in (select schema_id from sys.schemas)
and t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and t.oid not in (select typrelid from sys.table_types_internal)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;

create or replace view sys.views as 
select 
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type 
  , 'VIEW'::varchar(60) as type_desc
  , vd.create_date::timestamp as create_date
  , vd.create_date::timestamp as modify_date
  , 0 as is_ms_shipped 
  , 0 as is_published 
  , 0 as is_schema_published 
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id 
left outer join sys.babelfish_view_def vd on t.relname::sys.sysname = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id() 
where t.relkind = 'v'
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
	scale INT;
BEGIN
	IF type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE type
		WHEN 'date' THEN scale = 0;
		WHEN 'datetime' THEN scale = 3;
		WHEN 'smalldatetime' THEN scale = 0;
		WHEN 'datetime2' THEN scale = 6;
		WHEN 'datetimeoffset' THEN scale = 6;
		WHEN 'decimal' THEN scale = 38;
		WHEN 'numeric' THEN scale = 38;
		WHEN 'money' THEN scale = 4;
		WHEN 'smallmoney' THEN scale = 4;
		WHEN 'time' THEN scale = 6;
		WHEN 'tinyint' THEN scale = 0;
		ELSE
			IF return_null_for_rest
				THEN scale = NULL;
			ELSE scale = 0;
			END IF;
		END CASE;
		RETURN scale;
	END IF;

	CASE type 
	WHEN 'decimal' THEN scale = (typemod - 4) & 65535;
	WHEN 'numeric' THEN scale = (typemod - 4) & 65535;
	WHEN 'smalldatetime' THEN scale = 0;
	WHEN 'datetime2' THEN
		CASE typemod 
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	ELSE
		IF return_null_for_rest
			THEN scale = NULL;
		ELSE scale = 0;
		END IF;
	END CASE;
	RETURN scale;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_precision_helper(IN type TEXT, IN typemod INT) RETURNS sys.TINYINT
AS $$
DECLARE
	precision INT;
BEGIN
	IF type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE type
		WHEN 'bigint' THEN precision = 19;
		WHEN 'bit' THEN precision = 1;
		WHEN 'date' THEN precision = 10;
		WHEN 'datetime' THEN precision = 23;
		WHEN 'datetime2' THEN precision = 26;
		WHEN 'datetimeoffset' THEN precision = 33;
		WHEN 'decimal' THEN precision = 38;
		WHEN 'numeric' THEN precision = 38;
		WHEN 'float' THEN precision = 53;
		WHEN 'int' THEN precision = 10;
		WHEN 'money' THEN precision = 19;
		WHEN 'real' THEN precision = 24;
		WHEN 'smalldatetime' THEN precision = 16;
		WHEN 'smallint' THEN precision = 5;
		WHEN 'smallmoney' THEN precision = 10;
		WHEN 'time' THEN precision = 15;
		WHEN 'tinyint' THEN precision = 3;
		ELSE precision = 0;
		END CASE;
		RETURN precision;
	END IF;

	CASE type
	WHEN 'numeric' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'decimal' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'smalldatetime' THEN precision = 16;
	WHEN 'datetime2' THEN 
		CASE typemod 
		WHEN 0 THEN precision = 19;
		WHEN 1 THEN precision = 21;
		WHEN 2 THEN precision = 22;
		WHEN 3 THEN precision = 23;
		WHEN 4 THEN precision = 24;
		WHEN 5 THEN precision = 25;
		WHEN 6 THEN precision = 26;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 27;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN precision = 26;
		WHEN 1 THEN precision = 28;
		WHEN 2 THEN precision = 29;
		WHEN 3 THEN precision = 30;
		WHEN 4 THEN precision = 31;
		WHEN 5 THEN precision = 32;
		WHEN 6 THEN precision = 33;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN precision = 34;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN precision = 8;
		WHEN 1 THEN precision = 10;
		WHEN 2 THEN precision = 11;
		WHEN 3 THEN precision = 12;
		WHEN 4 THEN precision = 13;
		WHEN 5 THEN precision = 14;
		WHEN 6 THEN precision = 15;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 16;
		END CASE;
	ELSE precision = 0;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION sys.tsql_type_max_length_helper(IN type TEXT, IN typelen INT, IN typemod INT, IN for_sys_types boolean DEFAULT false, IN used_typmod_array boolean DEFAULT false)
RETURNS SMALLINT
AS $$
DECLARE
	max_length SMALLINT;
	precision INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	-- unknown tsql type
	IF v_type IS NULL THEN
		RETURN CAST(typelen as SMALLINT);
	END IF;

	-- if using typmod_array from pg_proc.probin
	IF used_typmod_array THEN
		IF v_type = 'sysname' THEN
			RETURN 256;
		ELSIF (v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary', 'nchar', 'nvarchar'))
		THEN
			IF typemod < 0 THEN -- max value. 
				RETURN -1;
			ELSIF v_type in ('nchar', 'nvarchar') THEN
				RETURN (2 * typemod);
			ELSE
				RETURN typemod;
			END IF;
		END IF;
	END IF;

	IF typelen != -1 THEN
		CASE v_type 
		WHEN 'tinyint' THEN max_length = 1;
		WHEN 'date' THEN max_length = 3;
		WHEN 'smalldatetime' THEN max_length = 4;
		WHEN 'smallmoney' THEN max_length = 4;
		WHEN 'datetime2' THEN
			IF typemod = -1 THEN max_length = 8;
			ELSIF typemod <= 2 THEN max_length = 6;
			ELSIF typemod <= 4 THEN max_length = 7;
			ELSEIF typemod <= 7 THEN max_length = 8;
			-- typemod = 7 is not possible for datetime2 in Babel
			END IF;
		WHEN 'datetimeoffset' THEN
			IF typemod = -1 THEN max_length = 10;
			ELSIF typemod <= 2 THEN max_length = 8;
			ELSIF typemod <= 4 THEN max_length = 9;
			ELSIF typemod <= 7 THEN max_length = 10;
			-- typemod = 7 is not possible for datetimeoffset in Babel
			END IF;
		WHEN 'time' THEN
			IF typemod = -1 THEN max_length = 5;
			ELSIF typemod <= 2 THEN max_length = 3;
			ELSIF typemod <= 4 THEN max_length = 4;
			ELSIF typemod <= 7 THEN max_length = 5;
			END IF;
		WHEN 'timestamp' THEN max_length = 8;
		ELSE max_length = typelen;
		END CASE;
		RETURN max_length;
	END IF;

	IF typemod = -1 THEN
		CASE 
		WHEN v_type in ('image', 'text', 'ntext') THEN max_length = 16;
		WHEN v_type = 'sql_variant' THEN max_length = 8016;
		WHEN v_type in ('varbinary', 'varchar', 'nvarchar') THEN 
			IF for_sys_types THEN max_length = 8000;
			ELSE max_length = -1;
			END IF;
		WHEN v_type in ('binary', 'char', 'bpchar', 'nchar') THEN max_length = 8000;
		WHEN v_type in ('decimal', 'numeric') THEN max_length = 17;
		ELSE max_length = typemod;
		END CASE;
		RETURN max_length;
	END IF;

	CASE
	WHEN v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN max_length = typemod - 4;
	WHEN v_type in ('nchar', 'nvarchar') THEN max_length = (typemod - 4) * 2;
	WHEN v_type = 'sysname' THEN max_length = (typemod - 4) * 2;
	WHEN v_type in ('numeric', 'decimal') THEN
		precision = ((typemod - 4) >> 16) & 65535;
		IF precision >= 1 and precision <= 9 THEN max_length = 5;
		ELSIF precision <= 19 THEN max_length = 9;
		ELSIF precision <= 28 THEN max_length = 13;
		ELSIF precision <= 38 THEN max_length = 17;
	ELSE max_length = typelen;
	END IF;
	ELSE
		max_length = typemod;
	END CASE;
	RETURN max_length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else 
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else 
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit) as is_identity
  , CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

-- internal function in order to workaround BABEL-1597
CREATE OR REPLACE FUNCTION sys.columns_internal()
RETURNS TABLE (
    out_object_id int,
    out_name sys.sysname,
    out_column_id int,
    out_system_type_id int,
    out_user_type_id int,
    out_max_length smallint,
    out_precision sys.tinyint,
    out_scale sys.tinyint,
    out_collation_name sys.sysname,
    out_collation_id int,
    out_offset smallint,
    out_is_nullable sys.bit,
    out_is_ansi_padded sys.bit,
    out_is_rowguidcol sys.bit,
    out_is_identity sys.bit,
    out_is_computed sys.bit,
    out_is_filestream sys.bit,
    out_is_replicated sys.bit,
    out_is_non_sql_subscribed sys.bit,
    out_is_merge_published sys.bit,
    out_is_dts_replicated sys.bit,
    out_is_xml_document sys.bit,
    out_xml_collection_id int,
    out_default_object_id int,
    out_rule_object_id int,
    out_is_sparse sys.bit,
    out_is_column_set sys.bit,
    out_generated_always_type sys.tinyint,
    out_generated_always_type_desc sys.nvarchar(60),
    out_encryption_type int,
    out_encryption_type_desc sys.nvarchar(64),
    out_encryption_algorithm_name sys.sysname,
    out_column_encryption_key_id int,
    out_column_encryption_key_database_name sys.sysname,
    out_is_hidden sys.bit,
    out_is_masked sys.bit,
    out_graph_type int,
    out_graph_type_desc sys.nvarchar(60)
)
AS
$$
BEGIN
	RETURN QUERY
		SELECT CAST(c.oid AS int),
			CAST(a.attname AS sys.sysname),
			CAST(a.attnum AS int),
			CASE 
			WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
				-- either tsql or PG base type 
				CAST(a.atttypid AS int)
			ELSE 
				CAST(t.typbasetype AS int)
			END,
			CAST(a.atttypid AS int),
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
			ELSE 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
			ELSE 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
			ELSE 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
			END,
			CAST(coll.collname AS sys.sysname),
			CAST(a.attcollation AS int),
			CAST(a.attnum AS smallint),
			CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
			CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit),
			CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS int),
			CAST(coalesce(d.oid, 0) AS int),
			CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
						and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.tinyint),
			CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(64)),
			CAST(null AS sys.sysname),
			CAST(null AS int),
			CAST(null AS sys.sysname),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(60))
		FROM pg_attribute a
		INNER JOIN pg_class c ON c.oid = a.attrelid
		INNER JOIN pg_type t ON t.oid = a.atttypid
		INNER JOIN sys.schemas sch on c.relnamespace = sch.schema_id 
		INNER JOIN sys.pg_namespace_ext ext on sch.schema_id = ext.oid 
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
		, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
		WHERE NOT a.attisdropped
		AND a.attnum > 0
		-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
		AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
		AND has_schema_privilege(sch.schema_id, 'USAGE')
		AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
		union all
		-- system tables information
		SELECT CAST(c.oid AS int),
			CAST(a.attname AS sys.sysname),
			CAST(a.attnum AS int),
			CASE 
			WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
				-- either tsql or PG base type 
				CAST(a.atttypid AS int)
			ELSE 
				CAST(t.typbasetype AS int)
			END,
			CAST(a.atttypid AS int),
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
			ELSE 
				sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
			ELSE 
				sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
			END,
			CASE
			WHEN a.atttypmod != -1 THEN 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
			ELSE 
				sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
			END,
			CAST(coll.collname AS sys.sysname),
			CAST(a.attcollation AS int),
			CAST(a.attnum AS smallint),
			CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
			CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit),
			CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS int),
			CAST(coalesce(d.oid, 0) AS int),
			CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
						and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.tinyint),
			CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(64)),
			CAST(null AS sys.sysname),
			CAST(null AS int),
			CAST(null AS sys.sysname),
			CAST(0 AS sys.bit),
			CAST(0 AS sys.bit),
			CAST(null AS int),
			CAST(null AS sys.nvarchar(60))
		FROM pg_attribute a
		INNER JOIN pg_class c ON c.oid = a.attrelid
		INNER JOIN pg_type t ON t.oid = a.atttypid
		INNER JOIN pg_namespace nsp ON (nsp.oid = c.relnamespace and nsp.nspname = 'sys')
		LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
		LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
		, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
		, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
		WHERE NOT a.attisdropped
		AND a.attnum > 0
		AND c.relkind = 'r'
		AND has_schema_privilege(nsp.oid, 'USAGE')
		AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
END;
$$
language plpgsql STABLE;

create or replace view sys.columns AS
select out_object_id as object_id
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
from sys.columns_internal();
GRANT SELECT ON sys.columns TO PUBLIC;

CREATE OR replace view sys.foreign_key_columns as
SELECT DISTINCT
  CAST(c.oid AS INT) AS constraint_object_id
  ,CAST((generate_series(1,ARRAY_LENGTH(c.conkey,1))) AS INT) AS constraint_column_id
  ,CAST(c.conrelid AS INT) AS parent_object_id
  ,CAST((UNNEST (c.conkey)) AS INT) AS parent_column_id
  ,CAST(c.confrelid AS INT) AS referenced_object_id
  ,CAST((UNNEST(c.confkey)) AS INT) AS referenced_column_id
FROM pg_constraint c
WHERE c.contype = 'f'
AND (c.connamespace IN (SELECT schema_id FROM sys.schemas))
AND has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.foreign_key_columns TO PUBLIC;

CREATE OR replace view sys.foreign_keys AS
SELECT
  CAST(c.conname AS sys.SYSNAME) AS name
, CAST(c.oid AS INT) AS object_id
, CAST(NULL AS INT) AS principal_id
, CAST(sch.schema_id AS INT) AS schema_id
, CAST(c.conrelid AS INT) AS parent_object_id
, CAST('F' AS CHAR(2)) AS type
, CAST('FOREIGN_KEY_CONSTRAINT' AS NVARCHAR(60)) AS type_desc
, CAST(NULL AS sys.DATETIME) AS create_date
, CAST(NULL AS sys.DATETIME) AS modify_date
, CAST(0 AS sys.BIT) AS is_ms_shipped
, CAST(0 AS sys.BIT) AS is_published
, CAST(0 AS sys.BIT) as is_schema_published
, CAST(c.confrelid AS INT) AS referenced_object_id
, CAST(c.conindid AS INT) AS key_index_id
, CAST(0 AS sys.BIT) AS is_disabled
, CAST(0 AS sys.BIT) AS is_not_for_replication
, CAST(0 AS sys.BIT) AS is_not_trusted
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END) 
    AS sys.TINYINT) AS delete_referential_action
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END) 
    AS sys.NVARCHAR(60)) AS delete_referential_action_desc
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS update_referential_action
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) update_referential_action_desc
, CAST(1 AS sys.BIT) AS is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

CREATE OR replace view sys.identity_columns AS
SELECT 
  CAST(out_object_id AS INT) AS object_id
  , CAST(out_name AS SYSNAME) AS name
  , CAST(out_column_id AS INT) AS column_id
  , CAST(out_system_type_id AS TINYINT) AS system_type_id
  , CAST(out_user_type_id AS INT) AS user_type_id
  , CAST(out_max_length AS SMALLINT) AS max_length
  , CAST(out_precision AS TINYINT) AS precision
  , CAST(out_scale AS TINYINT) AS scale
  , CAST(out_collation_name AS SYSNAME) AS collation_name
  , CAST(out_is_nullable AS sys.BIT) AS is_nullable
  , CAST(out_is_ansi_padded AS sys.BIT) AS is_ansi_padded
  , CAST(out_is_rowguidcol AS sys.BIT) AS is_rowguidcol
  , CAST(out_is_identity AS sys.BIT) AS is_identity
  , CAST(out_is_computed AS sys.BIT) AS is_computed
  , CAST(out_is_filestream AS sys.BIT) AS is_filestream
  , CAST(out_is_replicated AS sys.BIT) AS is_replicated
  , CAST(out_is_non_sql_subscribed AS sys.BIT) AS is_non_sql_subscribed
  , CAST(out_is_merge_published AS sys.BIT) AS is_merge_published
  , CAST(out_is_dts_replicated AS sys.BIT) AS is_dts_replicated
  , CAST(out_is_xml_document AS sys.BIT) AS is_xml_document
  , CAST(out_xml_collection_id AS INT) AS xml_collection_id
  , CAST(out_default_object_id AS INT) AS default_object_id
  , CAST(out_rule_object_id AS INT) AS rule_object_id
  , CAST(out_is_sparse AS sys.BIT) AS is_sparse
  , CAST(out_is_column_set AS sys.BIT) AS is_column_set
  , CAST(out_generated_always_type AS TINYINT) AS generated_always_type
  , CAST(out_generated_always_type_desc AS NVARCHAR(60)) AS generated_always_type_desc
  , CAST(out_encryption_type AS INT) AS encryption_type
  , CAST(out_encryption_type_desc AS NVARCHAR(60)) AS encryption_type_desc
  , CAST(out_encryption_algorithm_name AS SYSNAME) AS encryption_algorithm_name
  , CAST(out_column_encryption_key_id AS INT) column_encryption_key_id
  , CAST(out_column_encryption_key_database_name AS SYSNAME) AS column_encryption_key_database_name
  , CAST(out_is_hidden AS sys.BIT) AS is_hidden
  , CAST(out_is_masked AS sys.BIT) AS is_masked
  , CAST(sys.ident_seed(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS seed_value
  , CAST(sys.ident_incr(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS increment_value
  , CAST(sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) AS SQL_VARIANT) AS last_value
  , CAST(0 as sys.BIT) as is_not_for_replication
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = cast(a.attname as sys.sysname) AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

create or replace view sys.indexes as
select 
  CAST(object_id as int)
  , CAST(name as sys.sysname)
  , CAST(type as sys.tinyint)
  , CAST(type_desc as sys.nvarchar(60))
  , CAST(is_unique as sys.bit)
  , CAST(data_space_id as int)
  , CAST(ignore_dup_key as sys.bit)
  , CAST(is_primary_key as sys.bit)
  , CAST(is_unique_constraint as sys.bit)
  , CAST(fill_factor as sys.tinyint)
  , CAST(is_padded as sys.bit)
  , CAST(is_disabled as sys.bit)
  , CAST(is_hypothetical as sys.bit)
  , CAST(allow_row_locks as sys.bit)
  , CAST(allow_page_locks as sys.bit)
  , CAST(has_filter as sys.bit)
  , CAST(filter_definition as sys.nvarchar)
  , CAST(auto_created as sys.bit)
  , CAST(index_id as int)
from 
(
  -- Get all indexes from all system and user tables
  select
    X.indrelid as object_id
    , I.relname as name
    , case when X.indisclustered then 1 else 2 end as type
    , case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as type_desc
    , case when X.indisunique then 1 else 0 end as is_unique
    , I.reltablespace as data_space_id
    , 0 as ignore_dup_key
    , case when X.indisprimary then 1 else 0 end as is_primary_key
    , case when const.oid is null then 0 else 1 end as is_unique_constraint
    , 0 as fill_factor
    , case when X.indpred is null then 0 else 1 end as is_padded
    , case when X.indisready then 0 else 1 end as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , case when X.indisclustered then 1 else 1+row_number() over(partition by C.oid) end as index_id -- use rownumber to get index_id scoped on each objects
  from (pg_index X 
  -- get all the objects on which indexes can be created
  join pg_class C on C.oid=X.indrelid and C.relkind in ('r', 'm', 'p')
  -- get list of all indexes grouped by objects
  cross join pg_class I  
  )
  -- to get namespace information
  left join sys.schemas sch on I.relnamespace = sch.schema_id
  -- check if index is a unique constraint
  left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
  where has_schema_privilege(I.relnamespace, 'USAGE')
  and I.oid = X.indexrelid 
  and I.relkind = 'i' 
  -- index is active
  and X.indislive 
  -- filter to get all the objects that belong to sys or babelfish schemas
  and (sch.schema_id is not null or I.relnamespace::regnamespace::text = 'sys')

  union all 
  
-- Create HEAP entries for each system and user table
  select distinct on (t.oid)
    t.oid as object_id
    , null as name
    , 0 as type
    , 'HEAP' as type_desc
    , 0 as is_unique
    , 1 as data_space_id
    , 0 as ignore_dup_key
    , 0 as is_primary_key
    , 0 as is_unique_constraint
    , 0 as fill_factor
    , 0 as is_padded
    , 0 as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , 0 as index_id
  from pg_class t
  left join sys.schemas sch on t.relnamespace = sch.schema_id
  where t.relkind = 'r'
  -- filter to get all the objects that belong to sys or babelfish schemas
  and (sch.schema_id is not null or t.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(t.relnamespace, 'USAGE')
  and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

) as indexes_select order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

CREATE OR replace view sys.key_constraints AS
SELECT
    CAST(c.conname AS SYSNAME) AS name
  , CAST(c.oid AS INT) AS object_id
  , CAST(0 AS INT) AS principal_id
  , CAST(sch.schema_id AS INT) AS schema_id
  , CAST(c.conrelid AS INT) AS parent_object_id
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PK'
      WHEN 'u' THEN 'UQ'
    END) 
    AS CHAR(2)) AS type
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PRIMARY_KEY_CONSTRAINT'
      WHEN 'u' THEN 'UNIQUE_CONSTRAINT'
    END)
    AS NVARCHAR(60)) AS type_desc
  , CAST(NULL AS DATETIME) AS create_date
  , CAST(NULL AS DATETIME) AS modify_date
  , CAST(c.conindid AS INT) AS unique_index_id
  , CAST(0 AS sys.BIT) AS is_ms_shipped
  , CAST(0 AS sys.BIT) AS is_published
  , CAST(0 AS sys.BIT) AS is_schema_published
  , CAST(1 as sys.BIT) as is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype IN ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;

create or replace view sys.procedures as
select
  cast(p.proname as sys.sysname) as name
  , cast(p.oid as int) as object_id
  , cast(null as int) as principal_id
  , cast(sch.schema_id as int) as schema_id
  , cast (0 as int) as parent_object_id
  , cast(case p.prokind
      when 'p' then 'P'
      when 'a' then 'AF'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'
          else 'FN'
        end
    end as sys.bpchar(2)) COLLATE sys.database_default as type
  , cast(case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'
      when 'a' then 'AGGREGATE_FUNCTION'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'
          else 'SQL_SCALAR_FUNCTION'
        end
    end as sys.nvarchar(60)) as type_desc
  , cast(f.create_date as sys.datetime) as create_date
  , cast(f.create_date as sys.datetime) as modify_date
  , cast(0 as sys.bit) as is_ms_shipped
  , cast(0 as sys.bit) as is_published
  , cast(0 as sys.bit) as is_schema_published
  , cast(0 as sys.bit) as is_auto_executed
  , cast(0 as sys.bit) as is_execution_replicated
  , cast(0 as sys.bit) as is_repl_serializable_only
  , cast(0 as sys.bit) as skips_repl_constraints
from pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and format_type(p.prorettype, null) <> 'trigger'
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

create or replace view sys.sysforeignkeys as
select
  c.conname as name
  , c.oid as object_id
  , c.conrelid as fkeyid
  , c.confrelid as rkeyid
  , a_con.attnum as fkey
  , a_conf.attnum as rkey
  , a_conf.attnum as keyno
from pg_constraint c
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f'
and (c.connamespace in (select schema_id from sys.schemas))
and has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.sysforeignkeys TO PUBLIC;

create or replace view  sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.index_id::smallint as indid
  , null::binary(6) as root
  , 0::smallint as minlen
  , 1::smallint as keycnt
  , null::smallint as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0::bigint as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0::smallint as xmaxlen
  , null::smallint as maxirow
  , 90::sys.tinyint as "OrigFillFactor"
  , 0::sys.tinyint as "StatVersion"
  , 0 as reserved2
  , null::binary(6) as "FirstIAM"
  , 0::smallint as impid
  , 0::smallint as lockflags
  , 0 as pgmodctr
  , null::sys.varbinary(816) as keys
  , i.name::sys.sysname as name
  , null::sys.image as statblob
  , 0 as maxlen
  , 0 as rows
from sys.indexes i;
GRANT SELECT ON sys.sysindexes TO PUBLIC;

create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , a.state as status
  , null::bytea as sid
  , CAST(t.host_name AS sys.nchar(128)) as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , t.context_info::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database(); /* current physical database will always be babelfish database */
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

create or replace view sys.types As
with RECURSIVE type_code_list as
(
    select distinct  pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
),
tt_internal as MATERIALIZED
(
  Select * from sys.table_types_internal
)
-- For System types
select 
  ti.tsql_type_name as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(ti.tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , cast(sys.tsql_type_precision_helper(ti.tsql_type_name, t.typtypmod) as int) as precision
  , cast(sys.tsql_type_scale_helper(ti.tsql_type_name, t.typtypmod, false) as int) as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE  c.collname
    END as collation_name
  , case when typnotnull then 0 else 1 end as is_nullable
  , 0 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , 0 as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
inner join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
,cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
where
ti.tsql_type_name IS NOT NULL  
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as text) as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , t.typnamespace as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE  c.collname 
    END as collation_name
  , case when tt.typrelid is not null then 0
         else case when typnotnull then 0 else 1 end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , 1 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , case when tt.typrelid is not null then 1 else 0 end as is_table_type
from pg_type t
join sys.schemas sch on t.typnamespace = sch.schema_id
left join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
left join tt_internal tt on t.typrelid = tt.typrelid
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
, cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
-- we want to show details of user defined datatypes created under babelfish database
where 
 ti.tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    tt.typrelid is not null  
  );
GRANT SELECT ON sys.types TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.systypes_precision_helper(IN type TEXT, IN max_length SMALLINT)
RETURNS SMALLINT
AS $$
DECLARE
	precision SMALLINT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	CASE
	WHEN v_type in ('text', 'ntext', 'image') THEN precision = CAST(NULL AS SMALLINT);
	WHEN v_type in ('nchar', 'nvarchar', 'sysname') THEN precision = max_length/2;
	WHEN v_type = 'sql_variant' THEN precision = 0;
	ELSE
		precision = max_length;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE VIEW sys.systypes AS
SELECT CAST(name as sys.sysname) as name
  , CAST(system_type_id as int) as xtype
  , CAST((case when is_nullable = 1 then 0 else 1 end) as sys.tinyint) as status
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as xusertype
  , max_length as length
  , CAST(precision as sys.tinyint) as xprec
  , CAST(scale as sys.tinyint) as xscale
  , CAST(default_object_id as int) as tdefault
  , CAST(rule_object_id as int) as domain
  , CAST((case when schema_id < 32767 then schema_id::int else null end) as smallint) as uid
  , CAST(0 as smallint) as reserved
  , CAST(sys.CollationProperty(collation_name, 'CollationId') as int) as collationid
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as usertype
  , CAST((case when (coalesce(sys.translate_pg_type_to_tsql(system_type_id), sys.translate_pg_type_to_tsql(user_type_id)) 
            in ('nvarchar', 'varchar', 'sysname', 'varbinary')) then 1 
          else 0 end) as sys.bit) as variable
  , CAST(is_nullable as sys.bit) as allownulls
  , CAST(system_type_id as int) as type
  , CAST(null as sys.varchar(255)) as printfmt
  , (case when precision <> 0::smallint then precision 
      else sys.systypes_precision_helper(sys.translate_pg_type_to_tsql(system_type_id), max_length) end) as prec
  , CAST(scale as sys.tinyint) as scale
  , CAST(collation_name as sys.sysname) as collation
FROM sys.types;
GRANT SELECT ON sys.systypes TO PUBLIC;

create or replace view sys.table_types as
select st.*
  , pt.typrelid::int as type_table_object_id
  , 0::sys.bit as is_memory_optimized -- return 0 until we support in-memory tables
from sys.types st
inner join pg_catalog.pg_type pt on st.user_type_id = pt.oid
where is_table_type = 1;
GRANT SELECT ON sys.table_types TO PUBLIC;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as char(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  , CAST(tsql_get_expr(d.adbin, d.adrelid) as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as char(2)) as type
  , CAST('CHECK_CONSTRAINT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.bit) as is_disabled
  , CAST(0 as sys.bit) as is_not_for_replication
  , CAST(0 as sys.bit) as is_not_trusted
  , CAST(c.conkey[1] as integer) AS parent_column_id
  , CAST(tsql_get_constraintdef(c.oid) as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('sp_addlinkedserver', 'master_dbo', 'P'),
    ('sp_addlinkedsrvlogin', 'master_dbo', 'P'),
    ('sp_dropserver', 'master_dbo', 'P'),
    ('sp_droplinkedsrvlogin', 'master_dbo', 'P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on t.schema_name = ns.nspname

union all

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name = b.orig_name
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

create or replace view sys.all_objects as
select 
    cast (name as sys.sysname) collate sys.database_default
  , cast (object_id as integer) 
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , cast (type as char(2)) collate sys.database_default
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , cast (case when (schema_id::regnamespace::text = 'sys') then 1
          when name in (select name from sys.shipped_objects_not_in_sys nis 
                        where nis.name = name and nis.schemaid = schema_id and nis.type = type) then 1 
          else 0 end as sys.bit) as is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- details of user defined and system tables
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U' as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and not sys.is_table_type(t.oid)
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F' as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'f'
union all
-- details of user defined and system primary key constraints
select
    c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK' as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'p'
union all
-- details of user defined and system defined procedures
select
    p.proname as name 
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null 
  		       then tr.tgrelid 
  		       else 0 end as int) 
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case 
          when pg_catalog.format_type(p.prorettype, null) = 'trigger'
            then 'TR'::varchar(2)
          when p.proretset then
            case 
              when t.typtype = 'c'
                then 'TF'::varchar(2)
              else 'IF'::varchar(2)
            end
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case 
          when pg_catalog.format_type(p.prorettype, null) = 'trigger'
            then 'SQL_TRIGGER'::varchar(60)
          when p.proretset then
            case 
              when t.typtype = 'c'
                then 'SQL_TABLE_VALUED_FUNCTION'::varchar(60)
              else 'SQL_INLINE_TABLE_VALUED_FUNCTION'::varchar(60)
            end
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
inner join pg_catalog.pg_type t on t.oid = p.prorettype
left join pg_trigger tr on tr.tgfoid = p.oid
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
union all
-- details of all default constraints
select
    ('DF_' || o.relname || '_' || d.oid)::name as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
where a.atthasdef = 't' and a.attgenerated = ''
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::name
  , c.oid::integer as object_id
  , NULL::integer as principal_id 
  , c.connamespace::integer as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'c' and c.conrelid != 0
union all
-- details of user defined and system defined sequence objects
select
  p.relname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where p.relkind = 'S'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
union all
-- details of user defined table types
select
    ('TT_' || tt.name || '_' || tt.type_table_object_id)::name as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::varchar(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace view sys.system_objects as
select * from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname = 'sys';
GRANT SELECT ON sys.system_objects TO PUBLIC;

create or replace view sys.all_views as
SELECT
    CAST(c.relname AS sys.SYSNAME) as name
  , CAST(c.oid AS INT) as object_id
  , CAST(null AS INT) as principal_id
  , CAST(c.relnamespace as INT) as schema_id
  , CAST(0 as INT) as parent_object_id
  , CAST('V' as sys.bpchar(2)) as type
  , CAST('VIEW'as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(case when (c.relnamespace::regnamespace::text = 'sys') then 1
	when c.relname in (select name from sys.shipped_objects_not_in_sys nis
		where nis.name = c.relname and nis.schemaid = c.relnamespace and nis.type = 'V') then 1
	else 0 end as sys.bit) AS is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.BIT) AS is_replicated
  , CAST(0 as sys.BIT) AS has_replication_filter
  , CAST(0 as sys.BIT) AS has_opaque_metadata
  , CAST(0 as sys.BIT) AS has_unchecked_assembly_data
  , CAST(
      CASE 
        WHEN (v.check_option = 'NONE') 
          THEN 0
        ELSE 1
      END
    AS sys.BIT) AS with_check_option
  , CAST(0 as sys.BIT) AS is_date_correlation_view
FROM pg_catalog.pg_namespace AS ns
INNER JOIN pg_class c ON ns.oid = c.relnamespace
INNER JOIN information_schema.views v ON c.relname = v.table_name AND ns.nspname = v.table_schema
WHERE c.relkind = 'v' AND ns.nspname in 
  (SELECT nspname from sys.babelfish_namespace_ext where dbid = sys.db_id() UNION ALL SELECT CAST('sys' AS NAME))
AND pg_is_other_temp_schema(ns.oid) = false
AND (pg_has_role(c.relowner, 'USAGE') = true
OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') = true
OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') = true);
GRANT SELECT ON sys.all_views TO PUBLIC;

-- TODO: BABELFISH-506
CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(p.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(f.create_date as sys.datetime) AS create_date,
  CAST(f.create_date as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(
      CASE WHEN tr.tgenabled = 'D'
      THEN 1
      ELSE 0
      END
      AS sys.bit
  )	AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;

create or replace view sys.objects as
select
      CAST(t.name as sys.sysname) as name 
    , CAST(t.object_id as int) as object_id
    , CAST(t.principal_id as int) as principal_id
    , CAST(t.schema_id as int) as schema_id
    , CAST(t.parent_object_id as int) as parent_object_id
    , CAST('U' as char(2)) as type
    , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
    , CAST(t.create_date as sys.datetime) as create_date
    , CAST(t.modify_date as sys.datetime) as modify_date
    , CAST(t.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(t.is_published as sys.bit) as is_published
    , CAST(t.is_schema_published as sys.bit) as is_schema_published
from  sys.tables t
union all
select
      CAST(v.name as sys.sysname) as name
    , CAST(v.object_id as int) as object_id
    , CAST(v.principal_id as int) as principal_id
    , CAST(v.schema_id as int) as schema_id
    , CAST(v.parent_object_id as int) as parent_object_id
    , CAST('V' as char(2)) as type
    , CAST('VIEW' as sys.nvarchar(60)) as type_desc
    , CAST(v.create_date as sys.datetime) as create_date
    , CAST(v.modify_date as sys.datetime) as modify_date
    , CAST(v.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(v.is_published as sys.bit) as is_published
    , CAST(v.is_schema_published as sys.bit) as is_schema_published
from  sys.views v
union all
select
      CAST(f.name as sys.sysname) as name
    , CAST(f.object_id as int) as object_id
    , CAST(f.principal_id as int) as principal_id
    , CAST(f.schema_id as int) as schema_id
    , CAST(f.parent_object_id as int) as parent_object_id
    , CAST('F' as char(2)) as type
    , CAST('FOREIGN_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(f.create_date as sys.datetime) as create_date
    , CAST(f.modify_date as sys.datetime) as modify_date
    , CAST(f.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(f.is_published as sys.bit) as is_published
    , CAST(f.is_schema_published as sys.bit) as is_schema_published
 from sys.foreign_keys f
union all
select
      CAST(p.name as sys.sysname) as name
    , CAST(p.object_id as int) as object_id
    , CAST(p.principal_id as int) as principal_id
    , CAST(p.schema_id as int) as schema_id
    , CAST(p.parent_object_id as int) as parent_object_id
    , CAST('PK' as char(2)) as type
    , CAST('PRIMARY_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
where p.type = 'PK'
union all
select
      CAST(pr.name as sys.sysname) as name
    , CAST(pr.object_id as int) as object_id
    , CAST(pr.principal_id as int) as principal_id
    , CAST(pr.schema_id as int) as schema_id
    , CAST(pr.parent_object_id as int) as parent_object_id
    , CAST(pr.type as char(2)) as type
    , CAST(pr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(pr.create_date as sys.datetime) as create_date
    , CAST(pr.modify_date as sys.datetime) as modify_date
    , CAST(pr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(pr.is_published as sys.bit) as is_published
    , CAST(pr.is_schema_published as sys.bit) as is_schema_published
 from sys.procedures pr
union all
select
      CAST(tr.name as sys.sysname) as name
    , CAST(tr.object_id as int) as object_id
    , CAST(NULL as int) as principal_id
    , CAST(p.pronamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_proc p on p.oid = tr.object_id
union all 
select
    CAST(def.name as sys.sysname) as name
  , CAST(def.object_id as int) as object_id
  , CAST(def.principal_id as int) as principal_id
  , CAST(def.schema_id as int) as schema_id
  , CAST(def.parent_object_id as int) as parent_object_id
  , CAST(def.type as char(2)) as type
  , CAST(def.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(def.create_date as sys.datetime) as create_date
  , CAST(def.modified_date as sys.datetime) as modify_date
  , CAST(def.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(def.is_published as sys.bit) as is_published
  , CAST(def.is_schema_published as sys.bit) as is_schema_published
  from sys.default_constraints def
union all
select
    CAST(chk.name as sys.sysname) as name
  , CAST(chk.object_id as int) as object_id
  , CAST(chk.principal_id as int) as principal_id
  , CAST(chk.schema_id as int) as schema_id
  , CAST(chk.parent_object_id as int) as parent_object_id
  , CAST(chk.type as char(2)) as type
  , CAST(chk.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(chk.create_date as sys.datetime) as create_date
  , CAST(chk.modify_date as sys.datetime) as modify_date
  , CAST(chk.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(chk.is_published as sys.bit) as is_published
  , CAST(chk.is_schema_published as sys.bit) as is_schema_published
  from sys.check_constraints chk
union all
select
    CAST(p.relname as sys.sysname) as name
  , CAST(p.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(s.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('SO' as char(2)) as type
  , CAST('SEQUENCE_OBJECT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
and has_schema_privilege(s.schema_id, 'USAGE')
union all
select
    CAST(('TT_' || tt.name collate "C" || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt
inner join pg_class c on tt.type_table_object_id = c.oid;
GRANT SELECT ON sys.objects TO PUBLIC;

create or replace view sys.sysobjects as
select
  CAST(s.name as sys._ci_sysname)
  , CAST(s.object_id as int) as id
  , CAST(s.type as sys.bpchar(2)) as xtype

  -- 'uid' is specified as type INT here, and not SMALLINT per SQL Server documentation.
  -- This is because if you routinely drop and recreate databases, it is possible for the
  -- dbo schema which relies on pg_catalog oid values to exceed the size of a smallint. 
  , CAST(s.schema_id as int) as uid
  , CAST(0 as smallint) as info
  , CAST(0 as int) as status
  , CAST(0 as int) as base_schema_ver
  , CAST(0 as int) as replinfo
  , CAST(s.parent_object_id as int) as parent_obj
  , CAST(s.create_date as sys.datetime) as crdate
  , CAST(0 as smallint) as ftcatid
  , CAST(0 as int) as schema_ver
  , CAST(0 as int) as stats_schema_ver
  , CAST(s.type as sys.bpchar(2)) as type
  , CAST(0 as smallint) as userstat
  , CAST(0 as smallint) as sysstat
  , CAST(0 as smallint) as indexdel
  , CAST(s.modify_date as sys.datetime) as refdate
  , CAST(0 as int) as version
  , CAST(0 as int) as deltrig
  , CAST(0 as int) as instrig
  , CAST(0 as int) as updtrig
  , CAST(0 as int) as seltrig
  , CAST(0 as int) as category
  , CAST(0 as smallint) as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

-- TODO: BABEL-3127
CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF', 'TR') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition  -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF', 'IF') THEN
        CASE WHEN p.proisstrict THEN 1
        ELSE 0 
        END
      ELSE 0
      END
    AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nmext.nspname = ext.nspname
LEFT OUTER JOIN sys.babelfish_view_def bvd 
 on (
      ext.orig_name = bvd.schema_name AND 
      ext.dbid = bvd.dbid AND
      ao.name = bvd.object_name 
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
LEFT JOIN sys.babelfish_function_ext f ON ao.name = f.funcname COLLATE "C" AND ao.schema_id::regnamespace::name = f.nspname
AND sys.babelfish_get_pltsql_function_signature(ao.object_id) = f.funcsignature COLLATE "C"
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1;
GRANT SELECT ON sys.all_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.system_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 1;
GRANT SELECT ON sys.system_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 0;
GRANT SELECT ON sys.sql_modules TO PUBLIC;

CREATE VIEW sys.syscharsets
AS
SELECT 1001 as type,
  1 as id,
  0 as csid,
  0 as status,
  NULL::nvarchar(128) as name,
  NULL::nvarchar(255) as description ,
  NULL::varbinary(6000) binarydefinition ,
  NULL::image definition;
GRANT SELECT ON sys.syscharsets TO PUBLIC;

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
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.endpoints 
AS
SELECT CAST('TSQL Default TCP' AS sys.sysname) AS name
	, CAST(4 AS int) AS endpoint_id
	, CAST(1 AS int) AS principal_id
	, CAST(2 AS sys.tinyint) AS protocol
	, CAST('TCP' AS sys.nvarchar(60)) AS protocol_desc
	, CAST(2 AS sys.tinyint) AS type
  , CAST('TSQL' AS sys.nvarchar(60)) AS type_desc
  , CAST(0 AS tinyint) AS state
  , CAST('STARTED' AS sys.nvarchar(60)) AS state_desc
  , CAST(0 AS sys.bit) AS is_admin_endpoint;
GRANT SELECT ON sys.endpoints TO PUBLIC;

create or replace view sys.index_columns
as
select i.indrelid::integer as object_id
  , CAST(CASE WHEN i.indisclustered THEN 1 ELSE 1+row_number() OVER(PARTITION BY c.oid) END AS INTEGER) AS index_id
  , a.attrelid::integer as index_column_id
  , a.attnum::integer as column_id
  , a.attnum::sys.tinyint as key_ordinal
  , 0::sys.tinyint as partition_ordinal
  , 0::sys.bit as is_descending_key
  , 1::sys.bit as is_included_column
from pg_index as i
inner join pg_catalog.pg_attribute a on i.indexrelid = a.attrelid
inner join pg_class c on i.indrelid = c.oid
inner join sys.schemas sch on sch.schema_id = c.relnamespace
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.index_columns TO PUBLIC;

-- internal function that returns relevant info needed
-- by sys.syscolumns view for all procedure parameters.
-- This separate function was needed to workaround BABEL-1597
CREATE OR REPLACE FUNCTION sys.proc_param_helper()
RETURNS TABLE (
    name sys.sysname,
    id int,
    xtype int,
    colid smallint,
    collationid int,
    prec smallint,
    scale int,
    isoutparam int,
    collation sys.sysname
)
AS
$$
BEGIN
RETURN QUERY
select params.parameter_name::sys.sysname
  , pgproc.oid::int
  , CAST(case when pgproc.proallargtypes is null then split_part(pgproc.proargtypes::varchar, ' ', params.ordinal_position)
    else split_part(btrim(pgproc.proallargtypes::text,'{}'), ',', params.ordinal_position) end AS int)
  , params.ordinal_position::smallint
  , coll.oid::int
  , params.numeric_precision::smallint
  , params.numeric_scale::int
  , case params.parameter_mode when 'OUT' then 1 when 'INOUT' then 1 else 0 end
  , params.collation_name::sys.sysname
from information_schema.routines routine
left join information_schema.parameters params
  on routine.specific_schema = params.specific_schema
  and routine.specific_name = params.specific_name
left join pg_collation coll on coll.collname = params.collation_name
/* assuming routine.specific_name is constructed by concatenating procedure name and oid */
left join pg_proc pgproc on routine.specific_name = nameconcatoid(pgproc.proname, pgproc.oid)
left join sys.schemas sch on sch.schema_id = pgproc.pronamespace
where has_schema_privilege(sch.schema_id, 'USAGE');
END;
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE VIEW sys.syscolumns AS
SELECT out_name as name
  , out_object_id as id
  , out_system_type_id as xtype
  , 0::sys.tinyint as typestat
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as xusertype
  , out_max_length as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , out_column_id::smallint as colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , out_default_object_id::int as cdefault
  , out_rule_object_id::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , out_offset as offset
  , out_collation_id as collationid
  , (case out_is_nullable::int when 1 then 8    else 0 end +
     case out_is_identity::int when 1 then 128  else 0 end)::sys.tinyint as status
  , out_system_type_id as type
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal()
union all
SELECT p.name
  , p.id
  , p.xtype
  , 0::sys.tinyint as typestat
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as xusertype
  , null as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , p.colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , null::int as cdefault
  , null::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , 0::smallint as offset
  , collationid
  , (case p.isoutparam when 1 then 64 else 0 end)::sys.tinyint as status
  , p.xtype as type
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , p.prec
  , p.scale
  , 0::int as iscomputed
  , p.isoutparam
  , 1::int as isnullable
  , p.collation
FROM sys.proc_param_helper() as p;
GRANT SELECT ON sys.syscolumns TO PUBLIC;

create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , d.host_name::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , d.context_info::sys.varbinary(128) as context_info
    , null::integer as cpu_time
    , null::integer as memory_usage
    , null::integer as total_scheduled_time
    , null::integer as total_elapsed_time
    , a.client_port as endpoint_id
    , a.query_start::sys.datetime as last_request_start_time
    , a.state_change::sys.datetime as last_request_end_time
    , null::bigint as "reads"
    , null::bigint as "writes"
    , null::bigint as logical_reads
    , case when a.client_port > 0 then 1::sys.bit else 0::sys.bit end as is_user_process
    , d.textsize as text_size
    , d.language::sys.nvarchar(128) as language
    , 'ymd'::sys.nvarchar(3) as date_format-- Bld 173 lacks support for SET DATEFORMAT and always expects ymd
    , d.datefirst::smallint as date_first -- Bld 173 lacks support for SET DATEFIRST and always returns 7
    , CAST(CAST(d.quoted_identifier as integer) as sys.bit) as quoted_identifier
    , CAST(CAST(d.arithabort as integer) as sys.bit) as arithabort
    , CAST(CAST(d.ansi_null_dflt_on as integer) as sys.bit) as ansi_null_dflt_on
    , CAST(CAST(d.ansi_defaults as integer) as sys.bit) as ansi_defaults
    , CAST(CAST(d.ansi_warnings as integer) as sys.bit) as ansi_warnings
    , CAST(CAST(d.ansi_padding as integer) as sys.bit) as ansi_padding
    , CAST(CAST(d.ansi_nulls as integer) as sys.bit) as ansi_nulls
    , CAST(CAST(d.concat_null_yields_null as integer) as sys.bit) as concat_null_yields_null
    , d.transaction_isolation::smallint as transaction_isolation_level
    , d.lock_timeout as lock_timeout
    , 0 as deadlock_priority
    , d.row_count as row_count
    , d.error as prev_error
    , null::sys.varbinary(85) as original_security_id
    , a.usename::sys.nvarchar(128) as original_login_name
    , null::sys.datetime as last_successful_logon
    , null::sys.datetime as last_unsuccessful_logon
    , null::bigint as unsuccessful_logons
    , null::int as group_id
    , d.database_id::smallint as database_id
    , 0 as authenticating_database_id
    , d.trancount as open_transaction_count
  from pg_catalog.pg_stat_activity AS a
  RIGHT JOIN sys.tsql_stat_get_activity('sessions') AS d ON (a.pid = d.procid);
  GRANT SELECT ON sys.dm_exec_sessions TO PUBLIC;

create or replace view sys.dm_exec_connections
 as
 select a.pid as session_id
   , a.pid as most_recent_session_id
   , a.backend_start::sys.datetime as connect_time
   , 'TCP'::sys.nvarchar(40) as net_transport
   , 'TSQL'::sys.nvarchar(40) as protocol_type
   , d.protocol_version as protocol_version
   , 4 as endpoint_id
   , d.encrypyt_option::sys.nvarchar(40) as encrypt_option
   , null::sys.nvarchar(40) as auth_scheme
   , null::smallint as node_affinity
   , null::int as num_reads
   , null::int as num_writes
   , null::sys.datetime as last_read
   , null::sys.datetime as last_write
   , d.packet_size as net_packet_size
   , a.client_addr::varchar(48) as client_net_address
   , a.client_port as client_tcp_port
   , null::varchar(48) as local_net_address
   , null::int as local_tcp_port
   , null::sys.uniqueidentifier as connection_id
   , null::sys.uniqueidentifier as parent_connection_id
   , a.pid::sys.varbinary(64) as most_recent_sql_handle
 from pg_catalog.pg_stat_activity AS a
 RIGHT JOIN sys.tsql_stat_get_activity('connections') AS d ON (a.pid = d.procid);
 GRANT SELECT ON sys.dm_exec_connections TO PUBLIC;

CREATE OR REPLACE VIEW sys.configurations
AS
SELECT  configuration_id, 
        name, 
        value, 
        minimum, 
        maximum, 
        value_in_use, 
        description, 
        is_dynamic, 
        is_advanced 
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.configurations TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscurconfigs
AS
SELECT  value,
        configuration_id AS config,
        comment_syscurconfigs AS comment,
        CASE
        	WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 0 THEN CAST(0 as smallint)
        	WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 1 THEN CAST(1 as smallint)
        	WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 0 THEN CAST(2 as smallint)
        	WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 1 THEN CAST(3 as smallint)
        END AS status
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.syscurconfigs TO PUBLIC;

CREATE OR REPLACE VIEW sys.sysconfigures
AS
SELECT  value_in_use AS value,
        configuration_id AS config,
        comment_sysconfigures AS comment,
        CASE
        	WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 0 THEN CAST(0 as smallint)
        	WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 1 THEN CAST(1 as smallint)
        	WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 0 THEN CAST(2 as smallint)
        	WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 1 THEN CAST(3 as smallint)
        END AS status
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.sysconfigures TO PUBLIC;

CREATE OR REPLACE VIEW sys.syslanguages
AS
SELECT
    lang_id AS langid,
    CAST(lower(lang_data_jsonb ->> 'date_format'::TEXT) AS SYS.NCHAR(3)) AS dateformat,
    CAST(lang_data_jsonb -> 'date_first'::TEXT AS SYS.TINYINT) AS datefirst,
    CAST(NULL AS INT) AS upgrade,
    CAST(coalesce(lang_name_mssql, lang_name_pg) AS SYS.SYSNAME) AS name,
    CAST(coalesce(lang_alias_mssql, lang_alias_pg) AS SYS.SYSNAME) AS alias,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_names'::TEXT)), ',') AS SYS.NVARCHAR(372)) AS months,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_shortnames'::TEXT)),',') AS SYS.NVARCHAR(132)) AS shortmonths,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'days_shortnames'::TEXT)),',') AS SYS.NVARCHAR(217)) AS days,
    CAST(NULL AS INT) AS lcid,
    CAST(NULL AS SMALLINT) AS msglangid
FROM sys.babelfish_syslanguages;
GRANT SELECT ON sys.syslanguages TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_schema_collections
AS
SELECT
  CAST(NULL AS INT) as xml_collection_id,
  CAST(NULL AS INT) as schema_id,
  CAST(NULL AS INT) as principal_id,
  CAST('sys' AS sys.sysname) as name,
  CAST(NULL as sys.datetime) as create_date,
  CAST(NULL as sys.datetime) as modify_date
WHERE FALSE;
GRANT SELECT ON sys.xml_schema_collections TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_database_replica_states
AS
SELECT
   CAST(0 as INT) database_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as replica_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_database_id
  ,CAST(0 as sys.BIT) as is_local
  ,CAST(0 as sys.BIT) as is_primary_replica
  ,CAST(0 as sys.TINYINT) as synchronization_state
  ,CAST('' as sys.nvarchar(60)) as synchronization_state_desc
  ,CAST(0 as sys.BIT) as is_commit_participant
  ,CAST(0 as sys.TINYINT) as synchronization_health
  ,CAST('' as sys.nvarchar(60)) as synchronization_health_desc
  ,CAST(0 as sys.TINYINT) as database_state
  ,CAST('' as sys.nvarchar(60)) as database_state_desc
  ,CAST(0 as sys.BIT) as is_suspended
  ,CAST(0 as sys.TINYINT) as suspend_reason
  ,CAST('' as sys.nvarchar(60)) as suspend_reason_desc
  ,CAST(0.0 as numeric(25,0)) as truncation_lsn
  ,CAST(0.0 as numeric(25,0)) as recovery_lsn
  ,CAST(0.0 as numeric(25,0)) as last_sent_lsn
  ,CAST(NULL as sys.DATETIME) as last_sent_time
  ,CAST(0.0 as numeric(25,0)) as last_received_lsn
  ,CAST(NULL as sys.DATETIME) as last_received_time
  ,CAST(0.0 as numeric(25,0)) as last_hardened_lsn
  ,CAST(NULL as sys.DATETIME) as last_hardened_time
  ,CAST(0.0 as numeric(25,0)) as last_redone_lsn
  ,CAST(NULL as sys.DATETIME) as last_redone_time
  ,CAST(0 as sys.BIGINT) as log_send_queue_size
  ,CAST(0 as sys.BIGINT) as log_send_rate
  ,CAST(0 as sys.BIGINT) as redo_queue_size
  ,CAST(0 as sys.BIGINT) as redo_rate
  ,CAST(0 as sys.BIGINT) as filestream_send_rate
  ,CAST(0.0 as numeric(25,0)) as end_of_log_lsn
  ,CAST(0.0 as numeric(25,0)) as last_commit_lsn
  ,CAST(NULL as sys.DATETIME) as last_commit_time
  ,CAST(0 as sys.BIGINT) as low_water_mark_for_ghosts
  ,CAST(0 as sys.BIGINT) as secondary_lag_seconds
WHERE FALSE;
GRANT SELECT ON sys.dm_hadr_database_replica_states TO PUBLIC;

CREATE OR REPLACE VIEW sys.data_spaces
AS
SELECT 
  CAST('PRIMARY' as SYSNAME) AS name,
  CAST(1 as INT) AS data_space_id,
  CAST('FG' as CHAR(2)) AS type,
  CAST('ROWS_FILEGROUP' as NVARCHAR(60)) AS type_desc,
  CAST(1 as sys.BIT) AS is_default,
  CAST(0 as sys.BIT) AS is_system;
GRANT SELECT ON sys.data_spaces TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_mirroring
AS
SELECT 
  CAST(database_id AS int) AS database_id,
	CAST(NULL AS sys.uniqueidentifier) AS mirroring_guid,
	CAST(NULL AS sys.tinyint) AS mirroring_state,
	CAST(NULL AS sys.nvarchar(60)) AS mirroring_state_desc,
	CAST(NULL AS sys.tinyint) AS mirroring_role,
	CAST(NULL AS sys.nvarchar(60)) AS mirroring_role_desc,
	CAST(NULL AS int) AS mirroring_role_sequence,
	CAST(NULL AS sys.tinyint) as mirroring_safety_level,
	CAST(NULL AS sys.nvarchar(60)) AS mirroring_safety_level_desc,
	CAST(NULL AS int) as mirroring_safety_sequence,
	CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_name,
	CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_instance,
	CAST(NULL AS sys.nvarchar(128)) AS mirroring_witness_name,
	CAST(NULL AS sys.tinyint) AS mirroring_witness_state,
	CAST(NULL AS sys.nvarchar(60)) AS mirroring_witness_state_desc,
	CAST(NULL AS numeric(25,0)) AS mirroring_failover_lsn,
	CAST(NULL AS int) AS mirroring_connection_timeout,
	CAST(NULL AS int) AS mirroring_redo_queue,
	CAST(NULL AS sys.nvarchar(60)) AS mirroring_redo_queue_type,
	CAST(NULL AS numeric(25,0)) AS mirroring_end_of_log_lsn,
	CAST(NULL AS numeric(25,0)) AS mirroring_replication_lsn
FROM sys.databases;
GRANT SELECT ON sys.database_mirroring TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_files
AS
SELECT
    CAST(1 as INT) AS file_id,
    CAST(NULL as sys.uniqueidentifier) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as sys.NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as sys.SYSNAME) AS name,
    CAST('' as sys.NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as sys.NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as sys.uniqueidentifier) AS differential_base_guid,
    CAST(NULL as sys.datetime) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn
WHERE false;
GRANT SELECT ON sys.database_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.hash_indexes
AS
SELECT 
  si.object_id,
  si.name,
  si.index_id,
  si.type,
  si.type_desc,
  si.is_unique,
  si.data_space_id,
  si.ignore_dup_key,
  si.is_primary_key,
  si.is_unique_constraint,
  si.fill_factor,
  si.is_padded,
  si.is_disabled,
  si.is_hypothetical,
  si.allow_row_locks,
  si.allow_page_locks,
  si.has_filter,
  si.filter_definition,
  CAST(0 as INT) AS bucket_count,
  si.auto_created
FROM sys.indexes si
WHERE FALSE;
GRANT SELECT ON sys.hash_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetable_system_defined_objects
AS
SELECT 
  CAST(0 as INT) AS object_id,
  CAST(0 as INT) AS parent_object_id
  WHERE FALSE;
GRANT SELECT ON sys.filetable_system_defined_objects TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_filestream_options
AS
SELECT
  CAST(0 as INT) AS database_id,
  CAST('' as NVARCHAR(255)) AS directory_name,
  CAST(0 as TINYINT) AS non_transacted_access,
  CAST('' as NVARCHAR(60)) AS non_transacted_access_desc
WHERE FALSE;
GRANT SELECT ON sys.database_filestream_options TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT)  AS index_id
  , CAST(idx.type AS sys.tinyint) AS type
  , CAST(idx.type_desc AS sys.nvarchar(60)) AS type_desc
  , CAST(idx.is_unique AS sys.bit) AS is_unique
  , CAST(idx.data_space_id AS int) AS data_space_id
  , CAST(idx.ignore_dup_key AS sys.bit) AS ignore_dup_key
  , CAST(idx.is_primary_key AS sys.bit) AS is_primary_key
  , CAST(idx.is_unique_constraint AS sys.bit) AS is_unique_constraint
  , CAST(idx.fill_factor AS sys.tinyint) AS fill_factor
  , CAST(idx.is_padded AS sys.bit) AS is_padded
  , CAST(idx.is_disabled AS sys.bit) AS is_disabled
  , CAST(idx.is_hypothetical AS sys.bit) AS is_hypothetical
  , CAST(idx.allow_row_locks AS sys.bit) AS allow_row_locks
  , CAST(idx.allow_page_locks AS sys.bit) AS allow_page_locks
  , CAST(idx.has_filter AS sys.bit) AS has_filter
  , CAST(idx.filter_definition AS sys.nvarchar(4000)) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS char(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM  sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_cluster
AS
SELECT
   CAST('' as sys.nvarchar(128)) as cluster_name
  ,CAST(0 as sys.tinyint) as quorum_type
  ,CAST('NODE_MAJORITY' as sys.nvarchar(50)) as quorum_type_desc
  ,CAST(0 as sys.tinyint) as quorum_state
  ,CAST('NORMAL_QUORUM' as sys.nvarchar(50)) as quorum_state_desc;
GRANT SELECT ON sys.dm_hadr_cluster TO PUBLIC;

CREATE OR REPLACE VIEW sys.assembly_modules
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS assembly_id,
   CAST('' AS SYSNAME) AS assembly_class,
   CAST('' AS SYSNAME) AS assembly_method,
   CAST(0 AS sys.BIT) AS null_on_null_input,
   CAST(0 as INT) AS execute_as_principal_id
   WHERE FALSE;
GRANT SELECT ON sys.assembly_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.change_tracking_databases
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(0 as sys.BIT) AS is_auto_cleanup_on,
   CAST(0 as INT) AS retention_period,
   CAST('' as NVARCHAR(60)) AS retention_period_units_desc,
   CAST(0 as TINYINT) AS retention_period_units
WHERE FALSE;
GRANT SELECT ON sys.change_tracking_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_recovery_status
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(NULL as UNIQUEIDENTIFIER) AS database_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS family_guid,
   CAST(0 as NUMERIC(25,0)) AS last_log_backup_lsn,
   CAST(NULL as UNIQUEIDENTIFIER) AS recovery_fork_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS first_recovery_fork_guid,
   CAST(0 as NUMERIC(25,0)) AS fork_point_lsn
WHERE FALSE;
GRANT SELECT ON sys.database_recovery_status TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_languages
AS
SELECT 
   CAST(0 as INT) AS lcid,
   CAST('' as SYSNAME) AS name
WHERE FALSE;
GRANT SELECT ON sys.fulltext_languages TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_index_columns
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS column_id,
   CAST(0 as INT) AS type_column_id,
   CAST(0 as INT) AS language_id,
   CAST(0 as INT) AS statistical_semantics
WHERE FALSE;
GRANT SELECT ON sys.fulltext_index_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.selective_xml_index_paths
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS index_id,
   CAST(0 as INT) AS path_id,
   CAST('' as NVARCHAR(4000)) AS path,
   CAST('' as SYSNAME) AS name,
   CAST(0 as TINYINT) AS path_type,
   CAST(0 as SYSNAME) AS path_type_desc,
   CAST(0 as INT) AS xml_component_id,
   CAST('' as NVARCHAR(4000)) AS xquery_type_description,
   CAST(0 as sys.BIT) AS is_xquery_type_inferred,
   CAST(0 as SMALLINT) AS xquery_max_length,
   CAST(0 as sys.BIT) AS is_xquery_max_length_inferred,
   CAST(0 as sys.BIT) AS is_node,
   CAST(0 as TINYINT) AS system_type_id,
   CAST(0 as TINYINT) AS user_type_id,
   CAST(0 as SMALLINT) AS max_length,
   CAST(0 as TINYINT) AS precision,
   CAST(0 as TINYINT) AS scale,
   CAST('' as SYSNAME) AS collation_name,
   CAST(0 as sys.BIT) AS is_singleton
WHERE FALSE;
GRANT SELECT ON sys.selective_xml_index_paths TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_indexes
AS
SELECT 
   object_id,
   name,
   index_id,
   type,
   type_desc,
   is_unique,
   data_space_id,
   ignore_dup_key,
   is_primary_key,
   is_unique_constraint,
   fill_factor,
   is_padded,
   is_disabled,
   is_hypothetical,
   allow_row_locks,
   allow_page_locks,
   CAST(1 as TINYINT) AS spatial_index_type,
   CAST('' as NVARCHAR(60)) AS spatial_index_type_desc,
   CAST('' as SYSNAME) AS tessellation_scheme,
   has_filter,
   filter_definition,
   auto_created
FROM sys.indexes WHERE FALSE;
GRANT SELECT ON sys.spatial_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetables
AS
SELECT 
   CAST(0 AS INT) AS object_id,
   CAST(0 AS sys.BIT) AS is_enabled,
   CAST('' AS sys.VARCHAR(255)) AS directory_name,
   CAST(0 AS INT) AS filename_collation_id,
   CAST('' AS sys.VARCHAR) AS filename_collation_name
   WHERE FALSE;
GRANT SELECT ON sys.filetables TO PUBLIC;

CREATE OR REPLACE VIEW sys.registered_search_property_lists
AS
SELECT 
   CAST(0 AS INT) AS property_list_id,
   CAST('' AS SYSNAME) AS name,
   CAST(NULL AS DATETIME) AS create_date,
   CAST(NULL AS DATETIME) AS modify_date,
   CAST(0 AS INT) AS principal_id
WHERE FALSE;
GRANT SELECT ON sys.registered_search_property_lists TO PUBLIC;

CREATE OR REPLACE VIEW sys.filegroups
AS
SELECT 
   CAST(ds.name AS sys.SYSNAME),
   CAST(ds.data_space_id AS INT),
   CAST(ds.type AS sys.BPCHAR(2)) COLLATE sys.database_default,
   CAST(ds.type_desc AS sys.NVARCHAR(60)),
   CAST(ds.is_default AS sys.BIT),
   CAST(ds.is_system AS sys.BIT),
   CAST(NULL as sys.UNIQUEIDENTIFIER) AS filegroup_guid,
   CAST(0 as INT) AS log_filegroup_id,
   CAST(0 as sys.BIT) AS is_read_only,
   CAST(0 as sys.BIT) AS is_autogrow_all_files
FROM sys.data_spaces ds WHERE type = 'FG';
GRANT SELECT ON sys.filegroups TO PUBLIC;

CREATE OR REPLACE VIEW sys.master_files
AS
SELECT
    CAST(0 as INT) AS database_id,
    CAST(0 as INT) AS file_id,
    CAST(NULL as UNIQUEIDENTIFIER) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as SYSNAME) AS name,
    CAST('' as NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS differential_base_guid,
    CAST(NULL as DATETIME) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn,
    CAST(0 as INT) AS credential_id
WHERE FALSE;
GRANT SELECT ON sys.master_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.stats
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST('' as SYSNAME) AS name,
   CAST(0 as INT) AS stats_id,
   CAST(0 as sys.BIT) AS auto_created,
   CAST(0 as sys.BIT) AS user_created,
   CAST(0 as sys.BIT) AS no_recompute,
   CAST(0 as sys.BIT) AS has_filter,
   CAST('' as sys.NVARCHAR(4000)) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;
GRANT SELECT ON sys.stats TO PUBLIC;


CREATE OR REPLACE VIEW sys.change_tracking_tables
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as sys.BIT) AS is_track_columns_updated_on,
   CAST(0 AS sys.BIGINT) AS begin_version,
   CAST(0 AS sys.BIGINT) AS cleanup_version,
   CAST(0 AS sys.BIGINT) AS min_valid_version
   WHERE FALSE;
GRANT SELECT ON sys.change_tracking_tables TO PUBLIC;


CREATE OR REPLACE VIEW sys.fulltext_catalogs
AS
SELECT 
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST('' as SYSNAME) AS name,
   CAST('' as NVARCHAR(260)) AS path,
   CAST(0 as sys.BIT) AS is_default,
   CAST(0 as sys.BIT) AS is_accent_sensitivity_on,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS file_id,
   CAST(0 as INT) AS principal_id,
   CAST(2 as sys.BIT) AS is_importing
WHERE FALSE;
GRANT SELECT ON sys.fulltext_catalogs TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_stoplists
AS
SELECT 
   CAST(0 as INT) AS stoplist_id,
   CAST('' as SYSNAME) AS name,
   CAST(NULL as DATETIME) AS create_date,
   CAST(NULL as DATETIME) AS modify_date,
   CAST(0 as INT) AS Principal_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_stoplists TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_indexes
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS unique_index_id,
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST(0 as sys.BIT) AS is_enabled,
   CAST('O' as sys.BPCHAR(1)) AS change_tracking_state,
   CAST('' as sys.NVARCHAR(60)) AS change_tracking_state_desc,
   CAST(0 as sys.BIT) AS has_crawl_completed,
   CAST('' as sys.BPCHAR(1)) AS crawl_type,
   CAST('' as sys.NVARCHAR(60)) AS crawl_type_desc,
   CAST(NULL as sys.DATETIME) AS crawl_start_date,
   CAST(NULL as sys.DATETIME) AS crawl_end_date,
   CAST(NULL as BINARY(8)) AS incremental_timestamp,
   CAST(0 as INT) AS stoplist_id,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS property_list_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.synonyms
AS
SELECT 
    CAST(obj.name as sys.sysname) AS name
  , CAST(obj.object_id as int) AS object_id
  , CAST(obj.principal_id as int) AS principal_id
  , CAST(obj.schema_id as int) AS schema_id
  , CAST(obj.parent_object_id as int) AS parent_object_id
  , CAST(obj.type as sys.bpchar(2)) AS type
  , CAST(obj.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(obj.create_date as sys.datetime) as create_date
  , CAST(obj.modify_date as sys.datetime) as modify_date
  , CAST(obj.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(obj.is_published as sys.bit) as is_published
  , CAST(obj.is_schema_published as sys.bit) as is_schema_published
  , CAST('' as sys.nvarchar(1035)) AS base_object_name
FROM sys.objects obj
WHERE type='SN';
GRANT SELECT ON sys.synonyms TO PUBLIC;
  
CREATE OR REPLACE VIEW sys.plan_guides
AS
SELECT 
    CAST(0 as int) AS plan_guide_id
  , CAST('' as sys.sysname) AS name
  , CAST(NULL as sys.datetime) as create_date
  , CAST(NULL as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_disabled
  , CAST('' as sys.nvarchar(4000)) AS query_text
  , CAST(0 as sys.tinyint) AS scope_type
  , CAST('' as sys.nvarchar(60)) AS scope_type_desc
  , CAST(0 as int) AS scope_type_id
  , CAST('' as sys.nvarchar(4000)) AS scope_batch
  , CAST('' as sys.nvarchar(4000)) AS parameters
  , CAST('' as sys.nvarchar(4000)) AS hints
WHERE FALSE;
GRANT SELECT ON sys.plan_guides TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_index_tessellations 
AS
SELECT 
    CAST(0 as int) AS object_id
  , CAST(0 as int) AS index_id
  , CAST('' as sys.sysname) AS tessellation_scheme
  , CAST(0 as float(53)) AS bounding_box_xmin
  , CAST(0 as float(53)) AS bounding_box_ymin
  , CAST(0 as float(53)) AS bounding_box_xmax
  , CAST(0 as float(53)) AS bounding_box_ymax
  , CAST(0 as smallint) as level_1_grid
  , CAST('' as sys.nvarchar(60)) AS level_1_grid_desc
  , CAST(0 as smallint) as level_2_grid
  , CAST('' as sys.nvarchar(60)) AS level_2_grid_desc
  , CAST(0 as smallint) as level_3_grid
  , CAST('' as sys.nvarchar(60)) AS level_3_grid_desc
  , CAST(0 as smallint) as level_4_grid
  , CAST('' as sys.nvarchar(60)) AS level_4_grid_desc
  , CAST(0 as int) as cells_per_object
WHERE FALSE;
GRANT SELECT ON sys.spatial_index_tessellations TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_parameters
AS
SELECT
    CAST(ss.p_oid AS INT) AS object_id
  , CAST(COALESCE(ss.proargnames[(ss.x).n], '') AS sys.SYSNAME) AS name
  , CAST(
      CASE 
        WHEN is_out_scalar = 1 THEN 0 -- param_id = 0 for output of scalar function
        ELSE (ss.x).n
      END 
    AS INT) AS parameter_id
  -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
  -- This is because the IDs of system type values generated by
  -- Babelfish installation will exceed the size of TINYINT
  , CAST(st.system_type_id AS INT) AS system_type_id
  , CAST(st.user_type_id AS INT) AS user_type_id
  , CAST( 
      CASE
        WHEN st.is_table_type = 1 THEN -1 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.max_length -- UDT case
        ELSE sys.tsql_type_max_length_helper(st.name, t.typlen, typmod, true, true)
      END
    AS smallint) AS max_length
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.precision -- UDT case
        ELSE sys.tsql_type_precision_helper(st.name, typmod)
      END
    AS sys.tinyint) AS precision
  , CAST(
      CASE 
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1  THEN st.scale
        ELSE sys.tsql_type_scale_helper(st.name, typmod,false)
      END
    AS sys.tinyint) AS scale
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 1 -- Output of a scalar function
        WHEN ss.proargmodes[(ss.x).n] in ('o', 'b', 't') THEN 1
        ELSE 0
      END 
    AS sys.bit) AS is_output
  , CAST(0 AS sys.bit) AS is_cursor_ref
  , CAST(0 AS sys.bit) AS has_default_value
  , CAST(0 AS sys.bit) AS is_xml_document
  , CAST(NULL AS sys.sql_variant) AS default_value
  , CAST(0 AS int) AS xml_collection_id
  , CAST(0 AS sys.bit) AS is_readonly
  , CAST(1 AS sys.bit) AS is_nullable
  , CAST(NULL AS int) AS encryption_type
  , CAST(NULL AS sys.nvarchar(64)) AS encryption_type_desc
  , CAST(NULL AS sys.sysname) AS encryption_algorithm_name
  , CAST(NULL AS int) AS column_encryption_key_id
  , CAST(NULL AS sys.sysname) AS column_encryption_key_database_name
FROM pg_type t
  INNER JOIN sys.types st ON st.user_type_id = t.oid
  INNER JOIN 
  (
    SELECT
      p.oid AS p_oid,
      p.proargnames,
      p.proargmodes,
      p.prokind,
      json_extract_path(CAST(p.probin as json), 'typmod_array') AS typmod_array,
      information_schema._pg_expandarray(
      COALESCE(p.proallargtypes,
        CASE 
          WHEN p.prokind = 'f' THEN (CAST( p.proargtypes AS oid[]) || p.prorettype) -- Adds return type if not present on proallargtypes
          ELSE CAST(p.proargtypes AS oid[])
        END
      )) AS x
    FROM pg_proc p
    WHERE (
      p.pronamespace in (select schema_id from sys.schemas union all select oid from pg_namespace where nspname = 'sys')
      AND (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND p.probin like '{%typmod_array%}') -- Needs to have a typmod array in JSON format
  ) ss ON t.oid = (ss.x).x,
  COALESCE(pg_get_function_result(ss.p_oid), '') AS return_type,
  CAST(ss.typmod_array->>(ss.x).n-1 AS INT) AS typmod, 
  CAST(
    CASE
      WHEN ss.prokind = 'f' AND ss.proargnames[(ss.x).n] IS NULL THEN 1 -- checks if param is output of scalar function
      ELSE 0
    END 
  AS INT) AS is_out_scalar
WHERE ( -- If it is a Table function, we only want the inputs
      return_type NOT LIKE 'TABLE(%' OR 
      (return_type LIKE 'TABLE(%' AND ss.proargmodes[(ss.x).n] = 'i'));
GRANT SELECT ON sys.all_parameters TO PUBLIC;

CREATE OR REPLACE VIEW sys.numbered_procedures
AS
SELECT 
    CAST(0 as int) AS object_id
  , CAST(0 as smallint) AS procedure_number
  , CAST('' as sys.nvarchar(4000)) AS definition
WHERE FALSE; -- This condition will ensure that the view is empty
GRANT SELECT ON sys.numbered_procedures TO PUBLIC;

-- BABEL-3325: Revisit once DDL and/or CREATE EVENT NOTIFICATION is supported
CREATE OR REPLACE VIEW sys.events 
AS
SELECT 
  CAST(pt.tgfoid as int) AS object_id
  , CAST(
      CASE 
        WHEN tr.event_manipulation='INSERT' THEN 1
        WHEN tr.event_manipulation='UPDATE' THEN 2
        WHEN tr.event_manipulation='DELETE' THEN 3
        ELSE 1
      END as int
  ) AS type
  , CAST(tr.event_manipulation as sys.nvarchar(60)) AS type_desc
  , CAST(1 as sys.bit) AS  is_trigger_event
  , CAST(null as int) AS event_group_type
  , CAST(null as sys.nvarchar(60)) AS event_group_type_desc
FROM information_schema.triggers tr
JOIN pg_catalog.pg_namespace np ON tr.event_object_schema = np.nspname COLLATE sys.database_default
JOIN pg_class pc ON pc.relname = tr.event_object_table COLLATE sys.database_default AND pc.relnamespace = np.oid
JOIN pg_trigger pt ON pt.tgrelid = pc.oid AND tr.trigger_name = pt.tgname COLLATE sys.database_default
AND has_schema_privilege(pc.relnamespace, 'USAGE')
AND has_table_privilege(pc.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.events TO PUBLIC;

CREATE OR REPLACE VIEW sys.trigger_events
AS
SELECT
  CAST(e.object_id as int) AS object_id,
  CAST(e.type as int) AS type,
  CAST(e.type_desc as sys.nvarchar(60)) AS type_desc,
  CAST(0 as sys.bit) AS is_first,
  CAST(0 as sys.bit) AS is_last,
  CAST(null as int) AS event_group_type,
  CAST(null as sys.nvarchar(60)) AS event_group_type_desc,
  CAST(e.is_trigger_event as sys.bit) AS is_trigger_event
FROM sys.events e
WHERE e.is_trigger_event = 1;
GRANT SELECT ON sys.trigger_events TO PUBLIC;

CREATE OR REPLACE VIEW sys.partitions AS
SELECT
 (to_char( i.object_id, 'FM9999999999' ) || to_char( i.index_id, 'FM9999999999' ) || '1')::bigint AS partition_id
 , i.object_id
 , i.index_id
 , 1::integer AS partition_number
 , 0::bigint AS hobt_id
 , c.reltuples::bigint AS "rows"
 , 0::smallint AS filestream_filegroup_id
 , 0::sys.tinyint AS data_compression
 , 'NONE'::sys.nvarchar(60) AS data_compression_desc
FROM sys.indexes AS i
INNER JOIN pg_catalog.pg_class AS c ON i.object_id = c."oid";
GRANT SELECT ON sys.partitions TO PUBLIC;

CREATE OR REPLACE VIEW sys.servers
AS
SELECT
  CAST(f.oid as int) AS server_id,
  CAST(f.srvname as sys.sysname) AS name,
  CAST('' as sys.sysname) AS product,
  CAST('tds_fdw' as sys.sysname) AS provider,
  CAST((select string_agg(
                  case
                  when option like 'servername=%%' then substring(option, 12)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
  CAST(NULL as sys.nvarchar(4000)) AS location,
  CAST(NULL as sys.nvarchar(4000)) AS provider_string,
  CAST((select string_agg(
                  case
                  when option like 'database=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
  CAST(0 as int) AS connect_timeout,
  CAST(s.query_timeout as int) AS query_timeout,
  CAST(1 as sys.bit) AS is_linked,
  CAST(0 as sys.bit) AS is_remote_login_enabled,
  CAST(0 as sys.bit) AS is_rpc_out_enabled,
  CAST(1 as sys.bit) AS is_data_access_enabled,
  CAST(0 as sys.bit) AS is_collation_compatible,
  CAST(1 as sys.bit) AS uses_remote_collation,
  CAST(NULL as sys.sysname) AS collation_name,
  CAST(0 as sys.bit) AS lazy_schema_validation,
  CAST(0 as sys.bit) AS is_system,
  CAST(0 as sys.bit) AS is_publisher,
  CAST(0 as sys.bit) AS is_subscriber,
  CAST(0 as sys.bit) AS is_distributor,
  CAST(0 as sys.bit) AS is_nonsql_subscriber,
  CAST(1 as sys.bit) AS is_remote_proc_transaction_promotion_enabled,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_rda_server
FROM pg_foreign_server AS f
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
LEFT JOIN sys.babelfish_server_options AS s on f.srvname = s.servername COLLATE "C"
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

CREATE OR REPLACE VIEW sys.linked_logins
AS
SELECT
  CAST(u.srvid as int) AS server_id,
  CAST(0 as int) AS local_principal_id,
  CAST(0 as sys.bit) AS uses_self_credential,
  CAST((select string_agg(
                  case
                  when option like 'username=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(u.umoptions) as option) as sys.sysname) AS remote_name,
  CAST(NULL as sys.datetime) AS modify_date
FROM pg_user_mappings AS U
LEFT JOIN pg_foreign_server AS f ON u.srvid = f.oid
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.linked_logins TO PUBLIC;
