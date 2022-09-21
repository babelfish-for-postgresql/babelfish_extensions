create database babel_sp_fkeys_vu_prepare_db1
go
use babel_sp_fkeys_vu_prepare_db1
go
create table babel_sp_fkeys_vu_prepare_t1(a int, primary key(a))
go
create table babel_sp_fkeys_vu_prepare_t2(a int, b int, c int, foreign key(b) references babel_sp_fkeys_vu_prepare_t1(a))
go
create table babel_sp_fkeys_vu_prepare_t3(a int, b int, c int, primary key(c, b))
go
create table babel_sp_fkeys_vu_prepare_t4(d int, e int, foreign key(d, e) references babel_sp_fkeys_vu_prepare_t3(c, b))
go
create table babel_sp_fkeys_vu_prepare_MyTable5(cOlUmN_a int, CoLuMn_b int, primary key(cOlUmN_a , CoLuMn_b))
go
create table babel_sp_fkeys_vu_prepare_MyTable6(cOlUmN_c int, CoLuMn_d int, foreign key(cOlUmN_c, CoLuMn_d) references babel_sp_fkeys_vu_prepare_MyTable5(cOlUmN_a, CoLuMn_b))
go
create table [babel_sp_fkeys_vu_prepare_MyTable7] ([MyColumn_a] int, [MyColumn_b] int, foreign key([MyColumn_a], [MyColumn_b]) references babel_sp_fkeys_vu_prepare_MyTable5(cOlUmN_a, CoLuMn_b))
go

use master
go
create table babel_sp_fkeys_vu_prepare_t3(a int, b int, c int, primary key(c, b))
go
create table babel_sp_fkeys_vu_prepare_t4(d int, e int, foreign key(d, e) references babel_sp_fkeys_vu_prepare_t3(c, b))
go