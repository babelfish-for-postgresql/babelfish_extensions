USE db1_sys_foreign_keys;
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_1_sys_foreign_keys') and type = 'PK';
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

USE master;
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_1_sys_foreign_keys') and type = 'PK';
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_2_sys_foreign_keys');
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_3_sys_foreign_keys') and type = 'PK';
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

USE db1_sys_foreign_keys;
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_3_sys_foreign_keys') and type = 'PK';
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_4_sys_foreign_keys');
GO

SELECT COUNT(*) from sys.foreign_keys where name = 'fk1_pk1_id_fkey';
GO


SELECT COUNT(*) from sys.foreign_keys where name = 'fk2_fk2_int_2_fkey';
GO


SELECT COUNT(*) from sys.foreign_keys where name = 'fk3_pk3_int_1_pk3_int_2_fkey';
GO

