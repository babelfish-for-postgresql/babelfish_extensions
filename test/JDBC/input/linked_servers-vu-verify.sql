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

-- Try to drop a linked server login that does not exist (should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "invalid_server", @locallogin = NULL
GO

-- Try to drop a linked server login with @rmtsrvname = NULL (should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = NULL, @locallogin = NULL
GO

-- Try to drop a linked server login with locallogin != NULL (should throw error saying that only localogin = NULL is supported)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server", @locallogin = "login_1"
GO

-- drop all the linked server logins that have been created
EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server2", @locallogin = NULL
GO

EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server3", @locallogin = NULL
GO

-- Call sp_droplinkedsrvlogin from master.dbo schema
EXEC master.dbo.sp_droplinkedsrvlogin @rmtsrvname = "mssql_server", @locallogin = NULL
GO

