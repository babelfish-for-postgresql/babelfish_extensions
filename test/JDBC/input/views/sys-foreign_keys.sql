CREATE DATABASE db1;
GO

USE db1
GO

create table fk_1 (a int, primary key (a))
GO

create table fk_2 (a int, b int, primary key (a), foreign key (b) references fk_1(a))
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_1') and type = 'PK'
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_2');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_2');
GO

USE master
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_1') and type = 'PK'
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_2');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_2');
GO

create table fk_3 (a int, primary key (a))
GO

create table fk_4 (a int, b int, primary key (a), foreign key (b) references fk_3(a))
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_3') and type = 'PK'
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_4');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_4');
GO

USE db1
GO

select count(*) from sys.key_constraints where parent_object_id = object_id('fk_3') and type = 'PK'
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
GO

select count(*) from sys.objects where type='F' and parent_object_id = object_id('fk_4');
GO

select count(*) from sys.all_objects where type='F' and parent_object_id = object_id('fk_4');
GO

drop table fk_2;
GO

drop table fk_1;
GO

USE master
GO

drop table fk_4;
GO

drop table fk_3;
GO

DROP DATABASE db1
GO