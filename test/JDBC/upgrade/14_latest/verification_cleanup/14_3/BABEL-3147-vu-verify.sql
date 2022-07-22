SELECT c_comp FROM t_3147_1
GO

-- Test ISNULL with numeric columns
SELECT ISNULL(a, b) FROM t_3147_2
GO

-- Test ISNULL with decimal columns
SELECT ISNULL(a, b) FROM t_3147_3
GO