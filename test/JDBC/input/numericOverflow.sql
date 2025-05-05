-- Numeric testcase for precision overflow triggers known protocol violation
CREATE TABLE overflow_test (amount numeric(38, 0));
go

-- sum(38 9's + 1) -> should cause arithmetic overflow
INSERT INTO overflow_test VALUES(99999999999999999999999999999999999999);
go

SELECT amount + 1 from overflow_test;
go

SELECT amount * 10 from overflow_test;
go

INSERT INTO overflow_test VALUES(1);
go

SELECT sum(amount) from overflow_test;
go

SELECT avg(amount) from overflow_test;
go

DROP TABLE overflow_test;
go

CREATE TABLE overflow_test (amount numeric(38, 5));
go

INSERT INTO overflow_test VALUES(999999999999999999999999999999999.99999);
go

INSERT INTO overflow_test VALUES(.00001);
go

SELECT sum(amount) from overflow_test;
go

DROP TABLE overflow_test;
go

-- 39 9's
select CAST(999999999999999999999999999999999999999 AS NUMERIC);
go

create table num_t1(a varchar(39));
go

-- 39 9's
insert into num_t1 values (999999999999999999999999999999999999999);
go

select cast(a as numeric) from num_t1;
go

drop table num_t1;
go

-- BABEL-3450 (Zero produced as result of numeric operation is causing crash)
create table num_zero(a numeric(5, 2));
go

insert into num_zero values(123.45);
go

insert into num_zero values(-123.45);
go

select sum(a) from num_zero;
go

drop table num_zero;
go

-- Create test table with different integer types
CREATE TABLE variable_test (
    size_int INT,
    size_smallint SMALLINT,
    size_bigint BIGINT
);
GO

-- Test data insertion
INSERT INTO variable_test VALUES 
(707072, 32767, 9223372036854775807);
GO

-- Basic multiplication
SELECT 
    size_int * 8.00 as int_mult,
    size_smallint * 8.00 as smallint_mult,
    size_bigint * 8.00 as bigint_mult
FROM variable_test;
GO

-- Decimal multiplication
SELECT 
    size_int * 1.23 as int_mult,
    size_smallint * 1.23 as smallint_mult,
    size_bigint * 1.23 as bigint_mult
FROM variable_test;
GO

-- Small decimal multiplication
SELECT 
    size_int * 0.01 as int_mult,
    size_smallint * 0.01 as smallint_mult,
    size_bigint * 0.01 as bigint_mult
FROM variable_test;
GO

-- Large decimal multiplication
SELECT 
    size_int * 999999.99 as int_mult,
    size_smallint * 999999.99 as smallint_mult,
    size_bigint * 999999.99 as bigint_mult
FROM variable_test;
GO

-- Basic division
SELECT 
    size_int / 2.00 as int_div,
    size_smallint / 2.00 as smallint_div,
    size_bigint / 2.00 as bigint_div
FROM variable_test;
GO

-- Decimal division
SELECT 
    size_int / 1.23 as int_div,
    size_smallint / 1.23 as smallint_div,
    size_bigint / 1.23 as bigint_div
FROM variable_test;
GO

-- Small decimal division
SELECT 
    size_int / 0.01 as int_div,
    size_smallint / 0.01 as smallint_div,
    size_bigint / 0.01 as bigint_div
FROM variable_test;
GO

-- Complex calculations
SELECT 
    size_int * 1.23 / 4.56 as int_complex,
    size_smallint * 1.23 / 4.56 as smallint_complex,
    size_bigint * 1.23 / 4.56 as bigint_complex
FROM variable_test;
GO

-- Cleanup
DROP TABLE variable_test;
GO
