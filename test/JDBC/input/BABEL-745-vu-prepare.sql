-- Create SalesData table
CREATE TABLE SalesData (
  Product varchar(50),
  SalesAmount float8
);
-- Insert some sample data
INSERT INTO SalesData (Product, SalesAmount)
VALUES ('Product A', 100.00), ('Product A', 150.00), ('Product A', 200.00),
       ('Product B', 50.00), ('Product B', 75.00), ('Product B', 100.00),
       ('Product C', 25.00), ('Product C', 50.00), ('Product C', 75.00);
GO

-- Create a view for SalesData
CREATE VIEW v_SalesData AS
SELECT Product, STDEV(SalesAmount) AS SalesAmount
FROM SalesData
GROUP BY Product
ORDER BY Product, SalesAmount;
GO

-- Create a stored procedure for STDEV calculation
CREATE PROCEDURE sp_CalculateStdev
  @Product varchar(50)
AS
BEGIN
  SELECT STDEV(SalesAmount) AS SalesAmountStdev
  FROM SalesData
  WHERE Product = @Product
  GROUP BY Product;
END;
GO

-- Create a stored procedure for STDEVP calculation
CREATE PROCEDURE sp1_CalculateStdev
  @Product varchar(50)
AS
BEGIN
  SELECT STDEVP(SalesAmount) AS SalesAmountStdev
  FROM SalesData
  WHERE Product = @Product
  GROUP BY Product;
END;
GO

-- Create a stored procedure for VAR calculation
CREATE PROCEDURE sp2_CalculateStdev
  @Product varchar(50)
AS
BEGIN
  SELECT VAR(SalesAmount) AS SalesAmountStdev
  FROM SalesData
  WHERE Product = @Product
  GROUP BY Product;
END;
GO

-- Create a stored procedure for VARP calculation
CREATE PROCEDURE sp3_CalculateStdev
  @Product varchar(50)
AS
BEGIN
  SELECT VARP(SalesAmount) AS SalesAmountStdev
  FROM SalesData
  WHERE Product = @Product
  GROUP BY Product;
END;
GO
