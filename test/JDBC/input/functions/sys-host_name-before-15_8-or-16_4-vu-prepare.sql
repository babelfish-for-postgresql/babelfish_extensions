CREATE VIEW sys_host_name_vu_prepare__host_name_view AS SELECT DISTINCT hostname FROM sys.sysprocesses WHERE spid = @@SPID
GO

CREATE FUNCTION sys_host_name_vu_prepare__host_name_func(@pid int)
RETURNS TABLE
AS
RETURN (SELECT DISTINCT CAST(hostname as nvarchar(128)) FROM sys.sysprocesses WHERE spid = @pid);
GO

CREATE PROCEDURE sys_host_name_vu_prepare__host_name_proc
AS
SELECT DISTINCT hostname FROM sys.sysprocesses WHERE spid = @@SPID
GO

-- Create objects that relied on dependent functions that were modified
CREATE VIEW sys_host_name_vu_prepare__dm_exec_connections_view AS select net_transport, protocol_type, protocol_version, endpoint_id, encrypt_option from sys.dm_exec_connections where session_id = @@SPID
GO

CREATE FUNCTION sys_host_name_vu_prepare__dm_exec_connections_func(@pid int)
RETURNS TABLE
AS
RETURN (select net_transport, protocol_type, protocol_version, endpoint_id, encrypt_option from sys.dm_exec_connections where session_id = @pid);
GO

CREATE PROCEDURE sys_host_name_vu_prepare__dm_exec_connections_proc
AS
select net_transport, protocol_type, protocol_version, endpoint_id, encrypt_option from sys.dm_exec_connections where session_id = @@SPID
GO

CREATE VIEW sys_host_name_vu_prepare__dm_exec_sessions_view AS select language, host_name, client_version, TRIM('0123456789.' FROM client_interface_name), program_name, date_format, date_first from sys.dm_exec_sessions where session_id = @@SPID
GO

CREATE FUNCTION sys_host_name_vu_prepare__dm_exec_sessions_func(@pid int)
RETURNS TABLE
AS
RETURN (select language, host_name, client_version, TRIM('0123456789.' FROM client_interface_name), program_name, date_format, date_first from sys.dm_exec_sessions where session_id = @pid);
GO

CREATE PROCEDURE sys_host_name_vu_prepare__dm_exec_sessions_proc
AS
select language, host_name, client_version, TRIM('0123456789.' FROM client_interface_name), program_name, date_format, date_first from sys.dm_exec_sessions where session_id = @@SPID
GO
