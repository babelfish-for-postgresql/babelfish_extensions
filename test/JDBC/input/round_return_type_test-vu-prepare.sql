-- Create a table to test ROUND function with various data types
CREATE TABLE TestRound(
    id INT IDENTITY(1,1) PRIMARY KEY,
    float_data FLOAT NOT NULL,
    decimal_data DECIMAL(10,4) NOT NULL,
    int_data INT NOT NULL,
    round_float_0 AS (ROUND(float_data, 0)) PERSISTED,
    round_float_2 AS (ROUND(float_data, 2)) PERSISTED,
    round_decimal_0 AS (ROUND(decimal_data, 0)) PERSISTED,
    round_decimal_2 AS (ROUND(decimal_data, 2)) PERSISTED,
    round_int_0 AS (ROUND(CAST(int_data AS FLOAT), 0)) PERSISTED,
    round_int_2 AS (ROUND(CAST(int_data AS FLOAT), 2)) PERSISTED
);
GO

-- Function to round FLOAT to specified decimal places
CREATE FUNCTION dbo.RoundFloat
(
    @Input FLOAT,
    @Decimals INT
)
RETURNS FLOAT
AS
BEGIN
    RETURN ROUND(@Input, @Decimals);
END
GO

-- Function to round DECIMAL to specified decimal places
CREATE FUNCTION dbo.RoundDecimal
(
    @Input DECIMAL(18,6),
    @Decimals INT
)
RETURNS DECIMAL(18,6)
AS
BEGIN
    RETURN ROUND(@Input, @Decimals);
END
GO

-- View that demonstrates rounding of different data types
CREATE VIEW dbo.RoundDemoView
AS
SELECT 
    dbo.RoundFloat(3.14159, 2) AS RoundedPiFloat,
    dbo.RoundDecimal(3.14159, 2) AS RoundedPiDecimal,
    ROUND(CAST(314 AS FLOAT) / 100, 2) AS RoundedIntAsPi
GO

-- Insert sample data into TestRound table
INSERT INTO TestRound (float_data, decimal_data, int_data)
VALUES 
(3.14159, 3.14159, 3),
(2.71828, 2.71828, 3),
(1.41421, 1.41421, 1),
(9.99999, 9.99999, 10);
GO

-- View to demonstrate rounding in TestRound table
CREATE VIEW dbo.TestRoundView
AS
SELECT 
    id,
    float_data,
    decimal_data,
    int_data,
    round_float_0,
    round_float_2,
    round_decimal_0,
    round_decimal_2,
    round_int_0,
    round_int_2
FROM TestRound
GO

-- Function to round multiple types
CREATE FUNCTION dbo.RoundMultipleTypes
(
    @FloatInput FLOAT,
    @DecimalInput DECIMAL(10,4),
    @IntInput INT,
    @Decimals INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ROUND(@FloatInput, @Decimals) AS RoundedFloat,
        ROUND(@DecimalInput, @Decimals) AS RoundedDecimal,
        ROUND(CAST(@IntInput AS FLOAT), @Decimals) AS RoundedInt
)
GO

-- View to demonstrate rounding of multiple types
CREATE VIEW dbo.RoundMultipleTypesView
AS
SELECT *
FROM dbo.RoundMultipleTypes(3.14159, 3.14159, 3, 2)
GO

-- Cleanup
-- DROP VIEW dbo.RoundMultipleTypesView;
-- DROP FUNCTION dbo.RoundMultipleTypes;
-- DROP VIEW dbo.TestRoundView;
-- DROP VIEW dbo.RoundDemoView;
-- DROP FUNCTION dbo.RoundDecimal;
-- DROP FUNCTION dbo.RoundFloat;
-- DROP TABLE TestRound;
