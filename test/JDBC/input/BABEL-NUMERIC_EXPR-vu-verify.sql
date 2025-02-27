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
SELECT * FROM BABEL_5454_V2 ORDER BY sum_num;
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

-- test union all
SELECT a FROM BABEL_5454_T7
UNION All
SELECT amount + 100 FROM BABEL_5454_T8
where id = 1
ORDER BY a
GO

-- multiple union all, same column on top
SELECT sum_num + sum_num
FROM (
    SELECT value1 + COL3_T2 AS sum_num
    FROM (
        SELECT COL2_T2 AS value1, COL3_T2
        FROM BABEL_5454_T1
        INNER JOIN BABEL_5454_T2 ON COL1_T2 = COL1_T1
        UNION ALL
        SELECT 1 AS aw, COL3_T1 AS aw1
        FROM BABEL_5454_T1
    ) a
    UNION ALL
    SELECT COL2_T2
    FROM BABEL_5454_T2
)
ORDER BY sum_num;
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
GO

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
GO

-- limit
SELECT
    TOP 2
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
ORDER BY sum_num, description, row_num;
GO

-- limit, and windowAgg togther with operator
SELECT
    TOP 5
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

-- edge case of scale and precision

-- multiply and divide
-- the integral part is less than 32, The result might be rounded in this case.
-- (10, 7) * (4, 0)
SELECT COL4_T12 * COL5_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (10, 7) / (4,0)
SELECT COL4_T12 / COL5_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- The scale isn't changed if it's less than 6 and if the integral part is greater than 32.
-- (30, 5) * (4, 0)
SELECT COL6_T12 * COL5_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (30, 5) / (4, 0)
SELECT COL6_T12 / COL5_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- The scale is set to 6 if it's greater than 6 and if the integral part is greater than 32.
-- (38,5) * (10, 7)
SELECT COL6_T12 * COL4_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (38,5) / (10, 7)
SELECT COL6_T12 / COL4_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO

-- (38,6) / (38,6)
SELECT COL2_T12 / COL2_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO

-- addition and subtraction
--  (38,6) + (38, 0)
SELECT COL2_T12 + COL3_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
--  (38,6) - (38, 0)
SELECT COL2_T12 - COL3_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (38, 0) + (38, 0)
SELECT COL3_T12 + COL3_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (38, 0) + (38, 0)
SELECT COL3_T12 - COL3_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO

-- (38,6) + (38,6)
SELECT COL2_T12 + COL2_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO
-- (38,6) - (38,6)
SELECT COL2_T12 - COL2_T12 AS Result FROM BABEL_5454_T11 ORDER BY RESULT
GO

-- edge case with union
-- (38,5) * (10, 7)
SELECT COL6_T12 * COL4_T12 AS RESULT FROM (SELECT * FROM BABEL_5454_T11 UNION ALL SELECT * FROM BABEL_5454_T11) ORDER BY RESULT
GO

-- (38,6) / (38,6)
SELECT COL2_T12 / COL2_T12 AS Result FROM (SELECT * FROM BABEL_5454_T11 UNION ALL SELECT * FROM BABEL_5454_T11) ORDER BY RESULT
GO

-- (38,6) + (38,6)
SELECT COL2_T12 + COL2_T12 AS Result FROM (SELECT * FROM BABEL_5454_T11 UNION ALL SELECT * FROM BABEL_5454_T11) ORDER BY RESULT
GO

-- (38,6) - (38,6)
SELECT COL2_T12 - COL2_T12 AS Result FROM (SELECT * FROM BABEL_5454_T11 UNION ALL SELECT * FROM BABEL_5454_T11) ORDER BY RESULT
GO

-- view with CTE and limit node, BABEL-5588
SELECT * FROM BABEL_5454_V3;
GO

-- BABEL-5588
SELECT * FROM BABEL_5454_V1 ORDER BY volume;
GO

-- SubqueryScan on top
SELECT id + 10 FROM (SELECT TOP 5 ROW_NUMBER() OVER(ORDER BY id) AS srNo, id + 1.0 AS id FROM BABEL_5454_T10) AS BABEL_5454_T10
GO

-- INNER_VAR with CTE
SELECT * FROM BABEL_5454_V4;
GO

-- CTE with window function and self-join
WITH CTE AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS row_num 
    FROM BABEL_5454_T9 
    WHERE id <= 50
)
SELECT c1.id, c1.row_num, c2.id AS next_id 
FROM CTE c1 
LEFT JOIN CTE c2 ON c1.row_num = c2.row_num - 1
ORDER BY c1.row_num
GO

