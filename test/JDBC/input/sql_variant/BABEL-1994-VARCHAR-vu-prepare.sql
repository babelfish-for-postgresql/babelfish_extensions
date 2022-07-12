drop table if exists person;
go
create table person(
    name_vcnn varchar(10) not null primary key,
    name_vcn varchar(10) null
);
go

insert into person values ('smith', 'smith');
go
insert into person values ('jones  ', 'jones  ');
go
insert into person values ('jones ', 'jones  ');
go