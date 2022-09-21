create procedure babel_sp_sproc_columns_dep_vu_prepare_p1 as
    select 1
go

create procedure babel_sp_sproc_columns_dep_vu_prepare_p2 as
    EXEC sp_sproc_columns @procedure_name = 'babel_sp_sproc_columns_dep_vu_prepare_p1'
go

