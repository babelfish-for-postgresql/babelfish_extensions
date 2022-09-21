create table sys_sp_statistics_100_vu_prepare_t1(a int)
go

create index sys_sp_statistics_100_vu_prepare_i1 on sys_sp_statistics_100_vu_prepare_t1(a)
go

create table sys_sp_statistics_100_vu_prepare_t2(a int, b int not null primary key)
go

create index sys_sp_statistics_100_vu_prepare_i2 on sys_sp_statistics_100_vu_prepare_t2(a,b)
go

create table sys_sp_statistics_100_vu_prepare_t3(a int)
go

create database sys_sp_statistics_100_vu_prepare_db1
go
