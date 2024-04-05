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
create view test_int_numeric_v1 as
select count(*) from test_int_numeric_vu where a IS NULL;
GO

-- seq scan
create view test_int_numeric_v2 as
select count(*) from test_int_numeric_vu where a <> 5.0;
GO

create view test_int_numeric_v3 as
select count(*) from test_int_numeric_vu where 5.0 <> a;
GO

-- index scan on < and >
create view test_int_numeric_v4 as
select count(*) from test_int_numeric_vu where a < 5.0;
GO

create view test_int_numeric_v5 as
select count(*) from test_int_numeric_vu where 5.0 > a;
GO

create view test_int_numeric_v6 as
select count(*) from test_int_numeric_vu where a < -2147483648.0;
GO

create view test_int_numeric_v7 as
select count(*) from test_int_numeric_vu where -2147483648.0 > a;
GO

create view test_int_numeric_v8 as
select count(*) from test_int_numeric_vu where a <= 5.0;
GO

create view test_int_numeric_v9 as
select count(*) from test_int_numeric_vu where 5.0 >= a;
GO

create view test_int_numeric_v10 as
select count(*) from test_int_numeric_vu where a > 999995.0;
GO

create view test_int_numeric_v11 as
select count(*) from test_int_numeric_vu where 999995.0 < a;
GO

create view test_int_numeric_v12 as
select count(*) from test_int_numeric_vu where a >= 999995.0;
GO

create view test_int_numeric_v13 as
select count(*) from test_int_numeric_vu where 999995.0 <= a;
GO

create view test_int_numeric_v14 as
select count(*) from test_int_numeric_vu where a > 2147483647.0;
go

create view test_int_numeric_v15 as
select count(*) from test_int_numeric_vu where 2147483647.0 < a;
go

-- seq scan on < and >
create view test_int_numeric_v16 as
select count(*) from test_int_numeric_vu where a > 5.0;
GO

create view test_int_numeric_v17 as
select count(*) from test_int_numeric_vu where 5.0 < a;
GO

-- index scan for BETWEEN
create view test_int_numeric_v18 as
select count(*) from test_int_numeric_vu where a between 5.0 and 10.0;
GO

-- seq scan for BETWEEN
create view test_int_numeric_v19 as
select count(*) from test_int_numeric_vu where a between 5.0 and 999999.0;
GO

-- mix of int op numeric and int op int
create view test_int_numeric_v20 as
select count(*) from test_int_numeric_vu where (a between 5.0 and 999999.0) and a = 10;
GO

create view test_int_numeric_v21 as
select count(*) from test_int_numeric_vu where a > 5.0 and a < 7;
Go

create view test_int_numeric_v22 as
select count(*) from test_int_numeric_vu where 5.0 < a and 7 > a;
Go

-- shouldn't be any regression on int op int operators

-- seq scan
create view test_int_numeric_v23 as
select count(*) from test_int_numeric_vu where a <> 5;
GO

-- index scan on < and >
create view test_int_numeric_v24 as
select count(*) from test_int_numeric_vu where a < 5;
GO

create view test_int_numeric_v25 as
select count(*) from test_int_numeric_vu where a < -2147483648;
GO

create view test_int_numeric_v26 as
select count(*) from test_int_numeric_vu where a <= 5;
GO

create view test_int_numeric_v27 as
select count(*) from test_int_numeric_vu where a > 999995;
GO

create view test_int_numeric_v28 as
select count(*) from test_int_numeric_vu where a >= 999995;
GO

create view test_int_numeric_v29 as
select count(*) from test_int_numeric_vu where a > 2147483647;
go

-- seq scan on < and >
create view test_int_numeric_v30 as
select count(*) from test_int_numeric_vu where a > 5;
GO

-- index scan for BETWEEN
create view test_int_numeric_v31 as
select count(*) from test_int_numeric_vu where a between 5 and 10;
GO

-- seq scan for BETWEEN
create view test_int_numeric_v32 as
select count(*) from test_int_numeric_vu where a between 5 and 999999;
GO
