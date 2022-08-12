drop table if exists babel_1994_vu_prepare_t1;
go

create table babel_1994_vu_prepare_t1(
    c5nn char(5) not null,
    c5n character(5) null
);
go

insert into babel_1994_vu_prepare_t1 values('ab ', 'ab ');
create index babel_1994_vu_prepare_idx on babel_1994_vu_prepare_t1(c5nn);
go

-- default length of CHAR should be 1. Otherwise, it will crash on the below select statement.
drop table if exists babel_1994_vu_prepare_t2;
go

CREATE TABLE babel_1994_vu_prepare_t2 (c1 CHAR);
INSERT INTO babel_1994_vu_prepare_t2 VALUES ('A');
GO
