USE db1_sys_sysforeignkeys
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_2_sys_sysforeignkeys');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_sysforeignkeys');
GO

USE master
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_2_sys_sysforeignkeys');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_sysforeignkeys');
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_4_sys_sysforeignkeys');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_sysforeignkeys');
GO

USE db1_sys_sysforeignkeys
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_4_sys_sysforeignkeys');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_sysforeignkeys');
GO