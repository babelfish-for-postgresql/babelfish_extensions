-- basic operator testing
-- test 1
SELECT COL2_T2 + COL3_T2 FROM BABEL_5454_T2
go

SELECT COL2_T2 * COL3_T2 FROM BABEL_5454_T2
GO

SELECT COL2_T2 - COL3_T2 FROM BABEL_5454_T2
go

SELECT COL2_T2 / COL3_T2 FROM BABEL_5454_T2
go

-- test 2 : with ORDER BY
SELECT COL2_T2 + COL3_T2 FROM BABEL_5454_T2 ORDER BY COL2_T2
go
-- test 3 : subquery
SELECT val1 FROM (SELECT COL2_T2 + COL3_T2 AS val1 FROM BABEL_5454_T2)
go


-- Selecting varchar and numeric, JIRA QUERY
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_num
FROM (
    SELECT
        COL2_T2 AS value1,
        COL2_T1 AS value2,
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
        COL2_T1 AS value2,
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
        COL2_T1 AS value2,
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
            COL2_T1 AS value2,
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
    value2 AS description,
    value1 + COL3_T2 AS value1
FROM (
    SELECT
        COL2_T2 AS value1,
        COL2_T1 AS value2,
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
ORDER BY value1
GO

-- Testing inner query with operator
-- union of decimal
SELECT
    COL2_T2 + COL3_T2 AS value1,
    COL2_T1 AS value2,
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
ORDER BY value1;
GO

-- union with t_const
SELECT
    COL2_T2 + COL3_T2 AS value1,
    COL2_T1 AS value2,
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
ORDER BY value1, value2, COL2_T1;
GO

-- Testing with different order of inner columns in union
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T2 AS value1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
    FROM BABEL_5454_T1
)
ORDER BY sum_num
GO

-- Testing with where clause
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T2 AS value1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
WHERE value2 = 'US'
ORDER BY sum_num;
GO

-- Testing with different order of inner columns in union
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_numeric
FROM (
    SELECT COL2_T1 AS value2, COL2_T2 AS value1, COL3_T2, COL2_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT COL2_T1 AS cr, 1 AS aw, COL3_T1 AS aw1, COL2_T1
    FROM BABEL_5454_T1
) a
ORDER BY sum_numeric;
GO

-- Testing with more columns in unions
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_numeric
FROM (
    SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T1 AS cr2, COL2_T2 AS value1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL2_T1 AS cr3, COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
ORDER BY sum_numeric;
GO

-- Multiple alias and t_const in union
SELECT
    description AS d1,
    value2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, value1 AS value2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS value1, COL2_T1 AS value2, COL2_T1, COL3_T2 AS h1
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
    value2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, value1 AS value2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS value1, COL2_T1 AS value2, COL2_T1, COL3_T2 AS h1
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
    value2 + h2 AS test1
FROM (
    SELECT COL2_T1 AS description, value1 AS value2, h1 AS h2
    FROM (
        SELECT COL2_T2 AS value1, COL2_T1 AS value2, COL2_T1, COL3_T2 AS h1
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, 1 AS aw1
        FROM BABEL_5454_T1
    ) a
)
ORDER BY test1, d1;
GO

-- Selecting same column without alias in inner query
SELECT
    value2 AS description,
    COL3_T1 + COL3_T1 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T2 AS value1, COL3_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1, COL3_T1
    FROM BABEL_5454_T1
)
ORDER BY description, sum_num;
GO

-- Operator with a constant value
SELECT
    value2 AS description,
    COL3_T1 + 5.2 AS sum_num
FROM (
    SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T2 AS value1, COL3_T1
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT 1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1, COL3_T1
    FROM BABEL_5454_T1
)
ORDER BY description, sum_num;
GO

-- Nested query
SELECT
    description,
    sum_num + sum_num AS result
FROM (
    SELECT value2 AS description, COL3_T1 + COL3_T1 AS sum_num
    FROM (
        SELECT COL3_T2, COL2_T1 AS value2, COL2_T1, COL2_T2 AS value1, COL3_T1
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
    SELECT value2 AS description, value1 + COL3_T2 AS sum_num
    FROM (
        SELECT COL2_T2 AS value1, COL2_T1 AS value2, COL2_T1, COL3_T2
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
ORDER BY sum_result
GO

-- Multiple UNION ALL query
SELECT
    value5 + value5 AS value_result
FROM (
    SELECT COL1_T2, COL2_T2 AS value5
    FROM BABEL_5454_T2
    UNION ALL
    (
        SELECT
            value2 AS description,
            value1 + COL3_T2 AS value1
        FROM (
            SELECT COL2_T2 AS value1, COL2_T1 AS value2, COL2_T1, COL3_T2
            FROM BABEL_5454_T1
            INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
            UNION ALL
            SELECT COL3_T1 AS aw, COL2_T1 AS cr, COL2_T1, COL3_T1 AS aw1
            FROM BABEL_5454_T1
        ) a
    )
) AS subquery
ORDER BY value_result
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
ORDER BY sum_result, result;
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
ORDER BY final_result;
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
ORDER BY dec_num_sum;
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
ORDER BY int_float_sum;
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
ORDER BY result;
GO

-- inner query is selecting same column with and without alias, large numbers
SELECT
    result1 + result1 AS result2,
    a
FROM
    (
        SELECT
            a,
            a AS result1
        FROM
            BABEL_5454_T4
        UNION ALL
        SELECT
            in4,
            in4 + in5 AS result
        FROM
            BABEL_5454_T3
    ) a
ORDER BY result2;
GO

-- test
SELECT a FROM BABEL_5454_T7
UNION All
SELECT amount + 100 FROM BABEL_5454_T8
where id = 1
ORDER BY a
GO

-- cte and limit node, BABEL-5588
WITH cte AS (SELECT TOP 10 (id+1) AS id FROM BABEL_5454_T9 WHERE id >50 ORDER BY id) SELECT TOP 1 1, id FROM cte
GO

-- multiple union all, same column on top
select sum_num + sum_num from
(SELECT value1 + COL3_T2 AS sum_num FROM (SELECT COL2_T2 AS value1,COL3_T2 FROM BABEL_5454_T1 INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1 UNION ALL SELECT 1 AS aw, COL3_T1 AS aw1 FROM BABEL_5454_T1) a
union all
select COL2_T2 from BABEL_5454_T2)
Order by sum_num
GO


-- random node test - windowAGG
SELECT 
    IntCol,
    FloatCol,
    SmallIntCol,
    NumericCol,
    UDTCol,
    AVG(NumericCol) OVER (ORDER BY IntCol ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_avg
FROM TestTypes
ORDER BY IntCol;

-- windowAGG and union
SELECT 
    IntCol,
    FloatCol,
    SmallIntCol,
    NumericCol,
    UDTCol,
    AVG(NumericCol) OVER (ORDER BY IntCol ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_avg
FROM (
    SELECT IntCol, FloatCol, SmallIntCol, NumericCol, UDTCol
    FROM TestTypes
    UNION ALL
    SELECT IntCol + 1000, FloatCol + 1000, SmallIntCol + 100, NumericCol + 1000, UDTCol + 1000
    FROM TestTypes
) AS combined_data
ORDER BY IntCol;


-- selecting limit and windowAgg on top 
SELECT TOP 1
    description,
    sum_num,
    ROW_NUMBER() OVER (ORDER BY sum_num) AS row_num
FROM (
    SELECT
        value2 AS description,
        value1 + COL3_T2 AS sum_num
    FROM (
        SELECT
            COL2_T2 AS value1,
            COL2_T1 AS value2,
            COL2_T1,
            COL3_T2
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT
            1 AS aw,
            COL2_T1 AS cr,
            COL2_T1,
            COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) a
) b
ORDER BY sum_num;
GO

-- limit, and windowAgg togther with operator
SELECT
    value2 AS description,
    value1 + COL3_T2 AS sum_num,
    ROW_NUMBER() OVER (ORDER BY COL3_T2) AS row_num
FROM (
    SELECT
        COL2_T2 AS value1,
        COL2_T1 AS value2,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
ORDER BY sum_num;
Go

-- columns having agg and column operator
SELECT
    value2 AS description,
    SUM(value1) AS sum_value,
    value1 + COL3_T2 AS sum_num
FROM (
    SELECT
        COL2_T2 AS value1,
        COL2_T1 AS value2,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
GROUP BY value2, value1, COL3_T2
ORDER BY sum_num;
GO
-- combination of agg and addition
SELECT
    value2 AS description,
    SUM(value1) + MAX(COL3_T2) AS sum_num
FROM (
    SELECT
        COL2_T2 AS value1,
        COL2_T1 AS value2,
        COL2_T1,
        COL3_T2
    FROM BABEL_5454_T1
    INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
    UNION ALL
    SELECT
        1 AS aw,
        COL2_T1 AS cr,
        COL2_T1,
        COL3_T1 AS aw1
    FROM BABEL_5454_T1
) a
GROUP BY value2
ORDER BY sum_num;
Go

-- edge case of scake and precision
-- multiply
-- the integral part is less than 32, The result might be rounded in this case.
SELECT COL4_T12 * COL5_T12 FROM BABEL_5454_T12
GO
-- The scale isn't changed if it's less than 6 and if the integral part is greater than 32.
SELECT COL6_T12 * COL5_T12 FROM BABEL_5454_T12
GO
-- The scale is set to 6 if it's greater than 6 and if the integral part is greater than 32.
SELECT COL4_T12 * COL6_T12 FROM BABEL_5454_T12
GO


--  (38,6) + (38, 0) -- existing issue 
SELECT COL2_T12 + COL3_T12 FROM BABEL_5454_T12
GO
SELECT COL2_T12 - COL3_T12 FROM BABEL_5454_T12
GO
-- (38, 0) + (38, 0) -- correct
SELECT COL3_T12 + COL3_T12 FROM BABEL_5454_T12
GO
SELECT COL3_T12 - COL3_T12 FROM BABEL_5454_T12
GO

SELECT COL2_T12 + COL2_T12 AS Result FROM BABEL_5454_T12
GO
SELECT COL2_T12 - COL2_T12 AS Result FROM BABEL_5454_T12
GO
SELECT COL5_T12 * COL5_T12 AS Result FROM BABEL_5454_T12
GO
SELECT COL2_T12 / COL2_T12 AS Result FROM BABEL_5454_T12
GO


