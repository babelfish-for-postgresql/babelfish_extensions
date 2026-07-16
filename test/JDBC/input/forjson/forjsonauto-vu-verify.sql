SELECT * FROM forjson_vu_v_1
GO

SELECT * FROM forjson_vu_v_2
GO

SELECT * FROM forjson_vu_v_3
GO

SELECT * FROM forjson_vu_v_4
GO

SELECT * FROM forjson_vu_v_5
GO

SELECT * FROM forjson_vu_v_6
GO

SELECT * FROM forjson_vu_v_7
GO

SELECT * FROM forjson_vu_v_8
GO

SELECT * FROM forjson_vu_v_9
GO

SELECT * FROM forjson_vu_v_10
GO

SELECT * FROM forjson_vu_v_11
GO

SELECT * FROM forjson_vu_v_12
GO

SELECT * FROM forjson_vu_v_13
GO

SELECT * FROM forjson_vu_v_14
GO

EXECUTE forjson_vu_p_1
GO

EXECUTE forjson_vu_p_2
GO

EXECUTE forjson_vu_p_3
GO

EXECUTE forjson_vu_p_4
GO

EXECUTE forjson_vu_p_5
GO

EXECUTE forjson_vu_p_6
GO

EXECUTE forjson_vu_p_7
GO

EXECUTE forjson_vu_p_8
GO

EXECUTE forjson_vu_p_9
GO

EXECUTE forjson_vu_p_10
GO

EXECUTE forjson_vu_p_11
GO

EXECUTE forjson_vu_p_12
GO

EXECUTE forjson_vu_p_13
GO

EXECUTE forjson_vu_p_14
GO

EXECUTE forjson_vu_p_15
GO

SELECT forjson_vu_f_2()
GO

INSERT INTO forjson_auto_vu_t_users VALUES (1, 'e', 'o', 'testemail3')
go

/* BABEL-5910 - Crash inside strcmp(), under buildJsonEntry() */

-- Should fail gracefully with proper error message rather than crash
SELECT 1+2 , firstname as [NULL] FROM forjson_auto_vu_t_users FOR JSON AUTO;
GO

select 1+2 as 'a' for json auto;
GO

select NULL as [NULL] from forjson_auto_vu_t_users for json auto;
GO

-- empty result set
SELECT * FROM forjson_auto_vu_t_users WHERE 1=0 FOR JSON AUTO;
GO

-- NULL testing
SELECT n1.id as "outer.id", 
       n1.data as "outer.data", 
       n2.id as "inner.id", 
       n2.ref_id as "inner.ref_id" 
FROM forjson_test_nested_1 n1 
LEFT JOIN forjson_test_nested_2 n2 ON n1.id = n2.id 
FOR JSON AUTO, INCLUDE_NULL_VALUES;
GO

--Special Unicode characters in column names
SELECT id as "parent.id", 
       column_标 as "parent.子.data" 
FROM forjson_test_unicode 
FOR JSON AUTO;
GO

-- long alias name test check
SELECT id as "ThisIsAnExtremelyLongColumnNameThatExceedsTheNormalLimitForColumnNamesInMostDatabaseSystemsIncludingPostgreSQLAndShouldTriggerOurHashKeyTruncationWarningWithoutCrashing.id"
FROM forjson_auto_vu_t_users
FOR JSON AUTO;
GO

-- ORDER BY with calculation - creates resjunk column
SELECT id, name, value FROM forjson_test_orderby ORDER BY value * 2 DESC FOR JSON AUTO;
GO

-- ORDER BY with multiple expressions - creates multiple resjunk columns
SELECT id, name, value FROM forjson_test_orderby ORDER BY SUBSTRING(name, 1, 1), value DESC FOR JSON AUTO;
GO

-- Simple GROUP BY - creates resjunk columns
SELECT category, SUM(quantity) as total_quantity, AVG(price) as avg_price FROM forjson_test_groupby GROUP BY category FOR JSON AUTO;
GO

-- GROUP BY with HAVING - creates resjunk columns with filtering
SELECT category, COUNT(*) as product_count, SUM(quantity) as total_quantity FROM forjson_test_groupby GROUP BY category
HAVING SUM(quantity) > 20 FOR JSON AUTO;
GO

-- This creates multiple resjunk columns of various types
SELECT category, 
       COUNT(*) as product_count, 
       SUM(quantity) as total_quantity,
       MAX(price) as max_price,
       MIN(price) as min_price
FROM forjson_test_groupby
GROUP BY category
ORDER BY SUM(quantity * price) DESC
FOR JSON AUTO;
GO

-- Test 13: Window functions - create resjunk columns
SELECT id, 
       value,
       ROW_NUMBER() OVER(ORDER BY value) as row_num,
       RANK() OVER(ORDER BY value) as rank_val
FROM forjson_test_orderby
ORDER BY id
FOR JSON AUTO;
GO

-- For Version Upgrade Test
EXECUTE forjson_vu_v_resjunk_orderby_groupby;
GO

EXECUTE forjson_vu_v_resjunk_window_functions;
GO

EXECUTE forjson_vu_p_resjunk_groupby_having_orderby;
GO


/* ----------- Found Incorrect cases with needs to be handled in future  -------------- */

/*
 *  Condition : Only Function in the query
 *  Expected Output: should not throw any error
 *  Actual Output: throws incorrect error message
 */ 
SELECT  b.EmployeeId
FROM dbo.forjson_auto_test_diff_cases_fn(1) as b
FOR JSON AUTO;
GO


