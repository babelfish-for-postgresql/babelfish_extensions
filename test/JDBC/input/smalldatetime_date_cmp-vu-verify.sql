-- parallel_query_expected
SET BABELFISH_SHOWPLAN_ALL ON
GO

SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE) AND smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO

EXEC test_smalldatetime_date_p1;
GO

EXEC test_smalldatetime_date_p2;
GO

EXEC test_smalldatetime_date_p3;
GO

EXEC test_smalldatetime_date_p4;
GO

EXEC test_smalldatetime_date_p5;
GO

EXEC test_smalldatetime_date_p6;
GO

EXEC test_smalldatetime_date_p7;
GO

SELECT * FROM test_smalldatetime_date_v1;
GO

SELECT * FROM test_smalldatetime_date_v2;
GO

SELECT * FROM test_smalldatetime_date_v3;
GO

SELECT * FROM test_smalldatetime_date_v4;
GO

SELECT * FROM test_smalldatetime_date_v5;
GO

SELECT * FROM test_smalldatetime_date_v6;
GO

SELECT * FROM test_smalldatetime_date_v7;
GO

SELECT COUNT(*) FROM smalldate_date_cmp_t2 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE) AND smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO