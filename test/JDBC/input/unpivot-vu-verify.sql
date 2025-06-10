-- Basic UNPIVOT Tests

    -- Basic column unpivoting
SELECT customer_id, turnover, quarter FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

    -- Order preservation of unpivot source columns
SELECT customer_id, turnover, quarter FROM customer_turnover ct
UNPIVOT (turnover FOR quarter IN (q4, q3, q2, q1)) AS unpvt;
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

SELECT unpvt.* FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

SELECT unpvt.* 
FROM (customer_turnover c JOIN product_sales p ON p.product_id = c.customer_id) 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

SELECT 
    p.*, 
    unpvt.* 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
JOIN product_sales p ON p.product_id = unpvt.customer_id;
GO

SELECT 
    p.*, 
    u1.*, 
    u2.* 
FROM customer_turnover t1 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS u1 
JOIN product_sales p 
    ON p.product_id = u1.customer_id 
    AND p.revenue_q1 > 1000.00 
JOIN revenue_data t2 
UNPIVOT (revenue FOR quarter2 IN (q1_sales, q2_sales)) AS u2 
    ON u1.customer_id = u2.id
    AND u1.quarter = SUBSTRING(u2.quarter2, 1, 2)
    AND turnover > 100;
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

    -- CASE
SELECT 
    unpvt.customer_id AS [ID],
    [unpvt].[turnover],
    [unpvt].[quarter],
    CASE [unpvt].[quarter]
        WHEN 'q1' THEN 'First'
        WHEN 'q2' THEN 'Second'
        WHEN 'q3' THEN 'Third'
        WHEN 'q4' THEN 'Fourth'
    END AS [Quarter Name]
FROM customer_turnover
UNPIVOT ([turnover] FOR [quarter] IN ([q1], [q2], [q3], [q4])) AS unpvt;
GO

-- CONSECUTIVE UNPIVOTS
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
FROM numeric_types
UNPIVOT ( bit_value FOR bit_name IN (bit_val1, bit_val2, bit_val3)) AS bit_unpvt;
GO

        -- 2. DECIMAL and NUMERIC UNPIVOT
SELECT id, decimal_value, decimal_name, numeric_value, numeric_name
FROM numeric_types
UNPIVOT ( decimal_value FOR decimal_name IN (decimal_val1, decimal_val2)) AS decimal_unpvt
UNPIVOT ( numeric_value FOR numeric_name IN (numeric_val1, numeric_val2)) AS numeric_unpvt;
GO

        -- 3. FLOAT and REAL UNPIVOT
SELECT * FROM (
    SELECT id, float_value, float_name 
    FROM numeric_types
    UNPIVOT ( float_value FOR float_name IN (float_val1, float_val2)) AS float_unpvt
) t1
CROSS JOIN (
    SELECT id, real_value, real_name
    FROM numeric_types
    UNPIVOT ( real_value FOR real_name IN (real_val1, real_val2)) AS real_unpvt
) t2;
GO

        -- 4. BIGINT, INT, SMALLINT UNPIVOT
SELECT id, bigint_value, bigint_name, int_value, int_name, smallint_value, smallint_name, tinyint_value, tinyint_name 
FROM numeric_types
UNPIVOT ( bigint_value FOR bigint_name IN (bigint_val1, bigint_val2)) AS bigint_unpvt 
UNPIVOT ( int_value FOR int_name IN (int_val1, int_val2)) AS int_unpvt 
UNPIVOT ( smallint_value FOR smallint_name IN (smallint_val1,smallint_val2)) AS smallint_unpvt 
UNPIVOT ( tinyint_value FOR tinyint_name IN (tinyint_val1, tinyint_val2)) AS tinyint_unpvt
WHERE RIGHT(bigint_name, 1) = RIGHT(int_name, 1)
    AND RIGHT(int_name, 1) = RIGHT(smallint_name, 1)
    AND RIGHT(smallint_name, 1) = RIGHT(tinyint_name, 1);
GO

        -- 5. MONEY and SMALLMONEY UNPIVOT
SELECT 
    m.id,
    m.name as money_name,
    m.money_value,
    s.name as smallmoney_name,
    s.smallmoney_value 
FROM 
    (SELECT * FROM numeric_types
     UNPIVOT (money_value FOR name IN (money_val1, money_val2)) AS money_unpvt) m 
