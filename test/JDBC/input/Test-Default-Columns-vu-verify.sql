insert into test_default_columns_vu_prepare_t1 DEFAULT VALUES
GO

SELECT * FROM test_default_columns_vu_prepare_t1
GO

insert into test_default_columns_vu_prepare_t2 DEFAULT VALUES
GO

SELECT * FROM test_default_columns_vu_prepare_t2
GO

insert into test_default_columns_vu_prepare_t3 DEFAULT VALUES
GO

SELECT * FROM test_default_columns_vu_prepare_t3
GO

insert into test_default_columns_vu_prepare_t4 DEFAULT VALUES
GO

SELECT * FROM test_default_columns_vu_prepare_t4
GO

insert into test_default_columns_vu_prepare_t5 DEFAULT VALUES
GO

SELECT * FROM test_default_columns_vu_prepare_t5
GO

EXEC test_default_columns_vu_prepare_p1
GO

SELECT * FROM test_default_columns_vu_prepare_t1
GO

EXEC test_default_columns_vu_prepare_p2
GO

SELECT * FROM test_default_columns_vu_prepare_t2
GO

EXEC test_default_columns_vu_prepare_p3
GO

SELECT * FROM test_default_columns_vu_prepare_t3
GO

EXEC test_default_columns_vu_prepare_p4
GO

SELECT * FROM test_default_columns_vu_prepare_t4
GO

EXEC test_default_columns_vu_prepare_p5
GO

SELECT * FROM test_default_columns_vu_prepare_t5
GO

SELECT * from test_default_columns_vu_prepare_func_1(1)
GO

SELECT * from test_default_columns_vu_prepare_func_2(1)
GO

SELECT * from test_default_columns_vu_prepare_func_3(1)
GO

SELECT * from test_default_columns_vu_prepare_func_4(1)
GO

SELECT * from test_default_columns_vu_prepare_func_5(1)
GO