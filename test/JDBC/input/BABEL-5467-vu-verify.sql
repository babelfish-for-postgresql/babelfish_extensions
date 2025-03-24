-- Client Tests
select count_avg = avg(convert(decimal(38,6), 10) + (convert(decimal(38,6), 2)/convert(decimal(38,6), 3)))
 , count_val = avg(cast(18 as decimal)) 
into babel_5467_avgdata_1
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_1
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6))
from babel_5467_avgdata_1
go

select count_avg = avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3)))
 ,count_val = avg(cast(18 as decimal))
into babel_5467_avgdata_2
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_2
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6))
from babel_5467_avgdata_2
go

create table babel_5467_avgdata_3_setup ( CountData int )
insert into babel_5467_avgdata_3_setup (CountData) values (10), (11), (11)
go

select avg(convert(decimal, CountData)) as count_avg
 ,avg(cast(18 as decimal)) as count_val 
into babel_5467_avgdata_3 
from babel_5467_avgdata_3_setup
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_3
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6)) 
from babel_5467_avgdata_3
go

-- constant expression
select cast(((cast(18 as decimal) - cast(10.666666 as decimal(38,6)))/cast(10.666666 as decimal(38,6)))*100 as decimal(38,6))
go

select convert(decimal(38,6), 32)/convert(decimal(38,6), 3)
go

select avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3)))
go

select count_avg = avg(convert(decimal(38,6), 10) + (convert(decimal(38,6), 2)/convert(decimal(38,6), 3))) 
 ,count_val = avg(cast(18 as decimal))
go

select count_avg = avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3))) 
 ,count_val = avg(cast(18 as decimal))
go

SELECT a = 10.12345678, b = 10.0/3.0, c = cast(10.2345 as decimal(38,6)) 
 , d = (cast(32 as decimal(38,6)) / cast(3 as decimal(38,6))), e = avg(10.0/3.0) 
 , f = avg(cast(10.2345 as decimal(38,6))) 
 into babel_5467_t1
go

-- Precision and scale details should be stored correctly
select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_1' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_2' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_3' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_t1' order by COLUMN_NAME
go

-- tables with computed columns having expression which results in numeric
create table babel_5467_t2(a decimal(38,6), b decimal(38,6), c as a / b, d as a * b)
insert into babel_5467_t2 values(32,3)
insert into babel_5467_t2 values(10.666666, 10.666666)
go

select * from babel_5467_t2
go

-- non-constant expression
select c = (a/b), d = (a*b) into babel_5467_t3 from babel_5467_t2
go
select * from babel_5467_t3
go

-- tables with check constraints having expression which results in numeric
create table babel_5467_t6(a decimal(38,6), b decimal(38,6), CHECK (a/b = 10.666666))
go

create table babel_5467_t7(a decimal(38,6), b decimal(38,6), CHECK (a * b = 113.777764))
go

insert into babel_5467_t6 values(32, 3)
go

insert into babel_5467_t7 values(10.666666, 10.666666)
go

select * from babel_5467_t6
go

select * from babel_5467_t7
go


-- Tests with numeric expressions in where clause where with and without truncation results in different behaviour
create table babel_5467_t9(a decimal(38,6), b decimal(38,6))
go

insert into babel_5467_t9 values(32, 3), (10.666666, 10.666666)
go

select * from babel_5467_t9 where a/b = 10.666666
go

select * from babel_5467_t9 where a/b = 32.0/3.0
go

select * from babel_5467_t9 where a*b = 113.777764
go

select * from babel_5467_t9 where a*b = 10.666666*10.666666
go


-- tests when result precision and scale is adjusted as precision value becomes more than MAX_PRECISION_VALUE which is 38
-- -- result precision and scale such as (precision - scale > 38 && scale <= 6)
-- -- -- initial precision = 46, scale = 6
select (cast(32 as decimal(38,1)) / cast(3 as decimal(4,3))) as a, 
        cast(32.123 as decimal(38,3)) * cast(3.12 as decimal(38,2)) as b, 
        cast(32.2222 as decimal(38,4)) + cast(3.11111 as decimal(38,5)) as c,
        cast(32.2222 as decimal(38,4)) - cast(3.11111 as decimal(38,5)) as d 
