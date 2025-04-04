-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.2.0'" to load this file. \quit
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) RENAME TO bbf_numeric_round_deprecated_5_2_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_round_deprecated_5_2_0');


DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) RENAME TO bbf_numeric_trunc_deprecated_5_2_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_numeric_trunc_deprecated_5_2_0');

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS sys.DECIMAL AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER)
RETURNS sys.INT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number INTEGER, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER) TO PUBLIC;



CREATE OR REPLACE FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER)
RETURNS sys.BIGINT
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.BIGINT, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER)
RETURNS sys.money
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.fixeddecimal, length INTEGER, function INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER) TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER)
RETURNS sys.float
AS $$
BEGIN
    RETURN sys.round(number::PG_CATALOG.NUMERIC, length, function);
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.round(number sys.float, length INTEGER, function INTEGER) TO PUBLIC;



CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(suser_id());
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

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
  , cast(
		coalesce(
			(select pg_catalog.string_agg(
				case
					when option like 'bbf_original_rel_name=%' then substring(option, 23 /* prefix length */)
					else null
				end, ',')
			from unnest(I.reloptions) as option),
			I.relname)
		AS sys.sysname) AS name
  , cast(case when X.indisclustered then 1 else 2 end as sys.tinyint) as type
  , cast(case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as sys.nvarchar(60)) as type_desc
  , cast(X.indisunique as sys.bit) as is_unique
  , cast(case when ps.scheme_id is null then 1 else ps.scheme_id end as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(X.indisprimary as sys.bit) as is_primary_key
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
inner join pg_class I on I.oid = X.indexrelid
inner join pg_class ptbl on ptbl.oid = X.indrelid and ptbl.relispartition = false
inner join pg_namespace nsp on nsp.oid = I.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
left join sys.babelfish_partition_depend pd on
  (ext.orig_name  = pd.schema_name COLLATE sys.database_default
   and CAST(ptbl.relname AS sys.nvarchar(128)) = pd.table_name COLLATE sys.database_default and pd.dbid = sys.db_id() and ptbl.relkind = 'p')
left join sys.babelfish_partition_scheme ps on (ps.partition_scheme_name = pd.partition_scheme_name and ps.dbid = sys.db_id())
-- check if index is a unique constraint
left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
where 
-- index is active
X.indislive 
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
  , cast(case when ps.scheme_id is null then 1 else ps.scheme_id end as int) as data_space_id
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
left join sys.babelfish_partition_depend pd on
  (ext.orig_name = pd.schema_name COLLATE sys.database_default
   and CAST(t.relname AS sys.nvarchar(128)) = pd.table_name COLLATE sys.database_default and pd.dbid = sys.db_id())
left join sys.babelfish_partition_scheme ps on (ps.partition_scheme_name = pd.partition_scheme_name and ps.dbid = sys.db_id())
where (t.relkind = 'r' or t.relkind = 'p')
and t.relispartition = false
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
order by object_id, type_desc;

CREATE OR REPLACE FUNCTION sys.babelfish_construct_unique_index_name(index_name TEXT, table_name TEXT)
RETURNS TEXT AS 'babelfishpg_tsql', 'bbf_construct_unique_index_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_word_parse(
	IN "@input" sys.nvarchar(776),
	IN "@objtype" sys.varchar(13),
	INOUT "@subname" sys.nvarchar(776),
	INOUT "@curr_relname" sys.nvarchar(776),
	INOUT "@schemaname" sys.nvarchar(776),
	INOUT "@dbname" sys.nvarchar(776)
)
AS $$
BEGIN
	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row, * 
	INTO #sp_rename_temptable 
	FROM sys.babelfish_split_identifier(@input) ORDER BY row DESC;

	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as id, * 
	INTO #sp_rename_temptable2 
	FROM #sp_rename_temptable;
	
	DECLARE @row_count INT;
	SELECT @row_count = COUNT(*) FROM #sp_rename_temptable2;

	IF @objtype = 'COLUMN' OR @objtype = 'INDEX'
		BEGIN
			IF @row_count = 1
				BEGIN
					IF @objtype = 'COLUMN'
						THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.', 1;
					ELSE
						THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (INDEX) is wrong.', 1;
				END
			ELSE IF @row_count > 4
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					IF @row_count > 1
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SELECT @curr_relname = value FROM #sp_rename_temptable2 WHERE id = 2;
							SET @schemaname = sys.schema_name();

						END
					IF @row_count > 2
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 3;
						END
					IF @row_count > 3
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 4;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
	ELSE
		BEGIN
			IF @row_count > 3
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					SET @curr_relname = NULL;
					IF @row_count > 0
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SET @schemaname = sys.schema_name();
						END
					IF @row_count > 1
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 2;
						END
					IF @row_count > 2
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 3;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776) = NULL,
	IN "@newname" sys.SYSNAME = NULL,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET @objtype = sys.TRIM(@objtype);
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	ELSE IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
		END
	ELSE IF @objtype = 'DATABASE'
		BEGIN
			exec sys.sp_renamedb @objname, @newname;
		END
	ELSE
		BEGIN
			DECLARE @subname sys.nvarchar(776);
			DECLARE @schemaname sys.nvarchar(776);
			DECLARE @dbname sys.nvarchar(776);
			DECLARE @curr_relname sys.nvarchar(776);
			
			EXEC sys.babelfish_sp_rename_word_parse @objname, @objtype, @subname OUT, @curr_relname OUT, @schemaname OUT, @dbname OUT;

			DECLARE @currtype char(2);

			IF @objtype = 'COLUMN'
				BEGIN
					DECLARE @col_count INT;
					SELECT @col_count = COUNT(*)FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @curr_relname and COLUMN_NAME = @subname;
					IF @col_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'CO';
				END
			ELSE IF @objtype = 'INDEX'
				BEGIN
					DECLARE @relid INT = 0;
					DECLARE @index_count INT;
					SELECT @relid = object_id FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
						WHERE s1.name = @schemaname AND o1.name = @curr_relname;
					IF @relid = 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SELECT @index_count = COUNT(*) FROM pg_index i JOIN pg_class c ON i.indexrelid = c.oid
						WHERE i.indrelid = @relid AND c.relname = sys.babelfish_construct_unique_index_name(@subname, @curr_relname);
					IF @index_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'IX';
				END
			ELSE IF @objtype = 'USERDATATYPE'
				BEGIN
					DECLARE @alias_count INT;
					SELECT @alias_count = COUNT(*) FROM sys.types t1 INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND t1.name = @subname;
					IF @alias_count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @alias_count < 1
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'AL';				
				END
			ELSE IF @objtype = 'OBJECT'
				BEGIN
					DECLARE @count INT;
					SELECT type INTO #tempTable FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND o1.name = @subname;
					SELECT @count = COUNT(*) FROM #tempTable;

					IF @count < 1
						BEGIN
							-- sys.objects does not show routines which current user cannot execute but
							-- roles like db_ddladmin allow renaming a procedure even though they cannot
							-- execute it, so search again in pg_proc if count is zero
							DROP TABLE #tempTable;
							SELECT CAST(CASE 
											WHEN p.prokind = 'p' THEN 'P'
											WHEN p.prokind = 'a' THEN 'AF'
											WHEN format_type(p.prorettype, NULL) = 'trigger' THEN 'TR'
											ELSE 'FN'
										END as sys.bpchar(2)) AS type INTO #tempTable
							FROM pg_proc p INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id
							WHERE s1.name = @schemaname AND CAST(p.proname AS sys.sysname) = @subname;
							SELECT @count = COUNT(*) FROM #tempTable;
						END
					IF @count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @count < 1
						BEGIN
							-- TABLE TYPE: check if there is a match in sys.table_types (if we cannot alter sys.objects table_type naming)
							SELECT @count = COUNT(*) FROM sys.table_types tt1 INNER JOIN sys.schemas s1 ON tt1.schema_id = s1.schema_id 
							WHERE s1.name = @schemaname AND tt1.name = @subname;
							IF @count > 1
								BEGIN
									THROW 33557097, N'There are multiple objects with the given @objname.', 1;
								END
							ELSE IF @count < 1
								BEGIN
									THROW 33557097, N'There is no object with the given @objname.', 1;
								END
							ELSE
								BEGIN
									SET @currtype = 'TT'
								END
						END
					IF @currtype IS NULL
						BEGIN
							SELECT @currtype = type from #tempTable;
						END
					IF @currtype = 'TR' OR @currtype = 'TA'
						BEGIN
							DECLARE @physical_schema_name sys.nvarchar(776) = '';
							SELECT @physical_schema_name = nspname FROM sys.babelfish_namespace_ext WHERE dbid = sys.db_id() AND orig_name = @schemaname;
							SELECT @curr_relname = relname FROM pg_catalog.pg_trigger tr LEFT JOIN pg_catalog.pg_class c ON tr.tgrelid = c.oid LEFT JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid 
							WHERE tr.tgname = @subname AND n.nspname = @physical_schema_name;
						END
				END
			ELSE
				BEGIN
					THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
				END
			EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype, @curr_relname;
			PRINT 'Caution: Changing any part of an object name could break scripts and stored procedures.';
		END
