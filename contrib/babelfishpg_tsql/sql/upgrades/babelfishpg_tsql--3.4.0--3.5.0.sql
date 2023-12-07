-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.4.0'" to load this file. \quit

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

ALTER VIEW sys.sysforeignkeys RENAME TO sysforeignkeys_deprecated_3_4;

create or replace view sys.sysforeignkeys as
select
  c.oid as constid
  , c.conrelid as fkeyid
  , c.confrelid as rkeyid
  , a_con.attnum as fkey
  , a_conf.attnum as rkey
  , a_conf.attnum as keyno
from pg_constraint c
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f'
and (c.connamespace in (select schema_id from sys.schemas))
and has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.sysforeignkeys TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sysforeignkeys_deprecated_3_4');

ALTER VIEW sys.system_objects RENAME TO system_objects_deprecated_3_4;

create or replace view sys.system_objects as
select
  name, object_id, principal_id, schema_id, 
  parent_object_id, type, type_desc, create_date, 
  modify_date, is_ms_shipped, is_published, is_schema_published
 from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname = 'sys';
GRANT SELECT ON sys.system_objects TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'system_objects_deprecated_3_4');

ALTER VIEW sys.syscolumns RENAME TO syscolumns_deprecated_3_4;

CREATE OR REPLACE VIEW sys.syscolumns AS
SELECT out_name as name
  , out_object_id as id
  , out_system_type_id as xtype
  , 0::sys.tinyint as typestat
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as xusertype
  , out_max_length as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , out_column_id::smallint as colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , out_default_object_id::int as cdefault
  , out_rule_object_id::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , out_offset as offset
  , out_collation_id as collationid
  , (case out_is_nullable::int when 1 then 8    else 0 end +
     case out_is_identity::int when 1 then 128  else 0 end)::sys.tinyint as status
  , out_system_type_id as type
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as usertype
  , null::sys.varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal()
union all
SELECT p.name
  , p.id
  , p.xtype
  , 0::sys.tinyint as typestat
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as xusertype
  , null as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , p.colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , null::int as cdefault
  , null::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , 0::smallint as offset
  , collationid
  , (case p.isoutparam when 1 then 64 else 0 end)::sys.tinyint as status
  , p.xtype as type
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , p.prec
  , p.scale
  , 0::int as iscomputed
  , p.isoutparam
  , 1::int as isnullable
  , p.collation
FROM sys.proc_param_helper() as p;
GRANT SELECT ON sys.syscolumns TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'syscolumns_deprecated_3_4');

ALTER VIEW sys.dm_exec_connections RENAME TO dm_exec_connections_deprecated_3_4;

create or replace view sys.dm_exec_connections
 as
 select a.pid as session_id
   , a.pid as most_recent_session_id
   , a.backend_start::sys.datetime as connect_time
   , 'TCP'::sys.nvarchar(40) as net_transport
   , 'TSQL'::sys.nvarchar(40) as protocol_type
   , d.protocol_version as protocol_version
   , 4 as endpoint_id
   , d.encrypyt_option::sys.nvarchar(40) as encrypt_option
   , null::sys.nvarchar(40) as auth_scheme
   , null::smallint as node_affinity
   , null::int as num_reads
   , null::int as num_writes
   , null::sys.datetime as last_read
   , null::sys.datetime as last_write
   , d.packet_size as net_packet_size
   , a.client_addr::sys.varchar(48) as client_net_address
   , a.client_port as client_tcp_port
   , null::sys.varchar(48) as local_net_address
   , null::int as local_tcp_port
   , null::sys.uniqueidentifier as connection_id
   , null::sys.uniqueidentifier as parent_connection_id
   , a.pid::sys.varbinary(64) as most_recent_sql_handle
 from pg_catalog.pg_stat_activity AS a
 RIGHT JOIN sys.tsql_stat_get_activity('connections') AS d ON (a.pid = d.procid);
 GRANT SELECT ON sys.dm_exec_connections TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'dm_exec_connections_deprecated_3_4');

ALTER VIEW sys.xml_indexes RENAME TO xml_indexes_connections_deprecated_3_4;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT)  AS index_id
  , CAST(idx.type AS sys.tinyint) AS type
  , CAST(idx.type_desc AS sys.nvarchar(60)) AS type_desc
  , CAST(idx.is_unique AS sys.bit) AS is_unique
  , CAST(idx.data_space_id AS int) AS data_space_id
  , CAST(idx.ignore_dup_key AS sys.bit) AS ignore_dup_key
  , CAST(idx.is_primary_key AS sys.bit) AS is_primary_key
  , CAST(idx.is_unique_constraint AS sys.bit) AS is_unique_constraint
  , CAST(idx.fill_factor AS sys.tinyint) AS fill_factor
  , CAST(idx.is_padded AS sys.bit) AS is_padded
  , CAST(idx.is_disabled AS sys.bit) AS is_disabled
  , CAST(idx.is_hypothetical AS sys.bit) AS is_hypothetical
  , CAST(idx.allow_row_locks AS sys.bit) AS allow_row_locks
  , CAST(idx.allow_page_locks AS sys.bit) AS allow_page_locks
  , CAST(idx.has_filter AS sys.bit) AS has_filter
  , CAST(idx.filter_definition AS sys.nvarchar(4000)) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS sys.bpchar(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM  sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'xml_indexes_connections_deprecated_3_4');

ALTER VIEW sys.stats RENAME TO stats__deprecated_3_4;

