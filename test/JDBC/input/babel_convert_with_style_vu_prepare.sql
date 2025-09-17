-- Tables
CREATE TABLE money_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value MONEY,
    style_number SQL_VARIANT,
    description VARCHAR(100)
);
GO

INSERT INTO money_style_conversion_test (test_value, style_number, description) VALUES
-- Basic test cases
(1234.1357, 0, 'Basic decimal - style 0'),
(1234.1357, 1, 'Basic decimal - style 1'),
(1234.1357, 2, 'Basic decimal - style 2'),
(1234.1357, 126, 'Basic decimal - style 126'),
(1234.1357, NULL, 'Basic decimal - NULL style'),

-- Negative numbers
(-1234.1357, 0, 'Negative decimal - style 0'),
(-1234.1357, 1, 'Negative decimal - style 1'),
(-1234.1357, 2, 'Negative decimal - style 2'),

-- Edge cases for MONEY
(922337203685477.5807, 0, 'Maximum MONEY value'),
(-922337203685477.5808, 0, 'Minimum MONEY value'),
(922337203685477.5807, 1, 'Maximum MONEY value with comma format'),
(-922337203685477.5808, 1, 'Minimum MONEY value with comma format'),

-- Zero values
(0.00, 0, 'Zero value - style 0'),
(0.00, 1, 'Zero value - style 1'),
(0.00, 2, 'Zero value - style 2'),

-- Decimal places variations
(1234.10, 0, 'Two decimal places'),
(1234.1, 0, 'One decimal place'),
(1234.0000, 0, 'Four trailing zeros'),
(0.1234, 0, 'Leading zero decimal'),

-- Negative styles
(123.45, -1, 'Negative style -1'),
(123.45, -126, 'Negative style -126'),

-- Float-like values
(123.45678901234, 0, 'Float-like decimal'),
(-123.45678901234, 0, 'Negative float-like decimal'),

-- Large numbers with decimals
(123456789.1234, 0, 'Large number with decimals'),
(-123456789.1234, 1, 'Large negative with comma format'),

-- Currency symbol values
($123.45, 0, 'Currency symbol value'),
(-$123.45, 1, 'Negative currency symbol value');
GO

CREATE TABLE smallmoney_style_conversion_test (
    id INT IDENTITY(1,1) PRIMARY KEY,
    test_value SMALLMONEY,
    style_number SQL_VARIANT,
    description VARCHAR(100)
);
GO

INSERT INTO smallmoney_style_conversion_test (test_value, style_number, description) VALUES
-- Basic test cases
(1234.1357, 0, 'Basic decimal - style 0'),
(1234.1357, 1, 'Basic decimal - style 1'),
(1234.1357, 2, 'Basic decimal - style 2'),
(1234.1357, 126, 'Basic decimal - style 126'),
(1234.1357, NULL, 'Basic decimal - NULL style'),

-- Negative numbers
(-1234.1357, 0, 'Negative decimal - style 0'),
(-1234.1357, 1, 'Negative decimal - style 1'),
(-1234.1357, 2, 'Negative decimal - style 2'),

-- Edge cases for SMALLMONEY
(214748.3647, 0, 'Maximum SMALLMONEY value'),
(-214748.3648, 0, 'Minimum SMALLMONEY value'),
(214748.3647, 1, 'Maximum SMALLMONEY with comma format'),
(-214748.3648, 1, 'Minimum SMALLMONEY with comma format'),

-- Zero values
(0.00, 0, 'Zero value - style 0'),
(0.00, 1, 'Zero value - style 1'),
(0.00, 2, 'Zero value - style 2'),

-- Decimal places variations
(1234.10, 0, 'Two decimal places'),
(1234.1, 0, 'One decimal place'),
(1234.0000, 0, 'Four trailing zeros'),
(0.1234, 0, 'Leading zero decimal'),

-- Negative styles
(123.45, -1, 'Negative style -1'),
(123.45, -126, 'Negative style -126'),

-- Float-like values
(123.4567, 0, 'Float-like decimal'),
(-123.4567, 0, 'Negative float-like decimal'),

-- Currency symbol values
($123.45, 0, 'Currency symbol value'),
(-$123.45, 1, 'Negative currency symbol value');
GO

-- Create views for MONEY tests
CREATE VIEW money_style_test_v1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY));
GO

CREATE VIEW money_style_test_v2 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 0);
GO

CREATE VIEW money_style_test_v3 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 1);
GO

CREATE VIEW money_style_test_v4 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 2);
GO

CREATE VIEW money_style_test_v5 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 126);
GO

-- Create views for SMALLMONEY tests
CREATE VIEW smallmoney_style_test_v1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY));
GO

CREATE VIEW smallmoney_style_test_v2 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 0);
GO

CREATE VIEW smallmoney_style_test_v3 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 1);
GO

CREATE VIEW smallmoney_style_test_v4 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 2);
GO

CREATE VIEW smallmoney_style_test_v5 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY), 126);
GO

-- Create procedures for MONEY tests
CREATE PROCEDURE money_style_test_p1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY));
GO

CREATE PROCEDURE money_style_test_p2 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), -1);
GO

CREATE PROCEDURE money_style_test_p3 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), -126);
GO

CREATE PROCEDURE money_style_test_p4 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS MONEY), 1.8);
GO

CREATE PROCEDURE money_style_test_p5 AS SELECT CONVERT(VARCHAR, CAST($23.12 AS MONEY), 16);
GO

-- Create procedures for SMALLMONEY tests
CREATE PROCEDURE smallmoney_style_test_p1 AS SELECT CONVERT(VARCHAR, CAST(1234.1357 AS SMALLMONEY));
GO

CREATE PROCEDURE smallmoney_style_test_p2 AS SELECT CONVERT(VARCHAR, CAST(-1234.1357 AS SMALLMONEY));
GO

CREATE PROCEDURE smallmoney_style_test_p3 AS SELECT CONVERT(VARCHAR, CAST(214748.3647 AS SMALLMONEY));
GO

CREATE PROCEDURE smallmoney_style_test_p4 AS SELECT CONVERT(VARCHAR, CAST(-214748.3648 AS SMALLMONEY));
GO

CREATE PROCEDURE smallmoney_style_test_p5 AS SELECT CONVERT(VARCHAR, CAST(0.00 AS SMALLMONEY));
GO
