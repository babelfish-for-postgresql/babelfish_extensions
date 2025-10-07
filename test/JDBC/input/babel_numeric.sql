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

create table BABEL_6081_t1(id int, value decimal(15,2))
go

insert into BABEL_6081_t1 values(1,2.5),(1,3.5),(1,4.5),(2,1.5),(2,2.5)
go

select
    avg(value) as avgValue,
    avg(value) * 1.0 as avgValueMul,
    avg(value) / 1.0 as avgValueDiv
into avg_t from BABEL_6081_t1 group by id
go

select COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE from information_schema.columns where table_name = 'avg_t';
go

drop table BABEL_6081_t1
go

drop table avg_t
go

CREATE TABLE decimal_test (
    id INT,
    value1 DECIMAL(10,2),
    value2 DECIMAL(15,4),
    category INT
)
GO

INSERT INTO decimal_test VALUES
(1, 123.45, 123.4567, 1),
(1, 234.56, 234.5678, 1),
(2, 345.67, 345.6789, 2),
(2, 456.78, 456.7890, 2),
(3, 567.89, 567.8901, 1)
GO

SELECT
    AVG(value1) as avg_value1,
    AVG(value2) as avg_value2,
    AVG(value1) * 1.000 as avg_value1_mul
INTO avg_results
FROM decimal_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('avg_results')
ORDER BY COLUMN_NAME;
GO

SELECT
    SUM(value1) as sum_value1,
    SUM(value2) as sum_value2,
    SUM(value2) / 1.0000 as sum_value2_div
INTO sum_results
FROM decimal_test
GROUP BY category
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('sum_results')
ORDER BY COLUMN_NAME;
GO

SELECT
    SUM(value1 * value2) as product_sum,
    AVG(value1 * value2) as product_avg,
    SUM(value1) * SUM(value2) / 1.0000 as product_sum_div
INTO calc_results
FROM decimal_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('calc_results')
ORDER BY COLUMN_NAME;
GO

CREATE TABLE numeric_test (
    id INT,
    num1 NUMERIC(12,4),
    num2 NUMERIC(16,6)
)
GO

INSERT INTO numeric_test VALUES
(1, 1234.5678, 1234.567890),
(1, 2345.6789, 2345.678901),
(2, 3456.7890, 3456.789012),
(2, 4567.8901, 4567.890123)
GO

SELECT 
    SUM(num1) as sum_num1,
    SUM(num2) as sum_num2,
    AVG(num1) as avg_num1,
    AVG(num2) as avg_num2,
    SUM(num2) * AVG(num1) as sum_num2_div
INTO numeric_results
FROM numeric_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('numeric_results')
ORDER BY COLUMN_NAME;
GO

SELECT
    MAX(value1) - MIN(value1) as value1_range,
    MAX(value2) - MIN(value2) as value2_range,
    MAX(value2) * MIN(value2) as value2_product
INTO range_results
FROM decimal_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('range_results')
ORDER BY COLUMN_NAME;
GO

SELECT
    SUM(value1)/COUNT(*) as manual_avg1,
    AVG(value1) as builtin_avg1,
    SUM(value2)/COUNT(*) as manual_avg2,
    AVG(value2) as builtin_avg2
INTO precision_test
FROM decimal_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('precision_test')
ORDER BY COLUMN_NAME;
GO

SELECT
    COUNT(*) as count,
    SUM(value1) as sum1,
    AVG(value1) as avg1,
    MIN(value1) as min1,
    MAX(value1) as max1,
    COUNT(*) * AVG(value1) * 1.0000 as count_mul
INTO multi_agg_results
FROM decimal_test
GROUP BY category
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('multi_agg_results')
ORDER BY COLUMN_NAME;
GO

CREATE TABLE decimal_zero_test (
    id INT,
    value DECIMAL(10,2)
)
GO

INSERT INTO decimal_zero_test VALUES
(1, 0.00),
(1, 10.50),
(2, 0.00),
(2, 0.00)
GO

SELECT
    AVG(value) as avg_value,
    SUM(value) as sum_value
INTO zero_value_results
FROM decimal_zero_test
GROUP BY id
GO

select
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_PRECISION_RADIX,
    NUMERIC_SCALE
from information_schema.columns
where
table_name IN ('zero_value_results')
ORDER BY COLUMN_NAME;
GO

DROP TABLE decimal_test
GO

DROP TABLE numeric_test
GO

DROP TABLE decimal_zero_test
GO

