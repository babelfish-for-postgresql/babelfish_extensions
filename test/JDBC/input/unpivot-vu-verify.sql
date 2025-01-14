-- Basic unpivot without targetlist aliases
SELECT customer_id, turnover, quarter 
FROM customer_turnover  
UNPIVOT (
    turnover FOR quarter IN (q1, q2, q3, q4)
) AS unpvt;


SELECT unpvt.customer_id, unpvt.turnover, unpvt.quarter 
FROM customer_turnover  
UNPIVOT (
    turnover FOR quarter IN (q1, q2, q3, q4)
) AS unpvt;
GO

SELECT * 
FROM customer_turnover k 
UNPIVOT (
    turnover FOR quarter IN (q1, q2, q3, q4)
) AS unpvt;
GO

-- Subquery as source
SELECT customer_id, turnover, quarter 
FROM ( 
    SELECT customer_id, q1, q2, q3, q4 
    FROM customer_turnover 
    WHERE q2 > 120 
) AS source_data 
UNPIVOT ( 
    turnover FOR quarter IN (q1, q2, q3, q4) 
) AS unpvt; 
GO

-- Join as source
SELECT p.product_name, u.customer_desc, u.turnover, u.quarter 
FROM product_info p 
JOIN customer_turnover c 
UNPIVOT (
    turnover FOR quarter IN (q1, q2, q3, q4)
) AS u ON p.product_id = u.customer_id;

-- with TOP
SELECT TOP 5
    customer_id,
    quarter,
    turnover 
FROM customer_turnover 
UNPIVOT
(
    turnover
    FOR quarter IN (q1, q2, q3, q4)
) AS unpivoted_data 
ORDER BY turnover DESC;
GO



-- Consecutive unpivots
SELECT product_id, sales, quarter, region, region_quarter 
FROM sales_data 
UNPIVOT ( sales FOR quarter IN (q1_sales, q2_sales)) AS sales_unpvt 
UNPIVOT ( region FOR region_quarter IN (q1_region, q2_region)) AS region_unpvt;
GO

SELECT 
    product_id AS PID, 
    RIGHT(col_name, 2) as quarter, 
    quantity, 
    revenue 
FROM product_sales p 
UNPIVOT ( quantity for col_name in (quantity_q1, quantity_q2) ) AS q 
UNPIVOT ( revenue for col_name1 in (revenue_q1, revenue_q2) ) AS r 
WHERE RIGHT(col_name, 2) = RIGHT(col_name1, 2) ;
GO


SELECT 
    r.product_id AS PID, 
    RIGHT(r.col_name, 2) as quarter,
    r.quantity, 
    r.revenue 
FROM product_sales p 
UNPIVOT (quantity for col_name in (quantity_q1, quantity_q2)) AS q 
UNPIVOT (revenue for col_name1 in (revenue_q1, revenue_q2)) AS r 
WHERE RIGHT(r.col_name, 2) = RIGHT(r.col_name1, 2);
GO

SELECT 
    r.product_id AS PID, 
    RIGHT(r.col_name, 2) as quarter, 
    r.quantity, 
    r.revenue 
FROM 
(
    ( product_sales p 

    CROSS JOIN LATERAL ( VALUES
        (P.quantity_q1, 'quantity_q1'), 
        (P.quantity_q2, 'quantity_q2')
        ) q1(quantity, col_name) 
    ) AS q 

CROSS JOIN LATERAL ( VALUES
    (q.revenue_q1, 'revenue_q1'), (q.revenue_q2, 'revenue_q2')
    ) r1(revenue, col_name1) 
) AS r 

WHERE RIGHT(r.col_name, 2) 
    = RIGHT(r.col_name1, 2) 
    AND r.quantity is NOT NULL 
    AND r.revenue is NOT NULL;




    -- Create view with UNPIVOT
CREATE VIEW vw_quarterly_sales AS 
SELECT 
    product_id,
    product_name,
    RIGHT(sales_quarter, 2) as quarter,
    sales_value,
    profit_value,
    region 
