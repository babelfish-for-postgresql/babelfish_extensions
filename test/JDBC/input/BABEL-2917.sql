create table t1 (a int not null)
go

create unique index ix1 on t1(a) with ignore_dup_key
go

create unique index ix2 on t1(a) with ignore_dup_key=on
go

create unique index ix3 on t1(a) with ignore_dup_key=off
go

drop index ix3 on t1
go

drop table t1
go

sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_ignore_dup_key', 'ignore'
go

create table t1 (a int not null)
go

create unique index ix1 on t1(a) with ignore_dup_key
go

create unique index ix2 on t1(a) with ignore_dup_key=on
go

create unique index ix3 on t1(a) with ignore_dup_key=off
go

drop index ix1 on t1
go

drop index ix2 on t1
go

drop index ix3 on t1
go

drop table t1
go

sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_ignore_dup_key', 'strict'
go
