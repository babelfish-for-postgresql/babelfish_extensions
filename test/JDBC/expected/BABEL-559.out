create table babel_559_t1 (a int);
go

alter table babel_559_t1 add primary key (a asc);
go

create table babel_559_t2 (a int, b int, c int, d int);
go

alter table babel_559_t2 add primary key (a asc, b desc , c);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

alter table babel_559_t2 add unique (a asc);
go

alter table babel_559_t2 add unique (a asc, c desc);
go

create table babel_559_t3 (a int, primary key(a asc));
go

create table babel_559_t4 (a int, b int, primary key(a asc, b desc));
go

create table babel_559_t5 (a int, b int, c varchar(20), unique(a asc, b, c desc));
go

create table babel_559_t6 (a int);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go
