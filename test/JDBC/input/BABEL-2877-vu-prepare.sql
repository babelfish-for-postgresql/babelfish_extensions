DROP FUNCTION IF EXISTS babel_2877_vu_prepare_func1;
GO

DROP PROCEDURE IF EXISTS babel_2877_vu_prepare_proc1;
GO

CREATE FUNCTION babel_2877_vu_prepare_func1 (@a int, @b int = 20, @c int, @d int = 40)
RETURNS int AS
BEGIN
	RETURN @a + @b + @c + @d;
END
GO

CREATE PROCEDURE babel_2877_vu_prepare_proc1 (@a int, @b int = 20, @c int = 30, @d int)
AS
BEGIN
	SELECT @a + @b + @c + @d;
END
GO