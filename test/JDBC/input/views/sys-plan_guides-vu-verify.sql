USE master
GO

SELECT * FROM sys.plan_guides
GO

SELECT * FROM sys_plan_guides_vu_prepare_view
GO

EXEC sys_plan_guides_vu_prepare_proc
GO

SELECT dbo.sys_plan_guides_vu_prepare_func()
GO