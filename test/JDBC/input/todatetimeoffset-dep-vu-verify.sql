SELECT * FROM todatetimeoffset_dep_vu_prepare_v1
GO

SELECT * FROM todatetimeoffset_dep_vu_prepare_v2
GO

EXEC todatetimeoffset_dep_vu_prepare_p1
GO

EXEC todatetimeoffset_dep_vu_prepare_p2
GO

SELECT todatetimeoffset_dep_vu_prepare_f1()
GO

SELECT todatetimeoffset_dep_vu_prepare_f2()
GO