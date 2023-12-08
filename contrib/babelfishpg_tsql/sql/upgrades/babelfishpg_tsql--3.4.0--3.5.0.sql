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

ALTER VIEW sys.data_spaces RENAME TO data_spaces_deprecated_3_4;


CREATE OR REPLACE VIEW sys.data_spaces
AS
SELECT 
  CAST('PRIMARY' as SYSNAME) AS name,
  CAST(1 as INT) AS data_space_id,
  CAST('FG' as sys.bpchar(2)) AS type,
  CAST('ROWS_FILEGROUP' as NVARCHAR(60)) AS type_desc,
  CAST(1 as sys.BIT) AS is_default,
  CAST(0 as sys.BIT) AS is_system;
GRANT SELECT ON sys.data_spaces TO PUBLIC;

CREATE OR REPLACE VIEW sys.filegroups
AS
SELECT 
   CAST(ds.name AS sys.SYSNAME),
   CAST(ds.data_space_id AS INT),
   CAST(ds.type AS sys.BPCHAR(2)) COLLATE sys.database_default,
   CAST(ds.type_desc AS sys.NVARCHAR(60)),
   CAST(ds.is_default AS sys.BIT),
   CAST(ds.is_system AS sys.BIT),
   CAST(NULL as sys.UNIQUEIDENTIFIER) AS filegroup_guid,
   CAST(0 as INT) AS log_filegroup_id,
   CAST(0 as sys.BIT) AS is_read_only,
   CAST(0 as sys.BIT) AS is_autogrow_all_files
FROM sys.data_spaces ds WHERE type = 'FG';
GRANT SELECT ON sys.filegroups TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'data_spaces_deprecated_3_4');

ALTER VIEW sys.sysprocesses RENAME TO sysprocesses_deprecated_3_4;

