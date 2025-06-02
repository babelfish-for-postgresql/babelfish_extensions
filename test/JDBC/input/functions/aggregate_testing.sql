DROP TABLE IF EXISTS Sales;
GO

DROP TABLE IF EXISTS T1;
GO

CREATE TABLE T1(
        numeric_col NUMERIC(15,5),
        money_col MONEY,
        smallmoney_col SMALLMONEY,
        bigint_col BIGINT,
        int_col INT,
        smallint_col SMALLINT,
        tinyint_col TINYINT,
        bit_col BIT,
        char_col CHAR(10),
        varchar_col VARCHAR(50),
        nvarchar_col NVARCHAR(50),
        text_col TEXT,
        ntext_col NTEXT,
        binary_col BINARY(10),
        varbinary_col VARBINARY(50)
)
GO

INSERT INTO T1 VALUES 
(123.45678, 1234.56, 214.35, 9223372036854775807, 2147483647, 32767, 255, 1, 'CHAR10', 'Variable text', N'Unicode text', 'Large text field', N'Large unicode text', 0x0123456789, 0x0123456789AB);
GO
INSERT INTO T1 VALUES 
(987.65432, 9876.54, 1234.56, 1234567890123456789, 1234567890, 12345, 128, 0, 'CHAR20', 'Another variable text', N'Another unicode text', 'Another large text field', N'Another large unicode text', 0xABCDEF1234, 0xABCDEF1234567890);
GO

INSERT INTO T1 VALUES 
(0.00001, 0.01, 0.01, 1, 1, 1, 1, 0, 'CHAR30', 'Short text', N'Short unicode text', 'Short large text field', N'Short large unicode text', 0x0000000000, 0x000000);
GO

