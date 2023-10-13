USE master
GO

SELECT * FROM sys_sequences_vu_prepare_view
GO

EXEC sys_sequences_vu_prepare_proc
GO

SELECT sys_sequences_vu_prepare_func()
GO

SELECT sys_sequences_vu_prepare_func1()
GO

SELECT sys_sequences_vu_prepare_func2()
GO