/*
 *  Condition : FUNCTION + RELATION
 *  Actual Output: Treats Function as relation and gives incorrect output
 *  Expected Output: should treat function and relation as separate and provides different
 *                   nesting key and level for both
 */ 
SELECT  b.EmployeeId, a.salary
FROM dbo.forjson_auto_test_diff_cases_fn(1) as b, forjson_auto_test_diff_cases a
FOR JSON AUTO;
GO


---------------------------------------- Subqueries (in FROM_clause) ----------------------------------------
-- Single subquery
SELECT sub.CustomerID, sub.CompanyName
FROM (
    SELECT CustomerID, CompanyName
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
) AS sub
WHERE sub.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- Multiple subqueries with JOIN
SELECT sub1.CustomerID, sub1.CompanyName, sub2.TotalAmount
FROM (
    SELECT CustomerID, CompanyName
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
) AS sub1
JOIN (
    SELECT CustomerID, TotalAmount
    FROM forjsonauto_t_orders
    WHERE TotalAmount > 500
) AS sub2
ON sub1.CustomerID = sub2.CustomerID
FOR JSON AUTO;
GO

-- Multiple subqueries referencing same base table
SELECT o1.OrderID, o1.CustomerID, o1.TotalAmount, o2.AvgAmount
FROM (
    SELECT OrderID, CustomerID, TotalAmount
    FROM forjsonauto_t_orders
    WHERE TotalAmount > 1000
) AS o1
JOIN (
    SELECT CustomerID, AVG(TotalAmount) AS AvgAmount
    FROM forjsonauto_t_orders
    GROUP BY CustomerID
) AS o2
ON o1.CustomerID = o2.CustomerID
WHERE o1.CustomerID = 'BERGS'
FOR JSON AUTO;
GO

-- UNION subqueries
SELECT combined.CustomerID, combined.Source
FROM (
    SELECT CustomerID, 'Active' as Source
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
    UNION ALL
    SELECT CustomerID, 'International' as Source
    FROM forjsonauto_t_customers
    WHERE Country != 'USA'
) AS combined
WHERE combined.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- Two-level nesting subqueries
SELECT outer_sub.CustomerID, outer_sub.OrderCount
FROM (
    SELECT sub.CustomerID, COUNT(*) as OrderCount
    FROM (
        SELECT CustomerID, OrderID
        FROM forjsonauto_t_orders
        WHERE TotalAmount > 200
    ) AS sub
    GROUP BY sub.CustomerID
) AS outer_sub
WHERE outer_sub.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- Three-level nesting subqueries
SELECT final.CategoryName, final.ProductCount
FROM (
    SELECT level2.CategoryName, COUNT(*) as ProductCount
    FROM (
        SELECT level1.CategoryName, level1.ProductName
        FROM (
            SELECT c.CategoryName, p.ProductName, p.UnitPrice
            FROM forjsonauto_t_categories c
            JOIN forjsonauto_t_products p ON c.CategoryID = p.CategoryID
        ) AS level1
        WHERE level1.UnitPrice > 15
    ) AS level2
    GROUP BY level2.CategoryName
) AS final
WHERE final.CategoryName = 'Coffee'
FOR JSON AUTO;
GO

-- Correlated subqueries in FROM_clause
SELECT
    c.CustomerID,
    c.CompanyName,
    c.Country, 
    order_stats.total_orders,
    order_stats.avg_order_value
FROM forjsonauto_t_customers c
CROSS APPLY (
    SELECT
        COUNT(*) as total_orders, 
        AVG(TotalAmount) as avg_order_value
    FROM forjsonauto_t_orders o
    WHERE o.CustomerID = c.CustomerID
) order_stats
WHERE order_stats.total_orders > 0
AND c.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- Correlated subqueries in SELECT_clause
SELECT p.ProductName,
       c.CategoryName,
       (SELECT COUNT(*)
        FROM forjsonauto_t_orders o
        WHERE o.TotalAmount > p.UnitPrice
       ) as HigherValueOrderCount
FROM forjsonauto_t_products p
JOIN forjsonauto_t_categories c ON p.CategoryID = c.CategoryID
WHERE p.ProductName = 'Coffee Beans'
FOR JSON AUTO;
GO

-- Correlated subqueries in SELECT_clause + nested FOR JSON AUTO (inner correlated subquery reference to outer query’s sources)
SELECT
    p.ProductName,
    c.CategoryName,
    (SELECT
        o.OrderID,
        od.Quantity,
        od.UnitPrice,
        (od.Quantity * od.UnitPrice) as line_total,
        cu.CustomerID,
        p.ProductName as analyzed_product,
        c.CategoryName
    FROM forjsonauto_t_order_details od
    JOIN forjsonauto_t_orders o ON od.OrderID = o.OrderID
    JOIN forjsonauto_t_customers cu ON o.CustomerID = cu.CustomerID
    WHERE od.ProductID = p.ProductID
    AND od.Quantity >= 10
    FOR JSON AUTO
    ) as product_sales_analysis
FROM forjsonauto_t_products p
JOIN forjsonauto_t_categories c ON p.CategoryID = c.CategoryID
WHERE p.ProductName = 'Coffee Beans'
FOR JSON AUTO;
GO

