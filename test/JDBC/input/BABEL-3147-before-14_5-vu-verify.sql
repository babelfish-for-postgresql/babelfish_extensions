SELECT c_comp FROM BABEL_3147_before_14_5_vu_prepare_t_1
GO

-- Test ISNULL with numeric columns
SELECT ISNULL(a, b) FROM BABEL_3147_before_14_5_vu_prepare_t_2
GO

-- Test ISNULL with decimal columns
SELECT ISNULL(a, b) FROM BABEL_3147_before_14_5_vu_prepare_t_3
GO