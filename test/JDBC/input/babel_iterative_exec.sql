-- Basic SELECT
CREATE PROCEDURE my_test1 @a int AS
BEGIN
	SELECT @a;
END
GO

-- If
CREATE PROCEDURE my_test2 @a int AS
BEGIN
	SELECT 'first stmt';
	IF @a < 10
		BEGIN
			SELECT 'true branch stmt 1';
		END
END
GO

-- If-ELSE
CREATE PROCEDURE my_test3 @a int AS
BEGIN
	SELECT 'first stmt';
	SELECT 'second stmt';
	IF @a < 10
		BEGIN
			SELECT 'true branch stmt 1';
			SELECT 'true branch stmt 2';
		END
	ELSE
		BEGIN
			SELECT 'false branch stmt 1';
			SELECT 'false branch stmt 2';
		END
	SELECT 'last stmt';
END
GO

-- Nested If-ELSE
CREATE PROCEDURE my_test4 @a int AS
BEGIN
	SELECT 'first stmt';
	SELECT 'second stmt';
	IF @a < 10
		if @a < 5
			BEGIN
				SELECT 'print1';
				SELECT 'print2';
			END
		else
			BEGIN
				SELECT 'print3';
				SELECT 'print4';
			END
	ELSE
		BEGIN
			SELECT 'print5';
			SELECT 'print6';
		END
	SELECT 'last stmt';
END
GO

EXEC my_test1 11
GO

EXEC my_test2 5
GO

EXEC my_test2 12
GO

EXEC my_test3 5
GO

EXEC my_test3 13
GO

EXEC my_test4 4
GO

EXEC my_test4 7
GO

EXEC my_test4 14
GO

DROP PROCEDURE my_test1;
GO

DROP PROCEDURE my_test2;
GO

DROP PROCEDURE my_test3;
GO

DROP PROCEDURE my_test4;
GO
