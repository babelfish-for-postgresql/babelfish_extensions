CREATE VIEW sys_assembly_types_view_vu_prepare AS
SELECT * FROM sys.assembly_types
GO

CREATE PROC sys_assembly_types_proc_vu_prepare AS
SELECT * FROM sys.assembly_types
GO

CREATE FUNCTION sys_assembly_types_func_vu_prepare()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.assembly_types)
END
GO
