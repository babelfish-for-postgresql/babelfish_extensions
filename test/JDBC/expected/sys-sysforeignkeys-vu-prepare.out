CREATE DATABASE sys_sysforeignkeys_vu_prepare_db1;
GO

USE sys_sysforeignkeys_vu_prepare_db1
GO

create table sys_sysforeignkeys_vu_prepare_fk1 (a int, primary key (a))
GO

create table sys_sysforeignkeys_vu_prepare_fk2 (a int, b int, primary key (a), foreign key (b) references sys_sysforeignkeys_vu_prepare_fk1(a))
GO

USE master
GO

create table sys_sysforeignkeys_vu_prepare_fk3 (a int, primary key (a))
GO

create table sys_sysforeignkeys_vu_prepare_fk4 (a int, b int, primary key (a), foreign key (b) references sys_sysforeignkeys_vu_prepare_fk3(a))
GO
