create table babel_2144_vu_prepare_t1(c1 int, c2 int);
go
create table babel_2144_vu_prepare_t2(c1 int, c2 int);
go
insert into babel_2144_vu_prepare_t1 values (12,15);
go
insert into babel_2144_vu_prepare_t1 values (0,0);
go
insert into babel_2144_vu_prepare_t2 values (13,16);
go
insert into babel_2144_vu_prepare_t2 values (0,0);
go
CREATE VIEW babel_2144_vu_prepare_v1 AS SELECT * FROM babel_2144_vu_prepare_t2 WHERE c2 > 10;
go

