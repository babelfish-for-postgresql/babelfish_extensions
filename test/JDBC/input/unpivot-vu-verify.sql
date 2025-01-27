--Basic UNPIVOT Tests

    -- Basic column unpivoting
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

    -- With square brackets notation
SELECT [customer_id], turnover AS [sales value], [time period] 
FROM [customer_turnover] 
UNPIVOT (turnover FOR [time period] IN ([q1],[q2],[q3],[q4])) AS [unpvt alias];
GO

    -- With explicit column aliases
SELECT customer_id AS ID, turnover AS Amount, quarter AS [Time Line] 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

-- Target List Variations
    -- SELECT *
SELECT * FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

    -- Mixed join and unpivoted columns
SELECT c.customer_name, u.turnover, u.quarter 
FROM customer_info c 
JOIN customer_turnover t 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS u 
ON c.customer_id = u.customer_id;
GO

    -- With computed columns
SELECT 
    customer_id,
    turnover * 1.1 AS adjusted_turnover,
    CAST(quarter AS VARCHAR(10)) AS quarter_name
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO


-- CONSECUTIVE UNPIVOTS

    -- two consecutive unpivots
SELECT r.product_id AS PID,
       RIGHT(r.col_name, 2) as [Time Period],
       r.quantity,
       r.revenue 
FROM product_sales p 
UNPIVOT (quantity for col_name in (quantity_q1, quantity_q2)) AS q 
UNPIVOT (revenue for col_name1 in (revenue_q1, revenue_q2)) AS r 
WHERE RIGHT(r.col_name, 2) = RIGHT(r.col_name1, 2) AND r.product_desc IS NOT NULL;
GO


-- DATA TYPES
    -- NUMERIC
        -- 1. BIT type UNPIVOT
SELECT id, bit_value, bit_name
FROM all_numeric_types
UNPIVOT ( bit_value FOR bit_name IN (bit_val1, bit_val2, bit_val3)) AS bit_unpvt;

        -- 2. DECIMAL and NUMERIC UNPIVOT
SELECT id, decimal_value, decimal_name, numeric_value, numeric_name
FROM all_numeric_types
UNPIVOT ( decimal_value FOR decimal_name IN (decimal_val1, decimal_val2)) AS decimal_unpvt
UNPIVOT ( numeric_value FOR numeric_name IN (numeric_val1, numeric_val2)) AS numeric_unpvt;

        -- 3. FLOAT and REAL UNPIVOT
SELECT * FROM (
    SELECT id, float_value, float_name 
    FROM all_numeric_types
    UNPIVOT ( float_value FOR float_name IN (float_val1, float_val2)) AS float_unpvt
) t1
CROSS JOIN (
    SELECT id, real_value, real_name
    FROM all_numeric_types
    UNPIVOT ( real_value FOR real_name IN (real_val1, real_val2)) AS real_unpvt
) t2;

        -- 4. BIGINT, INT, SMALLINT UNPIVOT
SELECT id, bigint_value, bigint_name, int_value, int_name, smallint_value, smallint_name, tinyint_value, tinyint_name 
FROM all_numeric_types
UNPIVOT ( bigint_value FOR bigint_name IN (bigint_val1, bigint_val2)) AS bigint_unpvt 
UNPIVOT ( int_value FOR int_name IN (int_val1, int_val2)) AS int_unpvt 
UNPIVOT ( smallint_value FOR smallint_name IN (smallint_val1,smallint_val2)) AS smallint_unpvt 
UNPIVOT ( tinyint_value FOR tinyint_name IN (tinyint_val1, tinyint_val2)) AS tinyint_unpvt;

        -- 5. MONEY and SMALLMONEY UNPIVOT
SELECT 
    m.id,
    m.name as money_name,
    m.money_value,
    s.name as smallmoney_name,
    s.smallmoney_value 
FROM 
    (SELECT * FROM all_numeric_types
     UNPIVOT (money_value FOR name IN (money_val1, money_val2)) AS money_unpvt) m 