-- nested FOR JSON AUTO in subquery at outer query's FROM_clause
WITH SalesData AS (
    SELECT * FROM (VALUES
        (1, 'East', '2023-01', 1000),
        (1, 'East', '2023-02', 1200),
        (2, 'West', '2023-01', 800),
        (2, 'West', '2023-02', 900)
    ) AS v(RegionId, RegionName, Period, Sales)
)
SELECT
    v.RegionId,
    v.RegionName,
    (
        SELECT
            sd.Period,
            sd.Sales,
            sd.Sales * 0.15 as Commission,
            (
                SELECT TOP 1 t.TargetValue
                FROM (VALUES
                    ('East', 1100),
                    ('West', 850)
                ) t(Region, TargetValue)
                WHERE t.Region = v.RegionName
            ) as MonthlyTarget,
            CASE
                WHEN sd.Sales >= (
                    SELECT TOP 1 t.TargetValue
                    FROM (VALUES
                        ('East', 1100),
                        ('West', 850)
                    ) t(Region, TargetValue)
                    WHERE t.Region = v.RegionName
                ) THEN 'Achieved'
                ELSE 'Not Achieved'
            END as TargetStatus
        FROM SalesData sd
        WHERE sd.RegionId = v.RegionId
        FOR JSON AUTO
    ) as MonthlyPerformance
FROM (VALUES
    (1, 'East'),
    (2, 'West')
) v(RegionId, RegionName)
WHERE v.RegionId = 1
FOR JSON AUTO;
GO

---------------------------------------- VALUES (in FROM_clause) ----------------------------------------
-- VALUES with Mixed Data Types
SELECT v.product_name, v.price, v.in_stock, v.launch_date
FROM (VALUES 
    ('New Coffee', 25.50, 1, '2024-01-15'),
    ('Premium Tea', 18.75, 0, '2024-02-20'),
    ('Energy Drink', 3.99, 1, '2024-03-10')
) AS v(product_name, price, in_stock, launch_date)
WHERE v.product_name = 'New Coffee'
FOR JSON AUTO;
GO

-- VALUES with NULL Values
SELECT v.customer_id, v.region, v.phone
FROM (VALUES 
    ('ALFKI', 'WA', '030-0074321'),
    ('BERGS', NULL, '0921-12 34 65'),
    ('NEWCO', 'CA', NULL)
) AS v(customer_id, region, phone)
WHERE v.customer_id = 'BERGS'
FOR JSON AUTO;
GO

-- VALUES Joined with Existing Tables
SELECT c.CompanyName, v.priority, v.discount_rate
FROM forjsonauto_t_customers c
JOIN (VALUES 
    ('ALFKI', 1, 0.10),
    ('BERGS', 2, 0.15),
    ('CONSH', 3, 0.05)
) AS v(customer_id, priority, discount_rate) 
ON c.CustomerID = v.customer_id
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- VALUES with Aggregation
SELECT
    v.category,
    COUNT(*) as item_count,
    AVG(v.score) as avg_score
FROM (VALUES 
    ('Electronics', 85),
    ('Electronics', 92),
    ('Beverages', 78),
    ('Beverages', 88),
    ('Beverages', 95)
) AS v(category, score)
WHERE v.category = 'Beverages'
GROUP BY v.category
FOR JSON AUTO;
GO

-- VALUES in Subquery
SELECT
    c.companyname,
    c.country
FROM forjsonauto_t_customers c
JOIN (
    VALUES
      ('ALFKI'),
      ('BERGS')
) AS v(customer_id) ON c.customerid = v.customer_id
WHERE c.companyname = 'Alfreds Inc'
FOR JSON AUTO;
GO

---------------------------------------- CTEs (in FROM_clause) ----------------------------------------
-- Single CTE (only base table reference)
WITH usa_customers
AS (
    SELECT
        CustomerID, 
        CompanyName, 
        Country
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
)
SELECT
    CustomerID,
    CompanyName
FROM usa_customers
WHERE CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- single CTE (only base table reference, nest_level > 1)
WITH usa_customers AS (
    SELECT 
        CustomerID, 
        CompanyName, 
        Country
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
)
SELECT 
    o.OrderID,
    u.CustomerID,
    u.CompanyName
FROM forjsonauto_t_orders o
JOIN usa_customers u ON o.CustomerID = u.CustomerID
WHERE o.OrderID = 10248
FOR JSON AUTO;
GO

-- two CTEs (only base table references)
WITH 
  cte AS (
    SELECT CustomerID, CompanyName 
    FROM forjsonauto_t_customers
  ),
  cte2 AS (
    SELECT CustomerID, OrderID 
    FROM forjsonauto_t_orders
  ) 
SELECT C.CustomerID, O.OrderID
FROM cte C
JOIN cte2 O
ON (C.CustomerID = O.CustomerID)
WHERE C.CustomerID = 'ALFKI'
FOR JSON AUTO
GO

-- two CTEs (w/ same source aliases inside each)
WITH high_value_orders AS (
    SELECT o.CustomerID, 
           COUNT(*) as high_order_count,
           AVG(o.TotalAmount) as avg_high_amount
    FROM forjsonauto_t_orders o
    WHERE o.TotalAmount > 1000
    GROUP BY o.CustomerID
),
all_customer_orders AS (
    SELECT o.CustomerID,
           o.OrderID,
           COUNT(*) as total_order_count
    FROM forjsonauto_t_orders o
    GROUP BY o.CustomerID, o.OrderID
)
SELECT 
    c.CustomerID,
    hvo.customerID,
    aco.customerID,
    aco.total_order_count
