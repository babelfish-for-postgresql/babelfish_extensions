-- basic operator testing
-- test 1
select COL2_T2 + COL3_T2 from BABEL_5454_T2
go

-- test 2 : with order by
select COL2_T2 + COL3_T2 from BABEL_5454_T2 order by COL2_T2
go
-- test 3 : subquery
select abc from (select COL2_T2 + COL3_T2 as abc from BABEL_5454_T2)
go


-- Selecting varchar and numeric
SELECT
    cr1 AS description,
    ex + COL3_T2 AS sum_num
FROM (
    SELECT
        COL2_T2 AS ex,
        COL2_T1 AS cr1,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2
        ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
ORDER BY sum_num;
GO

-- Selecting only numeric
SELECT
    COL3_T1 + COL3_T2 AS val
FROM (
    SELECT
        COL3_T1,
        COL2_T2 + COL3_T2,
        COL2_T1 AS cr1,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2
        ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        1 AS aw1,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
ORDER BY val;
GO

-- Nested operator query
SELECT
    sum + COL3_T2 AS val
FROM (
    SELECT
        COL3_T1,
        COL2_T2 + COL3_T2 AS sum,
        COL2_T1 AS cr1,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2
        ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        1 AS aw1,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
ORDER BY val;
GO

-- aggregate function and nested query
SELECT
    AVG(sum_num)
FROM (
    SELECT
        sum + COL3_T2 AS sum_num
    FROM (
        SELECT
            COL3_T1,
            COL2_T2 + COL3_T2 AS sum,
            COL2_T1 AS cr1,
            COL2_T1,
            COL3_T2
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2
            ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT
            1 AS aw,
            1 AS aw1,
            COL2_T1 AS cr,
            COL2_T1,
            COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) subquery
) a;
GO

-- selecting 1
SELECT
    1,
    cr1 AS description,
    ex + COL3_T2 AS ex1
FROM (
    SELECT
        COL2_T2 AS ex,
        COL2_T1 AS cr1,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2
        ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        COL3_T1 AS aw,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
order by ex1
GO

-- Testing inner query with operator
-- union of decimal
SELECT
    COL2_T2 + COL3_T2 AS ex,
    COL2_T1 AS cr1,
    COL2_T1
FROM BABEL_5454_T1
INNER JOIN BABEL_5454_T2
    ON COL1_T2 = COL1_T1
UNION ALL
SELECT
    COL3_T1 AS aw,
    COL2_T1 AS cr,
    COL2_T1
FROM BABEL_5454_T1
ORDER BY ex;
GO

-- union with t_const
SELECT
    COL2_T2 + COL3_T2 AS ex,
    COL2_T1 AS cr1,
    COL2_T1
FROM BABEL_5454_T1
INNER JOIN BABEL_5454_T2
    ON COL1_T2 = COL1_T1
UNION ALL
SELECT
    1 AS aw,
    COL2_T1 AS cr,
    COL2_T1
FROM BABEL_5454_T1
ORDER BY ex;
GO

-- Testing with different order of inner columns in union
SELECT
    cr1 AS description,
    ex + COL3_T2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T2 AS ex
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
    FROM BABEL_5454_T1
);
GO

-- Testing with where clause
SELECT
    cr1 AS description,
    ex + COL3_T2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T2 AS ex
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
WHERE cr1 = 'US';
GO

-- Testing with different order of inner columns in union
SELECT
    cr1 AS description,
    ex + COL3_T2 AS sum_numeric
FROM (
    SELECT COL2_T1 AS cr1, COL2_T2 AS ex, COL3_T2, COL2_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT COL2_T1 AS cr, 1 AS aw, COL3_T1 AS aw1, COL2_T1
    FROM BABEL_5454_T1
) a;
GO

-- Testing with more columns in unions
SELECT
    cr1 AS description,
    ex + COL3_T2 AS sum_numeric
FROM (
    SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T1 AS cr2, COL2_T2 AS ex
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL2_T1 AS cr3, COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a;
GO

-- Multiple alias and t_const in union
SELECT
    description AS d1,
    ex2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, ex AS ex2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS ex, COL2_T1 AS cr1, COL2_T1, COL3_T2 AS h1
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) a
)
ORDER BY test1;
GO

-- Multiple alias and decimal in union
SELECT
    description AS d1,
    ex2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, ex AS ex2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS ex, COL2_T1 AS cr1, COL2_T1, COL3_T2 AS h1
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT COL3_T1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) AS a
)
ORDER BY test1;
GO

-- Nested query and alias
SELECT
    description AS d1,
    ex2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, ex AS ex2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS ex, COL2_T1 AS cr1, COL2_T1, COL3_T2 AS h1
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, 1 AS aw1
        FROM BABEL_5454_T1
    ) a
)
ORDER BY test1;
GO

-- Selecting same column without alias in inner query
SELECT
    cr1 AS description,
    COL3_T1 + COL3_T1 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T2 AS ex, COL3_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1, COL3_T1
    FROM BABEL_5454_T1
);
GO

-- Operator with a constant value
SELECT
    cr1 AS description,
    COL3_T1 + 5.2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T2 AS ex, COL3_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1, COL3_T1
    FROM BABEL_5454_T1
);
GO

-- Nested query
SELECT
    description,
    sum_num + sum_num AS result
