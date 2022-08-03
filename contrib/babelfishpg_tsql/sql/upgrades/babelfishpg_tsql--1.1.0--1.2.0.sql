-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE DOMAIN sys._ci_sysname as sys.sysname;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_grant_usage_to_all()
AS $$
DECLARE
	schema_name text;
BEGIN
	FOR schema_name IN SELECT nspname FROM sys.babelfish_namespace_ext
	LOOP
		EXECUTE format('GRANT USAGE ON SCHEMA %I TO PUBLIC', schema_name);
	END LOOP;
END;
$$ LANGUAGE plpgsql;

CALL sys.sp_babelfish_grant_usage_to_all();
DROP PROCEDURE sys.sp_babelfish_grant_usage_to_all;

CREATE OR REPLACE FUNCTION sys.lock_timeout()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.lock_timeout');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

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

CREATE OR REPLACE FUNCTION COLUMNS_UPDATED ()
	 	   RETURNS sys.VARBINARY AS 'babelfishpg_tsql', 'columnsupdated' LANGUAGE C;

CREATE OR REPLACE FUNCTION UPDATE (TEXT)
	 	   RETURNS BOOLEAN AS 'babelfishpg_tsql', 'updated' LANGUAGE C;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but 
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85) DEFAULT NULL)
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but 
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME DEFAULT NULL, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) 
AS $$
    SELECT CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Added for BABEL-1544
CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_VARBINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  cnt int;
  cur refcursor;
  eh_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';
  IF cnt = 0 THEN
    RAISE EXCEPTION 'unknown configuration: %', normalized_name;
  END IF;

  OPEN cur FOR SELECT name FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';

  LOOP
    FETCH NEXT FROM cur into eh_name;
    exit when not found;

    -- Each setting has a boot_val which is the wired-in default value
    -- Assuming that escape hatches cannot be modified using ALTER SYTEM/config file
    -- we are setting the boot_val as the default value for the escape hatches
    SELECT boot_val INTO default_value FROM pg_catalog.pg_settings WHERE name = eh_name;
    IF lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(eh_name, default_value, 'false');
    ELSE
        PERFORM pg_catalog.set_config(eh_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, default_value);
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, "@option_value");
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

