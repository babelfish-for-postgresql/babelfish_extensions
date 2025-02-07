CREATE TABLE TestMoneyTable (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Amount MONEY,
    Description NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO TestMoneyTable (Amount, Description) VALUES 
(100.50, 'Item 1'),
(200.75, 'Item 2'),
(150.25, 'Item 3'),
(300.00, 'Item 4'),
(250.50, 'Item 5'),
(NULL, 'Null Amount');
GO

CREATE PROCEDURE get_column_info_p1
    @table_name text
AS
BEGIN
    SELECT c.[name] AS column_name,
           t.[name] AS [type_name],
           c.[max_length],
           c.[precision],
           c.[scale]
    FROM sys.columns c
        INNER JOIN sys.types t
            ON c.user_type_id = t.user_type_id
    WHERE object_id = object_id(@table_name)
    ORDER BY c.[name];
END
GO

-- Test Case 1: MAX aggregation
SELECT MAX(Amount) AS MaxAmount
INTO ResultTable1
FROM TestMoneyTable;
GO

-- Test Case 2: MIN aggregation
SELECT MIN(Amount) AS MinAmount
INTO ResultTable2
FROM TestMoneyTable;
GO

-- Test Case 3: AVG aggregation
SELECT AVG(Amount) AS AvgAmount
INTO ResultTable3
FROM TestMoneyTable;
GO

-- Test Case 4: SUM aggregation
SELECT SUM(Amount) AS TotalAmount
INTO ResultTable4
FROM TestMoneyTable;
GO

-- Test Case 5: COUNT aggregation (should remain as INT)
SELECT COUNT(Amount) AS CountAmount
INTO ResultTable5
FROM TestMoneyTable;
GO

-- Test Case 6: Multiple aggregations in one query
SELECT 
    MAX(Amount) AS MaxAmount,
    MIN(Amount) AS MinAmount,
    AVG(Amount) AS AvgAmount,
    SUM(Amount) AS TotalAmount,
    COUNT(Amount) AS CountAmount
INTO ResultTable6
FROM TestMoneyTable;
GO

-- Test Case 7: Aggregation with GROUP BY
SELECT 
    Description,
    MAX(Amount) AS MaxAmount
INTO ResultTable7
FROM TestMoneyTable
GROUP BY Description;
GO

-- Test Case 8: Aggregation with subquery
SELECT MaxAmount
INTO ResultTable8
FROM (
    SELECT MAX(Amount) AS MaxAmount
    FROM TestMoneyTable
) AS Subquery;
GO

-- Test Case 9: Aggregation with HAVING clause
SELECT 
    Description,
    MAX(Amount) AS MaxAmount
INTO ResultTable9
FROM TestMoneyTable
GROUP BY Description
HAVING MAX(Amount) > 200;
GO

-- Test Case 10: Aggregation with calculated MONEY column
SELECT 
    MAX(Amount * 2) AS DoubleMaxAmount
INTO ResultTable10
FROM TestMoneyTable;
GO

-- Negative Test Case: Empty table
CREATE TABLE EmptyMoneyTable (Amount MONEY);
GO

SELECT MAX(Amount) AS MaxAmount
INTO ResultTableEmpty
FROM EmptyMoneyTable;
GO

-- Edge Test Case: Extreme values
CREATE TABLE ExtremeMoneyTable (Amount MONEY);
GO

INSERT INTO ExtremeMoneyTable VALUES 
(922337203685477.5807),  -- Maximum positive value for MONEY
(-922337203685477.5808); -- Minimum negative value for MONEY
GO

SELECT MAX(Amount) AS MaxAmount, MIN(Amount) AS MinAmount
INTO ResultTableExtreme
FROM ExtremeMoneyTable;
GO

-- Arbitrary Test Case: Mixing NULL and non-NULL values
CREATE TABLE MixedNullMoneyTable (Amount MONEY);
GO

INSERT INTO MixedNullMoneyTable VALUES 
(100.00), (NULL), (200.00), (NULL), (300.00);
GO

SELECT 
    AVG(Amount) AS AvgAmount,
    SUM(Amount) AS TotalAmount,
    COUNT(Amount) AS CountNonNull,
    COUNT(*) AS CountAll
INTO ResultTableMixedNull
FROM MixedNullMoneyTable;
GO

-- Edge Test Case: Aggregating calculated values that exceed MONEY range
CREATE TABLE OverflowMoneyTable (Amount MONEY);
GO

INSERT INTO OverflowMoneyTable VALUES 
(922337203685477), (922337203685477);
GO

SELECT SUM(Amount) AS TotalAmount
INTO ResultTableOverflow
FROM OverflowMoneyTable;
GO

-- Negative Test Case: Trying to aggregate non-MONEY column as MONEY
CREATE TABLE NonMoneyTable (Amount VARCHAR(20));
GO

INSERT INTO NonMoneyTable VALUES ('100.00'), ('200.00');
GO

SELECT SUM(CAST(Amount AS MONEY)) AS TotalAmount
INTO ResultTableNonMoney
FROM NonMoneyTable;
GO

-- Check Constraint Test
CREATE TABLE CheckConstraintMoneyTable (
    ID INT PRIMARY KEY,
    Amount MONEY CHECK (Amount > 0 AND Amount < 1000)
);
GO

INSERT INTO CheckConstraintMoneyTable VALUES (1, 100.00), (2, 200.00), (3, 300.00);
GO

SELECT MAX(Amount) AS MaxCheckAmount
INTO ResultTableCheck
FROM CheckConstraintMoneyTable;
GO

-- Complex Dependent Objects Test
CREATE VIEW MoneyView AS SELECT MAX(Amount) as Amount FROM TestMoneyTable;
GO

CREATE FUNCTION GetTotalMoney()
RETURNS MONEY
AS
BEGIN
    DECLARE @Total MONEY;
    SELECT @Total = SUM(Amount) FROM TestMoneyTable;
    RETURN @Total;
END;
GO

CREATE PROCEDURE InsertMoney
    @Amount MONEY
AS
BEGIN
    INSERT INTO TestMoneyTable (Amount, Description) VALUES (@Amount, 'From Procedure');
END;
GO

EXEC InsertMoney 400.00;
GO

SELECT MAX(Amount) AS MaxViewAmount
INTO ResultTableView
FROM MoneyView;
GO

SELECT GetTotalMoney() AS TotalFunctionAmount
INTO ResultTableFunction;
GO

-- Indexed View Test
CREATE TABLE IndexedViewBaseTable (
    ID INT PRIMARY KEY,
    Amount MONEY
);
GO

INSERT INTO IndexedViewBaseTable VALUES (1, 100.00), (2, 200.00), (3, 300.00);
GO

CREATE VIEW IndexedMoneyView
WITH SCHEMABINDING
AS
SELECT ID, Amount, COUNT_BIG(*) AS Count
FROM IndexedViewBaseTable
GROUP BY ID, Amount;
GO

SELECT MAX(Amount) AS MaxIndexedViewAmount
INTO ResultTableIndexedView
FROM IndexedMoneyView;
GO

-- Currency Symbol Test Cases
CREATE TABLE CurrencyMoneyTable (
    ID INT IDENTITY(1,1),
    Amount MONEY
);
GO

-- Insert values with different currency symbols
INSERT INTO CurrencyMoneyTable (Amount) VALUES
('$100.50'),
('£200.75'),
('€150.25'),
('¥300.00'),
('₹250.50'),
('CHF 175.25');
GO

-- Test different aggregations with currency symbols
SELECT MAX(Amount) AS MaxAmount
INTO ResultTableCurrency1
FROM CurrencyMoneyTable;
GO

SELECT MIN(Amount) AS MinAmount
INTO ResultTableCurrency2
FROM CurrencyMoneyTable;
GO

SELECT SUM(Amount) AS TotalAmount
INTO ResultTableCurrency3
FROM CurrencyMoneyTable;
GO

-- Test with mixed currency symbols in calculations
SELECT 
    MAX(Amount) AS MaxAmount,
    MIN(Amount) AS MinAmount,
    AVG(Amount) AS AvgAmount,
    SUM(Amount) * 1.1 AS TotalWithMarkup
INTO ResultTableCurrency4
FROM CurrencyMoneyTable;
GO
