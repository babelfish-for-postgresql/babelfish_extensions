-- INTEGER Types
SELECT SQRT(144);
GO
SELECT SQRT(0);
GO
SELECT SQRT(-144);
GO
SELECT SQRT(2147483647);
GO
SELECT SQRT(9223372036854775807);
GO
SELECT SQRT(32767);
GO
SELECT SQRT(255);
GO
SELECT SQRT(9223372036854775808);
GO
SELECT SQRT(CAST(2147483647 AS INT));
GO
SELECT SQRT(CAST(2147483648 AS INT));
GO
SELECT SQRT(CAST(9223372036854775807 AS BIGINT));
GO
SELECT SQRT(CAST(9223372036854775808 AS BIGINT));
GO
SELECT SQRT(CAST(32767 AS SMALLINT));
GO
SELECT SQRT(CAST(32768 AS SMALLINT));
GO
SELECT SQRT(CAST(255 AS TINYINT));
GO
SELECT SQRT(CAST(256 AS TINYINT));
GO

-- Numeric/Decimal
SELECT SQRT(144.00);
GO
SELECT SQRT(0.00);
GO
SELECT SQRT(-144.00);
GO
SELECT SQRT(NULL);
GO
SELECT SQRT(9999999999.99);
GO
SELECT SQRT(0.0001);
GO
SELECT SQRT(12.25);
GO
SELECT SQRT(9999999999999999999999999999999999999.99);
GO
SELECT SQRT(CAST(99999999999999999999999999999999999999.99 AS NUMERIC(38,2)));
GO

-- BIT
SELECT SQRT(CAST(1 AS BIT));
GO
SELECT SQRT(CAST(0 AS BIT));
GO
SELECT SQRT(CAST(NULL AS BIT));
GO

-- MONEY
SELECT SQRT(CAST(144.00 AS MONEY));
GO
SELECT SQRT(CAST(0.00 AS MONEY));
GO
SELECT SQRT(CAST(-144.00 AS MONEY));
GO
SELECT SQRT(CAST(NULL AS MONEY));
GO
SELECT SQRT(CAST(0.0001 AS MONEY));
GO
SELECT SQRT(CAST(12.25 AS MONEY));
GO
SELECT SQRT(CAST(922337203685477.5807 AS MONEY));
GO
SELECT SQRT(CAST(922337203685477.581 AS MONEY));
GO

-- SMALLMONEY
SELECT SQRT(CAST(144.00 AS SMALLMONEY));
GO
SELECT SQRT(CAST(0.00 AS SMALLMONEY));
GO
SELECT SQRT(CAST(-144.00 AS SMALLMONEY));
GO
SELECT SQRT(CAST(NULL AS SMALLMONEY));
GO
SELECT SQRT(CAST(214748.3647 AS SMALLMONEY));
GO
SELECT SQRT(CAST(0.0001 AS SMALLMONEY));
GO
SELECT SQRT(CAST(12.25 AS SMALLMONEY));
GO
SELECT SQRT(CAST(214748.365 AS SMALLMONEY));
GO

-- FLOAT
SELECT SQRT(CAST(144.00 AS FLOAT));
GO
SELECT SQRT(CAST(0.00 AS FLOAT));
GO
SELECT SQRT(CAST(-144.00 AS FLOAT));
GO
SELECT SQRT(CAST(NULL AS FLOAT));
GO
SELECT SQRT(CAST(1.79E+308 AS FLOAT));
GO
SELECT SQRT(CAST(2.23E-308 AS FLOAT));
GO
SELECT SQRT(CAST(12.25 AS FLOAT));
GO
SELECT SQRT(CAST(1.79769E+308 AS FLOAT));
GO
SELECT SQRT(CAST(2.22507E-308 AS FLOAT));  
GO
SELECT SQRT(CAST(1.79E+309 AS FLOAT));
GO
SELECT SQRT(CAST(2.22E-308 AS FLOAT));
GO

-- REAL
SELECT SQRT(CAST(144.00 AS REAL));
GO
SELECT SQRT(CAST(0.00 AS REAL));
GO
SELECT SQRT(CAST(-144.00 AS REAL));
GO
SELECT SQRT(CAST(NULL AS REAL));
GO
SELECT SQRT(CAST(3.40E+38 AS REAL));
GO
SELECT SQRT(CAST(1.18E-38 AS REAL));
GO
SELECT SQRT(CAST(12.25 AS REAL));
GO
SELECT SQRT(CAST(3.40282E+38 AS REAL));
GO
SELECT SQRT(CAST(1.17549E-38 AS REAL));
GO
SELECT SQRT(CAST(3.41E+38 AS REAL));
GO
SELECT SQRT(CAST(1.17E-38 AS REAL));
GO