into babel_5467_t8
go

select * from babel_5467_t8
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_t8' order by COLUMN_NAME
go

-- Testing on UDT
CREATE TYPE DECIMALUDT_38_6 FROM decimal(38,6)
GO

CREATE TYPE DECIMALUDT FROM decimal
GO

select count_avg = avg(convert(DECIMALUDT_38_6, 10) + (convert(DECIMALUDT_38_6, 2)/convert(DECIMALUDT_38_6, 3)))
 , count_val = avg(cast(18 as DECIMALUDT)) 
into babel_5467_avgdata_udt_1
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_1
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT_38_6)
from babel_5467_avgdata_udt_1
go

select count_avg = avg((convert(DECIMALUDT_38_6, 32)/convert(DECIMALUDT_38_6, 3)))
 ,count_val = avg(cast(18 as DECIMALUDT))
into babel_5467_avgdata_udt_2
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_2
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT_38_6)
from babel_5467_avgdata_udt_2
go

select avg(convert(DECIMALUDT, CountData)) as count_avg
 ,avg(cast(18 as DECIMALUDT)) as count_val 
into babel_5467_avgdata_udt_3 
from babel_5467_avgdata_3_setup
go

select cast(count_avg as DECIMALUDT), cast(count_val as DECIMALUDT)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_3
go

select cast(count_avg as DECIMALUDT), cast(count_val as DECIMALUDT)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT) 
from babel_5467_avgdata_udt_3
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_udt_3' order by COLUMN_NAME
go

-- Tests for aggregates
create table babel_5467_t4(a decimal(10,2), b decimal(15, 6), c decimal(8, 5))
go

insert into babel_5467_t4 values(12345678.12, 123456789.666666, 123.66666), (11111111.33, 123456789.666666, 321.444444)
go

select avg(a) as p, avg(b) as q, avg(c) as r, avg(a+c) as s into babel_5467_avgdata_4 from babel_5467_t4
go

select min(a) as p, min(b) as q, min(c) as r, min(a+c) as s into babel_5467_avgdata_5 from babel_5467_t4
go

select max(a) as p, max(b) as q, max(c) as r, max(a+c) as s into babel_5467_avgdata_6 from babel_5467_t4
go

select sum(a) as p, sum(b) as q, sum(c) as r, sum(a+c) as s into babel_5467_avgdata_7 from babel_5467_t4
go

select count(a) as p, count(b) as q, count(c) as r, count(a+c) as s into babel_5467_avgdata_8 from babel_5467_t4
go

select * from babel_5467_avgdata_4
go

select * from babel_5467_avgdata_5
go

select * from babel_5467_avgdata_6
go

select * from babel_5467_avgdata_7
go

select * from babel_5467_avgdata_8
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_4' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_5' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_6' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_7' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_8' order by COLUMN_NAME
go

CREATE TABLE babel_5467_t5 (id integer PRIMARY KEY, amount decimal(38,6));
GO

INSERT INTO babel_5467_t5 VALUES (1, 10);
INSERT INTO babel_5467_t5 VALUES (2, 11);
INSERT INTO babel_5467_t5 VALUES (3, 11);
GO

SELECT count(*), avg(amount) FROM babel_5467_t5;
GO

SELECT count(*), avg(amount) + 100 FROM babel_5467_t5;
GO

SELECT count(*), avg(amount) - 100 FROM babel_5467_t5;
GO

SELECT count(*), avg(amount) * 100 FROM babel_5467_t5;
GO

SELECT count(*), avg(amount) / 100 FROM babel_5467_t5;
GO

SELECT count(*), avg(amount) % 100 FROM babel_5467_t5;
GO