-- For getting host os from PG_VERSION_STR
CREATE OR REPLACE FUNCTION sys.get_host_os()
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'host_os' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.dm_os_host_info AS
SELECT
  -- get_host_os() depends on a Postgres function created separately.
  cast( sys.get_host_os() as sys.nvarchar(256) ) as host_platform
  -- Hardcoded at the moment. Should likely be GUC with default '' (empty string).
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_distribution') as sys.nvarchar(256) ) as host_distribution
  -- documentation on one hand states this is empty string on linux, but otoh shows an example with "ubuntu 16.04"
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_release') as sys.nvarchar(256) ) as host_release
  -- empty string on linux.
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_service_pack_level') as sys.nvarchar(256) )
    as host_service_pack_level
  -- windows stock keeping unit. null on linux.
  , cast( null as int ) as host_sku
  -- lcid
  , cast( sys.collationproperty( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.server_collation_name') , 'lcid') as int )
    as "os_language_version";
GRANT SELECT ON sys.dm_os_host_info TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.is_table_type(object_id oid) RETURNS bool AS
$BODY$
SELECT
  EXISTS(
    SELECT 1
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid
    join sys.schemas sch on pt.typnamespace = sch.schema_id
    JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i' AND pt.typrelid = object_id AND pc.relkind = 'r');
$BODY$
LANGUAGE SQL VOLATILE STRICT;

create or replace view sys.tables as
select
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'U'::varchar(2) as type
  , 'USER_TABLE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , null::integer as filestream_data_space_id
  , relnatts as max_column_id_used
  , 0 as lock_on_bulk_load
  , 1 as uses_ansi_nulls
  , 0 as is_replicated
  , 0 as has_replication_filter
  , 0 as is_merge_published
  , 0 as is_sync_tran_subscribed
  , 0 as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , 0 as large_value_types_out_of_row
  , 0 as is_tracked_by_cdc
  , 0 as lock_escalation
  , 'TABLE'::varchar(60) as lock_escalation_desc
  , 0 as is_filetable
  , 0 as durability
  , 'SCHEMA_AND_DATA'::varchar(60) as durability_desc
  , 0 as is_memory_optimized
  , case relpersistence when 't' then 2 else 0 end as temporal_type
  , case relpersistence when 't' then 'SYSTEM_VERSIONED_TEMPORAL_TABLE' else 'NON_TEMPORAL_TABLE' end as temporal_type_desc
  , null::integer as history_table_id
  , 0 as is_remote_data_archive_enabled
  , 0 as is_external
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and not sys.is_table_type(t.oid)
and has_schema_privilege(sch.schema_id, 'USAGE')
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
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped 
  , 0 as is_published 
  , 0 as is_schema_published 
  , 0 as with_check_option 
  , 0 as is_date_correlation_view 
  , 0 as is_tracked_by_cdc 
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id 
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


CREATE OR REPLACE FUNCTION sys.tsql_type_max_length_helper(IN type TEXT, IN typelen INT, IN typemod INT, IN for_sys_types boolean DEFAULT false)
RETURNS SMALLINT
AS $$
DECLARE
  max_length SMALLINT;
  precision INT;
BEGIN
  -- unknown tsql type
  IF type IS NULL THEN
    RETURN CAST(typelen as SMALLINT);
  END IF;

  IF typelen != -1 THEN
    CASE type 
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
    WHEN type in ('image', 'text', 'ntext') THEN max_length = 16;
    WHEN type = 'sql_variant' THEN max_length = 8016;
    WHEN type in ('varbinary', 'varchar', 'nvarchar') THEN 
      IF for_sys_types THEN max_length = 8000;
      ELSE max_length = -1;
      END IF;
    WHEN type in ('binary', 'char', 'bpchar', 'nchar') THEN max_length = 8000;
    WHEN type in ('decimal', 'numeric') THEN max_length = 17;
    ELSE max_length = typemod;
    END CASE;
    RETURN max_length;
  END IF;

  CASE
  WHEN type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN max_length = typemod - 4;
  WHEN type in ('nchar', 'nvarchar') THEN max_length = (typemod - 4) * 2;
  WHEN type = 'sysname' THEN max_length = (typemod - 4) * 2;
  WHEN type in ('numeric', 'decimal') THEN
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
    INNER JOIN information_schema.columns isc ON c.relname = isc.table_name AND ext.nspname = isc.table_schema AND a.attname = isc.column_name
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
    INNER JOIN information_schema.columns isc ON c.relname = isc.table_name AND nsp.nspname = isc.table_schema AND a.attname = isc.column_name
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
language plpgsql;

create or replace view sys.types As
-- For System types
select tsql_type_name as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , cast(sys.tsql_type_precision_helper(tsql_type_name, t.typtypmod) as int) as precision
  , cast(sys.tsql_type_scale_helper(tsql_type_name, t.typtypmod, false) as int) as scale
  , CASE c.collname
    WHEN 'default' THEN cast(current_setting('babelfishpg_tsql.server_collation_name') as name)
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
left join pg_collation c on c.oid = t.typcollation
, sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name
where tsql_type_name IS NOT NULL
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all 
-- For User Defined Types
select cast(t.typname as text) as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , null::integer as principal_id
  , case when is_tbl_type then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when is_tbl_type then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when is_tbl_type then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN cast(current_setting('babelfishpg_tsql.server_collation_name') as name)
    ELSE  c.collname 
    END as collation_name
  , case when is_tbl_type then 0
         else case when typnotnull then 0 else 1 end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , 1 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , case when is_tbl_type then 1 else 0 end as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
join sys.schemas sch on t.typnamespace = sch.schema_id
left join pg_collation c on c.oid = t.typcollation
, sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
, sys.is_table_type(t.typrelid) as is_tbl_type
-- we want to show details of user defined datatypes created under babelfish database
where tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    sys.is_table_type(t.typrelid)
  );
GRANT SELECT ON sys.types TO PUBLIC;

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
  , d.oid as object_id
  , null::int as principal_id
  , tab.schema_id as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modified_date
  , 0::sys.bit as is_ms_shipped
  , 0::sys.bit as is_published
  , 0::sys.bit as is_schema_published
  , d.adnum::int as parent_column_id
  , pg_get_expr(d.adbin, d.adrelid) as definition
  , 1::sys.bit as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

create or replace view sys.index_columns
as
select i.indrelid::integer as object_id
  , i.indexrelid::integer as index_id
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

create or replace view sys.foreign_keys as
select
  c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , c.conrelid as parent_object_id
  , 'F'::varchar(2) as type
  , 'FOREIGN_KEY_CONSTRAINT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , c.confrelid as referenced_object_id
  , c.confkey as key_index_id
  , 0 as is_disabled
  , 0 as is_not_for_replication
  , 0 as is_not_trusted
  , case c.confdeltype
      when 'a' then 0
      when 'r' then 0
      when 'c' then 1
      when 'n' then 2
      when 'd' then 3
    end as delete_referential_action
  , case c.confdeltype
      when 'a' then 'NO_ACTION'
      when 'r' then 'NO_ACTION'
      when 'c' then 'CASCADE'
      when 'n' then 'SET_NULL'
      when 'd' then 'SET_DEFAULT'
    end as delete_referential_action_desc
  , case c.confupdtype
      when 'a' then 0
      when 'r' then 0
      when 'c' then 1
      when 'n' then 2
      when 'd' then 3
    end as update_referential_action
  , case c.confupdtype
      when 'a' then 'NO_ACTION'
      when 'r' then 'NO_ACTION'
      when 'c' then 'CASCADE'
      when 'n' then 'SET_NULL'
      when 'd' then 'SET_DEFAULT'
    end as update_referential_action_desc
  , 1 as is_system_named
from pg_constraint c
inner join sys.schemas sch on sch.schema_id = c.connamespace
where has_schema_privilege(sch.schema_id, 'USAGE')
and c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

create or replace view sys.key_constraints as
select
  c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , c.conrelid as parent_object_id
  , case contype
      when 'p' then 'PK'::varchar(2)
      when 'u' then 'UQ'::varchar(2)
    end as type
  , case contype
      when 'p' then 'PRIMARY_KEY_CONSTRAINT'::varchar(60)
      when 'u' then 'UNIQUE_CONSTRAINT'::varchar(60)
    end  as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , c.conindid as unique_index_id
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join sys.schemas sch on sch.schema_id = c.connamespace
where has_schema_privilege(sch.schema_id, 'USAGE')
and c.contype in ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;

create or replace view sys.procedures as
select
  p.proname as name
  , p.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , cast (case when tr.tgrelid is not null 
      then tr.tgrelid 
      else 0 end as int) 
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'::varchar(2)
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'::varchar(60)
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , oid::integer as object_id
  , NULL::integer as principal_id 
  , c.connamespace::integer as schema_id
  , conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0::sys.bit as is_ms_shipped
  , 0::sys.bit as is_published
  , 0::sys.bit as is_schema_published
  , 0::sys.bit as is_disabled
  , 0::sys.bit as is_not_for_replication
  , 0::sys.bit as is_not_trusted
  , c.conkey[1]::integer AS parent_column_id
  , substring(pg_get_constraintdef(c.oid) from 7) AS definition
  , 1::sys.bit as uses_database_collation
  , 0::sys.bit as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

create or replace view sys.objects as
select
      t.name
    , t.object_id
    , t.principal_id
    , t.schema_id
    , t.parent_object_id
    , 'U' as type
    , 'USER_TABLE' as type_desc
    , t.create_date
    , t.modify_date
    , t.is_ms_shipped
    , t.is_published
    , t.is_schema_published
from  sys.tables t
union all
select
      v.name
    , v.object_id
    , v.principal_id
    , v.schema_id
    , v.parent_object_id
    , 'V' as type
    , 'VIEW' as type_desc
    , v.create_date
    , v.modify_date
    , v.is_ms_shipped
    , v.is_published
    , v.is_schema_published
from  sys.views v
union all
select
      f.name
    , f.object_id
    , f.principal_id
    , f.schema_id
    , f.parent_object_id
    , 'F' as type
    , 'FOREIGN_KEY_CONSTRAINT'
    , f.create_date
    , f.modify_date
    , f.is_ms_shipped
    , f.is_published
    , f.is_schema_published
 from sys.foreign_keys f
union all
select
      p.name
    , p.object_id
    , p.principal_id
    , p.schema_id
    , p.parent_object_id
    , 'PK' as type
    , 'PRIMARY_KEY_CONSTRAINT' as type_desc
    , p.create_date
    , p.modify_date
    , p.is_ms_shipped
    , p.is_published
    , p.is_schema_published
from sys.key_constraints p
where p.type = 'PK'
union all
select
      pr.name
    , pr.object_id
    , pr.principal_id
    , pr.schema_id
    , pr.parent_object_id
    , pr.type
    , pr.type_desc
    , pr.create_date
    , pr.modify_date
    , pr.is_ms_shipped
    , pr.is_published
    , pr.is_schema_published
 from sys.procedures pr
union all
select
    def.name::name
  , def.object_id
  , def.principal_id
  , def.schema_id
  , def.parent_object_id
  , def.type
  , def.type_desc
  , def.create_date
  , def.modified_date as modify_date
  , def.is_ms_shipped::int
  , def.is_published::int
  , def.is_schema_published::int
  from sys.default_constraints def
union all
select
    chk.name::name
  , chk.object_id
  , chk.principal_id
  , chk.schema_id
  , chk.parent_object_id
  , chk.type
  , chk.type_desc
  , chk.create_date
  , chk.modify_date
  , chk.is_ms_shipped::int
  , chk.is_published::int
  , chk.is_schema_published::int
  from sys.check_constraints chk
union all
select
   p.relname as name
  ,p.oid as object_id
  , null::integer as principal_id
  , s.schema_id as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
and has_schema_privilege(s.schema_id, 'USAGE')
union all
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
from sys.table_types tt;
GRANT SELECT ON sys.objects TO PUBLIC;

create or replace view sys.indexes as
select
  i.indrelid as object_id
  , c.relname as name
  , case when i.indisclustered then 1 else 2 end as type
  , case when i.indisclustered then 'CLUSTERED'::varchar(60) else 'NONCLUSTERED'::varchar(60) end as type_desc
  , case when i.indisunique then 1 else 0 end as is_unique
  , c.reltablespace as data_space_id
  , 0 as ignore_dup_key
  , case when i.indisprimary then 1 else 0 end as is_primary_key
  , case when constr.oid is null then 0 else 1 end as is_unique_constraint
  , 0 as fill_factor
  , case when i.indpred is null then 0 else 1 end as is_padded
  , case when i.indisready then 0 else 1 end is_disabled
  , 0 as is_hypothetical
  , 1 as allow_row_locks
  , 1 as allow_page_locks
  , 0 as has_filter
  , null::varchar as filter_definition
  , 0 as auto_created
  , c.oid as index_id
from pg_class c
inner join sys.schemas sch on c.relnamespace = sch.schema_id
inner join pg_index i on i.indexrelid = c.oid
left join pg_constraint constr on constr.conindid = c.oid
where c.relkind = 'i' and i.indislive
and has_schema_privilege(sch.schema_id, 'USAGE');
GRANT SELECT ON sys.indexes TO PUBLIC;

create or replace view sys.sql_modules as
select
  p.oid as object_id
  , pg_get_functiondef(p.oid) as definition
  , 1 as uses_ansi_nulls
  , 1 as uses_quoted_identifier
  , 0 as is_schema_bound
  , 0 as uses_database_collation
  , 0 as is_recompiled
  , case when p.proisstrict then 1 else 0 end as null_on_null_input
  , null::integer as execute_as_principal_id
  , 0 as uses_native_compilation
from pg_proc p
inner join sys.schemas s on s.schema_id = p.pronamespace
inner join pg_type t on t.oid = p.prorettype
left join pg_collation c on c.oid = t.typcollation
where has_schema_privilege(s.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.sql_modules TO PUBLIC;

-- USER extension
CREATE TABLE sys.babelfish_authid_user_ext (
rolname NAME NOT NULL,
login_name NAME NOT NULL,
type CHAR(1) NOT NULL DEFAULT 'S',
owning_principal_id INT,
is_fixed_role INT NOT NULL DEFAULT 0,
authentication_type INT,
default_language_lcid INT,
allow_encrypted_value_modifications INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
orig_username SYS.NVARCHAR(128) NOT NULL,
database_name SYS.NVARCHAR(128) NOT NULL,
default_schema_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128),
authentication_type_desc SYS.NVARCHAR(60),
PRIMARY KEY (rolname));

CREATE INDEX babelfish_authid_user_ext_login_db_idx ON sys.babelfish_authid_user_ext (login_name, database_name);

GRANT SELECT ON sys.babelfish_authid_user_ext TO PUBLIC;

-- DATABASE_PRINCIPALS
CREATE VIEW sys.database_principals AS SELECT
Ext.orig_username AS name,
CAST(Base.OID AS INT) AS principal_id,
Ext.type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER' ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
Ext.default_schema_name,
Ext.create_date,
Ext.modify_date,
Ext.owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
Ext.authentication_type,
Ext.authentication_type_desc,
Ext.default_language_name,
Ext.default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

GRANT SELECT ON sys.database_principals TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babel_add_existing_users_to_catalog()
LANGUAGE C
AS 'babelfishpg_tsql', 'add_existing_users_to_catalog';

CALL sys.babel_add_existing_users_to_catalog();

CREATE OR REPLACE PROCEDURE sys.babel_drop_all_users()
LANGUAGE C
AS 'babelfishpg_tsql', 'drop_all_users';

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
	CALL sys.babel_drop_all_dbs();
	CALL sys.babel_drop_all_users();
	CALL sys.babel_drop_all_logins();
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', CURRENT_DATABASE());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
END
$$;

create or replace view sys.identity_columns AS
select out_object_id::bigint as object_id
  , out_name::name as name
  , out_column_id::smallint as column_id
  , out_system_type_id::oid as system_type_id
  , out_user_type_id::oid as user_type_id
  , out_max_length as max_length
  , out_precision::integer as precision
  , out_scale::integer as scale
  , out_collation_name::name as collation_name
  , out_is_nullable::integer as is_nullable
  , out_is_ansi_padded::integer as is_ansi_padded
  , out_is_rowguidcol::integer as is_rowguidcol
  , out_is_identity::integer as is_identity
  , out_is_computed::integer as is_computed
  , out_is_filestream::integer as is_filestream
  , out_is_replicated::integer as is_replicated
  , out_is_non_sql_subscribed::integer as is_non_sql_subscribed
  , out_is_merge_published::integer as is_merge_published
  , out_is_dts_replicated::integer as is_dts_replicated
  , out_is_xml_document::integer as is_xml_document
  , out_xml_collection_id::integer as xml_collection_id
  , out_default_object_id::oid as default_object_id
  , out_rule_object_id::oid as rule_object_id
  , out_is_sparse::integer as is_sparse
  , out_is_column_set::integer as is_column_set
  , out_generated_always_type::integer as generated_always_type
  , out_generated_always_type_desc::character varying(60) as generated_always_type_desc
  , out_encryption_type::integer as encryption_type
  , out_encryption_type_desc::character varying(64)  as encryption_type_desc
  , out_encryption_algorithm_name::character varying as encryption_algorithm_name
  , out_column_encryption_key_id::integer as column_encryption_key_id
  , out_column_encryption_key_database_name::character varying as column_encryption_key_database_name
  , out_is_hidden::integer as is_hidden
  , out_is_masked::integer as is_masked
  , sys.ident_seed(OBJECT_NAME(sc.out_object_id))::bigint as seed_value
  , sys.ident_incr(OBJECT_NAME(sc.out_object_id))::bigint as increment_value
  , sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) as last_value
from sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname AND sc.out_column_id = a.attnum
inner join pg_class c on c.oid = a.attrelid
inner join sys.pg_namespace_ext ext on ext.oid = c.relnamespace
where not a.attisdropped
and sc.out_is_identity::integer = 1
and pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)  is not null
and has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

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
LANGUAGE plpgsql;

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

