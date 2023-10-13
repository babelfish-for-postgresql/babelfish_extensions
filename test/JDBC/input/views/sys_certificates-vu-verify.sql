USE master
GO

SELECT * FROM sys.certificates
GO

SELECT * FROM sys_certificates_vu_prepare_view
GO

EXEC sys_certificates_vu_prepare_proc
GO

SELECT sys_certificates_vu_prepare_func()
GO