FROM product_performance 
UNPIVOT (
    sales_value FOR sales_quarter IN (sales_q1, sales_q2)
) AS sales_unpvt 
UNPIVOT (
    profit_value FOR profit_quarter IN (profit_q1, profit_q2)
) AS profit_unpvt 
WHERE RIGHT(sales_quarter, 2) = RIGHT(profit_quarter, 2);
GO

SELECT * from vw_quarterly_sales;
GO

CREATE VIEW sales_vw AS 
SELECT 
        product_id,
        product_name,
        sales_value,
        RIGHT(quarter_col, 2) as quarter,
        region 
FROM product_performance 
UNPIVOT (
    sales_value FOR quarter_col IN (sales_q1, sales_q2)
) AS unpvt;
GO

SELECT * from sales_vw;
GO

-- Query using CTE with UNPIVOT
WITH sales_unpivoted AS (
    SELECT 
        product_id,
        product_name,
        sales_value,
        RIGHT(quarter_col, 2) as quarter,
        region
    FROM product_performance
    UNPIVOT (
        sales_value FOR quarter_col IN (sales_q1, sales_q2)
    ) AS unpvt
)
SELECT 
    s.product_id,
    s.product_name,
    s.quarter,
    s.sales_value,
    s.region,
    AVG(s.sales_value) OVER (PARTITION BY s.region) as avg_regional_sales 
FROM sales_unpivoted s;
GO

-- Simple UNPIVOT-JOIN-UNPIVOT query
SELECT 
    s.product_id,
    s.quarter as sales_quarter,
    s.sales,
    i.stock,
    i.quarter as inventory_quarter 
FROM 
    (SELECT product_id, sales, quarter 
     FROM sales_data1 
     UNPIVOT (sales FOR quarter IN (q1_sales, q2_sales, q3_sales)) AS sales_unpvt) s 
JOIN 
    (SELECT product_id, stock, quarter 
     FROM inventory_data 
     UNPIVOT (stock FOR quarter IN (q1_stock, q2_stock, q3_stock)) AS inv_unpvt) i 
ON s.product_id = i.product_id 
AND LEFT(s.quarter, 2) = LEFT(i.quarter, 2) 
ORDER BY s.product_id, s.quarter;


-- Testing insert:
INSERT INTO quarterly_sales (customer_id, customer_desc, quarter, sales_value) 
SELECT customer_id, 
       customer_desc,
       quarter,
       sales_value 
FROM customer_turnover 
UNPIVOT 
(
    sales_value
    FOR quarter IN (q1, q2, q3, q4)
) AS unpvt;
GO

SELECT * from quarterly_sales;
GO


-- Errors:

    -- alias mismatch, columns should not be found
SELECT 
    p.product_id AS PID, 
    RIGHT(q.col_name, 2) as quarter, 
    q.quantity, 
    r.revenue 
FROM product_sales p 
UNPIVOT (quantity for col_name in (quantity_q1, quantity_q2)) AS q 
UNPIVOT (revenue for col_name1 in (revenue_q1, revenue_q2)) AS r 
WHERE RIGHT(q.col_name, 2) = RIGHT(r.col_name1, 2);

error:
SELECT c.customer_id, unpvt.turnover, unpvt.quarter 
FROM customer_turnover c 
UNPIVOT (
    turnover FOR quarter IN (q1, q2, q3, q4)
) AS unpvt;
GO

error:
SELECT 
    p.product_id AS PID, 
    RIGHT(q.col_name, 2) as quarter, 
    q.quantity, 
    r.revenue 
FROM product_sales p 
UNPIVOT ( quantity for col_name in (quantity_q1, quantity_q2) ) AS q 
UNPIVOT ( revenue for col_name1 in (revenue_q1, revenue_q2) ) AS r 
WHERE RIGHT(q.col_name, 2) = RIGHT(r.col_name1, 2) ;
GO