INSERT INTO T1 VALUES 
(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
GO

-- *** T_Aggref ***
-- AVG() testing
SELECT AVG(tinyint_col) * 1.00 FROM T1;
GO

SELECT AVG(smallint_col) * 1.00 FROM T1;
GO

SELECT AVG(int_col) * 1.00 FROM T1;
GO

SELECT AVG(bigint_col) * 1.00 FROM T1;
GO

SELECT AVG(numeric_col) * 1.00 FROM T1;
GO

SELECT AVG(money_col) * 1.00 FROM T1;
GO

SELECT AVG(smallmoney_col) * 1.00 FROM T1;
GO

SELECT AVG(bit_col) * 1.00 FROM T1;
GO

-- COUNT() testing
SELECT COUNT(tinyint_col) * 1.00 FROM T1;
GO

SELECT COUNT(smallint_col) * 1.00 FROM T1;
GO

SELECT COUNT(int_col) * 1.00 FROM T1;
GO

SELECT COUNT(bigint_col) * 1.00 FROM T1;
GO

SELECT COUNT(numeric_col) * 1.00 FROM T1;
GO

SELECT COUNT(money_col) * 1.00 FROM T1;
GO

SELECT COUNT(smallmoney_col) * 1.00 FROM T1;
GO

SELECT COUNT(bit_col) * 1.00 FROM T1;
GO

-- COUNT(*) testing
SELECT COUNT(*) * 1.00 FROM T1;
GO

SELECT COUNT(1) * 1.00 FROM T1;
GO

-- COUNT_BIG() testing
SELECT COUNT_BIG(tinyint_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(smallint_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(int_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(bigint_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(numeric_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(money_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(smallmoney_col) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(bit_col) * 1.00 FROM T1;
GO

-- COUNT_BIG(*) testing
SELECT COUNT_BIG(*) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(1) * 1.00 FROM T1;
GO

-- SUM() testing
SELECT SUM(tinyint_col) * 1.00 FROM T1;
GO

SELECT SUM(smallint_col) * 1.00 FROM T1;
GO

SELECT SUM(int_col) * 1.00 FROM T1;
GO

SELECT SUM(bigint_col) * 1.00 FROM T1;
GO

SELECT SUM(numeric_col) * 1.00 FROM T1;
GO

SELECT SUM(money_col) * 1.00 FROM T1;
GO

SELECT SUM(smallmoney_col) * 1.00 FROM T1;
GO

SELECT SUM(bit_col) * 1.00 FROM T1;
GO

-- MAX() testing
SELECT MAX(tinyint_col) * 1.00 FROM T1;
GO

SELECT MAX(smallint_col) * 1.00 FROM T1;
GO

SELECT MAX(int_col) * 1.00 FROM T1;
GO

SELECT MAX(bigint_col) * 1.00 FROM T1;
GO

SELECT MAX(numeric_col) * 1.00 FROM T1;
GO

SELECT MAX(money_col) * 1.00 FROM T1;
GO

SELECT MAX(smallmoney_col) * 1.00 FROM T1;
GO

SELECT MAX(bit_col) * 1.00 FROM T1;
GO

-- MIN() testing
SELECT MIN(tinyint_col) * 1.00 FROM T1;
GO

SELECT MIN(smallint_col) * 1.00 FROM T1;
GO

SELECT MIN(int_col) * 1.00 FROM T1;
GO

SELECT MIN(bigint_col) * 1.00 FROM T1;
GO

SELECT MIN(numeric_col) * 1.00 FROM T1;
GO

SELECT MIN(money_col) * 1.00 FROM T1;
GO

SELECT MIN(smallmoney_col) * 1.00 FROM T1;
GO

SELECT MIN(bit_col) * 1.00 FROM T1;
GO

-- STRING_AGG() testing
SELECT STRING_AGG(CAST(numeric_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(money_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(smallmoney_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(bigint_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(int_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(smallint_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(tinyint_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(bit_col AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

SELECT STRING_AGG(CAST(NULL AS VARCHAR(20)), ', ') * 1.00 FROM T1;
GO

-- NULL as an input
SELECT STRING_AGG(NULL, ',') * 1.00 FROM T1 WHERE numeric_col IS NULL;
GO

SELECT COUNT(NULL) * 1.00 FROM T1;
GO

SELECT COUNT_BIG(NULL) * 1.00 FROM T1;
GO

SELECT AVG(NULL) * 1.00 FROM T1;
GO

SELECT SUM(NULL) * 1.00 FROM T1;
GO

-- Additional test cases
CREATE TABLE Sales (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    Price MONEY
);
GO

INSERT INTO Sales (ProductID, Quantity, Price) VALUES (1, 10, 25.99);
GO

INSERT INTO Sales (ProductID, Quantity, Price) VALUES (2, 5, 49.99);
GO

INSERT INTO Sales (ProductID, Quantity, Price) VALUES (3, 8, 15.50);
GO

-- 1. Basic counts comparison
SELECT 
    ProductID,
    COUNT(*) as TotalRowsStar,
    COUNT(1) as TotalRowsOne,
    COUNT_BIG(*) as TotalRowsBigStar,
    COUNT_BIG(1) as TotalRowsBigOne
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 2. Counts with mathematical operations
SELECT 
    ProductID,
    COUNT(*) as TotalRowsStar,
    COUNT(*) + 10.00 as CountStarPlus10,
    COUNT(*) * 2.00 as CountStarMultiply2,
    COUNT(*) - 3.00 as CountStarMinus3,
    COUNT(*) / 2.00 as CountStarDivide2,
    COUNT_BIG(*) as TotalRowsBigStar,
    COUNT_BIG(*) + 100.00 as BigCountStarPlus100,
    COUNT_BIG(*) * 5.00 as BigCountStarMultiply5,
    COUNT_BIG(*) - 2.00 as BigCountStarMinus2,
    COUNT_BIG(*) / 3.00 as BigCountStarDivide3
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 3. Conditional counts
SELECT 
    ProductID,
    COUNT(*) as TotalRowsStar,
    COUNT(1) as TotalRowsOne,
    COUNT(*) - COUNT(1) as CountDifference,
    COUNT(CASE WHEN Price > 100.00 THEN '*' END) as HighPriceCountStar,
    COUNT(CASE WHEN Price > 100.00 THEN 1 END) as HighPriceCountOne,
    COUNT_BIG(CASE WHEN Quantity > 10.00 THEN '*' END) as HighQuantityBigCountStar,
    COUNT_BIG(CASE WHEN Quantity > 10.00 THEN 1 END) as HighQuantityBigCountOne
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 4. Counts with GROUP BY
SELECT 
    ProductID,
    COUNT(*) as SalesCountStar,
    COUNT(1) as SalesCountOne,
    COUNT_BIG(*) as SalesBigCountStar,
    COUNT_BIG(1) as SalesBigCountOne,
    COUNT(*) * AVG(Price) as WeightedAvgPriceStar,
    COUNT(1) * AVG(Price) as WeightedAvgPriceOne
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 5. Combining counts with other aggregates
SELECT 
    ProductID,
    COUNT(*) as TotalRowsStar,
    COUNT(1) as TotalRowsOne,
    COUNT_BIG(*) as TotalRowsBigStar,
    COUNT_BIG(1) as TotalRowsBigOne,
    SUM(Quantity) as TotalQuantity,
    AVG(Price) as AveragePrice,
    COUNT(*) * AVG(Price) as CountStarTimesAvg,
    COUNT(1) * AVG(Price) as CountOneTimesAvg,
    COUNT_BIG(*) * SUM(Quantity) as BigCountStarTimesSum,
    COUNT_BIG(1) * SUM(Quantity) as BigCountOneTimesSum
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 6. Combining all count variations in a single query
SELECT 
    ProductID,
    COUNT(*) as RegularCountStar,
    COUNT(1) as RegularCountOne,
    COUNT_BIG(*) as BigCountStar,
    COUNT_BIG(1) as BigCountOne,
    CASE 
        WHEN COUNT(*) = COUNT(1) AND COUNT(*) = COUNT_BIG(*) AND COUNT(*) = COUNT_BIG(1) THEN 'All Equal'
        ELSE 'Different'
    END as ComparisonResult
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 7. Complex calculations with different count types
SELECT 
    ProductID,
    COUNT(*) as SalesCountStar,
    COUNT(1) as SalesCountOne,
    COUNT_BIG(*) as SalesBigCountStar,
    COUNT_BIG(1) as SalesBigCountOne,
    SUM(Quantity) as TotalQuantity,
    AVG(Price) as AveragePrice,
    (SUM(Quantity) * AVG(Price)) / NULLIF(COUNT(*), 0) as PerTransactionRevenueStar,
    (SUM(Quantity) * AVG(Price)) / NULLIF(COUNT(1), 0) as PerTransactionRevenueOne,
    (COUNT_BIG(*) * SUM(Price)) / NULLIF(SUM(Quantity), 0) as PricePerUnitStar,
    (COUNT_BIG(1) * SUM(Price)) / NULLIF(SUM(Quantity), 0) as PricePerUnitOne
FROM Sales
GROUP BY ProductID
HAVING COUNT(*) > 3
ORDER BY ProductID DESC;
GO

-- 8. Basic counts with @temp operations
DECLARE @temp NUMERIC(10,2) = 3.25;
SELECT 
    ProductID,
    COUNT(*) * @temp as CountStarTimesTemp,
    COUNT(1) * @temp as CountOneTimesTemp,
    COUNT_BIG(*) * @temp as BigCountStarTimesTemp,
    COUNT_BIG(1) * @temp as BigCountOneTimesTemp
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 9. Arithmetic operations with different precision
DECLARE @temp NUMERIC(12,3) = 5.755;
SELECT 
    ProductID,
    COUNT(*) + @temp as CountPlusTemp,
    COUNT(1) - @temp as CountMinusTemp,
    COUNT_BIG(*) * @temp as BigCountMultiplyTemp,
    COUNT_BIG(1) / @temp as BigCountDivideTemp
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 10. Conditional counts with higher precision
DECLARE @temp NUMERIC(15,4) = 2.7182;
SELECT 
    ProductID,
    COUNT(CASE WHEN Price > @temp * 100.0000 THEN 1 END) as HighPriceCount,
    COUNT_BIG(CASE WHEN Quantity > @temp * 5.0000 THEN 1 END) as HighQuantityCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 11. Group by calculations with pi value
DECLARE @temp NUMERIC(18,6) = 3.141592;
SELECT 
    ProductID,
    CAST(COUNT(*) * @temp as NUMERIC(18,6)) as WeightedCountStar,
    CAST(COUNT(1) / @temp as NUMERIC(18,6)) as AdjustedCountOne
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 12. Complex calculations with larger value
DECLARE @temp NUMERIC(12,2) = 10.75;
SELECT 
    ProductID,
    COUNT(*) * (@temp + 1.00) as ComplexCount1,
    COUNT(1) * (@temp * 2.00) as ComplexCount2
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 13. Multiple temp variables with different values
DECLARE @temp NUMERIC(14,4) = 7.1234;
SELECT 
    ProductID,
    COUNT(*) * @temp as WeightedCount,
    SUM(Quantity) / @temp as AdjustedSum,
    AVG(Price) * @temp as WeightedAvg
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 14. Negative temp value calculations
DECLARE @temp NUMERIC(10,3) = -2.567;
SELECT 
    ProductID,
    COUNT(1) / @temp as NegativeAdjustedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 15. Very precise decimal calculations
DECLARE @temp NUMERIC(20,8) = 1.23456789;
SELECT 
    ProductID,
    CAST(COUNT(*) * @temp as NUMERIC(20,8)) as PreciseWeightedCount,
    CAST(COUNT_BIG(1) / @temp as NUMERIC(20,8)) as PreciseAdjustedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 16. Large number calculations
DECLARE @temp NUMERIC(16,2) = 123.45;
SELECT 
    ProductID,
    COUNT(*) * @temp as LargeWeightedCount,
    COUNT_BIG(1) / @temp as SmallAdjustedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 17. Integer-like temp value
DECLARE @temp NUMERIC(8,0) = 5;
SELECT 
    ProductID,
    COUNT(*) * @temp as SimpleWeightedCount,
    COUNT_BIG(1) / @temp as SimpleDividedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 18. Mixed precision calculations
DECLARE @temp NUMERIC(12,4) = 4.3210;
SELECT 
    ProductID,
    CAST(COUNT(*) * @temp as NUMERIC(12,4)) as MixedWeightedCount,
    CAST(SUM(Quantity) / @temp as NUMERIC(12,4)) as MixedAdjustedSum
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 19. Percentage-like temp value
DECLARE @temp NUMERIC(5,2) = 0.25;
SELECT 
    ProductID,
    COUNT(*) * @temp as PercentageCount,
    COUNT_BIG(1) / @temp as InversePercentageCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 20. Maximum precision calculations
DECLARE @temp NUMERIC(38,10) = 9.9999999999;
SELECT 
    ProductID,
    CAST(COUNT(*) * @temp as NUMERIC(38,10)) as MaxPrecisionCount,
    CAST(COUNT_BIG(1) / @temp as NUMERIC(38,10)) as MaxPrecisionAdjustedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 21. Combining multiple numeric types
DECLARE @num_factor NUMERIC(10,4) = 1.2345;
SELECT 
    ProductID,
    (CAST(COUNT(*) * @num_factor as NUMERIC(15,4))) * 1.00 as NumericWeightedCount
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 22. Percentage calculations with DECIMAL and INT
DECLARE @percentage_factor DECIMAL(5,2) = 0.15;
DECLARE @base_count INT = 1000;
SELECT 
    ProductID,
    (COUNT(*) * @percentage_factor) * 1.00 as PercentageCount,
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 23. Conditional aggregates with numeric types
DECLARE @threshold MONEY = 500.00;
DECLARE @bigint_multiplier BIGINT = 1000000;
SELECT 
    ProductID,
    (COUNT(CASE WHEN Price > @threshold THEN 1 END)) * 1.00 as HighPriceCount,
    (AVG(CASE WHEN Price < @threshold THEN CAST(Price as SMALLMONEY) END)) * 1.00 as AvgLowPrice
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

-- 24. Complex ratio calculations with numeric casting
DECLARE @ratio_factor DECIMAL(8,4) = 0.1234;
SELECT 
    ProductID,
    (CAST(SUM(CASE WHEN Price > 100 THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0) as NUMERIC(10,2))) * 1.00 as HighPricePercentage,
    (CAST(AVG(Quantity) / AVG(Price) * @ratio_factor as DECIMAL(10,4))) * 1.00 as QuantityPriceRatio,
    (CAST(COUNT(*) * @ratio_factor * AVG(CAST(Price as MONEY)) as MONEY)) * 1.00 as WeightedTotalValue
FROM Sales
GROUP BY ProductID
ORDER BY ProductID DESC;
GO

DROP TABLE IF EXISTS Sales;
GO

DROP TABLE IF EXISTS T1;
GO
