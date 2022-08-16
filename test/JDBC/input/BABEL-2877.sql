DROP FUNCTION IF EXISTS babel_2877_func1;
GO

DROP PROCEDURE IF EXISTS babel_2877_proc1;
GO

CREATE FUNCTION babel_2877_func1 (@a int, @b int = 20, @c int, @d int = 40)
RETURNS int AS
BEGIN
	RETURN @a + @b + @c + @d;
END
GO

CREATE PROCEDURE babel_2877_proc1 (@a int, @b int = 20, @c int = 30, @d int)
AS
BEGIN
	SELECT @a + @b + @c + @d;
END
GO

SELECT * FROM babel_2877_func1(10); -- should fail, required argument @c not supplied
GO

SELECT * FROM babel_2877_func1(10, 20, 30, 40);
GO

EXEC babel_2877_proc1; -- should fail, required arguments @a and @d not supplied
GO

EXEC babel_2877_proc1 10; -- should fail, required argument @d not supplied
GO

EXEC babel_2877_proc1 @d=40; -- should fail, required argument @a not supplied
GO

EXEC babel_2877_proc1 @a = 10, @d = 40;
GO

EXEC babel_2877_proc1 @a = 10, @b = 20, @c = 30, @d = 40;
GO
 
DROP FUNCTION IF EXISTS babel_2877_func1;
GO

DROP PROCEDURE IF EXISTS babel_2877_proc1;
GO