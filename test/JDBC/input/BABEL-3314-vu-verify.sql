SELECT * FROM BABEL_3314_vu_prepare_v1
GO
DROP VIEW BABEL_3314_vu_prepare_v1
GO

SELECT * FROM BABEL_3314_vu_prepare_v2
GO
DROP VIEW BABEL_3314_vu_prepare_v2
GO

EXEC BABEL_3314_vu_prepare_p1
GO
DROP procedure  BABEL_3314_vu_prepare_p1
GO

EXEC BABEL_3314_vu_prepare_p2
GO
DROP procedure  BABEL_3314_vu_prepare_p2
GO

SELECT BABEL_3314_vu_prepare_f1()
GO
DROP FUNCTION BABEL_3314_vu_prepare_f1
GO

SELECT BABEL_3314_vu_prepare_f2()
GO
DROP FUNCTION BABEL_3314_vu_prepare_f2
GO
