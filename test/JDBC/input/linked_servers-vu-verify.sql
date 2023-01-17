-- Check if the linked server added is reflected in the system view
SELECT name, product, provider, data_source, provider_string, catalog, is_linked FROM sys.servers ORDER BY name
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_servers_func()
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_servers_view
GO

SELECT s.name as linked_srv_name, l.remote_name as username FROM sys.servers as s INNER JOIN sys.linked_logins as l on s.server_id = l.server_id ORDER BY linked_srv_name
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_linked_logins_view
GO
