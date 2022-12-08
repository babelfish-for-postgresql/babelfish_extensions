create procedure babel_sp_sproc_columns_100_dep_vu_prepare_p1 as
    select 1
go

create procedure babel_sp_sproc_columns_100_dep_vu_prepare_p2 as
    EXEC sp_sproc_columns_100 @procedure_name = 'babel_sp_sproc_columns_100_dep_vu_prepare_p1'
go

create procedure babel_sp_sproc_columns_100_dep_vu_prepare_p3 as
    EXEC sp_sproc_columns_100 @procedure_name = 'BABEL_sp_SpRoC_columns_100_DEP_vu_PrePare_p1'
go
