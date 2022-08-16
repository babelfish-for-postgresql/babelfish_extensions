drop index ix1 on babel_2955_vu_prepare_t1
go

drop index ix2 on babel_2955_vu_prepare_t1
go

drop index ix3 on babel_2955_vu_prepare_t1
go

drop table babel_2955_vu_prepare_t1
go

drop table babel_2955_vu_prepare_t2
go

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
go
