-- tsql
create table babel_test_numeric_money_vu_prepare(a numeric);
GO

-- insert data
INSERT INTO babel_test_numeric_money_vu_prepare (a) SELECT cast(generate_series(1, 100000) as numeric);
GO

-- Insert boundary values for money type
INSERT INTO babel_test_numeric_money_vu_prepare VALUES 
(NULL), 
(-922337203685477.5808), -- money min
(922337203685477.5807);  -- money max
GO

CREATE INDEX babel_test_numeric_money_vu_prepare_idx on babel_test_numeric_money_vu_prepare(a);
GO

-- Basic equality tests
create procedure babel_test_numeric_money_p0 as
select count(*) from babel_test_numeric_money_vu_prepare where a = cast(1 as money);
GO

create procedure babel_test_numeric_money_p00 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(1 as money) = a;
GO

create procedure babel_test_numeric_money_p1 as
select count(*) from babel_test_numeric_money_vu_prepare where a IS NULL;
GO

-- seq scan
create procedure babel_test_numeric_money_p2 as
select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money);
GO

create procedure babel_test_numeric_money_p3 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) <> a;
GO

-- index scan on < and >
create procedure babel_test_numeric_money_p4 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money);
GO

create procedure babel_test_numeric_money_p5 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) > a;
GO

create procedure babel_test_numeric_money_p6 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money);
GO

create procedure babel_test_numeric_money_p7 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(-922337203685477.5808 as money) > a;
GO

create procedure babel_test_numeric_money_p8 as
select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money);
GO

create procedure babel_test_numeric_money_p9 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) >= a;
GO

create procedure babel_test_numeric_money_p10 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money);
GO

create procedure babel_test_numeric_money_p11 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) < a;
GO

create procedure babel_test_numeric_money_p12 as
select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money);
GO

create procedure babel_test_numeric_money_p13 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) <= a;
GO

create procedure babel_test_numeric_money_p14 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money);
GO

create procedure babel_test_numeric_money_p15 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(922337203685477.5807 as money) < a;
GO

-- seq scan on < and >
create procedure babel_test_numeric_money_p16 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money);
GO

create procedure babel_test_numeric_money_p17 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a;
GO

-- index scan for BETWEEN
create procedure babel_test_numeric_money_p18 as
select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(10 as money);
GO

-- seq scan for BETWEEN
create procedure babel_test_numeric_money_p19 as
select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(922337203685477.5807 as money);
GO

-- mix of numeric op money and numeric op numeric
create procedure babel_test_numeric_money_p20 as
select count(*) from babel_test_numeric_money_vu_prepare where (a between cast(5 as money) and cast(99995 as money)) and a = cast(10 as money);
GO

create procedure babel_test_numeric_money_p21 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money) and a < cast(7 as money);
GO

create procedure babel_test_numeric_money_p22 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a and cast(7 as money) > a;
GO

-- shouldn't be any regression on numeric op numeric operators

-- seq scan
create procedure babel_test_numeric_money_p23 as
select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money);
GO

-- index scan on < and >
create procedure babel_test_numeric_money_p24 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money);
GO

create procedure babel_test_numeric_money_p25 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money);
GO

create procedure babel_test_numeric_money_p26 as
select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money);
GO

create procedure babel_test_numeric_money_p27 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money);
GO

create procedure babel_test_numeric_money_p28 as
select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money);
GO

create procedure babel_test_numeric_money_p29 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money);
GO

-- seq scan on < and >
create procedure babel_test_numeric_money_p30 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money);
GO


-- Views
create view babel_test_numeric_money_v0 as
select count(*) from babel_test_numeric_money_vu_prepare where a = cast(1 as money);
GO

create view babel_test_numeric_money_v00 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(1 as money) = a;
GO

create view babel_test_numeric_money_v1 as
select count(*) from babel_test_numeric_money_vu_prepare where a IS NULL;
GO

create view babel_test_numeric_money_v2 as
select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money);
GO

create view babel_test_numeric_money_v3 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) <> a;
GO

create view babel_test_numeric_money_v4 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money);
GO

create view babel_test_numeric_money_v5 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) > a;
GO

create view babel_test_numeric_money_v6 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money);
GO

create view babel_test_numeric_money_v7 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(-922337203685477.5808 as money) > a;
GO

create view babel_test_numeric_money_v8 as
select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money);
GO

