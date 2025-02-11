-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.2.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */


-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);


CREATE OR REPLACE FUNCTION sys.loginproperty(login_name sys.sysname, property_name sys.nvarchar(128)) 
RETURNS sys.nvarchar(128) 
AS $$ 
DECLARE 
BEGIN 
    RETURN NULL; 
END; 
$$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION sys.fn_varbintohexsubstring(start_position INT, binary_input sys.varbinary(128), output_start_char INT, length_to_return INT) 
RETURNS sys.nvarchar(128) 
AS $$ 
DECLARE 
BEGIN 
    RETURN NULL; 
END; 
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE VIEW sys.server_permissions 
AS
SELECT
  CAST(0 as sys.tinyint) AS class,
  CAST(NULL as sys.nvarchar(60)) AS class_desc,
  CAST(NULL as INT) AS major_id,
  CAST(NULL as INT) AS minor_id,
  CAST(NULL as INT) AS grantee_principal_id,
  CAST(NULL as INT) AS grantor_principal_id,
  CAST('a' as sys.BPCHAR(4)) AS type,
  CAST(NULL as sys.nvarchar(128)) AS permission_name,
  CAST(NULL as sys.BPCHAR(1)) AS state,
  CAST(NULL as sys.nvarchar(60)) AS state_desc
WHERE FALSE;
GRANT SELECT ON sys.server_permissions TO PUBLIC;

CREATE OR REPLACE VIEW sys.credentials 
AS
SELECT
  CAST(NULL as INT) AS credential_id,
  CAST(NULL as sys.sysname) AS name,
  CAST(NULL as sys.nvarchar(4000)) AS credential_identity,
  CAST(NULL as sys.datetime) AS create_date,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(NULL as sys.nvarchar(100)) AS target_type,
  CAST(NULL as INT) AS target_id
WHERE FALSE;
GRANT SELECT ON sys.credentials TO PUBLIC;

CREATE OR REPLACE VIEW sys.sql_logins 
AS
SELECT
  CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
  CAST(Base.oid As INT) AS principal_id,
  CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
  CAST(Ext.type AS CHAR(1)) as type,
  CAST(
    CASE
      WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
      WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
      WHEN Ext.type = 'U' THEN 'WINDOWS_LOGIN'
      ELSE NULL
    END
    AS NVARCHAR(60)) AS type_desc,
  CAST(Ext.is_disabled AS INT) AS is_disabled,
  CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
  CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
  CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
  CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
  CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
  CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
  CAST(Ext.is_fixed_role AS sys.BIT) AS is_fixed_role
  CAST(0 as sys.BIT) AS is_policy_checked,
  CAST(0 as sys.BIT) AS is_expiration_checked,
  CAST(NULL as sys.varbinary(256)) AS password_hash
WHERE FALSE;
GRANT SELECT ON sys.sql_logins TO PUBLIC;