create or replace view sys.all_views as
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
  , 0 as with_check_option
  , 0 as is_date_correlation_view
  , 0 as is_tracked_by_cdc
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.all_views TO PUBLIC;

create or replace view sys.all_objects as
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
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    v.name
  , v.object_id
  , v.principal_id
  , v.schema_id
  , v.parent_object_id
  , 'V' as type
  , 'VIEW' as type_desc
  , v.create_date
  , v.modify_date
  , v.is_ms_shipped
  , v.is_published
  , v.is_schema_published
from  sys.all_views v
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
  , 0 as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'::varchar(2)
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'::varchar(60)
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
from sys.table_types tt;
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace view sys.system_objects as
select * from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname = 'sys';
GRANT SELECT ON sys.system_objects TO PUBLIC;

create or replace view sys.all_columns as
select c.oid as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 0 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
t3.rolname AS TABLE_OWNER,
t1.relname AS TABLE_NAME,
case
  when t1.relkind = 'v' then 'VIEW'
  else 'TABLE'
end AS TABLE_TYPE,
CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, pg_catalog.pg_roles AS t3
WHERE t1.relowner = t3.oid AND t1.relnamespace = t2.oid
AND (t1.relnamespace IN (SELECT schema_id FROM sys.schemas))
AND has_schema_privilege(t1.relnamespace, 'USAGE')
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT on sys.sp_tables_view TO PUBLIC;

create or replace view sys.foreign_key_columns as
select distinct
  c.oid as constraint_object_id
  , c.confkey as constraint_column_id
  , c.conrelid as parent_object_id
  , a_con.attnum as parent_column_id
  , c.confrelid as referenced_object_id
  , a_conf.attnum as referenced_column_id
from pg_constraint c
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f'
and (c.connamespace in (select schema_id from sys.schemas))
and has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.foreign_key_columns TO PUBLIC;

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

CREATE OR REPLACE FUNCTION sys.get_current_full_xact_id()
    RETURNS XID8 AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN pg_snapshot_xmin(pg_current_snapshot())::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.schema_id()
RETURNS INT
LANGUAGE plpgsql
STRICT
AS $$
BEGIN
  RETURN (select oid from sys.pg_namespace_ext where nspname = (select current_schema()))::INT;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.schema_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp()::pg_catalog.timestamp)::sys.datetime;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC; 

CREATE SCHEMA information_schema_tsql;
GRANT USAGE ON SCHEMA information_schema_tsql TO PUBLIC;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypid(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS oid
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypid ELSE tp.typbasetype END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypmod(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS int4
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypmod ELSE tp.typtypmod END$$;


CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length(type text, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
    THEN CASE WHEN typmod = -1
      THEN -1
      ELSE typmod - 4
      END
    WHEN type IN ('text', 'image')
    THEN 2147483647
    WHEN type = 'ntext'
    THEN 1073741823
    WHEN type = 'sysname'
    THEN 128
    WHEN type = 'xml'
    THEN -1
    WHEN type = 'sql_variant'
    THEN 0
    ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length(type text, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
    THEN CASE WHEN typmod = -1 /* default typmod */
      THEN -1
      ELSE typmod - 4
      END
    WHEN type IN ('nchar', 'nvarchar')
    THEN CASE WHEN typmod = -1 /* default typmod */
      THEN -1
      ELSE (typmod - 4) * 2
      END
    WHEN type IN ('text', 'image')
    THEN 2147483647 /* 2^30 + 1 */
    WHEN type = 'ntext'
    THEN 2147483646 /* 2^30 */
    WHEN type = 'sysname'
    THEN 256
    WHEN type = 'sql_variant'
    THEN 0
    WHEN type = 'xml'
    THEN -1
     ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision(type text, typid oid, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE typid
     WHEN 21 /*int2*/ THEN 5
     WHEN 23 /*int4*/ THEN 10
     WHEN 20 /*int8*/ THEN 19
     WHEN 1700 /*numeric*/ THEN
        CASE WHEN typmod = -1
           THEN null
           ELSE ((typmod - 4) >> 16) & 65535
           END
     WHEN 700 /*float4*/ THEN 24
     WHEN 701 /*float8*/ THEN 53
     ELSE
      CASE WHEN type = 'tinyint' THEN 3
        WHEN type = 'money' THEN 19
        WHEN type = 'smallmoney' THEN 10
        ELSE null
      END
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision_radix(type text, typid oid, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE WHEN typid IN (700, 701) THEN 2
    WHEN typid IN (20, 21, 23, 1700) THEN 10
    WHEN type IN ('tinyint', 'money', 'smallmoney') THEN 10
    ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_scale(type text, typid oid, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE WHEN typid IN (21, 23, 20) THEN 0
    WHEN typid IN (1700) THEN
      CASE WHEN typmod = -1
         THEN null
         ELSE (typmod - 4) & 65535
         END
    WHEN type = 'tinyint' THEN 0
      WHEN type IN ('money', 'smallmoney') THEN 4
    ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_datetime_precision(type text, typmod int4) RETURNS integer
  LANGUAGE sql
  IMMUTABLE
  PARALLEL SAFE
  RETURNS NULL ON NULL INPUT
  AS
$$SELECT
  CASE WHEN type = 'date'
       THEN 0
    WHEN type = 'datetime'
    THEN 3
    WHEN type IN ('time', 'datetime2', 'smalldatetime', 'datetimeoffset')
      THEN CASE WHEN typmod < 0 THEN 6 ELSE typmod END
    ELSE null
  END$$;

CREATE OR REPLACE VIEW information_schema_tsql.columns AS
  SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
      CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
      CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
      CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
      CAST(a.attnum AS int) AS "ORDINAL_POSITION",
      CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
      CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
        AS varchar(3))
        AS "IS_NULLABLE",

      CAST(
        CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
        ELSE tsql_type_name END
        AS sys.nvarchar(128))
        AS "DATA_TYPE",

      CAST(
        information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
        AS int)
        AS "CHARACTER_MAXIMUM_LENGTH",

      CAST(
        information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
        AS int)
        AS "CHARACTER_OCTET_LENGTH",

      CAST(
        /* Handle Tinyint separately */
        information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
        AS sys.tinyint)
        AS "NUMERIC_PRECISION",

      CAST(
        information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
        AS smallint)
        AS "NUMERIC_PRECISION_RADIX",

      CAST(
        information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
        AS int)
        AS "NUMERIC_SCALE",

      CAST(
        information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
        AS smallint)
        AS "DATETIME_PRECISION",

      CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
      CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",
      /*
       * TODO: We need to first create mapping of collation name to char-set name;
       * Until then return null.
       */
      CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

      CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
      CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

      /* Returns Babelfish specific collation name. */
      CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

      CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
        THEN nc.dbname ELSE null END
        AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
      CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
        THEN ext.orig_name ELSE null END
        AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
      CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
        THEN t.typname ELSE null END
        AS sys.nvarchar(128)) AS "DOMAIN_NAME"

  FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
    JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
    JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
    LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
      ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
    LEFT JOIN pg_collation co on co.oid = a.attcollation
    LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
    information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
    information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
    sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

  WHERE (NOT pg_is_other_temp_schema(nc.oid))
    AND a.attnum > 0 AND NOT a.attisdropped
    AND c.relkind IN ('r', 'v', 'p')
    AND (pg_has_role(c.relowner, 'USAGE')
      OR has_column_privilege(c.oid, a.attnum,
                  'SELECT, INSERT, UPDATE, REFERENCES'))
    AND ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.domains AS
  SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
    CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
    CAST(t.typname AS sys.sysname) AS "DOMAIN_NAME",
    CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",

    CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
      AS int)
    AS "CHARACTER_MAXIMUM_LENGTH",

    CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
      AS int)
    AS "CHARACTER_OCTET_LENGTH",

    CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
    CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",

    /* Returns Babelfish specific collation name. */
    CAST(
      CASE co.collname
        WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
        ELSE co.collname
      END
    AS sys.nvarchar(128)) AS "COLLATION_NAME",

    CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
    CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",
    /*
     * TODO: We need to first create mapping of collation name to char-set name;
     * Until then return null.
     */
    CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

    CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.typbasetype, t.typtypmod)
      AS sys.tinyint)
    AS "NUMERIC_PRECISION",

    CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, t.typbasetype, t.typtypmod)
      AS smallint)
    AS "NUMERIC_PRECISION_RADIX",

    CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.typbasetype, t.typtypmod)
      AS int)
    AS "NUMERIC_SCALE",

    CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, t.typtypmod)
      AS smallint)
    AS "DATETIME_PRECISION",

    CAST(case when is_tbl_type THEN NULL ELSE t.typdefault END AS sys.nvarchar(4000)) AS "DOMAIN_DEFAULT"

    FROM (pg_type t JOIN sys.pg_namespace_ext nc ON t.typnamespace = nc.oid)
    LEFT JOIN pg_collation co ON t.typcollation = co.oid
    LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
    sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_type_name,
    sys.is_table_type(t.typrelid) as is_tbl_type

    WHERE (pg_has_role(t.typowner, 'USAGE')
      OR has_type_privilege(t.oid, 'USAGE'))
    AND (t.typtype = 'd' OR is_tbl_type)
    AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;


