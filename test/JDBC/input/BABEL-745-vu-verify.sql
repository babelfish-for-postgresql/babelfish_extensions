Select * from SalesData 
ORDER BY Product;
GO

SELECT Product, STDEV(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
GO

SELECT Product, STDEVP(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
GO

SELECT Product, VAR(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
GO

SELECT Product, VARP(SalesAmount) AS SalesAmountStdev
FROM SalesData
GROUP BY Product
GO

EXEC sp_CalculateStdev 'Product A';
GO

EXEC sp1_CalculateStdev 'Product A';
GO

EXEC sp2_CalculateStdev 'Product A';
GO

EXEC sp3_CalculateStdev 'Product A';
GO