-- Check if the linked server added is reflected in the system view
SELECT name, product, provider, data_source, provider_string, catalog, is_linked FROM sys.servers ORDER BY name
GO

SELECT * FROM sys_linked_servers_vu_prepare__sys_servers_func()
GO
