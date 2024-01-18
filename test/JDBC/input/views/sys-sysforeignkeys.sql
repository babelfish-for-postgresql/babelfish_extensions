CREATE DATABASE db1;
GO

USE db1
GO

create table fk_1 (a int, primary key (a))
GO

create table fk_2 (a int, b int, primary key (a), foreign key (b) references fk_1(a))
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_2');
GO

-- sysforeignkeys should also exist in dbo schema
SELECT COUNT(*) FROM dbo.SySFoReIGNkeYs where fkeyid = object_id('fk_2');
go

SELECT COUNT(*) FROM db1.sys.SySFoReIGNkeYs where fkeyid = object_id('fk_2');
go

-- In case of cross-db, sysforeignkeys should also exist in dbo schema
SELECT COUNT(*) FROM db1.dbo.SySFoReIGNkeYs where fkeyid = object_id('fk_2');
go

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2') and type='f';
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2') and type='F';
GO

USE master
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_2');
GO

select count(*) from dbo.sysforeignkeys where fkeyid = object_id('fk_2');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_2');
GO

create table fk_3 (a int, primary key (a))
GO

create table fk_4 (a int, b int, primary key (a), foreign key (b) references fk_3(a))
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_4');
GO

-- sysforeignkeys should also exist in dbo schema
SELECT COUNT(*) FROM dbo.SySFoReIGNkeYs where fkeyid = object_id('fk_4');
go

-- In case of cross-db, sysforeignkeys should also exist in dbo schema
-- should not be visible here
SELECT COUNT(*) FROM db1.sys.SySFoReIGNkeYs where fkeyid = object_id('fk_4');
go

SELECT COUNT(*) FROM db1.dbo.SySFoReIGNkeYs where fkeyid = object_id('fk_4');
go

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
GO

USE db1
GO

select count(*) from sys.sysforeignkeys where fkeyid = object_id('fk_4');
GO

select count(*) from dbo.sysforeignkeys where fkeyid = object_id('fk_4');
GO

select count(*) from sys.foreign_keys where parent_object_id = object_id('fk_4');
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