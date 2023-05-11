-- Procedures
-- block statement
CREATE PROCEDURE p AS BEGIN
	USE db;
END
GO

-- if_statement
CREATE PROCEDURE p AS BEGIN
	DECLARE @i INT = 2; 
	IF (@i = 2) BEGIN 
		USE db 
	END
END
GO

-- else statement
CREATE PROCEDURE p AS BEGIN
	DECLARE @i INT =2;
	IF (@i=2) BEGIN
		SELECT 1
	END
	ELSE BEGIN 
		USE db
	END
END
GO

-- try-catch block
CREATE PROCEDURE p AS BEGIN
	BEGIN TRY
  		USE db
	END TRY
	BEGIN CATCH
  		SELECT 1
	END CATCH
END
GO

CREATE PROCEDURE p AS BEGIN
	BEGIN TRY
 		SELECT 1
	END TRY
	BEGIN CATCH
  		USE db
	END CATCH
END
GO

-- while loop
CREATE PROCEDURE p AS BEGIN
	DECLARE @i INT = 2
	WHILE @i > 0 BEGIN
		USE db
		SET @i = @i-1
	END
END
GO

-- multiple loops
CREATE PROCEDURE P(@total INT) AS BEGIN
	DECLARE @cnt INT = 0
	WHILE @cnt < @total
	  BEGIN
		SELECT 1
		IF @cnt >= 5
    		USE db;
			BREAK
		SELECT 2
		IF (@cnt < 5)
			SELECT 3
		SET @cnt = @cnt + 1
	END
END
GO

-- Triggers
CREATE TABLE tb(i INT);
GO

CREATE TRIGGER t ON tb
FOR INSERT AS BEGIN
    USE db;
	INSERT INTo t VALUES(1);
END
GO

CREATE TRIGGER t ON tb
AFTER DELETE AS
    DECLARE @cnt INT = 0
	WHILE @cnt < @total
	  BEGIN
		SELECT 1
		IF @cnt >= 5
    		USE db;
			BREAK
		SELECT 2
		IF (@cnt < 5)
			SELECT 3
		SET @cnt = @cnt + 1
	END
GO

DROP TABLE tb;
GO

-- Functions
-- sql_clauses is not supported for function of return type func_body_returns_table_clr
CREATE FUNCTION func() RETURNS TABLE AS
	USE db;
	RETURN (SELECT * FROM babel_execute_as_caller_table)
GO

CREATE FUNCTION func(@i INT) returns @tableVar table(a text not null) AS
BEGIN
	USE db;
    RETURN
END
GO

CREATE FUNCTION func(@c INT) RETURNS INT AS
BEGIN
	USE db;
	RETURN (SELECT 1)
END
GO

CREATE FUNCTION func(@c INT) RETURNS INT AS
BEGIN
	DECLARE @cnt INT = 0
	WHILE @cnt < @total
	  BEGIN
		SELECT 1
		IF @cnt >= 5
    		USE db;
			BREAK
		SELECT 2
		IF (@cnt < 5)
			SELECT 3
		SET @cnt = @cnt + 1
	END
END
GO

CREATE FUNCTION func() RETURNS BIGINT AS
BEGIN
    DECLARE @ans BIGINT
    SELECT @ans= SUM(c1) FROM babel_execute_as_caller_table
	if(@ans!=1)
		USE db;
    RETURN @ans
END
GO

CREATE FUNCTION func (@v INT) RETURNS INT WITH RETURNS NULL ON NULL INPUT AS
BEGIN
	DECLARE @cnt INT = 0
	WHILE @cnt < @total
	  BEGIN
		SELECT 1
		IF @cnt >= 5
    		USE db;
			BREAK
		SELECT 2
		IF (@cnt < 5)
			SELECT 3
		SET @cnt = @cnt + 1
	END
END
GO

CREATE FUNCTION func (@v INT) RETURNS INT WITH RETURNS NULL ON NULL INPUT
BEGIN
	USE db;
    RETURN @v+1
END;
GO
