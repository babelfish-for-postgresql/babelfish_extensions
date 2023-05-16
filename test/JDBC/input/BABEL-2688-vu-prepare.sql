/* Example from JIRA */ 
CREATE FUNCTION babel_2688_fn1() RETURNS @p TABLE (b bit)
AS
BEGIN
            DECLARE @tv TABLE (b bit);

            INSERT INTO @tv values (1);

            UPDATE t
            SET b  = 0
            FROM @tv AS t;

            INSERT INTO @p SELECT * FROM @tv;

            RETURN;
END
GO

CREATE TABLE babel_2688_tab1(a int)
GO

CREATE FUNCTION babel_2688_fn2() RETURNS int
AS
BEGIN
	UPDATE t
	SET a = 1
	FROM babel_2688_tab1 AS t;

	RETURN 0;
END
GO

CREATE FUNCTION babel_2688_fn3() RETURNS @t TABLE (a int)
AS
BEGIN
	DECLARE @tv TABLE (a int);
	INSERT INTO @tv values (1); 
	INSERT INTO @tv values (2);
	INSERT INTO @tv values (3);

	UPDATE @tv
	SET a = 0
	WHERE a%2 = 1;

	INSERT INTO @t SELECT * FROM @tv;

	RETURN;
END
GO

CREATE FUNCTION babel_2688_fn4() RETURNS @t TABLE (a int)
AS
BEGIN
	UPDATE @tv_does_not_exist
	SET a = 0;
	RETURN;
END
GO

CREATE FUNCTION babel_2688_fn5() RETURNS int
AS
BEGIN
	DELETE FROM babel_2688_tab1;
	RETURN 0;
END
GO

CREATE FUNCTION babel_2688_fn6() RETURNS @t TABLE (a int)
AS
BEGIN
	DECLARE  @tv TABLE (a int);
	
	INSERT INTO @tv values (1); 
	INSERT INTO @tv values (2);
	INSERT INTO @tv values (3);

	DELETE FROM @tv
	WHERE a%2 = 1;

	INSERT INTO @t SELECT * FROM @tv;

	RETURN;
END
GO

CREATE FUNCTION babel_2688_fn7() RETURNS @t TABLE (a int)
AS
BEGIN
	DELETE FROM @tv_does_not_exist;
	RETURN;
END
GO
