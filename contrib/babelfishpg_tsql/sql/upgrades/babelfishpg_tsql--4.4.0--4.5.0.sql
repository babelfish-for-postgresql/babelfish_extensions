-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.5.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
-- Update all grants to babelfish users to make bbf_role_admin as grantor.
DO
LANGUAGE plpgsql
$$
DECLARE
    temprow RECORD;
    query TEXT;
    init_user NAME;
BEGIN
    SELECT r.rolname
    INTO init_user
    FROM pg_roles r
    INNER JOIN pg_database d
    ON r.oid = d.datdba
    WHERE d.datname = current_database();

    FOR temprow IN
        WITH bbf_catalog AS (
            SELECT r.oid AS roleid, ext1.rolname
            FROM sys.babelfish_authid_login_ext ext1
            INNER JOIN pg_roles r ON ext1.rolname = r.rolname
            WHERE r.rolname != init_user
            UNION
            SELECT r.oid AS roleid, ext2.rolname
            FROM sys.babelfish_authid_user_ext ext2
            INNER JOIN pg_roles r ON ext2.rolname = r.rolname
        )
        SELECT cat.rolname AS rolname, cat2.rolname AS member, am.grantor::regrole
        FROM pg_auth_members am
        INNER JOIN bbf_catalog cat ON am.roleid = cat.roleid
        INNER JOIN bbf_catalog cat2 ON am.member = cat2.roleid
        WHERE am.admin_option = 'f'
        AND am.grantor != 'bbf_role_admin'::regrole
    LOOP
        -- First revoke the existing grant
        query := pg_catalog.format('REVOKE %I FROM %I GRANTED BY %s;', temprow.rolname, temprow.member, temprow.grantor);
        EXECUTE query;
        -- Now create the grant with bbf_role_admin as grantor
        query := pg_catalog.format('GRANT %I TO %I GRANTED BY bbf_role_admin;', temprow.rolname, temprow.member);
        EXECUTE query;
    END LOOP;
END;
$$;


/* Helper function to update local variables dynamically during execution */
CREATE OR REPLACE FUNCTION sys.pltsql_assign_var(dno INT, val ANYELEMENT)
RETURNS ANYELEMENT
AS 'babelfishpg_tsql', 'pltsql_assign_var' LANGUAGE C PARALLEL UNSAFE;

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
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE pg_catalog.lower(in_catalog)) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE pg_catalog.lower(in_owner)) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE pg_catalog.lower(in_table)) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE pg_catalog.lower(in_column)) AND
        (in_schematype = 0 AND (s_cv.IS_SPARSE = 0) OR in_schematype = 1 OR in_schematype = 2 AND (s_cv.IS_SPARSE = 1));
