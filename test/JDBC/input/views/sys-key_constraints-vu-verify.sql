USE sys_key_constraints_vu_prepare_db1
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_vu_prepare_uq_1');
GO

USE master
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_vu_prepare_uq_1');
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_vu_prepare_uq_2');
GO

USE sys_key_constraints_vu_prepare_db1
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('sys_key_constraints_vu_prepare_uq_2');
GO