create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , CAST(a.wait_event_type as sys.nchar(32)) as lastwaittype
  , null::sys.nchar(256) as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , CAST(a.state as sys.nchar(30)) as status
  , null::bytea as sid
  , CAST(t.host_name AS sys.nchar(128)) as hostname
  , CAST(a.application_name as sys.nchar(128)) as program_name
  , t.client_pid::sys.nchar(10) as hostprocess
  , CAST(a.query as sys.nchar(52)) as cmd
  , null::sys.nchar(128) as nt_domain
  , null::sys.nchar(128) as nt_username
  , null::sys.nchar(12) as net_address
  , null::sys.nchar(12) as net_library
  , CAST(a.usename as sys.nchar(128)) as loginname
  , t.context_info::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database(); /* current physical database will always be babelfish database */
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_who(
	IN "@loginame" sys.sysname DEFAULT NULL,
	IN "@option"   sys.VARCHAR(30) DEFAULT NULL)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET NOCOUNT ON
	DECLARE @msg sys.VARCHAR(200)
	DECLARE @show_pg BIT = 0
	DECLARE @hide_col sys.VARCHAR(50) 
	
	IF @option IS NOT NULL
	BEGIN
		IF LOWER(TRIM(@option)) <> 'postgres' 
		BEGIN
			RAISERROR('Parameter @option can only be ''postgres''', 16, 1)
			RETURN			
		END
	END
	
	-- Take a copy of sysprocesses so that we reference it only once
	SELECT DISTINCT * INTO #sp_who_sysprocesses FROM sys.sysprocesses

	-- Get the executing statement for each spid and extract the main stmt type
	-- This is for informational purposes only
	SELECT pid, query INTO #sp_who_tmp FROM pg_stat_activity pgsa
	
	UPDATE #sp_who_tmp SET query = ' ' + TRIM(UPPER(query))
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(9), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(10), ' ')
	UPDATE #sp_who_tmp SET query = sys.REPLACE(query,  chr(13), ' ')
	WHILE (SELECT count(*) FROM #sp_who_tmp WHERE sys.CHARINDEX('  ',query)>0) > 0 
	BEGIN
		UPDATE #sp_who_tmp SET query = sys.REPLACE(query, '  ', ' ')
	END

	-- Determine type of stmt to report by sp_who: very basic only
	-- NB: not handling presence of comments in the query string
	UPDATE #sp_who_tmp 
	SET query = 
	    CASE 
			WHEN PATINDEX('%[^a-zA-Z0-9_]UPDATE[^a-zA-Z0-9_]%', query) > 0 THEN 'UPDATE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]DELETE[^a-zA-Z0-9_]%', query) > 0 THEN 'DELETE'
			WHEN PATINDEX('%[^a-zA-Z0-9_]INSERT[^a-zA-Z0-9_]%', query) > 0 THEN 'INSERT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]SELECT[^a-zA-Z0-9_]%', query) > 0 THEN 'SELECT'
			WHEN PATINDEX('%[^a-zA-Z0-9_]WAITFOR[^a-zA-Z0-9_]%', query) > 0 THEN 'WAITFOR'
			WHEN PATINDEX('%[^a-zA-Z0-9_]CREATE ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('CREATE ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]ALTER ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('ALTER ', query))
			WHEN PATINDEX('%[^a-zA-Z0-9_]DROP ]%', query) > 0 THEN sys.SUBSTRING(query,1,sys.CHARINDEX('DROP ', query))
			ELSE sys.SUBSTRING(query, 1, sys.CHARINDEX(' ', query))
		END

	UPDATE #sp_who_tmp 
	SET query = sys.SUBSTRING(query,1, 8-1 + sys.CHARINDEX(' ', sys.SUBSTRING(query,8,99)))
	WHERE query LIKE 'CREATE %' OR query LIKE 'ALTER %' OR query LIKE 'DROP %'	

	-- The executing spid is always shown as doing a SELECT
	UPDATE #sp_who_tmp SET query = 'SELECT' WHERE pid = @@spid
	UPDATE #sp_who_tmp SET query = TRIM(query)

	-- Get all current connections
	SELECT 
		spid, 
		MAX(blocked) AS blocked, 
		0 AS ecid, 
		CAST('' AS sys.VARCHAR(100)) AS status,
		CAST('' AS sys.VARCHAR(100)) AS loginname,
		CAST('' AS sys.VARCHAR(100)) AS hostname,
		0 AS dbid,
		CAST('' AS sys.VARCHAR(100)) AS cmd,
		0 AS request_id,
		CAST('TDS' AS sys.VARCHAR(20)) AS connection,
		hostprocess
	INTO #sp_who_proc
	FROM #sp_who_sysprocesses
		GROUP BY spid, status, hostprocess
		
	-- Add attributes to each connection
	UPDATE #sp_who_proc
	SET ecid = sp.ecid,
		status = sp.status,
		loginname = sp.loginname,
		hostname = sp.hostname,
		dbid = sp.dbid,
		request_id = sp.request_id
	FROM #sp_who_sysprocesses sp
		WHERE #sp_who_proc.spid = sp.spid				

	-- Identify PG connections: the hostprocess PID comes from the TDS login packet 
	-- and therefore PG connections do not have a value here
	UPDATE #sp_who_proc
	SET connection = 'PostgreSQL'
	WHERE hostprocess IS NULL 

	-- Keep or delete PG connections
	IF (LOWER(@loginame) = 'postgres' OR LOWER(@option) = 'postgres')
	begin    
		-- Show PG connections; these have dbid = 0
		-- This is a Babelfish-specific enhancement, since PG connections may also be active in the Babelfish DB
		-- and it may be useful to see these displayed
		SET @show_pg = 1
		
		-- blank out the loginame parameter for the tests below
		IF LOWER(@loginame) = 'postgres' SET @loginame = NULL
	END
	
	-- By default, do not show the column indicating the connection type since SQL Server does not have this column
	SET @hide_col = 'connection' 
	
	IF (@show_pg = 1) 
	BEGIN
		SET @hide_col = ''
	END
	ELSE 
	BEGIN
		-- Delete PG connections
		DELETE #sp_who_proc
		WHERE dbid = 0
	END
			
	-- Apply filter if specified
	IF (@loginame IS NOT NULL)
	BEGIN
		IF (TRIM(@loginame) = '')
		BEGIN
			-- Raise error
			SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
			RAISERROR(@msg, 16, 1)
			RETURN
		END
		
		IF (sys.ISNUMERIC(@loginame) = 1)
		BEGIN
			-- Remove all connections except the specified one
			DELETE #sp_who_proc
			WHERE spid <> CAST(@loginame AS INT)
		END
		ELSE 
		BEGIN	
			IF (LOWER(@loginame) = 'active')
			BEGIN
				-- Remove all 'idle' connections 
				DELETE #sp_who_proc
				WHERE status = 'idle'
			END
			ELSE 
			BEGIN
				-- Verify the specified login name exists
				IF (sys.SUSER_ID(@loginame) IS NULL)
				BEGIN
					SET @msg = ''''+@loginame+''' is not a valid login or you do not have permission.'
					RAISERROR(@msg, 16, 1)
					RETURN					
				END
				ELSE 
				BEGIN
					-- Keep only connections for the specified login
					DELETE #sp_who_proc
					WHERE sys.SUSER_ID(loginname) <> sys.SUSER_ID(@loginame)
				END
			END
		END
	END			
			
	-- Create final result set; use DISTINCT since there are usually duplicate rows from the PG catalogs
	SELECT distinct 
		p.spid AS spid, 
		p.ecid AS ecid, 
		CAST(LEFT(p.status,20) AS sys.VARCHAR(20)) AS status,
		CAST(LEFT(p.loginname,40) AS sys.VARCHAR(40)) AS loginame,
		CAST(LEFT(p.hostname,60) AS sys.VARCHAR(60)) AS hostname,
		p.blocked AS blk, 
		CAST(LEFT(db_name(p.dbid),40) AS sys.VARCHAR(40)) AS dbname,
		CAST(LEFT(#sp_who_tmp.query,30)as sys.VARCHAR(30)) AS cmd,
		p.request_id AS request_id,
		connection
	INTO #sp_who_tmp2
	FROM #sp_who_proc p, #sp_who_tmp
		WHERE p.spid = #sp_who_tmp.pid
		ORDER BY spid		
	
	-- Patch up remaining cases
	UPDATE #sp_who_tmp2
	SET cmd = 'AWAITING COMMAND'
	WHERE TRIM(ISNULL(cmd,'')) = '' AND status = 'idle'
	
	UPDATE #sp_who_tmp2
	SET cmd = 'UNKNOWN'
	WHERE TRIM(cmd) = ''	
	
	-- Format the result set as narrow as possible for readability
	SET @hide_col += ',hostprocess'
	EXECUTE sys.sp_babelfish_autoformat @tab='#sp_who_tmp2', @orderby='ORDER BY spid', @hiddencols=@hide_col, @printrc=0
	RETURN
END	
$$;
GRANT EXECUTE ON PROCEDURE sys.sp_who(IN sys.sysname, IN sys.VARCHAR(30)) TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sysprocesses_deprecated_3_4');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
