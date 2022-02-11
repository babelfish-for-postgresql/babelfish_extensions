CREATE PROCEDURE test_proc1 AS
BEGIN
    DECLARE @v1 INT;
    DECLARE @v2 AS INT;
    SET @v1 = 1;
    SET @v2 = 2;
    PRINT @v1;
    PRINT @v2;
END
GO

EXEC test_proc1
GO

-- Test single declare stmt ending with datatype and followed by K_END
CREATE PROCEDURE test_proc2 AS
BEGIN
    DECLARE @a INT
END
GO

EXEC test_proc2
GO

-- Test single declare stmt ending with datatype not wrapped in BEGIN...END
CREATE PROCEDURE test_proc3 AS
    DECLARE @a INT
GO

EXEC test_proc3
GO

SELECT proname, prosrc FROM pg_proc WHERE proname LIKE 'test_proc%'
GO

-- CLEAN UP
DROP PROCEDURE test_proc1;
GO
DROP PROCEDURE test_proc2;
GO
DROP PROCEDURE test_proc3;
GO
