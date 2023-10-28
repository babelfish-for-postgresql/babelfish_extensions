use pivot_test
GO

-- 2 column in src table pivot
SELECT 'OrderNumbers' AS OrderCountbyStore, [1] AS STORE1, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5
FROM
(
    Select StoreID, OrderID
    FROM StoreReceipt
)as SrcTable
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
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- 3+ column in src table pivot
SELECT ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- order by test
SELECT  ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
order by EmployeeID
GO

-- whereclause test
SELECT  ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
where ManufactureID < 1220
GO

-- groupby, having clause test
SELECT EmployeeID, ManufactureID, [2] as STORE2
FROM
(
    SELECT EmployeeID, ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
where EmployeeID < 210
group by EmployeeID, ManufactureID, [2]
having ManufactureID < 1250
order by 1,2
GO


-- top test
SELECT top 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- distinct test 
SELECT distinct ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- insert into test
INSERT INTO pivot_insert_into
SELECT  ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt;

SELECT TOP 10 * FROM pivot_insert_into order by 1, 2;
GO

-- select into test
SELECT ManufactureID, EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
INTO pivot_select_into
FROM
(
    SELECT ManufactureID, EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt;

SELECT TOP 10 * FROM pivot_select_into order by 1, 2;
GO

-- union test
SELECT TOP 5 EmployeeID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT EmployeeID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
UNION
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt2
order by 1
GO

-- sub query test
SELECT TOP 3 * from (
    SELECT ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
    FROM
    (
        SELECT ManufactureID, ItemID, StoreID
        FROM StoreReceipt
    )as srctable
    PIVOT (
        COUNT (ItemID)
        FOR StoreID in ([2], [3], [4], [5], [6])
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
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt2
GO

-- temp table test
SELECT ManufactureID, ItemID, StoreID into #pivot_temp_table FROM StoreReceipt;
SELECT TOP 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
    #pivot_temp_table
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt2
GO

-- procedure test
-- Cannot execute twice (BUG)
exec top_n_pivot 10
GO

-- function test
-- Cannot execute twice (BUG)
select * from test_table_valued_function(12);
GO

-- explain pivot
set BABELFISH_SHOWPLAN_ALL ON;
SELECT top 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO
set BABELFISH_SHOWPLAN_ALL OFF;
GO


-- test column name with indirection (value column)
SELECT top 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- test column name win indirection (category column)
SELECT top 5 ManufactureID, [2] AS STORE2, [3] AS STORE3, [4] AS STORE4, [5] AS STORE5, [6] AS STORE6
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (ItemID)
    FOR srctable.StoreID in ([2], [3], [4], [5], [6])
) AS pvt
GO

-- left join test
-- Wrong result (bug)
Select * from (SELECT top 5 ManufactureID, [2] AS STORE2, [3] AS STORE3
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID in ([2], [3])
) AS pvt) as p1
left outer join
(SELECT top 5 ManufactureID, [4] AS STORE2, [5] AS STORE3
FROM
(
    SELECT ManufactureID, ItemID, StoreID
    FROM StoreReceipt
)as srctable
PIVOT (
    COUNT (srctable.ItemID)
    FOR StoreID in ([4], [5])
) AS pvt2) as p2
on p1.ManufactureID = p2.ManufactureID
GO
