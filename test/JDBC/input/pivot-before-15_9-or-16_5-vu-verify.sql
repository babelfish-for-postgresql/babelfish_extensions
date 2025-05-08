use pivot_test
GO

-- 2 column in src table pivot
SELECT 'OrderNumbers' AS OrderCountbyStore, [1] AS STORE1, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5
FROM
(
    SELECT StoreID, OrderID
    FROM StoreReceipt
)AS SrcTable
PIVOT (
    COUNT (OrderID)
    FOR StoreID IN ([1], [2], [3],[4], [5])
) AS pvt
ORDER BY 1
GO

-- testing trigger with pivot 
insert into trigger_testing (col) select N'Muffler'
GO

-- 3 column in src table pivot
SELECT EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- 3+ column IN src table pivot
SELECT ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- ORDER by test
SELECT  ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER by EmployeeID
GO

-- whereclause test
SELECT  ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
WHERE ManufactureID < 1220
ORDER BY 1
GO

-- groupby, having clause test
SELECT EmployeeID, ManufactureID, [2] AS STORE2
FROM
(
    SELECT EmployeeID, ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
WHERE EmployeeID < 210
group by EmployeeID, ManufactureID, [2]
having ManufactureID < 1250
ORDER by 1,2
GO


-- TOP test
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- distinct test 
SELECT distinct ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- INSERT INTO test
INSERT INTO pivot_insert_into
SELECT  ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1

SELECT TOP 10 * FROM pivot_insert_into ORDER by 1, 2;
GO

-- SELECT INTO test
SELECT ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
INTO pivot_SELECT_into
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1

SELECT TOP 10 * FROM pivot_SELECT_into ORDER by 1, 2;
GO

-- union test
SELECT TOP 5 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
UNION
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt2
ORDER by 1
GO

-- sub query test
SELECT TOP 3 * FROM (
    SELECT ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT ManufactureID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt2
) p
ORDER BY 1
GO

-- table variable test
DECLARE  @pivot_table_var TABLE (
	ManufactureID INT,
    ItemID INT,
	StoreID INT
);
INSERT INTO @pivot_table_var SELECT ManufactureID, ItemID, StoreID FROM StoreReceipt;
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
    @pivot_table_var
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt2
ORDER BY 1
GO

-- temp table test
SELECT ManufactureID, ItemID, StoreID INTO #pivot_temp_table FROM StoreReceipt;
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
    #pivot_temp_table
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt2
ORDER BY 1
GO

-- procedure test
exec top_n_pivot 10
GO

exec top_n_pivot 5
GO

-- function test
SELECT * FROM test_table_valued_function(12) ORDER BY 1
GO

SELECT * FROM test_table_valued_function(2) ORDER BY 1
GO

-- explain pivot
SET BABELFISH_SHOWPLAN_ALL ON;
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO
SET BABELFISH_SHOWPLAN_ALL OFF;
GO


-- test column name with indirection (value column)
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- test column name win indirection (category column)
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR srctable.StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
ORDER BY 1
GO

-- CTE test data
CREATE TABLE #FruitSales
(FruitType VARCHAR(20), SalesYear INT, FruitSales MONEY);
GO

INSERT INTO #FruitSales VALUES('Orange', 2024, 23425);
INSERT INTO #FruitSales VALUES('Orange', 2024, 54234);
INSERT INTO #FruitSales VALUES('Orange', 2023, 12490);
INSERT INTO #FruitSales VALUES('Orange', 2023, 4535);
INSERT INTO #FruitSales VALUES('Banana', 2024, 45745);
INSERT INTO #FruitSales VALUES('Banana', 2024, 5636);
INSERT INTO #FruitSales VALUES('Banana', 2023, 24654);
INSERT INTO #FruitSales VALUES('Banana', 2023, 6547);
GO

-- CTE test 1
WITH
SalesTotal AS
(
SELECT FruitType,
  [2023] AS [2023_Total],
  [2024] AS [2024_Total]
FROM #FruitSales
  PIVOT(SUM(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
),
SalesAvg AS
(
SELECT FruitType,
  [2023] AS [2023_Avg],
  [2024] AS [2024_Avg]
FROM #FruitSales
  PIVOT(AVG(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
)
SELECT st.FruitType, st.[2023_Total], sa.[2023_Avg],
  st.[2024_Total], sa.[2024_Avg]
FROM SalesTotal AS st
  INNER JOIN SalesAvg AS sa
  ON st.FruitType = sa.FruitType
ORDER BY 1
GO

-- CTE test 2
WITH
SalesTotal AS
(
SELECT FruitType,
  [2023] AS [2023_Total],
  [2024] AS [2024_Total]
FROM #FruitSales
  PIVOT(SUM(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
),
SalesAvg AS
(
SELECT FruitType,
  [2023] AS [2023_Avg],
  [2024] AS [2024_Avg]
FROM #FruitSales
  PIVOT(AVG(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
)
SELECT * from SalesTotal ORDER BY FruitType;
GO

-- CTE test 3
WITH
SalesTotal AS
(
SELECT FruitType,
  [2023] AS [2023_Total],
  [2024] AS [2024_Total]
FROM #FruitSales
  PIVOT(SUM(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
),
SalesAvg AS
(
SELECT FruitType,
  [2023] AS [2023_Avg],
  [2024] AS [2024_Avg]
FROM #FruitSales
  PIVOT(AVG(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
)
SELECT * from SalesAvg ORDER BY FruitType;
GO

-- CTE of 3 expression table
WITH
SalesTotal AS
(
SELECT FruitType,
  [2023] AS [2023_Total],
  [2024] AS [2024_Total]
FROM #FruitSales
  PIVOT(SUM(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
),
SalesAvg AS
(
SELECT FruitType,
  [2023] AS [2023_Avg],
  [2024] AS [2024_Avg]
FROM #FruitSales
  PIVOT(AVG(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
),
SalesMin AS
(
SELECT FruitType,
  [2023] AS [2023_min],
  [2024] AS [2024_min]
FROM #FruitSales
  PIVOT(MIN(FruitSales)
  FOR SalesYear IN([2023], [2024])
  ) AS PivotSales
)
SELECT st.FruitType, st.[2023_Total], sa.[2023_Avg],
  st.[2024_Total], sa.[2024_Avg], sm.[2023_min],sm.[2024_min]
FROM SalesTotal AS st
  INNER JOIN SalesAvg AS sa
  ON st.FruitType = sa.FruitType
  INNER JOIN SalesMin as sm
  ON sa.FruitType = sm.FruitType
ORDER BY 1
GO

-- Test stmt of CTE table and PIVOT stmt in different level 
WITH
SalesTotal AS
(
    SELECT FruitType,
        [2023] AS [2023_Total],
        [2024] AS [2024_Total]
    FROM #FruitSales
    PIVOT(SUM(FruitSales)
    FOR SalesYear IN([2023], [2024])
    ) AS PivotSales
)
SELECT st.FruitType, st.[2023_Total], sa.[2023_Avg],
  st.[2024_Total], sa.[2024_Avg]
FROM SalesTotal AS st
JOIN (
    SELECT FruitType,
        [2023] AS [2023_Avg],
        [2024] AS [2024_Avg]
    FROM #FruitSales
    PIVOT(AVG(FruitSales)
    FOR SalesYear IN([2023], [2024])
    ) AS PivotSales
) sa ON st.FruitType = sa.FruitType;
GO

DROP TABlE IF EXISTS #FruitSales
GO

-- PIVOT with CTE as source table
WITH cte_table AS (
    SELECT [p].productName, [o].[employeeName]
    FROM orders [o] JOIN products AS [p] on (o.productId = p.productId)
)
SELECT CAST('COUNT' AS VARCHAR(10)), [mac],[ipad],[charger] FROM cte_table
PIVOT (
    COUNT(employeeName)
    FOR productName IN (mac, [iphone], [ipad], [charger])
) as pvt
GO

-- string is not allowed in PIVOT column value list
WITH cte_table AS (
    SELECT o.[orderId], o.[productId], [p].productName,
        [p].productPrice, [o].[employeeName], [o].employeeCode, [o].date
    FROM orders [o] JOIN products AS [p] on (o.productId = p.productId)
)
SELECT * FROM cte_table
PIVOT (
    COUNT(orderId)
    FOR productName IN ('mac', 'iphone', 'ipad', 'charger')
) as p
GO

-- aggregate column in PIVOT column value list is not allowed
WITH cte_table AS
(
  SELECT
    CAST('COUNT' AS VARCHAR(10)) AS COUNT,
    [mac], [ipad], [charger], [employeeName]
  FROM (
    SELECT [o].employeeName, [p].productName
    FROM orders [o] JOIN products AS [p] on ([o].productId = [p].productId)
  ) AS dervied_table
PIVOT
  (
      COUNT(employeeName)
      FOR productName IN ([mac], [employeeName], [iphone], [ipad], [charger])
  ) as pvt
)
SELECT * FROM cte_table
GO

-- Join stmts inside PIVOT statment (BABEL-4558)
SELECT Oid, [1] AS TYPE1, [2] AS TYPE2, [3] AS TYPE3
FROM (SELECT OSTable.Oid, STable.Scode, STable.Type
        FROM OSTable
        INNER JOIN STable
        ON OSTable.Sid = STable.Id
        ) AS SourceTable
PIVOT ( MAX(Scode) FOR [Type] IN ([1], [2], [3]))
        AS os_pivot
ORDER BY 1
GO

-- JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- INNER JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
INNER JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- LEFT JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
LEFT JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- RIGHT JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
RIGHT JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- FULL JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
FULL JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- CROSS JOIN TEST
SELECT * FROM
(
    SELECT TOP 5 EmployeeID, [2] AS STORE2
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
CROSS JOIN
(
    SELECT TOP 5 EmployeeID, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2 ORDER BY 1
GO

-- COMMA JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
,
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
WHERE p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- COMMA CROSS JOIN TEST
SELECT * FROM
(
    SELECT TOP 5 EmployeeID, [2] AS STORE2
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
,
(
    SELECT TOP 5 EmployeeID, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2 ORDER BY 1
GO

--3+ JOIN TEST
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID
JOIN
(
    SELECT TOP 10 EmployeeID, [1] AS STORE1
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([1])
    ) AS pvt where EmployeeID > 248
)AS p3
ON p2.EmployeeID = p3.EmployeeID ORDER BY 1
GO


-- Result Order Test
-- JOIN A
SELECT p2.EmployeeID, STORE7, STORE8, STORE9, STORE10 FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- JOIN B (Reference)
SELECT * FROM
(
    SELECT TOP 10 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([2], [3], [4], [5], [6])
    ) AS pvt where EmployeeID > 250
) AS p1
JOIN
(
    SELECT TOP 10 EmployeeID, [7] AS STORE7, [8] AS STORE8, [9] AS STORE9, [10] AS STORE10
    FROM
    (
        SELECT EmployeeID, ItemID, StoreID
        FROM StoreReceipt
    )AS srctable
    PIVOT (
        COUNT (srctable.ItemID)
        FOR StoreID IN ([7], [8], [9], [10])
    ) AS pvt where EmployeeID > 245
) AS p2
ON p1.EmployeeID = p2.EmployeeID ORDER BY 1
GO

-- Test view as a data source in a stmt with pivot operator
SELECT TOP 5 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT EmployeeID, ItemID, StoreID
    FROM StoreReceipt_view
)AS srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID IN ([2], [3], [4], [5], [6])
) AS pvt
GO

-- aggregate string value, when no row is selected, should output NULL
SELECT [seatings], [LEFT], [RIGHT] 
FROM
(
    SELECT [seatings], left_right 
    FROM seating_tbl
) AS p1
PIVOT (
    MAX(left_right) 
    FOR left_right IN ([LEFT], [RIGHT]) 
) AS p2
ORDER BY 1
GO

-- test pivot with table in different schemas 1
SELECT CAST('COUNT' AS VARCHAR(10)) AS COUNT, [mac], [ipad], [charger]
FROM (
    SELECT [o].employeeName, [p].productName
    FROM dbo.orders [o] JOIN products AS [p] on ([o].productId = [p].productId)
) AS dervied_table
PIVOT(
     COUNT(employeeName)
     FOR productName IN ([mac], [iphone], [ipad], [charger])
) as pvt
GO

-- test pivot with table in different schemas 2
SELECT CAST('COUNT' AS VARCHAR(10)) AS COUNT, [mac], [ipad], [charger]
FROM (
    SELECT [o].employeeName, [p].productName
    FROM dbo.orders [o] JOIN pivot_schema.products_sch AS [p] on ([o].productId = [p].productId)
) AS dervied_table
PIVOT(
     COUNT(employeeName)
     FOR productName IN ([mac], [iphone], [ipad], [charger])
) as pvt
GO