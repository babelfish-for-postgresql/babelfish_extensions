drop table if exists pad;
go

create table pad(
    c5nn char(5) not null,
    c5n character(5) null
);
go

insert into pad values('ab ', 'ab ');
create index pad_c5nn_idx on pad(c5nn);
go

-- default length of CHAR should be 1. Otherwise, it will crash on the below select statement.
drop table if exists t1_babel_1994_char;
go

CREATE TABLE t1_babel_1994_char (c1 CHAR);
INSERT INTO t1_babel_1994_char VALUES ('A');
GO
