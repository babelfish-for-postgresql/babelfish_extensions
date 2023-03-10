Select * from SalesData 
ORDER BY Product;
GO

SELECT STDEV(SalesAmount) AS SalesAmountStdev
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

SELECT
  VARP(col1) AS col1_VARP,
  VAR(col2) AS col2_VAR
FROM FloatTest;
GO

SELECT
  STDEVP(col1) AS col1_STDEVP,
  STDEV(col2) AS col2_STDEV
FROM FloatTest;
GO
