-- Check if the linked server added is reflected in the system view
SELECT name, product, provider, data_source, provider_string, catalog, is_linked FROM sys.servers WHERE name NOT LIKE 'bbf_server%' AND name NOT LIKE 'server_4229%' ORDER BY name
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_servers_func()
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_servers_view
GO

SELECT s.name as linked_srv_name, l.remote_name as username FROM sys.servers as s INNER JOIN sys.linked_logins as l on s.server_id = l.server_id WHERE s.name NOT LIKE 'bbf_server%' AND s.name NOT LIKE 'server_4229%' ORDER BY linked_srv_name
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_linked_logins_view
GO

-- Try to call sp_helplinkedsrvlogin with server name = NULL and login name = NULL. Should return all mappings
SET NOCOUNT ON
DECLARE @sp_helplinkedsrvlogin_var table(a sysname, b sysname NULL, c smallint, d sysname NULL)
INSERT INTO @sp_helplinkedsrvlogin_var EXEC sp_helplinkedsrvlogin
SELECT * FROM @sp_helplinkedsrvlogin_var WHERE a NOT LIKE 'bbf_server%' AND a NOT LIKE 'server_4229%' ORDER BY a
SET NOCOUNT OFF
GO

-- Try to call sp_helplinkedsrvlogin with correct server name but invalid login name. Should return zero rows
EXEC sp_helplinkedsrvlogin @rmtsrvname = 'mssql_server', @locallogin = 'testlogin'
GO

-- Try to call sp_helplinkedsrvlogin with correct server name but login name = NULL. Also modifying the case of servername.  should return all mapppings of the given server
EXEC sp_helplinkedsrvlogin @rmtsrvname = 'MSSQL_server'
GO

-- Try to call sp_helplinkedsrvlogin with correct server name but login name = NULL.  should return all mapppings of the given server
EXEC sp_helplinkedsrvlogin @rmtsrvname = 'mssql_server'
GO

-- Try to call sp_helplinkedsrvlogin with server name = NULL and invalid login name. Should return zero rows
EXEC sp_helplinkedsrvlogin @locallogin = 'testlogin'
GO

-- Try to call sp_helplinkedsrvlogin with invalid server name. Should throw error
EXEC sp_helplinkedsrvlogin @rmtsrvname = 'invalid_srv'
GO

SET NOCOUNT ON
DECLARE @sp_linkedservers_var table(a sysname, b nvarchar(128), c nvarchar(128), d nvarchar(4000), e nvarchar(4000), f nvarchar(4000), g sysname NULL)
INSERT INTO @sp_linkedservers_var EXEC sp_linkedservers
SELECT * FROM @sp_linkedservers_var WHERE a NOT LIKE 'bbf_server%' AND a NOT LIKE 'server_4229%' ORDER BY a
SET NOCOUNT OFF
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

-- drop all the linked server logins that have been created (case insensitive)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "MSSQL_server2", @locallogin = NULL
GO

-- leading spaces are not ignored (should throw error)
EXEC sp_droplinkedsrvlogin @rmtsrvname = "   mssql_server3", @locallogin = NULL
GO

-- trailing spaces are ignored
EXEC sp_droplinkedsrvlogin @rmtsrvname = "mssql_server3    ", @locallogin = NULL
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

-- Dropping a server without droplogins should also drop the server and the linked login and modifying the case of servername
EXEC sp_dropserver @server = 'MSSQL_server', @droplogins = NULL
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

-- Testing the sp_testlinkedserver stored procedure with NULL servername argument (should throw error)
EXEC sp_testlinkedserver NULL
GO