-- CTE with aggregation and outer join
WITH CTE AS (
    SELECT (id/10) AS group_id, AVG(id) AS avg_id 
    FROM BABEL_5454_T9 
    GROUP BY (id/10)
)
SELECT t.id, c.avg_id 
FROM BABEL_5454_T9 t 
LEFT JOIN CTE c ON (t.id/10) = c.group_id
WHERE t.id % 10 = 0
ORDER BY t.id
GO

-- Nested CTEs with UNION ALL
WITH cte1 AS (
    SELECT id FROM BABEL_5454_T9 WHERE id <= 50
),
cte2 AS (
    SELECT id FROM BABEL_5454_T9 WHERE id > 50
),
combined AS (
    SELECT id, 'Lower' AS category FROM cte1
    UNION ALL
    SELECT id, 'Upper' AS category FROM cte2
)
SELECT category, AVG(id) AS avg_id
FROM combined
GROUP BY category
Order BY avg_id
GO

-- CTE with subquery and CROSS APPLY
WITH CTE AS (
    SELECT id FROM BABEL_5454_T9 WHERE id % 10 = 0
)
SELECT c.id, t.multiplied_id 
FROM CTE c
CROSS APPLY (SELECT c.id * 2 AS multiplied_id) t
ORDER BY c.id
GO

-- CTE with PIVOT-like operation
WITH CTE AS (
    SELECT id, 
           CASE WHEN id % 3 = 0 THEN 'Fizz'
                WHEN id % 5 = 0 THEN 'Buzz'
                ELSE 'Other' END AS category
    FROM BABEL_5454_T9
    WHERE id <= 30
)
SELECT 
    category,
    COUNT(*) AS count,
    STRING_AGG(CAST(id AS VARCHAR), ',') AS ids
FROM CTE
GROUP BY category
ORDER BY count
GO

-- CTE with self-join and arithmetic operations
WITH CTE AS (
    SELECT id, id * 2 AS double_id, id * id AS squared_id
    FROM BABEL_5454_T10
)
SELECT 
    t1.id AS original_id,
    t1.double_id,
    t1.squared_id,
    t2.id AS next_id,
    t1.id + t2.id AS sum_ids
FROM CTE t1
LEFT JOIN CTE t2 ON t1.id < t2.id
ORDER BY t1.id
GO

-- CTE with running total
WITH CTE AS (
    SELECT id,
           SUM(id) OVER (ORDER BY id) AS running_total
    FROM BABEL_5454_T10
)
SELECT 
    id,
    running_total,
    running_total - id AS previous_total
FROM CTE
ORDER BY id
GO

-- CTE with multiple levels and join
WITH 
cte1 AS (
    SELECT id, CAST(id AS INT) AS int_id
    FROM BABEL_5454_T10
),
cte2 AS (
    SELECT DISTINCT int_id
    FROM cte1
)
SELECT 
    c1.id,
    c2.int_id AS floor_id,
    c1.id * c2.int_id AS product
FROM cte1 c1
JOIN cte2 c2 ON c1.int_id = c2.int_id
ORDER BY c1.id, c2.int_id;
GO

-- CTE with pivoting (simulated)
WITH CTE AS (
    SELECT 
        id,
        CASE 
            WHEN id < 1 THEN 'Low'
            WHEN id >= 1 AND id < 2 THEN 'Medium'
            ELSE 'High'
        END AS category
    FROM BABEL_5454_T10
)
SELECT 
    SUM(CASE WHEN category = 'Low' THEN id ELSE 0 END) AS Low_Total,
    SUM(CASE WHEN category = 'Medium' THEN id ELSE 0 END) AS Medium_Total,
    SUM(CASE WHEN category = 'High' THEN id ELSE 0 END) AS High_Total
FROM CTE
GO

-- CTE with window functions
WITH CTE AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS row_num,
        NTILE(3) OVER (ORDER BY id) AS ntile,
        LAG(id) OVER (ORDER BY id) AS prev_id,
        LEAD(id) OVER (ORDER BY id) AS next_id
    FROM BABEL_5454_T10
)
SELECT *
FROM CTE
ORDER BY id
GO

-- CTE with UNION, LIMIT, and window aggregation
WITH number_categories AS (
    SELECT id, 
           id % 10 AS category,
           CASE 
               WHEN id <= 33 THEN 'Low'
               WHEN id <= 66 THEN 'Medium'
               ELSE 'High'
           END AS range_category
    FROM BABEL_5454_T9
),
ranked_data AS (
    SELECT 
        id, 
        category,
        range_category,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY id DESC) AS rank_in_category,
        SUM(id) OVER (PARTITION BY category) AS category_total,
        AVG(id) OVER (PARTITION BY range_category) AS range_avg
    FROM number_categories
)
SELECT TOP 20
    id,
    category,
    range_category,
    rank_in_category,
    category_total,
    range_avg,
    CAST(id AS FLOAT) / NULLIF(category_total, 0) * 100 AS percent_of_category
