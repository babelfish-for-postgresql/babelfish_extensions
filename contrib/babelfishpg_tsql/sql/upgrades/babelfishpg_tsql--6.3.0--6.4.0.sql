-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '6.4.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar, arg_types varchar DEFAULT '') AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
    full_object_name text;
BEGIN
    -- Construct full object name with argument types if provided (for aggregates)
    IF arg_types <> '' THEN
        full_object_name := pg_catalog.format('%s.%s(%s)', schema_name, object_name, arg_types);
    ELSE
        full_object_name := pg_catalog.format('%s.%s', schema_name, object_name);
    END IF;

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', object_type, full_object_name);
    query2 := pg_catalog.format('drop %s %s', object_type, full_object_name);
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

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

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

-- BABEL-7225: long/mixed-case identifier resolution fixes.

-- Finding 5: resolve the original sequence name via the identifier mapping.
CREATE OR REPLACE VIEW information_schema_tsql.SEQUENCES AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SEQUENCE_CATALOG",
            CAST(extc.orig_name AS sys.nvarchar(128)) AS "SEQUENCE_SCHEMA",
            CAST(sys.bbf_get_original_identifier_name(r.relname, nc.nspname, 'pg_class'::regclass::oid, '') AS sys.nvarchar(128)) AS "SEQUENCE_NAME",
            CAST(CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype) ELSE tsql_type_name END
                    AS sys.nvarchar(128))AS "DATA_TYPE",  -- numeric and decimal data types are converted into bigint which is due to Postgres inherent implementation
            CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, -1)
                        AS smallint) AS "NUMERIC_PRECISION",
            CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, -1)
                        AS smallint) AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, -1)
                        AS int) AS "NUMERIC_SCALE",
            CAST(s.seqstart AS sys.sql_variant) AS "START_VALUE",
            CAST(s.seqmin AS sys.sql_variant) AS "MINIMUM_VALUE",
            CAST(s.seqmax AS sys.sql_variant) AS "MAXIMUM_VALUE",
            CAST(s.seqincrement AS sys.sql_variant) AS "INCREMENT",
            CAST( CASE WHEN s.seqcycle = 't' THEN 1 ELSE 0 END AS int) AS "CYCLE_OPTION",
            CAST(NULL AS sys.nvarchar(128)) AS "DECLARED_DATA_TYPE",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_PRECISION",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_SCALE"
        FROM sys.pg_namespace_ext nc JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
            pg_sequence s join pg_class r on s.seqrelid = r.oid join pg_type t on s.seqtypid=t.oid,
            sys.translate_pg_type_to_tsql(s.seqtypid) AS tsql_type_name
        WHERE nc.oid = r.relnamespace
        AND extc.dbid = sys.db_id()
            AND r.relkind = 'S'
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND (pg_has_role(r.relowner, 'USAGE')
                OR has_sequence_privilege(r.oid, 'SELECT, UPDATE, USAGE'));
GRANT SELECT ON information_schema_tsql.sequences TO PUBLIC;

-- Finding 5: resolve the original domain (scalar user type) name via the
-- identifier mapping.
CREATE OR REPLACE VIEW information_schema_tsql.domains AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
		CAST(sys.bbf_get_original_identifier_name(t.typname, nc.nspname, 'pg_type'::regclass::oid) AS sys.sysname) AS "DOMAIN_NAME",
		CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",
		CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_MAXIMUM_LENGTH",
		CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
			AS int)
		AS "CHARACTER_OCTET_LENGTH",
		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
		CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",
		CAST(
			CASE co.collname
				WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
				ELSE co.collname
			END
		AS sys.nvarchar(128)) AS "COLLATION_NAME",
		CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
		CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",
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
		AND ext.dbid = sys.db_id();
GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;

