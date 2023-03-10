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

CREATE TABLE FloatTest (
  col1 float8,
  col2 float8
);
INSERT INTO FloatTest (col1, col2)
VALUES
  (1.0, NULL),
  (NULL, 2.0),
  (3.0, 4.0),
  (NULL, NULL),
  (5.0, 'inf'),
  ('inf', 6.0),
  (7.0, 'nan'),
  ('nan', 8.0),
  (9.0, 10.0),
  (11.0, 12.0),
  (13.0, 'inf'),
  ('inf', 14.0),
  (15.0, 'nan'),
  ('nan', 16.0),
  (17.0, 18.0),
  (19.0, 20.0),
  (21.0, 'inf'),
  ('inf', 22.0),
  (23.0, 'nan'),
  ('nan', 24.0),
  (25.0, 26.0),
  (27.0, 28.0),
  (29.0, 'inf'),
  ('inf', 30.0),
  (31.0, 'nan'),
  ('nan', 32.0),
  (33.0, 34.0),
  (35.0, 36.0),
  (37.0, 'inf'),
  ('inf', 38.0),
  (39.0, 'nan'),
  ('nan', 40.0),
  (41.0, 42.0),
  (43.0, 44.0),
  (45.0, 'inf'),
  ('inf', 46.0),
  (47.0, 'nan'),
  ('nan', 48.0);
GO
