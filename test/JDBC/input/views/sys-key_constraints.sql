CREATE DATABASE db1;
GO

USE db1
GO

create table uq_1 (a int not null unique)
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_1');
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_1') and type = 'UQ';
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_1') and type = 'uq';
GO

USE master
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_1');
GO

create table uq_2 (a int not null unique)
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_2');
GO

USE db1
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('uq_2');
GO

select is_system_named from sys.key_constraints where parent_object_id = object_id('uq_2');
GO

drop table uq_1;
GO

USE master
GO

drop table uq_2;
GO

DROP DATABASE db1
GO
