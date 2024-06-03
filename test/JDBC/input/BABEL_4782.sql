CREATE PROCEDURE babel_4782_p(@in INT)
AS
IF (@in = 1)
BEGIN
        SELECT 1;
END
ELSE
BEGIN
        SET @in = @in - 1
        EXEC babel_4782_p @in
END
GO

EXEC babel_4782_p 3
GO

DROP PROC babel_4782_p
GO