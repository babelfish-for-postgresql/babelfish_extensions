SELECT * FROM ATTIMEZONE_dep_vu_prepare_v1
GO

SELECT * FROM ATTIMEZONE_dep_vu_prepare_v2
GO

EXEC ATTIMEZONE_dep_vu_prepare_p1
GO

EXEC ATTIMEZONE_dep_vu_prepare_p2
GO

SELECT ATTIMEZONE_dep_vu_prepare_f1()
GO

SELECT ATTIMEZONE_dep_vu_prepare_f2()
GO