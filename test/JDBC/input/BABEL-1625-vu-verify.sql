declare @dt datetimeoffset(6);
set @dt = '1912-10-25 12:24:32 +10:0';
select dateadd(month,1,@dt);
GO

SELECT * FROM BABEL_1625_vu_prepare_v1
GO
DROP VIEW BABEL_1625_vu_prepare_v1
GO

SELECT * FROM BABEL_1625_vu_prepare_v2
GO
DROP VIEW BABEL_1625_vu_prepare_v2
GO

SELECT * FROM BABEL_1625_vu_prepare_v3
GO
DROP VIEW BABEL_1625_vu_prepare_v3
GO

SELECT * FROM BABEL_1625_vu_prepare_v4
GO
DROP VIEW BABEL_1625_vu_prepare_v4
GO

SELECT * FROM BABEL_1625_vu_prepare_v5
GO
DROP VIEW BABEL_1625_vu_prepare_v5
GO

SELECT * FROM BABEL_1625_vu_prepare_v6
GO
DROP VIEW BABEL_1625_vu_prepare_v6
GO

EXEC BABEL_1625_vu_prepare_p1
GO
DROP procedure  BABEL_1625_vu_prepare_p1
GO

EXEC BABEL_1625_vu_prepare_p2
GO
DROP procedure  BABEL_1625_vu_prepare_p2
GO

EXEC BABEL_1625_vu_prepare_p3
GO
DROP procedure  BABEL_1625_vu_prepare_p3
GO

EXEC BABEL_1625_vu_prepare_p4
GO
DROP procedure  BABEL_1625_vu_prepare_p4
GO

EXEC BABEL_1625_vu_prepare_p5
GO
DROP procedure  BABEL_1625_vu_prepare_p5
GO

EXEC BABEL_1625_vu_prepare_p6
GO
DROP procedure  BABEL_1625_vu_prepare_p6
GO

SELECT BABEL_1625_vu_prepare_f1()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f1()
GO

SELECT BABEL_1625_vu_prepare_f2()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f2()
GO

SELECT BABEL_1625_vu_prepare_f3()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f3()
GO

SELECT BABEL_1625_vu_prepare_f4()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f4()
GO

SELECT BABEL_1625_vu_prepare_f5()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f5()
GO

SELECT BABEL_1625_vu_prepare_f6()
GO
DROP FUNCTION BABEL_1625_vu_prepare_f6()
GO
