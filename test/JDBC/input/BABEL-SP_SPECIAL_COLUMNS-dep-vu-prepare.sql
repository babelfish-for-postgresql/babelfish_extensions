create table babel_sp_special_columns_dep_vu_prepare_t1(a int, primary key(a))
go
create procedure babel_sp_special_columns_dep_vu_prepare_p1 as
    exec sp_special_columns @table_name = 'babel_sp_special_columns_dep_vu_prepare_t1'
go
