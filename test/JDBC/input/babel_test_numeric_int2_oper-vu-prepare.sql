-- tsql
create table babel_test_numeric_int2_vu_prepare(a numeric(18,2));
GO

-- insert data
INSERT INTO babel_test_numeric_int2_vu_prepare (a) SELECT cast(generate_series(1, 32767) as numeric(18,2));
GO

INSERT INTO babel_test_numeric_int2_vu_prepare VALUES (NULL), (-32768.00), (32767.00);
GO

CREATE INDEX babel_test_numeric_int2_vu_prepare_idx on babel_test_numeric_int2_vu_prepare(a);
GO

-- procedures dependency on all the numeric,int2 or int2, numeric operators

create procedure babel_test_numeric_int2_p0 as
select count(*) from babel_test_numeric_int2_vu_prepare where a = cast(1 as smallint);
GO

create procedure babel_test_numeric_int2_p00 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(1 as smallint) = a;
GO

create procedure babel_test_numeric_int2_p1 as
select count(*) from babel_test_numeric_int2_vu_prepare where a IS NULL;
GO

-- seq scan
create procedure babel_test_numeric_int2_p2 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p3 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) <> a;
GO

-- index scan on < and >
create procedure babel_test_numeric_int2_p4 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p5 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) > a;
GO

create procedure babel_test_numeric_int2_p6 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint);
GO

create procedure babel_test_numeric_int2_p7 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(-32768 as smallint) > a;
GO

create procedure babel_test_numeric_int2_p8 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p9 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) >= a;
GO

create procedure babel_test_numeric_int2_p10 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint);
GO

create procedure babel_test_numeric_int2_p11 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) < a;
GO

create procedure babel_test_numeric_int2_p12 as
select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint);
GO

create procedure babel_test_numeric_int2_p13 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) <= a;
GO

create procedure babel_test_numeric_int2_p14 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint);
go

create procedure babel_test_numeric_int2_p15 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32767 as smallint) < a;
go

-- seq scan on < and >
create procedure babel_test_numeric_int2_p16 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p17 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a;
GO

-- index scan for BETWEEN
create procedure babel_test_numeric_int2_p18 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint);
GO

-- seq scan for BETWEEN
create procedure babel_test_numeric_int2_p19 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32767 as smallint);
GO

-- mix of numeric op int2 and numeric op numeric
create procedure babel_test_numeric_int2_p20 as
select count(*) from babel_test_numeric_int2_vu_prepare where (a between cast(5 as smallint) and cast(32763 as smallint)) and a = cast(10 as smallint);
GO

create procedure babel_test_numeric_int2_p21 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint) and a < cast(7 as smallint);
Go

create procedure babel_test_numeric_int2_p22 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a and cast(7 as smallint) > a;
Go

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create procedure babel_test_numeric_int2_p23 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint);
GO

-- index scan on < and >
create procedure babel_test_numeric_int2_p24 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p25 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint);
GO

create procedure babel_test_numeric_int2_p26 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint);
GO

create procedure babel_test_numeric_int2_p27 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint);
GO

create procedure babel_test_numeric_int2_p28 as
select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint);
GO

create procedure babel_test_numeric_int2_p29 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint);
go

-- seq scan on < and >
create procedure babel_test_numeric_int2_p30 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint);
GO

-- index scan for BETWEEN
create procedure babel_test_numeric_int2_p31 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint);
GO

-- seq scan for BETWEEN
create procedure babel_test_numeric_int2_p32 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32763 as smallint);
GO

-- view body dependency on all the numeric,int2 or int2, numeric operators
create view babel_test_numeric_int2_v0 as
select count(*) from babel_test_numeric_int2_vu_prepare where a = cast(1 as smallint);
GO

create view babel_test_numeric_int2_v00 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(1 as smallint) = a;
GO

create view babel_test_numeric_int2_v1 as
select count(*) from babel_test_numeric_int2_vu_prepare where a IS NULL;
GO

-- seq scan
create view babel_test_numeric_int2_v2 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint);
GO

create view babel_test_numeric_int2_v3 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) <> a;
GO

-- index scan on < and >
create view babel_test_numeric_int2_v4 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint);
GO

create view babel_test_numeric_int2_v5 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) > a;
GO

create view babel_test_numeric_int2_v6 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint);
GO

create view babel_test_numeric_int2_v7 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(-32768 as smallint) > a;
GO

create view babel_test_numeric_int2_v8 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint);
GO

create view babel_test_numeric_int2_v9 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) >= a;
GO

create view babel_test_numeric_int2_v10 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint);
GO

create view babel_test_numeric_int2_v11 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) < a;
GO

create view babel_test_numeric_int2_v12 as
select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint);
GO

create view babel_test_numeric_int2_v13 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) <= a;
GO

