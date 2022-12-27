-- sla 20000
SELECT name,type,type_desc FROM sys.system_objects WHERE name = 'key_constraints'
GO

SELECT name,type,type_desc FROM sys.system_objects WHERE name = 'KEY_CONSTRAINTS'
GO

EXEC sys_system_objects_vu_prepare_p1
GO

SELECT * FROM sys_system_objects_vu_prepare_f1()
SELECT * FROM sys_system_objects_vu_prepare_f2()
GO

SELECT * FROM sys_system_objects_vu_prepare_v1
GO
