-- BABEL-6813: Fix infinite CAST recursion and DATETRUNC regtype resolution

-- Test CAST(numeric AS INT) in CHECK constraint (exercises _trunc_numeric_to_int*)
CREATE TABLE t1 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val CHECK (CAST(val AS INT) > 0)
)
GO

INSERT INTO t1 VALUES (1, 5.7)
GO

-- Test CAST to different integer sizes
CREATE TABLE t2 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val_int2 CHECK (CAST(val AS SMALLINT) > 0)
)
GO

INSERT INTO t2 VALUES (1, 3.9)
GO

CREATE TABLE t3 (
    id int,
    val DECIMAL(10,2),
    CONSTRAINT chk_val_int8 CHECK (CAST(val AS BIGINT) > 0)
)
GO

INSERT INTO t3 VALUES (1, 10.5)
GO

-- DATETRUNC tests with various datetime types
SELECT DATETRUNC(year, CAST('2023-06-15 10:30:00' AS datetime))
GO

SELECT DATETRUNC(month, CAST('2023-06-15 10:30:00' AS smalldatetime))
GO

SELECT DATETRUNC(day, CAST('2023-06-15 10:30:00.1234567' AS datetime2))
GO

SELECT DATETRUNC(hour, CAST('2023-06-15 10:30:00.1234567 +05:30' AS datetimeoffset))
GO
