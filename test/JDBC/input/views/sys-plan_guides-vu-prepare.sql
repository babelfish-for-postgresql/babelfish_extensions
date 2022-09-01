USE master
GO

CREATE VIEW sys_plan_guides_vu_prepare_view AS
SELECT * FROM sys.plan_guides
GO

CREATE PROC sys_plan_guides_vu_prepare_proc AS
SELECT * FROM sys.plan_guides
GO

CREATE FUNCTION dbo.sys_plan_guides_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.plan_guides)
END
GO