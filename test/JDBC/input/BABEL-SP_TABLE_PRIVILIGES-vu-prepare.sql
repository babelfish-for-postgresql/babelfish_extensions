create database babel_sp_table_priviliges_vu_prepare_db1
go
use babel_sp_table_priviliges_vu_prepare_db1
go
create table babel_sp_table_priviliges_vu_prepare_t1(a int, primary key(a))
go
create table babel_sp_table_priviliges_vu_prepare_t2(a int, b int, c int)
go
create table babel_sp_table_priviliges_vu_prepare_t3(a int, b int, c int)
go
create table babel_sp_table_priviliges_vu_prepare_t4(a int)
go
create table babel_sp_table_priviliges_vu_prepare_MyTable5 (a int, b int, c int)
go
create table [babel_sp_table_priviliges_vu_prepare_MyTable6] ([a] int, [b] int, [c] int)
go
create table babel_sp_table_priviliges_vu_prepare_foobar1(a int)
go
create table babel_sp_table_priviliges_vu_prepare_foobar2(b int)
go
create table babel_sp_table_priviliges_vu_prepare_folbar1(c int)
go

-- ensure that only tables from the same database are retrieved
use master
go
create table babel_sp_table_priviliges_vu_prepare_t4(a int)
go