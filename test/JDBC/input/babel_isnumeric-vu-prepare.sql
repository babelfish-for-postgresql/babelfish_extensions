--
-- Tests for ISNUMERIC function
--

DROP TABLE IF EXISTS babel_isnumeric
GO

CREATE TABLE babel_isnumeric (
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

INSERT INTO babel_isnumeric (
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