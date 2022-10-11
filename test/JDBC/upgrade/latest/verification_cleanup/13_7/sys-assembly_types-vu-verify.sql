SELECT * FROM sys_assembly_types_view_vu_prepare
GO

EXEC sys_assembly_types_proc_vu_prepare
GO

SELECT * FROM sys_assembly_types_func_vu_prepare()
GO

-- Test from sys-assembly_types.sql
SELECT * FROM sys.assembly_types
GO
