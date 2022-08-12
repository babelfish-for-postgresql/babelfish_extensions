drop table if exists babel_1994_varchar_vu_prepare_t1;
go
create table babel_1994_varchar_vu_prepare_t1(
    name_vcnn varchar(10) not null primary key,
    name_vcn varchar(10) null
);
go

insert into babel_1994_varchar_vu_prepare_t1 values ('smith', 'smith');
go
insert into babel_1994_varchar_vu_prepare_t1 values ('jones  ', 'jones  ');
go
insert into babel_1994_varchar_vu_prepare_t1 values ('jones ', 'jones  ');
go