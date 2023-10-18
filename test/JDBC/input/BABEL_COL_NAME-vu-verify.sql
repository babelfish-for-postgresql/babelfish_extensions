USE babel_3172_test_db;
GO

SELECT * FROM col_name_prepare_v1;
GO

SELECT * FROM col_name_prepare_v2;
GO

SELECT * FROM col_name_prepare_v3;
GO

SELECT * FROM col_name_prepare_v4;
GO

EXEC col_name_prepare_p1;
GO

EXEC col_name_prepare_p2;
GO

EXEC col_name_prepare_p3;
GO

EXEC col_name_prepare_p4;
GO

SELECT col_name_prepare_f1();
GO

SELECT col_name_prepare_f2();
GO

SELECT * FROM COL_NAME(NULL, NULL);
GO

DECLARE @table_id INT = (SELECT OBJECT_ID('sys_col_name_test_schema.test_table'));

SELECT * FROM COL_NAME(@table_id, 1);
GO

SELECT * FROM COL_NAME('0x1A', 3);
GO

SELECT * FROM COL_NAME(7, 'column_name');
GO

SELECT * FROM COL_NAME('0x2F', 'another_column');
GO

SELECT * FROM COL_NAME('0xAB', '0x8C');
GO

SELECT * FROM COL_NAME('sample_table', 'some_column');
GO