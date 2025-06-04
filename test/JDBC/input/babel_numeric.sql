-- Test numeric in cast function
select cast(1.123 as numeric(38, 10));
go
select cast(1.123 as numeric(39, 10));
go

-- Test decimal in cast function
select cast(1.123 as decimal(38, 10));
go
select cast(1.123 as decimal(39, 10));
go

-- Test dec in cast function
select cast(1.123 as dec(38, 10));
go
select cast(1.123 as dec(39, 10));
go

-- Test numeric in create table
create table t1 (col numeric(38,37));
drop table t1;
go

create table t1 (col numeric(39, 37));
go

-- Test decimal in create table
create table t1 (col decimal(38,37));
drop table t1;
go

create table t1 (col decimal(39, 37));
go

-- Test dec in create table
create table t1 (col decimal(38,37));
drop table t1;
go

create table t1 (col decimal(39, 37));
go

-- Test default precision and scale is set to 18, 0
create table t1 (col numeric);
insert into t1 values (1.2);
insert into t1 values (123456789012345678);
select * from t1;
go
insert into t1 values (1234567890123456789);
select * from t1;
go

drop table t1;
go

-- Test default scale is set to 0 if only precision is specified
create table t1 (col numeric(4));
insert into t1 values (1.2);
select * from t1;
go

drop table t1;
go

select * from 
(
    select cast(1.23 as decimal(18,2)) as col
    union all
    select cast(1.23 as decimal(7,2)) as col
) dummy order by col;
go

select * from 
(
    select cast(NULL as decimal(18,2)) as col
    union all
    select cast(1.23 as decimal(7,2)) as col
) dummy order by col;
go

select * from 
(
    select cast(9999999999999999.99 as decimal(18,2)) as col
    union all
    select cast(99999.99 as decimal(7,2)) as col
) dummy order by col;
go

create type decimal_18_2 from decimal(18,2);
go

create type decimal_7_2 from decimal(7,2);
go

select * from 
(
    select cast(1.23 as decimal_18_2) as col
    union all
    select cast(1.23 as decimal_7_2) as col
) dummy order by col;
go

select * from 
(
    select cast(1.23 as decimal_18_2) as col
    union all
    select cast(NULL as decimal_7_2) as col
) dummy order by col;
go

select * from 
(
    select cast(9999999999999999.99 as decimal_18_2) as col
    union all
    select cast(99999.99 as decimal_7_2) as col
) dummy order by col;
go

create table babel_5086_t1 (a decimal(18,2), b decimal(7,2), c decimal_18_2, d decimal_7_2);
go

insert into babel_5086_t1 values (1.23, 1.23, 1.23, 1.23);
insert into babel_5086_t1 values (9999999999999999.99, NULL, 9999999999999999.99, NULL);
insert into babel_5086_t1 values (NULL, 99999.99, NULL, 99999.99);
go

select * from 
(
    select a as col from babel_5086_t1
    union all
    select b as col from babel_5086_t1
) dummy order by col;
go

select * from 
(
    select c as col from babel_5086_t1
    union all
    select d as col from babel_5086_t1
) dummy order by col;
go

select * from 
(
    select a as col from babel_5086_t1
    union all
    select b as col from babel_5086_t1
    union all
    select c as col from babel_5086_t1
    union all
    select d as col from babel_5086_t1
) dummy order by col;
go

select * from 
(
    select a as col from babel_5086_t1
    union all
    select c as col from babel_5086_t1
) dummy order by col;
go

select * from 
(
    select b as col from babel_5086_t1
    union all
    select d as col from babel_5086_t1
) dummy order by col;
go

create type numeric_18_2 from numeric(18,2);
go

create type numeric_7_2 from numeric(7,2);
go

select * from 
(
    select cast(1.23 as numeric_18_2) as col
    union all
    select cast(1.23 as numeric_7_2) as col
) dummy order by col;
go

select * from 
(
    select cast(12344.234 as numeric_18_2) as col
    union all
    select cast(1.23 as numeric_7_2) as col
) dummy order by col;
go

create table babel_5086_t2 (a numeric(18,2), b numeric(7,2), c numeric_18_2, d numeric_7_2);
go

insert into babel_5086_t2 values (1.23, 1.23, 1.23, 1.23);
insert into babel_5086_t2 values (9999999999999999.99, NULL, 9999999999999999.99, NULL);
insert into babel_5086_t2 values (NULL, 99999.99, NULL, 99999.99);
go