FROM ranked_data
WHERE rank_in_category <= 3  -- Top 3 values in each category
UNION ALL
SELECT 
    NULL AS id,
    category,
    'Total' AS range_category,
    NULL AS rank_in_category,
    category_total,
    NULL AS range_avg,
    100 AS percent_of_category
FROM ranked_data
WHERE rank_in_category = 1  -- To get one row per category for totals
ORDER BY category, rank_in_category;
GO

-- CTE and edge case of precision/scale
-- CTE with multiplication and division operations
WITH cte_mult_div AS (
    SELECT 
        COL1_T12,
        COL4_T12 * COL5_T12 AS mult_result_1, -- (10, 7) * (4, 0)
        COL4_T12 / COL5_T12 AS div_result_1,  -- (10, 7) / (4, 0)
        COL6_T12 * COL5_T12 AS mult_result_2, -- (30, 5) * (4, 0)
        COL6_T12 / COL5_T12 AS div_result_2,  -- (30, 5) / (4, 0)
        COL6_T12 * COL4_T12 AS mult_result_3, -- (30, 5) * (10, 7)
        COL6_T12 / COL4_T12 AS div_result_3,  -- (30, 5) / (10, 7)
        COL2_T12 / COL2_T12 AS div_result_4   -- (38, 6) / (38, 6)
    FROM BABEL_5454_T11
)
SELECT 
    COL1_T12,
    mult_result_1, div_result_1,
    mult_result_2, div_result_2,
    mult_result_3, div_result_3,
    div_result_4
FROM cte_mult_div
ORDER BY COL1_T12;
GO

-- CTE with addition and subtraction operations
WITH cte_add_sub AS (
    SELECT 
        COL1_T12,
        COL2_T12 + COL3_T12 AS add_result_1,  -- (38, 6) + (38, 0)
        COL2_T12 - COL3_T12 AS sub_result_1,  -- (38, 6) - (38, 0)
        COL3_T12 + COL3_T12 AS add_result_2,  -- (38, 0) + (38, 0)
        COL3_T12 - COL3_T12 AS sub_result_2,  -- (38, 0) - (38, 0)
        COL2_T12 + COL2_T12 AS add_result_3,  -- (38, 6) + (38, 6)
        COL2_T12 - COL2_T12 AS sub_result_3   -- (38, 6) - (38, 6)
    FROM BABEL_5454_T11
)
SELECT 
    COL1_T12,
    add_result_1, sub_result_1,
    add_result_2, sub_result_2,
    add_result_3, sub_result_3
FROM cte_add_sub
ORDER BY COL1_T12;
GO

-- CTE with edge cases using UNION ALL
WITH cte_union AS (
    SELECT * FROM BABEL_5454_T11
    UNION ALL
    SELECT * FROM BABEL_5454_T11
)
SELECT 
    COL1_T12,
    COL6_T12 * COL4_T12 AS mult_result,  -- (30, 5) * (10, 7)
    COL2_T12 / COL2_T12 AS div_result,   -- (38, 6) / (38, 6)
    COL2_T12 + COL2_T12 AS add_result,   -- (38, 6) + (38, 6)
    COL2_T12 - COL2_T12 AS sub_result    -- (38, 6) - (38, 6)
FROM cte_union
ORDER BY COL1_T12, mult_result;
GO

-- CTE with complex calculations breaching precision/scale limits
WITH cte_complex AS (
    SELECT 
        COL1_T12,
        (COL2_T12 * COL3_T12) / (COL4_T12 + COL5_T12) AS complex_result_1,
        (COL6_T12 * COL6_T12) + (COL2_T12 * COL2_T12) AS complex_result_2,
        (COL3_T12 / COL4_T12) * (COL5_T12 + COL6_T12) AS complex_result_3
    FROM BABEL_5454_T11
)
SELECT 
    COL1_T12,
    complex_result_1,
    complex_result_2,
    complex_result_3
FROM cte_complex
ORDER BY COL1_T12;
GO

-- CTE with window , aggerate and operations breaching precision/scale
WITH cte_window AS (
    SELECT 
        COL1_T12,
        COL2_T12,
        COL3_T12,
        SUM(COL2_T12) OVER (ORDER BY COL1_T12) AS running_sum,
        AVG(COL3_T12) OVER (ORDER BY COL1_T12) AS running_avg
    FROM BABEL_5454_T11
)
SELECT 
    COL1_T12,
    running_sum / COL2_T12 AS ratio_1,
    running_avg * COL3_T12 AS product_1,
    running_sum + running_avg AS sum_1
FROM cte_window
ORDER BY COL1_T12;
GO

