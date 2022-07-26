INSERT INTO babel_3116_vu_prepare_t1 (c1, c2, c3) VALUES (1, 1, 1);
GO

SELECT * FROM babel_3116_vu_prepare_t1;
GO


UPDATE babel_3116_vu_prepare_t1
SET c1 = c1 + 1 --Trigger should cause c3 to be 2
WHERE id = 1;
GO

SELECT * FROM babel_3116_vu_prepare_t1;
GO
