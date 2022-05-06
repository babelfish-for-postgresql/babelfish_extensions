-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.1.0'" to load this file. \quit
 
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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
	WHEN idx.is_primary_key != 1
	THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
	ELSE CAST('p' AS sys.sysname)
END AS CONSTRAINT_TYPE,
CAST(idx.name AS sys.sysname) AS CONSTRAINT_NAME,
CAST(idx.index_id AS int) AS INDEX_ID
        
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
	INNER JOIN pg_catalog.pg_attribute i2 ON idx.index_id = i2.attrelid
	INNER JOIN sys.columns c1 ON c1.object_id = idx.object_id AND i2.attname = c1.name

	JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
	JOIN sys.types AS t8 ON c1.user_type_id = t8.user_type_id 
	LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name OR t7.typname = t6.type_name --need in order to get accurate DATA_TYPE value
	LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname
	, sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
	, sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
	WHERE has_schema_privilege(s1.schema_id, 'USAGE');
  
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
DECLARE @constraint_name sys.sysname;
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
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
		  AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
		  AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0)
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
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
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
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
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
		SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier))
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
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
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
				WHERE LOWER(@table_name) = LOWER(table_name)
				AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
				AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
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
 
CREATE OR REPLACE VIEW sys.sp_column_privileges_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(COALESCE(SPLIT_PART(t6.attoptions[1], '=', 2), t5.column_name) AS sys.sysname) AS COLUMN_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantee) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
	JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
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
			WHERE LOWER(@table_name) = LOWER(table_name)
				AND (LOWER('dbo')= LOWER(table_owner))
				AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
				AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
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
		WHERE LOWER(@table_name) = LOWER(table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
			AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
			AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
		ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
	END
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
-- Will use sp_column_priivleges_view to get information from SELECT, INSERT and REFERENCES (only need permission from 1 column in table)
SELECT DISTINCT
CAST(TABLE_QUALIFIER AS sys.sysname) AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) AS IS_GRANTABLE
FROM sys.sp_column_privileges_view

UNION 
-- We need these set of joins only for the DELETE privilege
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type = 'DELETE'; 
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
		WHERE LOWER(TABLE_NAME) = LOWER(@table_name)
			AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) = LOWER(@table_owner))
		ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
	END
	
