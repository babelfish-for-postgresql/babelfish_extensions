Select * from SalesData 
ORDER BY Product, SalesAmount;
GO

SELECT * FROM v_SalesData
GO

SELECT STDEV(SalesAmount) AS SalesAmount
FROM SalesData;
GO

-- This should throw an error since STDEV cannot be applied to a non-numeric data type
SELECT STDEV(Product) AS ProductStdev
FROM SalesData;
GO

SELECT VAR(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
ORDER BY Product ASC;
GO

SELECT VARP(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
ORDER BY Product ASC;
GO

EXEC sp_CalculateStdev 'Product A';
GO

EXEC sp1_CalculateStdev 'Product A';
GO

EXEC sp2_CalculateStdev 'Product A';
GO

EXEC sp3_CalculateStdev 'Product A';
GO

--Float8
SELECT VARP(CAST(1.0 AS float8)), VAR(CAST(2.0 AS float8));
GO

SELECT STDEVP(CAST(3.0 AS float8)), STDEV(CAST(4.0 AS float8));
GO

SELECT VARP(CAST('inf' AS float8)), VAR(CAST('inf' AS float8));
GO

SELECT STDEVP(CAST('inf' AS float8)), STDEV(CAST('inf' AS float8));
GO

SELECT VARP(CAST('nan' AS float8)), VAR(CAST('nan' AS float8));
GO

SELECT STDEVP(CAST('nan' AS float8)), STDEV(CAST('nan' AS float8));
GO
