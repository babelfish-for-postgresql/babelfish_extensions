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

-- case sensitive check
SELECT * FROM sys.COL_LENGTH('sys_column_length_test_TABLE', 'COL_NUMERIC');
GO

SELECT * FROM sys.COL_LENGTH('', '');
GO

-- arguments with CAST
SELECT * FROM sys.COL_LENGTH('sys_column_length_test_TABLE', CAST('col_numeric' as VARCHAR(20)));
GO

SELECT * FROM sys.COL_LENGTH('sys_column_length_test_table', (SELECT CAST('123' as text)));
GO

SELECT * FROM sys.COL_LENGTH((SELECT CAST('abc#$' as VARCHAR(10))), 'col_numeric');
GO

-- Using COL_LENGTH() in queries on tables, returning columns with even length
WITH ColumnLengths AS (
    SELECT COLUMN_NAME,
           sys.COL_LENGTH(TABLE_NAME, COLUMN_NAME) AS ColumnLength
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'sys_column_length_test_table'
)
SELECT COLUMN_NAME, ColumnLength
FROM ColumnLengths
WHERE ColumnLength % 2 = 0;
GO

-- Using COL_LENGTH() in expressions
SELECT 
    CASE 
        WHEN sys.COL_LENGTH('sys_column_length_test_table', 'col_sql_variant') > 8015
        THEN 'SQL Variant Column'
        ELSE 'Other Column' 
    END AS ColumnStatus;
GO

-- Test Cases for User-Defined Data Types
SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customchar');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customvarchar');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_custombinary');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customvarbinary');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customnchar');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customnvarchar');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customtext');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customimage');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customntext');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customsysname');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customsqlvariant');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customxml');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customvarcharmax');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customnvarcharmax');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customvarbinarymax');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_custombit');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customtinyint');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_custombigint');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customsmallint');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customsmallmoney');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_custommoney');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customsmalldatetime');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customreal');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customfloat');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customtime');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customdatetime');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customdatetime2');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customdatetimeoffset');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customuniqueidentifier');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customdate');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customdecimal');
GO

SELECT * FROM sys.COL_LENGTH('udd_test_table', 'col_customnumeric');
GO
