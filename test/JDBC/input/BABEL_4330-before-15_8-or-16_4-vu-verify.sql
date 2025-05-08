SELECT replace(a, 'a', 'c') FROM babel_4330_vu_prepare_t1;
go

SELECT * FROM babel_4330_vu_prepare_v1;
go


SELECT * FROM babel_4330_vu_prepare_f1();
go

EXEC babel_4330_vu_prepare_p1;
GO


DROP PROCEDURE babel_4330_vu_prepare_p1;
GO

DROP FUNCTION babel_4330_vu_prepare_f1;
GO

DROP VIEW babel_4330_vu_prepare_v1;
GO

DROP TABLE babel_4330_vu_prepare_t1;
GO