JOIN 
    (SELECT * FROM numeric_types 
     UNPIVOT (smallmoney_value FOR name IN (smallmoney_val1, smallmoney_val2)) AS smallmoney_unpvt) s 
ON m.id = s.id 
    AND RIGHT(m.name, 1) = RIGHT(s.name, 1) 
    ORDER BY m.id, s.name;
GO

    -- STRING TYPES
        -- 1. CHAR (fixed-length), VARCHAR (variable-length) (non-Unicode)
SELECT id, char_value, char_name, varchar_value, varchar_name
FROM string_types
UNPIVOT ( char_value FOR char_name IN (char_val1, char_val2, char_val3)) AS char_unpvt 
UNPIVOT ( varchar_value FOR varchar_name IN (varchar_val1, varchar_val2, varchar_val3)) AS varchar_unpvt;
GO

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
UNPIVOT ( nvarchar_value FOR nvarchar_name IN (nvarchar_val1, nvarchar_val2, nvarchar_val3)) AS nvarchar_unpvt
WHERE RIGHT(nchar_name, 1) = RIGHT(nvarchar_name, 1);
GO

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
ON t.id = nt.id AND RIGHT(t.name, 1) = RIGHT(nt.name, 1) 
ORDER BY t.id, nt.name;
GO

    -- DATE AND TIME TYPES UNPIVOT with UNION
SELECT id, 'DATE' as data_type, date_name as column_name, CAST(date_value AS VARCHAR(50)) as date_value 
FROM datetime_types 
UNPIVOT ( date_value FOR date_name IN (date_val1, date_val2)) AS date_unpvt 

UNION ALL 

SELECT id, 'DATETIME' as data_type, datetime_name, CAST(datetime_value AS VARCHAR(50)) 
FROM datetime_types 
UNPIVOT ( datetime_value FOR datetime_name IN (datetime_val1, datetime_val2)) AS datetime_unpvt 

UNION ALL 

SELECT id, 'DATETIME2' as data_type, datetime2_name, CAST(datetime2_value AS VARCHAR(50)) 
FROM datetime_types 
UNPIVOT ( datetime2_value FOR datetime2_name IN (datetime2_val1, datetime2_val2)) AS datetime2_unpvt 

UNION ALL 

SELECT id, 'DATETIMEOFFSET' as data_type, datetimeoffset_name, CAST(datetimeoffset_value AS VARCHAR(50)) 
FROM datetime_types 
UNPIVOT ( datetimeoffset_value FOR datetimeoffset_name IN (datetimeoffset_val1, datetimeoffset_val2)) AS datetimeoffset_unpvt 

UNION ALL 

SELECT id, 'SMALLDATETIME' as data_type, smalldatetime_name, CAST(smalldatetime_value AS VARCHAR(50)) 
FROM datetime_types 
UNPIVOT ( smalldatetime_value FOR smalldatetime_name IN (smalldatetime_val1, smalldatetime_val2) ) AS smalldatetime_unpvt 

UNION ALL 

SELECT id, 'TIME' as data_type, time_name, CAST(time_value AS VARCHAR(50)) 
FROM datetime_types 
UNPIVOT ( time_value FOR time_name IN (time_val1, time_val2)) AS time_unpvt 

ORDER BY id, data_type, column_name;
GO

-- JOIN Operations
    -- 1. INNER JOIN
SELECT c.customer_name, u.turnover, u.quarter 
FROM customer_info c 
JOIN customer_turnover t 
UNPIVOT (turnover FOR quarter IN (q4, q3, q1, q2)) AS u 
ON c.customer_id = u.customer_id;
GO

    -- 2. LEFT JOIN
SELECT u.customer_id, u.customer_name, u.turnover, u.quarter, c2.customer_segment 
FROM (
    SELECT t.*, c.customer_name, c.customer_segment
    FROM customer_turnover t
    LEFT JOIN customer_info c ON t.customer_id = c.customer_id 
) AS ct 
UNPIVOT ( turnover FOR quarter IN (q3, q1, q2, q4)) AS u 
LEFT JOIN customer_info c2 ON u.customer_id = c2.customer_id;
GO

    -- 3. CROSS JOIN
