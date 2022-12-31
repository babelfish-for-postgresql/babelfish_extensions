-- sla 35000
SELECT * FROM sys_all_objects_dep_vu_prepare_func1()
GO

EXEC sys_all_objects_dep_vu_prepare_proc1;
GO

SELECT * FROM sys_all_objects_dep_vu_prepare_view1
GO
