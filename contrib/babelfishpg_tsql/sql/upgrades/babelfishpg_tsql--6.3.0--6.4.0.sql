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

-- CONVERT without a style follows SET DATEFORMAT (babelfishpg_tsql.dateformat)
-- Following function can be used to convert string literal to DATE, TIME and DATETIME2.
CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime2(IN p_datatype TEXT,
                                                                        IN p_datetimestring TEXT,
                                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_sign VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offhours VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offminutes VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_language VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATE|TIME|DATETIME2|DATETIMEOFFSET)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('\s*((\-|\+)\s*(', TIMEUNIT_REGEXP, ')\s*\:\s*(', TIMEUNIT_REGEXP, ')|Z)\s*');
    HHMMSSFSOFF_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', HHMMSSFSOFF_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');    
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', SHORTYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*\,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*', SHORTYEAR_REGEXP, '$');
    DEFMASK9_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '($comp_month$)\s*\,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', COMPYEAR_REGEXP, '$');
    SLASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', COMPYEAR_REGEXP, '$');
    DOT_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    DASH_FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    SLASH_FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\/\s*', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    DOT_FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '\s*\d{4}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '\s*\d{6}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', '\s*\d{8}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    W3C_XML_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, '(', '(\-|\+)', '(\d{2})', '\:', '(\d{2})', '|', 'Z', ')','$');                                                        
    W3C_XML_Z_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'Z','$');
    ISO_8601_DATETIMEOFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'T', '\d{2}', '\:', '\d{1,2}', '\:', '\d{1,2}', '(?:\.', '\d{1,9}', ')?', '((\-|\+)', '\d{2}', '\:', '\d{2}','|Z)?$');
