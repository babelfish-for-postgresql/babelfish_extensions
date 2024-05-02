-- tsql
create table test_int8_numeric_vu(a bigint);
GO

-- insert 1M rows of data
INSERT INTO test_int8_numeric_vu (a) SELECT generate_series(1, 1000000);
GO

INSERT INTO test_int8_numeric_vu VALUES (NULL), (-9223372036854775808), (9223372036854775807);
GO

CREATE INDEX test_int8_numeric_vu_idx on test_int8_numeric_vu(a);
GO

-- tsql
create procedure test_int8_numeric_p0 as
select count(*) from test_int8_numeric_vu where a = 1.0;
GO

create procedure test_int8_numeric_p00 as
select count(*) from test_int8_numeric_vu where 1.0 = a;
GO

create procedure test_int8_numeric_p1 as
select count(*) from test_int8_numeric_vu where a IS NULL;
GO

-- seq scan
create procedure test_int8_numeric_p2 as
select count(*) from test_int8_numeric_vu where a <> 5.0;
GO

create procedure test_int8_numeric_p3 as
select count(*) from test_int8_numeric_vu where 5.0 <> a;
GO

-- index scan on < and >
create procedure test_int8_numeric_p4 as
select count(*) from test_int8_numeric_vu where a < 5.0;
GO

create procedure test_int8_numeric_p5 as
select count(*) from test_int8_numeric_vu where 5.0 > a;
GO

create procedure test_int8_numeric_p6 as
select count(*) from test_int8_numeric_vu where a < -9223372036854775808.0;
GO

create procedure test_int8_numeric_p7 as
select count(*) from test_int8_numeric_vu where -9223372036854775808.0 > a;
GO

create procedure test_int8_numeric_p8 as
select count(*) from test_int8_numeric_vu where a <= 5.0;
GO

create procedure test_int8_numeric_p9 as
select count(*) from test_int8_numeric_vu where 5.0 >= a;
GO

create procedure test_int8_numeric_p10 as
select count(*) from test_int8_numeric_vu where a > 999995.0;
GO

create procedure test_int8_numeric_p11 as
select count(*) from test_int8_numeric_vu where 999995.0 < a;
GO

create procedure test_int8_numeric_p12 as
select count(*) from test_int8_numeric_vu where a >= 999995.0;
GO

create procedure test_int8_numeric_p13 as
select count(*) from test_int8_numeric_vu where 999995.0 <= a;
GO

create procedure test_int8_numeric_p14 as
select count(*) from test_int8_numeric_vu where a > 9223372036854775807.0;
go

create procedure test_int8_numeric_p15 as
select count(*) from test_int8_numeric_vu where 9223372036854775807.0 < a;
go

-- seq scan on < and >
create procedure test_int8_numeric_p16 as
select count(*) from test_int8_numeric_vu where a > 5.0;
GO

create procedure test_int8_numeric_p17 as
select count(*) from test_int8_numeric_vu where 5.0 < a;
GO

-- index scan for BETWEEN
create procedure test_int8_numeric_p18 as
select count(*) from test_int8_numeric_vu where a between 5.0 and 10.0;
GO

-- seq scan for BETWEEN
create procedure test_int8_numeric_p19 as
select count(*) from test_int8_numeric_vu where a between 5.0 and 999999.0;
GO

-- mix of int op numeric and int op int
create procedure test_int8_numeric_p20 as
select count(*) from test_int8_numeric_vu where (a between 5.0 and 999999.0) and a = 10;
GO

create procedure test_int8_numeric_p21 as
select count(*) from test_int8_numeric_vu where a > 5.0 and a < 7;
Go

create procedure test_int8_numeric_p22 as
select count(*) from test_int8_numeric_vu where 5.0 < a and 7 > a;
Go

-- shouldn't be any regression on int op int operators

-- seq scan
create procedure test_int8_numeric_p23 as
select count(*) from test_int8_numeric_vu where a <> 5;
GO

-- index scan on < and >
create procedure test_int8_numeric_p24 as
select count(*) from test_int8_numeric_vu where a < 5;
GO

create procedure test_int8_numeric_p25 as
select count(*) from test_int8_numeric_vu where a < -9223372036854775808;
GO

create procedure test_int8_numeric_p26 as
select count(*) from test_int8_numeric_vu where a <= 5;
GO

create procedure test_int8_numeric_p27 as
select count(*) from test_int8_numeric_vu where a > 999995;
GO

create procedure test_int8_numeric_p28 as
select count(*) from test_int8_numeric_vu where a >= 999995;
GO

create procedure test_int8_numeric_p29 as
select count(*) from test_int8_numeric_vu where a > 9223372036854775807;
go

-- seq scan on < and >
create procedure test_int8_numeric_p30 as
select count(*) from test_int8_numeric_vu where a > 5;
GO

-- index scan for BETWEEN
create procedure test_int8_numeric_p31 as
select count(*) from test_int8_numeric_vu where a between 5 and 10;
GO

