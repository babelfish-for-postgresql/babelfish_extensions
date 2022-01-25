--
-- Tests for ISNUMERIC function
--

DROP TABLE IF EXISTS test_table
GO

CREATE TABLE test_table (
    bigint_type bigint,
    int_type int,
    smallint_type smallint,
    tinyint_type tinyint,
    bit_type bit,
    decimal_type decimal(5,2),
    numeric_type numeric(10,5),
    float_type float)
GO

INSERT INTO test_table (
    bigint_type,
    int_type,
    smallint_type,
    tinyint_type,
    bit_type,
    decimal_type,
    numeric_type,
    float_type)
VALUES (
    9223372036854775806,
    45000,
    -32767,
    100,
    1,
    123.456,
    12345.12,
    1.79E+30
)
GO

-- Check correctness of values for floor function
SELECT 
    floor(bigint_type),
    floor(int_type),
    floor(smallint_type),
    floor(tinyint_type),
    floor(bit_type),
    floor(decimal_type),
    floor(numeric_type),
    floor(float_type)
FROM test_table
GO

-- Check correctness of return types for floor function
SELECT 
    cast(pg_typeof(floor(bigint_type)) as varchar(10)),
    cast(pg_typeof(floor(int_type)) as varchar(10)),
    cast(pg_typeof(floor(smallint_type)) as varchar(10)),
    cast(pg_typeof(floor(tinyint_type)) as varchar(10)),
    cast(pg_typeof(floor(bit_type)) as varchar(10)),
    cast(pg_typeof(floor(decimal_type)) as varchar(10)),
    cast(pg_typeof(floor(numeric_type)) as varchar(10)),
    cast(pg_typeof(floor(float_type)) as varchar(10))
FROM test_table
GO

-- Check correctness of values for ceiling function
SELECT 
    ceiling(bigint_type),
    ceiling(int_type),
    ceiling(smallint_type),
    ceiling(tinyint_type),
    ceiling(bit_type),
    ceiling(decimal_type),
    ceiling(numeric_type),
    ceiling(float_type)
FROM test_table
GO

-- Check correctness of return types for ceiling function
SELECT 
    cast(pg_typeof(ceiling(bigint_type)) as varchar(10)),
    cast(pg_typeof(ceiling(int_type)) as varchar(10)),
    cast(pg_typeof(ceiling(smallint_type)) as varchar(10)),
    cast(pg_typeof(ceiling(tinyint_type)) as varchar(10)),
    cast(pg_typeof(ceiling(bit_type)) as varchar(10)),
    cast(pg_typeof(ceiling(decimal_type)) as varchar(10)),
    cast(pg_typeof(ceiling(numeric_type)) as varchar(10)),
    cast(pg_typeof(ceiling(float_type)) as varchar(10))
FROM test_table
GO

--Cleanup
DROP TABLE test_table
GO