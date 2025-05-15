-- tsql
create table babel_test_numeric_int4_vu_prepare(a numeric(18,2));
GO

-- insert data
INSERT INTO babel_test_numeric_int4_vu_prepare (a) SELECT cast(generate_series(1, 100000) as numeric(18,2));
GO

INSERT INTO babel_test_numeric_int4_vu_prepare VALUES (NULL), (-2147483648.00), (2147483647.00);
GO

CREATE INDEX babel_test_numeric_int4_vu_prepare_idx on babel_test_numeric_int4_vu_prepare(a);
GO

create procedure babel_test_numeric_int4_p0 as
select count(*) from babel_test_numeric_int4_vu_prepare where a = cast(1 as int);
GO

create procedure babel_test_numeric_int4_p00 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(1 as int) = a;
GO

create procedure babel_test_numeric_int4_p1 as
select count(*) from babel_test_numeric_int4_vu_prepare where a IS NULL;
GO

-- seq scan
create procedure babel_test_numeric_int4_p2 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int);
GO

create procedure babel_test_numeric_int4_p3 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) <> a;
GO

-- index scan on < and >
create procedure babel_test_numeric_int4_p4 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int);
GO

create procedure babel_test_numeric_int4_p5 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) > a;
GO

create procedure babel_test_numeric_int4_p6 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int);
GO

create procedure babel_test_numeric_int4_p7 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(-2147483648 as int) > a;
GO

create procedure babel_test_numeric_int4_p8 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int);
GO

create procedure babel_test_numeric_int4_p9 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) >= a;
GO

create procedure babel_test_numeric_int4_p10 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int);
GO

create procedure babel_test_numeric_int4_p11 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) < a;
GO

create procedure babel_test_numeric_int4_p12 as
select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int);
GO

create procedure babel_test_numeric_int4_p13 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) <= a;
GO

create procedure babel_test_numeric_int4_p14 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int);
go

create procedure babel_test_numeric_int4_p15 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(2147483647 as int) < a;
go

-- seq scan on < and >
create procedure babel_test_numeric_int4_p16 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int);
GO

create procedure babel_test_numeric_int4_p17 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a;
GO

-- index scan for BETWEEN
create procedure babel_test_numeric_int4_p18 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int);
GO

-- seq scan for BETWEEN
create procedure babel_test_numeric_int4_p19 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(2147483647 as int);
GO

-- mix of numeric op int4 and numeric op numeric
create procedure babel_test_numeric_int4_p20 as
select count(*) from babel_test_numeric_int4_vu_prepare where (a between cast(5 as int) and cast(99995 as int)) and a = cast(10 as int);
GO

create procedure babel_test_numeric_int4_p21 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int) and a < cast(7 as int);
Go

create procedure babel_test_numeric_int4_p22 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a and cast(7 as int) > a;
Go

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create procedure babel_test_numeric_int4_p23 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int);
GO

-- index scan on < and >
create procedure babel_test_numeric_int4_p24 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int);
GO

create procedure babel_test_numeric_int4_p25 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int);
GO

create procedure babel_test_numeric_int4_p26 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int);
GO

create procedure babel_test_numeric_int4_p27 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int);
GO

create procedure babel_test_numeric_int4_p28 as
select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int);
GO

create procedure babel_test_numeric_int4_p29 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int);
go

-- seq scan on < and >
create procedure babel_test_numeric_int4_p30 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int);
GO

-- index scan for BETWEEN
create procedure babel_test_numeric_int4_p31 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int);
GO

-- seq scan for BETWEEN
create procedure babel_test_numeric_int4_p32 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(99995 as int);
GO

-- view body dependency on all the numeric,int4 or int4, numeric operators
GO

-- tsql
create view babel_test_numeric_int4_v0 as
select count(*) from babel_test_numeric_int4_vu_prepare where a = cast(1 as int);
GO

create view babel_test_numeric_int4_v00 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(1 as int) = a;
GO

create view babel_test_numeric_int4_v1 as
select count(*) from babel_test_numeric_int4_vu_prepare where a IS NULL;
GO

-- seq scan
create view babel_test_numeric_int4_v2 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int);
GO

create view babel_test_numeric_int4_v3 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) <> a;
GO

-- index scan on < and >
create view babel_test_numeric_int4_v4 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int);
GO

create view babel_test_numeric_int4_v5 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) > a;
GO

create view babel_test_numeric_int4_v6 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int);
GO

create view babel_test_numeric_int4_v7 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(-2147483648 as int) > a;
GO

create view babel_test_numeric_int4_v8 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int);
GO

create view babel_test_numeric_int4_v9 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) >= a;
GO

create view babel_test_numeric_int4_v10 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int);
GO

create view babel_test_numeric_int4_v11 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) < a;
GO

create view babel_test_numeric_int4_v12 as
select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int);
GO

create view babel_test_numeric_int4_v13 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) <= a;
GO

create view babel_test_numeric_int4_v14 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int);
go

create view babel_test_numeric_int4_v15 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(2147483647 as int) < a;
go

-- seq scan on < and >
create view babel_test_numeric_int4_v16 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int);
GO

create view babel_test_numeric_int4_v17 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a;
GO

-- index scan for BETWEEN
create view babel_test_numeric_int4_v18 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int);
GO

-- seq scan for BETWEEN
create view babel_test_numeric_int4_v19 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(2147483647 as int);
GO

-- mix of numeric op int4 and numeric op numeric
create view babel_test_numeric_int4_v20 as
select count(*) from babel_test_numeric_int4_vu_prepare where (a between cast(5 as int) and cast(99995 as int)) and a = cast(10 as int);
GO

create view babel_test_numeric_int4_v21 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int) and a < cast(7 as int);
Go

create view babel_test_numeric_int4_v22 as
select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a and cast(7 as int) > a;
Go

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create view babel_test_numeric_int4_v23 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int);
GO

-- index scan on < and >
create view babel_test_numeric_int4_v24 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int);
GO

create view babel_test_numeric_int4_v25 as
select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int);
GO

create view babel_test_numeric_int4_v26 as
select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int);
GO

create view babel_test_numeric_int4_v27 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int);
GO

create view babel_test_numeric_int4_v28 as
select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int);
GO

create view babel_test_numeric_int4_v29 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int);
go

-- seq scan on < and >
create view babel_test_numeric_int4_v30 as
select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int);
GO

-- index scan for BETWEEN
create view babel_test_numeric_int4_v31 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int);
GO

-- seq scan for BETWEEN
create view babel_test_numeric_int4_v32 as
select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(99995 as int);
GO

-- functions dependency on all the numeric,int4 or int4, numeric operators
GO

-- tsql
create function babel_test_numeric_int4_f0() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a = cast(1 as int)) end;
GO

create function babel_test_numeric_int4_f00() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(1 as int) = a) end;
GO

create function babel_test_numeric_int4_f1() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a IS NULL) end;
GO

-- seq scan
create function babel_test_numeric_int4_f2() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f3() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) <> a) end;
GO

-- index scan on < and >
create function babel_test_numeric_int4_f4() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f5() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) > a) end;
GO

create function babel_test_numeric_int4_f6() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int)) end;
GO

create function babel_test_numeric_int4_f7() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(-2147483648 as int) > a) end;
GO

create function babel_test_numeric_int4_f8() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f9() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) >= a) end;
GO

create function babel_test_numeric_int4_f10() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int)) end;
GO

create function babel_test_numeric_int4_f11() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) < a) end;
GO

create function babel_test_numeric_int4_f12() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int)) end;
GO

create function babel_test_numeric_int4_f13() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(99995 as int) <= a) end;
GO

create function babel_test_numeric_int4_f14() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int)) end;
GO

create function babel_test_numeric_int4_f15() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(2147483647 as int) < a) end;
GO

-- seq scan on < and >
create function babel_test_numeric_int4_f16() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f17() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a) end;
GO

-- index scan for BETWEEN
create function babel_test_numeric_int4_f18() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int)) end;
GO

-- seq scan for BETWEEN
create function babel_test_numeric_int4_f19() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(2147483647 as int)) end;
GO

-- mix of numeric op int4 and numeric op numeric
create function babel_test_numeric_int4_f20() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where (a between cast(5 as int) and cast(99995 as int)) and a = cast(10 as int)) end;
GO

create function babel_test_numeric_int4_f21() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int) and a < cast(7 as int)) end;
GO

create function babel_test_numeric_int4_f22() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where cast(5 as int) < a and cast(7 as int) > a) end;
GO

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create function babel_test_numeric_int4_f23() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a <> cast(5 as int)) end;
GO

-- index scan on < and >
create function babel_test_numeric_int4_f24() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f25() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a < cast(-2147483648 as int)) end;
GO

create function babel_test_numeric_int4_f26() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a <= cast(5 as int)) end;
GO

create function babel_test_numeric_int4_f27() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(99995 as int)) end;
GO

create function babel_test_numeric_int4_f28() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a >= cast(99995 as int)) end;
GO

create function babel_test_numeric_int4_f29() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(2147483647 as int)) end;
GO

-- seq scan on < and >
create function babel_test_numeric_int4_f30() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a > cast(5 as int)) end;
GO

-- index scan for BETWEEN
create function babel_test_numeric_int4_f31() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(10 as int)) end;
GO

-- seq scan for BETWEEN
create function babel_test_numeric_int4_f32() returns int as
begin return (select count(*) from babel_test_numeric_int4_vu_prepare where a between cast(5 as int) and cast(99995 as int)) end;
GO