END;
$$;
CREATE OR REPLACE FUNCTION sys.db_id() RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE STABLE;

CREATE OR REPLACE FUNCTION sys.db_name() RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE STABLE;


DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_addlinkedserver;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_addlinkedsrvlogin;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_droplinkedsrvlogin;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_dropserver;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_testlinkedserver;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

DO $$
BEGIN
    BEGIN
        DROP PROCEDURE master_dbo.sp_enum_oledb_providers;
    EXCEPTION
        WHEN OTHERS THEN
            raise NOTICE '%', SQLERRM;
    END;
END;
$$;

-- This is a temporary procedure which is called during upgrade to alter
-- default privileges on guest the schemas where the schema owner is guest
CREATE OR REPLACE PROCEDURE sys.babelfish_revoke_create_privilege_from_guest_user()
LANGUAGE C
AS 'babelfishpg_tsql', 'revoke_create_privilege_from_guest_user';

CALL sys.babelfish_revoke_create_privilege_from_guest_user();

-- Drop this procedure after it gets executed once.

DROP PROCEDURE sys.babelfish_revoke_create_privilege_from_guest_user();
DO $$
BEGIN
IF NOT EXISTS(
    SELECT 1 FROM pg_class c JOIN pg_attribute a ON a.attrelid = c.oid 
      WHERE c.relname = 'babelfish_partition_function' COLLATE sys.database_default
      AND c.relnamespace::regnamespace::text = 'sys' COLLATE sys.database_default
	  AND a.attname = 'input_parameter_collation' COLLATE sys.database_default)