CREATE VIEW information_schema_tsql.tables AS
  SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
       CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
	   CAST(
			CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
			ELSE c.relname END
            AS sys._ci_sysname) AS "TABLE_NAME",

       CAST(
       CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
          WHEN c.relkind = 'v' THEN 'VIEW'
          ELSE null END
       AS varchar(10)) AS "TABLE_TYPE"

  FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
       LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

  WHERE c.relkind IN ('r', 'v', 'p')
    AND (NOT pg_is_other_temp_schema(nc.oid))
    AND (pg_has_role(c.relowner, 'USAGE')
      OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
      OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
    AND ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id                     AS OBJECT_ID,
    isc."TABLE_CATALOG"::information_schema.sql_identifier               AS TABLE_CATALOG,
    isc."TABLE_SCHEMA"::information_schema.sql_identifier                AS TABLE_SCHEMA,
    o.name                          AS TABLE_NAME,
    c.name                          AS COLUMN_NAME,
    isc."ORDINAL_POSITION"::information_schema.cardinal_number           AS ORDINAL_POSITION,
    isc."COLUMN_DEFAULT"::information_schema.character_data              AS COLUMN_DEFAULT,
    isc."IS_NULLABLE"::information_schema.yes_or_no                      AS IS_NULLABLE,
    isc."DATA_TYPE"::information_schema.character_data                   AS DATA_TYPE,

    CAST (CASE WHEN isc."CHARACTER_MAXIMUM_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_MAXIMUM_LENGTH" END
    AS information_schema.cardinal_number) AS CHARACTER_MAXIMUM_LENGTH,

    CAST (CASE WHEN isc."CHARACTER_OCTET_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_OCTET_LENGTH" END
    AS information_schema.cardinal_number)      AS CHARACTER_OCTET_LENGTH,

    CAST (CASE WHEN isc."NUMERIC_PRECISION" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION" END
    AS information_schema.cardinal_number)      AS NUMERIC_PRECISION,

    CAST (CASE WHEN isc."NUMERIC_PRECISION_RADIX" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION_RADIX" END
    AS information_schema.cardinal_number)      AS NUMERIC_PRECISION_RADIX,

    CAST (CASE WHEN isc."NUMERIC_SCALE" < 0 THEN 0 ELSE isc."NUMERIC_SCALE" END
    AS information_schema.cardinal_number)      AS NUMERIC_SCALE,

    CAST (CASE WHEN isc."DATETIME_PRECISION" < 0 THEN 0 ELSE isc."DATETIME_PRECISION" END
    AS information_schema.cardinal_number)      AS DATETIME_PRECISION,

    isc."CHARACTER_SET_CATALOG"::information_schema.sql_identifier       AS CHARACTER_SET_CATALOG,
    isc."CHARACTER_SET_SCHEMA"::information_schema.sql_identifier        AS CHARACTER_SET_SCHEMA,
    isc."CHARACTER_SET_NAME"::information_schema.sql_identifier          AS CHARACTER_SET_NAME,
    isc."COLLATION_CATALOG"::information_schema.sql_identifier           AS COLLATION_CATALOG,
    isc."COLLATION_SCHEMA"::information_schema.sql_identifier            AS COLLATION_SCHEMA,
    c.collation_name                                                     AS COLLATION_NAME,
    isc."DOMAIN_CATALOG"::information_schema.sql_identifier              AS DOMAIN_CATALOG,
    isc."DOMAIN_SCHEMA"::information_schema.sql_identifier               AS DOMAIN_SCHEMA,
    isc."DOMAIN_NAME"::information_schema.sql_identifier                 AS DOMAIN_NAME,
    c.is_sparse                     AS IS_SPARSE,
    c.is_column_set                 AS IS_COLUMN_SET,
    c.is_filestream                 AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V')  -- limit columns to tables and views
        )
    LEFT JOIN information_schema_tsql.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc."TABLE_SCHEMA" and
            o.name = isc."TABLE_NAME" and
            c.name = isc."COLUMN_NAME"
        )
    WHERE CAST("COLUMN_NAME" AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');
GRANT SELECT ON sys.spt_columns_view_managed TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_columns_managed_internal(
    in_catalog sys.nvarchar(128), 
    in_owner sys.nvarchar(128),
    in_table sys.nvarchar(128),
    in_column sys.nvarchar(128),
    in_schematype int)
RETURNS TABLE (
    out_table_catalog sys.nvarchar(128),
    out_table_schema sys.nvarchar(128),
    out_table_name sys.nvarchar(128),
    out_column_name sys.nvarchar(128),
    out_ordinal_position int,
    out_column_default sys.nvarchar(4000),
    out_is_nullable sys.nvarchar(3),
    out_data_type sys.nvarchar,
    out_character_maximum_length int,
    out_character_octet_length int,
    out_numeric_precision int,
    out_numeric_precision_radix int,
    out_numeric_scale int,
    out_datetime_precision int,
    out_character_set_catalog sys.nvarchar(128),
    out_character_set_schema sys.nvarchar(128),
    out_character_set_name sys.nvarchar(128),
    out_collation_catalog sys.nvarchar(128),
    out_is_sparse int,
    out_is_column_set int,
    out_is_filestream int
    )
AS
$$
BEGIN
    RETURN QUERY 
        SELECT CAST(table_catalog AS sys.nvarchar(128)),
            CAST(table_schema AS sys.nvarchar(128)),
            CAST(table_name AS sys.nvarchar(128)),
            CAST(column_name AS sys.nvarchar(128)),
            CAST(ordinal_position AS int),
            CAST(column_default AS sys.nvarchar(4000)),
            CAST(is_nullable AS sys.nvarchar(3)),
            CAST(data_type AS sys.nvarchar),
            CAST(character_maximum_length AS int),
            CAST(character_octet_length AS int),
            CAST(numeric_precision AS int),
            CAST(numeric_precision_radix AS int),
            CAST(numeric_scale AS int),
            CAST(datetime_precision AS int),
            CAST(character_set_catalog AS sys.nvarchar(128)),
            CAST(character_set_schema AS sys.nvarchar(128)),
            CAST(character_set_name AS sys.nvarchar(128)),
            CAST(collation_catalog AS sys.nvarchar(128)),
            CAST(is_sparse AS int),
            CAST(is_column_set AS int),
            CAST(is_filestream AS int)
        FROM sys.spt_columns_view_managed s_cv
        WHERE
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE LOWER(in_catalog)) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE LOWER(in_owner)) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE LOWER(in_table)) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE LOWER(in_column)) AND
        (in_schematype = 0 AND (s_cv.IS_SPARSE = 0) OR in_schematype = 1 OR in_schematype = 2 AND (s_cv.IS_SPARSE = 1));
END;
$$
language plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_columns_managed
(
    "@Catalog"          nvarchar(128) = NULL,
    "@Owner"            nvarchar(128) = NULL,
    "@Table"            nvarchar(128) = NULL,
    "@Column"           nvarchar(128) = NULL,
    "@SchemaType"       nvarchar(128) = 0)        --  0 = 'select *' behavior (default), 1 = all columns, 2 = columnset columns
AS
$$
BEGIN
    SELECT
        out_TABLE_CATALOG AS TABLE_CATALOG,
        out_TABLE_SCHEMA AS TABLE_SCHEMA,
        out_TABLE_NAME AS TABLE_NAME,
        out_COLUMN_NAME AS COLUMN_NAME,
        out_ORDINAL_POSITION AS ORDINAL_POSITION,
        out_COLUMN_DEFAULT AS COLUMN_DEFAULT,
        out_IS_NULLABLE AS IS_NULLABLE,
        out_DATA_TYPE AS DATA_TYPE,
        out_CHARACTER_MAXIMUM_LENGTH AS CHARACTER_MAXIMUM_LENGTH,
        out_CHARACTER_OCTET_LENGTH AS CHARACTER_OCTET_LENGTH,
        out_NUMERIC_PRECISION AS NUMERIC_PRECISION,
        out_NUMERIC_PRECISION_RADIX AS NUMERIC_PRECISION_RADIX,
        out_NUMERIC_SCALE AS NUMERIC_SCALE,
        out_DATETIME_PRECISION AS DATETIME_PRECISION,
        out_CHARACTER_SET_CATALOG AS CHARACTER_SET_CATALOG,
        out_CHARACTER_SET_SCHEMA AS CHARACTER_SET_SCHEMA,
        out_CHARACTER_SET_NAME AS CHARACTER_SET_NAME,
        out_COLLATION_CATALOG AS COLLATION_CATALOG,
        out_IS_SPARSE AS IS_SPARSE,
        out_IS_COLUMN_SET AS IS_COLUMN_SET,
        out_IS_FILESTREAM AS IS_FILESTREAM
    FROM
        sys.sp_columns_managed_internal(@Catalog, @Owner, @Table, @Column, @SchemaType) s_cv
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, IS_NULLABLE;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_managed TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_stat_get_activity(
  IN view_name text,
  OUT procid int,
  OUT client_version int,
  OUT library_name VARCHAR(32),
  OUT language VARCHAR(128),
  OUT quoted_identifier bool,
  OUT arithabort bool,
  OUT ansi_null_dflt_on bool,
  OUT ansi_defaults bool,
  OUT ansi_warnings bool,
  OUT ansi_padding bool,
  OUT ansi_nulls bool,
  OUT concat_null_yields_null bool,
  OUT textsize int,
  OUT datefirst int,
  OUT lock_timeout int,
  OUT transaction_isolation int2,
  OUT client_pid int,
  OUT row_count bigint,
  OUT error int,
  OUT trancount int,
  OUT protocol_version int,
  OUT packet_size int,
  OUT encrypyt_option VARCHAR(40),
  OUT database_id int2)
AS 'babelfishpg_tsql', 'tsql_stat_get_activity'
LANGUAGE C VOLATILE STRICT;

create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , a.client_hostname::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , null::sys.nvarchar(128) as context_info
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

-- BABEL-1782
CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
CAST(t3.name AS name) AS TABLE_OWNER,
t1.relname AS TABLE_NAME,

CASE 
WHEN t1.relkind = 'v' 
	THEN 'VIEW'
ELSE 'TABLE'
END AS TABLE_TYPE,

CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, sys.schemas AS t3
WHERE t1.relnamespace = t3.schema_id AND t1.relnamespace = t2.oid AND t1.relkind IN ('r','v','m') 
AND has_schema_privilege(t1.relnamespace, 'USAGE')
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.sp_tables_view TO PUBLIC;

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
	BEGIN
	   
		IF (SELECT count(*) FROM unnest(string_to_array(in_table_type, ',')) WHERE upper(trim(unnest)) = 'TABLE' OR upper(trim(unnest)) = '''TABLE''') >= 1 THEN
			opt_table = 'TABLE';
		END IF;
		IF (SELECT count(*) from unnest(string_to_array(in_table_type, ',')) WHERE upper(trim(unnest)) = 'VIEW' OR upper(trim(unnest)) = '''VIEW''') >= 1 THEN
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
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR lower(table_name) LIKE lower(in_table_name))
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR lower(table_owner) LIKE lower(in_table_owner))
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR lower(table_qualifier) LIKE lower(in_table_qualifier))
			AND ((SELECT coalesce(in_table_type,'')) = '' OR table_type = opt_table OR table_type = opt_view)
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
			WHERE ((SELECT coalesce(in_table_name,'')) = '' OR lower(table_name) = lower(in_table_name))
			AND ((SELECT coalesce(in_table_owner,'')) = '' OR lower(table_owner) = lower(in_table_owner))
			AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR lower(table_qualifier) = lower(in_table_qualifier))
			AND ((SELECT coalesce(in_table_type,'')) = '' OR table_type = opt_table OR table_type = opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		END IF;
	END;
$$
LANGUAGE plpgsql;
	 

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = '',
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.sysname = '',
    "@table_type" sys.nvarchar(100) = '',
    "@fusepattern" sys.bit = '1')
AS $$
	DECLARE @opt_table sys.varchar(16) = '';
	DECLARE @opt_view sys.varchar(16) = ''; 
BEGIN
	IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	SELECT
	CAST(out_table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
	CAST(out_table_owner AS sys.sysname) AS TABLE_OWNER,
	CAST(out_table_name AS sys.sysname) AS TABLE_NAME,
	CAST(out_table_type AS sys.varchar(32)) AS TABLE_TYPE,
	CAST(out_remarks AS sys.varchar(254)) AS REMARKS
	FROM sys.sp_tables_internal(@table_name, @table_owner, @table_qualifier, CAST(@table_type AS varchar(100)), @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

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
  , a.client_hostname as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , null::bytea as context_info
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

-- For some cases, T-SQL throws an error in DML-time even though it can be detected in DDL-time.
-- This function can be used in DDL-time to postpone errors without impacting general DML performance.
CREATE OR REPLACE FUNCTION sys.babelfish_runtime_error(msg ANYCOMPATIBLE)
RETURNS ANYCOMPATIBLE AS
$$
BEGIN
	RAISE EXCEPTION '%', msg;
END;
$$
LANGUAGE PLPGSQL;
GRANT ALL on FUNCTION sys.babelfish_runtime_error TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_column_privileges_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(COALESCE(SPLIT_PART(t6.attoptions[1], '=', 2), t5.column_name) AS sys.sysname) AS COLUMN_NAME,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = t5.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = t5.grantee) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
	JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name
WHERE t5.privilege_type NOT IN ('TRIGGER', 'TRUNCATE');
GRANT SELECT ON sys.sp_column_privileges_view TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_column_privileges(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
    "@column_name" sys.nvarchar(384) = ''
)
AS $$
BEGIN
    IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
 	
	IF (COALESCE(@table_owner, '') = '')
	BEGIN
		
		IF EXISTS ( 
			SELECT * FROM sys.sp_column_privileges_view 
			WHERE LOWER(@table_name) = LOWER(table_name) and LOWER(SCHEMA_NAME()) = LOWER(table_qualifier)
			)
		BEGIN 
			SELECT 
			TABLE_QUALIFIER,
			TABLE_OWNER,
			TABLE_NAME,
			COLUMN_NAME,
			GRANTOR,
			GRANTEE,
			PRIVILEGE,
			IS_GRANTABLE
			FROM sys.sp_column_privileges_view
			WHERE LOWER(@table_name) = LOWER(table_name)
				AND (LOWER(SCHEMA_NAME()) = LOWER(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
			ORDER BY table_qualifier, table_owner, table_name, column_name, privilege;
		END
		ELSE
		BEGIN
			SELECT 
			TABLE_QUALIFIER,
			TABLE_OWNER,
			TABLE_NAME,
			COLUMN_NAME,
			GRANTOR,
			GRANTEE,
			PRIVILEGE,
			IS_GRANTABLE
			FROM sys.sp_column_privileges_view
			WHERE LOWER(@table_name) = LOWER(table_name)
				AND (LOWER('dbo')= LOWER(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
			ORDER BY table_qualifier, table_owner, table_name, column_name, privilege;
		END
	END
	ELSE
	BEGIN
		SELECT 
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		COLUMN_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE
		FROM sys.sp_column_privileges_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege;
	END
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_datatype_info_helper(
    IN odbcVer smallint,
    IN is_100 bool,
    OUT TYPE_NAME VARCHAR(20),
    OUT DATA_TYPE INT,
    OUT "PRECISION" BIGINT,
    OUT LITERAL_PREFIX VARCHAR(20),
    OUT LITERAL_SUFFIX VARCHAR(20),
    OUT CREATE_PARAMS VARCHAR(20),
    OUT NULLABLE INT,
    OUT CASE_SENSITIVE INT,
    OUT SEARCHABLE INT,
    OUT UNSIGNED_ATTRIBUTE INT,
    OUT MONEY INT,
    OUT AUTO_INCREMENT INT,
    OUT LOCAL_TYPE_NAME VARCHAR(20),
    OUT MINIMUM_SCALE INT,
    OUT MAXIMUM_SCALE INT,
    OUT SQL_DATA_TYPE INT,
    OUT SQL_DATETIME_SUB INT,
    OUT NUM_PREC_RADIX INT,
    OUT INTERVAL_PRECISION INT,
    OUT USERTYPE INT,
    OUT LENGTH INT,
    OUT SS_DATA_TYPE smallint,
-- below column is added in order to join PG's information_schema.columns for sys.sp_columns_100_view
    OUT PG_TYPE_NAME VARCHAR(20)
)
AS 'babelfishpg_tsql', 'sp_datatype_info_helper'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_precision_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('real','float') THEN sp_columns_max_length * 2 - 1
		WHEN type in ('char','varchar','binary','varbinary') THEN sp_columns_max_length
		WHEN type in ('nchar','nvarchar') THEN sp_columns_max_length / 2
		WHEN type in ('sysname','uniqueidentifier') THEN sp_datatype_info_precision
		ELSE sp_columns_precision
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_length_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('decimal','numeric','money','smallmoney') THEN sp_columns_precision + 2
		WHEN type in ('time','date','datetime2','datetimeoffset') THEN sp_columns_precision * 2
		WHEN type in ('smalldatetime') THEN sp_columns_precision
		WHEN type in ('datetime') THEN sp_columns_max_length * 2
		WHEN type in ('sql_variant') THEN sp_datatype_info_precision
		ELSE sp_columns_max_length
	END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_scale_helper(IN type TEXT, IN sp_columns_scale INT) RETURNS INT
AS $$
SELECT
	CASE
		WHEN type in ('bit','real','float','char','varchar','nchar','nvarchar','time','date','datetime2','datetimeoffset','varbinary','binary','sql_variant','sysname','uniqueidentifier') THEN NULL
		ELSE sp_columns_scale
	END;
$$ LANGUAGE SQL IMMUTABLE;

-- TODO: BABEL-2838
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT DISTINCT 
CAST(1 as smallint) AS SCOPE,
CAST(coalesce (split_part(pa.attoptions[1], '=', 2) ,c1.name) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS smallint) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN c1.is_identity = 1 AND (t8.name = 'decimal' or t8.name = 'numeric') 
	THEN CAST(CONCAT(t8.name, '() identity') AS sys.sysname)
	WHEN c1.is_identity = 1 AND (t8.name != 'decimal' AND t8.name != 'numeric')
	THEN CAST(CONCAT(t8.name, ' identity') AS sys.sysname)
	ELSE CAST(t8.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS smallint) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CAST(c1.is_nullable AS int) AS IS_NULLABLE,
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN idx.is_unique = 1 AND (idx.is_unique_constraint !=1 AND idx.is_primary_key != 1)
	THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
	ELSE CAST(t5.contype AS sys.sysname)
END AS CONSTRAINT_TYPE
        
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	LEFT JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
	JOIN sys.columns c1 ON t1.oid = c1.object_id

	JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
	JOIN sys.types as t8 ON c1.user_type_id = t8.user_type_id 
	LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name OR t7.typname = t6.type_name --need in order to get accurate DATA_TYPE value
	LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname
	, sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
	, sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
	WHERE (t5.contype = 'p' OR t5.contype = 'u' 
	OR ((idx.is_unique = 1) AND (idx.is_primary_key !=1 AND idx.is_unique_constraint !=1))) -- Only looking for unique indexes
	AND (CAST(c1.column_id AS smallint) = ANY (t5.conkey) OR ((idx.is_unique = 1) AND (idx.is_primary_key !=1 AND idx.is_unique_constraint !=1)))
	AND has_schema_privilege(s1.schema_id, 'USAGE');
  
GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_special_columns(
	"@table_name" sys.sysname,
	"@table_owner" sys.sysname = '',
	"@qualifier" sys.sysname = '',
	"@col_type" char(1) = 'R',
	"@scope" char(1) = 'T',
	"@nullable" char(1) = 'U',
	"@odbcver" int = 2
)
AS $$
DECLARE @special_col_type sys.sysname;
BEGIN
	IF (@qualifier != '') AND (LOWER(@qualifier) != LOWER(sys.db_name()))
 	BEGIN
 		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	 	
	END
	
	IF (LOWER(@col_type) = LOWER('V'))
	BEGIN
		THROW 33557097, N'TIMESTAMP datatype is not currently supported in Babelfish', 1;
	END
	
	IF (LOWER(@nullable) = LOWER('O'))
	BEGIN
		SELECT TOP 1 @special_col_type=constraint_type FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0)
		ORDER BY constraint_type, column_name;
	
		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT TOP 1 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				ORDER BY scope, column_name;
				
			END
			ELSE
			BEGIN
				SELECT TOP 1 
				SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
			END
			
		END
		
		ELSE 
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN  FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
		END
	END
	
	ELSE 
	BEGIN
		SELECT TOP 1 @special_col_type=constraint_type FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier))
		ORDER BY constraint_type, column_name;

		IF @special_col_type='u'
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT TOP 1
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				ORDER BY scope, column_name;
			END
			
			ELSE
			BEGIN
				SELECT TOP 1 SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				ORDER BY scope, column_name;
			END
			
		END
		ELSE
		BEGIN
			IF @scope='C'
			BEGIN
				SELECT 
				CAST(0 AS smallint) AS SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;	
			END
			
			ELSE
			BEGIN
				SELECT SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
				
		END
	END

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_special_columns_100(
	"@table_name" sys.sysname,
	"@table_owner" sys.sysname = '',
	"@qualifier" sys.sysname = '',
	"@col_type" char(1) = 'R',
	"@scope" char(1) = 'T',
	"@nullable" char(1) = 'U',
	"@odbcver" int = 2
)
AS $$
BEGIN
	EXEC sp_special_columns @table_name, @table_owner, @qualifier, @col_type, @scope, @nullable, @odbcver
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns_100 TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
SELECT DISTINCT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type NOT IN ('TRIGGER', 'TRUNCATE');
GRANT SELECT on sys.sp_table_privileges_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.sysname = '',
	"@fusepattern" sys.bit = 1
)
AS $$
BEGIN
	
	IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF @fusepattern = 1
  	BEGIN
		SELECT
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE LOWER(TABLE_NAME) LIKE LOWER(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) LIKE LOWER(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege;
	END
	ELSE 
  	BEGIN
		SELECT
		TABLE_QUALIFIER,
		TABLE_OWNER,
		TABLE_NAME,
		GRANTOR,
		GRANTEE,
		PRIVILEGE,
		IS_GRANTABLE FROM sys.sp_table_privileges_view
		WHERE LOWER(TABLE_NAME) = LOWER(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) = LOWER(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege;
	END
	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_type_radix_for_sp_columns_helper(IN type TEXT)
RETURNS SMALLINT
AS $$
DECLARE
  radix SMALLINT;
BEGIN
  CASE type
    WHEN 'tinyint' THEN radix = 10;
    WHEN 'money' THEN radix = 10;
    WHEN 'smallmoney' THEN radix = 10;
    WHEN 'sql_variant' THEN radix = 10;
  ELSE
    radix = NULL;
  END CASE;
  RETURN radix;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_length_for_sp_columns_helper(IN type TEXT, IN typelen INT, IN typemod INT)
RETURNS INT
AS $$
DECLARE
  length INT;
  precision INT;
BEGIN
  -- unknown tsql type
  IF type IS NULL THEN
    RETURN typelen::INT;
  END IF;

  IF typemod = -1 AND (type = 'varchar' OR type = 'nvarchar' OR type = 'varbinary') THEN
    length = 0;
    RETURN length;
  END IF;

  IF typelen != -1 THEN
    CASE type
    WHEN 'tinyint' THEN length = 1;
    WHEN 'date' THEN length = 6;
    WHEN 'smalldatetime' THEN length = 16;
    WHEN 'smallmoney' THEN length = 12;
    WHEN 'money' THEN length = 21;
    WHEN 'datetime' THEN length = 16;
    WHEN 'datetime2' THEN length = 16;
    WHEN 'datetimeoffset' THEN length = 20;
    WHEN 'time' THEN length = 12;
    WHEN 'timestamp' THEN length = 8;
    ELSE length = typelen;
    END CASE;
    RETURN length;
  END IF;

  CASE
  WHEN type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN length = typemod - 4;
  WHEN type in ('nchar', 'nvarchar') THEN length = (typemod - 4) * 2;
  WHEN type in ('text', 'image') THEN length = 2147483647;
  WHEN type = 'ntext' THEN length = 2147483646;
  WHEN type = 'xml' THEN length = 0;
  WHEN type = 'sql_variant' THEN length = 8000;
  WHEN type = 'money' THEN length = 21;
  WHEN type = 'sysname' THEN length = (typemod - 4) * 2;
  WHEN type in ('numeric', 'decimal') THEN
    precision = ((typemod - 4) >> 16) & 65535;
    length = precision + 2;
  ELSE
    length = typemod;
  END CASE;
  RETURN length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
  SELECT 
  CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,

  CASE WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp'
    THEN 8
    ELSE
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
  END AS PRECISION,

  CASE WHEN a.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
  END AS LENGTH,


  CASE WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
  END AS SCALE,


  CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
  case
    when t4."IS_NULLABLE" = 'YES' then CAST(1 AS smallint)
    else CAST(0 AS smallint)
  end AS NULLABLE,

  CAST(NULL AS varchar(254)) AS remarks,
  CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,

  CASE WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' THEN 8000::INT
    WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,

  CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
  CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME

  FROM pg_catalog.pg_class t1
     JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
     JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
     JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname = t4."COLUMN_NAME"
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = t5.TYPE_NAME)
    AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

create or replace function sys.sp_columns_100_internal(
	in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384) = '', 
    in_table_qualifier sys.nvarchar(384) = '',
    in_column_name sys.nvarchar(384) = '',
	in_NameScope int = 0,
    in_ODBCVer int = 2,
    in_fusepattern smallint = 1)
returns table (
	out_table_qualifier sys.sysname,
	out_table_owner sys.sysname,
	out_table_name sys.sysname,
	out_column_name sys.sysname,
	out_data_type smallint,
	out_type_name sys.sysname,
	out_precision int,
	out_length int,
	out_scale smallint,
	out_radix smallint,
	out_nullable smallint,
	out_remarks varchar(254),
	out_column_def sys.nvarchar(4000),
	out_sql_data_type smallint,
	out_sql_datetime_sub smallint,
	out_char_octet_length int,
	out_ordinal_position int,
	out_is_nullable varchar(254),
	out_ss_is_sparse smallint,
	out_ss_is_column_set smallint,
	out_ss_is_computed smallint,
	out_ss_is_identity smallint,
	out_ss_udt_catalog_name varchar(254),
	out_ss_udt_schema_name varchar(254),
	out_ss_udt_assembly_type_name varchar(254),
	out_ss_xml_schemacollection_catalog_name varchar(254),
	out_ss_xml_schemacollection_schema_name varchar(254),
	out_ss_xml_schemacollection_name varchar(254),
	out_ss_data_type sys.tinyint
)
as $$
begin
	IF in_fusepattern = 1 THEN
		return query
	    select table_qualifier, 
				table_owner,
				table_name,
				column_name,
				data_type,
				type_name,
				precision,
				length,
				scale,
				radix,
				nullable,
				remarks,
				column_def,
				sql_data_type,
				sql_datetime_sub,
				char_octet_length,
				ordinal_position,
				is_nullable,
				ss_is_sparse,
				ss_is_column_set,
				ss_is_computed,
				ss_is_identity,
				ss_udt_catalog_name,
				ss_udt_schema_name,
				ss_udt_assembly_type_name,
				ss_xml_schemacollection_catalog_name,
				ss_xml_schemacollection_schema_name,
				ss_xml_schemacollection_name,
				ss_data_type
		from sys.sp_columns_100_view
	    where lower(table_name) similar to lower(in_table_name)
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name)
		order by table_qualifier, table_owner, table_name, ordinal_position;
	ELSE 
		return query
	    select table_qualifier, precision from sys.sp_columns_100_view
	      where in_table_name = table_name
	      and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
	      and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
	      and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name)
		order by table_qualifier, table_owner, table_name, ordinal_position;
	END IF;
