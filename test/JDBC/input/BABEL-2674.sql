USE master
go

drop table if exists babel_2674_t1;
go
create table babel_2674_t1 (A int);
go
insert into babel_2674_t1 values (1);
go
insert into babel_2674_t1 (a) values (2);
go
insert into babel_2674_t1 (A) values (3);
go
select * from babel_2674_t1;
go

drop view if exists babel_2674_v1;
go
create view babel_2674_v1 as select A FROM babel_2674_t1;
go
insert into babel_2674_v1 values (4);
go
insert into babel_2674_v1 (a) values (5);
go
insert into babel_2674_v1 (A) values (6);
go
select * from babel_2674_v1;
go
select * from babel_2674_v1 where a = 1;
go
select * from babel_2674_v1 where A = 2;
go

drop view if exists babel_2674_v1;
go
select * from babel_2674_t1;
go

SELECT A into babel_2674_t2 FROM babel_2674_t1;
go
select * from babel_2674_t2;
go
INSERT INTO babel_2674_t2 SELECT 7;
go
INSERT INTO babel_2674_t2 (a) SELECT 8;
go
INSERT INTO babel_2674_t2 (A) SELECT 9;
go
select * from babel_2674_t2;
go

drop table if exists babel_2674_t1;
go
drop table if exists babel_2674_t2;
go