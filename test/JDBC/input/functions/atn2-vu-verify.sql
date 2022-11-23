SELECT * FROM atn2_vu_prepare_v1
GO

-- test with all datatypes that could implicity converted to float
SELECT * FROM atn2_vu_prepare_v2
GO

-- returns NULL
SELECT * FROM atn2_vu_prepare_v3
GO

-- expect float overflow error
SELECT * FROM atn2_vu_prepare_v4
GO

-- won't over flow
SELECT * FROM atn2_vu_prepare_v5
GO

EXEC atn2_vu_prepare_p1
GO

-- test with all datatypes that could implicity converted to float
EXEC atn2_vu_prepare_p2
GO

EXEC atn2_vu_prepare_p3
GO

EXEC atn2_vu_prepare_p4
GO

EXEC atn2_vu_prepare_p5
GO

EXEC atn2_vu_prepare_p6
GO

EXEC atn2_vu_prepare_p7
GO

EXEC atn2_vu_prepare_p8
GO

EXEC atn2_vu_prepare_p9
GO

EXEC atn2_vu_prepare_p10
GO

EXEC atn2_vu_prepare_p11
GO

EXEC atn2_vu_prepare_p12
GO

EXEC atn2_vu_prepare_p13
GO

EXEC atn2_vu_prepare_p14
GO

EXEC atn2_vu_prepare_p15
GO

-- returns NULL
EXEC atn2_vu_prepare_p16
GO

EXEC atn2_vu_prepare_p17
GO

EXEC atn2_vu_prepare_p18
GO

-- expect float overflow
EXEC atn2_vu_prepare_p19
GO

-- won't over flow
EXEC atn2_vu_prepare_p20
GO

SELECT atn2_vu_prepare_f1()
GO

-- test with all datatypes that could implicity converted to float
SELECT atn2_vu_prepare_f2()
GO

SELECT atn2_vu_prepare_f3()
GO

SELECT atn2_vu_prepare_f4()
GO

SELECT atn2_vu_prepare_f5()
GO

SELECT atn2_vu_prepare_f6()
GO

SELECT atn2_vu_prepare_f7()
GO

SELECT atn2_vu_prepare_f8()
GO

SELECT atn2_vu_prepare_f9()
GO

SELECT atn2_vu_prepare_f10()
GO

SELECT atn2_vu_prepare_f11()
GO

SELECT atn2_vu_prepare_f12()
GO

SELECT atn2_vu_prepare_f13()
GO

SELECT atn2_vu_prepare_f14()
GO

SELECT atn2_vu_prepare_f15()
GO

-- returns NULL when input is NULL
SELECT atn2_vu_prepare_f16()
GO

SELECT atn2_vu_prepare_f17()
GO

SELECT atn2_vu_prepare_f18()
GO

-- expect float overflow error
SELECT atn2_vu_prepare_f19()
GO

-- won't over flow
SELECT atn2_vu_prepare_f20()
GO