end;
$$
LANGUAGE plpgsql;

-- Need to rename and recreate the object due to previous incorrect definition.
ALTER FUNCTION sys.sp_describe_undeclared_parameters_internal RENAME TO sp_describe_undeclared_parameters_internal_deprecated_1_2;
-- BABEL-1797: initial support of sp_describe_undeclared_parameters
-- sys.sp_describe_undeclared_parameters_internal: internal function
-- For the result rows, can we create a template table for it?
CREATE OR REPLACE FUNCTION sys.sp_describe_undeclared_parameters_internal(
 tsqlquery sys.nvarchar(4000),
    params sys.nvarchar(4000) = NULL
)
returns table (
 parameter_ordinal int, -- NOT NULL
 name sys.sysname, -- NOT NULL
 suggested_system_type_id int, -- NOT NULL
 suggested_system_type_name sys.nvarchar(256),
 suggested_max_length smallint, -- NOT NULL
 suggested_precision sys.tinyint, -- NOT NULL
 suggested_scale sys.tinyint, -- NOT NULL
 suggested_user_type_id int, -- NOT NULL
 suggested_user_type_database sys.sysname,
 suggested_user_type_schema sys.sysname,
 suggested_user_type_name sys.sysname,
 suggested_assembly_qualified_type_name sys.nvarchar(4000),
 suggested_xml_collection_id int,
 suggested_xml_collection_database sys.sysname,
 suggested_xml_collection_schema sys.sysname,
 suggested_xml_collection_name sys.sysname,
 suggested_is_xml_document sys.bit, -- NOT NULL
 suggested_is_case_sensitive sys.bit, -- NOT NULL
 suggested_is_fixed_length_clr_type sys.bit, -- NOT NULL
 suggested_is_input sys.bit, -- NOT NULL
 suggested_is_output sys.bit, -- NOT NULL
 formal_parameter_name sys.sysname,
 suggested_tds_type_id int, -- NOT NULL
 suggested_tds_length int -- NOT NULL
)
AS 'babelfishpg_tsql', 'sp_describe_undeclared_parameters_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_undeclared_parameters_internal TO PUBLIC;

-- Need to rename and recreate the object due to previous incorrect definition.
ALTER PROCEDURE sys.sp_describe_undeclared_parameters RENAME TO sp_describe_undeclared_parameters_deprecated_1_2;