select * from 
(
    select a as col from babel_5086_t2 
    union all
    select b as col from babel_5086_t2
) dummy order by col;
go

select * from 
(
    select c as col from babel_5086_t2
    union all
    select d as col from babel_5086_t2
) dummy order by col;
go

select * from 
(
    select a as col from babel_5086_t2
    union all
    select b as col from babel_5086_t2
    union all
    select c as col from babel_5086_t2
    union all
    select d as col from babel_5086_t2
) dummy order by col;
go

select * from 
(
    select a as col from babel_5086_t2
    union all
    select c as col from babel_5086_t2
) dummy order by col;
go


select * from 
(
    select b as col from babel_5086_t2
    union all
    select d as col from babel_5086_t2
) dummy order by col;
go

drop  table babel_5086_t1;
go

drop  table babel_5086_t2;
go

drop type decimal_18_2;
drop type decimal_7_2;
drop type numeric_18_2;
drop type numeric_7_2;
go

CREATE TABLE agg_test_table (a NUMERIC(38, 10), b NUMERIC(38, 37));
GO

INSERT INTO agg_test_table VALUES (1.1234567890, 1.1234567890);
GO

INSERT INTO agg_test_table VALUES (8.8765434567, 8.1234634);
GO

INSERT INTO agg_test_table VALUES (9.5678, 1);
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT(*) / 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) / 1 FROM agg_test_table
GO

SELECT COUNT(*) FROM agg_test_table
GO

SELECT COUNT_BIG(*) FROM agg_test_table
GO

-- FIX ME: Will be fixed by BABEL-5880.
SELECT COUNT_BIG(NULL) * 1.00 FROM agg_test_table 
UNION 
SELECT 2.00 
GO

SELECT COUNT_BIG(NULL) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(NULL) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(NULL) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(NULL) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(NULL) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(NULL)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(NULL)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(NULL)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(NULL)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(NULL) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(NULL) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT COUNT(NULL) * 1.00 FROM agg_test_table
GO

SELECT COUNT(NULL) / 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(NULL) * 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(NULL) / 1 FROM agg_test_table
GO

SELECT COUNT(NULL) FROM agg_test_table
GO

SELECT COUNT_BIG(NULL) FROM agg_test_table
GO

DROP TABLE agg_test_table;
GO

CREATE TABLE agg_test_table (a MONEY, b SMALLMONEY);
GO

INSERT INTO agg_test_table VALUES (1.1234567890, 1.1234567890);
GO

INSERT INTO agg_test_table VALUES (8.8765434567, 8.1234634);
GO

INSERT INTO agg_test_table VALUES (9.5678, 1);
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT(*) / 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) / 1 FROM agg_test_table
GO

SELECT COUNT(*) FROM agg_test_table
GO

SELECT COUNT_BIG(*) FROM agg_test_table
GO

DROP TABLE agg_test_table;
GO

create type numeric_18_2 from numeric(18,2);
go

create type numeric_7_2 from numeric(7,2);
go

CREATE TABLE agg_test_table (a numeric_18_2, b numeric_7_2);
GO

INSERT INTO agg_test_table VALUES (1.1234567890, 1.1234567890);
GO

INSERT INTO agg_test_table VALUES (8.8765434567, 8.1234634);
GO

INSERT INTO agg_test_table VALUES (9.5678, 1);
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT_BIG(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) + 1.00 FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT COUNT(*) FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*)
    ELSE 2.00
END * 1.00
FROM agg_test_table
UNION
SELECT 2.00
GO

SELECT CASE 1
    WHEN 1 THEN COUNT(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT CASE 1
    WHEN 1 THEN COUNT_BIG(*) * 1.00
    ELSE 2.00
END
FROM agg_test_table
GO

SELECT COUNT(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT(*) / 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) * 1.00 FROM agg_test_table
GO

SELECT COUNT_BIG(*) / 1 FROM agg_test_table
GO

SELECT COUNT(*) FROM agg_test_table
GO

SELECT COUNT_BIG(*) FROM agg_test_table
GO

DROP TABLE agg_test_table;
GO

DROP TYPE numeric_18_2;
GO

drop TYPE numeric_7_2;
GO
