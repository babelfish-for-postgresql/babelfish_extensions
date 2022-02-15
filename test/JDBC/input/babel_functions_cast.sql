-- test CAST function
-- Casting with date/time types
select CAST('08/25/2017' AS date);
GO
select CAST('12:01:59' AS time);
GO
select CAST('2017-08-25 01:01:59PM' AS datetime);
GO
select CAST('2017-08-25 01:01:59PM' AS datetime2);
GO
select CAST(CAST('2017-08-25' AS date) AS varchar(30));
GO
select CAST(CAST('13:01:59' AS time) AS varchar(30));
GO
select CAST(CAST('2017-08-25 13:01:59' AS datetime) AS varchar(30));
GO

-- Casting with numerics
select CAST(123 AS float);
GO
select CAST(CAST(11234561231231.234 AS float) AS varchar(30));
GO
select CAST('123' AS int);
GO
select CAST('123' AS text);
GO
select CAST('123.456' AS numeric(6,3));
GO
select CAST(123.456 AS numeric(6,3));
GO
select CAST('123' As smallint);
GO
select CAST('1234567890' AS bigint);
GO

-- Casting with money
select CAST(4936.56 AS MONEY);
GO
select CAST(-4936.56 AS MONEY);
GO
select CAST(CAST(4936.56 AS MONEY) AS varchar(10));
GO
select CAST(CAST(-4936.56 AS MONEY) AS varchar(10));
GO
select CAST(4936.56 AS smallmoney);
GO

-- Casting from money/smallmoney to smallint
select CAST(CAST(1.56 as smallmoney) AS smallint);
GO
select CAST(CAST(-1.56 as smallmoney) AS smallint);
GO
-- out of range
select CAST(CAST(-214748.3648 as smallmoney) As smallint);
GO
-- out of range
select CAST(CAST(214748.3647 as smallmoney) As smallint);
GO
select CAST(CAST(1.56 as MONEY) AS smallint);
GO
select CAST(CAST(-1.56 as MONEY) AS smallint);
GO
-- out of range
select CAST(CAST(922337203685477.5807 as MONEY) AS smallint);
GO
-- out of range
select CAST(CAST(-922337203685477.5808 as MONEY) AS smallint);
GO

-- Casting from money/smallmoney to int
select CAST(CAST(1.56 as smallmoney) AS int);
GO
select CAST(CAST(-1.56 as smallmoney) AS int);
GO
select CAST(CAST(-214748.3648 as smallmoney) As int);
GO
select CAST(CAST(214748.3647 as smallmoney) As int);
GO
select CAST(CAST(1.56 as MONEY) AS int);
GO
select CAST(CAST(-1.56 as MONEY) AS int);
GO
-- out of range
select CAST(CAST(922337203685477.5807 as MONEY) AS int);
GO
-- out of range
select CAST(CAST(-922337203685477.5808 as MONEY) AS int);
GO

-- Casting from money/smallmoney to bigint
select CAST(CAST(1.56 as smallmoney) AS bigint);
GO
select CAST(CAST(-1.56 as smallmoney) AS bigint);
GO
select CAST(CAST(-214748.3648 as smallmoney) As bigint);
GO
select CAST(CAST(214748.3647 as smallmoney) As bigint);
GO
select CAST(CAST(1.56 as MONEY) AS bigint);
GO
select CAST(CAST(-1.56 as MONEY) AS bigint);
GO
select CAST(CAST(922337203685477.5807 as MONEY) AS bigint);
GO
select CAST(CAST(-922337203685477.5808 as MONEY) AS bigint);
GO