THEN
    -- Add input_parameter_collation column in sys.babelfish_partition_function.
    SET allow_system_table_mods = on;
    ALTER TABLE sys.babelfish_partition_function ADD COLUMN input_parameter_collation NAME;
    RESET allow_system_table_mods;

    -- Update the input_parameter_collation column in sys.babelfish_partition_function
    -- catalog for collatable datatypes with default database collation.
    UPDATE sys.babelfish_partition_function pf
    SET input_parameter_collation = db.default_collation
    FROM sys.babelfish_sysdatabases db 
    WHERE pf.dbid = db.dbid 
    AND pf.input_parameter_type IN ('CHAR', 'VARCHAR', 'NCHAR', 'NVARCHAR');
END IF;
END $$;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT,
														  IN p_floatval FLOAT,
														  IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
	v_style SMALLINT;
	v_format VARCHAR COLLATE "C";
	v_floatval NUMERIC := abs(p_floatval);
	v_digits SMALLINT;
	v_integral_digits SMALLINT;
	v_decimal_digits SMALLINT;
	v_sign SMALLINT := sign(p_floatval);
	v_result TEXT;
	v_res_length SMALLINT;
	MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
	v_style := floor(p_style)::SMALLINT;
	IF (v_style = 0) THEN
		v_digits := length(v_floatval::NUMERIC::TEXT);
		v_decimal_digits := scale(v_floatval);
		IF (v_decimal_digits > 0) THEN
			v_integral_digits := v_digits - v_decimal_digits - 1;
		ELSE
			v_integral_digits := v_digits;
		END IF;
		IF (v_floatval >= 999999.5) THEN
			v_format := '9D99999EEEE';
			v_result := to_char(v_sign::NUMERIC * ceiling(v_floatval), v_format);
			v_result := to_char(substring(v_result, 1, 8)::NUMERIC, 'FM9D99999')::NUMERIC::TEXT || substring(v_result, 9);
		ELSE
            IF (6 - v_integral_digits < v_decimal_digits) AND (trunc(abs(v_floatval)) != 0) THEN
                v_decimal_digits := 6 - v_integral_digits;
            ELSIF (6 - v_integral_digits < v_decimal_digits) THEN
                v_decimal_digits := 6;
            END IF;
			v_format := (pow(10, v_integral_digits)-10)::TEXT || 'D';
			IF (v_decimal_digits > 0) THEN
				v_format := v_format || (pow(10, v_decimal_digits)-1)::TEXT;
			END IF;
			v_result := to_char(p_floatval, v_format);
		END IF;
	ELSIF (v_style = 1) THEN
		v_format := '9D9999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSIF (v_style = 2) THEN
		v_format := '9D999999999999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSIF (v_style = 3) THEN
		v_format := '9D9999999999999999EEEE';
		v_result := to_char(p_floatval, v_format);
	ELSE
		RAISE invalid_parameter_value;
	END IF;

	v_res_length := substring(p_datatype COLLATE "C", MASK_REGEXP)::SMALLINT;
	IF v_res_length IS NULL THEN
		RETURN ltrim(v_result);
	ELSE
		RETURN rpad(ltrim(v_result),  v_res_length, ' ');
	END IF;