CREATE OR REPLACE PROCEDURE sys.sp_describe_undeclared_parameters (
 "@tsql" sys.nvarchar(4000),
    "@params" sys.nvarchar(4000) = NULL)
AS $$
BEGIN
 select * from sys.sp_describe_undeclared_parameters_internal(@tsql, @params);
 return 1;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_undeclared_parameters TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
-- primary key info
CAST(t2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = ref.table_schema) AS sys.sysname) AS PKTABLE_OWNER,
CAST(ref.table_name AS sys.sysname) AS PKTABLE_NAME,
CAST(coalesce(split_part(pkname_table.attoptions[1], '=', 2), ref.column_name) AS sys.sysname) AS PKCOLUMN_NAME,

-- foreign key info
CAST(t2.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname = fk.table_schema) AS sys.sysname) AS FKTABLE_OWNER,
CAST(fk.table_name AS sys.sysname) AS FKTABLE_NAME,
CAST(coalesce(split_part(fkname_table.attoptions[1], '=', 2), fk.column_name) AS sys.sysname) AS FKCOLUMN_NAME,

CAST(seq AS smallint) AS KEY_SEQ,
CASE
    WHEN map.update_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.update_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.update_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS UPDATE_RULE,

CASE
    WHEN map.delete_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.delete_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.delete_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(fk.constraint_name AS sys.sysname) AS FK_NAME,
CAST(ref.constraint_name AS sys.sysname) AS PK_NAME
        
FROM information_schema.referential_constraints AS map

-- join unique constraints (e.g. PKs constraints) to ref columns info
INNER JOIN information_schema.key_column_usage AS ref
    JOIN pg_catalog.pg_class p1 -- Need to join this in order to get oid for pkey's original bbf name
    JOIN sys.pg_namespace_ext p2 ON p1.relnamespace = p2.oid
    JOIN information_schema.columns p4 ON p1.relname = p4.table_name AND p1.relnamespace::regnamespace::text = p4.table_schema
    JOIN pg_constraint p5 ON p1.oid = p5.conrelid
    ON (p1.relname=ref.table_name AND p4.column_name=ref.column_name AND ref.table_schema = p2.nspname AND ref.table_schema = p4.table_schema)
    
    ON ref.constraint_catalog = map.unique_constraint_catalog
    AND ref.constraint_schema = map.unique_constraint_schema
    AND ref.constraint_name = map.unique_constraint_name

-- join fk columns to the correct ref columns using ordinal positions
INNER JOIN information_schema.key_column_usage AS fk
    ON  fk.constraint_catalog = map.constraint_catalog
    AND fk.constraint_schema = map.constraint_schema
    AND fk.constraint_name = map.constraint_name
    AND fk.position_in_unique_constraint = ref.ordinal_position

INNER JOIN pg_catalog.pg_class t1 
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name AND t1.relnamespace::regnamespace::text = t4.table_schema
    JOIN pg_constraint t5 ON t1.oid = t5.conrelid
    ON (t1.relname=fk.table_name AND t4.column_name=fk.column_name AND fk.table_schema = t2.nspname AND fk.table_schema = t4.table_schema)
    
-- get foreign key's original bbf name
JOIN pg_catalog.pg_attribute fkname_table
	ON (t1.oid = fkname_table.attrelid) AND (fk.column_name = fkname_table.attname)

-- get primary key's original bbf name
JOIN pg_catalog.pg_attribute pkname_table
	ON (p1.oid = pkname_table.attrelid) AND (ref.column_name = pkname_table.attname)
	
	, generate_series(1,16) seq -- BBF has max 16 columns per primary key
WHERE t5.contype = 'f'
AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

GRANT SELECT ON sys.sp_fkeys_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_fkeys(
	"@pktable_name" sys.sysname = '',
	"@pktable_owner" sys.sysname = '',
	"@pktable_qualifier" sys.sysname = '',
	"@fktable_name" sys.sysname = '',
	"@fktable_owner" sys.sysname = '',
	"@fktable_qualifier" sys.sysname = ''
)
AS $$
BEGIN

	IF coalesce(@pktable_name,'') = '' AND coalesce(@fktable_name,'') = ''
	BEGIN
		THROW 33557097, N'Primary or foreign key table name must be given.', 1;
	END

	IF (@pktable_qualifier != '' AND (SELECT sys.db_name()) != @pktable_qualifier) OR 
		(@fktable_qualifier != '' AND (SELECT sys.db_name()) != @fktable_qualifier)	
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END

	SELECT 
	PKTABLE_QUALIFIER,
	PKTABLE_OWNER,
	PKTABLE_NAME,
	PKCOLUMN_NAME,
	FKTABLE_QUALIFIER,
	FKTABLE_OWNER,
	FKTABLE_NAME,
	FKCOLUMN_NAME,
	KEY_SEQ,
	UPDATE_RULE,
	DELETE_RULE,
	FK_NAME,
	PK_NAME
	FROM sys.sp_fkeys_view
	WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR LOWER(pktable_name) = LOWER(@pktable_name))
		AND ((SELECT coalesce(@fktable_name,'')) = '' OR LOWER(fktable_name) = LOWER(@fktable_name))
		AND ((SELECT coalesce(@pktable_owner,'')) = '' OR LOWER(pktable_owner) = LOWER(@pktable_owner))
		AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR LOWER(pktable_qualifier) = LOWER(@pktable_qualifier))
		AND ((SELECT coalesce(@fktable_owner,'')) = '' OR LOWER(fktable_owner) = LOWER(@fktable_owner))
		AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR LOWER(fktable_qualifier) = LOWER(@fktable_qualifier))
		ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;

-- Need to rename and recreate the object due to previous incorrect definition.
ALTER FUNCTION sys.checksum RENAME TO checksum_deprecated_1_2;
CREATE OR REPLACE FUNCTION sys.checksum(VARIADIC arr TEXT[])
RETURNS INTEGER
AS 'babelfishpg_tsql', 'checksum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- Need to rename and recreate the object due to previous incorrect definition.
ALTER FUNCTION sys.babelfish_inconsistent_metadata RENAME TO babelfish_inconsistent_metadata_deprecated_1_2;
CREATE OR REPLACE FUNCTION sys.babelfish_inconsistent_metadata(return_consistency boolean default false)
RETURNS table (
	object_type varchar(32),
	schema_name varchar(128),
	object_name varchar(128),
	detail jsonb
) AS 'babelfishpg_tsql', 'babelfish_inconsistent_metadata' LANGUAGE C;

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
	role  := TRIM(trailing from LOWER(role));
	login := TRIM(trailing from LOWER(login));
	
	login_valid = (login = suser_name()) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				LOWER(name) = login 
				AND type = 'S'));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' THEN
    	RETURN 1;
	
 	ELSIF role = 'sysadmin' THEN
	  	has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role IN (
            'serveradmin',
            'securityadmin',
            'setupadmin',
            'securityadmin',
            'processadmin',
            'dbcreator',
            'diskadmin',
            'bulkadmin') THEN 
    	RETURN 0;
 	
    ELSE
 		  RETURN NULL;
 	END IF;
	
 	EXCEPTION WHEN OTHERS THEN
	 	  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT 
CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER, 