FROM forjsonauto_t_customers c
LEFT JOIN high_value_orders hvo ON c.CustomerID = hvo.CustomerID
LEFT JOIN all_customer_orders aco ON c.CustomerID = aco.CustomerID
WHERE aco.CustomerID IS NOT NULL
AND c.CustomerID = 'BERGS'
FOR JSON AUTO;
GO

-- two CTEs (w/ subquery inside CTEs)
WITH 
  cte AS (
    SELECT CustomerID, CompanyName 
    FROM (
      SELECT CustomerID, CompanyName, Country
      FROM forjsonauto_t_customers
      WHERE Country = 'USA'
    ) AS usa_customers
  ),
  cte2 AS (
    SELECT CustomerID, OrderID, TotalAmount
    FROM (
      SELECT CustomerID, OrderID, TotalAmount, OrderDate
      FROM forjsonauto_t_orders
      WHERE TotalAmount > 400
    ) AS large_orders
  ) 
SELECT C.CustomerID, C.CompanyName, O.OrderID, O.TotalAmount
FROM cte C
JOIN cte2 O ON (C.CustomerID = O.CustomerID)
WHERE C.CustomerID = 'ALFKI'
FOR JSON AUTO
GO

-- values (with or without alias) inside CTE
WITH priority_customers AS (
    SELECT v.customer_id, v.priority_level, v.discount_rate
    FROM (VALUES 
        ('ALFKI', 'Gold', 0.15),
        ('BERGS', 'Silver', 0.10),
        ('CONSH', 'Platinum', 0.20)
    ) AS v(customer_id, priority_level, discount_rate)
)
SELECT pc.customer_id, pc.priority_level, pc.discount_rate
FROM priority_customers pc
WHERE pc.customer_id = 'ALFKI'
FOR JSON AUTO;
GO

-- assign alias for CTE => NO new JSON nesting level
WITH 
    cte AS (SELECT 1 AS Id), 
    cte2 AS (SELECT 1 AS Id)
SELECT U.Id, O.Id
FROM cte U
LEFT JOIN cte2 O ON (U.Id = O.Id)
FOR JSON AUTO
GO

-- NO alias for simple 1 layer CTE
WITH
    cte AS(SELECT 1 AS Id), 
    cte2 AS(SELECT 1 AS Id2)
SELECT Id , Id2
FROM cte 
LEFT JOIN cte2 ON (cte.Id = cte2.Id2)
FOR JSON AUTO
GO

-- CTE created from temp table
CREATE TABLE #temp_sales (
    SalesID INT,
    CustomerID NCHAR(5),
    SalesAmount MONEY,
    SalesDate DATETIME
);

INSERT INTO #temp_sales VALUES
(1, 'ALFKI', 500.00, '2023-07-01'),
(2, 'BERGS', 750.00, '2023-07-02'),
(3, 'CONSH', 300.00, '2023-07-03'),
(4, 'ALFKI', 400.00, '2023-07-04');

WITH sales_summary AS (
    SELECT 
        CustomerID,
        COUNT(*) as TransactionCount,
        SUM(SalesAmount) as TotalSales,
        AVG(SalesAmount) as AvgSales
    FROM #temp_sales
    GROUP BY CustomerID
)
SELECT ss.CustomerID, ss.TransactionCount, ss.TotalSales, ss.AvgSales
FROM sales_summary ss
WHERE ss.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- Nested CTE: wo-w, wo-wo (outer cte w/o alias + inner cte w/ alias, outer cte w/o alias + inner cte w/o alias)
WITH cte_inner AS (
    SELECT Country, COUNT(*) as order_count
    FROM forjsonauto_t_customers 
    GROUP BY Country
),
cte1 AS (
    SELECT cin.Country, cin.order_count, p.ProductName
    FROM cte_inner cin
    JOIN forjsonauto_t_products p ON p.ProductID = 1
),
cte2 AS (
    SELECT cte_inner.Country, cte_inner.order_count, cat.CategoryName
    FROM cte_inner
    JOIN forjsonauto_t_categories cat ON cat.CategoryID = 1
)
SELECT c.CompanyName, cte1.Country, cte1.productname, cte2.Country, cte2.categoryname
FROM forjsonauto_t_customers c
JOIN cte1 ON c.Country = cte1.Country
JOIN cte2 ON c.Country = cte2.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Nested CTE: w-w, w-wo (outer cte w/o alias + inner cte w/ alias, outer cte w/o alias + inner cte w/o alias) (target entry w/ alias) (two column of inner source put in same layer)
WITH cte_inner AS (
    SELECT
        Country,
        COUNT(*) as order_count
    FROM forjsonauto_t_customers 
    GROUP BY Country
),
cte1 AS (
    SELECT
        cin.Country,
        cin.order_count as odc,
        p.ProductName
    FROM cte_inner cin
    JOIN forjsonauto_t_products p ON p.ProductID = 2
),
cte2 AS (
    SELECT
        cte_inner.Country,
        cte_inner.order_count,
        cat.CategoryName
    FROM cte_inner
    JOIN forjsonauto_t_categories cat ON cat.CategoryID = 2
)
SELECT
    c.CompanyName,
    c1.Country,
    c1.productname,
    c2.Country,
    c2.categoryname,
    c1.Country,
    c1.odc
