SELECT * FROM sysusers_dep_vu_prepare_view
GO

EXEC sysusers_dep_vu_prepare_proc
GO

SELECT sysusers_dep_vu_prepare_func()
GO

SELECT name FROM sys.sysusers
WHERE name LIKE '%sysusers_dep_vu_prepare_%'
ORDER BY name
GO

