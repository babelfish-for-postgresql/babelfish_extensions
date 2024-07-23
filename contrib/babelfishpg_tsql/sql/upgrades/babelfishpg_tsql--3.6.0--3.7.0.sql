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

CREATE OR REPLACE VIEW sys.database_principals AS
SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
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
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME()
  AND (Ext.orig_username IN ('dbo', 'db_owner', 'guest') -- system users should always be visible
  OR pg_has_role(Ext.rolname, 'MEMBER')) -- Current user should be able to see users it has permission of
UNION ALL
SELECT
CAST(name AS SYS.SYSNAME) AS name,
CAST(-1 AS INT) AS principal_id,
CAST(type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN type = 'S' THEN 'SQL_USER'
    WHEN type = 'R' THEN 'DATABASE_ROLE'
    WHEN type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL
  END
  AS SYS.NVARCHAR(60)) AS type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_schema_name,
CAST(NULL AS SYS.DATETIME) AS create_date,
CAST(NULL AS SYS.DATETIME) AS modify_date,
CAST(-1 AS INT) AS owning_principal_id,
CAST(CAST(0 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(0 AS SYS.BIT) AS is_fixed_role,
CAST(-1 AS INT) AS authentication_type,
CAST(NULL AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(NULL AS SYS.SYSNAME) AS default_language_name,
CAST(-1 AS INT) AS default_language_lcid,
CAST(0 AS SYS.BIT) AS allow_encrypted_value_modifications
FROM (VALUES ('public', 'R'), ('sys', 'S'), ('INFORMATION_SCHEMA', 'S')) as dummy_principals(name, type);

CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.orig_username AS SYS.NVARCHAR(128)) AS NAME,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
WHEN Ext.type = 'R' THEN 'ROLE'
ELSE 'SQL USER' END
AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = sys.DB_NAME()
AND ((Ext.rolname = CURRENT_USER AND Ext.type in ('S','U')) OR
((SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo' AND Ext.type = 'R' AND pg_has_role(current_user, Ext.rolname, 'MEMBER')))
UNION ALL
SELECT
CAST(-1 AS INT) AS principal_id,
CAST(CAST(-1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
DECLARE
    is_windows_grp boolean := (CHARINDEX('\', role) != 0);
BEGIN
    -- Always return 1 for 'public'
    IF (role = 'public')
    THEN RETURN 1;
    END IF;
    IF EXISTS (SELECT orig_loginname FROM sys.babelfish_authid_login_ext WHERE orig_loginname = role AND type != 'S') -- do not consider sql logins
    THEN
        IF ((EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type IN ('SERVER ROLE', 'SQL LOGIN'))) OR is_windows_grp) -- do not consider sql logins, server roles
        THEN RETURN NULL; -- Also return NULL if session is not a windows auth session but argument is a windows group
        ELSIF EXISTS (SELECT name FROM sys.login_token WHERE name = role AND type NOT IN ('SERVER ROLE', 'SQL LOGIN'))
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSIF EXISTS (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE orig_username = role)
    THEN
        IF EXISTS (SELECT name FROM sys.user_token WHERE name = role)
        THEN RETURN 1; -- Return 1 if current session user is a member of role or windows group
        ELSIF (is_windows_grp)
        THEN RETURN NULL; -- Return NULL if session is not a windows auth session but argument is a windows group
        ELSE RETURN 0; -- Return 0 if current session user is not a member of role or windows group
        END IF;
    ELSE RETURN NULL; -- Return NULL if role/group does not exist
    END IF;
END;
$$
LANGUAGE plpgsql STRICT STABLE;

CREATE OR REPLACE VIEW information_schema_tsql.columns_internal AS
	SELECT c.oid AS "TABLE_OID",
			CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
			CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
			CAST(
				COALESCE(
					(SELECT string_agg(
						CASE
						WHEN option LIKE 'bbf_original_rel_name=%' THEN substring(option, 23 /* prefix length */)
						ELSE NULL
						END, ',')
					FROM unnest(c.reloptions) AS option),
					c.relname)
				AS sys.nvarchar(128)) AS "TABLE_NAME",

			CAST(
				COALESCE(
					(SELECT string_agg(
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
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_column_privilege(c.oid, a.attnum,
									'SELECT, INSERT, UPDATE, REFERENCES'))
		AND ext.dbid =sys.db_id();

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
	SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
		   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
		   CAST(
				COALESCE(
					(SELECT string_agg(
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
		AND (NOT pg_is_other_temp_schema(nc.oid))
		AND tt.typrelid IS NULL
		AND (pg_has_role(c.relowner, 'USAGE')
			OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
			OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
		AND ext.dbid = sys.db_id()
		AND (NOT c.relname = 'sysdatabases');

CREATE OR REPLACE FUNCTION sys.babelfish_split_identifier(IN identifier VARCHAR, OUT value VARCHAR)
RETURNS SETOF VARCHAR AS 'babelfishpg_tsql', 'split_identifier_internal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_word_parse(
	IN "@input" sys.nvarchar(776),
	IN "@objtype" sys.varchar(13),
	INOUT "@subname" sys.nvarchar(776),
	INOUT "@curr_relname" sys.nvarchar(776),
	INOUT "@schemaname" sys.nvarchar(776),
	INOUT "@dbname" sys.nvarchar(776)
)
AS $$
BEGIN
	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row, * 
	INTO #sp_rename_temptable 
	FROM sys.babelfish_split_identifier(@input) ORDER BY row DESC;

	SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as id, * 
	INTO #sp_rename_temptable2 
	FROM #sp_rename_temptable;
	
	DECLARE @row_count INT;
	SELECT @row_count = COUNT(*) FROM #sp_rename_temptable2;

	IF @objtype = 'COLUMN'
		BEGIN
			IF @row_count = 1
				BEGIN
					THROW 33557097, N'Either the parameter @objname is ambiguous or the claimed @objtype (COLUMN) is wrong.', 1;
				END
			ELSE IF @row_count > 4
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					IF @row_count > 1
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SELECT @curr_relname = value FROM #sp_rename_temptable2 WHERE id = 2;
							SET @schemaname = sys.schema_name();

						END
					IF @row_count > 2
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 3;
						END
					IF @row_count > 3
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 4;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
	ELSE
		BEGIN
			IF @row_count > 3
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			ELSE
				BEGIN
					SET @curr_relname = NULL;
					IF @row_count > 0
						BEGIN
							SELECT @subname = value FROM #sp_rename_temptable2 WHERE id = 1;
							SET @schemaname = sys.schema_name();
						END
					IF @row_count > 1
						BEGIN
							SELECT @schemaname = value FROM #sp_rename_temptable2 WHERE id = 2;
						END
					IF @row_count > 2
						BEGIN
							SELECT @dbname = value FROM #sp_rename_temptable2 WHERE id = 3;
							IF @dbname != sys.db_name()
								BEGIN
									THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
								END
						END
				END
		END
END;
$$
LANGUAGE 'pltsql';

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
