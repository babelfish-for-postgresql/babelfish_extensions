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

-- Assigning dbo role to the db_owner login
DO $$
DECLARE
    owner_name NAME;
    db_name TEXT;
    role_name NAME;
    owner_cursor CURSOR FOR SELECT DISTINCT owner, name FROM sys.babelfish_sysdatabases;
BEGIN
    OPEN owner_cursor;
    FETCH NEXT FROM owner_cursor INTO owner_name, db_name;

    WHILE FOUND
    LOOP
        SELECT rolname FROM sys.babelfish_authid_user_ext WHERE database_name = db_name INTO role_name;

        IF db_name = 'master' OR db_name = 'tempdb' OR db_name = 'msdb'
        THEN
            FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
            CONTINUE;
        END IF;

        EXECUTE FORMAT('GRANT %I TO %I', role_name, owner_name);

        FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
    END LOOP;

    CLOSE owner_cursor;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_varchar(INTERNAL)
RETURNS sys.VARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_nvarchar(INTERNAL)
RETURNS sys.NVARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.VARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_varchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.NVARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_nvarchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

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
INNER JOIN pg_attribute a ON a.attrelid = sc.out_object_id AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = NULL,
    "@table_owner" sys.nvarchar(384) = NULL, 
    "@table_qualifier" sys.sysname = NULL,
    "@table_type" sys.nvarchar(100) = NULL,
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN

	-- Handle special case: Enumerate all databases when name and owner are blank but qualifier is '%'
	IF (@table_qualifier = '%' AND @table_owner = '' AND @table_name = '')
	BEGIN
		SELECT
			d.name AS TABLE_QUALIFIER,
			CAST(NULL AS sys.sysname) AS TABLE_OWNER,
			CAST(NULL AS sys.sysname) AS TABLE_NAME,
			CAST(NULL AS sys.varchar(32)) AS TABLE_TYPE,
			CAST(NULL AS sys.varchar(254)) AS REMARKS
		FROM sys.databases d ORDER BY TABLE_QUALIFIER;
		
		RETURN;
	END;

	IF (@table_qualifier != '' AND LOWER(@table_qualifier) != LOWER(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
	
	IF (@fusepattern = 1)
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view 
		WHERE (@table_name IS NULL OR table_name LIKE @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner LIKE @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier LIKE @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
	ELSE
		SELECT 
			CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
			CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
			CAST(table_name AS sys.sysname) AS TABLE_NAME,
			CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
			remarks AS REMARKS
		FROM sys.sp_tables_view
		WHERE (@table_name IS NULL OR table_name = @table_name collate database_default)
		AND (@table_owner IS NULL OR table_owner = @table_owner collate database_default)
		AND (@table_qualifier IS NULL OR table_qualifier = @table_qualifier collate database_default)
		AND (
			@table_type IS NULL OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''TABLE''%' collate database_default AND table_type = 'TABLE' collate database_default) OR 
			(CAST(@table_type AS varchar(100)) LIKE '%''VIEW''%' collate database_default AND table_type = 'VIEW' collate database_default)
		)
		ORDER BY TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

ALTER FUNCTION sys.sp_tables_internal RENAME TO sp_tables_internal_deprecated_in_3_8_0;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sp_tables_internal_deprecated_in_3_8_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
