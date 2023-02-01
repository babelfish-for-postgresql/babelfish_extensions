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

EXEC sp_linkedservers
GO

-- Try to drop a linked server login that does not exist (should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "invalid_server", @locallogin = NULL
GO

-- Try to drop a linked server login with @rmtsrvname = NULL (should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = NULL, @locallogin = NULL
GO

-- Try to drop a linked server locallogin that does not exist (Should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server", @locallogin = "invalid_login"
GO

EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server4", @locallogin = "linked_server_login_861"
GO

-- drop all the linked server logins that have been created
EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server2", @locallogin = NULL
GO

EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server3", @locallogin = NULL
GO

-- Call sp_droplinkedsrvlogin from master.dbo schema
EXEC master.dbo.sp_droplinkedsrvlogin @rmtsrvname = "mssql_server", @locallogin = NULL
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_linked_logins_view
GO

-- Trying to drop a server that does not exist (Should throw error)
EXEC sp_dropserver @server = 'mssql_server_that_does_not_exist', @droplogins = NULL
GO

-- Trying to drop a server with @droplogins = invalid value (Should throw error)
EXEC sp_dropserver @server = 'mssql_server', @droplogins = 'definitely_invalid'
GO

-- Dropping a server without droplogins should also drop the server and the linked login
EXEC sp_dropserver @server = 'mssql_server', @droplogins = NULL
GO

SELECT * FROM sys.servers WHERE name = 'mssql_server'
GO

SELECT s.name as linked_srv_name, l.remote_name as username FROM sys.servers as s INNER JOIN sys.linked_logins as l on s.server_id = l.server_id WHERE s.name = 'mssql_server'
GO

-- Dropping a server with droplogins should drop the linked logins as well. Also call sp_dropserver from master.dbo schema
EXEC master.dbo.sp_dropserver @server = 'mssql_server2', @droplogins = 'droplogins'
GO

SELECT * FROM sys.servers WHERE name = 'mssql_server'
GO

SELECT s.name as linked_srv_name, l.remote_name as username FROM sys.servers as s INNER JOIN sys.linked_logins as l on s.server_id = l.server_id WHERE s.name = 'mssql_server2'
GO