SELECT c.customer_name, u.customer_desc, u.turnover, u.quarter
FROM customer_info c
CROSS JOIN (
    SELECT customer_id, customer_desc, turnover, quarter
    FROM customer_turnover
    UNPIVOT (turnover FOR quarter IN (q2, q4, q3, q1)) AS unpvt
) u
WHERE u.customer_id = c.customer_id and u.customer_id = 2;
GO

    -- 4. CROSS APPLY (Equivalent to Postgres’ CROSS JOIN LATERAL)
SELECT c.customer_name, u.customer_desc, u.turnover, u.quarter 
FROM customer_info c 
CROSS APPLY (
    SELECT customer_id, customer_desc, turnover, quarter
    FROM customer_turnover
    UNPIVOT (turnover FOR quarter IN (q3, q4, q2, q1)) AS unpvt
    WHERE customer_id = c.customer_id
) u 
WHERE c.customer_id = 1;
GO

    -- 5. Multiple Joins
SELECT c.customer_name, u1.turnover as quarterly_turnover, u2.quarter as revenue_quarter 
FROM customer_turnover t1 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS u1 
JOIN customer_info c ON c.customer_id = u1.customer_id and c.customer_segment = 'Premium' 
JOIN customer_turnover t2 
UNPIVOT (revenue FOR quarter IN (q1, q2, q3, q4)) AS u2
    ON u1.customer_id = u2.customer_id
    AND RIGHT(u1.quarter, 1) = RIGHT(u2.quarter, 1)
    AND turnover > 100;
GO

    -- 6. Grouped Join
SELECT * 
FROM (product_info c
  JOIN customer_turnover t 
  ON c.product_id = t.customer_id)
UNPIVOT (turnover FOR quarter IN 
        (product_id, q3, q1, q2)
) AS u;
GO

    -- 7. UNPIVOT Subquery in JOIN
SELECT * FROM product_info p 
JOIN (
    SELECT product_id, sales, quarter
    FROM sales_data
    UNPIVOT (
        sales FOR quarter IN (q1_sales, q2_sales)
    ) AS inner_unpvt 
) u ON p.product_id = u.product_id;
GO

-- CTE
    -- 1. CTE as unpivot source
WITH QuarterlyData AS (
    SELECT customer_id, q1, q2, q3, q4
    FROM customer_turnover
    WHERE customer_type = 'R'
) 
SELECT * FROM QuarterlyData 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

    -- 2. Unpivot within CTE
WITH QuarterlyData AS (
    SELECT * FROM customer_turnover
    UNPIVOT (sales FOR month IN (q1, q2, q3, q4)) AS t2
    WHERE customer_type = 'P'
)
SELECT * FROM QuarterlyData;
GO

    -- 3. Recursive CTE
WITH RecursiveSales AS (
    SELECT 
        id,
        parent_id,
        q1, q2, q3, q4,
        0 as level,
        CAST(id AS VARCHAR(100)) as path
    FROM SalesHierarchy
    WHERE parent_id IS NULL

    UNION ALL

    SELECT 
        s.id,
        s.parent_id,
        s.q1, s.q2, s.q3, s.q4,
        r.level + 1,
        CAST(r.path + '->' + CAST(s.id AS VARCHAR(10)) AS VARCHAR(100))
    FROM SalesHierarchy s
    INNER JOIN RecursiveSales r ON s.parent_id = r.id
) 
SELECT path, level, quarter, sales 
FROM RecursiveSales 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY path, quarter;
GO

    -- 4. Multiple CTEs, multiple unpivots
WITH QuantityCTE AS (
    SELECT product_id, quarter, quantity FROM cte_product_sales
    UNPIVOT (quantity FOR quarter IN (q1_quantity, q2_quantity, q3_quantity, q4_quantity)) AS unpvt_qty
),
RevenueCTE AS (
    SELECT product_id, quarter, revenue FROM cte_product_revenue
    UNPIVOT (revenue FOR quarter IN (q1_revenue, q2_revenue, q3_revenue, q4_revenue)) AS unpvt_rev
),
CombinedCTE AS (
    SELECT 
        q.product_id,
        p.product_name,
        SUBSTRING(q.quarter, 2, 1) as quarter_num,
        CAST(q.quantity AS DECIMAL(10,2)) as quantity,
        CAST(r.revenue AS DECIMAL(10,2)) as revenue,
        CAST((CAST(r.revenue AS DECIMAL(10,2)) / CAST(q.quantity AS DECIMAL(10,2))) AS DECIMAL(10,2)) as price_per_unit
    FROM QuantityCTE q
    JOIN cte_product_sales p ON q.product_id = p.product_id
    JOIN RevenueCTE r ON q.product_id = r.product_id 
        AND SUBSTRING(q.quarter, 2, 1) = SUBSTRING(r.quarter, 2, 1)
)
SELECT * FROM CombinedCTE 
UNPIVOT (metric_value FOR metric_type IN (quantity, revenue, price_per_unit)) AS final_unpvt 
ORDER BY product_id, quarter_num, metric_type;
GO

