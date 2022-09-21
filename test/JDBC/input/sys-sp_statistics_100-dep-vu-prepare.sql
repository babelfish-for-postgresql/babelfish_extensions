create table sys_sp_statistics_100_dep_vu_prepare_t1(a int)
go

create procedure sys_sp_statistics_100_dep_vu_prepare_p1 as
    exec [sys].sp_statistics_100 @table_name = 'sys_sp_statistics_100_dep_vu_prepare_t1'
go