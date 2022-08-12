CREATE DATABASE sys_key_constraints_vu_prepare_db1;
GO

USE sys_key_constraints_vu_prepare_db1
GO

create table sys_key_constraints_vu_prepare_uq_1 (a int not null unique)
GO

USE master
GO

create table sys_key_constraints_vu_prepare_uq_2 (a int not null unique)
GO
