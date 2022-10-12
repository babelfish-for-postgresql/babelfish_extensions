SELECT * FROM BABEL_1062_vu_prepare_v1
GO
DROP VIEW BABEL_1062_vu_prepare_v1
GO

SELECT * FROM BABEL_1062_vu_prepare_v2
GO
DROP VIEW BABEL_1062_vu_prepare_v2
GO

SELECT * FROM BABEL_1062_vu_prepare_v3
GO
DROP VIEW BABEL_1062_vu_prepare_v3
GO

SELECT * FROM BABEL_1062_vu_prepare_v4
GO
DROP VIEW BABEL_1062_vu_prepare_v4
GO

EXEC BABEL_1062_vu_prepare_p1
GO
DROP procedure  BABEL_1062_vu_prepare_p1
GO

EXEC BABEL_1062_vu_prepare_p2
GO
DROP procedure  BABEL_1062_vu_prepare_p2
GO

EXEC BABEL_1062_vu_prepare_p3
GO
DROP procedure  BABEL_1062_vu_prepare_p3
GO

EXEC BABEL_1062_vu_prepare_p4
GO
DROP procedure  BABEL_1062_vu_prepare_p4
GO

SELECT BABEL_1062_vu_prepare_f1()
GO
DROP FUNCTION BABEL_1062_vu_prepare_f1
GO

SELECT BABEL_1062_vu_prepare_f2()
GO
DROP FUNCTION BABEL_1062_vu_prepare_f2
GO

SELECT BABEL_1062_vu_prepare_f3()
GO
DROP FUNCTION BABEL_1062_vu_prepare_f3
GO

SELECT BABEL_1062_vu_prepare_f4()
GO
DROP FUNCTION BABEL_1062_vu_prepare_f4
GO
