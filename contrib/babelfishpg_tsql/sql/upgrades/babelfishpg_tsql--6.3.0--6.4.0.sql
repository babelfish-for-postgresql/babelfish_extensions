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

-- Global batch query antlr parse cache statistics
CREATE OR REPLACE FUNCTION sys.antlr_batch_parse_cache_stats(
    OUT cache_hits BIGINT,
    OUT cache_misses BIGINT,
    OUT cache_writes BIGINT,
    OUT cache_evictions BIGINT,
    OUT cache_errors BIGINT,
    OUT cache_entries BIGINT
) RETURNS RECORD
AS 'babelfishpg_tsql', 'antlr_batch_parse_cache_stats'
LANGUAGE C VOLATILE PARALLEL RESTRICTED;

-- Flush all entries from the batch query antlr parse cache
-- Returns true if any entries were flushed, false if cache was already empty
CREATE OR REPLACE FUNCTION sys.flush_antlr_batch_parse_cache()
RETURNS BOOLEAN
AS 'babelfishpg_tsql', 'flush_antlr_batch_parse_cache'
LANGUAGE C VOLATILE PARALLEL UNSAFE;

-- List all entries in the batch query antlr parse cache
CREATE OR REPLACE FUNCTION sys.antlr_batch_parse_cache_entries(
    OUT cache_key BIGINT,
    OUT created_at sys.DATETIME,
    OUT last_used_at sys.DATETIME,
    OUT query_text_len INT,
    OUT parse_tree_len INT,
    OUT parse_datums_len INT,
    OUT bbf_version TEXT
) RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'antlr_batch_parse_cache_entries'
LANGUAGE C VOLATILE PARALLEL RESTRICTED;

-- Attribute versioning stores a reserved 'pg_attver=<lsn>' entry as the first element of
-- pg_attribute.attoptions on every column, so the original T-SQL column name can no
-- longer be read positionally from attoptions[1]. Look it up by name instead, matching
-- how these same objects already read bbf_original_rel_name from reloptions.

CREATE OR REPLACE FUNCTION sys.sp_column_privileges_internal()
RETURNS TABLE (
    TABLE_QUALIFIER sys.sysname,
    TABLE_OWNER sys.sysname,
    TABLE_NAME sys.sysname,
    COLUMN_NAME sys.sysname,
    GRANTOR sys.sysname,
    GRANTEE sys.sysname,
    PRIVILEGE sys.varchar(32),
    IS_GRANTABLE sys.varchar(3)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
        CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
        CAST(COALESCE(
            CASE WHEN pg_catalog.octet_length(t1.relname) >= 60 THEN
                (SELECT pg_catalog.lower(pg_catalog.substring(opt, 23) COLLATE "C")
                 FROM pg_catalog.unnest(t1.reloptions) opt
                 WHERE opt LIKE 'bbf_original_rel_name=%'
                 LIMIT 1)
            END,
            t1.relname::text) AS sys.sysname) AS TABLE_NAME,
        CAST(COALESCE(
            (SELECT pg_catalog.substring(opt, pg_catalog.length('bbf_original_name=') + 1) COLLATE "C"
             FROM pg_catalog.unnest(t6.attoptions) opt
             WHERE opt LIKE 'bbf_original_name=%'
             LIMIT 1),
            t5.column_name) AS sys.sysname) AS COLUMN_NAME,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t5.grantor::name) AS sys.sysname) AS GRANTOR,
        CAST((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = t5.grantee::name) AS sys.sysname) AS GRANTEE,
        CAST(t5.privilege_type AS sys.varchar(32)) COLLATE sys.database_default AS PRIVILEGE,
        CAST(t5.is_grantable AS sys.varchar(3)) COLLATE sys.database_default AS IS_GRANTABLE
    FROM pg_catalog.pg_class t1 
        JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
        JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
        JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
        JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
END;
$$ LANGUAGE plpgsql STABLE PARALLEL SAFE;

CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
-- get original column name if exists
CAST(coalesce(
    (SELECT pg_catalog.substring(opt, pg_catalog.length('bbf_original_name=') + 1) COLLATE "C"
     FROM pg_catalog.unnest(a.attoptions) opt
     WHERE opt LIKE 'bbf_original_name=%'
     LIMIT 1),
    a.attname) AS sys.sysname) AS COLUMN_NAME,