EXCEPTION
	WHEN invalid_parameter_value THEN
		RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from FLOAT to a character string.', v_style),
					DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
					HINT := 'Change "style" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

-- SERVER_PRINCIPALS
CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
    WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_LOGIN'
    ELSE NULL
  END
  AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(Ext.is_fixed_role AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE (pg_has_role(suser_id(), 'sysadmin'::TEXT, 'MEMBER') 
  OR pg_has_role(suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Ext.orig_loginname = suser_name()
  OR Ext.orig_loginname = (SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = CURRENT_DATABASE()) COLLATE sys.database_default
  OR Ext.type = 'R')
  AND Ext.type != 'Z'
UNION ALL
SELECT
CAST('public' AS SYS.SYSNAME) AS name,
CAST(2 AS INT) AS principal_id,
CAST(CAST(2 as INT) as sys.varbinary(85)) AS sid,
CAST('R' AS CHAR(1)) as type,
CAST('SERVER_ROLE' AS NVARCHAR(60)) AS type_desc,
CAST(0 AS INT) AS is_disabled,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(NULL AS SYS.SYSNAME) AS default_database_name,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(NULL AS INT) AS credential_id,
CAST(1 AS INT) AS owning_principal_id,
CAST(0 AS sys.BIT) AS is_fixed_role;

GRANT SELECT ON sys.server_principals TO PUBLIC;

-- DATABASE_PRINCIPALS
CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
-- PG reserves these oid > 16383 AND oid < 16400 for PG specific internal roles.
-- Any change here in the oid should be reflected in sys.database_role_members view as well.
CAST(
  CASE Ext.orig_username
    WHEN 'db_owner' THEN 16384
    WHEN 'db_accessadmin' THEN 16385
    WHEN 'db_securityadmin' THEN 16386
    WHEN 'db_ddladmin' THEN 16387
    WHEN 'db_datareader' THEN 16390
    WHEN 'db_datawriter' THEN 16391
    ELSE Base.oid
  END AS INT) AS principal_id,
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
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'db_securityadmin', 'db_accessadmin', 'db_datareader', 'db_datawriter', 'db_ddladmin', 'guest') -- system users should always be visible
  OR bbf_is_role_member(current_user, Ext.rolname)) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(
  CASE name
    WHEN 'public' THEN 1
    WHEN 'INFORMATION_SCHEMA' THEN 3
    WHEN 'sys' THEN 4
  END AS INT) AS principal_id,
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

GRANT SELECT ON sys.database_principals TO PUBLIC;