-- Character Types
SELECT SQRT('144');
GO
SELECT SQRT('0');
GO
SELECT SQRT('-144');
GO
SELECT SQRT('ABC');
GO
SELECT SQRT('12.25');
GO
SELECT SQRT(N'144');
GO
SELECT SQRT(N'12.25');
GO

-- Tables
SELECT SQRT(numeric_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(numeric_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(decimal_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(decimal_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(bigint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(bigint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(int_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(int_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(smallint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(smallint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(tinyint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(tinyint_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(money_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(money_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(smallmoney_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(smallmoney_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(bit_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id != 8;
GO
SELECT SQRT(bit_val) FROM BABEL_5672_sqrt_exact_numeric_table WHERE id = 8;
GO

SELECT SQRT(float_val) FROM BABEL_5672_sqrt_approximate_numeric_table WHERE id != 8;
GO
SELECT SQRT(float_val) FROM BABEL_5672_sqrt_approximate_numeric_table WHERE id = 8;
GO

SELECT SQRT(real_val) FROM BABEL_5672_sqrt_approximate_numeric_table WHERE id != 8;
GO
SELECT SQRT(real_val) FROM BABEL_5672_sqrt_approximate_numeric_table WHERE id = 8;
GO

SELECT SQRT(char_val) FROM BABEL_5672_sqrt_char_table WHERE id != 4;
GO
SELECT SQRT(char_val) FROM BABEL_5672_sqrt_char_table WHERE id = 4;
GO

SELECT SQRT(varchar_val) FROM BABEL_5672_sqrt_char_table WHERE id != 4;
GO
SELECT SQRT(varchar_val) FROM BABEL_5672_sqrt_char_table WHERE id = 4;
GO

SELECT SQRT(nchar_val) FROM BABEL_5672_sqrt_unicode_table WHERE id != 4;
GO
SELECT SQRT(nchar_val) FROM BABEL_5672_sqrt_unicode_table WHERE id = 4;
GO

SELECT SQRT(nvarchar_val) FROM BABEL_5672_sqrt_unicode_table WHERE id != 4;
GO
SELECT SQRT(nvarchar_val) FROM BABEL_5672_sqrt_unicode_table WHERE id = 4;
GO

-- Views
SELECT * FROM BABEL_5672_sqrt_numeric;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_zero;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_negative;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_null;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_max;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_min;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_overflow1;
GO
SELECT * FROM BABEL_5672_sqrt_numeric_overflow2;
GO

SELECT * FROM BABEL_5672_sqrt_decimal;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_zero;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_negative;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_null;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_max;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_min;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_overflow1;
GO
SELECT * FROM BABEL_5672_sqrt_decimal_overflow2;
GO

SELECT * FROM BABEL_5672_sqrt_bit;
GO
SELECT * FROM BABEL_5672_sqrt_bit_zero;
GO
SELECT * FROM BABEL_5672_sqrt_bit_null;
GO

SELECT * FROM BABEL_5672_sqrt_int;
GO
SELECT * FROM BABEL_5672_sqrt_int_zero;
GO
SELECT * FROM BABEL_5672_sqrt_int_negative;
GO
SELECT * FROM BABEL_5672_sqrt_int_null;
GO
SELECT * FROM BABEL_5672_sqrt_int_max;
GO
SELECT * FROM BABEL_5672_sqrt_int_min;
GO
SELECT * FROM BABEL_5672_sqrt_int_overflow;
GO

SELECT * FROM BABEL_5672_sqrt_bigint;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_zero;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_negative;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_null;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_max;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_min;
GO
SELECT * FROM BABEL_5672_sqrt_bigint_overflow;
GO

SELECT * FROM BABEL_5672_sqrt_smallint;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_zero;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_negative;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_null;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_max;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_min;
GO
SELECT * FROM BABEL_5672_sqrt_smallint_overflow;
GO

SELECT * FROM BABEL_5672_sqrt_tinyint;
GO
SELECT * FROM BABEL_5672_sqrt_tinyint_zero;
GO
SELECT * FROM BABEL_5672_sqrt_tinyint_null;
GO
SELECT * FROM BABEL_5672_sqrt_tinyint_max;
GO
SELECT * FROM BABEL_5672_sqrt_tinyint_min;
GO
SELECT * FROM BABEL_5672_sqrt_tinyint_overflow;
GO

SELECT * FROM BABEL_5672_sqrt_float;
GO
SELECT * FROM BABEL_5672_sqrt_float_zero;
GO
SELECT * FROM BABEL_5672_sqrt_float_negative;
GO
SELECT * FROM BABEL_5672_sqrt_float_null;
GO
SELECT * FROM BABEL_5672_sqrt_float_max;
GO
SELECT * FROM BABEL_5672_sqrt_float_min;
GO
SELECT * FROM BABEL_5672_sqrt_float_overflow;
GO
SELECT * FROM BABEL_5672_sqrt_float_underflow;
GO

SELECT * FROM BABEL_5672_sqrt_real;
GO
SELECT * FROM BABEL_5672_sqrt_real_zero;
GO
SELECT * FROM BABEL_5672_sqrt_real_negative;
GO
SELECT * FROM BABEL_5672_sqrt_real_null;
GO
SELECT * FROM BABEL_5672_sqrt_real_max;
GO
SELECT * FROM BABEL_5672_sqrt_real_min;
GO
SELECT * FROM BABEL_5672_sqrt_real_overflow;
GO
SELECT * FROM BABEL_5672_sqrt_real_underflow;
GO

SELECT * FROM BABEL_5672_sqrt_money;
GO
SELECT * FROM BABEL_5672_sqrt_money_zero;
GO
SELECT * FROM BABEL_5672_sqrt_money_negative;
GO
SELECT * FROM BABEL_5672_sqrt_money_null;
GO
SELECT * FROM BABEL_5672_sqrt_money_max;
GO
SELECT * FROM BABEL_5672_sqrt_money_min;
GO
SELECT * FROM BABEL_5672_sqrt_money_overflow;
GO

SELECT * FROM BABEL_5672_sqrt_smallmoney;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_zero;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_negative;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_null;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_max;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_min;
GO
SELECT * FROM BABEL_5672_sqrt_smallmoney_overflow;
GO

-- Functions
SELECT BABEL_5672_sqrt_test_numeric();
GO
SELECT BABEL_5672_sqrt_test_numeric_zero();
GO
SELECT BABEL_5672_sqrt_test_numeric_negative();
GO
SELECT BABEL_5672_sqrt_test_numeric_null();
GO
SELECT BABEL_5672_sqrt_test_numeric_overflow();
GO

SELECT BABEL_5672_sqrt_test_decimal();
GO
SELECT BABEL_5672_sqrt_test_decimal_zero();
GO
SELECT BABEL_5672_sqrt_test_decimal_negative();
GO
SELECT BABEL_5672_sqrt_test_decimal_null();
GO
SELECT BABEL_5672_sqrt_test_decimal_overflow();
GO

SELECT BABEL_5672_sqrt_test_bit();
GO
SELECT BABEL_5672_sqrt_test_bit_zero();
GO
SELECT BABEL_5672_sqrt_test_bit_null();
GO

-- Procedures
EXEC BABEL_5672_sqrt_test_numeric_proc;
GO
EXEC BABEL_5672_sqrt_test_numeric_zero_proc;
GO
EXEC BABEL_5672_sqrt_test_numeric_negative_proc;
GO
EXEC BABEL_5672_sqrt_test_numeric_null_proc;
GO
EXEC BABEL_5672_sqrt_test_numeric_overflow_proc;
GO

EXEC BABEL_5672_sqrt_test_decimal_proc;
GO
EXEC BABEL_5672_sqrt_test_decimal_zero_proc;
GO
EXEC BABEL_5672_sqrt_test_decimal_negative_proc;
GO
EXEC BABEL_5672_sqrt_test_decimal_null_proc;
GO
EXEC BABEL_5672_sqrt_test_decimal_overflow_proc;
GO

EXEC BABEL_5672_sqrt_test_bit_proc;
GO
EXEC BABEL_5672_sqrt_test_bit_zero_proc;
GO
EXEC BABEL_5672_sqrt_test_bit_null_proc;
GO