create view babel_test_numeric_int2_v14 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint);
go

create view babel_test_numeric_int2_v15 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(32767 as smallint) < a;
go

-- seq scan on < and >
create view babel_test_numeric_int2_v16 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint);
GO

create view babel_test_numeric_int2_v17 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a;
GO

-- index scan for BETWEEN
create view babel_test_numeric_int2_v18 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint);
GO

-- seq scan for BETWEEN
create view babel_test_numeric_int2_v19 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32767 as smallint);
GO

-- mix of numeric op int2 and numeric op numeric
create view babel_test_numeric_int2_v20 as
select count(*) from babel_test_numeric_int2_vu_prepare where (a between cast(5 as smallint) and cast(32763 as smallint)) and a = cast(10 as smallint);
GO

create view babel_test_numeric_int2_v21 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint) and a < cast(7 as smallint);
Go

create view babel_test_numeric_int2_v22 as
select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a and cast(7 as smallint) > a;
Go

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create view babel_test_numeric_int2_v23 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint);
GO

-- index scan on < and >
create view babel_test_numeric_int2_v24 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint);
GO

create view babel_test_numeric_int2_v25 as
select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint);
GO

create view babel_test_numeric_int2_v26 as
select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint);
GO

create view babel_test_numeric_int2_v27 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint);
GO

create view babel_test_numeric_int2_v28 as
select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint);
GO

create view babel_test_numeric_int2_v29 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint);
go

-- seq scan on < and >
create view babel_test_numeric_int2_v30 as
select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint);
GO

-- index scan for BETWEEN
create view babel_test_numeric_int2_v31 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint);
GO

-- seq scan for BETWEEN
create view babel_test_numeric_int2_v32 as
select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32763 as smallint);
GO

-- functions dependency on all the numeric,int2 or int2, numeric operators
create function babel_test_numeric_int2_f0() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a = cast(1 as smallint)) end;
GO

create function babel_test_numeric_int2_f00() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(1 as smallint) = a) end;
GO

create function babel_test_numeric_int2_f1() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a IS NULL) end;
GO

-- seq scan
create function babel_test_numeric_int2_f2() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f3() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) <> a) end;
GO

-- index scan on < and >
create function babel_test_numeric_int2_f4() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f5() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) > a) end;
GO

create function babel_test_numeric_int2_f6() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint)) end;
GO

create function babel_test_numeric_int2_f7() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(-32768 as smallint) > a) end;
GO

create function babel_test_numeric_int2_f8() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f9() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) >= a) end;
GO

create function babel_test_numeric_int2_f10() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint)) end;
GO

create function babel_test_numeric_int2_f11() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) < a) end;
GO

create function babel_test_numeric_int2_f12() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint)) end;
GO

create function babel_test_numeric_int2_f13() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(32763 as smallint) <= a) end;
GO

create function babel_test_numeric_int2_f14() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint)) end;
GO

create function babel_test_numeric_int2_f15() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(32767 as smallint) < a) end;
GO

-- seq scan on < and >
create function babel_test_numeric_int2_f16() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f17() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a) end;
GO

-- index scan for BETWEEN
create function babel_test_numeric_int2_f18() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint)) end;
GO

-- seq scan for BETWEEN
create function babel_test_numeric_int2_f19() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32767 as smallint)) end;
GO

-- mix of numeric op int2 and numeric op numeric
create function babel_test_numeric_int2_f20() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where (a between cast(5 as smallint) and cast(32763 as smallint)) and a = cast(10 as smallint)) end;
GO

create function babel_test_numeric_int2_f21() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint) and a < cast(7 as smallint)) end;
GO

create function babel_test_numeric_int2_f22() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where cast(5 as smallint) < a and cast(7 as smallint) > a) end;
GO

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create function babel_test_numeric_int2_f23() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a <> cast(5 as smallint)) end;
GO

-- index scan on < and >
create function babel_test_numeric_int2_f24() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f25() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a < cast(-32768 as smallint)) end;
GO

create function babel_test_numeric_int2_f26() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a <= cast(5 as smallint)) end;
GO

create function babel_test_numeric_int2_f27() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32763 as smallint)) end;
GO

create function babel_test_numeric_int2_f28() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a >= cast(32763 as smallint)) end;
GO

create function babel_test_numeric_int2_f29() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(32767 as smallint)) end;
GO

-- seq scan on < and >
create function babel_test_numeric_int2_f30() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a > cast(5 as smallint)) end;
GO

-- index scan for BETWEEN
create function babel_test_numeric_int2_f31() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(10 as smallint)) end;
GO

-- seq scan for BETWEEN
create function babel_test_numeric_int2_f32() returns int as
begin return (select count(*) from babel_test_numeric_int2_vu_prepare where a between cast(5 as smallint) and cast(32763 as smallint)) end;
GO