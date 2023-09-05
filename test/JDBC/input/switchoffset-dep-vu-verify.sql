SELECT * FROM switchoffset_dep_vu_prepare_v1
GO

SELECT * FROM switchoffset_dep_vu_prepare_v2
GO

EXEC switchoffset_dep_vu_prepare_p1
GO

EXEC switchoffset_dep_vu_prepare_p2
GO

SELECT switchoffset_dep_vu_prepare_f1()
GO

SELECT switchoffset_dep_vu_prepare_f2()
GO