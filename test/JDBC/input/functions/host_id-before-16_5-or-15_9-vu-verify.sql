SELECT * FROM host_id_4272_v1
go

EXEC host_id_4272_p1
go

SELECT ISNUMERIC(HOST_ID())
go

SELECT 1
WHERE (SELECT DISTINCT ISNULL(hostprocess,0) FROM sys.sysprocesses WHERE spid = @@SPID) = CAST(HOST_ID() AS INT)
AND (SELECT DISTINCT ISNULL(host_process_id,0) FROM sys.dm_exec_sessions WHERE session_id = @@SPID) = CAST(HOST_ID() AS INT)
go
