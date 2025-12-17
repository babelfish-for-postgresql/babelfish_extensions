-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
-- Tests for datetime2fromparts OLD behavior (before version 17.7)
-- These objects will be created on old version and verified after upgrade
-- Use only fraction values <= 32767 (smallint limit) since old version had this bug

CREATE VIEW datetime2fromparts_before_17_7_v1 AS 
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 123, 3) AS result;
GO

CREATE VIEW datetime2fromparts_before_17_7_v2 AS 
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 12345, 5) AS result;
GO

CREATE VIEW datetime2fromparts_before_17_7_v3 AS 
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 32767, 5) AS max_smallint_result;
GO

CREATE VIEW datetime2fromparts_before_17_7_v4 AS
SELECT DATETIME2FROMPARTS(2024, 2, 29, 12, 30, 45, 999, 3) AS leap_year_result;
GO

CREATE PROCEDURE datetime2fromparts_before_17_7_p1 AS
SELECT DATETIME2FROMPARTS(2020, 1, 1, 9, 0, 0, 0, 0) AS result;
GO

CREATE PROCEDURE datetime2fromparts_before_17_7_p2 AS
SELECT 
    DATETIME2FROMPARTS(2020, 1, 1, 9, 0, 0, 0, 0) AS precision_0,
    DATETIME2FROMPARTS(2021, 6, 15, 12, 30, 45, 9999, 4) AS precision_4,
    DATETIME2FROMPARTS(2022, 12, 31, 23, 59, 59, 32767, 5) AS precision_5_max_smallint;
GO

CREATE FUNCTION datetime2fromparts_before_17_7_f1()
RETURNS DATETIME2 AS
BEGIN
    RETURN (SELECT DATETIME2FROMPARTS(2021, 6, 15, 12, 30, 45, 999, 3));
END
GO

CREATE FUNCTION datetime2fromparts_before_17_7_f2()
RETURNS DATETIME2 AS
BEGIN
    RETURN (SELECT DATETIME2FROMPARTS(2023, 1, 15, 14, 35, 42, 12345, 5));
END
GO

-- Test table for complex scenarios with old behavior (fractions <= 32767)
CREATE TABLE datetime2fromparts_before_17_7_t1 (
    ID INT PRIMARY KEY,
    Year INT,
    Month INT,
    Day INT,
    Hour INT,
    Minute INT,
    Second INT,
    Fraction INT,
    Precision INT
);
GO

INSERT INTO datetime2fromparts_before_17_7_t1 VALUES
(1, 2020, 1, 1, 9, 0, 0, 0, 0),
(2, 2021, 6, 15, 12, 30, 45, 1, 1),
(3, 2022, 6, 15, 12, 30, 45, 12, 2),
(4, 2023, 6, 15, 12, 30, 45, 123, 3),
(5, 2024, 6, 15, 12, 30, 45, 9999, 4),
(6, 2025, 12, 31, 23, 59, 59, 32767, 5);
GO
