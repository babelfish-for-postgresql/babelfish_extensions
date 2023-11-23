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
) AS pvt;

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
) AS pvt;

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
GO

-- procedure test
exec top_n_pivot 10
GO

exec top_n_pivot 5
GO

-- function test
SELECT * FROM test_table_valued_function(12);
GO

SELECT * FROM test_table_valued_function(2);
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
GO

-- JOIN with PIVOT stmt is not currently supported
SELECT * FROM (SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID IN ([2], [3])
) AS pvt) AS p1
LEFT OUTER JOIN
(SELECT TOP 5 ManufactureID, [4] AS STORE2, [5] AS STORE3
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)AS srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID IN ([4], [5])
) AS pvt2) AS p2
ON p1.ManufactureID = p2.ManufactureID
GO

-- Create VIEW ON PIVOT is not currently supported
CREATE VIEW pivot_view AS
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
GO

-- WITH CTE stmt with usage of pivot operator is not currently supported
WITH
EmployeeData AS
(
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
)
SELECT *
FROM EmployeeData;
GO

-- Join stmts inside PIVOT statment (BABEL-4558)
SELECT *
FROM (SELECT OSTable.Oid, STable.Scode, STable.Type
        FROM OSTable
        INNER JOIN STable
        ON OSTable.Sid = STable.Id
        ) AS SourceTable
PIVOT ( MAX(Scode) FOR [Type] IN ([1], [2], [3]))
        AS os_pivot
GO

-- view usage in PIVOT data source
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
GO