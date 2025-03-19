select round(cast(42 as int), 0)
go

select round(cast(42 as int), 1)
go

select round(cast(42 as int), 2)
go

select round(cast(42 as int), 999)
go

select round(cast(42 as int), -1)
go

select round(cast(42 as int), -2)
go


select round(cast(42 as tinyint), 0)
go

select round(cast(42 as tinyint), 1)
go

select round(cast(42 as tinyint), 2)
go

select round(cast(42 as tinyint), 999)
go

select round(cast(42 as tinyint), -1)
go

select round(cast(42 as tinyint), -2)
go


select round(cast(42 as smallint), 0)
go

select round(cast(42 as smallint), 1)
go

select round(cast(42 as smallint), 2)
go

select round(cast(42 as smallint), 999)
go

select round(cast(42 as smallint), -1)
go

select round(cast(42 as smallint), -2)
go


select round(cast(42 as bigint), 0)
go

select round(cast(42 as bigint), 1)
go

select round(cast(42 as bigint), 2)
go

select round(cast(42 as bigint), 999)
go

select round(cast(42 as bigint), -1)
go

select round(cast(42 as bigint), -2)
go


select round(cast(42 as decimal), 0)
go

select round(cast(42 as decimal), 1)
go

select round(cast(42 as decimal), 2)
go

select round(cast(42 as decimal), 999)
go

select round(cast(42 as decimal), -1)
go

select round(cast(42 as decimal), -2)
go


select round(cast(42 as numeric), 0)
go

select round(cast(42 as numeric), 1)
go

select round(cast(42 as numeric), 2)
go

select round(cast(42 as numeric), 999)
go

select round(cast(42 as numeric), -1)
go

select round(cast(42 as numeric), -2)
go


select round(cast(42 as money), 0)
go

select round(cast(42 as money), 1)
go

select round(cast(42 as money), 2)
go

select round(cast(42 as money), 999)
go

select round(cast(42 as money), -1)
go

select round(cast(42 as money), -2)
go


select round(cast(42 as smallmoney), 0)
go

select round(cast(42 as smallmoney), 1)
go

select round(cast(42 as smallmoney), 2)
go

select round(cast(42 as smallmoney), 999)
go

select round(cast(42 as smallmoney), -1)
go

select round(cast(42 as smallmoney), -2)
go


select round(cast(42 as real), 0)
go

select round(cast(42 as real), 1)
go

select round(cast(42 as real), 2)
go

select round(cast(42 as real), 999)
go

select round(cast(42 as real), -1)
go

select round(cast(42 as real), -2)
go



select round(cast(748.58 as float), -1)
go

select round(cast(748.58 as float), -2)
go

select round(cast(748.58 as float), 0)
go

select round(cast(748.58 as float), 1)
go

select round(cast(748.58 as float), 2)
go

select round(cast(748.58 as float), 3)
go

select round(cast(748.58 as int), 1)
go

select round(cast(748.58 as money), 1)
go

select round(cast(748.58 as real), 1)
go

-- test syntax incorrect cases
select round(42)
go

select round(42.123)
go

select round(42, 1, 2, 0)
go

-- test with function argument
select round(cast(42 as int), 1, 0)
go

select round(cast(42 as float), 1, 0)
go

select round(cast(748.58 as float), 1, 0)
go

select round(cast(748.58 as int), 1, 0)
go

-- Add a round test from BABEL-1193.sql to here
select round(cast ('123' as text), 1), round(cast ('123' as char(3)), 1), round(cast ('123' as varchar(3)), 1);
GO

-- Add a rount test from babel_function.sql to here
select ROUND(NULL, -3);
GO

IF OBJECT_ID('sample_table', 'U') IS NOT NULL
    DROP TABLE sample_table;
go

CREATE TABLE sample_table (
    id int,
    a smallint
);
go

-- Insert sample data
INSERT INTO sample_table (id, a) VALUES
(1, 123),
(2, 456),
(3, 789);
go

-- Query the data
SELECT
    id,
    ROUND(CAST(a AS decimal), 2) as rounded_value
FROM sample_table;

SELECT
    id,
    ROUND(CAST(a AS int), 2) as rounded_value
FROM sample_table;
go

IF OBJECT_ID('sample_table', 'U') IS NOT NULL
        DROP TABLE sample_table;
go

DECLARE @strDev FLOAT = 2.73; SELECT CASE WHEN 2 = 3 THEN 0.00 ELSE ROUND(@strDev, 2) END;
go
