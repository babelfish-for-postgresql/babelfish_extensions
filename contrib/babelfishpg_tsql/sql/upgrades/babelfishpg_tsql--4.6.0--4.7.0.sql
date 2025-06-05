-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.7.0'" to load this file. \quit

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
    when undefined_function then --if 'Deprecated function does not exist'
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


DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.fn_varbintohexsubstring RENAME TO fn_varbintohexsubstring_deprecated_in_4_7_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_varbintohexsubstring_deprecated_in_4_7_0');

CREATE OR REPLACE FUNCTION sys.fn_varbintohexsubstring(set_prefix sys.BIT, expression sys.varbinary, start_offset INT, substr_length INT)
RETURNS sys.nvarchar AS 
$$ 
DECLARE 
    pstrout sys.nvarchar;
    hex_str text;
BEGIN 
    IF expression IS NULL THEN 
        RETURN NULL;
    END IF;

    IF substr_length IS NULL OR substr_length <= 0 OR substr_length > sys.LEN(expression) THEN 
        substr_length := sys.LEN(expression);
    END IF;

    IF start_offset IS NULL OR start_offset < 1 OR start_offset > sys.LEN(expression) THEN 
        RETURN NULL;
    END IF;

    IF (sys.LEN(expression) - start_offset + 1) < substr_length THEN 
        substr_length := sys.LEN(expression) - start_offset + 1;
    END IF;

    hex_str := sys.LOWER(pg_catalog.ENCODE(sys.SUBSTRING(expression, start_offset, substr_length)::bytea, 'hex'));
    
    pstrout := CASE 
                WHEN set_prefix IS NULL THEN N''
                WHEN set_prefix = 0 THEN N'' 
                ELSE N'0x' 
               END || hex_str;
    RETURN pstrout;
