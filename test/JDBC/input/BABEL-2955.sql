create table t1 (a int not null)
go

create unique index ix1 on t1(a) with pad_index
go

create unique index ix2 on t1(a) with pad_index=on
go

create unique index ix3 on t1(a) with pad_index=off
go

drop index ix1 on t1
go

drop index ix2 on t1
go

drop index ix3 on t1
go

drop table t1
go

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
go

create table t1 (a int not null)
go

create unique index ix1 on t1(a) with pad_index
go

create unique index ix2 on t1(a) with pad_index=on
go

create unique index ix3 on t1(a) with pad_index=off
go

drop table t1
go

SELECT set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
go