-- user_token
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
CAST(1 AS INT) AS principal_id,
CAST(CAST(1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

-- login_token
CREATE OR REPLACE VIEW sys.login_token
AS SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
ELSE 'SQL LOGIN' END AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.orig_loginname = sys.suser_name()
AND Ext.type in ('S','U')
UNION ALL
SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST('SERVER ROLE' AS sys.nvarchar(128)) AS type,
CAST ('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.type = 'R'
AND bbf_is_member_of_role_nosuper(sys.suser_id(), Base.oid)
UNION ALL
SELECT
CAST(2 AS INT) AS principal_id,
CAST(CAST(2 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('SERVER ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE;

GRANT SELECT ON sys.login_token TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.loginproperty(login_name sys.sysname, property_name sys.nvarchar(128)) 
RETURNS sys.nvarchar(128) 
AS $$ 
DECLARE 
BEGIN 
    RETURN NULL; 
END; 
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.fn_varbintohexsubstring(set_prefix INT, expression sys.varbinary(128), start_offset INT, length_to_return INT) 
RETURNS sys.nvarchar(128) 
AS $$ 
DECLARE 
BEGIN 
    RETURN NULL; 
END; 
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE VIEW sys.server_permissions 
AS
SELECT
  CAST(0 as sys.tinyint) AS class,
  CAST(NULL as sys.nvarchar(60)) AS class_desc,
  CAST(NULL as INT) AS major_id,
  CAST(NULL as INT) AS minor_id,
  CAST(NULL as INT) AS grantee_principal_id,
  CAST(NULL as INT) AS grantor_principal_id,
  CAST(NULL as sys.BPCHAR(4)) AS type,
  CAST(NULL as sys.nvarchar(128)) AS permission_name,
  CAST(NULL as sys.BPCHAR(1)) AS state,
  CAST(NULL as sys.nvarchar(60)) AS state_desc
WHERE FALSE;
GRANT SELECT ON sys.server_permissions TO PUBLIC;

CREATE OR REPLACE VIEW sys.credentials 
AS
SELECT
  CAST(NULL as INT) AS credential_id,
  CAST(NULL as sys.sysname) AS name,
  CAST(NULL as sys.nvarchar(4000)) AS credential_identity,
  CAST(NULL as sys.datetime) AS create_date,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(NULL as sys.nvarchar(100)) AS target_type,
  CAST(NULL as INT) AS target_id
WHERE FALSE;
GRANT SELECT ON sys.credentials TO PUBLIC;

CREATE VIEW sys.sql_logins AS
SELECT
    CAST(NULL as sys.sysname) AS name,
    CAST(NULL as INT) AS principal_id,
    CAST(NULL as sys.VARBINARY(85)) AS sid,
    CAST(NULL as sys.BPCHAR(1)) AS type,
    CAST(NULL as sys.nvarchar(60)) AS type_desc,
    CAST(NULL as INT) AS is_disabled,
    CAST(NULL as sys.DATETIME) AS create_date,
    CAST(NULL as sys.DATETIME) AS modify_date,
    CAST(NULL as sys.sysname) AS default_database_name,
    CAST(NULL as sys.sysname) AS default_language_name,
    CAST(NULL as INT) AS credential_id,
    CAST(NULL as INT) AS owning_principal_id,
    CAST(0 as sys.BIT) AS is_fixed_role,
    CAST(0 as sys.BIT) AS is_policy_checked,
    CAST(0 as sys.BIT) AS is_expiration_checked,
    CAST(NULL as sys.varbinary(256)) AS password_hash
WHERE FALSE;
GRANT SELECT ON sys.sql_logins TO PUBLIC;
/* Shows the list of objects where the object owner is not same as schema owner */
/* Covers tables, views, functions, procedures, sequences, types */
CREATE OR REPLACE FUNCTION sys.get_schema_object_ownership()
RETURNS TABLE (
    schema_name name,
    schema_owner_name name,
    object_name name,
    object_owner_name name,
    object_type text
) AS
$$
BEGIN
    RETURN QUERY
    WITH common_schemas AS (
      SELECT
          b.nspname AS schema_name
      FROM
          sys.babelfish_namespace_ext b
      JOIN
          pg_namespace n ON b.nspname = n.nspname
      JOIN
          pg_roles r ON n.nspowner = r.oid
      JOIN
          sys.babelfish_authid_user_ext u ON r.rolname = u.rolname
      WHERE
          u.orig_username <> 'db_owner'
    )
    -- First query for tables, views, index, types and sequences
    -- table types are considered as tables
    SELECT 
        cs.schema_name::name,
        r1.rolname,
        c.relname,
        r2.rolname,
        CASE c.relkind
            WHEN 'r' THEN 'table'
            WHEN 'p' THEN 'table'
            WHEN 'v' THEN 'view'
            WHEN 'S' THEN 'sequence'
            ELSE c.relkind::text
        END
    FROM
        common_schemas cs
    JOIN 
        pg_namespace n ON cs.schema_name = n.nspname
    JOIN
        pg_class c ON n.oid = c.relnamespace
    JOIN
        pg_roles r1 ON n.nspowner = r1.oid
    JOIN
        pg_roles r2 ON c.relowner = r2.oid
    WHERE 
        c.relkind IN ('r', 'p', 'v', 'S')
        AND c.relname NOT LIKE '@%' -- Ignore temporary tables
        AND r1.rolname <> r2.rolname
    UNION ALL
    -- Second query for functions and procedures
    -- triggers are considered as functions
    SELECT 
        cs.schema_name::name,
        r1.rolname,
        p.proname,
        r2.rolname,
        CASE p.prokind
            WHEN 'f' THEN 'function'
            WHEN 'p' THEN 'procedure'
            ELSE p.prokind::text
        END
    FROM 
        common_schemas cs
    JOIN 
        pg_namespace n ON cs.schema_name = n.nspname
    JOIN 
        pg_roles r1 ON n.nspowner = r1.oid
    JOIN 
        pg_proc p ON n.oid = p.pronamespace
    JOIN 
        pg_roles r2 ON p.proowner = r2.oid
    WHERE 
        p.prokind IN ('f', 'p')
        AND r1.rolname <> r2.rolname
    UNION ALL
    -- Third query is for types(excluding table types)
    SELECT 
        cs.schema_name::name,
        r1.rolname,
        t.typname,
        r2.rolname,
        'type'::text
    FROM 
        common_schemas cs
    JOIN 
        pg_namespace n ON cs.schema_name = n.nspname
    JOIN 
        pg_roles r1 ON n.nspowner = r1.oid
    JOIN 
        pg_type t ON n.oid = t.typnamespace
    JOIN 
        pg_roles r2 ON t.typowner = r2.oid
    WHERE 
        t.typtype = 'd' -- Only show domain data type
        AND r1.rolname <> r2.rolname
    ORDER BY 1, 3;  -- Order by schema_name, object_name using column positions
END;
$$ LANGUAGE plpgsql;

/*
 * Gives a list of ALTER statements that, when executed,
 * will change the ownership of all the objects to match their schema owners.
 */
CREATE OR REPLACE FUNCTION sys.generate_alter_ownership_statements()
RETURNS TABLE (alter_statement text)
AS $$
DECLARE
    obj record;
BEGIN
    FOR obj IN SELECT * FROM sys.get_schema_object_ownership()
    LOOP
        CASE obj.object_type
            WHEN 'table' THEN
                alter_statement := format('ALTER TABLE %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;
            WHEN 'view' THEN
                alter_statement := 'SET babelfishpg_tsql.enable_create_alter_view_from_pg = true;';
				RETURN NEXT;

                alter_statement := format('ALTER VIEW %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;

                alter_statement := 'SET babelfishpg_tsql.enable_create_alter_view_from_pg = false;';
                RETURN NEXT;
            WHEN 'sequence' THEN
                alter_statement := format('ALTER SEQUENCE %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;
            WHEN 'function' THEN
                alter_statement := format('ALTER FUNCTION %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;
            WHEN 'procedure' THEN
                alter_statement := format('ALTER PROCEDURE %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;
            WHEN 'type' THEN
                alter_statement := format('ALTER TYPE %I.%I OWNER TO %I;',
                                          obj.schema_name, obj.object_name, obj.schema_owner_name);
                RETURN NEXT;
            ELSE
                alter_statement := format('-- Unsupported object type: %s for %I.%I',
                                          obj.object_type, obj.schema_name, obj.object_name);
                RETURN NEXT;
        END CASE;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION sys.json_query RENAME TO json_query_deprecated_in_5_2_0;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'json_query_deprecated_in_5_2_0');


CREATE OR REPLACE FUNCTION sys.json_query(json_string text, path text default '$')
RETURNS sys.NVARCHAR_JSON
AS 'babelfishpg_tsql', 'tsql_json_query' LANGUAGE C IMMUTABLE PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(anyelement, BOOL, NUMERIC) RENAME TO bbf_babelfish_conv_helper_to_datetime_with_arg_anyelement_deprecated_5_2_0;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'bbf_babelfish_conv_helper_to_datetime_with_arg_anyelement_deprecated_5_2_0');

DO $$
DECLARE
    old_function_exists boolean;
    exception_message text;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p 
        JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'sys' 
        AND p.proname = 'babelfish_try_conv_to_varbinary'
        AND p.pronargs = 2  -- old version with 2 parameters
    ) INTO old_function_exists;

    IF old_function_exists THEN
        ALTER FUNCTION sys.babelfish_try_conv_to_varbinary(
            IN arg anyelement,
            IN p_style NUMERIC
        ) RENAME TO babelfish_try_conv_to_varbinary_deprecated_in_5_2_0;
        CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varbinary(
            IN typmod INTEGER,
            IN arg anyelement,
            IN p_style NUMERIC DEFAULT 0
        )
        RETURNS sys.varbinary
        AS
        $BODY$
        DECLARE result sys.varbinary;
        BEGIN
            IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
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
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_to_varbinary_deprecated_in_5_2_0');
    END IF;

    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p 
        JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'sys' 
        AND p.proname = 'babelfish_conv_helper_to_varbinary'
        AND p.pronargs = 3  -- old version with 3 parameters
        AND p.proargtypes[0] = 'sys.varchar'::regtype::oid
    ) INTO old_function_exists;

    IF old_function_exists THEN
        ALTER FUNCTION sys.babelfish_conv_helper_to_varbinary(
            IN arg sys.VARCHAR,
            IN try BOOL,
            IN p_style NUMERIC
        ) RENAME TO babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_2_0;

        CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(
            IN typmod INTEGER,
            IN arg sys.VARCHAR,
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
                RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
            END IF;
        END;
        $BODY$
        LANGUAGE plpgsql
        IMMUTABLE;
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varbinary_varchar_deprecated_in_5_2_0');
    END IF;

    SELECT EXISTS (
        SELECT 1 
        FROM pg_proc p 
        JOIN pg_namespace n ON p.pronamespace = n.oid 
        WHERE n.nspname = 'sys' 
        AND p.proname = 'babelfish_conv_helper_to_varbinary'
        AND p.pronargs = 3  -- old version with 3 parameters
        AND p.proargtypes[0] = 'anyelement'::regtype::oid
    ) INTO old_function_exists;

    IF old_function_exists THEN
        -- Recreate definition with updated dependant function syntax.
        CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(
            IN arg anyelement,
            IN try BOOL,
            IN p_style NUMERIC DEFAULT 0
        )
        RETURNS sys.varbinary
        AS
        $BODY$
        DECLARE result sys.varbinary;
        BEGIN
            IF try THEN
                --  Hardcoding this as the internal function could have been dropped)
                RETURN sys.babelfish_try_conv_to_varbinary(-1 , arg, p_style);
            ELSE
                IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
                    RETURN sys.babelfish_conv_string_to_varbinary(arg, p_style);
                ELSE
                    RETURN CAST(arg as sys.varbinary);
                END IF;
            END IF;
        END;
        $BODY$
        LANGUAGE plpgsql
        IMMUTABLE;

        ALTER FUNCTION sys.babelfish_conv_helper_to_varbinary(
            IN arg anyelement,
            IN try BOOL,
            IN p_style NUMERIC
        ) RENAME TO babelfish_conv_helper_to_varbinary_anyel_deprecated_in_5_2_0;

        CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varbinary(
            IN typmod INTEGER,
            IN arg anyelement,
            IN try BOOL,
            IN p_style NUMERIC DEFAULT 0
        )
        RETURNS sys.varbinary
        AS
        $BODY$
        DECLARE result sys.varbinary;
        BEGIN
            IF try THEN
                RETURN sys.babelfish_try_conv_to_varbinary(typmod, arg, p_style);
            ELSE
                IF pg_typeof(arg) IN ('text'::regtype, 'sys.ntext'::regtype, 'sys.nvarchar'::regtype, 'sys.bpchar'::regtype, 'sys.nchar'::regtype) THEN
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

        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_varbinary_anyel_deprecated_in_5_2_0');
    END IF;

EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;
-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

