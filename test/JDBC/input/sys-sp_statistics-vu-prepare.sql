create database sys_sp_statistics_vu_prepare_db1
go
use sys_sp_statistics_vu_prepare_db1
go
create table sys_sp_statistics_vu_prepare_t1(a int)
go
create index sys_sp_statistics_vu_prepare_i1 on sys_sp_statistics_vu_prepare_t1(a)
go
create table sys_sp_statistics_vu_prepare_t2(a int, b int)
go
create index sys_sp_statistics_vu_prepare_i2 on sys_sp_statistics_vu_prepare_t2(a,b)
go
create table sys_sp_statistics_vu_prepare_t3(a int, b int, c int)
go
create index sys_sp_statistics_vu_prepare_i3 on sys_sp_statistics_vu_prepare_t3(c,a)
go
CREATE TABLE sys_sp_statistics_vu_prepare_t4(
        c1 INT PRIMARY KEY
        , c2 CHAR(10) NOT NULL UNIQUE
        , c3 VARCHAR(20) NULL
)
create index sys_sp_statistics_vu_prepare_i4 on sys_sp_statistics_vu_prepare_t4(c2)
go

create table sys_sp_statistics_vu_prepare_t5(a int)

go