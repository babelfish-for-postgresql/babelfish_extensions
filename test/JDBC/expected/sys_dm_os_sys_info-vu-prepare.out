CREATE VIEW sys_dm_os_sys_info_test_view
AS
  SELECT
    cpu_ticks,
    CASE
        WHEN ms_ticks IS NOT NULL THEN 'true' ELSE 'false'
    END AS ms_ticks, 
    cpu_count,
    hyperthread_ratio,
    physical_memory_kb,
    virtual_memory_kb,
    committed_kb,
    committed_target_kb,
    visible_target_kb,
    stack_size_in_bytes,
    os_quantum,
    os_error_mode,
    os_priority_class,
    max_workers_count,
    scheduler_count,
    scheduler_total_count,
    deadlock_monitor_serial_number,
    CASE
        WHEN sqlserver_start_time_ms_ticks IS NOT NULL THEN 'true' ELSE 'false'
    END AS sqlserver_start_time_ms_ticks,
    CASE
        WHEN sqlserver_start_time IS NOT NULL THEN 'true' ELSE 'false'
    END AS sqlserver_start_time,
    affinity_type,
    affinity_type_desc,
    process_kernel_time_ms,
    process_user_time_ms,
    time_source,
    time_source_desc,
    virtual_machine_type,
    virtual_machine_type_desc,
    softnuma_configuration,
    softnuma_configuration_desc,
    process_physical_affinity,
    sql_memory_model,
    sql_memory_model_desc,
    socket_count,
    cores_per_socket,
    numa_node_count,
    container_type,
    container_type_desc
  FROM sys.dm_os_sys_info 
GO

CREATE PROC sys_dm_os_sys_info_test_proc
AS 
  SELECT
    cpu_ticks,
    CASE
        WHEN ms_ticks IS NOT NULL THEN 'true' ELSE 'false'
    END AS ms_ticks, 
    cpu_count,
    hyperthread_ratio,
    physical_memory_kb,
    virtual_memory_kb,
    committed_kb,
    committed_target_kb,
    visible_target_kb,
    stack_size_in_bytes,
    os_quantum,
    os_error_mode,
    os_priority_class,
    max_workers_count,
    scheduler_count,
    scheduler_total_count,
    deadlock_monitor_serial_number,
    CASE
        WHEN sqlserver_start_time_ms_ticks IS NOT NULL THEN 'true' ELSE 'false'
    END AS sqlserver_start_time_ms_ticks,
    CASE
        WHEN sqlserver_start_time IS NOT NULL THEN 'true' ELSE 'false'
    END AS sqlserver_start_time,
    affinity_type,
    affinity_type_desc,
    process_kernel_time_ms,
    process_user_time_ms,
    time_source,
    time_source_desc,
    virtual_machine_type,
    virtual_machine_type_desc,
    softnuma_configuration,
    softnuma_configuration_desc,
    process_physical_affinity,
    sql_memory_model,
    sql_memory_model_desc,
    socket_count,
    cores_per_socket,
    numa_node_count,
    container_type,
    container_type_desc
  FROM sys.dm_os_sys_info 
GO

CREATE FUNCTION sys_dm_os_sys_info_test_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.dm_os_sys_info)
END
GO
