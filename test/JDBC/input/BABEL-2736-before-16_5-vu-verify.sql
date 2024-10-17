-- Test view v1 (style 0)
SELECT * FROM BABEL_BINARY_vu_prepare_v1
GO
DROP VIEW BABEL_BINARY_vu_prepare_v1
GO

-- Test procedure p1 (style 0)
EXEC BABEL_BINARY_vu_prepare_p1
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p1
GO

-- Test function f1 (style 0)
SELECT dbo.BABEL_BINARY_vu_prepare_f1()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f1
GO

-- Test view v2 (style 1)
SELECT * FROM BABEL_BINARY_vu_prepare_v2
GO
DROP VIEW BABEL_BINARY_vu_prepare_v2
GO

-- Test procedure p2 (style 1)
EXEC BABEL_BINARY_vu_prepare_p2
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p2
GO

-- Test function f2 (style 1)
SELECT dbo.BABEL_BINARY_vu_prepare_f2()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f2
GO

-- Test view v3 (style 2)
SELECT * FROM BABEL_BINARY_vu_prepare_v3
GO
DROP VIEW BABEL_BINARY_vu_prepare_v3
GO

-- Test procedure p3 (style 2)
EXEC BABEL_BINARY_vu_prepare_p3
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p3
GO

-- Test function f3 (style 2)
SELECT dbo.BABEL_BINARY_vu_prepare_f3()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f3
GO

-- Test view v4 (VARBINARY)
SELECT * FROM BABEL_BINARY_vu_prepare_v4
GO
DROP VIEW BABEL_BINARY_vu_prepare_v4
GO

-- Test procedure p4 (VARBINARY)
EXEC BABEL_BINARY_vu_prepare_p4
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p4
GO

-- Test function f4 (VARBINARY)
SELECT dbo.BABEL_BINARY_vu_prepare_f4()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f4
GO

-- Test procedure p5 (invalid style - should cause an error)
EXEC BABEL_BINARY_vu_prepare_p5
GO
DROP PROCEDURE BABEL_BINARY_vu_prepare_p5
GO

-- Test function f5 (NULL input)
SELECT dbo.BABEL_BINARY_vu_prepare_f5()
GO
DROP FUNCTION BABEL_BINARY_vu_prepare_f5
GO