-- Conversion of money to varchar
DECLARE @val MONEY = 1234
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, @val, 126);
GO

DECLARE @val MONEY = 0
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, @val, 126);
GO

DECLARE @val MONEY = 123.12
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, @val, 126);
GO

DECLARE @val MONEY = 0.12456
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, @val, 126);
GO

DECLARE @val MONEY = 123456789123456.12456
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, @val, 126);
GO

SELECT val,
    val_convert = '$' + CONVERT(VARCHAR, val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR, val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR, val, 126)
FROM test_conv_money_to_varchar_t1
GO

SELECT val,
    val_convert = '$' + CONVERT(VARCHAR(10), val),
    val_convert_style_0 = '$' + CONVERT(VARCHAR(10), val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR(10), val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR(10), val, 2),
    val_convert_style_126 = '$' + CONVERT(VARCHAR(10), val, 126)
FROM test_conv_money_to_varchar_t1
GO

-- Conversion of money to char
DECLARE @val MONEY = 1234
SELECT @val,
    val_convert = '$' + CONVERT(CHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), @val, 126);
GO

DECLARE @val MONEY = 0
SELECT @val,
    val_convert = '$' + CONVERT(CHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), @val, 126);
GO

DECLARE @val MONEY = 123.12
SELECT @val,
    val_convert = '$' + CONVERT(CHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), @val, 126);
GO

DECLARE @val MONEY = 0.12456
SELECT @val,
    val_convert = '$' + CONVERT(CHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), @val, 126);
GO

DECLARE @val MONEY = 123456789123456.12456
SELECT @val,
    val_convert = '$' + CONVERT(CHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), @val, 126);
GO

SELECT val,
    val_convert = '$' + CONVERT(CHAR(25), val),
    val_convert_style_0 = '$' + CONVERT(CHAR(25), val, 0),
    val_convert_style_1 = '$' + CONVERT(CHAR(25), val, 1),
    val_convert_style_2 = '$' + CONVERT(CHAR(25), val, 2),
    val_convert_style_126 = '$' + CONVERT(CHAR(25), val, 126)
FROM test_conv_money_to_varchar_t1
GO

-- Conversion of money to nvarchar
DECLARE @val MONEY = 1234
SELECT @val,
    val_convert = '$' + CONVERT(NVARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, @val, 126);
GO

DECLARE @val MONEY = 0
SELECT @val,
    val_convert = '$' + CONVERT(NVARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, @val, 126);
GO

DECLARE @val MONEY = 123.12
SELECT @val,
    val_convert = '$' + CONVERT(NVARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, @val, 126);
GO

DECLARE @val MONEY = 0.12456
SELECT @val,
    val_convert = '$' + CONVERT(NVARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, @val, 126);
GO

DECLARE @val MONEY = 123456789123456.12456
SELECT @val,
    val_convert = '$' + CONVERT(NVARCHAR, @val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, @val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, @val, 126);
GO

SELECT val,
    val_convert = '$' + CONVERT(NVARCHAR, val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR, val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR, val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR, val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR, val, 126)
FROM test_conv_money_to_varchar_t1
GO

SELECT val,
    val_convert = '$' + CONVERT(NVARCHAR(10), val),
    val_convert_style_0 = '$' + CONVERT(NVARCHAR(10), val, 0),
    val_convert_style_1 = '$' + CONVERT(NVARCHAR(10), val, 1),
    val_convert_style_2 = '$' + CONVERT(NVARCHAR(10), val, 2),
    val_convert_style_126 = '$' + CONVERT(NVARCHAR(10), val, 126)
FROM test_conv_money_to_varchar_t1
GO

-- Conversion of money to nchar
DECLARE @val MONEY = 1234
SELECT @val,
    val_convert = '$' + CONVERT(NCHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), @val, 126);
GO

DECLARE @val MONEY = 0
SELECT @val,
    val_convert = '$' + CONVERT(NCHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), @val, 126);
GO

DECLARE @val MONEY = 123.12
SELECT @val,
    val_convert = '$' + CONVERT(NCHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), @val, 126);
GO

DECLARE @val MONEY = 0.12456
SELECT @val,
    val_convert = '$' + CONVERT(NCHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), @val, 126);
GO

DECLARE @val MONEY = 123456789123456.12456
SELECT @val,
    val_convert = '$' + CONVERT(NCHAR(25), @val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), @val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), @val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), @val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), @val, 126);
GO

SELECT val,
    val_convert = '$' + CONVERT(NCHAR(25), val),
    val_convert_style_0 = '$' + CONVERT(NCHAR(25), val, 0),
    val_convert_style_1 = '$' + CONVERT(NCHAR(25), val, 1),
    val_convert_style_2 = '$' + CONVERT(NCHAR(25), val, 2),
    val_convert_style_126 = '$' + CONVERT(NCHAR(25), val, 126)
FROM test_conv_money_to_varchar_t1
GO

-- Dependent objects
SELECT * FROM test_conv_string_to_date_v1
GO

EXEC test_conv_string_to_date_p1
GO

SELECT * FROM test_conv_string_to_date_f1()
GO