SELECT ((avg(cast(18 as decimal)) - avg(amount))/avg(amount))*100 FROM babel_5467_t5;
GO

-- Tests aggregates with local variables
declare @a decimal(10,2) = 12345678.12, @b decimal(15, 6) = 123456789.666666, @c decimal(8, 5) = 123.66666;
select avg(@a) as p, avg(@b) as q, avg(@c) as r, avg(@a+@c) as s into babel_5467_avgdata_9
go

declare @a decimal(10,2) = 12345678.12, @b decimal(15, 6) = 123456789.666666, @c decimal(8, 5) = 123.66666;
select min(@a) as p, min(@b) as q, min(@c) as r, min(@a+@c) as s into babel_5467_avgdata_10
go

declare @a decimal(10,2) = 12345678.12, @b decimal(15, 6) = 123456789.666666, @c decimal(8, 5) = 123.66666;
select max(@a) as p, max(@b) as q, max(@c) as r, max(@a+@c) as s into babel_5467_avgdata_11
go

declare @a decimal(10,2) = 12345678.12, @b decimal(15, 6) = 123456789.666666, @c decimal(8, 5) = 123.66666;
select sum(@a) as p, sum(@b) as q, sum(@c) as r, sum(@a+@c) as s into babel_5467_avgdata_12
go

declare @a decimal(10,2) = 12345678.12, @b decimal(15, 6) = 123456789.666666, @c decimal(8, 5) = 123.66666;
select count(@a) as p, count(@b) as q, count(@c) as r, count(@a+@c) as s into babel_5467_avgdata_13
go

select * from babel_5467_avgdata_9
go

select * from babel_5467_avgdata_10
go

select * from babel_5467_avgdata_11
go

select * from babel_5467_avgdata_12
go

select * from babel_5467_avgdata_13
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_9' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_10' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_11' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_12' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_13' order by COLUMN_NAME
go

-- tests aggregates with group by clause
create table babel_5467_t12(id int, a decimal(38,6));
insert into babel_5467_t12 values(1, 10), (1, 11), (1, 11), (2, 2), (2, 2), (2, 1), (3, 10.666666), (3, 4.333333), (3, 1.000001);
go

select id, avg(a) as avg, sum(a) as sum, min(a) as min, max(a) as max, count(a) as count from babel_5467_t12 group by id order by id
go

-- tests for truncation/rounding of expressions
-- s = max(6, s1 + p2 + 1) = 45, p = p1 - s1 + s2 + max(6, s1 + p2 + 1) = 83 => s = 6, p = 38
-- truncation
select 32.0/3.0, cast(32 as decimal(38, 6)) / cast(3 as decimal(38, 6))
go

-- s = s1 + s2 = 12, p = p1 + p2 + 1 = 77 => s = 6, p = 38
-- rounding
select 10.666666*10.666666, cast(10.666666 as decimal(38, 6)) * cast(10.666666 as decimal(38, 6))
go

-- s = max(s1, s2) = 10, p = max(s1, s2) + max(p1 - s1, p2 - s2) + 1 = 40 => p = 38, s = 8
-- rounding
select cast(10.6666666666 as decimal(38, 10)) + cast(5.11111111 as decimal(38, 8))
go

-- s = max(s1, s2) = 10, p = max(s1, s2) + max(p1 - s1, p2 - s2) + 1 = 40 => p = 38, s = 8
-- rounding
select cast(10.6666666666 as decimal(38, 10)) - cast(5.11111111 as decimal(38, 8))
go

create table babel_5467_t10(a decimal(38,6));
insert into babel_5467_t10 values(20),(10),(2);
go

-- s = 6, p = 38
-- truncation
select avg(a) from babel_5467_t10
go


-- Combinations of arithmetic operations and aggregate functions
select (32.0/3.0)*10.666666, (cast(32 as decimal(38, 6)) / cast(3 as decimal(38, 6))) * cast(10.666666 as decimal(38, 6))
go