CASE 
	WHEN p.prokind = 'p' THEN CAST(concat(p.proname, ';1') AS sys.nvarchar(134))
	ELSE CAST(concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p 

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id 
INNER JOIN sys.databases d ON d.database_id = sys.db_id()
WHERE has_schema_privilege(s1.schema_id, 'USAGE')

UNION 

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE 
	WHEN prokind = 'p' THEN cast(concat(proname, ';1') AS sys.nvarchar(134))
	ELSE cast(concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM    pg_catalog.pg_namespace n 
JOIN    pg_catalog.pg_proc p 
ON      pronamespace = n.oid   
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

GRANT SELECT ON sys.sp_stored_procedures_view TO PUBLIC;

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
					WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
					AND (LOWER(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
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
				WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
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
			WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
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
			WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, -2)) LIKE LOWER(@sp_name))
				AND ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

CREATE OR REPLACE PROCEDURE xp_qv(IN nvarchar(256), IN nvarchar(256))
	   AS 'babelfishpg_tsql', 'xp_qv_internal' LANGUAGE C;

CREATE OR REPLACE PROCEDURE sys.create_xp_qv_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_qv_in_master_dbo_internal';

CALL sys.create_xp_qv_in_master_dbo();
ALTER PROCEDURE master_dbo.xp_qv OWNER TO sysadmin;
DROP PROCEDURE sys.create_xp_qv_in_master_dbo;

CREATE OR REPLACE FUNCTION sys.servicename()
        RETURNS sys.NVARCHAR(128)  AS 'babelfishpg_tsql' LANGUAGE C;

CREATE FUNCTION fulltextserviceproperty (TEXT)
  RETURNS sys.int AS 'babelfishpg_tsql', 'fulltextserviceproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- JSON Functions
CREATE OR REPLACE FUNCTION sys.isjson(json_string text)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_isjson' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_value(json_string text, path text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_json_value' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_query(json_string text, path text default '$')
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_json_query' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.sp_statistics_view AS
SELECT
CAST(t3."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t3."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(NULL AS smallint) AS NON_UNIQUE,
CAST(NULL AS sys.sysname) AS INDEX_QUALIFIER,
CAST(NULL AS sys.sysname) AS INDEX_NAME,
CAST(0 AS smallint) AS TYPE,
CAST(NULL AS smallint) AS SEQ_IN_INDEX,
CAST(NULL AS sys.sysname) AS COLUMN_NAME,
CAST(NULL AS sys.varchar(1)) AS COLLATION,
CAST(t1.reltuples AS int) AS CARDINALITY,
CAST(t1.relpages AS int) AS PAGES,
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN information_schema_tsql.columns t3 ON (t1.relname = t3."TABLE_NAME" AND s1.name = t3."TABLE_SCHEMA")
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
UNION
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(t1.relname AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
CASE 
WHEN t8.oid > 0 THEN CAST(t6.relname AS sys.sysname)
ELSE CAST(SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname) 
END AS INDEX_NAME,
CASE
WHEN t7.starelid > 0 THEN CAST(0 AS smallint)
ELSE
	CASE
	WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
	ELSE CAST(3 AS smallint)
	END
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND s1.name = t4."TABLE_SCHEMA")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

create or replace function sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname = '',
    in_table_qualifier sys.sysname = '',
    in_index_name sys.sysname = '',
	in_is_unique char = 'N',
	in_accuracy char = 'Q'
)
returns table(
    out_table_qualifier sys.sysname,
    out_table_owner sys.sysname,
    out_table_name sys.sysname,
	out_non_unique smallint,
	out_index_qualifier sys.sysname,
	out_index_name sys.sysname,
	out_type smallint,
	out_seq_in_index smallint,
	out_column_name sys.sysname,
	out_collation sys.varchar(1),
	out_cardinality int,
	out_pages int,
	out_filter_condition sys.varchar(128)
)
as $$
begin
    return query
    select * from sys.sp_statistics_view
    where in_table_name = table_name
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name)
        and ((in_is_unique = 'Y' and (non_unique IS NULL or non_unique = 0)) or (in_is_unique = 'N'))
    order by non_unique, type, index_name, seq_in_index;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_statistics_100(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
    select out_table_qualifier as TABLE_QUALIFIER,
            out_table_owner as TABLE_OWNER,
            out_table_name as TABLE_NAME,
			out_non_unique as NON_UNIQUE,
			out_index_qualifier as INDEX_QUALIFIER,
			out_index_name as INDEX_NAME,
			out_type as TYPE,
			out_seq_in_index as SEQ_IN_INDEX,
			out_column_name as COLUMN_NAME,
			out_collation as COLLATION,
			out_cardinality as CARDINALITY,
			out_pages as PAGES,
			out_filter_condition as FILTER_CONDITION
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1 
  JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
  JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
  JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
  JOIN pg_constraint t5 ON t1.oid = t5.conrelid
  , generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
  AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
  AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597
create or replace function sys.sp_pkeys_internal(
  in_table_name sys.nvarchar(384),
  in_table_owner sys.nvarchar(384) = '',
  in_table_qualifier sys.nvarchar(384) = ''
)
returns table(
  out_table_qualifier sys.sysname,
  out_table_owner sys.sysname,
  out_table_name sys.sysname,
  out_column_name sys.sysname,
  out_key_seq smallint,
  out_pk_name sys.sysname
)
as $$
begin
  return query
  select * from sys.sp_pkeys_view
  where in_table_name = table_name
    and table_owner = coalesce(in_table_owner,'dbo')
    and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
  order by table_qualifier, table_owner, table_name, key_seq;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
  "@table_name" sys.nvarchar(384),
  "@table_owner" sys.nvarchar(384) = 'dbo',
  "@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
  select out_table_qualifier as table_qualifier,
      out_table_owner as table_owner,
      out_table_name as table_name,
      out_column_name as column_name,
      out_key_seq as key_seq,
      out_pk_name as pk_name
  from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
  "@table_name" sys.nvarchar(384),
  "@table_owner" sys.nvarchar(384) = 'dbo',
  "@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
  select out_table_qualifier as TABLE_QUALIFIER,
      out_table_owner as TABLE_OWNER,
      out_table_name as TABLE_NAME,
      out_column_name as COLUMN_NAME,
      out_key_seq as KEY_SEQ,
      out_pk_name as PK_NAME
  from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_dbaccess(database_name SYSNAME) RETURNS INTEGER AS 
'babelfishpg_tsql', 'has_dbaccess'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
	"@data_type" int = 0,
	"@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
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
               CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';
CREATE TABLE sys.babelfish_configurations (
    configuration_id INT,
    name sys.nvarchar(35),
    value sys.sql_variant,
    minimum sys.sql_variant,
    maximum sys.sql_variant,
    value_in_use sys.sql_variant,
    description sys.nvarchar(255),
    is_dynamic sys.BIT,
    is_advanced sys.BIT,
    comment_syscurconfigs sys.nvarchar(255),
    comment_sysconfigures sys.nvarchar(255)
) WITH (OIDS = FALSE);

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_configurations', '');

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

-- The value and value_in_use is set to 1 because SSMS-Babelfish connectivity requires it.
INSERT INTO sys.babelfish_configurations
    VALUES (16387,
            'SMO and DMO XPs',
            1,
            0,
            1,
            1,
            'Enable or disable SMO and DMO XPs',
            sys.bitin('1'),
            sys.bitin('1'),
            'Enable or disable SMO and DMO XPs',
            'Enable or disable SMO and DMO XPs'
            );

CREATE OR REPLACE PROCEDURE sys.sp_columns (
  "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
  "@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
  select out_table_qualifier as TABLE_QUALIFIER, 
      out_table_owner as TABLE_OWNER,
      out_table_name as TABLE_NAME,
      out_column_name as COLUMN_NAME,
      out_data_type as DATA_TYPE,
      out_type_name as TYPE_NAME,
      out_precision as PRECISION,
      out_length as LENGTH,
      out_scale as SCALE,
      out_radix as RADIX,
      out_nullable as NULLABLE,
      out_remarks as REMARKS,
      out_column_def as COLUMN_DEF,
      out_sql_data_type as SQL_DATA_TYPE,
      out_sql_datetime_sub as SQL_DATETIME_SUB,
      out_char_octet_length as CHAR_OCTET_LENGTH,
      out_ordinal_position as ORDINAL_POSITION,
      out_is_nullable as IS_NULLABLE,
      out_ss_data_type as SS_DATA_TYPE
  from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
    sys.babelfish_truncate_identifier(@table_owner),
    sys.babelfish_truncate_identifier(@table_qualifier),
    sys.babelfish_truncate_identifier(@column_name), @NameScope,@ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_columns_100 (
  "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '', 
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
  "@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
  select out_table_qualifier as TABLE_QUALIFIER, 
      out_table_owner as TABLE_OWNER,
      out_table_name as TABLE_NAME,
      out_column_name as COLUMN_NAME,
      out_data_type as DATA_TYPE,
      out_type_name as TYPE_NAME,
      out_precision as PRECISION,
      out_length as LENGTH,
      out_scale as SCALE,
      out_radix as RADIX,
      out_nullable as NULLABLE,
      out_remarks as REMARKS,
      out_column_def as COLUMN_DEF,
      out_sql_data_type as SQL_DATA_TYPE,
      out_sql_datetime_sub as SQL_DATETIME_SUB,
      out_char_octet_length as CHAR_OCTET_LENGTH,
      out_ordinal_position as ORDINAL_POSITION,
      out_is_nullable as IS_NULLABLE,
      out_ss_is_sparse as SS_IS_SPARSE,
      out_ss_is_column_set as SS_IS_COLUMN_SET,
      out_ss_is_computed as SS_IS_COMPUTED,
      out_ss_is_identity as SS_IS_IDENTITY,
      out_ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
      out_ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
      out_ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
      out_ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
      out_ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
      out_ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
      out_ss_data_type as SS_DATA_TYPE
  from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
    sys.babelfish_truncate_identifier(@table_owner),
    sys.babelfish_truncate_identifier(@table_qualifier),
    sys.babelfish_truncate_identifier(@column_name), @NameScope,@ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

CREATE VIEW information_schema_tsql.table_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(nr.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(extr.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype NOT IN ('t', 'x')
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nr.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		  AND  extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.role_id(role_name SYS.SYSNAME)
RETURNS INT
AS 'babelfishpg_tsql', 'role_id'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.role_id TO PUBLIC;

CREATE PROCEDURE sys.sp_helpuser("@name_in_db" sys.SYSNAME = NULL) AS
$$
BEGIN
	IF @name_in_db IS NULL
	BEGIN
		SELECT CAST(Ext.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext.orig_username = 'dbo' THEN 'db_owner' ELSE 'PUBLIC' END AS SYS.SYSNAME) AS 'RoleName',
			   CAST(Ext.login_name AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base.oid AS INT) AS 'UserID',
			   CAST(CAST(Base.oid AS INT) AS SYS.VARBINARY(85))  AS 'SID'
			FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
			ON Base.rolname = Ext.rolname
			LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt
			ON LogExt.rolname = Ext.orig_username
			WHERE Ext.database_name = DB_NAME()
	END
    ELSE IF @name_in_db = 'db_owner'
	BEGIN
		-- simplification of role case, since no user defined roles exist yet
		SELECT CAST('db_owner' AS SYS.SYSNAME) AS 'Role_name',
			   ROLE_ID('db_owner') AS 'Role_id',
			   CAST('dbo' AS SYS.SYSNAME) AS Users_in_role,
			   USER_ID('dbo') AS 'Userid';
	END
	ELSE IF EXISTS (SELECT 1
					  FROM sys.babelfish_authid_user_ext
						WHERE (orig_username = @name_in_db
						      OR lower(orig_username) = lower(@name_in_db))
						      AND database_name = DB_NAME())
	BEGIN
		SELECT CAST(Ext.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext.orig_username = 'dbo' THEN 'db_owner' ELSE 'PUBLIC' END AS SYS.SYSNAME) AS 'RoleName',
			   CAST(Ext.login_name AS SYS.SYSNAME) AS 'LoginName',
			   CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
			   CAST(Ext.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
			   CAST(Base.oid AS INT) AS 'UserID',
			   CAST(CAST(Base.oid AS INT) AS SYS.VARBINARY(85))  AS 'SID'
			FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
			ON Base.rolname = Ext.rolname
			LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt
			ON LogExt.rolname = Ext.orig_username
			WHERE Ext.database_name = DB_NAME()
				  AND (orig_username = @name_in_db OR lower(orig_username) = lower(@name_in_db));
	END
	ELSE 
		RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_helpuser TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF sys.user_name() != 'dbo' THEN
    RAISE EXCEPTION 'user does not have permission';
  END IF;

  IF lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE VERBOSE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