FROM forjsonauto_t_customers c
JOIN cte1 c1 ON c.Country = c1.Country
JOIN cte2 c2 ON c.Country = c2.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Nested CTE: w-w, w-wo (outer cte w/ alias + inner cte w/ alias, outer cte w/ alias + inner cte w/o alias) accessing by ctename
WITH cte_inner AS (
    SELECT Country, COUNT(*) as order_count
    FROM forjsonauto_t_customers 
    GROUP BY Country
),
cte1 AS (
    SELECT cin.Country, cin.order_count, p.ProductName
    FROM cte_inner cin
    JOIN forjsonauto_t_products p ON p.ProductID = 3
),
cte2 AS (
    SELECT cte_inner.Country, cte_inner.order_count, cat.CategoryName
    FROM cte_inner
    JOIN forjsonauto_t_categories cat ON cat.CategoryID = 5
)
SELECT c.CompanyName, cte1.Country, cte1.productname, c2.Country, c2.categoryname
FROM forjsonauto_t_customers c
JOIN cte1 c1 ON c.Country = c1.Country
JOIN cte2 c2 ON c.Country = c2.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Nested CTE: w-w, wo-w (outer cte w/ alias + inner cte w/ alias, outer cte w/o alias + inner cte w/ alias)
WITH cte_inner AS (
    SELECT Country, COUNT(*) as order_count
    FROM forjsonauto_t_customers 
    GROUP BY Country
),
cte1 AS (
    SELECT cin.Country, cin.order_count, p.ProductName
    FROM cte_inner cin
    JOIN forjsonauto_t_products p ON p.ProductID = 4
),
cte2 AS (
    SELECT cin.Country, cin.order_count, cat.CategoryName
    FROM cte_inner cin
    JOIN forjsonauto_t_categories cat ON cat.CategoryID = 3
)
SELECT c.CompanyName, cte1.Country, cte1.productname, c2.Country, c2.categoryname
FROM forjsonauto_t_customers c
JOIN cte1 ON c.Country = cte1.Country
JOIN cte2 c2 ON c.Country = c2.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Nested CTE: w-subq, wo-subq (outer cte w/alias + inner subq w/ alias, outer cte w/oalias + inner subq w/ alias)
WITH cte_inner AS (
    SELECT Country, COUNT(*) as order_count
    FROM forjsonauto_t_customers 
    GROUP BY Country
),
cte1 AS (
    SELECT cin.Country, cin.order_count, sub.ProductName
    FROM cte_inner cin
    JOIN
    (SELECT
         ProductName
     FROM forjsonauto_t_products 
     WHERE ProductID = 1) sub ON 1=1
),
cte2 AS (
    SELECT cte_inner.Country, cte_inner.order_count, cat_sub.CategoryName
    FROM cte_inner
    JOIN
    (SELECT
         CategoryName
     FROM forjsonauto_t_categories
     WHERE CategoryID = 1) cat_sub ON 1=1
)
SELECT c.CompanyName, c1.Country, c1.productname, c2.Country, c2.categoryname
FROM forjsonauto_t_customers c
JOIN cte1 c1 ON c.Country = c1.Country
JOIN cte2 c2 ON c.Country = c2.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- alias for inner target entry, and at innermost layer, it doesn’t have a valid source
WITH cte_inner AS (
    SELECT Country1, COUNT(*) as order_count
    FROM (SELECT 'USA' as Country1) sub
    GROUP BY Country1
),
cte1 AS (
    SELECT cin.Country1 as c1C, cin.order_count, p.ProductName
    FROM cte_inner cin
    JOIN forjsonauto_t_products p ON p.ProductID = 2
)
SELECT c.CompanyName, c1.c1C, c1.productname, c1.order_count
FROM forjsonauto_t_customers c
JOIN cte1 c1 ON c.Country = c1.c1C
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- CTE with multiple-level long alias names (for checking if our hash can handle large full_src_path)
WITH cte_inner_inner AS (
    SELECT
          forjsonauto_t_customers_aaaaaa.Country,
          forjsonauto_t_orders_aaaaaa.OrderID
      FROM forjsonauto_t_customers forjsonauto_t_customers_aaaaaa 
      JOIN forjsonauto_t_orders forjsonauto_t_orders_aaaaaa
      ON forjsonauto_t_customers_aaaaaa.CustomerID = forjsonauto_t_orders_aaaaaa.CustomerID
),
cte_inner AS (
    SELECT
        cte_inner_inner_123456789012345.Country,
        cte_inner_inner_123456789012345.OrderID
    FROM cte_inner_inner cte_inner_inner_123456789012345
),
cte1 AS (
    SELECT
        cin12345678901234567890.Country,
        cin12345678901234567890.OrderID
    FROM cte_inner cin12345678901234567890
)
SELECT
    c.CompanyName,
    c123456789012345678901234567890.Country,
    c123456789012345678901234567890.OrderID
FROM forjsonauto_t_customers c
JOIN cte1 c123456789012345678901234567890 ON c.Country = c123456789012345678901234567890.Country
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- direct reference Recursive CTEs
WITH category_hierarchy AS (

    SELECT CategoryID, CategoryName, 0 as Level
    FROM forjsonauto_t_categories
    WHERE ParentCategoryID IS NULL

    UNION ALL

    SELECT c.CategoryID, c.CategoryName, ch.Level + 1
    FROM forjsonauto_t_categories c
    INNER JOIN category_hierarchy ch ON c.ParentCategoryID = ch.CategoryID
)
SELECT
    p.ProductName,
    c.CompanyName,
    ch.CategoryName,
    ch.Level
FROM category_hierarchy ch
LEFT JOIN forjsonauto_t_products p ON ch.CategoryID = p.CategoryID
LEFT JOIN forjsonauto_t_order_details od ON p.ProductID = od.ProductID
LEFT JOIN forjsonauto_t_orders o ON od.OrderID = o.OrderID
LEFT JOIN forjsonauto_t_customers c ON o.CustomerID = c.CustomerID
WHERE p.ProductName = 'Laptop'
FOR JSON AUTO;
GO