DROP TABLE avg_results
GO

DROP TABLE sum_results
GO

DROP TABLE calc_results
GO

DROP TABLE numeric_results
GO

DROP TABLE range_results
GO

DROP TABLE precision_test
GO

DROP TABLE multi_agg_results
GO

DROP TABLE zero_value_results
GO

-- cx query
drop table if exists [testtable1];
GO

drop table if exists [testtable2];
GO

CREATE TABLE [dbo].[testtable1](
	[businessdate] [datetime] NULL,
	[transactionid] [bigint] NULL,
	[accountid] [int] NULL,
	[accountnumber] [varchar](50) NULL,
	[transactionamount] [money] NULL,
	[creditamount] [money] NULL,
	[transactiondescription] [varchar](500) NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[testtable2](
	[accountid] [int] NULL,
	[accountnumber] [varchar](50) NULL,
	[dba] [varchar](255) NULL,
	[isctrexempted] [bit] NULL,
	[openeddate] [datetime] NULL,
	[lastsareddate] [datetime] NULL,
	[isclosed] [bit] NULL,
	[closeddate] [datetime] NULL,
	[homephone] [varchar](50) NULL,
	[businessphone] [varchar](50) NULL,
	[accountstatusid] [int] NULL,
	[officerid] [int] NULL,
	[producttypeid] [int] NULL,
	[applicationid] [int] NULL,
	[bsariskid] [int] NULL,
	[bsaactivityid] [int] NULL,
	[mailhandlingid] [int] NULL,
	[branchid] [int] NULL,
	[businesstypeid] [int] NULL,
	[createddate] [datetime] NULL,
	[createdby] [int] NULL,
	[lastmodifieddate] [datetime] NULL,
	[lastmodifiedby] [int] NULL,
	[isentity] [bit] NULL,
	[ownertypecode] [varchar](5) NULL,
	[codemodifieddate] [datetime] NULL,
	[codecreateddate] [datetime] NULL,
	[analysisaccountcode] [varchar](50) NULL,
	[collateralcodeid] [int] NULL,
	[chargeoffdate] [datetime] NULL,
	[nextrenewaldate] [datetime] NULL,
	[cdloanterm] [varchar](100) NULL,
	[renewaldate] [datetime] NULL,
	[micraccountnumber] [varchar](50) NULL,
	[micrroutingnumber] [varchar](10) NULL
) ON [PRIMARY]
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-25T00:00:00.000' AS DateTime), 30000000001, 729, N'115', 1000.0000, 1000.0000, N'Recent Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-25T00:00:00.000' AS DateTime), 30000000002, 729, N'115', 1000.0000, 1000.0000, N'Recent Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-26T00:00:00.000' AS DateTime), 30000000003, 729, N'115', 1000.0000, 1000.0000, N'Recent Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-25T00:00:00.000' AS DateTime), 30000000004, 729, N'115', 1000.0000, 1000.0000, N'Recent Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-25T00:00:00.000' AS DateTime), 30000000005, 729, N'115', 1000.0000, 1000.0000, N'Recent Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000006, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000007, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000008, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000009, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000010, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000011, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000012, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000013, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000014, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000015, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000016, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000017, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000018, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000019, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000020, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000021, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000022, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000023, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000024, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000025, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000026, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000027, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000028, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000029, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000030, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000031, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable1] ([businessdate], [transactionid], [accountid], [accountnumber], [transactionamount], [creditamount], [transactiondescription]) VALUES (CAST(N'2016-01-11T00:00:00.000' AS DateTime), 30000000032, 729, N'115', 1000.0000, 1000.0000, N'History Week 1')
GO
INSERT [dbo].[testtable2] ([accountid], [accountnumber], [dba], [isctrexempted], [openeddate], [lastsareddate], [isclosed], [closeddate], [homephone], [businessphone], [accountstatusid], [officerid], [producttypeid], [applicationid], [bsariskid], [bsaactivityid], [mailhandlingid], [branchid], [businesstypeid], [createddate], [createdby], [lastmodifieddate], [lastmodifiedby], [isentity], [ownertypecode], [codemodifieddate], [codecreateddate], [analysisaccountcode], [collateralcodeid], [chargeoffdate], [nextrenewaldate], [cdloanterm], [renewaldate], [micraccountnumber], [micrroutingnumber]) VALUES (0, N'', N'', 0, CAST(N'1900-01-01T00:00:00.000' AS DateTime), CAST(N'1900-01-01T00:00:00.000' AS DateTime), 0, CAST(N'1900-01-01T00:00:00.000' AS DateTime), N'', N'', 0, 0, 0, 0, 0, 0, 0, 0, 0, CAST(N'2025-05-19T06:59:14.667' AS DateTime), 888, NULL, NULL, 0, N'', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[testtable2] ([accountid], [accountnumber], [dba], [isctrexempted], [openeddate], [lastsareddate], [isclosed], [closeddate], [homephone], [businessphone], [accountstatusid], [officerid], [producttypeid], [applicationid], [bsariskid], [bsaactivityid], [mailhandlingid], [branchid], [businesstypeid], [createddate], [createdby], [lastmodifieddate], [lastmodifiedby], [isentity], [ownertypecode], [codemodifieddate], [codecreateddate], [analysisaccountcode], [collateralcodeid], [chargeoffdate], [nextrenewaldate], [cdloanterm], [renewaldate], [micraccountnumber], [micrroutingnumber]) VALUES (729, N'115', N'', 0, CAST(N'2015-11-04T00:00:00.000' AS DateTime), NULL, 0, NULL, N'', N'', 0, 0, 2, 1376, 0, 0, 0, 231, 0, CAST(N'2025-05-19T16:51:41.483' AS DateTime), 0, NULL, NULL, 0, N'', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[testtable2] ([accountid], [accountnumber], [dba], [isctrexempted], [openeddate], [lastsareddate], [isclosed], [closeddate], [homephone], [businessphone], [accountstatusid], [officerid], [producttypeid], [applicationid], [bsariskid], [bsaactivityid], [mailhandlingid], [branchid], [businesstypeid], [createddate], [createdby], [lastmodifieddate], [lastmodifiedby], [isentity], [ownertypecode], [codemodifieddate], [codecreateddate], [analysisaccountcode], [collateralcodeid], [chargeoffdate], [nextrenewaldate], [cdloanterm], [renewaldate], [micraccountnumber], [micrroutingnumber]) VALUES (730, N'105', N'', 0, CAST(N'2015-11-05T00:00:00.000' AS DateTime), NULL, 0, NULL, N'', N'', 0, 0, 2, 1376, 0, 0, 0, 231, 0, CAST(N'2025-05-19T16:51:41.723' AS DateTime), 0, NULL, NULL, 0, N'', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[testtable2] ([accountid], [accountnumber], [dba], [isctrexempted], [openeddate], [lastsareddate], [isclosed], [closeddate], [homephone], [businessphone], [accountstatusid], [officerid], [producttypeid], [applicationid], [bsariskid], [bsaactivityid], [mailhandlingid], [branchid], [businesstypeid], [createddate], [createdby], [lastmodifieddate], [lastmodifiedby], [isentity], [ownertypecode], [codemodifieddate], [codecreateddate], [analysisaccountcode], [collateralcodeid], [chargeoffdate], [nextrenewaldate], [cdloanterm], [renewaldate], [micraccountnumber], [micrroutingnumber]) VALUES (731, N'106', N'', 0, CAST(N'2015-11-06T00:00:00.000' AS DateTime), NULL, 0, CAST(N'2016-02-03T00:00:00.000' AS DateTime), N'', N'', 0, 0, 2, 1376, 0, 0, 0, 231, 0, CAST(N'2025-05-19T16:51:41.960' AS DateTime), 0, NULL, NULL, 0, N'', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
DECLARE @runDate DATETIME;
DECLARE @FirstDayOfWeekBeforeRunDate DATETIME; 
DECLARE @LastDayOfHistoryRange DATETIME;
DECLARE @LastDayOfReviewedRange DATETIME;

DECLARE @PercentageActivityDecreased DECIMAL(15, 2);
DECLARE @MinimumNumberOfTransactionsPerWeek MONEY;
DECLARE @NumberOfWeeksToCheck INT;
DECLARE @NumberOfWeeksOfHistory INT;

SET @runDate = '2/3/2016';
SET @PercentageActivityDecreased = 50*-1;
SET @NumberOfWeeksToCheck = 2
SET @NumberOfWeeksOfHistory = 3;
SET @MinimumNumberOfTransactionsPerWeek = 2;
SET @FirstDayOfWeekBeforeRunDate = 1
SET @LastDayOfReviewedRange = DATEADD(Day,@NumberOfWeeksToCheck*-7,@FirstDayOfWeekBeforeRunDate)
SET @LastDayOfHistoryRange = DATEADD(Day,(@NumberOfWeeksOfHistory+@NumberOfWeeksToCheck)*-7,@FirstDayOfWeekBeforeRunDate)
 

 SELECT 
    ct.AccountID, ct.AccountNumber, @NumberOfWeeksOfHistory ,COUNT(1),@NumberOfWeeksOfHistory,
	(count(1)/(@NumberOfWeeksOfHistory * 1.0  )) as TransactionCountAvg --(COUNT(1) /( @NumberOfWeeksOfHistory * cast(1.0 as float) ))-- ,   (COUNT(1)/(@NumberOfWeeksOfHistory * 1.0 )) as TransactionCountAvg
    FROM 
    [testtable1] ct
	INNER JOIN [testtable2] accounts
	ON ct.AccountID = accounts.accountid
	AND COALESCE(accounts.ClosedDate, @RunDate) >= @RunDate
    GROUP BY 
    ct.AccountID, ct.AccountNumber
HAVING (COUNT(1)/(@NumberOfWeeksOfHistory * cast(1.0 as float))) >= @MinimumNumberOfTransactionsPerWeek
GO

drop table if exists [testtable1];
GO

drop table if exists [testtable2];
GO

CREATE TYPE BABEL_6081_int FROM INT;
GO

CREATE TYPE BABEL_6081_numeric FROM NUMERIC(4, 2);
GO

CREATE TABLE BABEL_6081_t2 (id NUMERIC(4, 2));
GO
INSERT INTO BABEL_6081_t2 VALUES (1.0)
GO

WITH 
cte1 AS ( 
    SELECT id, CAST(id AS INT) AS int_id 
    FROM BABEL_6081_t2 
), 
cte2 AS ( 
    SELECT DISTINCT int_id 
    FROM cte1 
) 
SELECT 
    c1.id * avg(c2.int_id) AS product 
    INTO 
        BABEL_6081_t3 
FROM cte1 c1 
JOIN cte2 c2 ON c1.int_id = c2.int_id 
GROUP BY c1.id; 
GO

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE 
from information_schema.columns 
where TABLE_NAME = 'BABEL_6081_t3' order by COLUMN_NAME
GO

WITH 
cte1 AS ( 
    SELECT id, CAST(id AS BABEL_6081_int) AS int_id 
    FROM BABEL_6081_t2 
), 
cte2 AS ( 
    SELECT DISTINCT int_id 
    FROM cte1 
) 
SELECT 
    c1.id * avg(c2.int_id) AS product 
    INTO 
        BABEL_6081_t4 
FROM cte1 c1 
JOIN cte2 c2 ON c1.int_id = c2.int_id 
GROUP BY c1.id; 
GO

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE 
from information_schema.columns 
where TABLE_NAME = 'BABEL_6081_t4' order by COLUMN_NAME
GO

WITH 
cte1 AS ( 
    SELECT id, CAST(id AS BABEL_6081_numeric) AS int_id 
    FROM BABEL_6081_t2 
), 
cte2 AS ( 
    SELECT DISTINCT int_id 
    FROM cte1 
) 
SELECT 
    c1.id * avg(c2.int_id) AS product 
    INTO 
        BABEL_6081_t5 
FROM cte1 c1 
JOIN cte2 c2 ON c1.int_id = c2.int_id 
GROUP BY c1.id; 
GO

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'BABEL_6081_t5' order by COLUMN_NAME
GO

WITH 
cte1 AS ( 
    SELECT id, CAST(id AS INT) AS int_id 
    FROM BABEL_6081_t2 
), 
cte2 AS ( 
    SELECT DISTINCT int_id 
    FROM cte1 
) 
SELECT 
    c1.id, 
    c1.id * avg(c2.int_id) AS product 
INTO 
    BABEL_6081_t6 
FROM cte1 c1 
JOIN cte2 c2 ON c1.int_id = c2.int_id 
GROUP BY c1.id; 
GO

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE 
from information_schema.columns 
where TABLE_NAME = 'BABEL_6081_t6' order by COLUMN_NAME
GO

DROP TABLE BABEL_6081_t2
GO

DROP TABLE BABEL_6081_t3
GO

DROP TABLE BABEL_6081_t4
GO

DROP TABLE BABEL_6081_t5
GO

DROP TABLE BABEL_6081_t6
GO

DROP TYPE BABEL_6081_int;
GO

DROP TYPE BABEL_6081_numeric;
GO