END;
$$ 
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE VIEW sys.server_permissions AS 
WITH super_user AS (SELECT datdba AS super_user FROM pg_database WHERE datname = CURRENT_DATABASE()) 
SELECT 
CAST(100 AS sys.tinyint) AS class,
CAST('SERVER' AS sys.nvarchar(60)) AS class_desc,
CAST(0 AS int) AS major_id,
CAST(0 AS int) AS minor_id,
CAST(Base.oid AS INT) AS grantee_principal_id,
CAST((SELECT super_user FROM super_user) AS INT) AS grantor_principal_id,
CAST('COSQ' AS sys.BPCHAR(4)) AS type,
CAST('CONNECT SQL' AS sys.nvarchar(128)) AS permission_name,
CAST('G' AS sys.BPCHAR(1)) AS state,
CAST('GRANT' AS sys.nvarchar(60)) AS state_desc 
FROM pg_catalog.pg_roles AS Base 
INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname 
WHERE(pg_has_role(sys.suser_id(), 'sysadmin'::TEXT, 'MEMBER')
  OR pg_has_role(sys.suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Base.rolname = sys.suser_name() COLLATE sys.database_default 
  OR Base.rolname = (SELECT pg_get_userbyid(super_user) FROM super_user))
  AND Ext.type IN ('S', 'U') 
UNION ALL 
SELECT 
CAST(105 AS sys.tinyint) AS class,
CAST('ENDPOINT' AS sys.nvarchar(60)) AS class_desc,
CAST(4 AS int) AS major_id,
CAST(0 AS int) AS minor_id,
CAST(2 AS INT) AS grantee_principal_id,
CAST((SELECT super_user FROM super_user) AS INT) AS grantor_principal_id,
CAST('CO' AS sys.BPCHAR(4)) AS type,
CAST('CONNECT' AS sys.nvarchar(128)) AS permission_name,
CAST('G' AS sys.BPCHAR(1)) AS state,
CAST('GRANT' AS sys.nvarchar(60)) AS state_desc;
GRANT SELECT ON sys.server_permissions TO PUBLIC;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER VIEW sys.sql_logins RENAME TO sql_logins_deprecated_in_4_7_0;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sql_logins_deprecated_in_4_7_0');

CREATE OR REPLACE VIEW sys.sql_logins AS 
WITH super_user AS (SELECT pg_get_userbyid(datdba) COLLATE sys.database_default AS super_user FROM pg_database WHERE datname = CURRENT_DATABASE())
SELECT
  CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
  CAST(Base.oid AS INT) AS principal_id,
  CAST(CAST(Base.oid AS INT) AS sys.varbinary(85)) AS sid,
  CAST('S' AS sys.BPCHAR(1)) AS type,
  CAST('SQL_LOGIN' AS sys.NVARCHAR(60)) AS type_desc,
  CAST(Ext.is_disabled AS INT) AS is_disabled,
  CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
  CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
  CAST(Ext.default_database_name AS SYS.SYSNAME) AS default_database_name,
  CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
  CAST(Ext.credential_id AS INT) AS credential_id,
  CAST(
    CASE
      WHEN Ext.orig_loginname = (SELECT super_user FROM super_user) THEN 0
      ELSE 1
    END
  AS sys.BIT) AS is_policy_checked,
  CAST(0 AS sys.BIT) AS is_expiration_checked,
  CAST(NULL AS sys.varbinary(256)) AS password_hash 
FROM pg_catalog.pg_roles AS Base 
INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname 
WHERE(pg_has_role(sys.suser_id(), 'sysadmin'::TEXT, 'MEMBER')
  OR pg_has_role(sys.suser_id(), 'securityadmin'::TEXT, 'MEMBER')
  OR Ext.orig_loginname = sys.suser_name()
  OR Ext.orig_loginname = (SELECT super_user FROM super_user))
  AND Ext.type = 'S';
GRANT SELECT ON sys.sql_logins TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT)
RETURNS INTEGER AS
'babelfishpg_tsql', 'isnumeric'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_type_precision_helper(IN type TEXT, IN typemod INT) RETURNS sys.TINYINT
AS $$
DECLARE
	precision INT;
  v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
		WHEN 'bigint' THEN precision = 19;
		WHEN 'bit' THEN precision = 1;
		WHEN 'date' THEN precision = 10;
		WHEN 'datetime' THEN precision = 23;
		WHEN 'datetime2' THEN precision = 26;
		WHEN 'datetimeoffset' THEN precision = 33;
		WHEN 'decimal' THEN precision = 38;
		WHEN 'numeric' THEN precision = 38;
		WHEN 'float' THEN precision = 53;
		WHEN 'int' THEN precision = 10;
		WHEN 'money' THEN precision = 19;
		WHEN 'real' THEN precision = 24;
		WHEN 'smalldatetime' THEN precision = 16;
		WHEN 'smallint' THEN precision = 5;
		WHEN 'smallmoney' THEN precision = 10;
		WHEN 'time' THEN precision = 15;
		WHEN 'tinyint' THEN precision = 3;
		ELSE precision = 0;
		END CASE;
		RETURN precision;
	END IF;

	CASE v_type
	WHEN 'numeric' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'decimal' THEN precision = ((typemod - 4) >> 16) & 65535;
	WHEN 'money' THEN precision = 19;
	WHEN 'smallmoney' THEN precision = 10;
	WHEN 'smalldatetime' THEN precision = 16;
	WHEN 'datetime2' THEN 
		CASE typemod 
		WHEN 0 THEN precision = 19;
		WHEN 1 THEN precision = 21;
		WHEN 2 THEN precision = 22;
		WHEN 3 THEN precision = 23;
		WHEN 4 THEN precision = 24;
		WHEN 5 THEN precision = 25;
		WHEN 6 THEN precision = 26;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 27;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN precision = 26;
		WHEN 1 THEN precision = 28;
		WHEN 2 THEN precision = 29;
		WHEN 3 THEN precision = 30;
		WHEN 4 THEN precision = 31;
		WHEN 5 THEN precision = 32;
		WHEN 6 THEN precision = 33;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN precision = 34;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN precision = 8;
		WHEN 1 THEN precision = 10;
		WHEN 2 THEN precision = 11;
		WHEN 3 THEN precision = 12;
		WHEN 4 THEN precision = 13;
		WHEN 5 THEN precision = 14;
		WHEN 6 THEN precision = 15;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN precision = 16;
		END CASE;
	ELSE precision = 0;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
	scale INT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	IF v_type IS NULL THEN 
		RETURN -1;
	END IF;

	IF typemod = -1 THEN
		CASE v_type
		WHEN 'date' THEN scale = 0;
		WHEN 'datetime' THEN scale = 3;
		WHEN 'smalldatetime' THEN scale = 0;
		WHEN 'datetime2' THEN scale = 6;
		WHEN 'datetimeoffset' THEN scale = 6;
		WHEN 'decimal' THEN scale = 38;
		WHEN 'numeric' THEN scale = 38;
		WHEN 'money' THEN scale = 4;
		WHEN 'smallmoney' THEN scale = 4;
		WHEN 'time' THEN scale = 6;
		WHEN 'tinyint' THEN scale = 0;
		ELSE
			IF return_null_for_rest
				THEN scale = NULL;
			ELSE scale = 0;
			END IF;
		END CASE;
		RETURN scale;
	END IF;

	CASE v_type 
	WHEN 'decimal' THEN scale = (typemod - 4) & 65535;
	WHEN 'numeric' THEN scale = (typemod - 4) & 65535;
	WHEN 'money' THEN scale = 4;
	WHEN 'smallmoney' THEN scale = 4;
	WHEN 'smalldatetime' THEN scale = 0;
	WHEN 'datetime2' THEN
		CASE typemod 
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetime2 in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'datetimeoffset' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for datetimeoffset in Babelfish
		-- but adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	WHEN 'time' THEN
		CASE typemod
		WHEN 0 THEN scale = 0;
		WHEN 1 THEN scale = 1;
		WHEN 2 THEN scale = 2;
		WHEN 3 THEN scale = 3;
		WHEN 4 THEN scale = 4;
		WHEN 5 THEN scale = 5;
		WHEN 6 THEN scale = 6;
		-- typemod = 7 is not possible for time in Babelfish but
		-- adding the case just in case we support it in future
		WHEN 7 THEN scale = 7;
		END CASE;
	ELSE
		IF return_null_for_rest
			THEN scale = NULL;
		ELSE scale = 0;
		END IF;
	END CASE;
	RETURN scale;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