FROM (
    SELECT cr1 AS description, COL3_T1 + COL3_T1 AS sum_num
    FROM (
        SELECT COL3_T2, COL2_T1 AS cr1, COL2_T1, COL2_T2 AS ex, COL3_T1
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1, COL3_T1
        FROM BABEL_5454_T1
    )
)
ORDER BY result;
GO

-- selecting only numeric
SELECT
    sum_num + sum_num AS result
FROM (
    SELECT cr1 AS description, ex + COL3_T2 AS sum_num
    FROM (
        SELECT COL2_T2 AS ex, COL2_T1 AS cr1, COL2_T1, COL3_T2
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) a
)
ORDER BY result;
GO

-- Query with CASE and UNION ALL
SELECT
    result + result AS sum_result
FROM (
    SELECT
        CASE
            WHEN 1 = 1 THEN CAST(1.12343 AS DECIMAL(5,2))
        END AS result
    UNION ALL
    SELECT COL3_T2
    FROM BABEL_5454_T2
) AS derived_table
order by sum_result
GO

-- Multiple UNION ALL query
SELECT
    ex5 + ex5 AS ex_result
FROM (
    SELECT COL1_T2, COL2_T2 AS ex5
    FROM BABEL_5454_T2
    UNION ALL
    (
        SELECT
            cr1 AS description,
            ex + COL3_T2 AS ex1
        FROM (
            SELECT COL2_T2 AS ex, COL2_T1 AS cr1, COL2_T1, COL3_T2
            FROM BABEL_5454_T1
            INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
            UNION ALL
            SELECT COL3_T1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
            FROM BABEL_5454_T1
        ) a
    )
) AS subquery
order by ex_result
GO

-- UDT
-- Test Case 1: Multiple UNION ALLs with different combinations
SELECT 
    CASE WHEN IntCol > 150 THEN FloatCol ELSE SmallIntCol END AS result,
    NumericCol + UDTCol AS sum_result
FROM TestTypes
UNION ALL
SELECT 
    CAST(NumericCol AS float) AS result,
    IntCol + FloatCol AS sum_result
FROM TestTypes
UNION ALL
SELECT 
    COALESCE(SmallIntCol, 0) AS result,
    CAST(UDTCol AS numeric(12,6)) + NumericCol AS sum_result
FROM TestTypes
order by sum_result;
GO

-- Test Case 2: Nested queries with decimal and numeric operations
SELECT outer_result + inner_result AS final_result
FROM (
    SELECT 
        (SELECT AVG(NumericCol) FROM TestTypes) AS outer_result,
        (
            SELECT TOP 1 UDTCol + FloatCol 
            FROM TestTypes 
            ORDER BY IntCol DESC
        ) AS inner_result
) AS nested_query
order by final_result;
GO

-- Test Case 3: Decimal + Numeric with different scales and precisions
SELECT 
    CAST(12345.6789 AS decimal(10,4)) + NumericCol AS dec_num_sum,
    CAST(12345.6789 AS decimal(10,4)) * NumericCol AS dec_num_product
FROM TestTypes
UNION ALL
SELECT 
    CAST(9876.54321 AS numeric(12,8)) + UDTCol,
    CAST(9876.54321 AS numeric(12,8)) * UDTCol
FROM TestTypes
order by dec_num_sum;
GO

-- Test Case 4: UDT operations
SELECT 
    UDTCol + IntCol AS udt_int_sum,
    UDTCol * FloatCol AS udt_float_product,
    UDTCol / NULLIF(SmallIntCol, 0) AS udt_smallint_div
FROM TestTypes;
GO

-- Test Case 5: Mixed type operations with CAST
SELECT 
    CAST(IntCol AS decimal(10,2)) + FloatCol AS int_float_sum,
    CAST(SmallIntCol AS numeric(8,4)) * NumericCol AS smallint_numeric_product,
    CAST(UDTCol AS float) / NULLIF(IntCol, 0) AS udt_int_div
FROM TestTypes
UNION ALL
SELECT 
    CAST(12.34 AS decimal(5,2)) + CAST(56.78 AS numeric(6,3)),
    CAST(100 AS smallint) * CAST(2.5 AS float),
    CAST(1000 AS numeric(10,4)) / NULLIF(CAST(3 AS int), 0)
FROM TestTypes
order by int_float_sum;
GO

-- Test Case 6: All possible operations
SELECT
    IntCol + FloatCol AS addition,
    NumericCol - UDTCol AS subtraction,
    SmallIntCol * FloatCol AS multiplication,
    CAST(NumericCol AS float) / NULLIF(IntCol, 0) AS division,
    POWER(FloatCol, 2) AS exponentiation,
    IntCol % 3 AS modulo
FROM TestTypes;
GO

-- Test Case 7: UNION with different scales and precisions
SELECT CAST(IntCol AS decimal(10,2)) AS result
FROM TestTypes
UNION
SELECT CAST(FloatCol AS decimal(12,4))
FROM TestTypes
UNION
SELECT NumericCol
FROM TestTypes
UNION
SELECT UDTCol
FROM TestTypes
order by result;
GO

-- inner query is selecting same column with and without alias
select result1+result1 as result2 , a from (SELECT a , a AS result1 FROM BABEL_5454_T4 union all SELECT in4, in4 + in5 AS result FROM BABEL_5454_T3) order by result2


-- test
select a from BABEL_5454_T7 UNION All
SELECT amount + 100 FROM BABEL_5454_T8 where id = 1
