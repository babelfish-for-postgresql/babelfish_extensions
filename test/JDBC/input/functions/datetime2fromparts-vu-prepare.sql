-- [BABEL-1627, 2827] Support DATETIME2FROMPARTS Transact-SQL function
-- Tests for NEW behavior (version 17.7+) - specifically test fractions > 32767 (smallint bug fix)
-- These test the updated behavior where fractions parameter supports values up to 9999999

CREATE VIEW datetime2fromparts_vu_prepare_v1 AS 
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 32768, 5) AS just_above_smallint;
GO

CREATE VIEW datetime2fromparts_vu_prepare_v2 AS
SELECT DATETIME2FROMPARTS(2024, 2, 29, 12, 30, 45, 100000, 6) AS high_fraction;
GO

CREATE VIEW datetime2fromparts_vu_prepare_v3 AS
SELECT DATETIME2FROMPARTS(2023, 2, 28, 23, 59, 59, 9999999, 7) AS max_fraction;
GO

CREATE VIEW datetime2fromparts_vu_prepare_v4 AS
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 30, 45, 1234567, 7) AS high_precision_fraction;
GO

CREATE VIEW datetime2fromparts_vu_prepare_v5 AS
SELECT DATETIME2FROMPARTS(2023, 6, 15, 10, 20, 30, 500000, 6) AS mid_range_fraction;
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p1 AS
SELECT 
    DATETIME2FROMPARTS(2020, 1, 1, 9, 0, 0, 50000, 5) AS frac_50000,
    DATETIME2FROMPARTS(2021, 6, 15, 12, 30, 45, 999999, 6) AS frac_999999,
    DATETIME2FROMPARTS(2022, 12, 31, 23, 59, 59, 9999999, 7) AS frac_9999999;
GO

CREATE PROCEDURE datetime2fromparts_vu_prepare_p2 AS
SELECT DATETIME2FROMPARTS(2023, 1, 1, 12, 0, 0, 32768, 5) AS result;
GO

CREATE FUNCTION datetime2fromparts_vu_prepare_f1()
RETURNS DATETIME2 AS
BEGIN
    RETURN (SELECT DATETIME2FROMPARTS(2023, 1, 15, 14, 35, 42, 7654321, 7));
END
GO

CREATE FUNCTION datetime2fromparts_vu_prepare_f2()
RETURNS DATETIME2 AS
BEGIN
    RETURN (SELECT DATETIME2FROMPARTS(2023, 6, 30, 18, 45, 12, 888888, 6));
END
GO

-- Test table with high fraction values
CREATE TABLE datetime2fromparts_vu_prepare_t1 (
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

INSERT INTO datetime2fromparts_vu_prepare_t1 VALUES
(1, 2023, 1, 1, 12, 0, 0, 32767, 5),   -- max smallint
(2, 2023, 1, 1, 12, 0, 0, 32768, 5),   -- above smallint
(3, 2023, 1, 1, 12, 0, 0, 100000, 6),  -- 100k
(4, 2023, 1, 1, 12, 0, 0, 999999, 6),  -- max precision 6
(5, 2023, 1, 1, 12, 0, 0, 9999999, 7); -- max precision 7
GO
