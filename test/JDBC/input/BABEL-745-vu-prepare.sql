-- Create SalesData table
CREATE TABLE SalesData (
  Product varchar(50),
  SalesAmount decimal(10,2)
);
-- Insert some sample data
INSERT INTO SalesData (Product, SalesAmount)
VALUES ('Product A', 100.50), ('Product A', 150.25), ('Product A', 200.75),
       ('Product B', 50.75), ('Product B', 75.25), ('Product B', 100.50),
       ('Product C', 25.50), ('Product C', 50.75), ('Product C', 75.25);
GO

-- Create a view for SalesData
CREATE VIEW v_SalesData AS
SELECT Product, SalesAmount
FROM SalesData;
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