-- BASIC CLAUSES

    -- 1. WHERE Clause
        -- Basic WHERE on unpivoted column
SELECT customer_desc, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt  
WHERE turnover > 200;
GO
        
        -- Complex WHERE with multiple conditions
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
WHERE CAST(turnover AS DECIMAL(10,2)) > 150.00 
    AND quarter IN ('q1', 'q2') 
    AND unpvt.customer_id < 1000;
GO

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
GO

    -- 2. GROUP BY Clause
        -- GROUP BY with multiple columns
            -- (Needs ORDER BY to avoid unexpected ordering while grouping (PG behavior))
SELECT customer_type, quarter, 
       COUNT(*) as count,
       AVG(turnover) as avg_turnover 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
GROUP BY customer_type, quarter
ORDER BY customer_type, quarter DESC;
GO

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
GO

    -- 3. ORDER BY Clause
        -- Multiple column ORDER BY
SELECT customer_id, turnover, quarter
FROM customer_turnover
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt
ORDER BY customer_id ASC, turnover, quarter DESC;
GO

        -- ORDER BY with expressions
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY RIGHT(quarter, 1), turnover * 1.1;
GO

    -- 4. TOP Clause
        -- Simple TOP
SELECT TOP 5 customer_id, turnover, quarter
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY turnover DESC;
GO

        -- OFFSET-FETCH
SELECT customer_id, turnover, quarter 
FROM customer_turnover 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY turnover DESC 
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
GO


-- SOURCE OBJECT TYPES
    -- 1. Temporary Objects
        -- 1.1 TEMP TABLE
CREATE TABLE #temp_sales ( 
    id INT, 
    product_name VARCHAR(50), 
    q1_sales DECIMAL(10,2), 
    q2_sales DECIMAL(10,2));

INSERT INTO #temp_sales VALUES
(1, 'Product A', 100.50, 0),
(2, 'Product B', NULL, 300.00),
(3, 'Product C', NULL, NULL);

SELECT id, product_name, sales_amount, quarter 
FROM #temp_sales 
UNPIVOT ( sales_amount FOR quarter IN (q1_sales, q2_sales)) AS unpvt;
GO

        -- 1.2 TEMPORARY VARIABLES
DECLARE @sales_data TABLE (
    id INT,
    region VARCHAR(20),
    jan_rev MONEY,
    feb_rev MONEY
);
INSERT INTO @sales_data VALUES
(1, 'North', $1000.00, 0),
(2, 'South', $800, NULL);

SELECT id, region, revenue, month 
FROM @sales_data 
UNPIVOT ( revenue FOR month IN (jan_rev, feb_rev)) AS unpvt;
GO

    -- 2. Schema Objects

        -- 2.1 UNPIVOT on schema-qualified table
SELECT product_id, product_name, sales_amount, quarter 
FROM sales.quarterly_data 
UNPIVOT ( sales_amount FOR quarter IN (q1_sales, q2_sales, q4_sales, q3_sales)) AS unpvt 
WHERE quarter = 'q3_sales' OR quarter = 'q4_sales'; 
GO

        -- 2.2 Views - Create view with UNPIVOT
CREATE VIEW sales.sales_analysis_view AS
SELECT 
    product_id, 
    product_name,
    CAST(sales_amount * 1.1 AS DECIMAL(10,2)) as adjusted_sales,
    quarter,
    CASE 
        WHEN quarter = 'q1_sales' THEN 'First'
        WHEN quarter = 'q2_sales' THEN 'Second'
        WHEN quarter = 'q3_sales' THEN 'Third'
        WHEN quarter = 'q4_sales' THEN 'Fourth'
    END as quarter_name
FROM sales.quarterly_data
UNPIVOT ( sales_amount FOR quarter IN (q1_sales, q2_sales, q3_sales, q4_sales)) AS unpvt;
GO

