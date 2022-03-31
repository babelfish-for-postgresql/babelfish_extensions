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

CREATE OR REPLACE FUNCTION sys.suser_name_internal(IN server_user_id OID)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID)
RETURNS sys.NVARCHAR(128) AS $$
    SELECT CASE 
        WHEN server_user_id IS NULL THEN NULL
        ELSE sys.suser_name_internal(server_user_id)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but 
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85))
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT)); 
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sname()
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name();
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id_internal(IN login TEXT)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT)
RETURNS OID AS $$
    SELECT CASE
        WHEN login IS NULL THEN NULL
        ELSE sys.suser_id_internal(login)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id()
RETURNS OID
AS $$
    SELECT sys.suser_id_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but 
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = '' 
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE 
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sid()
RETURNS SYS.VARBINARY(85)
AS $$
    SELECT CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Fix sys.tables columns
ALTER VIEW sys.tables RENAME TO sys_tables_200_upg;
ALTER VIEW sys.objects RENAME TO sys_objects_200_upg;

create or replace view sys.tables as
select
  t.relname::sys._ci_sysname as name
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
  , 0::sys.bit as is_memory_optimized
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

create or replace view sys.objects as
select
      t.name::name
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

create or replace view sys.sysobjects as
select
  s.name
  , s.object_id as id
  , s.type as xtype
  , s.schema_id as uid
  , 0 as info
  , 0 as status
  , 0 as base_schema_ver
  , 0 as replinfo
  , s.parent_object_id as parent_obj
  , s.create_date as crdate
  , 0 as ftcatid
  , 0 as schema_ver
  , 0 as stats_schema_ver
  , s.type
  , 0 as userstat
  , 0 as sysstat
  , 0 as indexdel
  , s.modify_date as refdate
  , 0 as version
  , 0 as deltrig
  , 0 as instrig
  , 0 as updtrig
  , 0 as seltrig
  , 0 as category
  , 0 as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

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

drop view sys_objects_200_upg;
drop view sys_tables_200_upg;

create or replace function sys.get_tds_id(
	datatype varchar(50)
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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
