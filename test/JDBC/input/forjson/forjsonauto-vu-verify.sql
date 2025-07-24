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

-- TODO: CTE still handling, will fix in next commit
-- EXECUTE forjson_vu_p_4
-- GO

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


-- ==========================================
-- Subqueries (in FROM_clause)
-- ==========================================
-- Single subquery
SELECT sub.CustomerID, sub.CompanyName
FROM (
    SELECT CustomerID, CompanyName
    FROM forjsonauto_t_customers
    WHERE Country = 'USA'
) AS sub
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
FOR JSON AUTO;
GO

-- ==========================================
-- VALUES (in FROM_clause)
-- ==========================================
-- VALUES with Mixed Data Types
SELECT v.product_name, v.price, v.in_stock, v.launch_date
FROM (VALUES 
    ('New Coffee', 25.50, 1, '2024-01-15'),
    ('Premium Tea', 18.75, 0, '2024-02-20'),
    ('Energy Drink', 3.99, 1, '2024-03-10')
) AS v(product_name, price, in_stock, launch_date)
FOR JSON AUTO;
GO

-- VALUES with NULL Values
SELECT v.customer_id, v.region, v.phone
FROM (VALUES 
    ('ALFKI', 'WA', '030-0074321'),
    ('BERGS', NULL, '0921-12 34 65'),
    ('NEWCO', 'CA', NULL)
) AS v(customer_id, region, phone)
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
FOR JSON AUTO;
GO

-- ==========================================
-- Different types of Targets (in SELECT_clause)
-- ==========================================
-- subquery as target (nest_level > 1)
SELECT c.CompanyName, 
       o.OrderID,
       (SELECT COUNT(*) 
        FROM forjsonauto_t_orders o2 
        WHERE o2.CustomerID = c.CustomerID
       ) as OrderCount
FROM forjsonauto_t_customers c
JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID
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
WHERE c.CategoryID IN (2, 4, 5) 
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
WHERE cat.CategoryID IN (2, 4, 5)
FOR JSON AUTO;
GO

-- Function Expression as target (nest_level > 1)
SELECT 
    c.CompanyName,
    o.TotalAmount, 
    CAST('2023-01-01 12:00:00' AS DATETIME) AS time
FROM forjsonauto_t_customers c
JOIN forjsonauto_t_orders o ON c.CustomerID = o.CustomerID
FOR JSON AUTO;
GO

-- Coalesce Expression as target (nesting level > 1)
SELECT 
    s.SupplierName,
    w.WarehouseName,
    COALESCE(w.LastInspectionDate, '1900-01-01') as InspectionDate
FROM forjsonauto_t_inventory_schema.forjsonauto_t_suppliers s
INNER JOIN forjsonauto_t_inventory_schema.forjsonauto_t_warehouses w ON s.SupplierID = w.SupplierID
WHERE w.WarehouseID IN (101, 102, 104)
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
WHERE o.Status IN ('Shipped', 'Delivered', 'Pending')
FOR JSON AUTO;
GO

-- ==========================================
-- Cases should return error
-- ==========================================
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

-- ==========================================
-- sources valid for FOR JSON AUTO (test if only contain certain RTEKind as source will make MSSQL return "NO TABLE" error)
-- ==========================================
-- single RTE_RELATION as source
SELECT
    CustomerID,
    CompanyName
FROM forjsonauto_t_customers
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
