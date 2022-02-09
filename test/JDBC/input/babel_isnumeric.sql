--
-- Tests for ISNUMERIC function
--

DROP TABLE IF EXISTS test_isnumeric
GO

CREATE TABLE test_isnumeric (
    bigint_type bigint,
    int_type int,
    smallint_type smallint,
    tinyint_type tinyint,
    bit_type bit,
    decimal_type decimal(5,2),
    numeric_type numeric(10,5),
    float_type float,
    real_type real,
    money_type money,
    smallmoney_type money
)
GO

INSERT INTO test_isnumeric (
    bigint_type,
    int_type,
    smallint_type,
    tinyint_type,
    bit_type,
    decimal_type,
    numeric_type,
    float_type,
    real_type,
    money_type,
    smallmoney_type
)
VALUES (
    9223372036854775806,
    45000,
    -32767,
    100,
    1,
    123,
    12345.12,
    1.79E+30,
    -3.40E+38, 
    237891.22,
    77.58
)
GO

SELECT * FROM test_isnumeric
GO
-- Test bigint
SELECT ISNUMERIC(bigint_type)
FROM test_isnumeric
GO
-- Test int
SELECT ISNUMERIC(int_type)
FROM test_isnumeric
GO
-- Test smallint
SELECT ISNUMERIC(smallint_type)
FROM test_isnumeric
GO
-- Test tinyint
SELECT ISNUMERIC(tinyint_type)
FROM test_isnumeric
GO
-- Test bit
SELECT ISNUMERIC(bit_type)
FROM test_isnumeric
GO
-- Test decimal
SELECT ISNUMERIC(decimal_type)
FROM test_isnumeric
GO
-- Test numeric
SELECT ISNUMERIC(numeric_type)
FROM test_isnumeric
GO
-- Test float
SELECT ISNUMERIC(float_type)
FROM test_isnumeric
GO
-- Test real
SELECT ISNUMERIC(real_type)
FROM test_isnumeric
GO
-- Test money
SELECT ISNUMERIC(money_type)
FROM test_isnumeric
GO
-- Test smallmoney
SELECT ISNUMERIC(smallmoney_type)
FROM test_isnumeric
GO

DROP TABLE test_isnumeric
GO

-- Test valid and invalid operators and literals
select isnumeric(1234567890)
GO
select isnumeric('28903')
GO
select isnumeric('+')
GO
select isnumeric('+ ')
GO
-- Blocked due to BABEL-2853
--select isnumeric($)
--GO
select isnumeric('$24,23.43')
GO
-- Blocked due to BABEL-2853
--select isnumeric(€)
--GO
select isnumeric('+ 1')
GO
select isnumeric('$+1.1234')
GO
select isnumeric('+$1.1234')
GO
select isnumeric(' $ + 1.1234')
GO
select isnumeric(' + $ 1.1234')
GO

select isnumeric('abcdefghijklmnop')
GO
select isnumeric('24.89.43')
GO
select isnumeric('€24,2.3.43')
GO
select isnumeric('+-')
GO
select isnumeric('23$')
GO
select isnumeric(null)
GO
select isnumeric(' ')
GO
select isnumeric('1 .1234')
GO
select isnumeric('+1 .1234')
GO
select isnumeric('$1 .1234')
GO