-- test TRY_CAST function
-- Casting with date/time types
select TRY_CAST('08/25/2017' AS date);
GO
select TRY_CAST('12:01:59' AS time);
GO
select TRY_CAST('2017-08-25 01:01:59PM' AS datetime);
GO
select TRY_CAST('2017-08-25 01:01:59PM' AS datetime2);
GO
select TRY_CAST(TRY_CAST('2017-08-25' AS date) AS varchar(30));
GO
select TRY_CAST(TRY_CAST('13:01:59' AS time) AS varchar(30));
GO
select TRY_CAST(TRY_CAST('2017-08-25 13:01:59' AS datetime) AS varchar(30));
GO

-- Casting with numerics
select TRY_CAST(123 AS float);
GO
select TRY_CAST(CAST(11234561231231.234 AS float) AS varchar(30));
GO
select TRY_CAST('123' AS int);
GO
select TRY_CAST('123' AS text);
GO
select TRY_CAST('123.456' AS numeric(6,3));
GO
select TRY_CAST(123.456 AS numeric(6,3));
GO
select TRY_CAST('123' As smallint);
GO
select TRY_CAST('1234567890' AS bigint);
GO
select TRY_CAST(99.9 As int);
GO
select TRY_CAST(-99.9 As int);
GO

-- Casting from numeric to int types
-- Currently an issue with TRY_CASTing to tinyint(see: JIRA BABEL-926)
select TRY_CAST(CAST(12.56 as numeric(4,2)) As smallint);
GO
select TRY_CAST(CAST(-12.56 as numeric(4,2)) As smallint);
GO
select TRY_CAST(CAST(12.56 as numeric(4,2)) As int);
GO
select TRY_CAST(CAST(-12.56 as numeric(4,2)) As int);
GO
select TRY_CAST(CAST(12.56 as numeric(4,2)) As bigint);
GO
select TRY_CAST(CAST(-12.56 as numeric(4,2)) As bigint);
GO

-- Casting from double precision to int types
-- edge cases: -1.79e308, -2.23e-308, 0, 2.23e-308, 1.79e308
-- Currently an issue with TRY_CASTing to tinyint(see: JIRA BABEL-926)
select TRY_CAST(CAST(1.56 as float(53)) As smallint);
GO
select TRY_CAST(CAST(-1.56 as float(53)) As smallint);
GO
select TRY_CAST(CAST(-1.79e308 as float(53)) As smallint);
GO
select TRY_CAST(CAST(1.79e308 as float(53)) As smallint);
GO
select TRY_CAST(CAST(2.23e-308 as float(53)) As smallint);
GO
select TRY_CAST(CAST(-2.23e-308 as float(53)) As smallint);
GO
select TRY_CAST(CAST(1.56 as float(53)) As int);
GO
select TRY_CAST(CAST(-1.56 as float(53)) As int);
GO
select TRY_CAST(CAST(-1.79e308 as float(53)) As int);
GO
select TRY_CAST(CAST(1.79e308 as float(53)) As int);
GO
select TRY_CAST(CAST(2.23e-308 as float(53)) As int);
GO
select TRY_CAST(CAST(-2.23e-308 as float(53)) As int);
GO
select TRY_CAST(CAST(1.56 as float(53)) As bigint);
GO
select TRY_CAST(CAST(-1.56 as float(53)) As bigint);
GO
select TRY_CAST(CAST(-1.79e308 as float(53)) As bigint);
GO
select TRY_CAST(CAST(1.79e308 as float(53)) As bigint);
GO
select TRY_CAST(CAST(2.23e-308 as float(53)) As bigint);
GO
select TRY_CAST(CAST(-2.23e-308 as float(53)) As bigint);
GO

