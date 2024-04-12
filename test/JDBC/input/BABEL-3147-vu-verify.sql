-- error should not have been thrown, should be fixed under BABEL-1710
INSERT INTO BABEL_3147_vu_prepare_t_1 VALUES(1)
GO

-- error should not have been thrown, should be fixed under BABEL-1710
SELECT c_comp FROM BABEL_3147_vu_prepare_t_1
GO

-- Test ISNULL with numeric columns
SELECT ISNULL(a, b) FROM BABEL_3147_vu_prepare_t_2
GO

-- Test ISNULL with decimal columns
SELECT ISNULL(a, b) FROM BABEL_3147_vu_prepare_t_3
GO