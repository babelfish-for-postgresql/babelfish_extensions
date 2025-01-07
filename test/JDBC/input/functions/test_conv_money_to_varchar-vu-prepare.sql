CREATE TABLE test_conv_money_to_varchar_t1(val money)
GO

INSERT INTO test_conv_money_to_varchar_t1 VALUES (1234), (0), (123.12), (0.12456)
GO

CREATE VIEW test_conv_string_to_date_v1 as (
    SELECT val,
        val_convert = '$' + CONVERT(VARCHAR, val) ,
        val_convert_style_0 = '$' + CONVERT(VARCHAR, val, 0),
        val_convert_style_1 = '$' + CONVERT(VARCHAR, val, 1),
        val_convert_style_2 = '$' + CONVERT(VARCHAR, val, 2)
    FROM test_conv_money_to_varchar_t1
);
GO

CREATE PROCEDURE test_conv_string_to_date_p1 as (
    SELECT val,
        val_convert = '$' + CONVERT(VARCHAR, val) ,
        val_convert_style_0 = '$' + CONVERT(VARCHAR, val, 0),
        val_convert_style_1 = '$' + CONVERT(VARCHAR, val, 1),
        val_convert_style_2 = '$' + CONVERT(VARCHAR, val, 2)
    FROM test_conv_money_to_varchar_t1
);
GO

CREATE FUNCTION test_conv_string_to_date_f1()
RETURNS TABLE AS
RETURN (
    SELECT val,
        val_convert = '$' + CONVERT(VARCHAR, val) ,
        val_convert_style_0 = '$' + CONVERT(VARCHAR, val, 0),
        val_convert_style_1 = '$' + CONVERT(VARCHAR, val, 1),
        val_convert_style_2 = '$' + CONVERT(VARCHAR, val, 2)
    FROM test_conv_money_to_varchar_t1
);
GO