SELECT * FROM sales.sales_analysis_view;
GO

SELECT * FROM sales.quarterly_view 
UNPIVOT (turnover FOR quarter IN (q1_sales, q2, q3, q4)) AS unpvt;
GO

-- SUBQURIES
    -- 1. IN/EXISTS
SELECT * FROM customer_turnover 
WHERE customer_id IN (
    SELECT customer_id FROM customer_turnover
    UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt
    WHERE sales > 300
);
GO

SELECT * FROM customer_turnover ct 
WHERE EXISTS (
    SELECT 1
    FROM customer_turnover
    UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt
    WHERE unpvt.customer_id = ct.customer_id
    AND sales = 0
);
GO

    -- 2. Correlated Subqueries
SELECT ct.customer_id,
    (SELECT TOP 1 sales
     FROM (SELECT customer_id, sales
           FROM customer_turnover
           UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS u
           WHERE customer_id = ct.customer_id) AS sub
     ORDER BY sales DESC) as highest_quarterly_sales 
FROM customer_turnover ct;
GO

    -- 3. Derived Tables
SELECT * FROM (
    SELECT 
        customer_id,
        customer_type,
        q1 * 1.1 as q1_adj,
        q2 * 1.1 as q2_adj,
        q3 * 1.1 as [q3 adj]
    FROM customer_turnover
    WHERE customer_type = 'R'
) AS source 
UNPIVOT ( adjusted_turnover FOR quarter IN (q1_adj, [q3 adj])) AS u;
GO

-- Different source types
    -- 1. Using a table-valued function as source
CREATE FUNCTION dbo.GetSalesData() 
RETURNS TABLE 
AS 
RETURN ( SELECT product_id, q1_sales, q2_sales  FROM sales_data );
GO

SELECT * FROM dbo.GetSalesData()
UNPIVOT ( sales FOR quarter IN (q1_sales, q2_sales)) AS unpvt;
GO

    -- 2. Using OPENJSON as source
DECLARE @json NVARCHAR(MAX) = N'{
    "product_id": 1,
    "q1_sales": 100,
    "q2_sales": 200,
    "q3_sales": 300,
    "q4_sales": 400
}';

SELECT product_id, quarter, sales
FROM OPENJSON(@json) WITH (
    product_id INT,
    q1_sales INT,
    q2_sales INT,
    q3_sales INT,
    q4_sales INT
)
UNPIVOT (
    sales FOR quarter IN (q1_sales, q2_sales, q3_sales, q4_sales)
) AS unpvt;
GO


-- PROCEDURE containing unpivot 

CREATE PROCEDURE dbo.GetQuarterlyTotal
    @Quarter VARCHAR(2),
    @TotalSales DECIMAL(10,2) OUTPUT 
AS 
BEGIN
    SELECT @TotalSales = SUM(sales)
    FROM customer_turnover
    UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt
    WHERE quarter = @Quarter;
END;
GO

DECLARE @Result DECIMAL(10,2);
EXEC dbo.GetQuarterlyTotal 'q1', @Result OUTPUT;
SELECT @Result AS Q1Total;
GO

-- DYNAMIC UNPIVOT
DECLARE @cols NVARCHAR(MAX) = '';
DECLARE @unpivotSql NVARCHAR(MAX);

SELECT @cols = @cols + ',' + QUOTENAME(column_name) 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'customer_turnover' 
AND column_name LIKE 'q[1-4]' 
ORDER BY column_name;
SET @cols = SUBSTRING(@cols, 2, LEN(@cols));

SET @unpivotSql = N'
SELECT customer_id, customer_desc, customer_type, quarter, sales 
FROM customer_turnover 
UNPIVOT (
    sales FOR quarter IN (' + @cols + ')
) AS unpvt';
EXEC sp_executesql @unpivotSql;
GO


-- DML
    
    -- 1. INSERT
        -- INSERT INTO SELECT
INSERT INTO customer_quarterly_sales 
SELECT customer_id, customer_desc, customer_type, quarter, sales 
FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt WHERE sales < 200;
GO

SELECT * from customer_quarterly_sales;
GO
        -- SELECT INTO
SELECT customer_id, customer_desc, customer_type, quarter, sales 
INTO #new_quarterly_sales 
FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2)) AS unpvt;

