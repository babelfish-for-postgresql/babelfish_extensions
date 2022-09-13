USE sys_sysforeignkeys_vu_prepare_db1
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_vu_prepare_fk2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_sysforeignkeys_vu_prepare_fk2');
GO

USE master
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_vu_prepare_fk2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_sysforeignkeys_vu_prepare_fk2');
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_vu_prepare_fk4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_sysforeignkeys_vu_prepare_fk4');
GO

USE sys_sysforeignkeys_vu_prepare_db1
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('sys_sysforeignkeys_vu_prepare_fk4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('sys_sysforeignkeys_vu_prepare_fk4');
GO