BEGIN
    v_datatype := pg_catalog.btrim(p_datatype);
    v_datetimestring := pg_catalog.upper(pg_catalog.btrim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype = 'DATE' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        -- currently datetime2, datetimeoffset and time only support factional seconds
        -- upto 6 digits hence set v_scale to 6 to get consistent behaviour in datetime2(7) and datetime2
        v_scale := 6;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    -- For W3C_XML_REGEXP, there is no need of maintaining v_timepart and v_datestring
    IF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_timepart := NULL;
        v_datestring := NULL;
    ELSE
        v_timepart := pg_catalog.btrim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFSOFF_PART_REGEXP, ')')));
        v_datestring := pg_catalog.btrim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFSOFF_PART_REGEXP, ')'), '', 'gi'));
    END IF;

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), pg_catalog.upper(pg_catalog.current_setting('babelfishpg_tsql.dateformat', true)), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    -- If datetime string has some part as 'AMZ' or 'PMZ' then its invalid datetime format
    IF (v_datetimestring ~* pg_catalog.concat(AMPM_REGEXP, 'Z'))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp))
            THEN
                RAISE invalid_datetime_format;      
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[1]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
                    (v_datestring !~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) AND
                     v_datestring !~* pg_catalog.replace(DEFMASK9_3_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);
        ELSE
            IF ((v_datestring !~* pg_catalog.replace(DEFMASK10_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_3_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_4_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* SLASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* DOT_COMPYEAR1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                    RAISE character_not_in_repertoire;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (101, 110)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'YMD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        -- DATEFORMAT 'YDM' is not supported hence only applicable dateformat can be used here is YMD
        v_year := v_regmatch_groups[1];
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* SLASH_FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* DOT_FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 20, 21, 22, 23, 25, 101, 102, 103, 104, 105, 110, 111, 120, 121, 126, 127, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF ((v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP))
    THEN
        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFSOFF_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, W3C_XML_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

        IF (v_datetimestring !~* W3C_XML_Z_REGEXP)
        THEN
            v_sign := v_regmatch_groups[5];
            v_offhours := v_regmatch_groups[6];
            v_offminutes := v_regmatch_groups[7];
            IF ((v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
                (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
                (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
            THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_sign := '+';
            v_offhours := '0';
            v_offminutes := '0';
        END IF;
    ELSIF (v_datetimestring ~* ISO_8601_DATETIMEOFFSET_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIMEOFFSET_REGEXP, 'gi');
        
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

        -- v_offhours and v_offminutes will be already set for W3C_XML datetime string format
        v_sign := coalesce(v_sign, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFSIGN'), '+');
        v_offhours := coalesce(v_offhours, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFHOURS'), '0');
        v_offminutes := coalesce(v_offminutes, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFMINUTES'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;

    -- validate time and offset
    IF ((v_hours::SMALLINT NOT BETWEEN 0 AND 23) OR
        (v_minutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
        (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;
    
    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$') AND char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a ':'
        v_fseconds := lpad(v_fseconds, 3, '0');
    END IF;

    IF (v_scale = 0) THEN
        v_seconds := pg_catalog.concat_ws('.', v_seconds, v_fseconds);
        v_seconds := round(v_seconds::NUMERIC, 0)::TEXT;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(v_fseconds, v_scale);
        
        -- Following condition will handle overflow of fractsecs
        IF (v_fseconds::INTEGER < 0) THEN
            v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
            v_seconds := (v_seconds::INTEGER + 1)::TEXT;
        END IF;

        v_seconds := pg_catalog.concat_ws('.', v_seconds, v_fseconds);
    END IF;

    IF (v_res_datatype = 'DATE')
    THEN
        v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,0,0,0);
    ELSIF (v_res_datatype = 'TIME')
    THEN
        v_resdatetime := make_timestamp(9999, 12, 31, v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);        
    ELSE
        v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
    END IF;

    IF (v_resdatetime > make_timestamp(9999, 12, 31, 23, 59, 59.999999)) THEN
        -- if rounding of fractional seconds caused the date and time to go out of range 
        -- then max date and time that can be stored for p_datatype will be used
        v_resdatetime := make_timestamp(9999, 12, 31, 23, 59, pg_catalog.concat_ws('.', '59', PG_CATALOG.repeat('9', LEAST(v_scale, 6)))::NUMERIC); 
    END IF;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of conv_string_to_datetime2 function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATE'', ''TIME''/''TIME(n)'', ''DATETIME2''/''DATETIME2(n)'', ''DATETIMEOFFSET''/''DATETIMEOFFSET(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('CAST or CONVERT: invalid attributes specified for type ''%s''', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE :=  pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'This session''s YDM date format is not supported when converting from this character string format to date, time, datetime2 or datetimeoffset. Change the session''s date format or provide a style to the explicit conversion.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

-- Following function can be used to convert string literal to DATETIME and SMALLDATETIME
CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime_v2(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_language VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,3}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '(?:\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');

    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
  
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{4}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{6}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{8}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    ISO_8601_DATETIME_REGEXP CONSTANT VARCHAR COLLATE "C" := pg_catalog.concat('^', FULLYEAR_REGEXP, '-', '(\d{2})', '-', '(\d{2})', 'T', '\d{2}', '\:', '\d{2}', '\:', '\d{2}', '(?:\.', FRACTSECS_REGEXP, ')?','$');
BEGIN
    v_datatype := pg_catalog.btrim(p_datatype);
    v_datetimestring := pg_catalog.upper(pg_catalog.btrim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := pg_catalog.upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    END IF;

    v_timepart := pg_catalog.btrim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFS_PART_REGEXP, ')')));
    v_datestring := pg_catalog.btrim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFS_PART_REGEXP, ')'), '', 'gi'));

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), pg_catalog.upper(pg_catalog.current_setting('babelfishpg_tsql.dateformat', true)), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF (v_style = 127) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[2]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 130, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
            ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
        THEN
            v_day := v_rightpart;
            v_month := v_middlepart;

        ELSIF ((v_style IN (103, 104, 105, 130, 131)) OR
               ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
        THEN
            v_day := v_middlepart;
            v_month := v_rightpart;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style IS NOT NULL AND v_style != 0)
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_date_format IN ('MYD', 'MDY', 'YMD'))
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF (v_date_format IN ('DYM', 'DMY', 'YDM'))
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_datestring !~* '^\d{4}$')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* ISO_8601_DATETIME_REGEXP)
    THEN
        IF (v_style IN (130, 131))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIME_REGEXP, 'gi');

        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    -- DATETIME/SMALLDATETIME supports time part in either left or right side of date part, 
    -- but having time on both side of date part should throw error
    IF ((SELECT COUNT(*) FROM regexp_matches(v_datetimestring, HHMMSSFS_PART_REGEXP)) > 1)
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF ((v_datetimestring !~* HHMMSSFS_REGEXP AND
         length(v_datetimestring) != 0) AND
        v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;
    
    -- validate time
    IF ((v_hours::SMALLINT NOT BETWEEN 0 AND 23) OR
        (v_minutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_seconds::SMALLINT NOT BETWEEN 0 AND 59))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)) OR
        ((v_res_datatype = 'DATETIME') AND (v_year::SMALLINT NOT BETWEEN 1753 AND 9999)) OR
        ((v_res_datatype = 'SMALLDATETIME') AND 
            ((v_year::SMALLINT NOT BETWEEN 1900 AND 2079) OR
             (v_year::SMALLINT = 2079 AND 
                ((v_month::SMALLINT NOT BETWEEN 1 AND 6) OR (v_day::SMALLINT NOT BETWEEN 1 AND 6))))))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;

    -- validate boundary condition for date and time
    IF ((v_res_datatype = 'SMALLDATETIME' AND 
         (v_year::SMALLINT = 2079 AND v_month::SMALLINT = 6 AND v_day::SMALLINT = 6 AND 
            v_hours::SMALLINT = 23 AND v_minutes::SMALLINT = 59 AND 
                (v_seconds::SMALLINT > 29 OR (v_seconds::SMALLINT = 29 AND v_fseconds::SMALLINT > 998)))) OR
        (v_res_datatype = 'DATETIME' AND 
         (v_year::SMALLINT = 9999 AND v_month::SMALLINT = 12 AND v_day::SMALLINT = 31 AND 
            v_hours::SMALLINT = 23 AND v_minutes::SMALLINT = 59 AND v_seconds::SMALLINT = 59 AND v_fseconds::SMALLINT > 998))
        )
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF (v_timepart ~* PG_CATALOG.concat('^(', HHMMSSFS_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a '.'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            rpad(v_fseconds, 3, '0'));
    ELSE
        -- if before fractional seconds there is a ':'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            lpad(v_fseconds, 3, '0'));
    END IF;

    IF (v_res_datatype = 'SMALLDATETIME' AND
        to_char(v_resdatetime, 'SS') <> '00')
    THEN
        IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
            v_resdatetime := v_resdatetime + INTERVAL '1 minute';
        END IF;

        v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
    END IF;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('CAST or CONVERT: invalid attributes specified for type ''%s''', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to smalldatetime data type.'
                                  ELSE 'Conversion failed when converting date and/or time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN invalid_escape_sequence THEN
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
IMMUTABLE
RETURNS NULL ON NULL INPUT;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
