create table babel_2955_vu_verify_t1 (a int not null)
go

create unique index ix1 on babel_2955_vu_verify_t1(a) with pad_index
go

create unique index ix2 on babel_2955_vu_verify_t1(a) with pad_index=on
go

create unique index ix3 on babel_2955_vu_verify_t1(a) with pad_index=off
go

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
go

create table babel_2955_vu_verify_t2 (a int not null)
go

create unique index ix1 on babel_2955_vu_verify_t2(a) with pad_index
go

create unique index ix2 on babel_2955_vu_verify_t2(a) with pad_index=on
go

create unique index ix3 on babel_2955_vu_verify_t2(a) with pad_index=off
go
