create table babel_2917_vu_prepare_t1 (a int not null)
go

create unique index ix1 on babel_2917_vu_prepare_t1(a) with ignore_dup_key
go

create unique index ix2 on babel_2917_vu_prepare_t1(a) with ignore_dup_key=on
go

create unique index ix3 on babel_2917_vu_prepare_t1(a) with ignore_dup_key=off
go

insert into babel_2917_vu_prepare_t1 values (1)
GO

sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_ignore_dup_key', 'ignore'
go

create table babel_2917_vu_prepare_t2 (a int not null)
go

create unique index ix1 on babel_2917_vu_prepare_t2(a) with ignore_dup_key
go

create unique index ix2 on babel_2917_vu_prepare_t2(a) with ignore_dup_key=on
go

create unique index ix3 on babel_2917_vu_prepare_t2(a) with ignore_dup_key=off
go

insert into babel_2917_vu_prepare_t2 values (1)
GO