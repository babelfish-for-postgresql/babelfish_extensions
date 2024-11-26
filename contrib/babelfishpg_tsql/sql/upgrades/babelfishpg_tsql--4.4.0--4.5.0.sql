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

CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
SELECT 
	CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
	CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
	CAST(
		COALESCE(
			(SELECT pg_catalog.string_agg(
				CASE
					WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23 /* prefix length */)
					ELSE NULL
				END, ',')
			FROM unnest(t1.reloptions) AS option),
			t4."TABLE_NAME")
		AS sys.sysname) AS TABLE_NAME,
	CAST(
		COALESCE(
			(SELECT pg_catalog.string_agg(
				CASE
					WHEN option LIKE 'bbf_original_name=%' THEN substring(option, 19 /* prefix length */)
					ELSE NULL
				END, ',')
			FROM unnest(a.attoptions) AS option),
			t4."COLUMN_NAME")
		AS sys.sysname) AS COLUMN_NAME,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,
	CASE 
		WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
		WHEN a.atttypmod != -1
			THEN CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
		WHEN tsql_type_name = 'timestamp'
			THEN 8
		ELSE
			CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
	END AS PRECISION,
	CASE 
		WHEN a.atttypmod != -1
			THEN CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
		ELSE
			CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
	END AS LENGTH,
	CASE 
		WHEN a.atttypmod != -1
			THEN CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
		ELSE
			CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
	END AS SCALE,
	CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
	CASE 
		WHEN t4."IS_NULLABLE" = 'YES'
			THEN CAST(1 AS smallint)
		ELSE
			CAST(0 AS smallint)
	END AS NULLABLE,
	CAST(NULL AS varchar(254)) AS remarks,
	CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,
	CASE 
		WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
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
FROM 
	pg_catalog.pg_class t1
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
	LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
	JOIN information_schema_tsql.columns_internal t4 ON (t1.oid = t4."TABLE_OID")
	LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
	LEFT JOIN pg_type t ON t.oid = a.atttypid
	LEFT JOIN sys.columns t6 ON
	(
		t1.oid = t6.object_id AND
		t4."ORDINAL_POSITION" = t6.column_id
	)
	, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
	, sys.spt_datatype_info_table AS t5
WHERE 
	(t4."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)) OR (t4."DATA_TYPE" = 'bytea' AND t5.TYPE_NAME = 'image'))
	AND ext.dbid = sys.db_id();

GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

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
	-- TODO: we should be able to get rid of babelfish_truncate_identifier when we fix BABEL-5416
	declare @truncated_ident sys.nvarchar(384);
	select @truncated_ident = sys.babelfish_truncate_identifier(pg_catalog.lower(@table_name));
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		where table_name like @truncated_ident COLLATE database_default
			and (coalesce(@table_owner,'') = '' or table_owner like @table_owner collate database_default)
			and (coalesce(@table_qualifier,'') = '' or table_qualifier like @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name like @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
			where table_name = @truncated_ident collate database_default
			and (coalesce(@table_owner, '') = '' or table_owner = @table_owner collate database_default)
			and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name = @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
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
	-- TODO: we should be able to get rid of babelfish_truncate_identifier when we fix BABEL-5416
	declare @truncated_ident sys.nvarchar(384);
	select @truncated_ident = sys.babelfish_truncate_identifier(pg_catalog.lower(@table_name));
	IF @fusepattern = 1 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
		-- TODO: Temporary fix to use \ as escape character for now, need to remove ESCAPE clause from LIKE once we have fixed the dependencies on this procedure
		where table_name like @truncated_ident COLLATE database_default ESCAPE '\' -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_owner,'') = '' or table_owner like @table_owner collate database_default ESCAPE '\') -- '  adding quote in comment to suppress build warning
			and (coalesce(@table_qualifier,'') = '' or table_qualifier like @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name like @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
	ELSE 
		select table_qualifier as TABLE_QUALIFIER, 
			table_owner as TABLE_OWNER,
			table_name as TABLE_NAME,
			column_name as COLUMN_NAME,
			data_type as DATA_TYPE,
			type_name as TYPE_NAME,
			precision as PRECISION,
			length as LENGTH,
			scale as SCALE,
			radix as RADIX,
			nullable as NULLABLE,
			remarks as REMARKS,
			column_def as COLUMN_DEF,
			sql_data_type as SQL_DATA_TYPE,
			sql_datetime_sub as SQL_DATETIME_SUB,
			char_octet_length as CHAR_OCTET_LENGTH,
			ordinal_position as ORDINAL_POSITION,
			is_nullable as IS_NULLABLE,
			ss_is_sparse as SS_IS_SPARSE,
			ss_is_column_set as SS_IS_COLUMN_SET,
			ss_is_computed as SS_IS_COMPUTED,
			ss_is_identity as SS_IS_IDENTITY,
			ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
			ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
			ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
			ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
			ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
			ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
			(
				CASE
					WHEN ss_is_identity = 1 AND sql_data_type = -6 THEN 48 -- Tinyint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 5 THEN 52 -- Smallint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 4 THEN 56 -- Int Identity
					WHEN ss_is_identity = 1 AND sql_data_type = -5 THEN 63 -- Bigint Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 3 THEN 55 -- Decimal Identity
					WHEN ss_is_identity = 1 AND sql_data_type = 2 THEN 63 -- Numeric Identity
					ELSE ss_data_type
				END
			) as SS_DATA_TYPE
		from sys.sp_columns_100_view
			where table_name = @truncated_ident collate database_default
			and (coalesce(@table_owner, '') = '' or table_owner = @table_owner collate database_default)
			and (coalesce(@table_qualifier,'') = '' or table_qualifier = @table_qualifier collate database_default)
			and (coalesce(@column_name,'') = '' or column_name = @column_name collate database_default)
		order by table_qualifier,
				 table_owner,
				 table_name,
				 ordinal_position;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
