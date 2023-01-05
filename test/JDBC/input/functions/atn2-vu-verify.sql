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

-- throws error when input is (0, 0)
SELECT * FROM atn2_vu_prepare_v6
GO

SELECT * FROM atn2_vu_prepare_v7
GO

SELECT * FROM atn2_vu_prepare_v8
GO

EXEC atn2_vu_prepare_p1
GO

-- test with all datatypes that could implicity converted to float
EXEC atn2_vu_prepare_p2
GO

-- returns NULL
EXEC atn2_vu_prepare_p3
GO

-- expect float overflow
EXEC atn2_vu_prepare_p4
GO

-- won't over flow
EXEC atn2_vu_prepare_p5
GO

-- throws error when input is (0, 0)
EXEC atn2_vu_prepare_p6
GO

EXEC atn2_vu_prepare_p7
GO

EXEC atn2_vu_prepare_p8
GO

