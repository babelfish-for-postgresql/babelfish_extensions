-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.1.0'" to load this file. \quit
 
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_view(schema_name varchar, view_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop view %s.%s', schema_name, view_name);
    query2 := format('drop view %s.%s', schema_name, view_name);
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

-- DATABASE_ROLE_MEMBERS
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

CREATE OR REPLACE PROCEDURE BABEL_CREATE_MSDB_IF_NOT_EXISTS_INTERNAL(IN login TEXT)
AS 'babelfishpg_tsql', 'create_msdb_if_not_exists' LANGUAGE C;

CREATE OR REPLACE PROCEDURE BABEL_CREATE_MSDB_IF_NOT_EXISTS()
LANGUAGE PLPGSQL
AS $$
DECLARE
  sa_name TEXT := (SELECT owner FROM sys.babelfish_sysdatabases WHERE dbid=1);
BEGIN
  CALL SYS.BABEL_CREATE_MSDB_IF_NOT_EXISTS_INTERNAL(sa_name);
END
$$;

CALL sys.babel_create_msdb_if_not_exists();

-- Role member functions
CREATE OR REPLACE FUNCTION sys.is_rolemember_internal(
	IN role sys.SYSNAME,
	IN database_principal sys.SYSNAME
)
RETURNS INT AS 'babelfishpg_tsql', 'is_rolemember'
LANGUAGE C STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
	SELECT sys.is_rolemember_internal(role, NULL);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(IN role sys.SYSNAME)
RETURNS INT AS
$$
	SELECT sys.is_rolemember_internal(role, NULL);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(
	IN role sys.SYSNAME,
	IN database_principal sys.SYSNAME
)
RETURNS INT AS
$$
	SELECT sys.is_rolemember_internal(role, database_principal);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

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
					OR lower(orig_username) = lower(@rolename))
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
		AND (Ext.orig_username = @rolename OR lower(Ext.orig_username) = lower(@rolename))
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
					OR lower(orig_username) = lower(@rolename))
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
		AND Ext2.orig_username != 'db_owner';
		AND (Ext1.orig_username = @rolename OR lower(Ext1.orig_username) = lower(@rolename))
		ORDER BY RoleName, MemberName;
	END
	-- If the specified role is not valid
	ELSE
		RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprolemember TO PUBLIC;

alter view sys.indexes rename to indexes_deprecated;

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
    i.indrelid as object_id
    , c.relname as name
    , case when i.indisclustered then 1 else 2 end as type
    , case when i.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as type_desc
    , case when i.indisunique then 1 else 0 end as is_unique
    , c.reltablespace as data_space_id
    , 0 as ignore_dup_key
    , case when i.indisprimary then 1 else 0 end as is_primary_key
    , case when constr.oid is null then 0 else 1 end as is_unique_constraint
    , 0 as fill_factor
    , case when i.indpred is null then 0 else 1 end as is_padded
    , case when i.indisready then 0 else 1 end as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , case when i.indisclustered then 1 else c.oid end as index_id
  from pg_class c
  inner join pg_index i on i.indexrelid = c.oid
  left join pg_constraint constr on constr.conindid = c.oid
  where c.relkind = 'i' and i.indislive
  and (c.relnamespace in (select schema_id from sys.schemas) or c.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(c.relnamespace, 'USAGE')

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
  where t.relkind = 'r'
  and (t.relnamespace in (select schema_id from sys.schemas) or t.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(t.relnamespace, 'USAGE')
  and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

) as indexes_select order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

create or replace view  sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.type::smallint as indid
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

call sys.babelfish_drop_deprecated_view('sys', 'indexes_deprecated');

CREATE OR REPLACE FUNCTION OBJECTPROPERTY(IN object_id INT, IN property sys.varchar)
RETURNS INT AS
$$
BEGIN
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(IN object_id INT, IN property sys.varchar)
RETURNS SYS.SQL_VARIANT AS
$$
BEGIN
    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

ALTER PROCEDURE sys.babel_drop_all_users() RENAME TO babel_drop_all_users_deprecated_2_1;

ALTER VIEW sys.database_principals RENAME TO database_principals_deprecated;
-- sys.database_principals don't have any dependent objects
-- DATABASE_PRINCIPALS
CREATE VIEW sys.database_principals AS SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.OID AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER'
WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
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
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

GRANT SELECT ON sys.database_principals TO PUBLIC;

-- Drop the deprecated view if there isn't any dependent object
CALL sys.babelfish_drop_deprecated_view('sys', 'database_principals_deprecated');

ALTER VIEW sys.server_principals RENAME TO server_principals_deprecated;
-- sys.server_principals is used only in is_srvrolemember() function.
-- Nothing needs to be done for function as body doesn't get changed dynamically.
-- SERVER_PRINCIPALS
CREATE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN' 
WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
ELSE NULL END AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(Ext.is_fixed_role AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

GRANT SELECT ON sys.server_principals TO PUBLIC;

-- We have initialized 'sysadmin' role during initialize_babelfish().
-- Need to initialize it here again for the old users who are upgrading to new
-- babelfish version should have this role in the server_principles view.
CALL sys.babel_initialize_logins('sysadmin');

-- Drop the deprecated view if there isn't any dependent object
CALL sys.babelfish_drop_deprecated_view('sys', 'server_principals_deprecated');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);

-- OPENJSON functions
CREATE OR REPLACE FUNCTION sys.openjson_object(json_string text)
RETURNS TABLE 
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS 
$BODY$
SELECT  key, 
        CASE json_typeof(value) WHEN 'null'     THEN NULL
                                ELSE            TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null'     THEN 0
                                WHEN 'string'   THEN 1
                                WHEN 'number'   THEN 2
                                WHEN 'boolean'  THEN 3
                                WHEN 'array'    THEN 4
                                WHEN 'object'   THEN 5
        END
    FROM json_each(json_string::JSON)
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_array(json_string text)
RETURNS TABLE 
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS 
$BODY$
SELECT  (row_number() over ())-1, 
        CASE json_typeof(value) WHEN 'null'     THEN NULL
                                ELSE            TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null'     THEN 0
                                WHEN 'string'   THEN 1
                                WHEN 'number'   THEN 2
                                WHEN 'boolean'  THEN 3
                                WHEN 'array'    THEN 4
                                WHEN 'object'   THEN 5
        END
    FROM json_array_elements(json_string::JSON) AS value
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_simple(json_string text, path text default '$')
RETURNS TABLE 
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
DECLARE
    sub_json text := sys.json_query(json_string, path);
BEGIN
    IF json_typeof(sub_json::JSON) = 'array' THEN
        RETURN QUERY SELECT * FROM sys.openjson_array(sub_json);
    ELSE
        RETURN QUERY SELECT * FROM sys.openjson_object(sub_json);
    END IF;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.openjson_with(json_string text, path text, VARIADIC column_paths text[])
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_openjson_with' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (clock_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.GETUTCDATE() RETURNS sys.DATETIME AS
$BODY$
SELECT CAST(CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::pg_catalog.text AS sys.DATETIME);
$BODY$
LANGUAGE SQL PARALLEL SAFE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