-- Casting fromreal to int types
-- edge cases: -3.40e38, -1.18e-38, 0, 1.18e-38, 3.40e38
-- Currently an issue with TRY_CASTing to tinyint(see: JIRA BABEL-926)
select TRY_CAST(CAST(1.56 as real) As smallint);
GO
select TRY_CAST(CAST(-1.56 as real) As smallint);
GO
select TRY_CAST(CAST(-3.40e38 as real) As smallint);
GO
select TRY_CAST(CAST(-1.18e-38 as real) As smallint);
GO
select TRY_CAST(CAST(1.18e-38 as real) As smallint);
GO
select TRY_CAST(CAST(3.40e38 as real) As smallint);
GO
select TRY_CAST(CAST(1.56 as real) As int);
GO
select TRY_CAST(CAST(-1.56 as real) As int);
GO
select TRY_CAST(CAST(-3.40e38 as real) As int);
GO
select TRY_CAST(CAST(-1.18e-38 as real) As int);
GO
select TRY_CAST(CAST(1.18e-38 as real) As int);
GO
select TRY_CAST(CAST(3.40e38 as real) As int);
GO
select TRY_CAST(CAST(1.56 as real) As bigint);
GO
select TRY_CAST(CAST(-1.56 as real) As bigint);
GO
select TRY_CAST(CAST(-3.40e38 as real) As bigint);
GO
select TRY_CAST(CAST(-1.18e-38 as real) As bigint);
GO
select TRY_CAST(CAST(1.18e-38 as real) As bigint);
GO
select TRY_CAST(CAST(3.40e38 as real) As bigint);
GO

-- Casting from money to int types
-- edge cases: -922337203685477.5808, 922337203685477.5807
-- Currently an issue with TRY_CASTing to tinyint(see: JIRA BABEL-926)
select TRY_CAST(CAST(1.56 as money) As smallint);
GO
select TRY_CAST(CAST(-1.56 as money) As smallint);
GO
select (TRY_CAST(CAST(-922337203685477.5808 as money) As smallint));
GO
select (TRY_CAST(CAST(922337203685477.5807 as money) As smallint));
GO
select TRY_CAST(CAST(1.56 as money) As int);
GO
select TRY_CAST(CAST(-1.56 as money) As int);
GO
select (TRY_CAST(CAST(-922337203685477.5808 as money) As int));
GO
select (TRY_CAST(CAST(922337203685477.5807 as money) As int));
GO
select TRY_CAST(CAST(1.56 as money) As bigint);
GO
select TRY_CAST(CAST(-1.56 as money) As bigint);
GO
select (TRY_CAST(CAST(-922337203685477.5808 as money) As bigint));
GO
select (TRY_CAST(CAST(922337203685477.5807 as money) As bigint));
GO

-- Casting from smallmoney to int types
-- edge cases: -214748.3648, 214748.3647
-- Currently an issue with TRY_CASTing to tinyint(see: JIRA BABEL-926)
select TRY_CAST(CAST(1.56 as smallmoney) As smallint);
GO
select TRY_CAST(CAST(-1.56 as smallmoney) As smallint);
GO
select (TRY_CAST(CAST(-214748.3648 as smallmoney) As smallint));
GO
select (TRY_CAST(CAST(214748.3647 as smallmoney) As smallint));
GO
select TRY_CAST(CAST(1.56 as smallmoney) As int);
GO
select TRY_CAST(CAST(-1.56 as smallmoney) As int);
GO
select TRY_CAST(CAST(-214748.3648 as smallmoney) As int);
GO
select TRY_CAST(CAST(214748.3647 as smallmoney) As int);
GO
select TRY_CAST(CAST(1.56 as smallmoney) As bigint);
GO
select TRY_CAST(CAST(-1.56 as smallmoney) As bigint);
GO
select TRY_CAST(CAST(-214748.3648 as smallmoney) As bigint);
GO
select TRY_CAST(CAST(214748.3647 as smallmoney) As bigint);
GO

-- Casting with money
select TRY_CAST(4936.56 AS MONEY);
GO
select TRY_CAST(-4936.56 AS MONEY);
GO
select TRY_CAST(TRY_CAST(4936.56 AS MONEY) AS varchar(10));
GO
select TRY_CAST(TRY_CAST(-4936.56 AS MONEY) AS varchar(10));
GO
select TRY_CAST(4936.56 AS smallmoney);
GO
