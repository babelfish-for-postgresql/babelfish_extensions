CREATE DATABASE db1_sys_sysforeignkeys;
GO

USE db1_sys_sysforeignkeys
GO

create table fk_1_sys_sysforeignkeys (a int, primary key (a))
GO

create table fk_2_sys_sysforeignkeys (a int, b int, primary key (a), foreign key (b) references fk_1_sys_sysforeignkeys(a))
GO

USE master
GO

create table fk_3_sys_sysforeignkeys (a int, primary key (a))
GO

create table fk_4_sys_sysforeignkeys (a int, b int, primary key (a), foreign key (b) references fk_3_sys_sysforeignkeys(a))
GO