SELECT * from #new_quarterly_sales;
GO

    -- 2. UPDATE
        -- Basic UPDATE
UPDATE customer_quarterly_sales 
SET sales = sales * 1.1 
FROM (
    SELECT customer_id, quarter, turnover FROM customer_turnover
    UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt
    WHERE turnover BETWEEN 100 AND 200
) AS source 
WHERE customer_quarterly_sales.customer_id = source.customer_id 
AND customer_quarterly_sales.quarter = source.quarter 
AND customer_quarterly_sales.sales = source.turnover;
GO

SELECT * FROM customer_quarterly_sales;
GO

        -- UPDATE with join
UPDATE cqs 
SET cqs.sales = cqs.sales * 1.2 
FROM customer_quarterly_sales cqs 
JOIN (
    SELECT customer_id, quarter, sales FROM customer_turnover
    UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt
) AS source 
ON cqs.customer_id = source.customer_id 
AND cqs.quarter = source.quarter 
AND cqs.sales > 150;
GO

SELECT * FROM customer_quarterly_sales;
GO

        -- UPDATE with Subquery
UPDATE customer_quarterly_sales 
SET sales = sales * 1.5 
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM customer_turnover 
    UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt
    WHERE sales > 300
);
GO

SELECT * FROM customer_quarterly_sales;
GO

    -- 3. DELETE

        -- DELETE with Subquery
DELETE FROM customer_quarterly_sales 
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM customer_turnover
    UNPIVOT (
        sales FOR quarter IN (q1, q2, q3, q4)
    ) AS unpvt
    WHERE sales = 0
);
GO

        -- DELETE with JOIN
DELETE cqs 
FROM customer_quarterly_sales cqs 
JOIN (
    SELECT customer_id, quarter, sales
    FROM customer_turnover
    UNPIVOT (
        sales FOR quarter IN (q1, q2, q3, q4)
    ) AS unpvt
    WHERE sales < 120
) AS source 
ON cqs.customer_id = source.customer_id 
AND cqs.quarter = source.quarter;
GO

-- SET Operations
    -- 1. UNION
        -- UNION: Combines quarterly sales from both years, removing duplicates
SELECT customer_id, customer_desc, quarter, sales FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
UNION 
SELECT customer_id, customer_desc, quarter, sales FROM customer_turnover_2024 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY customer_id, quarter;
GO

        -- UNION ALL (keeps duplicates)
SELECT customer_id, customer_desc, quarter, sales FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
UNION ALL 
SELECT customer_id, customer_desc, quarter, sales FROM customer_turnover_2024 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY customer_id, quarter;
GO

    -- 2. INTERSECT
        -- Shows quarterly sales that are identical in both years
SELECT customer_id, quarter, sales FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
INTERSECT 
SELECT customer_id, quarter, sales FROM customer_turnover_2024 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY customer_id, quarter;
GO

    -- 3. EXCEPT
        -- Shows quarterly sales that exist in first table but not in second
SELECT customer_id, quarter, sales FROM customer_turnover 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
EXCEPT 
SELECT customer_id, quarter, sales FROM customer_turnover_2024 
UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4)) AS unpvt 
ORDER BY customer_id, quarter;
GO

-- Table-Valued Function Test
CREATE FUNCTION dbo.fn_UnpivotSales() 
RETURNS TABLE 
AS 
RETURN 
(
    SELECT product_id, sales, quarter FROM sales_data
    UNPIVOT (sales FOR quarter IN (q1_sales, q2_sales)) AS unpvt 
    WHERE product_id = 1
);
GO

SELECT * FROM dbo.fn_UnpivotSales();
GO

-- ERROR CONDITIONS

    -- Column names clashing (ambiguous usage)
        -- Test: Join with specific columns with potential conflict
SELECT customer_id, customer_desc, turnover, time_period, history_id, q1, q3 
FROM customer_turnover 
UNPIVOT (turnover FOR time_period IN (q1, q2, q3, q4)) AS unpvt 
JOIN customer_history t2 ON unpvt.customer_id = t2.customer_id;
GO

    -- Unpivot without mandatory alias
SELECT * FROM customer_turnover UNPIVOT (sales FOR quarter IN (q1, q2, q3, q4));
GO

    -- Using reserved keywords
