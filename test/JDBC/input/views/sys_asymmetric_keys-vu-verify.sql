USE master
GO

SELECT * FROM sys.asymmetric_keys
GO

SELECT * FROM sys_asymmetric_keys_vu_prepare_view
GO

EXEC sys_asymmetric_keys_vu_prepare_proc
GO

SELECT sys_asymmetric_keys_vu_prepare_func()
GO