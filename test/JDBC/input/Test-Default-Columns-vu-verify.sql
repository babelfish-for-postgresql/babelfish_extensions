insert into default_columns_t1 DEFAULT VALUES
GO

SELECT * FROM default_columns_t1
GO

insert into default_columns_t2 DEFAULT VALUES
GO

SELECT * FROM default_columns_t2
GO

insert into default_columns_t3 DEFAULT VALUES
GO

SELECT * FROM default_columns_t3
GO

insert into default_columns_t4 DEFAULT VALUES
GO

SELECT * FROM default_columns_t4
GO

insert into default_columns_t5 DEFAULT VALUES
GO

SELECT * FROM default_columns_t5
GO

EXEC default_columns_p1
GO

SELECT * FROM default_columns_t1
GO

EXEC default_columns_p2
GO

SELECT * FROM default_columns_t2
GO

EXEC default_columns_p3
GO

SELECT * FROM default_columns_t3
GO

EXEC default_columns_p4
GO

SELECT * FROM default_columns_t4
GO

EXEC default_columns_p5
GO

SELECT * FROM default_columns_t5
GO

SELECT * from default_columns_func_1(1)
GO

SELECT * from default_columns_func_2(1)
GO

SELECT * from default_columns_func_3(1)
GO

SELECT * from default_columns_func_4(1)
GO

SELECT * from default_columns_func_5(1)
GO