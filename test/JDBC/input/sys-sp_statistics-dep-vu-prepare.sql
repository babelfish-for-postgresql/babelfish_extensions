create table sys_sp_statistics_dep_vu_prepare_t1(a int)
go

create procedure sys_sp_statistics_dep_vu_prepare_p1 as
    exec sp_statistics @table_name = 'sys_sp_statistics_dep_vu_prepare_t1'
go