/*
 * Updates typmod values in pg_proc for smallmoney/money data types in
 * PLTSQL procedures/functions, defined in babelfish_namespace_ext schemas.
 * Sets money typmod to 1245192(19,4) and smallmoney to 655368(10,4) where typmod is -1.
 */
UPDATE pg_proc p
SET probin = (
	SELECT jsonb_set(
		p.probin::jsonb,
		'{typmod_array}',
		to_jsonb(
			(
				SELECT jsonb_agg(
					CASE
						WHEN p.prokind = 'p' OR (p.prokind = 'f' AND p.proargtypes[typ_index-1] IS NOT NULL) THEN
							CASE
								WHEN typmod = '-1' AND (p.proargtypes[typ_index-1] = 'sys.money'::regtype::oid) THEN '1245192'
								WHEN typmod = '-1' and (p.proargtypes[typ_index-1] = 'sys.smallmoney'::regtype::oid) THEN '655368'
								ELSE typmod
							END
						WHEN p.prokind = 'f' AND p.prorettype IS NOT NULL THEN
							CASE
								WHEN typmod = '-1' AND (p.prorettype = 'sys.money'::regtype::oid) THEN '1245192'
								WHEN typmod = '-1' AND (p.prorettype = 'sys.smallmoney'::regtype::oid) THEN '655368'
								ELSE typmod
							END
						ELSE typmod
					END
				)
				FROM jsonb_array_elements_text(p.probin::jsonb->'typmod_array') WITH ORDINALITY AS elem(typmod,typ_index)
			)
		)
	)
)
FROM sys.babelfish_namespace_ext sch, pg_language l
WHERE sch.nspname = p.pronamespace::regnamespace::name
	AND p.prolang = l.oid
	AND l.lanname = 'pltsql'
	AND ((p.prokind = 'p' AND p.proargtypes <> '') OR (p.prokind = 'f' AND p.proallargtypes IS NULL));

/*
 * Updates typmod values in pg_attribute for smallmoney/money columns
 * in r = ordinary table, i = index, v = view, p = partitioned table, I = partitioned index.
 * For other relkinds, we either don't create from TDS side or they don't support money/smallmoney.
 * Sets money typmod to 1245192(19,4) and smallmoney to 655368(10,4) where typmod is -1.
 */
UPDATE pg_attribute a
SET atttypmod =
	CASE
		WHEN atttypmod = '-1' AND (a.atttypid = 'sys.money'::regtype::oid)
		THEN 1245192
		WHEN atttypmod = '-1' AND (a.atttypid = 'sys.smallmoney'::regtype::oid)
		THEN 655368
		ELSE atttypmod
	END
FROM pg_class c
INNER JOIN sys.babelfish_namespace_ext sch
	ON sch.nspname = c.relnamespace::regnamespace::name
WHERE a.attrelid = c.oid
	AND a.atttypmod = -1
	AND NOT a.attisdropped
	AND (a.atttypid = 'sys.money'::regtype::oid OR
		a.atttypid = 'sys.smallmoney'::regtype::oid)
	AND c.relkind IN ('r', 'i', 'v', 'p', 'I');

/*
 * Updates typmod values for UDTs based on money/smallmoney types in babelfish_namespace_ext schemas.
 * Required when creating new tables or using these UDTs directly to ensure proper type handling.
 */
UPDATE pg_type t
SET typtypmod =
	CASE
		WHEN sys.bbf_get_immediate_base_type_of_UDT(t.oid) = 'sys.money'::regtype::oid
		THEN 1245192
		WHEN sys.bbf_get_immediate_base_type_of_UDT(t.oid) = 'sys.smallmoney'::regtype::oid
		THEN 655368
		ELSE t.typtypmod
	END
FROM sys.babelfish_namespace_ext sch
WHERE sch.nspname = t.typnamespace::regnamespace::name
	AND t.typtypmod = -1
	AND t.typtype = 'd';

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
