create table sys_sp_pkeys_dep_vu_prepare_t1(a int, primary key(a))
go

create procedure sys_sp_pkeys_dep_vu_prepare_p1 as
    exec sp_pkeys @table_name = 'sys_sp_pkeys_dep_vu_prepare_t1'
go