END; 
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view AS
-- Get parameters (if any) for a user-defined stored procedure/function
(SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 AS smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') AS sys.sysname) AS TYPE_NAME,
	CAST(t6.precision AS int) AS PRECISION,
	CAST(t6.max_length AS int) AS LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable AS smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		ON proc.specific_schema = args.specific_schema AND proc.specific_name = args.specific_name
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id =ext.dbid
	INNER JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
			ON t7.name = t5.type_name
		ON (args.data_type != 'USER-DEFINED' AND args.udt_name = t5.pg_type_name AND t6.name = t7.name)
		OR (args.data_type='USER-DEFINED' AND args.udt_name = t6.name)
	WHERE coalesce(args.parameter_name, '') LIKE '@%'
		AND ext.dbid = sys.db_id()
		AND has_schema_privilege(proc.specific_schema, 'USAGE')

UNION ALL

-- Create row describing return type for a user-defined stored procedure/function
SELECT 
	CAST(d.name AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(ext.orig_name AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 as smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type like '%TABLE%' then CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name

	FROM information_schema.routines proc
	INNER JOIN sys.babelfish_namespace_ext ext ON proc.specific_schema = ext.nspname
	INNER JOIN sys.databases d ON d.database_id = ext.dbid
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		JOIN sys.types t6
		JOIN sys.types t7 ON t6.system_type_id = t7.user_type_id
		ON t7.name = t5.type_name
	ON (proc.data_type != 'USER-DEFINED' 
			AND proc.type_udt_name = t5.pg_type_name 
			AND t6.name = t7.name)
		OR (proc.data_type = 'USER-DEFINED' 
			AND proc.type_udt_name = t6.name),
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE ext.dbid = sys.db_id() AND has_schema_privilege(proc.specific_schema, 'USAGE'))

UNION ALL 

-- Get parameters (if any) for a system stored procedure/function
(SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(args.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CAST(coalesce(args.parameter_name, '') AS sys.sysname) AS COLUMN_NAME,
	CAST(1 as smallint) AS COLUMN_TYPE,
	CAST(t5.data_type AS smallint) AS DATA_TYPE,
	CAST(coalesce(t6.name, '') as sys.sysname) as TYPE_NAME,
	CAST(t6.precision as int) as PRECISION,
	CAST(t6.max_length as int) as LENGTH,
	CAST(t6.scale AS smallint) AS SCALE,
	CAST(t5.num_prec_radix AS smallint) AS RADIX,
	CAST(t6.is_nullable as smallint) AS NULLABLE,
	CAST(NULL AS varchar(254)) AS REMARKS,
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
	CAST(t5.sql_datetime_sub AS smallint) AS SQL_DATETIME_SUB,
	CAST(NULL AS int) AS CHAR_OCTET_LENGTH,
	CAST(args.ordinal_position AS int) AS ORDINAL_POSITION,
	CAST('YES' AS varchar(254)) AS IS_NULLABLE,
	CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	JOIN information_schema.parameters args
		on proc.specific_schema = args.specific_schema
		and proc.specific_name = args.specific_name 
	LEFT JOIN sys.spt_datatype_info_table AS t5 
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
		ON args.udt_name = t5.pg_type_name OR args.udt_name = t5.type_name
	WHERE args.specific_schema ='sys' 
		AND coalesce(args.parameter_name, '') LIKE '@%' 
		AND (args.specific_name LIKE 'sp\_%' 
			OR args.specific_name LIKE 'xp\_%'
			OR args.specific_name LIKE 'dm\_%'
			OR  args.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
		
UNION ALL

-- Create row describing return type for a system stored procedure/function
SELECT 
	CAST((SELECT sys.db_name()) AS sys.sysname) AS PROCEDURE_QUALIFIER,
	CAST(proc.specific_schema AS sys.sysname) AS PROCEDURE_OWNER,
	CASE 
		WHEN proc.routine_type='PROCEDURE' then CAST(CONCAT(proc.routine_name, ';1') AS sys.nvarchar(134)) 
		ELSE CAST(CONCAT(proc.routine_name, ';0') AS sys.nvarchar(134)) 
	END AS PROCEDURE_NAME,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast('@TABLE_RETURN_VALUE' AS sys.sysname)
		ELSE cast('@RETURN_VALUE' AS sys.sysname)
 	END AS COLUMN_NAME,
	 
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(3 AS smallint)
		ELSE CAST(5 AS smallint) 
	END AS COLUMN_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN cast((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN cast(null AS smallint)
		ELSE CAST(t5.data_type AS smallint)
	END AS DATA_TYPE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('int' AS sys.sysname) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('table' AS sys.sysname)
		ELSE CAST(coalesce(t6.name, '') AS sys.sysname) 
	END AS TYPE_NAME,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.precision AS int) 
	END AS PRECISION,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(4 AS int) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS int) 
		ELSE CAST(t6.max_length AS int) 
	END AS LENGTH,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t6.scale AS smallint) 
	END AS SCALE,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(10 AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint) 
		ELSE CAST(t5.num_prec_radix AS smallint) 
	END AS RADIX,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(0 AS smallint)
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS smallint)
		ELSE CAST(t6.is_nullable AS smallint)
	END AS NULLABLE,
	
	CASE 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('Result table returned by table valued function' AS varchar(254)) 
		ELSE CAST(NULL AS varchar(254)) 
	END AS REMARKS,
	
	CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST((SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int') AS smallint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(null AS smallint) 
		ELSE CAST(t5.sql_data_type AS smallint) 
	END AS SQL_DATA_TYPE,
	
	CAST(null AS smallint) AS SQL_DATETIME_SUB,
	CAST(null AS int) AS CHAR_OCTET_LENGTH,
	CAST(0 AS int) AS ORDINAL_POSITION,
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST('NO' AS varchar(254)) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST('NO' AS varchar(254))
		ELSE CAST('YES' AS varchar(254)) 
	END AS IS_NULLABLE,
	
	CASE 
		WHEN proc.routine_type='PROCEDURE' THEN CAST(56 AS sys.tinyint) 
		WHEN pg_function_result_type LIKE '%TABLE%' THEN CAST(0 AS sys.tinyint) 
		ELSE CAST(t5.ss_data_type AS sys.tinyint) 
	END AS SS_DATA_TYPE,
	CAST(proc.routine_name AS sys.nvarchar(134)) AS original_procedure_name
	
	FROM information_schema.routines proc
	INNER JOIN pg_catalog.pg_proc p ON proc.specific_name = p.proname || '_' || p.oid
	LEFT JOIN sys.spt_datatype_info_table AS t5
		LEFT JOIN sys.types t6 ON t6.name = t5.type_name
	ON proc.type_udt_name = t5.pg_type_name OR proc.type_udt_name = t5.type_name, 
	pg_get_function_result(p.oid) AS pg_function_result_type
	WHERE proc.specific_schema = 'sys' 
		AND (proc.specific_name LIKE 'sp\_%' 
			OR proc.specific_name LIKE 'xp\_%' 
			OR proc.specific_name LIKE 'dm\_%'
			OR  proc.specific_name LIKE 'fn\_%')
		AND has_schema_privilege(proc.specific_schema, 'USAGE')
	);	
GRANT SELECT ON sys.sp_sproc_columns_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)	
AS $$
	SELECT @procedure_name = LOWER(COALESCE(@procedure_name, ''))
	SELECT @procedure_owner = LOWER(COALESCE(@procedure_owner, ''))
	SELECT @procedure_qualifier = LOWER(COALESCE(@procedure_qualifier, ''))
	SELECT @column_name = LOWER(COALESCE(@column_Name, ''))
BEGIN 
	IF (@procedure_qualifier != '' AND (SELECT LOWER(sys.db_name())) != @procedure_qualifier)
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
				AND (@column_name = '' OR column_name  LIKE @column_name)
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

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns_100(
	"@procedure_name" sys.nvarchar(390) = '%',
	"@procedure_owner" sys.nvarchar(384) = NULL,
	"@procedure_qualifier" sys.sysname = NULL,
	"@column_name" sys.nvarchar(384) = NULL,
	"@odbcver" int = 2,
	"@fusepattern" sys.bit = '1'
)    
AS $$
BEGIN 
    exec sys.sp_sproc_columns @procedure_name, @procedure_owner, @procedure_qualifier, @column_name, @odbcver, @fusepattern;
END; 
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns_100 TO PUBLIC;
 
-- DATABASE_PRINCIPALS
CREATE OR REPLACE VIEW sys.database_principals AS SELECT
Ext.orig_username AS name,
CAST(Base.OID AS INT) AS principal_id,
Ext.type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER'
WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
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

--DATABASE_ROLE_MEMBERS
CREATE VIEW sys.database_role_members AS
SELECT
CAST(Auth1.oid AS INT) AS role_principal_id,
CAST(Auth2.oid AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_authid AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_authid AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = DB_NAME()
AND Ext2.database_name = DB_NAME()
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';
GRANT SELECT ON sys.database_role_members TO PUBLIC;

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
	CALL sys.babel_drop_all_dbs();
	CALL sys.babel_drop_all_logins();
	EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', CURRENT_DATABASE());
	EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
	DROP OWNED BY sysadmin;
	DROP ROLE sysadmin;
END
$$;

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
    select out_table_qualifier as table_qualifier,
            out_table_owner as table_owner,
            out_table_name as table_name,
			out_non_unique as non_unique,
			out_index_qualifier as index_qualifier,
			out_index_name as index_name,
			out_type as type,
			out_seq_in_index as seq_in_index,
			out_column_name as column_name,
			out_collation as collation,
			out_cardinality as cardinality,
			out_pages as pages,
			out_filter_condition as filter_condition
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics TO PUBLIC;

-- same as sp_statistics
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

create or replace function sys.get_tds_id(
	datatype sys.varchar(50)
)
returns INT
AS $$
DECLARE
	tds_id INT;
BEGIN
	IF datatype IS NULL THEN
		RETURN 0;
	END IF;
	CASE datatype
		WHEN 'text' THEN tds_id = 35;
		WHEN 'uniqueidentifier' THEN tds_id = 36;
		WHEN 'tinyint' THEN tds_id = 38;
		WHEN 'smallint' THEN tds_id = 38;
		WHEN 'int' THEN tds_id = 38;
		WHEN 'bigint' THEN tds_id = 38;
		WHEN 'ntext' THEN tds_id = 99;
		WHEN 'bit' THEN tds_id = 104;
		WHEN 'float' THEN tds_id = 109;
		WHEN 'real' THEN tds_id = 109;
		WHEN 'varchar' THEN tds_id = 167;
		WHEN 'nvarchar' THEN tds_id = 231;
		WHEN 'nchar' THEN tds_id = 239;
		WHEN 'money' THEN tds_id = 110;
		WHEN 'smallmoney' THEN tds_id = 110;
		WHEN 'char' THEN tds_id = 175;
		WHEN 'date' THEN tds_id = 40;
		WHEN 'datetime' THEN tds_id = 111;
		WHEN 'smalldatetime' THEN tds_id = 111;
		WHEN 'numeric' THEN tds_id = 108;
		WHEN 'xml' THEN tds_id = 241;
		WHEN 'decimal' THEN tds_id = 106;
		WHEN 'varbinary' THEN tds_id = 165;
		WHEN 'binary' THEN tds_id = 173;
		WHEN 'image' THEN tds_id = 34;
		WHEN 'time' THEN tds_id = 41;
		WHEN 'datetime2' THEN tds_id = 42;
		WHEN 'sql_variant' THEN tds_id = 98;
		WHEN 'datetimeoffset' THEN tds_id = 43;
		ELSE tds_id = 0;
	END CASE;
	RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace function sys.sp_describe_first_result_set_internal(
	tsqlquery varchar(384),
    params varchar(384) = NULL,
    browseMode sys.tinyint = 0
)
returns table (
	is_hidden sys.bit,
	column_ordinal int,
	name sys.sysname,
	is_nullable sys.bit,
	system_type_id int,
	system_type_name sys.nvarchar(256),
	max_length smallint,
	"precision" sys.tinyint,
	scale sys.tinyint,
	collation_name sys.sysname,
	user_type_id int,
	user_type_database sys.sysname,
	user_type_schema sys.sysname,
	user_type_name sys.sysname,
	assembly_qualified_type_name sys.nvarchar(4000),
	xml_collection_id int,
	xml_collection_database sys.sysname,
	xml_collection_schema sys.sysname,
	xml_collection_name sys.sysname,
	is_xml_document sys.bit,
	is_case_sensitive sys.bit,
	is_fixed_length_clr_type sys.bit,
	source_server sys.sysname,
	source_database sys.sysname,
	source_schema sys.sysname,
	source_table sys.sysname,
	source_column sys.sysname,
	is_identity_column sys.bit,
	is_part_of_unique_key sys.bit,
	is_updateable sys.bit,
	is_computed_column sys.bit,
	is_sparse_column_set sys.bit,
	ordinal_in_order_by_list smallint,
	order_by_list_length smallint,
	order_by_is_descending smallint,
	tds_type_id int,
	tds_length int,
	tds_collation_id int,
	ss_data_type sys.tinyint
)
AS 'babelfishpg_tsql', 'sp_describe_first_result_set_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_first_result_set_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_describe_first_result_set (
	"@tsql" varchar(384),
    "@params" varchar(384) = NULL,
    "@browse_information_mode" sys.tinyint = 0)
AS $$
BEGIN
    select * from sys.sp_describe_first_result_set_internal(@tsql, @params,  @browse_information_mode);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_first_result_set TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id         AS object_id,
        o.schema_id         AS schema_id,
        c.column_id         AS colid,
        CASE WHEN p.attoptions[1] LIKE 'bbf_original_name=%' THEN split_part(p.attoptions[1], '=', 2)
            ELSE c.name END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname AND c.object_id = p.attrelid)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

CREATE COLLATION sys.Japanese_CS_AS (provider = icu, locale = 'ja_JP');
CREATE COLLATION sys.Japanese_CI_AI (provider = icu, locale = 'ja_JP@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Japanese_CI_AS (provider = icu, locale = 'ja_JP@colStrength=secondary', deterministic = false);

-- Remove single pair of either square brackets or double-quotes from outer ends if present
-- If name begins with a delimiter but does not end with the matching delimiter return NULL
-- Otherwise, return the name unchanged
CREATE OR REPLACE FUNCTION babelfish_remove_delimiter_pair(IN name TEXT)
RETURNS TEXT AS
$BODY$
BEGIN
    IF name IN('[', ']', '"') THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '[' AND right(name, 1) = ']' THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '[' AND right(name, 1) != ']' THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '[' AND right(name, 1) = ']' THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '"' AND right(name, 1) = '"' THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '"' AND right(name, 1) != '"' THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '"' AND right(name, 1) = '"' THEN
        RETURN NULL;
    
    END IF;
    RETURN name;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION babelfish_get_name_delimiter_pos(name TEXT)
RETURNS INTEGER
AS $$
DECLARE
    pos int;
BEGIN
    IF (length(name) <= 2 AND (position('"' IN name) != 0 OR position(']' IN name) != 0 OR position('[' IN name) != 0))
        -- invalid name
        THEN RETURN 0;
    ELSIF left(name, 1) = '[' THEN
        pos = position('].' IN name);
        IF pos = 0 THEN 
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 1;
        END IF;
    ELSIF left(name, 1) = '"' THEN
        -- search from position 1 in case name starts with ".
        pos = position('".' IN right(name, length(name) - 1));
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 2;
        END IF;
    ELSE
        RETURN position('.' IN name);
    END IF;
END;
$$
LANGUAGE plpgsql;

-- valid names are db_name.schema_name.object_name or schema_name.object_name or object_name
CREATE OR REPLACE FUNCTION babelfish_split_object_name(
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
    lower_object_name = lower(rtrim(name));

    counter = 1;
    cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);

    -- Parse user input into names split by '.'
    WHILE cur_pos > 0 LOOP
        IF counter > 3 THEN
            -- Too many names provided
            RETURN;
        END IF;

        names[counter] = babelfish_remove_delimiter_pair(rtrim(left(lower_object_name, cur_pos - 1)));
        
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
    object_name = sys.babelfish_truncate_identifier(babelfish_remove_delimiter_pair(rtrim(lower_object_name)));
END;
$$
LANGUAGE plpgsql;

-- Return the object ID given the object name. Can specify optional type.
CREATE OR REPLACE FUNCTION sys.object_id(IN object_name TEXT, IN object_type char(2) DEFAULT '')
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
        IF obj_name IS NULL OR obj_name = '' THEN
            RETURN NULL;
        END IF;

        IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
            bbf_schema_name := sys.schema_name();
        END IF;

        schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

        -- Check if looking for temp object.
        is_temp_object = left(obj_name, 1) = '#';

        -- Can only search in current database. Allowing tempdb for temp objects.
        IF db_name IS NOT NULL AND db_name <> db_name() AND db_name <> 'tempdb' THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;

        IF schema_name IS NULL OR schema_name = '' THEN
            RETURN NULL;
        END IF;

        -- Searching within a schema. Get schema oid.
        schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
        IF schema_oid IS NULL THEN
            RETURN NULL;
        END IF;

        if object_type <> '' then
            case
                -- Schema does not apply as much to temp objects.
                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
	            id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);

                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
	            id := (select oid from pg_class where lower(relname) = obj_name 
                            and relnamespace = schema_oid limit 1);

                when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
	            id := (select oid from pg_constraint where lower(conname) = obj_name 
                            and connamespace = schema_oid limit 1);

                when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
	            id := (select oid from pg_proc where lower(proname) = obj_name 
                            and pronamespace = schema_oid limit 1);

                when upper(object_type) in ('TR', 'TA') then
	            id := (select oid from pg_trigger where lower(tgname) = obj_name limit 1);

                -- Throwing exception as a reminder to add support in the future.
                when upper(object_type) in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                    RAISE EXCEPTION 'Object type currently unsupported.';

                -- unsupported object_type
                else id := null;
            end case;
        else
            if not is_temp_object then id := (
                                            select oid from pg_class where lower(relname) = obj_name
                                                and relnamespace = schema_oid
				            union
			                select oid from pg_constraint where lower(conname) = obj_name
				            and connamespace = schema_oid
                                                union
			                select oid from pg_proc where lower(proname) = obj_name
				            and pronamespace = schema_oid
                                                union
			                select oid from pg_trigger where lower(tgname) = obj_name
			                limit 1);
            else
                -- temp object without "object_type" in-argument
                id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);
            end if;
        end if;

        RETURN id::integer;
END;
$BODY$
LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;

DROP FUNCTION IF EXISTS sys.babelfish_single_unbracket_name;

CREATE OR REPLACE FUNCTION has_any_privilege(
    perm_target_type text,
    schema_name text,
    object_name text)
RETURNS INTEGER
AS
$BODY$
DECLARE 
    relevant_permissions text[];
    namespace_id oid;
    function_signature text;
    qualified_name text;
    permission text;
BEGIN
	IF perm_target_type IS NULL OR perm_target_type NOT IN('table', 'function', 'procedure')
        THEN RETURN NULL;
    END IF;

    relevant_permissions := (
        SELECT CASE
            WHEN perm_target_type = 'table'
                THEN '{"select", "insert", "update", "delete", "references"}'
            WHEN perm_target_type = 'column'
                THEN '{"select", "update", "references"}'
            WHEN perm_target_type IN('function', 'procedure')
                THEN '{"execute"}'
        END
    );

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = schema_name;

    IF perm_target_type IN('function', 'procedure')
        THEN SELECT oid::regprocedure 
                INTO function_signature 
                FROM pg_catalog.pg_proc 
                WHERE proname = object_name
                    AND pronamespace = namespace_id;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', schema_name, '"."', object_name, '"');

    FOREACH permission IN ARRAY relevant_permissions
    LOOP
        IF perm_target_type = 'table' AND has_table_privilege(qualified_name, permission)::integer = 1
            THEN RETURN 1;
        ELSIF perm_target_type IN('function', 'procedure') AND has_function_privilege(function_signature, permission)::integer = 1
            THEN RETURN 1;
        END IF;
    END LOOP;
    RETURN 0;
END
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW has_perms_by_name_view
AS
SELECT t.securable_type,t.permission_name,t.implied_dbo_permissions,t.fully_supported FROM
(
  VALUES
    ('application role', 'alter', 'f', 'f'),
    ('application role', 'any', 'f', 'f'),
    ('application role', 'control', 'f', 'f'),
    ('application role', 'view definition', 'f', 'f'),
    ('assembly', 'alter', 'f', 'f'),
    ('assembly', 'any', 'f', 'f'),
    ('assembly', 'control', 'f', 'f'),
    ('assembly', 'references', 'f', 'f'),
    ('assembly', 'take ownership', 'f', 'f'),
    ('assembly', 'view definition', 'f', 'f'),
    ('asymmetric key', 'alter', 'f', 'f'),
    ('asymmetric key', 'any', 'f', 'f'),
    ('asymmetric key', 'control', 'f', 'f'),
    ('asymmetric key', 'references', 'f', 'f'),
    ('asymmetric key', 'take ownership', 'f', 'f'),
    ('asymmetric key', 'view definition', 'f', 'f'),
    ('availability group', 'alter', 'f', 'f'),
    ('availability group', 'any', 'f', 'f'),
    ('availability group', 'control', 'f', 'f'),
    ('availability group', 'take ownership', 'f', 'f'),
    ('availability group', 'view definition', 'f', 'f'),
    ('certificate', 'alter', 'f', 'f'),
    ('certificate', 'any', 'f', 'f'),
    ('certificate', 'control', 'f', 'f'),
    ('certificate', 'references', 'f', 'f'),
    ('certificate', 'take ownership', 'f', 'f'),
    ('certificate', 'view definition', 'f', 'f'),
    ('contract', 'alter', 'f', 'f'),
    ('contract', 'any', 'f', 'f'),
    ('contract', 'control', 'f', 'f'),
    ('contract', 'references', 'f', 'f'),
    ('contract', 'take ownership', 'f', 'f'),
    ('contract', 'view definition', 'f', 'f'),
    ('database', 'administer database bulk operations', 'f', 'f'),
    ('database', 'alter', 't', 'f'),
    ('database', 'alter any application role', 'f', 'f'),
    ('database', 'alter any assembly', 'f', 'f'),
    ('database', 'alter any asymmetric key', 'f', 'f'),
    ('database', 'alter any certificate', 'f', 'f'),
    ('database', 'alter any column encryption key', 'f', 'f'),
    ('database', 'alter any column master key', 'f', 'f'),
    ('database', 'alter any contract', 'f', 'f'),
    ('database', 'alter any database audit', 'f', 'f'),
    ('database', 'alter any database ddl trigger', 'f', 'f'),
    ('database', 'alter any database event notification', 'f', 'f'),
    ('database', 'alter any database event session', 'f', 'f'),
    ('database', 'alter any database scoped configuration', 'f', 'f'),
    ('database', 'alter any dataspace', 'f', 'f'),
    ('database', 'alter any external data source', 'f', 'f'),
    ('database', 'alter any external file format', 'f', 'f'),
    ('database', 'alter any external language', 'f', 'f'),
    ('database', 'alter any external library', 'f', 'f'),
    ('database', 'alter any fulltext catalog', 'f', 'f'),
    ('database', 'alter any mask', 'f', 'f'),
    ('database', 'alter any message type', 'f', 'f'),
    ('database', 'alter any remote service binding', 'f', 'f'),
    ('database', 'alter any role', 'f', 'f'),
    ('database', 'alter any route', 'f', 'f'),
    ('database', 'alter any schema', 't', 'f'),
    ('database', 'alter any security policy', 'f', 'f'),
    ('database', 'alter any sensitivity classification', 'f', 'f'),
    ('database', 'alter any service', 'f', 'f'),
    ('database', 'alter any symmetric key', 'f', 'f'),
    ('database', 'alter any user', 't', 'f'),
    ('database', 'any', 't', 'f'),
    ('database', 'authenticate', 't', 'f'),
    ('database', 'backup database', 'f', 'f'),
    ('database', 'backup log', 'f', 'f'),
    ('database', 'checkpoint', 'f', 'f'),
    ('database', 'connect', 't', 'f'),
    ('database', 'connect replication', 'f', 'f'),
    ('database', 'control', 't', 'f'),
    ('database', 'create aggregate', 'f', 'f'),
    ('database', 'create assembly', 'f', 'f'),
    ('database', 'create asymmetric key', 'f', 'f'),
    ('database', 'create certificate', 'f', 'f'),
    ('database', 'create contract', 'f', 'f'),
    ('database', 'create database', 't', 'f'),
    ('database', 'create database ddl event notification', 'f', 'f'),
    ('database', 'create default', 'f', 'f'),
    ('database', 'create external language', 'f', 'f'),
    ('database', 'create external library', 'f', 'f'),
    ('database', 'create fulltext catalog', 'f', 'f'),
    ('database', 'create function', 't', 'f'),
    ('database', 'create message type', 'f', 'f'),
    ('database', 'create procedure', 't', 'f'),
    ('database', 'create queue', 'f', 'f'),
    ('database', 'create remote service binding', 'f', 'f'),
    ('database', 'create role', 'f', 'f'),
    ('database', 'create route', 'f', 'f'),
    ('database', 'create rule', 'f', 'f'),
    ('database', 'create schema', 't', 'f'),
    ('database', 'create service', 'f', 'f'),
    ('database', 'create symmetric key', 'f', 'f'),
    ('database', 'create synonym', 't', 'f'),
    ('database', 'create table', 't', 'f'),
    ('database', 'create type', 'f', 'f'),
    ('database', 'create view', 't', 'f'),
    ('database', 'create xml schema collection', 'f', 'f'),
    ('database', 'delete', 't', 'f'),
    ('database', 'execute', 't', 'f'),
    ('database', 'execute any external script', 'f', 'f'),
    ('database', 'insert', 't', 'f'),
    ('database', 'kill database connection', 'f', 'f'),
    ('database', 'references', 't', 'f'),
    ('database', 'select', 't', 'f'),
    ('database', 'showplan', 'f', 'f'),
    ('database', 'subscribe query notifications', 'f', 'f'),
    ('database', 'take ownership', 't', 'f'),
    ('database', 'unmask', 'f', 'f'),
    ('database', 'update', 't', 'f'),
    ('database', 'view any column encryption key definition', 'f', 'f'),
    ('database', 'view any column master key definition', 'f', 'f'),
    ('database', 'view any sensitivity classification', 'f', 'f'),
    ('database', 'view database state', 't', 'f'),
    ('database', 'view definition', 'f', 'f'),
    ('database scoped credential', 'alter', 'f', 'f'),
    ('database scoped credential', 'any', 'f', 'f'),
    ('database scoped credential', 'control', 'f', 'f'),
    ('database scoped credential', 'references', 'f', 'f'),
    ('database scoped credential', 'take ownership', 'f', 'f'),
    ('database scoped credential', 'view definition', 'f', 'f'),
    ('endpoint', 'alter', 'f', 'f'),
    ('endpoint', 'any', 'f', 'f'),
    ('endpoint', 'connect', 'f', 'f'),
    ('endpoint', 'control', 'f', 'f'),
    ('endpoint', 'take ownership', 'f', 'f'),
    ('endpoint', 'view definition', 'f', 'f'),
    ('external language', 'alter', 'f', 'f'),
    ('external language', 'any', 'f', 'f'),
    ('external language', 'control', 'f', 'f'),
    ('external language', 'execute external script', 'f', 'f'),
    ('external language', 'references', 'f', 'f'),
    ('external language', 'take ownership', 'f', 'f'),
    ('external language', 'view definition', 'f', 'f'),
    ('fulltext catalog', 'alter', 'f', 'f'),
    ('fulltext catalog', 'any', 'f', 'f'),
    ('fulltext catalog', 'control', 'f', 'f'),
    ('fulltext catalog', 'references', 'f', 'f'),
    ('fulltext catalog', 'take ownership', 'f', 'f'),
    ('fulltext catalog', 'view definition', 'f', 'f'),
    ('fulltext stoplist', 'alter', 'f', 'f'),
    ('fulltext stoplist', 'any', 'f', 'f'),
    ('fulltext stoplist', 'control', 'f', 'f'),
    ('fulltext stoplist', 'references', 'f', 'f'),
    ('fulltext stoplist', 'take ownership', 'f', 'f'),
    ('fulltext stoplist', 'view definition', 'f', 'f'),
    ('login', 'alter', 'f', 'f'),
    ('login', 'any', 'f', 'f'),
    ('login', 'control', 'f', 'f'),
    ('login', 'impersonate', 'f', 'f'),
    ('login', 'view definition', 'f', 'f'),
    ('message type', 'alter', 'f', 'f'),
    ('message type', 'any', 'f', 'f'),
    ('message type', 'control', 'f', 'f'),
    ('message type', 'references', 'f', 'f'),
    ('message type', 'take ownership', 'f', 'f'),
    ('message type', 'view definition', 'f', 'f'),
    ('object', 'alter', 't', 'f'),
    ('object', 'any', 't', 't'),
    ('object', 'control', 't', 'f'),
    ('object', 'delete', 't', 't'),
    ('object', 'execute', 't', 't'),
    ('object', 'insert', 't', 't'),
    ('object', 'receive', 'f', 'f'),
    ('object', 'references', 't', 't'),
    ('object', 'select', 't', 't'),
    ('object', 'take ownership', 'f', 'f'),
    ('object', 'update', 't', 't'),
    ('object', 'view change tracking', 'f', 'f'),
    ('object', 'view definition', 'f', 'f'),
    ('remote service binding', 'alter', 'f', 'f'),
    ('remote service binding', 'any', 'f', 'f'),
    ('remote service binding', 'control', 'f', 'f'),
    ('remote service binding', 'take ownership', 'f', 'f'),
    ('remote service binding', 'view definition', 'f', 'f'),
    ('role', 'alter', 'f', 'f'),
    ('role', 'any', 'f', 'f'),
    ('role', 'control', 'f', 'f'),
    ('role', 'take ownership', 'f', 'f'),
    ('role', 'view definition', 'f', 'f'),
    ('route', 'alter', 'f', 'f'),
    ('route', 'any', 'f', 'f'),
    ('route', 'control', 'f', 'f'),
    ('route', 'take ownership', 'f', 'f'),
    ('route', 'view definition', 'f', 'f'),
    ('schema', 'alter', 't', 'f'),
    ('schema', 'any', 't', 'f'),
    ('schema', 'control', 't', 'f'),
    ('schema', 'create sequence', 'f', 'f'),
    ('schema', 'delete', 't', 'f'),
    ('schema', 'execute', 't', 'f'),
    ('schema', 'insert', 't', 'f'),
    ('schema', 'references', 't', 'f'),
    ('schema', 'select', 't', 'f'),
    ('schema', 'take ownership', 't', 'f'),
    ('schema', 'update', 't', 'f'),
    ('schema', 'view change tracking', 'f', 'f'),
    ('schema', 'view definition', 'f', 'f'),
    ('search property list', 'alter', 'f', 'f'),
    ('search property list', 'any', 'f', 'f'),
    ('search property list', 'control', 'f', 'f'),
    ('search property list', 'references', 'f', 'f'),
    ('search property list', 'take ownership', 'f', 'f'),
    ('search property list', 'view definition', 'f', 'f'),
    ('server', 'administer bulk operations', 'f', 'f'),
    ('server', 'alter any availability group', 'f', 'f'),
    ('server', 'alter any connection', 'f', 'f'),
    ('server', 'alter any credential', 'f', 'f'),
    ('server', 'alter any database', 't', 'f'),
    ('server', 'alter any endpoint', 'f', 'f'),
    ('server', 'alter any event notification', 'f', 'f'),
    ('server', 'alter any event session', 'f', 'f'),
    ('server', 'alter any linked server', 'f', 'f'),
    ('server', 'alter any login', 'f', 'f'),
    ('server', 'alter any server audit', 'f', 'f'),
    ('server', 'alter any server role', 'f', 'f'),
    ('server', 'alter resources', 'f', 'f'),
    ('server', 'alter server state', 'f', 'f'),
    ('server', 'alter settings', 't', 'f'),
    ('server', 'alter trace', 'f', 'f'),
    ('server', 'any', 't', 'f'),
    ('server', 'authenticate server', 't', 'f'),
    ('server', 'connect any database', 't', 'f'),
    ('server', 'connect sql', 't', 'f'),
    ('server', 'control server', 't', 'f'),
    ('server', 'create any database', 't', 'f'),
    ('server', 'create availability group', 'f', 'f'),
    ('server', 'create ddl event notification', 'f', 'f'),
    ('server', 'create endpoint', 'f', 'f'),
    ('server', 'create server role', 'f', 'f'),
    ('server', 'create trace event notification', 'f', 'f'),
    ('server', 'external access assembly', 'f', 'f'),
    ('server', 'impersonate any login', 'f', 'f'),
    ('server', 'select all user securables', 't', 'f'),
    ('server', 'shutdown', 'f', 'f'),
    ('server', 'unsafe assembly', 'f', 'f'),
    ('server', 'view any database', 't', 'f'),
    ('server', 'view any definition', 'f', 'f'),
    ('server', 'view server state', 't', 'f'),
    ('server role', 'alter', 'f', 'f'),
    ('server role', 'any', 'f', 'f'),
    ('server role', 'control', 'f', 'f'),
    ('server role', 'take ownership', 'f', 'f'),
    ('server role', 'view definition', 'f', 'f'),
    ('service', 'alter', 'f', 'f'),
    ('service', 'any', 'f', 'f'),
    ('service', 'control', 'f', 'f'),
    ('service', 'send', 'f', 'f'),
    ('service', 'take ownership', 'f', 'f'),
    ('service', 'view definition', 'f', 'f'),
    ('symmetric key', 'alter', 'f', 'f'),
    ('symmetric key', 'any', 'f', 'f'),
    ('symmetric key', 'control', 'f', 'f'),
    ('symmetric key', 'references', 'f', 'f'),
    ('symmetric key', 'take ownership', 'f', 'f'),
    ('symmetric key', 'view definition', 'f', 'f'),
    ('type', 'any', 'f', 'f'),
    ('type', 'control', 'f', 'f'),
    ('type', 'execute', 'f', 'f'),
    ('type', 'references', 'f', 'f'),
    ('type', 'take ownership', 'f', 'f'),
    ('type', 'view definition', 'f', 'f'),
    ('user', 'alter', 'f', 'f'),
    ('user', 'any', 'f', 'f'),
    ('user', 'control', 'f', 'f'),
    ('user', 'impersonate', 'f', 'f'),
    ('user', 'view definition', 'f', 'f'),
    ('xml schema collection', 'alter', 'f', 'f'),
    ('xml schema collection', 'any', 'f', 'f'),
    ('xml schema collection', 'control', 'f', 'f'),
    ('xml schema collection', 'execute', 'f', 'f'),
    ('xml schema collection', 'references', 'f', 'f'),
    ('xml schema collection', 'take ownership', 'f', 'f'),
    ('xml schema collection', 'view definition', 'f', 'f')
) t(securable_type, permission_name, implied_dbo_permissions, fully_supported);
GRANT SELECT ON has_perms_by_name_view TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    db_name text COLLATE "C"; 
    bbf_schema_name text;
    pg_schema text COLLATE "C";
    implied_dbo_permissions boolean;
    fully_supported boolean;
    object_name text COLLATE "C";
    database_id smallint;
    namespace_id oid;
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
    cs_as_securable = lower(rtrim(cs_as_securable));
    cs_as_securable_class = lower(rtrim(cs_as_securable_class));
    cs_as_permission = lower(rtrim(cs_as_permission));
    cs_as_sub_securable = lower(rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, sub_securable_class must be set to 'column' and securable_class to 'object'
    -- Additionally, permission cannot be 'any' when checking column privileges
    ELSIF cs_as_sub_securable IS NOT NULL 
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

    IF cs_as_securable_class IS NULL THEN
        cs_as_securable_class = 'server';
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported 
    INTO implied_dbo_permissions,fully_supported 
    FROM has_perms_by_name_view p 
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;
    
    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name 
                    AND ext.dbid::oid = sys.db_id()::oid) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND CURRENT_USER IN('dbo', 'master_dbo', 'tempdb_dbo', 'msdb_dbo') THEN
        RETURN implied_dbo_permissions::integer;
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable
    -- If we reach this point we know the securable type is OBJECT
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name 
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE 
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);
  
    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname 
                    FROM sys.babelfish_namespace_ext ext 
                    WHERE ext.orig_name = bbf_schema_name 
                        AND ext.dbid::oid = database_id::oid);

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema;
    
    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE 
                    WHEN (SELECT count(name) 
                        FROM sys.all_columns 
                        WHERE name = cs_as_sub_securable
                            -- Use V as the object type to specify that the securable is table-like.
                            -- We don't know that the securable is a view, but object_id behaves the 
                            -- same for differint table-like types, so V can be arbitrarily chosen.
                            AND object_id = sys.object_id(cs_as_securable, 'V')) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname) 
                    FROM pg_catalog.pg_class 
                    WHERE relname = object_name 
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name 
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'
                
            WHEN (SELECT count(proname) 
                    FROM pg_catalog.pg_proc 
                    WHERE proname = object_name 
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );
    
    -- Object wasn't found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;
  
    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT oid::regprocedure 
            INTO function_signature 
            FROM pg_catalog.pg_proc 
            WHERE proname = object_name 
                AND pronamespace = namespace_id;
    END IF;

	return_value := (
        SELECT CASE            
            WHEN cs_as_permission = 'any' THEN has_any_privilege(object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE has_column_privilege(qualified_name, cs_as_sub_securable, cs_as_permission)::integer
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE has_table_privilege(qualified_name, cs_as_permission)::integer
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN has_function_privilege(function_signature, 'execute')::integer
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN has_function_privilege(function_signature, 'execute')::integer
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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