SELECT * FROM customer_turnover UNPIVOT (select FOR from IN (q1, q2)) AS u;
GO

-- Edge Cases
    -- Unpivot on empty table
SELECT customer_id, turnover, quarter FROM empty_table 
UNPIVOT (turnover FOR quarter IN (q1, q2, q3, q4)) AS unpvt;
GO

    -- Maximum length regular identifier (128 characters), col_identifier (63 characters)
SELECT * FROM very_long_table_name_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567 
UNPIVOT (value FOR column_name IN (
    very_long_column_name_q1_12345678901234567890123456789012345678, 
    very_long_column_name_q2_12345678901234567890123456789012345678
    )
) AS unpvt;
GO

    -- Test UNPIVOT with allowed special characters in identifiers
SELECT [Customer#ID], [Sales $ Amount], [Quarter@Period]
FROM [Sales$Data@2024]
UNPIVOT (
    [Sales $ Amount] FOR [Quarter@Period] IN (
        [q1$sales],
        [q2$sales],
        [q3$sales]
    )
) AS [Sales@Analysis];
GO

    -- Test UNPIVOT with non-Latin characters in column name
SELECT [ID_番号], [Amount_金額], [Quarter_四半期]
FROM [Global_データ_Sales]
UNPIVOT (
    [Amount_金額] FOR [Quarter_四半期] IN (
        [q1_売上],
        [q2_売上]
    )
) AS [Global_分析];
GO

-- Aliased column names in unpivot source list
    -- valid syntax
SELECT customer_id, turnover, quarter FROM customer_turnover c 
UNPIVOT (turnover FOR quarter IN (c.q1, c.q2, c.q3, c.q4)) AS unpvt;
GO

SELECT product_id, product_name, sales_amount, quarter 
FROM sales.quarterly_data 
UNPIVOT ( sales_amount FOR quarter IN 
                 (quarterly_data.q1_sales, q2_sales, q4_sales, q3_sales)) AS unpvt;
GO

SELECT product_id, product_name, sales_amount, quarter 
FROM sales.quarterly_data 
UNPIVOT ( sales_amount FOR quarter IN 
                 (sales.quarterly_data.q1_sales, q2_sales, q3_sales, q4_sales)) AS unpvt;
GO

SELECT product_id, product_name, sales_amount, quarter 
FROM sales.quarterly_data c_ALIAS 
UNPIVOT ( sales_amount FOR quarter IN 
                  (c_ALIAS.q1_sales, q2_sales, q4_sales, q3_sales)) AS unpvt;
GO


SELECT amount, quarter
FROM (sales_data s JOIN revenue_data r ON s.product_id = r.id)
UNPIVOT ( amount FOR quarter IN (s.q1_sales, r.q2_sales)) AS unpvt;
GO


        -- invalid syntax
SELECT product_id, product_name, sales_amount, quarter 
FROM sales.quarterly_data c_ALIAS 
UNPIVOT ( sales_amount FOR quarter IN 
                  (sales.quarterly_data.q1_sales, q2_sales, q4_sales, q3_sales)) AS unpvt;
GO

SELECT amount, quarter
FROM (sales_data s JOIN revenue_data r ON s.product_id = r.id)
UNPIVOT ( amount FOR quarter IN (s.q1_sales, r.q1_sales)) AS unpvt;
GO

SELECT * FROM customer_turnover UNPIVOT (
    amount FOR quarter IN (CAST(q1 AS DECIMAL(10,2)))) AS unpvt;
GO

SELECT * FROM customer_turnover UNPIVOT (
    amount FOR quarter IN (q2 AS [Q2 Sales])) AS unpvt;
GO

SELECT * FROM customer_turnover UNPIVOT (
    amount FOR quarter IN (MAX(q3))) AS unpvt;
GO

SELECT * FROM customer_turnover UNPIVOT (
    amount FOR quarter IN (CONVERT(numeric(10,2), q4))) AS unpvt;
GO

-- KNOWN ISSUES
    -- BABEL-5677 - Support more variations of UNPIVOT Syntax
        -- Uppercase column names in unpivot source list
SELECT [ID_番号], [Amount_金額], [Quarter_四半期]
FROM [Global_データ_Sales]
UNPIVOT (
    [Amount_金額] FOR [Quarter_四半期] IN (
        [Q1_売上],
        [Q2_売上]
    )
) AS [Global_分析];
GO