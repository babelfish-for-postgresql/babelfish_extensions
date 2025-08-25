SELECT SQRT(numeric_val) FROM sqrt_exact_numeric_tests WHERE id != 8;
GO
SELECT SQRT(numeric_val) FROM sqrt_exact_numeric_tests WHERE id = 8;
GO

SELECT SQRT(float_val) FROM sqrt_approximate_numeric_tests WHERE id != 8;
GO
SELECT SQRT(float_val) FROM sqrt_approximate_numeric_tests WHERE id = 8;
GO

SELECT SQRT(varchar_val) FROM sqrt_char_tests WHERE id != 4;
GO
SELECT SQRT(varchar_val) FROM sqrt_char_tests WHERE id = 4;
GO

SELECT SQRT(nvarchar_val) FROM sqrt_unicode_tests WHERE id != 4;
GO
SELECT SQRT(nvarchar_val) FROM sqrt_unicode_tests WHERE id = 4;
GO

SELECT * FROM sqrt_numeric;
GO
SELECT * FROM sqrt_numeric_zero;
GO
SELECT * FROM sqrt_numeric_negative;
GO
SELECT * FROM sqrt_numeric_null;
GO
SELECT * FROM sqrt_numeric_max;
GO
SELECT * FROM sqrt_numeric_min;
GO

SELECT * FROM sqrt_decimal;
GO
SELECT * FROM sqrt_decimal_zero;
GO
SELECT * FROM sqrt_decimal_negative;
GO
SELECT * FROM sqrt_decimal_null;
GO
SELECT * FROM sqrt_decimal_max;
GO
SELECT * FROM sqrt_decimal_min;
GO

SELECT * FROM sqrt_bit;
GO
SELECT * FROM sqrt_bit_zero;
GO
SELECT * FROM sqrt_bit_null;
GO

SELECT * FROM sqrt_int;
GO
SELECT * FROM sqrt_int_zero;
GO
SELECT * FROM sqrt_int_negative;
GO
SELECT * FROM sqrt_int_null;
GO
SELECT * FROM sqrt_int_max;
GO
SELECT * FROM sqrt_int_min;
GO

SELECT * FROM sqrt_bigint;
GO
SELECT * FROM sqrt_bigint_zero;
GO
SELECT * FROM sqrt_bigint_negative;
GO
SELECT * FROM sqrt_bigint_null;
GO
SELECT * FROM sqrt_bigint_max;
GO
SELECT * FROM sqrt_bigint_min;
GO

SELECT * FROM sqrt_smallint;
GO
SELECT * FROM sqrt_smallint_zero;
GO
SELECT * FROM sqrt_smallint_negative;
GO
SELECT * FROM sqrt_smallint_null;
GO
SELECT * FROM sqrt_smallint_max;
GO
SELECT * FROM sqrt_smallint_min;
GO

SELECT * FROM sqrt_tinyint;
GO
SELECT * FROM sqrt_tinyint_zero;
GO
SELECT * FROM sqrt_tinyint_null;
GO
SELECT * FROM sqrt_tinyint_max;
GO
SELECT * FROM sqrt_tinyint_min;
GO

SELECT * FROM sqrt_float;
GO
SELECT * FROM sqrt_float_zero;
GO
SELECT * FROM sqrt_float_negative;
GO
SELECT * FROM sqrt_float_null;
GO
SELECT * FROM sqrt_float_max;
GO
SELECT * FROM sqrt_float_min;
GO

SELECT * FROM sqrt_real;
GO
SELECT * FROM sqrt_real_zero;
GO
SELECT * FROM sqrt_real_negative;
GO
SELECT * FROM sqrt_real_null;
GO
SELECT * FROM sqrt_real_max;
GO
SELECT * FROM sqrt_real_min;
GO

SELECT * FROM sqrt_money;
GO
SELECT * FROM sqrt_money_zero;
GO
SELECT * FROM sqrt_money_negative;
GO
SELECT * FROM sqrt_money_null;
GO
SELECT * FROM sqrt_money_max;
GO
SELECT * FROM sqrt_money_min;
GO

SELECT * FROM sqrt_smallmoney;
GO
SELECT * FROM sqrt_smallmoney_zero;
GO
SELECT * FROM sqrt_smallmoney_negative;
GO
SELECT * FROM sqrt_smallmoney_null;
GO
SELECT * FROM sqrt_smallmoney_max;
GO
SELECT * FROM sqrt_smallmoney_min;
GO

SELECT sqrt_test_numeric();
GO
SELECT sqrt_test_numeric_zero();
GO
SELECT sqrt_test_numeric_negative();
GO
SELECT sqrt_test_numeric_null();
GO

SELECT sqrt_test_decimal();
GO
SELECT sqrt_test_decimal_zero();
GO
SELECT sqrt_test_decimal_negative();
GO
SELECT sqrt_test_decimal_null();
GO

SELECT sqrt_test_bit();
GO
SELECT sqrt_test_bit_zero();
GO
SELECT sqrt_test_bit_null();
GO

EXEC sqrt_test_numeric_proc;
GO
EXEC sqrt_test_numeric_zero_proc;
GO
EXEC sqrt_test_numeric_negative_proc;
GO
EXEC sqrt_test_numeric_null_proc;
GO

EXEC sqrt_test_decimal_proc;
GO
EXEC sqrt_test_decimal_zero_proc;
GO
EXEC sqrt_test_decimal_negative_proc;
GO
EXEC sqrt_test_decimal_null_proc;
GO

EXEC sqrt_test_bit_proc;
GO
EXEC sqrt_test_bit_zero_proc;
GO
EXEC sqrt_test_bit_null_proc;
GO