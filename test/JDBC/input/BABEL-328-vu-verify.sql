SELECT * FROM babel_328_vu_v1
GO

SELECT * FROM babel_328_vu_v2
GO

SELECT * FROM babel_328_vu_v3 ORDER BY NAME
GO

SELECT * FROM babel_328_vu_v4 ORDER BY NAME
GO

EXEC babel_328_vu_p1
GO

EXEC babel_328_vu_p2
GO

EXEC babel_328_vu_p3
GO

EXEC babel_328_vu_p4
GO

SELECT * FROM babel_328_vu_v5
GO

SELECT * FROM babel_328_vu_v6
GO

SELECT * FROM babel_328_vu_f2()
GO

--These calls should return an error
SELECT * FROM babel_328_vu_t1 D
CROSS babel_328_vu_t2 E
GO

SELECT * FROM babel_328_vu_t1 D
OUTER babel_328_vu_t2 E
GO

SELECT * FROM babel_328_vu_t1 d
CROSS APPLY (SELECT * FROM babel_328_vu_t2)
GO

SELECT * FROM babel_328_vu_t1 d
OUTER APPLY (SELECT * FROM babel_328_vu_t2)
GO

SELECT * FROM babel_328_vu_t1 d
CROSS APPLY (VALUES (3,3),(4,4))
GO

SELECT * FROM babel_328_vu_t1 d
OUTER APPLY (VALUES (3,3),(4,4))
GO