create view babel_test_numeric_money_v9 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) >= a;
GO

create view babel_test_numeric_money_v10 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money);
GO

create view babel_test_numeric_money_v11 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) < a;
GO

create view babel_test_numeric_money_v12 as
select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money);
GO

create view babel_test_numeric_money_v13 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) <= a;
GO

create view babel_test_numeric_money_v14 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money);
GO

create view babel_test_numeric_money_v15 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(922337203685477.5807 as money) < a;
GO

create view babel_test_numeric_money_v16 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money);
GO

create view babel_test_numeric_money_v17 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a;
GO

create view babel_test_numeric_money_v18 as
select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(10 as money);
GO

create view babel_test_numeric_money_v19 as
select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(922337203685477.5807 as money);
GO

create view babel_test_numeric_money_v20 as
select count(*) from babel_test_numeric_money_vu_prepare where (a between cast(5 as money) and cast(99995 as money)) and a = cast(10 as money);
GO

create view babel_test_numeric_money_v21 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money) and a < cast(7 as money);
GO

create view babel_test_numeric_money_v22 as
select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a and cast(7 as money) > a;
GO

create view babel_test_numeric_money_v23 as
select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money);
GO

create view babel_test_numeric_money_v24 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money);
GO

create view babel_test_numeric_money_v25 as
select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money);
GO

create view babel_test_numeric_money_v26 as
select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money);
GO

create view babel_test_numeric_money_v27 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money);
GO

create view babel_test_numeric_money_v28 as
select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money);
GO

create view babel_test_numeric_money_v29 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money);
GO

create view babel_test_numeric_money_v30 as
select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money);
GO

-- Functions
create function babel_test_numeric_money_f0() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a = cast(1 as money)) end;
GO

create function babel_test_numeric_money_f00() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(1 as money) = a) end;
GO

create function babel_test_numeric_money_f1() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a IS NULL) end;
GO

create function babel_test_numeric_money_f2() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money)) end;
GO

create function babel_test_numeric_money_f3() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) <> a) end;
GO

create function babel_test_numeric_money_f4() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money)) end;
GO

create function babel_test_numeric_money_f5() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) > a) end;
GO

create function babel_test_numeric_money_f6() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money)) end;
GO

create function babel_test_numeric_money_f7() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(-922337203685477.5808 as money) > a) end;
GO

create function babel_test_numeric_money_f8() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money)) end;
GO

create function babel_test_numeric_money_f9() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) >= a) end;
GO

create function babel_test_numeric_money_f10() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money)) end;
GO

create function babel_test_numeric_money_f11() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) < a) end;
GO

create function babel_test_numeric_money_f12() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money)) end;
GO

create function babel_test_numeric_money_f13() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(99995 as money) <= a) end;
GO

create function babel_test_numeric_money_f14() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money)) end;
GO

create function babel_test_numeric_money_f15() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(922337203685477.5807 as money) < a) end;
GO

create function babel_test_numeric_money_f16() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money)) end;
GO

create function babel_test_numeric_money_f17() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a) end;
GO

create function babel_test_numeric_money_f18() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(10 as money)) end;
GO

create function babel_test_numeric_money_f19() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a between cast(5 as money) and cast(922337203685477.5807 as money)) end;
GO

create function babel_test_numeric_money_f20() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where (a between cast(5 as money) and cast(99995 as money)) and a = cast(10 as money)) end;
GO

create function babel_test_numeric_money_f21() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money) and a < cast(7 as money)) end;
GO

create function babel_test_numeric_money_f22() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where cast(5 as money) < a and cast(7 as money) > a) end;
GO

create function babel_test_numeric_money_f23() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a <> cast(5 as money)) end;
GO

create function babel_test_numeric_money_f24() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a < cast(5 as money)) end;
GO

create function babel_test_numeric_money_f25() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a < cast(-922337203685477.5808 as money)) end;
GO

create function babel_test_numeric_money_f26() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a <= cast(5 as money)) end;
GO

create function babel_test_numeric_money_f27() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(99995 as money)) end;
GO

create function babel_test_numeric_money_f28() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a >= cast(99995 as money)) end;
GO

create function babel_test_numeric_money_f29() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(922337203685477.5807 as money)) end;
GO

create function babel_test_numeric_money_f30() returns int as
begin return (select count(*) from babel_test_numeric_money_vu_prepare where a > cast(5 as money)) end;
GO

