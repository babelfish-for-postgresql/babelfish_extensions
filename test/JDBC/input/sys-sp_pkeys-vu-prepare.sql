create database sys_sp_pkeys_vu_prepare_db1
go


create table sys_sp_pkeys_vu_prepare_t1(a int, primary key(a))
go
create table sys_sp_pkeys_vu_prepare_t2(a int, b int, c int, primary key(b, c))
go
create table sys_sp_pkeys_vu_prepare_t3(a int, b int, c int, primary key(c, b))
go
create table sys_sp_pkeys_vu_prepare_t4(a int)
go

-- cross reference database 
use sys_sp_pkeys_vu_prepare_db1
go

create table sys_sp_pkeys_vu_prepare_t1(a int, primary key(a))
go
create table sys_sp_pkeys_vu_prepare_t2(a int, b int, c int, primary key(b, c))
go
create table sys_sp_pkeys_vu_prepare_t3(a int, b int, c int, primary key(c, b))
go
create table sys_sp_pkeys_vu_prepare_t4(a int)
go