-- nested reference Recursive CTE (outer non-recursive CTE w/ alias  +  inner recursive CTE)
WITH order_tree AS (
    SELECT
        orderid,
        customerid,
        1 AS depth
    FROM forjsonauto_t_orders
    WHERE orderid = 10248

    UNION ALL

    SELECT
        o.orderid,
        o.customerid,
        ot.depth + 1
    FROM forjsonauto_t_orders o
    INNER JOIN order_tree ot
    ON o.orderid = ot.orderid + 1
    WHERE ot.depth < 2 )
,level2_cte AS (
    SELECT
        ot.orderid,
        c.companyname
    FROM order_tree ot
    JOIN forjsonauto_t_customers c
    ON ot.customerid = c.customerid )
,level3_cte AS (
    SELECT
        l2.orderid,
        l2.companyname,
        'Primary' AS ordertype
    FROM level2_cte l2 )
SELECT
    p.productname,
    l3cte.companyname,
    l3cte.orderid
FROM level3_cte l3cte
JOIN forjsonauto_t_order_details od ON l3cte.orderid = od.orderid
JOIN forjsonauto_t_products p ON od.productid = p.productid
WHERE p.productname = 'Chai'
FOR json auto;
GO

-- nested reference recursive CTE (outer non-recursive CTE w/o alias  +  inner recursive CTE)
WITH order_tree AS (
    SELECT
        orderid,
        customerid,
        1 AS depth
    FROM forjsonauto_t_orders
    WHERE orderid = 10248

    UNION ALL

    SELECT
        o.orderid,
        o.customerid,
        ot.depth + 1
    FROM forjsonauto_t_orders o
    INNER JOIN order_tree ot
    ON o.orderid = ot.orderid + 1
    WHERE ot.depth < 2 )
,level2_cte AS (
    SELECT
        ot.orderid,
        c.companyname
    FROM order_tree ot
    JOIN forjsonauto_t_customers c
    ON ot.customerid = c.customerid )
,level3_cte AS (
    SELECT
        l2.orderid,
        l2.companyname,
        'Primary' AS ordertype
    FROM level2_cte l2 )
SELECT
    p.productname,
    level3_cte.companyname,
    level3_cte.orderid
FROM level3_cte
JOIN forjsonauto_t_order_details od ON level3_cte.orderid = od.orderid
JOIN forjsonauto_t_products p ON od.productid = p.productid
WHERE p.productname = 'Chai'
FOR json auto;
GO

-- outer query w/o FOR JSON AUTO + inner query w/ FOR JSON AUTO
WITH customer_orders AS (
    SELECT c.CustomerID, c.CompanyName, o.OrderID, o.TotalAmount
    FROM forjsonauto_t_customers c
    JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID
)
SELECT subquery_result.aa
FROM (
    SELECT co.CompanyName, co.OrderID, co.TotalAmount
    FROM customer_orders co
      where co.OrderID = 10248
    FOR JSON AUTO
) AS subquery_result(aa)
GO

---------------------------------------- Different types of Targets (in SELECT_clause) ----------------------------------------
-- subquery as target (nest_level > 1)
SELECT c.CompanyName, 
       o.OrderID,
       (SELECT COUNT(*) 
        FROM forjsonauto_t_orders o2 
        WHERE o2.CustomerID = c.CustomerID
       ) as OrderCount
FROM forjsonauto_t_customers c
JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Operator Expression as target (nest_level > 1)
SELECT 
    c.CategoryName,
    p.ProductName, 
    p.UnitPrice * 2 AS doubled_price,
    p.UnitsInStock + 10 AS adjusted_stock,
    p.UnitPrice - 5 AS discounted_price
FROM forjsonauto_t_categories c
JOIN forjsonauto_t_products p ON c.CategoryID = p.CategoryID
WHERE c.CategoryID = 2
FOR JSON AUTO;
GO

-- Const Expression as target (nesting level > 1)
SELECT 
    cat.CategoryName,
    p.ProductName,
    'Premium' AS product_tier,
    0.15 AS commission_rate,
    'Active' AS status,
    2024 AS catalog_year
FROM forjsonauto_t_categories cat
JOIN forjsonauto_t_products p ON cat.CategoryID = p.CategoryID
WHERE cat.CategoryID = 2
FOR JSON AUTO;
GO

-- Function Expression as target (nest_level > 1)
SELECT 
    c.CompanyName,
    o.TotalAmount, 
    CAST('2023-01-01 12:00:00' AS DATETIME) AS time
FROM forjsonauto_t_customers c
JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID
WHERE c.CompanyName = 'Alfreds Inc'
FOR JSON AUTO;
GO

-- Coalesce Expression as target (nesting level > 1)
SELECT 
    s.SupplierName,
    w.WarehouseName,
    COALESCE(w.LastInspectionDate, '1900-01-01') as InspectionDate
FROM forjsonauto_t_inventory_schema.forjsonauto_t_suppliers s
INNER JOIN forjsonauto_t_inventory_schema.forjsonauto_t_warehouses w ON s.SupplierID = w.SupplierID
WHERE w.WarehouseID = 101
FOR JSON AUTO;
GO

