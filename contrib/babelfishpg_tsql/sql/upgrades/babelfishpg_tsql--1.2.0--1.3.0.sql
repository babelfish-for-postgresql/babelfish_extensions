-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.3.0'" to load this file. \quit
 
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
 
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);