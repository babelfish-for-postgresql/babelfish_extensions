-- tsql
create table test_int_numeric_vu(a int);
GO

-- insert 1M rows of data
INSERT INTO test_int_numeric_vu (a) SELECT generate_series(1, 1000000);
GO

INSERT INTO test_int_numeric_vu VALUES (NULL), (-2147483648), (2147483647);
GO

CREATE INDEX test_int_numeric_vu_idx on test_int_numeric_vu(a);
GO

-- tsql
create procedure test_int_numeric_p1 as
select count(*) from test_int_numeric_vu where a IS NULL;
GO

-- seq scan
create procedure test_int_numeric_p2 as
select count(*) from test_int_numeric_vu where a <> 5.0;
GO

create procedure test_int_numeric_p3 as
select count(*) from test_int_numeric_vu where 5.0 <> a;
GO

-- index scan on < and >
create procedure test_int_numeric_p4 as
select count(*) from test_int_numeric_vu where a < 5.0;
GO

create procedure test_int_numeric_p5 as
select count(*) from test_int_numeric_vu where 5.0 > a;
GO

create procedure test_int_numeric_p6 as
select count(*) from test_int_numeric_vu where a < -2147483648.0;
GO

create procedure test_int_numeric_p7 as
select count(*) from test_int_numeric_vu where -2147483648.0 > a;
GO

create procedure test_int_numeric_p8 as
select count(*) from test_int_numeric_vu where a <= 5.0;
GO

create procedure test_int_numeric_p9 as
select count(*) from test_int_numeric_vu where 5.0 >= a;
GO

create procedure test_int_numeric_p10 as
select count(*) from test_int_numeric_vu where a > 999995.0;
GO

create procedure test_int_numeric_p11 as
select count(*) from test_int_numeric_vu where 999995.0 < a;
GO

create procedure test_int_numeric_p12 as
select count(*) from test_int_numeric_vu where a >= 999995.0;
GO

create procedure test_int_numeric_p13 as
select count(*) from test_int_numeric_vu where 999995.0 <= a;
GO

create procedure test_int_numeric_p14 as
select count(*) from test_int_numeric_vu where a > 2147483647.0;
go

create procedure test_int_numeric_p15 as
select count(*) from test_int_numeric_vu where 2147483647.0 < a;
go

-- seq scan on < and >
create procedure test_int_numeric_p16 as
select count(*) from test_int_numeric_vu where a > 5.0;
GO

create procedure test_int_numeric_p17 as
select count(*) from test_int_numeric_vu where 5.0 < a;
GO

-- index scan for BETWEEN
create procedure test_int_numeric_p18 as
select count(*) from test_int_numeric_vu where a between 5.0 and 10.0;
GO

-- seq scan for BETWEEN
create procedure test_int_numeric_p19 as
select count(*) from test_int_numeric_vu where a between 5.0 and 999999.0;
GO

-- mix of int op numeric and int op int
create procedure test_int_numeric_p20 as
select count(*) from test_int_numeric_vu where (a between 5.0 and 999999.0) and a = 10;
GO

create procedure test_int_numeric_p21 as
select count(*) from test_int_numeric_vu where a > 5.0 and a < 7;
Go

create procedure test_int_numeric_p22 as
select count(*) from test_int_numeric_vu where 5.0 < a and 7 > a;
Go

-- shouldn't be any regression on int op int operators

-- seq scan
create procedure test_int_numeric_p23 as
select count(*) from test_int_numeric_vu where a <> 5;
GO

-- index scan on < and >
create procedure test_int_numeric_p24 as
select count(*) from test_int_numeric_vu where a < 5;
GO

create procedure test_int_numeric_p25 as
select count(*) from test_int_numeric_vu where a < -2147483648;
GO

create procedure test_int_numeric_p26 as
select count(*) from test_int_numeric_vu where a <= 5;
GO

create procedure test_int_numeric_p27 as
select count(*) from test_int_numeric_vu where a > 999995;
GO

create procedure test_int_numeric_p28 as
select count(*) from test_int_numeric_vu where a >= 999995;
GO

create procedure test_int_numeric_p29 as
select count(*) from test_int_numeric_vu where a > 2147483647;
go

-- seq scan on < and >
create procedure test_int_numeric_p30 as
select count(*) from test_int_numeric_vu where a > 5;
GO

-- index scan for BETWEEN
create procedure test_int_numeric_p31 as
select count(*) from test_int_numeric_vu where a between 5 and 10;
GO

-- seq scan for BETWEEN
create procedure test_int_numeric_p32 as
select count(*) from test_int_numeric_vu where a between 5 and 999999;
GO