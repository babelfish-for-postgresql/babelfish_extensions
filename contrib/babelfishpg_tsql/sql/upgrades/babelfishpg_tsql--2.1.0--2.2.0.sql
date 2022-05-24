-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit
  
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);


-- SERVER_PRINCIPALS
CREATE OR REPLACE VIEW sys.server_principals
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
  CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