-- CASE WHEN as target (nest_level > 1)
SELECT 
    cust.CompanyName,
    o.TotalAmount,
    CASE
        WHEN o.TotalAmount > 1500 THEN 'High Value'
        WHEN o.TotalAmount > 500 THEN 'Medium Value' 
        ELSE 'Low Value'
    END as OrderCategory
FROM forjsonauto_t_customers cust
INNER JOIN forjsonauto_t_orders o ON cust.CustomerID = o.CustomerID
WHERE o.Status = 'Shipped'
FOR JSON AUTO;
GO

---------------------------------------- Cases should return error ----------------------------------------
-- FOR JSON AUTO without any base table
SELECT 
    ss.value AS category,
    'Active' AS status
FROM STRING_SPLIT('Electronics,Premium,Popular', ',') ss
FOR JSON AUTO;
GO

-- nested FOR JSON AUTO, inner one doesn't have any base table
SELECT 
    p.ProductID,
    p.ProductName,
    (SELECT 
         p.UnitPrice AS price,
         'Active' AS status,
         ss.value AS category_tag
     FROM STRING_SPLIT('Electronics,Premium,Popular', ',') ss
     FOR JSON AUTO
    ) AS product_json
FROM forjsonauto_t_products p
WHERE p.CategoryID = 4
FOR JSON AUTO;
GO

---------------------------------------- sources valid for FOR JSON AUTO (test if only contain certain RTEKind as source will make MSSQL return "NO TABLE" error) ----------------------------------------
-- single RTE_RELATION as source
SELECT
    CustomerID,
    CompanyName
FROM forjsonauto_t_customers
WHERE CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- single RTE_SUBQUERY as source w/o inner sources
SELECT
    sub.id,
    sub.name 
FROM
    (SELECT
        1 as id,
        'test' as name
    ) AS sub 
FOR JSON AUTO;
GO

-- single RTE_FUNCTION as source w/o inner sources
SELECT s.value 
FROM STRING_SPLIT('apple,banana,cherry', ',') AS s 
FOR JSON AUTO;
GO

-- single RTE_CTE as source w/o inner sources
WITH cte
AS (SELECT
        1 as id,
        'test' as name
    )
SELECT
    cte.id,
    cte.name
FROM cte
FOR JSON AUTO;
GO

-- one cte in ctelist but no RTE_CTE in rtable
WITH 
    unused_cte AS (SELECT 1 as id, 'test' as name)
SELECT f.value 
FROM STRING_SPLIT('apple,banana,cherry', ',') AS f
FOR JSON AUTO;
GO

---------------------------------------- JSON structure with missing intermediate layers in output ----------------------------------------
-- base tables LEFT JOIN with 1 NULL intermediate levels
SELECT 
    c.CustomerID,
    o.OrderID,
    p.ProductName,
    od.OrderDetailID
FROM forjsonauto_t_customers c
LEFT JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID 
LEFT JOIN forjsonauto_t_order_details od ON o.OrderID = od.OrderID
LEFT JOIN forjsonauto_t_products p ON od.ProductID = p.ProductID AND p.UnitPrice > 100
WHERE c.CustomerID = 'ALFKI'
AND od.OrderDetailID = 1
FOR JSON AUTO;
GO

-- base tables LEFT JOIN with multiple NULL intermediate levels
SELECT 
    c.CustomerID,
    o.OrderID,
    p.ProductName,
    cat.CategoryName,
    s.SupplierName,
    w.WarehouseID
FROM forjsonauto_t_customers c
LEFT JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID 
LEFT JOIN forjsonauto_t_order_details od ON o.OrderID = od.OrderID
LEFT JOIN forjsonauto_t_products p ON od.ProductID = p.ProductID AND p.UnitPrice > 100
LEFT JOIN forjsonauto_t_categories cat ON p.CategoryID = cat.CategoryID AND cat.ParentCategoryID IS NULL
LEFT JOIN forjsonauto_t_inventory_schema.forjsonauto_t_suppliers s ON cat.CategoryID = s.Rating
LEFT JOIN forjsonauto_t_inventory_schema.forjsonauto_t_warehouses w ON s.SupplierID = w.SupplierID
WHERE c.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- subquery LEFT JOIN with NULL intermediate levels
SELECT 
    c.CustomerID,
    o.OrderID,
    expensive_products.ProductName,
    supplier_info.SupplierName,
    od.OrderDetailID
FROM forjsonauto_t_customers c
LEFT JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID 
LEFT JOIN forjsonauto_t_order_details od ON o.OrderID = od.OrderID
LEFT JOIN (
    SELECT p.ProductID, p.ProductName, p.CategoryID
    FROM forjsonauto_t_products p
    WHERE p.UnitPrice > 100
) expensive_products ON od.ProductID = expensive_products.ProductID
LEFT JOIN (
    SELECT s.SupplierID, s.SupplierName, s.Rating
    FROM forjsonauto_t_inventory_schema.forjsonauto_t_suppliers s
    WHERE s.Rating > 4
) supplier_info ON expensive_products.CategoryID = supplier_info.Rating
WHERE c.CustomerID = 'ALFKI'
AND od.OrderDetailID = 1
FOR JSON AUTO;
GO

-- CTE LEFT JOIN with NULL intermediate levels
WITH high_value_orders AS (
    SELECT o.CustomerID, 
           COUNT(*) as high_order_count,
           AVG(o.TotalAmount) as avg_high_amount
    FROM forjsonauto_t_orders o
    WHERE o.TotalAmount > 1000
    GROUP BY o.CustomerID
),
all_customer_orders AS (
    SELECT o.CustomerID,
           o.OrderID,
           COUNT(*) as total_order_count
    FROM forjsonauto_t_orders o
    GROUP BY o.CustomerID, o.OrderID
)
SELECT 
    c.CustomerID,
    hvo.customerID,
    aco.customerID,
    aco.total_order_count
