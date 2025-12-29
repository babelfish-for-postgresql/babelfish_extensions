DROP TABLE money_style_conversion_test;
GO

DROP TABLE smallmoney_style_conversion_test;
GO

DROP VIEW money_style_test_v1;
GO

DROP VIEW money_style_test_v2;
GO

DROP VIEW money_style_test_v3;
GO

DROP VIEW money_style_test_v4;
GO

DROP VIEW money_style_test_v5;
GO

DROP VIEW smallmoney_style_test_v1;
GO

DROP VIEW smallmoney_style_test_v2;
GO

DROP VIEW smallmoney_style_test_v3;
GO

DROP VIEW smallmoney_style_test_v4;
GO

DROP VIEW smallmoney_style_test_v5;
GO

DROP PROCEDURE money_style_test_p1;
GO

DROP PROCEDURE money_style_test_p2;
GO

DROP PROCEDURE money_style_test_p3;
GO

DROP PROCEDURE money_style_test_p4;
GO

DROP PROCEDURE money_style_test_p5;
GO

DROP PROCEDURE smallmoney_style_test_p1;
GO

DROP PROCEDURE smallmoney_style_test_p2;
GO

DROP PROCEDURE smallmoney_style_test_p3;
GO

DROP PROCEDURE smallmoney_style_test_p4;
GO

DROP PROCEDURE smallmoney_style_test_p5;
GO

--datetime, date, time style conversion test cleanup
DROP TABLE datetime_style_conversion_test;
GO

DROP TABLE date_style_conversion_test;
GO

DROP TABLE time_style_conversion_test;
GO

DROP VIEW datetime_style_test_v1;
GO

DROP VIEW datetime_style_test_v2;
GO

DROP VIEW datetime_style_test_v3;
GO

DROP VIEW date_style_test_v1;
GO

DROP VIEW date_style_test_v2;
GO

DROP VIEW time_style_test_v1;
GO

DROP PROCEDURE datetime_style_test_p1;
GO

DROP PROCEDURE date_style_test_p1;
GO

DROP PROCEDURE time_style_test_p1;
GO

DROP PROCEDURE convert_money_range;
GO

DROP PROCEDURE convert_datetime_range;
GO

DROP PROCEDURE test_convert_with_style_all_types;
GO

-- Drop views
DROP VIEW money_smallmoney_conversions;
GO

DROP VIEW datetime_date_time_conversions;
GO

DROP VIEW string_conversions;
GO

-- Drop tables
DROP TABLE money_smallmoney_table;
GO

DROP TABLE datetime_date_time_data;
GO

DROP TABLE negative_decimal_style_test;
GO

DROP TABLE edge_style_test;
GO

DROP TABLE combined_conversion_test;
GO

DROP TABLE null_overflow_test;
GO

DROP TABLE char_conversion_test;
GO

-- Drop user-defined types
DROP TYPE MoneyRange;
GO

DROP TYPE DateTimeRange;
GO

DROP PROCEDURE test_all_conversions;
GO