END;
$$
language plpgsql STABLE;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = NULL,
    "@table_owner" sys.nvarchar(384) = NULL, 
    "@table_qualifier" sys.sysname = NULL,
    "@table_type" sys.nvarchar(100) = NULL,
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN

	-- Temporary variable to hold the current database name
	DECLARE @current_db_name sys.sysname;

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

	SELECT @current_db_name = sys.db_name();

	IF (@table_qualifier != '' AND pg_catalog.lower(@table_qualifier) != pg_catalog.lower(@current_db_name))
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
    JOIN information_schema_tsql.columns_internal t3 ON (t1.oid = t3."TABLE_OID")
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
ELSE CAST(pg_catalog.SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname) 
END AS INDEX_NAME,
CASE
WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
ELSE CAST(3 AS smallint)
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.n_distinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	JOIN (pg_catalog.pg_index t5 JOIN
		pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
	JOIN pg_catalog.pg_namespace nsp ON (t1.relnamespace = nsp.oid)
	LEFT JOIN pg_catalog.pg_stats t7 ON (t1.relname = t7.tablename AND t7.schemaname = nsp.nspname)
	LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

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
		
		IF EXISTS ( 
			SELECT * FROM sys.sp_column_privileges_view 
			WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name) and pg_catalog.lower(SCHEMA_NAME()) = pg_catalog.lower(table_qualifier)
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
			WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND (pg_catalog.lower(SCHEMA_NAME()) = pg_catalog.lower(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
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
			WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND (pg_catalog.lower('dbo')= pg_catalog.lower(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
			ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
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
		WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR pg_catalog.lower(column_name) LIKE pg_catalog.lower(@column_name))
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
		WHERE pg_catalog.lower(TABLE_NAME) LIKE pg_catalog.lower(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(TABLE_OWNER) LIKE pg_catalog.lower(@table_owner))
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
		WHERE pg_catalog.lower(TABLE_NAME) = pg_catalog.lower(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR pg_catalog.lower(TABLE_OWNER) = pg_catalog.lower(@table_owner))
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
		WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND (is_nullable = 0) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
				AND CONSTRAINT_TYPE = 'p'
				ORDER BY scope, column_name;
			END
		END
	END
	
	ELSE 
	BEGIN
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier))
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
				WHERE pg_catalog.lower(@table_name) = pg_catalog.lower(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR pg_catalog.lower(table_owner) = pg_catalog.lower(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR pg_catalog.lower(table_qualifier) = pg_catalog.lower(@qualifier)) AND pg_catalog.lower(constraint_type) = pg_catalog.lower(@special_col_type)
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
	WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR pg_catalog.lower(pktable_name) = pg_catalog.lower(@pktable_name))
		AND ((SELECT coalesce(@fktable_name,'')) = '' OR pg_catalog.lower(fktable_name) = pg_catalog.lower(@fktable_name))
		AND ((SELECT coalesce(@pktable_owner,'')) = '' OR pg_catalog.lower(pktable_owner) = pg_catalog.lower(@pktable_owner))
		AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR pg_catalog.lower(pktable_qualifier) = pg_catalog.lower(@pktable_qualifier))
		AND ((SELECT coalesce(@fktable_owner,'')) = '' OR pg_catalog.lower(fktable_owner) = pg_catalog.lower(@fktable_owner))
		AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR pg_catalog.lower(fktable_qualifier) = pg_catalog.lower(@fktable_qualifier))
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
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
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
			WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
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
					WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
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
				WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
					AND (pg_catalog.lower(procedure_owner) = 'sys')
				ORDER BY procedure_qualifier, procedure_owner, procedure_name;
			END
			ELSE IF EXISTS ( 
				SELECT * FROM sys.sp_stored_procedures_view
				WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
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
				WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
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
				WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
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
			WHERE (pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) = pg_catalog.lower(@sp_name))
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
			WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR pg_catalog.lower(LEFT(procedure_name, LEN(procedure_name)-2)) LIKE pg_catalog.lower(@sp_name))
				AND ((SELECT COALESCE(@sp_owner,'')) = '' OR pg_catalog.lower(procedure_owner) LIKE pg_catalog.lower(@sp_owner))
			ORDER BY procedure_qualifier, procedure_owner, procedure_name;
		END
	END	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
	role  := TRIM(trailing from pg_catalog.lower(role));
	login := TRIM(trailing from pg_catalog.lower(login));
	
	login_valid = (login = suser_name() COLLATE sys.database_default) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				pg_catalog.lower(name) = login COLLATE sys.database_default
				AND type = 'S'));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' COLLATE sys.database_default THEN
    	RETURN 1;
	
 	ELSIF role = 'sysadmin' COLLATE sys.database_default THEN
	  	has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
	    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role COLLATE sys.database_default IN (
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
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE sys.sp_helprole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = DB_NAME()
		AND Ext.type = 'R'
		ORDER BY RoleName;
	END
	-- If a valid role is specified, return its info
	ELSE IF EXISTS (SELECT 1 
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@rolename))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Base.oid AS INT) AS 'RoleId',
			   0 AS 'IsAppRole'
		FROM pg_catalog.pg_roles AS Base 
		INNER JOIN sys.babelfish_authid_user_ext AS Ext
		ON Base.rolname = Ext.rolname
		WHERE Ext.database_name = DB_NAME()
		AND Ext.type = 'R'
		AND (Ext.orig_username = @rolename OR pg_catalog.lower(Ext.orig_username) = pg_catalog.lower(@rolename))
		ORDER BY RoleName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprole TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helprolemember("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If role is not specified, return info for all roles that have at least
	-- one member in the current db
	IF @rolename IS NULL
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		ORDER BY RoleName, MemberName;
	END
	-- If a valid role is specified, return its member info
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_user_ext
					WHERE (orig_username = @rolename
					OR pg_catalog.lower(orig_username) = pg_catalog.lower(@rolename))
					AND database_name = DB_NAME()
					AND type = 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
			   CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.database_name = DB_NAME()
		AND Ext2.database_name = DB_NAME()
		AND Ext1.type = 'R'
		AND Ext2.orig_username != 'db_owner'
		AND (Ext1.orig_username = @rolename OR pg_catalog.lower(Ext1.orig_username) = pg_catalog.lower(@rolename))
		ORDER BY RoleName, MemberName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprolemember TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- If server role is not specified, return info for all server roles
	IF @srvrolename IS NULL
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
		ORDER BY ServerRole, MemberName;
	END
	-- If a valid server role is specified, return its member info
	-- If the role is a SQL server predefined role (i.e. serveradmin), 
	-- do not raise an error even if it does not exist
	ELSE IF EXISTS (SELECT 1
					FROM sys.babelfish_authid_login_ext
					WHERE (rolname = PG_CATALOG.RTRIM(@srvrolename)
					OR pg_catalog.lower(rolname) = pg_catalog.lower(PG_CATALOG.RTRIM(@srvrolename)))
					AND type = 'R')
					OR pg_catalog.lower(PG_CATALOG.RTRIM(@srvrolename)) IN (
					'serveradmin', 'setupadmin', 'securityadmin', 'processadmin',
					'dbcreator', 'diskadmin', 'bulkadmin')
	BEGIN
		SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
			   CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
			   CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
		FROM pg_catalog.pg_auth_members AS Authmbr
		INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
		INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
		INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
		INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
		WHERE Ext1.type = 'R' AND Ext2.type != 'Z'
		AND (Ext1.rolname = PG_CATALOG.RTRIM(@srvrolename) OR pg_catalog.lower(Ext1.rolname) = pg_catalog.lower(PG_CATALOG.RTRIM(@srvrolename)))
		ORDER BY ServerRole, MemberName;
	END
	-- If the specified server role is not valid
	ELSE
		RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpdbfixedrole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
	-- Returns a list of the fixed database roles. 
	-- Only fixed role present in babelfish is db_owner.
	IF pg_catalog.lower(PG_CATALOG.RTRIM(@rolename)) IS NULL OR pg_catalog.lower(PG_CATALOG.RTRIM(@rolename)) = 'db_owner'
	BEGIN
		SELECT CAST('db_owner' AS sys.SYSNAME) AS DbFixedRole, CAST('DB Owners' AS sys.nvarchar(70)) AS Description;
	END
	ELSE IF pg_catalog.lower(PG_CATALOG.RTRIM(@rolename)) IN (
			'db_accessadmin','db_securityadmin','db_ddladmin', 'db_backupoperator', 
			'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
	BEGIN
		-- Return an empty result set instead of raising an error
		SELECT CAST(NULL AS sys.SYSNAME) AS DbFixedRole, CAST(NULL AS sys.nvarchar(70)) AS Description
		WHERE 1=0;	
	END
	ELSE
		RAISERROR('''%s'' is not a known fixed role.', 16, 1, @rolename);
END
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpdbfixedrole TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)	
AS $$
	SELECT @procedure_name = pg_catalog.lower(COALESCE(@procedure_name, ''))
	SELECT @procedure_owner = pg_catalog.lower(COALESCE(@procedure_owner, ''))
	SELECT @procedure_qualifier = pg_catalog.lower(COALESCE(@procedure_qualifier, ''))
	SELECT @column_name = pg_catalog.lower(COALESCE(@column_name, ''))
BEGIN 
	IF (@procedure_qualifier != '' AND (SELECT pg_catalog.lower(sys.db_name())) != @procedure_qualifier)
		BEGIN
			THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 	   	END
	IF @fusepattern = '1'
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name LIKE @procedure_name)
				AND (@procedure_owner = '' OR procedure_owner LIKE @procedure_owner)
				AND (@column_name = '' OR column_name LIKE @column_name)
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
	ELSE
		BEGIN
			SELECT PROCEDURE_QUALIFIER,
					PROCEDURE_OWNER,
					PROCEDURE_NAME,
					COLUMN_NAME,
					COLUMN_TYPE,
					DATA_TYPE,
					TYPE_NAME,
					PRECISION,
					LENGTH,
					SCALE,
					RADIX,
					NULLABLE,
					REMARKS,
					COLUMN_DEF,
					SQL_DATA_TYPE,
					SQL_DATETIME_SUB,
					CHAR_OCTET_LENGTH,
					ORDINAL_POSITION,
					IS_NULLABLE,
					SS_DATA_TYPE
			FROM sys.sp_sproc_columns_view
			WHERE (@procedure_name = '' OR original_procedure_name = @procedure_name)
				AND (@procedure_owner = '' OR procedure_owner = @procedure_owner)
				AND (@column_name = '' OR column_name = @column_name)
				AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
			ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
		END
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_who(
	IN "@loginame" sys.sysname DEFAULT NULL,
	IN "@option"   sys.VARCHAR(30) DEFAULT NULL)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET NOCOUNT ON
	DECLARE @msg sys.VARCHAR(200)
	DECLARE @show_pg BIT = 0
	DECLARE @hide_col sys.VARCHAR(50) 
	
	IF @option IS NOT NULL
	BEGIN
		IF pg_catalog.lower(TRIM(@option)) <> 'postgres' 
		BEGIN
			RAISERROR('Parameter @option can only be ''postgres''', 16, 1)
			RETURN			
		END
	END
	
	-- Take a copy of sysprocesses so that we reference it only once
	SELECT DISTINCT * INTO #sp_who_sysprocesses FROM sys.sysprocesses

	-- Get the executing statement for each spid and extract the main stmt type
	-- This is for informational purposes only
	SELECT pid, CAST(query AS sys.VARCHAR(MAX)) INTO #sp_who_tmp FROM pg_stat_activity pgsa
	
	UPDATE #sp_who_tmp SET query = ' ' + TRIM(CAST(UPPER(query) AS sys.VARCHAR(MAX)))
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(9), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(10), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(13), ' ')
	WHILE (SELECT count(*) FROM #sp_who_tmp WHERE sys.CHARINDEX('  ',query)>0) > 0 
	BEGIN
		UPDATE #sp_who_tmp SET query = sys.REPLACE(query, '  ', ' ')
	END

	-- Determine type of stmt to report by sp_who: very basic only
	-- NB: not handling presence of comments in the query string
	UPDATE #sp_who_tmp 
	SET query = 
	    CASE 
			WHEN PATINDEX('%[^a-zA-Z0-9_]UPDATE[^a-zA-Z0-9_]%', query) > 0 THEN 'UPDATE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]DELETE[^a-zA-Z0-9_]%', query) > 0 THEN 'DELETE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]INSERT[^a-zA-Z0-9_]%', query) > 0 THEN 'INSERT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]SELECT[^a-zA-Z0-9_]%', query) > 0 THEN 'SELECT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]WAITFOR[^a-zA-Z0-9_]%', query) > 0 THEN 'WAITFOR'
			WHEN PATINDEX('%[^a-zA-Z0-9_]CREATE ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('CREATE ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]ALTER ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('ALTER ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]DROP ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('DROP ', query))
			ELSE sys.SUBSTRING(query, 1, sys.CHARINDEX(' ', query))
		END

	UPDATE #sp_who_tmp 
	SET query = sys.SUBSTRING(query,1, 8-1 + sys.CHARINDEX(' ', sys.SUBSTRING(query,8,99)))
	WHERE query LIKE 'CREATE %' OR query LIKE 'ALTER %' OR query LIKE 'DROP %'	

	-- The executing spid is always shown as doing a SELECT
	UPDATE #sp_who_tmp SET query = 'SELECT' WHERE pid = @@spid
	UPDATE #sp_who_tmp SET query = TRIM(query)

	-- Get all current connections
	SELECT 
		spid, 
		MAX(blocked) AS blocked, 
		0 AS ecid, 
		CAST('' AS sys.VARCHAR(100)) AS status,
		CAST('' AS sys.VARCHAR(100)) AS loginname,
		CAST('' AS sys.VARCHAR(100)) AS hostname,
		0 AS dbid,
		CAST('' AS sys.VARCHAR(100)) AS cmd,
		0 AS request_id,
		CAST('TDS' AS sys.VARCHAR(20)) AS connection,
		hostprocess
	INTO #sp_who_proc
	FROM #sp_who_sysprocesses
		GROUP BY spid, status, hostprocess
		
	-- Add attributes to each connection
	UPDATE #sp_who_proc
	SET ecid = sp.ecid,
		status = sp.status,
		loginname = sp.loginname,
		hostname = sp.hostname,
		dbid = sp.dbid,
		request_id = sp.request_id
	FROM #sp_who_sysprocesses sp
		WHERE #sp_who_proc.spid = sp.spid				

	-- Identify PG connections: the hostprocess PID comes from the TDS login packet 
	-- and therefore PG connections do not have a value here
	UPDATE #sp_who_proc
	SET connection = 'PostgreSQL'
	WHERE hostprocess IS NULL 

	-- Keep or delete PG connections
	IF (pg_catalog.lower(@loginame) = 'postgres' OR pg_catalog.lower(@option) = 'postgres')
	begin    
		-- Show PG connections; these have dbid = 0
		-- This is a Babelfish-specific enhancement, since PG connections may also be active in the Babelfish DB
		-- and it may be useful to see these displayed
		SET @show_pg = 1
		
		-- blank out the loginame parameter for the tests below
		IF pg_catalog.lower(@loginame) = 'postgres' SET @loginame = NULL
	END
	
	-- By default, do not show the column indicating the connection type since SQL Server does not have this column
	SET @hide_col = 'connection' 
	
	IF (@show_pg = 1) 
	BEGIN
		SET @hide_col = ''
	END
	ELSE 
	BEGIN
		-- Delete PG connections
		DELETE #sp_who_proc
		WHERE dbid = 0
	END
			
	-- Apply filter if specified
	IF (@loginame IS NOT NULL)
	BEGIN
		IF (TRIM(@loginame) = '')
		BEGIN
			-- Raise error
			SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
			RAISERROR(@msg, 16, 1)
			RETURN
		END
		
		IF (sys.ISNUMERIC(@loginame) = 1)
		BEGIN
			-- Remove all connections except the specified one
			DELETE #sp_who_proc
			WHERE spid <> CAST(@loginame AS INT)
		END
		ELSE 
		BEGIN	
			IF (pg_catalog.lower(@loginame) = 'active')
			BEGIN
				-- Remove all 'idle' connections 
				DELETE #sp_who_proc
				WHERE status = 'idle'
			END
			ELSE 
			BEGIN
				-- Verify the specified login name exists
				IF (sys.SUSER_ID(@loginame) IS NULL)
				BEGIN
					SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
					RAISERROR(@msg, 16, 1)
					RETURN					
				END
				ELSE 
				BEGIN
					-- Keep only connections for the specified login
					DELETE #sp_who_proc
					WHERE sys.SUSER_ID(loginname) <> sys.SUSER_ID(@loginame)
				END
			END
		END
	END			
			
	-- Create final result set; use DISTINCT since there are usually duplicate rows from the PG catalogs
	SELECT distinct 
		p.spid AS spid, 
		p.ecid AS ecid, 
		CAST(LEFT(p.status,20) AS sys.VARCHAR(20)) AS status,
		CAST(LEFT(p.loginname,40) AS sys.VARCHAR(40)) AS loginame,
		CAST(LEFT(p.hostname,60) AS sys.VARCHAR(60)) AS hostname,
		p.blocked AS blk, 
		CAST(LEFT(db_name(p.dbid),40) AS sys.VARCHAR(40)) AS dbname,
		CAST(LEFT(#sp_who_tmp.query,30)as sys.VARCHAR(30)) AS cmd,
		p.request_id AS request_id,
		connection
	INTO #sp_who_tmp2
	FROM #sp_who_proc p, #sp_who_tmp
		WHERE p.spid = #sp_who_tmp.pid
		ORDER BY spid		
	
	-- Patch up remaining cases
	UPDATE #sp_who_tmp2
	SET cmd = 'AWAITING COMMAND'
	WHERE TRIM(ISNULL(cmd,'')) = '' AND status = 'idle'
	
	UPDATE #sp_who_tmp2
	SET cmd = 'UNKNOWN'
	WHERE TRIM(cmd) = ''	
	
	-- Format the result set as narrow as possible for readability
	SET @hide_col += ',hostprocess'
	EXECUTE sys.sp_babelfish_autoformat @tab='#sp_who_tmp2', @orderby='ORDER BY spid', @hiddencols=@hide_col, @printrc=0
	RETURN
END	
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_who(IN sys.sysname, IN sys.VARCHAR(30)) TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.columns_internal AS
	SELECT c.oid AS "TABLE_OID",
			CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
			CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23 /* prefix length */)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
					c.relname)
				AS sys.nvarchar(128)) AS "TABLE_NAME",

			CAST(
				COALESCE(
					(SELECT PG_CATALOG.string_agg(
						CASE
						WHEN option LIKE 'bbf_original_name=%' THEN substring(option, 19 /* prefix length */)
						ELSE NULL
						END, ',')
					FROM unnest(a.attoptions) AS option),
					a.attname)
				AS sys.nvarchar(128)) AS "COLUMN_NAME",

			CAST(a.attnum AS int) AS "ORDINAL_POSITION",
			CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
			CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
				AS varchar(3))
				AS "IS_NULLABLE",

			CAST(
				CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
				WHEN tsql_type_name.tsql_type_name IS NULL THEN format_type(t.oid, NULL::integer)
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
		AND c.relispartition = false
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid =sys.db_id();

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
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
		   LEFT JOIN sys.table_types_internal tt on c.oid = tt.typrelid

	WHERE c.relkind IN ('r', 'v', 'p')
		AND c.relispartition = false
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid IS NULL
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

create or replace view sys.tables as
with tt_internal as MATERIALIZED
(
  select * from sys.table_types_internal
)
select
  CAST(t.relname as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(t.relnamespace  as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as sys.bpchar(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select PG_CATALOG.string_agg(
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
inner join sys.schemas sch on sch.schema_id = t.relnamespace
left join tt_internal tt on t.oid = tt.typrelid
where tt.typrelid is null
and (t.relkind = 'r' or t.relkind = 'p')
and t.relispartition = false
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;

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
    , CAST(p.relnamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_class p on p.oid = tr.parent_id
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
union all
select
    CAST(('TT_' || tt.name collate "C" || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select PG_CATALOG.string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select PG_CATALOG.string_agg(
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

CREATE OR REPLACE VIEW sys.servers
AS
SELECT
  CAST(f.oid as int) AS server_id,
  CAST(f.srvname as sys.sysname) AS name,
  CAST('' as sys.sysname) AS product,
  CAST('tds_fdw' as sys.sysname) AS provider,
  CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'servername=%%' then substring(option, 12)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
  CAST(NULL as sys.nvarchar(4000)) AS location,
  CAST(NULL as sys.nvarchar(4000)) AS provider_string,
  CAST((select PG_CATALOG.string_agg(
                  case
                  when option like 'database=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
  CAST(s.connect_timeout as int) AS connect_timeout,
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
LEFT JOIN sys.babelfish_server_options AS s on f.srvname = s.servername
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

CREATE OR REPLACE VIEW sys.linked_logins
AS
SELECT
  CAST(u.srvid as int) AS server_id,
  CAST(0 as int) AS local_principal_id,
  CAST(0 as sys.bit) AS uses_self_credential,
  CAST((select PG_CATALOG.string_agg(
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

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetime2fromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                                p_hour::NUMERIC, p_minute::NUMERIC, p_seconds::NUMERIC,
                                                p_fractions::NUMERIC, p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year TEXT,
                                                               IN p_month TEXT,
                                                               IN p_day TEXT,
                                                               IN p_hour TEXT,
                                                               IN p_minute TEXT,
                                                               IN p_seconds TEXT,
                                                               IN p_milliseconds TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetimefromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                               p_hour::NUMERIC, p_minute::NUMERIC,
                                               p_seconds::NUMERIC, p_milliseconds::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour TEXT,
                                                           IN p_minute TEXT,
                                                           IN p_seconds TEXT,
                                                           IN p_fractions TEXT,
                                                           IN p_precision TEXT)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.timefromparts(p_hour::NUMERIC, p_minute::NUMERIC,
                                           p_seconds::NUMERIC, p_fractions::NUMERIC,
                                           p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.timezone(IN tzzone PG_CATALOG.TEXT , IN input_expr anyelement)
RETURNS sys.datetimeoffset
AS
$BODY$
DECLARE
    tz_offset PG_CATALOG.TEXT;
    tz_name PG_CATALOG.TEXT;
    lower_tzn PG_CATALOG.TEXT;
    prev_res PG_CATALOG.TEXT;
    result PG_CATALOG.TEXT;
    is_dstt bool;
    tz_diff PG_CATALOG.TEXT;
    input_expr_tx PG_CATALOG.TEXT;
    input_expr_tmz TIMESTAMPTZ;
BEGIN
    IF input_expr IS NULL OR tzzone IS NULL THEN 
    	RETURN NULL;
    END IF;

    lower_tzn := pg_catalog.lower(tzzone);
    IF lower_tzn <> 'utc' THEN
        tz_name := sys.babelfish_timezone_mapping(lower_tzn);
    ELSE
        tz_name := 'utc';
    END IF;

    IF tz_name = 'NULL' THEN
        RAISE USING MESSAGE := format('Argument data type or the parameter %s provided to AT TIME ZONE clause is invalid.', tzzone);
    END IF;

    IF pg_typeof(input_expr) IN ('sys.smalldatetime'::regtype, 'sys.datetime'::regtype, 'sys.datetime2'::regtype) THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;

        result := (SELECT input_expr_tmz AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := PG_CATALOG.concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        input_expr_tx := PG_CATALOG.concat(input_expr_tx,tz_offset);
        return cast(input_expr_tx as sys.datetimeoffset);
    ELSIF  pg_typeof(input_expr) = 'sys.DATETIMEOFFSET'::regtype THEN
        input_expr_tx := input_expr::TEXT;
        input_expr_tmz := input_expr_tx :: TIMESTAMPTZ;
        result := (SELECT input_expr_tmz  AT TIME ZONE tz_name)::TEXT;
        tz_diff := (SELECT result::TIMESTAMPTZ - input_expr_tmz)::TEXT;
        if PG_CATALOG.LEFT(tz_diff,1) <> '-' THEN
            tz_diff := PG_CATALOG.concat('+',tz_diff);
        END IF;
        tz_offset := PG_CATALOG.left(tz_diff,6);
        result := PG_CATALOG.concat(result,tz_offset);
        return cast(result as sys.datetimeoffset);
    ELSE
        RAISE USING MESSAGE := 'Argument data type varchar is invalid for argument 1 of AT TIME ZONE function.'; 
    END IF;
       
END;
$BODY$
LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    db_name text COLLATE sys.database_default; 
    bbf_schema_name text COLLATE sys.database_default;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    is_cross_db boolean := false;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    userid oid;
    object_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
    cs_as_securable text COLLATE "C" := securable;
    cs_as_securable_class text COLLATE "C" := securable_class;
    cs_as_permission text COLLATE "C" := permission;
    cs_as_sub_securable text COLLATE "C" := sub_securable;
    cs_as_sub_securable_class text COLLATE "C" := sub_securable_class;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    cs_as_securable = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_securable));
    cs_as_securable_class = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_securable_class));
    cs_as_permission = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_permission));
    cs_as_sub_securable = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = pg_catalog.lower(PG_CATALOG.rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, user must be evaluating column privileges.
    -- Check that inputs are valid for column privileges: sub_securable_class must 
    -- be column, securable_class must be object, and permission cannot be any.
    ELSIF cs_as_sub_securable_class IS NOT NULL 
            AND (cs_as_sub_securable_class != 'column' 
                    OR cs_as_securable_class IS NULL 
                    OR cs_as_securable_class != 'object' 
                    OR cs_as_permission = 'any') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null
    ELSIF cs_as_securable IS NULL AND cs_as_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If securable_class is null, securable must be null
    ELSIF cs_as_securable IS NOT NULL AND cs_as_securable_class IS NULL THEN
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'server' THEN
        -- SQL Server does not permit a securable_class value of 'server'.
        -- securable_class should be NULL to evaluate server permissions.
        RETURN NULL;
    ELSIF cs_as_securable_class IS NULL THEN
        -- NULL indicates a server permission. Set this variable so that we can
        -- search for the matching entry in babelfish_has_perms_by_name_permissions
        cs_as_securable_class = 'server';
    END IF;

    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported 
    INTO implied_dbo_permissions,fully_supported 
    FROM babelfish_has_perms_by_name_permissions p 
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;
    
    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name COLLATE sys.database_default) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
                    AND ext.dbid = sys.db_id()) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND
		(SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) = 'dbo' THEN
        RETURN CAST(implied_dbo_permissions AS integer);
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable class.
    -- The block above has dealt with all permissions that are not fully supported, so 
    -- if we reach this point we know the securable class is OBJECT.
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name 
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    -- If schema was not specified, use the default
    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE 
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

	IF database_id <> sys.db_id() THEN
        is_cross_db = true;
	END IF;

	userid := (
        SELECT CASE
            WHEN is_cross_db THEN sys.suser_id()
            ELSE sys.user_id()
        END);
  
    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname 
                    FROM sys.babelfish_namespace_ext ext 
                    WHERE ext.orig_name = bbf_schema_name COLLATE sys.database_default 
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := PG_CATALOG.concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(a.attname)
                        FROM pg_attribute a
                        INNER JOIN pg_class c ON c.oid = a.attrelid
                        INNER JOIN pg_namespace s ON s.oid = c.relnamespace
                        WHERE
                        a.attname = cs_as_sub_securable COLLATE sys.database_default
                        AND c.relname = object_name COLLATE sys.database_default
                        AND s.nspname = pg_schema COLLATE sys.database_default
                        AND NOT a.attisdropped
                        AND (s.nspname IN (SELECT nspname FROM sys.babelfish_namespace_ext) OR s.nspname = 'sys')
                        -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
                        AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
                        AND a.attnum > 0) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname) 
                    FROM pg_catalog.pg_class 
                    WHERE relname = object_name COLLATE sys.database_default
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default 
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'
                
            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );
    
    -- Object was not found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;
  
    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT CAST(oid AS regprocedure) 
            INTO function_signature 
            FROM pg_catalog.pg_proc 
            WHERE proname = object_name COLLATE sys.database_default
                AND pronamespace = namespace_id;
    END IF;

    return_value := (
        SELECT CASE
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(userid, object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(userid, qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(userid, qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
        END
    );

    RETURN return_value;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME, 
    securable_class sys.nvarchar(60), 
    permission sys.SYSNAME, 
    sub_securable sys.SYSNAME,
    sub_securable_class sys.nvarchar(60)) TO PUBLIC;

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
        CASE pg_catalog.LOWER(property_name)
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

CREATE OR REPLACE FUNCTION sys.COL_LENGTH(IN object_name TEXT, IN column_name TEXT)
RETURNS SMALLINT AS $BODY$
DECLARE
    col_name TEXT;
    object_id oid;
    column_id INT;
    column_length SMALLINT;
    column_data_type TEXT;
    typeid oid;
    typelen INT;
    typemod INT;
BEGIN
    -- Get the object ID for the provided object_name
    object_id := sys.OBJECT_ID(object_name, 'U');
    IF object_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Truncate and normalize the column name
    col_name := sys.babelfish_truncate_identifier(sys.babelfish_remove_delimiter_pair(pg_catalog.lower(column_name)));

    -- Get the column ID, typeid, length, and typmod for the provided column_name
    SELECT attnum, a.atttypid, a.attlen, a.atttypmod
    INTO column_id, typeid, typelen, typemod
    FROM pg_attribute a
    WHERE attrelid = object_id AND pg_catalog.lower(attname) = col_name COLLATE sys.database_default;

    IF column_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Get the correct data type
    column_data_type := sys.translate_pg_type_to_tsql(typeid);

    IF column_data_type = 'sysname' THEN
        column_length := 256;
    ELSIF column_data_type IS NULL THEN

        -- Check if it ia user-defined data type
        SELECT sys.translate_pg_type_to_tsql(typbasetype), typlen, typtypmod 
        INTO column_data_type, typelen, typemod
        FROM pg_type
        WHERE oid = typeid;

        IF column_data_type = 'sysname' THEN
            column_length := 256;
        ELSE 
            -- Calculate column length based on base type information
            column_length := sys.tsql_type_max_length_helper(column_data_type, typelen, typemod);
        END IF;
    ELSE
        -- Calculate column length based on base type information
        column_length := sys.tsql_type_max_length_helper(column_data_type, typelen, typemod);
    END IF;

    RETURN column_length;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_year NUMERIC)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day SMALLINT;
    v_month SMALLINT;
    v_year INTEGER;
    v_err_message VARCHAR COLLATE "C";
    v_jdnum DOUBLE PRECISION;
    v_lnum DOUBLE PRECISION;
    v_inum DOUBLE PRECISION;
    v_nnum DOUBLE PRECISION;
    v_jnum DOUBLE PRECISION;
    v_knum DOUBLE PRECISION;
BEGIN
    v_day := floor(p_day)::SMALLINT;
    v_month := floor(p_month)::SMALLINT;
    v_year := floor(p_year)::INTEGER;

    IF ((sign(v_day) = -1) OR (sign(v_month) = -1) OR (sign(v_year) = -1))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_year = 0) THEN
        RAISE null_value_not_allowed;
    END IF;

    v_jdnum = sys.babelfish_get_int_part((11 * v_year + 3) / 30) + 354 * v_year + 30 * v_month -
              sys.babelfish_get_int_part((v_month - 1) / 2) + v_day + 1948440 - 385;

    IF (v_jdnum > 2299160)
    THEN
        v_lnum := v_jdnum + 68569;
        v_nnum := sys.babelfish_get_int_part((4 * v_lnum) / 146097);
        v_lnum := v_lnum - sys.babelfish_get_int_part((146097 * v_nnum + 3) / 4);
        v_inum := sys.babelfish_get_int_part((4000 * (v_lnum + 1)) / 1461001);
        v_lnum := v_lnum - sys.babelfish_get_int_part((1461 * v_inum) / 4) + 31;
        v_jnum := sys.babelfish_get_int_part((80 * v_lnum) / 2447);
        v_day := v_lnum - sys.babelfish_get_int_part((2447 * v_jnum) / 80);
        v_lnum := sys.babelfish_get_int_part(v_jnum / 11);
        v_month := v_jnum + 2 - 12 * v_lnum;
        v_year := 100 * (v_nnum - 49) + v_inum + v_lnum;
    ELSE
        v_jnum := v_jdnum + 1402;
        v_knum := sys.babelfish_get_int_part((v_jnum - 1) / 1461);
        v_lnum := v_jnum - 1461 * v_knum;
        v_nnum := sys.babelfish_get_int_part((v_lnum - 1) / 365) - sys.babelfish_get_int_part(v_lnum / 1461);
        v_inum := v_lnum - 365 * v_nnum + 30;
        v_jnum := sys.babelfish_get_int_part((80 * v_inum) / 2447);
        v_day := v_inum-sys.babelfish_get_int_part((2447 * v_jnum) / 80);
        v_inum := sys.babelfish_get_int_part(v_jnum / 11);
        v_month := v_jnum + 2 - 12 * v_inum;
        v_year := 4 * v_knum + v_nnum + v_inum - 4716;
    END IF;

    RETURN to_date(pg_catalog.concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'Could not convert Hijri to Gregorian date if any part of the date is negative.',
                    DETAIL := 'Some of the supplied date parts (day, month, year) is negative.',
                    HINT := 'Change the value of the date part (day, month, year) wich was found to be negative.';

    WHEN null_value_not_allowed THEN
        RAISE USING MESSAGE := 'Could not convert Hijri to Gregorian date if year value is equal to zero.',
                    DETAIL := 'Supplied year value is equal to zero.',
                    HINT := 'Change the value of the year so that it is greater than zero.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_date(IN p_datestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_style SMALLINT;
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_fractsecs VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP,
                                                    ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_DOTPART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP,
                                                       ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', HHMMSSFS_PART_REGEXP, '$');
    HHMMSSFS_DOT_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', HHMMSSFS_DOTPART_REGEXP, '$');
    v_defmask1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    v_defmask4_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    v_defmask5_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask6_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s*\,\s*', COMPYEAR_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask9_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*($comp_month$)\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    DOT_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', SHORTYEAR_REGEXP, '$');
    DOT_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '$');
    SLASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', SHORTYEAR_REGEXP, '$');
    SLASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', FULLYEAR_REGEXP, '$');
    DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', SHORTYEAR_REGEXP, '$');
    DASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '$');
    DOT_SLASH_DASH_YEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    YEAR_DOTMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    YEAR_SLASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '$');
    YEAR_DASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    YEAR_DOT_SLASH_DASH_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '$');
    DIGITMASK1_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{6}$';
    DIGITMASK2_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{8}$';
BEGIN
    v_style := floor(p_style)::SMALLINT;
    v_datestring := trim(p_datestring);

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datestring ~* HHMMSSFS_PART_REGEXP AND v_datestring !~* HHMMSSFS_REGEXP)
    THEN
        v_datestring := trim(regexp_pg_catalog.replace(v_datestring, HHMMSSFS_PART_REGEXP, '', 'gi'));
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    v_defmask1_regexp := pg_catalog.replace(v_defmask1_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask2_regexp := pg_catalog.replace(v_defmask2_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask3_regexp := pg_catalog.replace(v_defmask3_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask4_regexp := pg_catalog.replace(v_defmask4_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask5_regexp := pg_catalog.replace(v_defmask5_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask6_regexp := pg_catalog.replace(v_defmask6_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask7_regexp := pg_catalog.replace(v_defmask7_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask8_regexp := pg_catalog.replace(v_defmask8_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask9_regexp := pg_catalog.replace(v_defmask9_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask10_regexp := pg_catalog.replace(v_defmask10_regexp, '$comp_month$', v_compmonth_regexp);

    IF (v_datestring ~* v_defmask1_regexp OR
        v_datestring ~* v_defmask2_regexp OR
        v_datestring ~* v_defmask3_regexp OR
        v_datestring ~* v_defmask4_regexp OR
        v_datestring ~* v_defmask5_regexp OR
        v_datestring ~* v_defmask6_regexp OR
        v_datestring ~* v_defmask7_regexp OR
        v_datestring ~* v_defmask8_regexp OR
        v_datestring ~* v_defmask9_regexp OR
        v_datestring ~* v_defmask10_regexp)
    THEN
        IF (v_style IN (130, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* v_defmask1_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask1_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask2_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask2_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask3_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask3_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask4_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask4_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask5_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* v_defmask6_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask6_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* v_defmask7_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask7_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask8_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask8_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask9_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask9_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];
        ELSE
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask10_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSEIF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* DOT_FULLYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_FULLYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_FULLYEAR_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (20, 21, 23, 25, 102, 111, 120, 121, 126, 127)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_YEAR_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22) AND v_date_format <> 'MDY') OR
                ((v_style IS NULL OR v_style IN (0, 1, 10, 22)) AND v_date_format NOT IN ('YDM', 'YMD', 'DMY', 'DYM', 'MYD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   ((v_style IS NULL OR v_style IN (0, 2, 11)) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   ((v_style IS NULL OR v_style IN (0, 3, 4, 5)) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day := v_leftpart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM') THEN
                RAISE character_not_in_repertoire;
            ELSIF (v_style IN (101, 103, 104, 105, 110, 131)) THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_year := v_rightpart;

            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (101, 110) AND v_date_format IN ('YDM', 'DMY', 'DYM')) OR
                       ((v_style IS NULL OR v_style IN (0, 101, 110)) AND v_date_format NOT IN ('YDM', 'DMY', 'DYM')))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22) AND v_date_format <> 'YDM') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22)) AND v_date_format = 'YDM'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 110) AND v_date_format = 'DMY') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22, 101, 110)) AND v_date_format <> 'DMY'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datestring ~* YEAR_DOTMASK_REGEXP OR
           v_datestring ~* YEAR_SLASHMASK_REGEXP OR
           v_datestring ~* YEAR_DASHMASK_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, YEAR_DOT_SLASH_DASH_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

    ELSIF (v_datestring ~* DIGITMASK1_REGEXP OR
           v_datestring ~* DIGITMASK2_REGEXP)
    THEN
        IF (v_datestring ~* DIGITMASK1_REGEXP)
        THEN
            v_day := substring(v_datestring, 5, 2);
            v_month := substring(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substring(v_datestring, 1, 2));
        ELSE
            v_day := substring(v_datestring, 7, 2);
            v_month := substring(v_datestring, 5, 2);
            v_year := substring(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datestring ~* HHMMSSFS_REGEXP)
    THEN
        v_fractsecs := coalesce(sys.babelfish_get_timeunit_from_string(v_datestring, 'FRACTSECONDS'), '');
        IF (v_datestring !~* HHMMSSFS_DOT_REGEXP AND char_length(v_fractsecs) > 3) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datestring ~* HHMMSSFS_REGEXP OR v_datestring ~* DIGITMASK1_REGEXP OR v_datestring ~* DIGITMASK2_REGEXP) AND v_style IN (130, 131)) OR
        ((v_datestring ~* DOT_FULLYEAR_REGEXP OR v_datestring ~* SLASH_FULLYEAR_REGEXP OR v_datestring ~* DASH_FULLYEAR_REGEXP) AND v_style = 131))
    THEN
        IF ((v_day::SMALLINT NOT BETWEEN 1 AND 29) OR
            (v_month::SMALLINT NOT BETWEEN 1 AND 12))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_datestring := to_char(v_hijridate, 'DD.MM.YYYY');

        v_day := split_part(v_datestring, '.', 1);
        v_month := split_part(v_datestring, '.', 2);
        v_year := split_part(v_datestring, '.', 3);
    END IF;

    RETURN to_date(pg_catalog.concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 2 of conv_string_to_date function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to DATE.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

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
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_full_year(IN p_short_year TEXT,
                                                           IN p_base_century TEXT DEFAULT '',
                                                           IN p_year_cutoff NUMERIC DEFAULT 49)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_full_year SMALLINT;
    v_short_year SMALLINT;
    v_base_century SMALLINT;
    v_result_param_set JSONB;
    v_full_year_res_jsonb JSONB;
BEGIN
    v_short_year := p_short_year::SMALLINT;

    BEGIN
        v_full_year_res_jsonb := nullif(current_setting('sys.full_year_res_json'), '')::JSONB;
    EXCEPTION
        WHEN undefined_object THEN
        v_full_year_res_jsonb := NULL;
    END;

    SELECT result
      INTO v_full_year
      FROM jsonb_to_recordset(v_full_year_res_jsonb) AS result_set (param1 SMALLINT,
                                                                    param2 TEXT,
                                                                    param3 NUMERIC,
                                                                    result VARCHAR)
     WHERE param1 = v_short_year
       AND param2 = p_base_century
       AND param3 = p_year_cutoff;

    IF (v_full_year IS NULL)
    THEN
        IF (v_short_year <= 99)
        THEN
            v_base_century := CASE
                                 WHEN (p_base_century ~ '^\s*([1-9]{1,2})\s*$') THEN pg_catalog.concat(trim(p_base_century), '00')::SMALLINT
                                 ELSE trunc(extract(year from current_date)::NUMERIC, -2)
                              END;

            v_full_year = v_base_century + v_short_year;
            v_full_year = CASE
                             WHEN (v_short_year::NUMERIC > p_year_cutoff) THEN v_full_year - 100
                             ELSE v_full_year
                          END;
        ELSE v_full_year := v_short_year;
        END IF;

        v_result_param_set := jsonb_build_object('param1', v_short_year,
                                                 'param2', p_base_century,
                                                 'param3', p_year_cutoff,
                                                 'result', v_full_year);
        v_full_year_res_jsonb := CASE
                                    WHEN (v_full_year_res_jsonb IS NULL) THEN jsonb_build_array(v_result_param_set)
                                    ELSE v_full_year_res_jsonb || v_result_param_set
                                 END;

        PERFORM set_config('sys.full_year_res_json',
                           v_full_year_res_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_full_year;
EXCEPTION
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

CREATE OR REPLACE FUNCTION sys.babelfish_get_microsecs_from_fractsecs(IN p_fractsecs TEXT,
                                                                          IN p_scale NUMERIC DEFAULT 7)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_scale SMALLINT;
    v_decplaces INTEGER;
    v_fractsecs VARCHAR COLLATE "C";
    v_pureplaces VARCHAR COLLATE "C";
    v_rnd_fractsecs INTEGER;
    v_fractsecs_len INTEGER;
    v_pureplaces_len INTEGER;
    v_err_message VARCHAR COLLATE "C";
BEGIN
    v_fractsecs := trim(p_fractsecs);
    v_fractsecs_len := char_length(v_fractsecs);
    v_scale := floor(p_scale)::SMALLINT;

    IF (v_fractsecs_len < 7) THEN
        v_fractsecs := rpad(v_fractsecs, 7, '0');
        v_fractsecs_len := char_length(v_fractsecs);
    END IF;

    v_pureplaces := trim(leading '0' from v_fractsecs);
    v_pureplaces_len := char_length(v_pureplaces);

    v_decplaces := v_fractsecs_len - v_pureplaces_len;

    v_rnd_fractsecs := round(v_fractsecs::INTEGER, (v_pureplaces_len - (v_scale - (v_fractsecs_len - v_pureplaces_len))) * (-1));

    v_fractsecs := pg_catalog.concat(pg_catalog.replace(rpad('', v_decplaces), ' ', '0'), v_rnd_fractsecs);

    RETURN substring(v_fractsecs, 1, CASE
                                        WHEN (v_scale >= 7) THEN 6
                                        ELSE v_scale
                                     END);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(pg_catalog.lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
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
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
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
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
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
        v_datestring ~* pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
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
        IF (v_datestring ~ pg_catalog.concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
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
            (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        IF (v_datestring ~ pg_catalog.concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
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
            (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
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
            (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                   '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);

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
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5])
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
                v_raw_year := sys.babelfish_get_full_year(pg_catalog.substring(v_year::TEXT, 3, 2), '14');

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
            v_timestring := PG_CATALOG.translate(v_timestring, '.,', ': ');

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
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
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
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
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
        v_datetimestring ~* pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
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
        IF (v_datetimestring ~ pg_catalog.concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
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
            (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        IF (v_datetimestring ~ pg_catalog.concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
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
            (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
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
            (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                       '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, v_defmask5_regexp, 'gi');
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);

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
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5])
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
                v_raw_year := sys.babelfish_get_full_year(pg_catalog.substring(v_year::TEXT, 3, 2), '14');

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
            v_timestring := PG_CATALOG.translate(v_timestring, '.,', ': ');

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
            v_seconds := pg_catalog.concat_ws('.', v_seconds, v_fseconds);

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
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
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
        pg_catalog.concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := pg_catalog.concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
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
        v_srctimestring ~* pg_catalog.concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
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
        IF (v_srctimestring ~ pg_catalog.concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
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
            (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
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
        IF (v_srctimestring ~ pg_catalog.concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
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
            (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
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
            (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                      '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, v_defmask5_regexp, 'gi');
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
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
            (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ pg_catalog.concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
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
        v_timestring := pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5]);

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
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE pg_catalog.concat(v_regmatch_groups[1], v_regmatch_groups[5])
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
                v_raw_year := sys.babelfish_get_full_year(pg_catalog.substring(v_year::TEXT, 3, 2), '14');

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
            v_timestring := PG_CATALOG.translate(v_timestring, '.,', ': ');

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
    v_seconds := pg_catalog.concat_ws('.', v_seconds, v_fseconds);

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

CREATE OR REPLACE FUNCTION sys.babelfish_tomsbit(in_str VARCHAR)
RETURNS SMALLINT
AS
$BODY$
BEGIN
  CASE
    WHEN pg_catalog.LOWER(in_str) = 'true' OR in_str = '1' THEN RETURN 1;
    WHEN pg_catalog.LOWER(in_str) = 'false' OR in_str = '0' THEN RETURN 0;
    ELSE RETURN 0;
  END CASE;
END;
$BODY$
LANGUAGE 'plpgsql'
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_split_object_name(
    name TEXT, 
    OUT db_name TEXT, 
    OUT schema_name TEXT, 
    OUT object_name TEXT)
AS $$
DECLARE
    lower_object_name text;
    names text[2];
    counter int;
    cur_pos int;
BEGIN
    lower_object_name = pg_catalog.lower(PG_CATALOG.rtrim(name));

    counter = 1;
    cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);

    -- Parse user input into names split by '.'
    WHILE cur_pos > 0 LOOP
        IF counter > 3 THEN
            -- Too many names provided
            RETURN;
        END IF;

        names[counter] = babelfish_remove_delimiter_pair(PG_CATALOG.rtrim(PG_CATALOG.left(lower_object_name, cur_pos - 1)));
        
        -- invalid name
        IF names[counter] IS NULL THEN
            RETURN;
        END IF;

        lower_object_name = substring(lower_object_name from cur_pos + 1);
        counter = counter + 1;
        cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);
    END LOOP;

    CASE counter
        WHEN 1 THEN
            db_name = NULL;
            schema_name = NULL;
        WHEN 2 THEN
            db_name = NULL;
            schema_name = sys.babelfish_truncate_identifier(names[1]);
        WHEN 3 THEN
            db_name = sys.babelfish_truncate_identifier(names[1]);
            schema_name = sys.babelfish_truncate_identifier(names[2]);
        ELSE
            RETURN;
    END CASE;

    -- Assign each name accordingly
    object_name = sys.babelfish_truncate_identifier(babelfish_remove_delimiter_pair(PG_CATALOG.rtrim(lower_object_name)));
END;
$$
LANGUAGE plpgsql
STABLE;

-- This is a temporary procedure which is only meant to be called during upgrade
CREATE OR REPLACE PROCEDURE sys.babelfish_revoke_guest_from_mapped_logins()
LANGUAGE C
AS 'babelfishpg_tsql', 'revoke_guest_from_mapped_logins';

CALL sys.babelfish_revoke_guest_from_mapped_logins();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_revoke_guest_from_mapped_logins();

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