FROM forjsonauto_t_customers c
LEFT JOIN high_value_orders hvo ON c.CustomerID = hvo.CustomerID
LEFT JOIN all_customer_orders aco ON c.CustomerID = aco.CustomerID
WHERE aco.CustomerID IS NOT NULL
AND c.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- only NULL-value columns in level 1
WITH high_value_orders AS (
    SELECT o.CustomerID,
           COUNT(*) as high_order_count,
           AVG(o.TotalAmount) as avg_high_amount
    FROM forjsonauto_t_orders o
    WHERE o.TotalAmount > 1000
    GROUP BY o.CustomerID
),
all_customer_orders AS (
    SELECT o.CustomerID,
           o.OrderID,
           COUNT(*) as total_order_count
    FROM forjsonauto_t_orders o
    GROUP BY o.CustomerID, o.OrderID
)
SELECT
    hvo.CustomerID,
    c.CustomerID,
    hvo.customerID,
    aco.customerID,
    aco.total_order_count
FROM forjsonauto_t_customers c
LEFT JOIN high_value_orders hvo ON c.CustomerID = hvo.CustomerID
LEFT JOIN all_customer_orders aco ON c.CustomerID = aco.CustomerID
WHERE aco.CustomerID IS NOT NULL
AND c.CustomerID = 'ALFKI'
FOR JSON AUTO;
GO

-- NULL-value columns in level 1 with “INCLUDE_NULL_VALUES”
WITH high_value_orders AS (
    SELECT o.CustomerID,
           COUNT(*) as high_order_count,
           AVG(o.TotalAmount) as avg_high_amount
    FROM forjsonauto_t_orders o
    WHERE o.TotalAmount > 1000
    GROUP BY o.CustomerID
),
all_customer_orders AS (
    SELECT o.CustomerID,
           o.OrderID,
           COUNT(*) as total_order_count
    FROM forjsonauto_t_orders o
    GROUP BY o.CustomerID, o.OrderID
)
SELECT
    hvo.CustomerID,
    c.CustomerID,
    hvo.customerID,
    aco.customerID,
    aco.total_order_count
FROM forjsonauto_t_customers c
LEFT JOIN high_value_orders hvo ON c.CustomerID = hvo.CustomerID
LEFT JOIN all_customer_orders aco ON c.CustomerID = aco.CustomerID
WHERE aco.CustomerID IS NOT NULL
AND c.CustomerID = 'ALFKI'
FOR JSON AUTO, INCLUDE_NULL_VALUES;
GO

-- SELECT FROM a table which value is a result of FOR JSON AUTO
SELECT * FROM JsonTable;
GO

-- FOR JSON AUTO with INSERTED in AFTER INSERT trigger — single row
INSERT INTO forjsonauto_t_trigger_test VALUES (1, 'Alice', 100);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with INSERTED — multiple rows
INSERT INTO forjsonauto_t_trigger_test VALUES (2, 'Bob', 200), (3, 'Charlie', 300);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with DELETED in AFTER DELETE trigger — single row
DELETE FROM forjsonauto_t_trigger_test WHERE ID = 1;
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with DELETED — multiple rows
DELETE FROM forjsonauto_t_trigger_test WHERE ID IN (2, 3);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with INSERTED and column subset
DISABLE TRIGGER forjsonauto_trg_insert ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_insert_subset ON forjsonauto_t_trigger_test;
GO

INSERT INTO forjsonauto_t_trigger_test VALUES (4, 'Diana', 400);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with INSERTED joined with base table
DISABLE TRIGGER forjsonauto_trg_insert_subset ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_insert_join ON forjsonauto_t_trigger_test;
GO

INSERT INTO forjsonauto_t_trigger_test VALUES (5, 'Eve', 500);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with UPDATE trigger (both inserted and deleted)
DISABLE TRIGGER forjsonauto_trg_insert_join ON forjsonauto_t_trigger_test;
GO
DISABLE TRIGGER forjsonauto_trg_delete ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_update_both ON forjsonauto_t_trigger_test;
GO

UPDATE forjsonauto_t_trigger_test SET Value = 999 WHERE ID = 4;
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with inserted JOIN deleted in UPDATE trigger (nesting behavior)
DISABLE TRIGGER forjsonauto_trg_update_both ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_update_join ON forjsonauto_t_trigger_test;
GO

UPDATE forjsonauto_t_trigger_test SET Value = 888, Name = 'Updated' WHERE ID = 5;
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with NULL values in transition table columns
DISABLE TRIGGER forjsonauto_trg_update_join ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_insert_null ON forjsonauto_t_trigger_test;
GO

INSERT INTO forjsonauto_t_trigger_test VALUES (6, NULL, NULL);
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO

-- FOR JSON AUTO with DELETED joined with base table
DISABLE TRIGGER forjsonauto_trg_insert_null ON forjsonauto_t_trigger_test;
GO
ENABLE TRIGGER forjsonauto_trg_delete_join ON forjsonauto_t_trigger_test;
GO

DELETE FROM forjsonauto_t_trigger_test WHERE ID = 6;
GO

SELECT ResultJson FROM forjsonauto_t_trigger_json_result;
GO

DELETE FROM forjsonauto_t_trigger_json_result;
GO
