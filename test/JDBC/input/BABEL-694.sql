CREATE PROCEDURE my_test @a int, @b int
AS
PRINT @a + @b
GO

CREATE PROCEDURE caller @a int, @b int
AS
EXEC my_test(@a,@b)
GO

EXEC my_test(1,2)
GO

EXEC my_test 1, (1,2)
GO

EXECUTE my_test(1,2)
GO

EXECUTE my_test 1, (1,2)
GO

drop procedure my_test
GO