CAST(t6.data_type AS SMALLINT) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN  a.attidentity <> ''::"char" AND (t1.name = 'decimal' OR t1.name = 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, '() identity') AS sys.sysname)
	WHEN  a.attidentity <> ''::"char" AND (t1.name != 'decimal' AND t1.name != 'numeric')
	THEN CAST(PG_CATALOG.CONCAT(t1.name, ' identity') AS sys.sysname)
	ELSE CAST(t1.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(COALESCE(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS SMALLINT) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CASE
	WHEN a.attnotnull
	THEN CAST(0 AS INT)
	ELSE CAST(1 AS INT) END
AS IS_NULLABLE,
CAST(nsp_ext.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
COALESCE(
    CASE WHEN pg_catalog.octet_length(C.relname) >= 60 THEN
        (SELECT pg_catalog.lower(pg_catalog.substring(opt, 23) COLLATE "C")
         FROM pg_catalog.unnest(C.reloptions) opt
         WHERE opt LIKE 'bbf_original_rel_name=%'
         LIMIT 1)
    END,
    C.relname::text)::sys.sysname AS TABLE_NAME,

CASE 
	WHEN X.indisprimary
	THEN CAST('p' AS sys.sysname)
	ELSE CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
END AS CONSTRAINT_TYPE,
CAST(I.relname AS sys.sysname) CONSTRAINT_NAME,
CAST(X.indexrelid AS int) AS INDEX_ID

FROM( pg_index X
JOIN pg_class C ON X.indrelid = C.oid
JOIN pg_class I ON I.oid = X.indexrelid
CROSS JOIN LATERAL unnest(X.indkey) AS ak(k)
        LEFT JOIN pg_attribute a
                       ON (a.attrelid = X.indrelid AND a.attnum = ak.k)
)
LEFT JOIN sys.pg_namespace_ext nsp_ext ON C.relnamespace = nsp_ext.oid
LEFT JOIN sys.schemas s1 ON s1.schema_id = C.relnamespace
LEFT JOIN sys.columns c1 ON c1.object_id = X.indrelid AND cast(a.attname AS sys.sysname) = c1.name COLLATE sys.database_default
LEFT JOIN pg_catalog.pg_type AS T ON T.oid = c1.system_type_id
LEFT JOIN sys.types AS t1 ON a.atttypid = t1.user_type_id
LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON T.typname = t6.pg_type_name OR T.typname = t6.type_name --need in order to get accurate DATA_TYPE value
, sys.translate_pg_type_to_tsql(t1.user_type_id) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t1.system_type_id) AS tsql_base_type_name
WHERE X.indislive ;

GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
COALESCE(
    CASE WHEN pg_catalog.octet_length(c2.relname) >= 60 THEN
        (SELECT pg_catalog.lower(pg_catalog.substring(opt, 23) COLLATE "C")
         FROM pg_catalog.unnest(c2.reloptions) opt
         WHERE opt LIKE 'bbf_original_rel_name=%'
         LIMIT 1)
    END,
    c2.relname::text)::sys.sysname AS PKTABLE_NAME,
CAST(COALESCE(
    (SELECT pg_catalog.substring(opt, pg_catalog.length('bbf_original_name=') + 1) COLLATE "C"
     FROM pg_catalog.unnest(a2.attoptions) opt
     WHERE opt LIKE 'bbf_original_name=%'
     LIMIT 1),
    a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
COALESCE(
    CASE WHEN pg_catalog.octet_length(c.relname) >= 60 THEN
        (SELECT pg_catalog.lower(pg_catalog.substring(opt, 23) COLLATE "C")
         FROM pg_catalog.unnest(c.reloptions) opt
         WHERE opt LIKE 'bbf_original_rel_name=%'
         LIMIT 1)
    END,
    c.relname::text)::sys.sysname AS FKTABLE_NAME,
CAST(COALESCE(
    (SELECT pg_catalog.substring(opt, pg_catalog.length('bbf_original_name=') + 1) COLLATE "C"
     FROM pg_catalog.unnest(a.attoptions) opt
     WHERE opt LIKE 'bbf_original_name=%'
     LIMIT 1),
    a.attname) AS sys.sysname) AS FKCOLUMN_NAME,
CAST(nr AS smallint) AS KEY_SEQ,
CASE
   WHEN const1.confupdtype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confupdtype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confupdtype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confupdtype = 'd' THEN CAST(3 AS smallint) -- set default
END AS UPDATE_RULE,

CASE
   WHEN const1.confdeltype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confdeltype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confdeltype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confdeltype = 'd' THEN CAST(3 AS smallint) -- set default
   ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(COALESCE(
		CASE WHEN octet_length(const1.conname) >= 60 THEN
			(SELECT pg_catalog.lower(m.original_identifier_name COLLATE "C")
			 FROM sys.babelfish_identifier_mapping m
			 WHERE m.truncated_identifier_name = const1.conname
				 AND m.nspname = nsp_ext.nspname
				 AND m.pg_catalog_type = 'pg_constraint'::regclass::oid
				 AND m.parent_name = c.relname
			 LIMIT 1)
		END,
		const1.conname::text) AS sys.sysname) AS FK_NAME,
CAST(COALESCE(
		CASE WHEN octet_length(const2.conname) >= 60 THEN
			(SELECT pg_catalog.lower(m.original_identifier_name COLLATE "C")
			 FROM sys.babelfish_identifier_mapping m
			 WHERE m.truncated_identifier_name = const2.conname
				 AND m.nspname = nsp_ext2.nspname
				 AND m.pg_catalog_type = 'pg_constraint'::regclass::oid
				 AND m.parent_name = c2.relname
			 LIMIT 1)
		END,
		const2.conname::text) AS sys.sysname) AS PK_NAME,
CASE
   WHEN const1.condeferrable = false THEN CAST(7 as smallint) -- not deferrable
   ELSE (CASE WHEN const1.condeferred = false THEN CAST(6 as smallint) --  not deferred by default
              ELSE CAST(5 as smallint) -- deferred by default
         END)
END AS DEFERRABILITY

FROM (pg_constraint const1
-- join with nsp_Ext to get constraints in current namespace
JOIN sys.pg_namespace_ext nsp_ext ON nsp_ext.oid = const1.connamespace
--get the table names corresponding to foreign keys
JOIN pg_class c ON const1.conrelid = c.oid AND const1.contype ='f'
-- join wiht bbf_nsp to get all constraint related to tsql endpoint and the owner of foreign key
JOIN sys.babelfish_namespace_ext bbf_nsp ON bbf_nsp.nspname = nsp_ext.nspname AND bbf_nsp.dbid = sys.db_id()
-- lateral join to use the conkey and confkey to join with pg_attribute to get column names
CROSS JOIN LATERAL unnest(const1.conkey,const1.confkey) WITH ORDINALITY AS ak(j, k, nr)
            LEFT JOIN pg_attribute a
                       ON (a.attrelid = const1.conrelid AND a.attnum = ak.j)
            LEFT JOIN pg_attribute a2
                       ON (a2.attrelid = const1.confrelid AND a2.attnum = ak.k)
)
-- get the index that foreign key depends on
LEFT JOIN pg_depend d1 ON d1.objid = const1.oid AND d1.classid = 'pg_constraint'::regclass
           AND d1.refclassid = 'pg_class'::regclass AND d1.refobjsubid = 0
-- get the pkey/ukey constraint for this index
LEFT JOIN pg_depend d2 ON d2.refclassid = 'pg_constraint'::regclass AND d2.classid = 'pg_class'::regclass AND d2.objid = d1.refobjid AND d2.objsubid = 0 AND d2.deptype = 'i'
-- get the constraint name from new pg_constraint
LEFT JOIN pg_constraint const2 ON const2.oid = d2.refobjid AND const2.contype IN ('p', 'u') AND const2.conrelid = const1.confrelid
-- get the namespace name for primary key
LEFT JOIN sys.pg_namespace_ext nsp_ext2 ON const2.connamespace = nsp_ext2.oid
-- get the owner name for primary key
LEFT JOIN sys.babelfish_namespace_ext bbf_nsp2 ON bbf_nsp2.nspname = nsp_ext2.nspname AND bbf_nsp2.dbid = sys.db_id()
-- get the table name for primary key
LEFT JOIN pg_class c2 ON const2.conrelid = c2.oid AND const2.contype IN ('p', 'u');

GRANT SELECT ON sys.sp_fkeys_view TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
