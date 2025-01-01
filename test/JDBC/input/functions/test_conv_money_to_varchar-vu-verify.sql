DECLARE @val MONEY = 1234
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val MONEY = 0
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val MONEY = 123.12
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val MONEY = 0.12456
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2);
GO

DECLARE @val MONEY = 123456789123456.12456
SELECT @val,
    val_convert = '$' + CONVERT(VARCHAR, @val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, @val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, @val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, @val, 2);
GO

SELECT val,
    val_convert = '$' + CONVERT(VARCHAR, val) ,
    val_convert_style_0 = '$' + CONVERT(VARCHAR, val, 0),
    val_convert_style_1 = '$' + CONVERT(VARCHAR, val, 1),
    val_convert_style_2 = '$' + CONVERT(VARCHAR, val, 2)
FROM test_conv_money_to_varchar_t1

-- Dependent objects
SELECT * FROM test_conv_string_to_date_v1
GO

EXEC test_conv_string_to_date_p1
GO

SELECT * FROM test_conv_string_to_date_f1()
GO
