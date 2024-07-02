-- should fail
EXEC babel_4390_prepare_p1;
GO

EXEC babel_4390_prepare_p2;
GO

-- should fail
EXEC babel_4390_prepare_p3;
GO

-- should fail
EXEC babel_4390_prepare_p4;
GO

-- should fail
BEGIN TRANSACTION;
EXEC babel_4390_prepare_p1;
ROLLBACK;
GO

-- should fail
DROP PROCEDURE dbo.xp_qv;
GO

-- should fail
EXEC babel_4390_prepare_p5;
GO

-- should fail
EXEC babel_4390_prepare_p6;
GO

-- should fail
EXEC babel_4390_prepare_p7;
GO

-- should fail
EXEC babel_4390_prepare_p8;
GO

-- should fail
EXEC babel_4390_prepare_p9;
GO

-- psql
-- should fail
DROP PROCEDURE dbo.xp_qv;
GO

-- should fail
DROP PROCEDURE xp_qv;
GO

-- should fail
DROP PROCEDURE dbo.sp_addlinkedsrvlogin;
GO