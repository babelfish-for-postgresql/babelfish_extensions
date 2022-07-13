DROP FUNCTION IF EXISTS my_func1;
GO

DROP PROCEDURE IF EXISTS my_proc1;
GO

DROP FUNCTION IF EXISTS my_func2;
GO

DROP FUNCTION IF EXISTS my_func3;
GO

CREATE FUNCTION my_func1 (@a int, @b int = 20, @c int, @d int = 40)
RETURNS int AS
BEGIN
	RETURN @a + @b + @c + @d;
END
GO

CREATE PROCEDURE my_proc1 (@a int, @b int = 20, @c int = 30, @d int)
AS
BEGIN
	SELECT @a + @b + @c + @d;
END
GO

-- invalid sql, this should fail as user need to provide unique column names
CREATE FUNCTION my_func2 (@a int, @b int = 20, @c int = 30, @d int)
RETURNS TABLE
AS
RETURN SELECT @a, @b, @c, @d;
GO

-- valid sql
CREATE FUNCTION my_func2 (@a int, @b int = 20, @c int = 30, @d int)
RETURNS TABLE
AS
RETURN SELECT @a AS a, @b AS b, @c AS c, @d AS d;
GO

CREATE FUNCTION my_func3 (@a int, @b int = 20, @c int, @d int = 40)
RETURNS TABLE
AS
RETURN SELECT @a AS a, @b AS b, @c AS c, @d AS d;
GO

EXEC my_proc1 @a = 10, @d = 40;
GO

EXEC my_proc1 @a = 10;
GO

SELECT * FROM my_func2(1);
GO

SELECT * FROM my_func3(2);
GO
 
DROP FUNCTION IF EXISTS my_func1;
GO

DROP PROCEDURE IF EXISTS my_proc1;
GO

DROP FUNCTION IF EXISTS my_func2;
GO

DROP FUNCTION IF EXISTS my_func3;
GO