select ((32.0/3.0)*10.666666) + 10.22, ((cast(32 as decimal(38, 6)) / cast(3 as decimal(38, 6))) * cast(10.666666 as decimal(38, 6))) + cast(10.22 as decimal(38, 2))
go

create table babel_5467_t11(a decimal(38,6), b decimal(38,6), c decimal(38,6), d decimal(38,2));
insert into babel_5467_t11 values(32,3,10.666666,10.22), (5,3,1.666666,1.22), (7,3,2.333333,2.22)
go

select (((a / b) * c) + d), ((a / b) * c), (a / b) from babel_5467_t11
go

select avg(((a / b) * c) + d), avg((a / b) * c), avg(a / b) from babel_5467_t11
go

-- Tests with other Mathematical functions which returns numeric/decimal type
select abs(99999999999999999999.12) * cast(1.23 as numeric(3,2)) 
go 

select CEILING(99999999999999999999.12) * cast(1.23 as numeric(3,2)) 
go

select degrees(cast((PI() * 99999999999999) as decimal(18,2))) * cast(1.23 as numeric(3,2)) 
go

select FLOOR(99999999999999999999.12) * cast(1.23 as numeric(3,2)) 
go

select POWER(99999999999999999999.12, 1) * cast(1.23 as numeric(3,2)) 
go

select RADIANS(99999999999999999999.12) * cast(1.23 as numeric(3,2)) 
go

select ROUND(99999999999999999999.12, 2) * cast(1.23 as numeric(3,2)) 
go

-- Test with UDT on DECIMAL/NUMERIC
CREATE TYPE dbo.NUMERICUDT_38_4 FROM numeric(38,4)
GO

CREATE TYPE dbo.DECIMALUDT_38_4 FROM decimal(38,4)
GO

SELECT cast(999999999999999.9999 as dbo.NUMERICUDT_38_4) * cast(1.23 as decimal(3,2))
GO

SELECT cast(999999999999999.9999 as dbo.DECIMALUDT_38_4) * cast(1.23 as decimal(3,2))
GO

-- numeric subtraction overflow
SELECT CAST(9999999999999999999999999999999999999 AS NUMERIC(38,0)) - CAST(0.0000000000000000000000000000000000001 AS NUMERIC(38,37)) AS result;
GO

-- numeric addition overflow
SELECT CAST(111.111111 as numeric(38,6)) + CAST(111.11111111 as numeric(38, 8))
GO

-- numeric multiplication overflow
create table babel_5467_t13(a numeric (38, 37));
insert into babel_5467_t13 values (6);
go

select sum(a) * CAST(10.00 AS NUMERIC(38,0)) from babel_5467_t13
go

-- cleanup
drop table babel_5467_avgdata_1
drop table babel_5467_avgdata_2
drop table babel_5467_avgdata_udt_1
drop table babel_5467_avgdata_udt_2
drop table babel_5467_avgdata_udt_3
drop table babel_5467_avgdata_3_setup
drop table babel_5467_avgdata_3
drop table babel_5467_avgdata_4
drop table babel_5467_avgdata_5
drop table babel_5467_avgdata_6
drop table babel_5467_avgdata_7
drop table babel_5467_avgdata_8
drop table babel_5467_avgdata_9
drop table babel_5467_avgdata_10
drop table babel_5467_avgdata_11
drop table babel_5467_avgdata_12
drop table babel_5467_avgdata_13
drop table babel_5467_t1
drop table babel_5467_t2
drop table babel_5467_t3
drop table babel_5467_t4
drop table babel_5467_t5
drop table babel_5467_t6
drop table babel_5467_t7
drop table babel_5467_t8
drop table babel_5467_t9
drop table babel_5467_t10
drop table babel_5467_t11
drop table babel_5467_t12
drop table babel_5467_t13
go

drop type DECIMALUDT_38_6
drop type DECIMALUDT
drop type dbo.NUMERICUDT_38_4
drop type dbo.DECIMALUDT_38_4
GO