-- Testing the sp_testlinkedserver stored procedure with servername argument whose length is more than 128 chars (should throw error)
EXEC sp_testlinkedserver 'LjW4d3W5DcAMPlqprZ3jhgYfKbU1e8nV20ovRmJH7kbv9iXq4SNlTIQxAloKOze1f2tsnPLRu9BFyUgQYvKLpN3CBNTZP4zIZT4koPloGBYhWvg2c0qD6nM5aChQolTmzq32yGFAgXaj5rdxOXTSNwTIjxGZTVzhr39EhObE3k2DHExzS5Wg6SE1ZFLIjVJWlxibh7Xa8OzU0xQrI1VdmVuPS9vllwTQfNRzxv2etZXJdfVgR2p9bMkprV7SZtcP97bDluDk3hqV0D8Qy0U2LsdAMbHwPb5m6SE2n0seInwq2t4sN'
GO

-- Testing the connection to a linked server using a server name that does not exist (should throw error)
IF EXISTS(SELECT * FROM sys.servers WHERE name = 'test_server')
    EXEC sp_dropserver 'test_server', 'droplogins'
GO

EXEC sp_testlinkedserver 'test_server'
GO

-- Testing the connection to a existing linked server using the server name with leading spaces (should throw error)
EXEC sp_addlinkedserver  @server = N'test_server', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'localhost', @catalog=N'master'
GO

EXEC sp_testlinkedserver ' test_server'
GO

-- Testing the connection to a existing linked server using the server name with mixed spaces (should throw error)
EXEC sp_testlinkedserver ' test_server '
GO

-- Tesing the connection to a linked server for which user mapping does not exist (should throw error)
EXEC sp_testlinkedserver 'test_server'
GO

EXEC sp_dropserver @server = 'test_server', @droplogins = 'droplogins'
GO

-- Testing the connection to a linked server whose data source is incorrect (should throw error)
EXEC sp_addlinkedserver  @server = N'test_server', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'localhos', @catalog=N'master'
GO

EXEC sp_addlinkedsrvlogin @rmtsrvname = 'test_server', @useself = 'FALSE', @rmtuser = 'jdbc_user', @rmtpassword = '12345678'
GO

EXEC sp_testlinkedserver 'test_server'
GO

EXEC sp_dropserver @server = 'test_server', @droplogins = 'droplogins'
GO

-- Testing the connection to a linked server whose catalog name is incorrect (should throw error)
EXEC sp_addlinkedserver  @server = N'test_server', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'localhost', @catalog=N'maste'
GO

EXEC sp_addlinkedsrvlogin @rmtsrvname = 'test_server', @useself = 'FALSE', @rmtuser = 'jdbc_user', @rmtpassword = '12345678'
GO

EXEC sp_testlinkedserver 'test_server'
GO

EXEC sp_dropserver @server = 'test_server', @droplogins = 'droplogins'
GO

-- Testing the connection to a linked server whose all parameters has been set correctly (should pass)
EXEC sp_addlinkedserver  @server = N'test_server', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'localhost', @catalog=N'master'
GO

EXEC sp_addlinkedsrvlogin @rmtsrvname = 'test_server', @useself = 'FALSE', @rmtuser = 'jdbc_user', @rmtpassword = '12345678'
GO

EXEC sp_testlinkedserver 'test_server'
GO

-- Testing the connection to a right linked server with trailing spaces in the servername argument (should pass)
EXEC sp_testlinkedserver 'test_server  '
GO

-- Testing the connection to a right linked server with double-quoted(delimiter) servername argument (should pass)
EXEC sp_testlinkedserver "test_server"
GO

-- Testing the connection to a right linked server with master.dbo prefix to stored procedure (should pass)
EXEC master.dbo.sp_testlinkedserver 'test_server'
GO

-- Testing the connection to a right linked server without the EXEC keyword (should pass)
sp_testlinkedserver 'test_server'
GO

EXEC sp_dropserver @server = 'test_server', @droplogins = 'droplogins'
GO

-- Testing the stored procedure sp_enum_oledb_providers as a sysadmin user and with tds_fdw extension
EXEC sp_enum_oledb_providers
GO

-- Testing the stored procedure sp_enum_oledb_providers with master.dbo prefix
EXEC master.dbo.sp_enum_oledb_providers
GO

-- Testing the stored procedure sp_enum_oledb_providers with master.sys prefix
EXEC master.sys.sp_enum_oledb_providers
GO
