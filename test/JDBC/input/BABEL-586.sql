CREATE PROCEDURE test_proc1 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1=@p0, @p3=@p2;
RETURN;
END
GO

CREATE PROCEDURE test_proc2 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1=@p0, @p3= @p2;
RETURN;
END
GO

CREATE PROCEDURE test_proc3 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1= @p0, @p3=@p2;
RETURN;
END
GO

CREATE PROCEDURE test_proc4 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1=@p0+@p0, @p3= @p2+@p2;
RETURN;
END
GO

CREATE PROCEDURE test_proc5 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1=CAST(@p0 as INT), @p3= @p2+@p2;
RETURN;
END
GO

CREATE PROCEDURE test_proc6 (@p0 int, @p1 int OUTPUT, @p2 smallint,  @p3 smallint OUTPUT)
AS BEGIN
SELECT @p1=1234, @p3= 5678;
RETURN;
END
GO


CREATE PROCEDURE test_proc0 
AS BEGIN
DECLARE @a int;
DECLARE @b smallint;

EXEC test_proc1 1, @a OUT, 2, @b OUT;
PRINT @a
PRINT @b

EXEC test_proc2 3, @a OUT, 4, @b OUT;
PRINT @a
PRINT @b

EXEC test_proc3 5, @a OUT, 6, @b OUT;
PRINT @a
PRINT @b

EXEC test_proc4 7, @a OUT, 9, @b OUT;
PRINT @a
PRINT @b

EXEC test_proc5 11, @a OUT, 13, @b OUT;
PRINT @a
PRINT @b

EXEC test_proc6 17, @a OUT, 19, @b OUT;
PRINT @a
PRINT @b

END
GO

EXEC test_proc0
GO

DROP PROCEDURE test_proc1
GO

DROP PROCEDURE test_proc2
GO

DROP PROCEDURE test_proc3
GO

DROP PROCEDURE test_proc4
GO

DROP PROCEDURE test_proc5
GO

DROP PROCEDURE test_proc6
GO

DROP PROCEDURE test_proc0
GO

