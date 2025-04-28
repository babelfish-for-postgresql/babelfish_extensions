-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '5.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

------------------------------------------------------------------------------
---- Add changes here --------------------------------------------------------
------------------------------------------------------------------------------

CREATE OR REPLACE VIEW sys.dm_os_sys_info 
AS SELECT 
  CAST(0 AS BIGINT) AS cpu_ticks,
  CAST(ROUND(CAST(EXTRACT(EPOCH FROM NOW()) AS NUMERIC(38,0)) * 1000.0, 0) AS BIGINT) AS ms_ticks, 
  CAST(0 AS INT) AS cpu_count,
  CAST(0 AS INT) AS hyperthread_ratio,
  CAST(0 AS BIGINT) AS physical_memory_kb,
  CAST(0 AS BIGINT) AS virtual_memory_kb,
  CAST(0 AS BIGINT) AS committed_kb,
  CAST(0 AS BIGINT) AS committed_target_kb,
  CAST(0 AS BIGINT) AS visible_target_kb,
  CAST(0 AS INT) AS stack_size_in_bytes,
  CAST(0 AS BIGINT) AS os_quantum,
  CAST(0 AS INT) AS os_error_mode,
  CAST(0 AS INT) AS os_priority_class,
  CAST(0 AS INT) AS max_workers_count,
  CAST(0 AS INT) AS scheduler_count,
  CAST(0 AS INT) AS scheduler_total_count,
  CAST(0 AS INT) AS deadlock_monitor_serial_number,
  CAST(ROUND(CAST(EXTRACT(EPOCH FROM pg_postmaster_start_time()) AS NUMERIC(38,0)) * 1000.0, 0) AS BIGINT) AS sqlserver_start_time_ms_ticks, 
  CAST(pg_postmaster_start_time() AS sys.DATETIME) AS sqlserver_start_time,
  CAST(0 AS INT) AS affinity_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS affinity_type_desc,
  CAST(0 AS BIGINT) AS process_kernel_time_ms,
  CAST(0 AS BIGINT) AS process_user_time_ms,
  CAST(0 AS INT) AS time_source,
  CAST(NULL AS sys.NVARCHAR(60)) AS time_source_desc,
  CAST(0 AS INT) AS virtual_machine_type,
  CAST('NONE' AS sys.NVARCHAR(60)) AS virtual_machine_type_desc,
  CAST(0 AS INT) AS softnuma_configuration,
  CAST('OFF' AS sys.NVARCHAR(60)) AS softnuma_configuration_desc,
  CAST(NULL AS sys.NVARCHAR(3072)) AS process_physical_affinity,
  CAST(0 AS INT) AS sql_memory_model,
  CAST(NULL AS sys.NVARCHAR(60)) AS sql_memory_model_desc,
  CAST(0 AS INT) AS socket_count,
  CAST(0 AS INT) AS cores_per_socket,
  CAST(0 AS INT) AS numa_node_count,
  CAST(0 AS INT) AS container_type,
  CAST(NULL AS sys.NVARCHAR(60)) AS container_type_desc;
GRANT SELECT ON sys.dm_os_sys_info TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