-- Finding 7: resolve the original (case/length-preserved) column name via the
-- attoptions-backed helper.
CREATE OR REPLACE VIEW information_schema_tsql.key_column_usage AS
	SELECT
		CAST(db_name AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
		sys.bbf_get_original_identifier_name(c.conname, nsp.nspname, 'pg_constraint'::regclass::oid, CASE WHEN octet_length(c.conname) >= 60 THEN (SELECT relname FROM pg_catalog.pg_class WHERE oid = c.conrelid) END)::sys.nvarchar(128) AS "CONSTRAINT_NAME",
		CAST(db_name AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		CAST(r.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
		CAST(sys.bbf_get_truncated_att_original_name(a.attoptions, a.attname) AS sys.nvarchar(128)) AS "COLUMN_NAME",
		CAST(ord AS int) AS "ORDINAL_POSITION"	
	FROM
		pg_constraint c 
		JOIN pg_class r ON r.oid = c.conrelid AND c.contype in ('p','u','f') AND r.relkind in ('r','p') AND r.relispartition = false
		JOIN pg_namespace nsp ON r.relnamespace = nsp.oid
		JOIN sys.babelfish_namespace_ext ext ON ext.nspname = nsp.nspname AND ext.dbid = sys.db_id()
		CROSS JOIN unnest(c.conkey) WITH ORDINALITY AS ak(j,ord) 
		LEFT JOIN pg_attribute a ON a.attrelid = r.oid AND a.attnum = ak.j
		, sys.db_name() AS db_name
	WHERE
		pg_has_role(r.relowner, 'USAGE'::text) 
  		OR has_column_privilege(r.oid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)
	;
GRANT SELECT ON information_schema_tsql.key_column_usage TO PUBLIC;

-- Finding 4: resolve the original (case/length-preserved) schema name from
-- babelfish_namespace_ext.orig_name.
CREATE OR REPLACE VIEW information_schema_tsql.schemata AS
	SELECT CAST(sys.db_name() AS sys.sysname) AS "CATALOG_NAME",
	CAST(CASE WHEN ext.orig_name IS NOT NULL THEN ext.orig_name::text
	     WHEN np.nspname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN PG_CATALOG.RIGHT(np.nspname, LENGTH(np.nspname) - LENGTH(sys.db_name()) - 1)
	     ELSE np.nspname::text END AS sys.nvarchar(128)) AS "SCHEMA_NAME",
	CAST(CASE WHEN sys.bbf_is_shared_schema(np.nspname) = TRUE THEN np.nspname
		  WHEN r.rolname LIKE PG_CATALOG.CONCAT(sys.db_name(),'%') THEN
			CASE WHEN PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) = 'db_owner' THEN 'dbo'
			     ELSE PG_CATALOG.RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) END ELSE 'dbo' END
			AS sys.nvarchar(128)) AS "SCHEMA_OWNER",
	CAST(null AS sys.varchar(6)) AS "DEFAULT_CHARACTER_SET_CATALOG",
	CAST(null AS sys.varchar(3)) AS "DEFAULT_CHARACTER_SET_SCHEMA",
	CAST(null AS sys.sysname) AS "DEFAULT_CHARACTER_SET_NAME"
	FROM ((pg_catalog.pg_namespace np LEFT JOIN sys.pg_namespace_ext nc on np.nspname = nc.nspname)
		LEFT JOIN pg_catalog.pg_roles r on r.oid = nc.nspowner) LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
	WHERE (ext.dbid = sys.db_id() OR np.nspname in ('sys', 'information_schema_tsql')) AND
	      (pg_has_role(np.nspowner, 'USAGE') OR has_schema_privilege(np.oid, 'CREATE, USAGE'))
	ORDER BY nc.nspname, np.nspname;
GRANT SELECT ON information_schema_tsql.schemata TO PUBLIC;


-- Use plain coalesce(@param, '') instead of (SELECT coalesce(@param, '')) in the optional
-- parameter filters below. The sub-SELECT becomes an InitPlan that the planner cannot fold,
-- which leads to a severe row underestimate and a nested loop over every schema.
CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = 'dbo',
	"@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
	select * from sys.sp_pkeys_view
	where (table_name = @table_name
		or sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = @table_name)
		and table_owner = coalesce(@table_owner, 'dbo') 
		and (coalesce(@table_qualifier,'') = '' or
		         table_qualifier = @table_qualifier )
	order by table_qualifier,
	         table_owner,
		 table_name,
		 key_seq;
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_statistics(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
	"@index_name" sys.sysname = '',
	"@is_unique" char = 'N',
	"@accuracy" char = 'Q'
)
AS $$
BEGIN
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where (@table_name = table_name
		or @table_name = sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)))
		and (coalesce(@table_owner,'') = '' or table_owner = @table_owner )
		and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier )
		and (coalesce(@index_name,'') = '' or index_name like @index_name )
		and ((pg_catalog.UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (pg_catalog.UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics TO PUBLIC;

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
	IF @index_name = '%'
	BEGIN
		SELECT @index_name = ''
	END
	select * from sys.sp_statistics_view
	where (@table_name = table_name
		or @table_name = sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)))
		and (coalesce(@table_owner,'') = '' or table_owner = @table_owner )
		and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier )
		and (coalesce(@index_name,'') = '' or index_name like @index_name )
		and ((pg_catalog.UPPER(@is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (pg_catalog.UPPER(@is_unique) = 'N'))
	order by non_unique, type, index_name, seq_in_index;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_column_privileges(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
    "@column_name" sys.nvarchar(384) = ''
)
AS $$
BEGIN
    IF (@table_qualifier != '') AND (pg_catalog.lower(@table_qualifier) != pg_catalog.lower(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
	END
 	
	IF (COALESCE(@table_owner, '') = '')
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
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND (pg_catalog.lower('dbo')= pg_catalog.lower(table_owner))
			AND (COALESCE(@table_qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
			AND (COALESCE(@column_name,'') = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
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
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND (COALESCE(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND (COALESCE(@table_qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
			AND (COALESCE(@column_name,'') = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
	END
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
	"@table_name" sys.nvarchar(384),
	"@table_owner" sys.nvarchar(384) = '',
	"@table_qualifier" sys.sysname = '',
	"@fusepattern" sys.bit = 1
)
AS $$
BEGIN
	
	IF (@table_qualifier != '') AND (pg_catalog.lower(@table_qualifier) != pg_catalog.lower(sys.db_name()))
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
		WHERE (pg_catalog.lower(TABLE_NAME) LIKE pg_catalog.lower(@table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(TABLE_NAME)) = pg_catalog.lower(@table_name))
			AND (COALESCE(@table_owner,'') = '' OR pg_catalog.lower(TABLE_OWNER) LIKE pg_catalog.lower(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
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
		WHERE (pg_catalog.lower(TABLE_NAME) = pg_catalog.lower(@table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(TABLE_NAME)) = pg_catalog.lower(@table_name))
			AND (COALESCE(@table_owner,'') = '' OR pg_catalog.lower(TABLE_OWNER) = pg_catalog.lower(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

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
DECLARE @constraint_name sys.sysname;
BEGIN
	IF (@qualifier != '') AND (pg_catalog.lower(@qualifier) != pg_catalog.lower(sys.db_name()))
	BEGIN
		THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
		
	END
	
	IF (pg_catalog.lower(@col_type) = pg_catalog.lower('V'))
	BEGIN
		THROW 33557097, N'TIMESTAMP datatype is not currently supported in Babelfish', 1;
	END
	
	IF (pg_catalog.lower(@nullable) = pg_catalog.lower('O'))
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0)
		ORDER BY constraint_type, index_id;
	
		IF @special_col_type='u'
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
				ORDER BY scope, column_name;
				
			END
			ELSE
			BEGIN
				SELECT  
				SCOPE,
				COLUMN_NAME,
				DATA_TYPE,
				TYPE_NAME,
				PRECISION,
				LENGTH,
				SCALE,
				PSEUDO_COLUMN FROM sys.sp_special_columns_view
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
		END
	END
	
	ELSE 
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
			AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier))
		ORDER BY constraint_type, index_id;

		IF @special_col_type='u'
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND @constraint_name = constraint_name
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE (pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(table_name)) = pg_catalog.lower(@table_name))
				AND (coalesce(@table_owner,'') = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND (coalesce(@qualifier,'') = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
    
		END
	END

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns TO PUBLIC;

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
	PK_NAME,
	DEFERRABILITY
	FROM sys.sp_fkeys_view
	WHERE (coalesce(@pktable_name,'') = '' OR pg_catalog.lower(pktable_name) = pg_catalog.lower(@pktable_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(pktable_name)) = pg_catalog.lower(@pktable_name))
		AND (coalesce(@fktable_name,'') = '' OR pg_catalog.lower(fktable_name) = pg_catalog.lower(@fktable_name)
			OR sys.babelfish_truncate_identifier(pg_catalog.lower(fktable_name)) = pg_catalog.lower(@fktable_name))
		AND (coalesce(@pktable_owner,'') = '' OR pg_catalog.lower(pktable_owner) = pg_catalog.lower(@pktable_owner))
		AND (coalesce(@pktable_qualifier,'') = '' OR pg_catalog.lower(pktable_qualifier) = pg_catalog.lower(@pktable_qualifier))
		AND (coalesce(@fktable_owner,'') = '' OR pg_catalog.lower(fktable_owner) = pg_catalog.lower(@fktable_owner))
		AND (coalesce(@fktable_qualifier,'') = '' OR pg_catalog.lower(fktable_qualifier) = pg_catalog.lower(@fktable_qualifier))
	ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_stored_procedures(
    "@sp_name" sys.nvarchar(390) = '',
    "@sp_owner" sys.nvarchar(384) = '',
    "@sp_qualifier" sys.sysname = '',
    "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
	IF (@sp_qualifier != '') AND pg_catalog.lower(sys.db_name()) != pg_catalog.lower(@sp_qualifier)
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
			WHERE (COALESCE(@sp_owner,'') = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
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
			WHERE (COALESCE(@sp_owner,'') = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
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
					WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
						AND (pg_catalog.lower(procedure_owner) = 'sys'))
			BEGIN
				SELECT PROCEDURE_QUALIFIER,
				PROCEDURE_OWNER,
				PROCEDURE_NAME,
				NUM_INPUT_PARAMS,
				NUM_OUTPUT_PARAMS,
				NUM_RESULT_SETS,
				REMARKS,
				PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
				WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
					AND (pg_catalog.lower(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
					AND (pg_catalog.lower(procedure_owner) = pg_catalog.lower(SCHEMA_NAME()))
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
				WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
					AND (pg_catalog.lower(procedure_owner) = pg_catalog.lower(SCHEMA_NAME()))
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
				WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
					AND (pg_catalog.lower(procedure_owner) = 'dbo')
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
			WHERE (pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) = pg_catalog.lower(@sp_name))
				AND (pg_catalog.lower(procedure_owner) = pg_catalog.lower(@sp_owner))
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
			WHERE (COALESCE(@sp_name,'') = '' OR pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2)) LIKE pg_catalog.lower(@sp_name) OR sys.babelfish_truncate_identifier(pg_catalog.lower(pg_catalog.LEFT(procedure_name, LEN(procedure_name)-2))) LIKE pg_catalog.lower(@sp_name))
				AND (COALESCE(@sp_owner,'') = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