JOIN 
    (SELECT * FROM all_numeric_types 
     UNPIVOT (smallmoney_value FOR name IN (smallmoney_val1, smallmoney_val2)) AS smallmoney_unpvt) s 
ON m.id = s.id 
    AND RIGHT(m.name, 1) = RIGHT(s.name, 1) 
    ORDER BY m.id, s.name;

    -- STRING TYPES
        -- 1. CHAR (fixed-length), VARCHAR (variable-length) (non-Unicode)
SELECT id, char_value, char_name, varchar_value, varchar_name
FROM string_types
UNPIVOT ( char_value FOR char_name IN (char_val1, char_val2, char_val3)) AS char_unpvt 
UNPIVOT ( varchar_value FOR varchar_name IN (varchar_val1, varchar_val2, varchar_val3)) AS varchar_unpvt;

        -- 2. NCHAR (fixed-length), NVARCHAR (variable-length)  (Unicode)
SELECT 
    id,
    nchar_value,
    nchar_name,
    CASE nchar_name
        WHEN 'nchar_val1' THEN 'Primary Value'
        WHEN 'nchar_val2' THEN 'Secondary Value'
        WHEN 'nchar_val3' THEN 'Tertiary Value'
        ELSE 'Unknown Value'
    END AS nchar_value_type,
    nvarchar_value,
    nvarchar_name 
FROM string_types 
UNPIVOT ( nchar_value FOR nchar_name IN (nchar_val1, nchar_val2, nchar_val3)) AS nchar_unpvt 
UNPIVOT ( nvarchar_value FOR nvarchar_name IN (nvarchar_val1, nvarchar_val2, nvarchar_val3)) AS nvarchar_unpvt;


        -- 3. TEXT UNPIVOT (large non-Unicode), NTEXT UNPIVOT (large Unicode)
SELECT 
    t.id,
    t.name as [Text name],
    text_value,
    nt.name as [NText name],
    ntext_value 
FROM 
    (SELECT * FROM string_types 
     UNPIVOT (text_value FOR name IN (text_val1, text_val2)) AS text_unpvt) t 
JOIN 
    (SELECT * FROM string_types 
     UNPIVOT (ntext_value FOR name IN (ntext_val1, ntext_val2)) AS ntext_unpvt) nt 
ON t.id = nt.id 
AND RIGHT(t.name, 1) = RIGHT(nt.name, 1) 
ORDER BY t.id, nt.name;


-- BASIC CLAUSES

    -- 1. WHERE Clause
        -- Basic WHERE on unpivoted column
SELECT customer_desc, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt  
WHERE turnover > 200;
        
        -- Complex WHERE with multiple conditions
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
WHERE CAST(turnover AS DECIMAL(10,2)) > 150.00 
    AND quarter IN ('q1', 'q2') 
    AND unpvt.customer_id < 1000;

        -- WHERE clause containing unpivot subquery
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS t 
WHERE turnover > ( 
    SELECT AVG(turnover) 
    FROM customer_turnover 
    UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS t2 
    WHERE t2.quarter = t.quarter 
);

    -- 2. GROUP BY Clause
        -- GROUP BY with multiple columns
SELECT customer_type, quarter, 
       COUNT(*) as count,
       AVG(turnover) as avg_turnover 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
GROUP BY customer_type, quarter;

        -- GROUP BY with HAVING
SELECT 
    customer_type,
    quarter,
    COUNT(*) as transaction_count,
    SUM(turnover) as total_turnover 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
GROUP BY customer_type, quarter 
HAVING COUNT(*) > 1 AND SUM(turnover) > 500;

    -- 3. ORDER BY Clause
        -- Multiple column ORDER BY
SELECT customer_id, turnover, quarter
FROM customer_turnover
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt
ORDER BY customer_id ASC, quarter DESC, turnover;

        -- ORDER BY with expressions
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY RIGHT(quarter, 1), turnover * 1.1;

    -- 4. TOP Clause
        -- Simple TOP
SELECT TOP 5 customer_id, turnover, quarter
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY turnover DESC;

        -- OFFSET-FETCH
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY turnover DESC 
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;


-- ERROR CONDITIONS