CREATE OR REPLACE VIEW sys.stats
AS
SELECT 
   CAST(0 as INT) AS object_id,
   CAST('' as SYSNAME) AS name,
   CAST(0 as INT) AS stats_id,
   CAST(0 as sys.BIT) AS auto_created,
   CAST(0 as sys.BIT) AS user_created,
   CAST(0 as sys.BIT) AS no_recompute,
   CAST(0 as sys.BIT) AS has_filter,
   CAST('' as sys.NVARCHAR(4000)) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as sys.VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;
GRANT SELECT ON sys.stats TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'stats__deprecated_3_4');

ALTER TABLE sys.babelfish_authid_login_ext RENAME TO babelfish_authid_login_ext_deprecated_3_4;

ALTER VIEW sys.server_principals RENAME TO server_principals_deprecated_3_4;

CREATE OR REPLACE TABLE sys.babelfish_authid_login_ext (
rolname NAME NOT NULL, -- pg_authid.rolname
is_disabled INT NOT NULL DEFAULT 0, -- to support enable/disable login
type sys.bpchar(1) NOT NULL DEFAULT 'S',
credential_id INT NOT NULL,
owning_principal_id INT NOT NULL,
is_fixed_role INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
default_database_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128) NOT NULL,
properties JSONB,
orig_loginname SYS.NVARCHAR(128) NOT NULL,
PRIMARY KEY (rolname));
GRANT SELECT ON sys.babelfish_authid_login_ext TO PUBLIC;

CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
Ext.type as type,
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
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE pg_has_role(suser_id(), 'sysadmin'::TEXT, 'MEMBER')
OR Ext.orig_loginname = suser_name()
OR Ext.orig_loginname = (SELECT pg_get_userbyid(datdba) FROM pg_database WHERE datname = CURRENT_DATABASE()) COLLATE sys.database_default
OR Ext.type = 'R';

GRANT SELECT ON sys.server_principals TO PUBLIC;

CREATE OR REPLACE VIEW sys.server_role_members AS
SELECT
CAST(Authmbr.roleid AS INT) AS role_principal_id,
CAST(Authmbr.member AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_roles AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_roles AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.type = 'R';

GRANT SELECT ON sys.server_role_members TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value text;
begin
	RETURN (select orig_loginname from sys.babelfish_authid_login_ext where rolname = session_user)::sys.sysname;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.original_login() TO PUBLIC;

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
	role  := TRIM(trailing from LOWER(role));
	login := TRIM(trailing from LOWER(login));
	
	login_valid = (login = suser_name()) OR 
		(EXISTS (SELECT name
	 			FROM sys.server_principals
		 	 	WHERE 
				LOWER(name) = login 
				AND type = 'S'));
 	
 	IF NOT login_valid THEN
 		RETURN NULL;
    
    ELSIF role = 'public' THEN
    	RETURN 1;
	
 	ELSIF role = 'sysadmin' THEN
	  	has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
	    IF has_role THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	
    ELSIF role IN (
            'serveradmin',
            'securityadmin',
            'setupadmin',
            'securityadmin',
            'processadmin',
            'dbcreator',
            'diskadmin',
            'bulkadmin') THEN 
    	RETURN 0;
 	
    ELSE
 		  RETURN NULL;
 	END IF;
	
 	EXCEPTION WHEN OTHERS THEN
	 	  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE VIEW sys.syslogins
AS SELECT 
Base.sid AS sid,
CAST(9 AS SYS.TINYINT) AS status,
Base.create_date AS createdate,
Base.modify_date AS updatedate,
Base.create_date AS accdate,
CAST(0 AS INT) AS totcpu,
CAST(0 AS INT) AS totio,
CAST(0 AS INT) AS spacelimit,
CAST(0 AS INT) AS timelimit,
CAST(0 AS INT) AS resultlimit,
Base.name AS name,
Base.default_database_name AS dbname,
Base.default_language_name AS default_language_name,
CAST(Base.name AS SYS.NVARCHAR(128)) AS loginname,
CAST(NULL AS SYS.NVARCHAR(128)) AS password,
CAST(0 AS INT) AS denylogin,
CAST(1 AS INT) AS hasaccess,
CAST( 
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' OR Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
AS INT) AS isntname,
CAST(
   CASE 
    WHEN Base.type_desc = 'WINDOWS_GROUP' THEN 1 
    ELSE 0
  END
  AS INT) AS isntgroup,
CAST(
  CASE 
    WHEN Base.type_desc = 'WINDOWS_LOGIN' THEN 1 
    ELSE 0
  END
AS INT) AS isntuser,
CAST(
    CASE
        WHEN is_srvrolemember('sysadmin', Base.name) = 1 THEN 1
        ELSE 0
    END
AS INT) AS sysadmin,
CAST(0 AS INT) AS securityadmin,
CAST(0 AS INT) AS serveradmin,
CAST(0 AS INT) AS setupadmin,
CAST(0 AS INT) AS processadmin,
CAST(0 AS INT) AS diskadmin,
CAST(0 AS INT) AS dbcreator,
CAST(0 AS INT) AS bulkadmin
FROM sys.server_principals AS Base
WHERE Base.type in ('S', 'U');

GRANT SELECT ON sys.syslogins TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'server_principals_deprecated_3_4');
CALL sys.babelfish_drop_deprecated_object('table', 'sys', 'babelfish_authid_login_ext_deprecated_3_4');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