-- seq scan for BETWEEN
create procedure test_int8_numeric_p32 as
select count(*) from test_int8_numeric_vu where a between 5 and 999999;
GO

-- view body dependency on all the int,numeric or numeric, int operators
GO

-- tsql
create view test_int8_numeric_v0 as
select count(*) from test_int8_numeric_vu where a = 1.0;
GO

create view test_int8_numeric_v00 as
select count(*) from test_int8_numeric_vu where 1.0 = a;
GO

create view test_int8_numeric_v1 as
select count(*) from test_int8_numeric_vu where a IS NULL;
GO

-- seq scan
create view test_int8_numeric_v2 as
select count(*) from test_int8_numeric_vu where a <> 5.0;
GO

create view test_int8_numeric_v3 as
select count(*) from test_int8_numeric_vu where 5.0 <> a;
GO

-- index scan on < and >
create view test_int8_numeric_v4 as
select count(*) from test_int8_numeric_vu where a < 5.0;
GO

create view test_int8_numeric_v5 as
select count(*) from test_int8_numeric_vu where 5.0 > a;
GO

create view test_int8_numeric_v6 as
select count(*) from test_int8_numeric_vu where a < -9223372036854775808.0;
GO

create view test_int8_numeric_v7 as
select count(*) from test_int8_numeric_vu where -9223372036854775808.0 > a;
GO

create view test_int8_numeric_v8 as
select count(*) from test_int8_numeric_vu where a <= 5.0;
GO

create view test_int8_numeric_v9 as
select count(*) from test_int8_numeric_vu where 5.0 >= a;
GO

create view test_int8_numeric_v10 as
select count(*) from test_int8_numeric_vu where a > 999995.0;
GO

create view test_int8_numeric_v11 as
select count(*) from test_int8_numeric_vu where 999995.0 < a;
GO

create view test_int8_numeric_v12 as
select count(*) from test_int8_numeric_vu where a >= 999995.0;
GO

create view test_int8_numeric_v13 as
select count(*) from test_int8_numeric_vu where 999995.0 <= a;
GO

create view test_int8_numeric_v14 as
select count(*) from test_int8_numeric_vu where a > 9223372036854775807.0;
go

create view test_int8_numeric_v15 as
select count(*) from test_int8_numeric_vu where 9223372036854775807.0 < a;
go

-- seq scan on < and >
create view test_int8_numeric_v16 as
select count(*) from test_int8_numeric_vu where a > 5.0;
GO

create view test_int8_numeric_v17 as
select count(*) from test_int8_numeric_vu where 5.0 < a;
GO

-- index scan for BETWEEN
create view test_int8_numeric_v18 as
select count(*) from test_int8_numeric_vu where a between 5.0 and 10.0;
GO

-- seq scan for BETWEEN
create view test_int8_numeric_v19 as
select count(*) from test_int8_numeric_vu where a between 5.0 and 999999.0;
GO

-- mix of int op numeric and int op int
create view test_int8_numeric_v20 as
select count(*) from test_int8_numeric_vu where (a between 5.0 and 999999.0) and a = 10;
GO

create view test_int8_numeric_v21 as
select count(*) from test_int8_numeric_vu where a > 5.0 and a < 7;
Go

create view test_int8_numeric_v22 as
select count(*) from test_int8_numeric_vu where 5.0 < a and 7 > a;
Go

-- shouldn't be any regression on int op int operators

-- seq scan
create view test_int8_numeric_v23 as
select count(*) from test_int8_numeric_vu where a <> 5;
GO

-- index scan on < and >
create view test_int8_numeric_v24 as
select count(*) from test_int8_numeric_vu where a < 5;
GO

create view test_int8_numeric_v25 as
select count(*) from test_int8_numeric_vu where a < -9223372036854775808;
GO

create view test_int8_numeric_v26 as
select count(*) from test_int8_numeric_vu where a <= 5;
GO

create view test_int8_numeric_v27 as
select count(*) from test_int8_numeric_vu where a > 999995;
GO

create view test_int8_numeric_v28 as
select count(*) from test_int8_numeric_vu where a >= 999995;
GO

create view test_int8_numeric_v29 as
select count(*) from test_int8_numeric_vu where a > 9223372036854775807;
go

-- seq scan on < and >
create view test_int8_numeric_v30 as
select count(*) from test_int8_numeric_vu where a > 5;
GO

-- index scan for BETWEEN
create view test_int8_numeric_v31 as
select count(*) from test_int8_numeric_vu where a between 5 and 10;
GO

-- seq scan for BETWEEN
create view test_int8_numeric_v32 as
select count(*) from test_int8_numeric_vu where a between 5 and 999999;
GO

-- functions dependency on all the int,numeric or numeric, int operators
GO

-- tsql
create function test_int8_numeric_f0() returns int as
begin return (select count(*) from test_int8_numeric_vu where a = 1.0) end;
GO

create function test_int8_numeric_f00() returns int as
begin return (select count(*) from test_int8_numeric_vu where 1.0 = a) end;
GO

