USE babel_3489_test_db;
GO

SELECT * FROM col_length_prepare_v1
GO

SELECT * FROM col_length_prepare_v2
GO

SELECT * FROM col_length_prepare_v3
GO

SELECT * FROM col_length_prepare_v4
GO

SELECT * FROM col_length_prepare_v5
GO

SELECT * FROM col_length_prepare_v6
GO

SELECT * FROM col_length_prepare_v7
GO

SELECT * FROM col_length_prepare_v8
GO

SELECT * FROM col_length_prepare_v9
GO

SELECT * FROM col_length_prepare_v10
GO

EXEC col_length_prepare_p1
GO

EXEC col_length_prepare_p2
GO

EXEC col_length_prepare_p3
GO

EXEC col_length_prepare_p4
GO

EXEC col_length_prepare_p5
GO

EXEC col_length_prepare_p6
GO

EXEC col_length_prepare_p7
GO

EXEC col_length_prepare_p8
GO

EXEC col_length_prepare_p9
GO

EXEC col_length_prepare_p10
GO

SELECT col_length_prepare_f1()
GO

SELECT col_length_prepare_f2()
GO

SELECT col_length_prepare_f3()
GO

SELECT col_length_prepare_f4()
GO

SELECT col_length_prepare_f5()
GO

SELECT col_length_prepare_f6()
GO

SELECT col_length_prepare_f7()
GO

SELECT col_length_prepare_f8()
GO

SELECT col_length_prepare_f9()
GO

SELECT col_length_prepare_f10()
GO

SELECT col_length_prepare_f11()
GO

SELECT col_length_prepare_f12()
GO

SELECT col_length_prepare_f13()
GO

SELECT col_length_prepare_f14()
GO

SELECT col_length_prepare_f15()
GO

SELECT col_length_prepare_f16()
GO

SELECT * FROM sys.COL_LENGTH(NULL, NULL);
GO

SELECT * FROM sys.COL_LENGTH();
GO

SELECT * FROM sys.COL_LENGTH('sys_col_length_test_schema.test_table', 'col_char');
GO

SELECT * FROM sys.COL_LENGTH('sys_col_length_test_schema.test_table', 'col_varchar');
GO

SELECT * FROM sys.COL_LENGTH('sys_col_length_test_schema.test_table', 'col_varbinary');
GO

SELECT * FROM sys.COL_LENGTH('sys_col_length_test_schema.invalid_test_table', 'col_char');
GO

SELECT * FROM sys.COL_LENGTH('sys_column_length_test_table', 'col_date');
GO

SELECT * FROM sys.COL_LENGTH('sys_column_length_test_table', 'col_decimal');
GO

SELECT * FROM sys.COL_LENGTH('sys_column_length_test_table', 'col_numeric');
GO