create function test_int8_numeric_f1() returns int as
begin return (select count(*) from test_int8_numeric_vu where a IS NULL) end;
GO

-- seq scan
create function test_int8_numeric_f2() returns int as
begin return (select count(*) from test_int8_numeric_vu where a <> 5.0) end;
GO

create function test_int8_numeric_f3() returns int as
begin return (select count(*) from test_int8_numeric_vu where 5.0 <> a) end;
GO

-- index scan on < and >
create function test_int8_numeric_f4() returns int as
begin return (select count(*) from test_int8_numeric_vu where a < 5.0) end;
GO

create function test_int8_numeric_f5() returns int as
begin return (select count(*) from test_int8_numeric_vu where 5.0 > a) end;
GO

create function test_int8_numeric_f6() returns int as
begin return (select count(*) from test_int8_numeric_vu where a < -9223372036854775808.0) end;
GO

create function test_int8_numeric_f7() returns int as
begin return (select count(*) from test_int8_numeric_vu where -9223372036854775808.0 > a) end;
GO

create function test_int8_numeric_f8() returns int as
begin return (select count(*) from test_int8_numeric_vu where a <= 5.0) end;
GO

create function test_int8_numeric_f9() returns int as
begin return (select count(*) from test_int8_numeric_vu where 5.0 >= a) end;
GO

create function test_int8_numeric_f10() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 999995.0) end;
GO

create function test_int8_numeric_f11() returns int as
begin return (select count(*) from test_int8_numeric_vu where 999995.0 < a) end;
GO

create function test_int8_numeric_f12() returns int as
begin return (select count(*) from test_int8_numeric_vu where a >= 999995.0) end;
GO

create function test_int8_numeric_f13() returns int as
begin return (select count(*) from test_int8_numeric_vu where 999995.0 <= a) end;
GO

create function test_int8_numeric_f14() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 9223372036854775807.0) end;
go

create function test_int8_numeric_f15() returns int as
begin return (select count(*) from test_int8_numeric_vu where 9223372036854775807.0 < a) end;
go

-- seq scan on < and >
create function test_int8_numeric_f16() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 5.0) end;
GO

create function test_int8_numeric_f17() returns int as
begin return (select count(*) from test_int8_numeric_vu where 5.0 < a) end;
GO

-- index scan for BETWEEN
create function test_int8_numeric_f18() returns int as
begin return (select count(*) from test_int8_numeric_vu where a between 5.0 and 10.0) end;
GO

-- seq scan for BETWEEN
create function test_int8_numeric_f19() returns int as
begin return (select count(*) from test_int8_numeric_vu where a between 5.0 and 999999.0) end;
GO

-- mix of int op numeric and int op int
create function test_int8_numeric_f20() returns int as
begin return (select count(*) from test_int8_numeric_vu where (a between 5.0 and 999999.0) and a = 10) end;
GO

create function test_int8_numeric_f21() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 5.0 and a < 7) end;
Go

create function test_int8_numeric_f22() returns int as
begin return (select count(*) from test_int8_numeric_vu where 5.0 < a and 7 > a) end;
Go

-- shouldn't be any regression on int op int operators

-- seq scan
create function test_int8_numeric_f23() returns int as
begin return (select count(*) from test_int8_numeric_vu where a <> 5) end;
GO

-- index scan on < and >
create function test_int8_numeric_f24() returns int as
begin return (select count(*) from test_int8_numeric_vu where a < 5) end;
GO

create function test_int8_numeric_f25() returns int as
begin return (select count(*) from test_int8_numeric_vu where a < -9223372036854775808) end;
GO

create function test_int8_numeric_f26() returns int as
begin return (select count(*) from test_int8_numeric_vu where a <= 5) end;
GO

create function test_int8_numeric_f27() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 999995) end;
GO

create function test_int8_numeric_f28() returns int as
begin return (select count(*) from test_int8_numeric_vu where a >= 999995) end;
GO

create function test_int8_numeric_f29() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 9223372036854775807) end;
go

-- seq scan on < and >
create function test_int8_numeric_f30() returns int as
begin return (select count(*) from test_int8_numeric_vu where a > 5) end;
GO

-- index scan for BETWEEN
create function test_int8_numeric_f31() returns int as
begin return (select count(*) from test_int8_numeric_vu where a between 5 and 10) end;
GO

-- seq scan for BETWEEN
create function test_int8_numeric_f32() returns int as
begin return (select count(*) from test_int8_numeric_vu where a between 5 and 999999) end;
GO

-- table constraints
create table test_int8_numeric_t1(
    a bigint,
    b bigint,
    c bigint,
    d bigint,
    e bigint,
    f numeric,
    check (a = f),
    check (b < f),
    check (c <= f),
    check (d > f),
    check (e >= f)
)
GO

create table test_int8_numeric_t2(
    a numeric,
    b numeric,
    c numeric,
    d numeric,
    e numeric,
    f bigint,
    check (a = f),
    check (b < f),
    check (c <= f),
    check (d > f),
    check (e >= f)
)
GO