CREATE PROCEDURE sp_babel_1261_1 (@a SMALLINT OUTPUT) AS
BEGIN
  SET @a=100;
  select @a as a;
END;
GO

exec sp_babel_1261_1 2;
GO

CREATE PROCEDURE sp_babel_1261_2 (@a SMALLINT OUTPUT, @b SMALLINT OUTPUT) AS
BEGIN
  SET @a=100;
  SET @b=200;
  select @a+@b as r;
END;
GO

EXEC sp_babel_1261_2 2, 3;
GO

DECLARE @a INT;
EXEC sp_babel_1261_2 @a OUT, 3;
SELECT @a;
GO

DECLARE @b INT;
EXEC sp_babel_1261_2 2, @b OUT;
SELECT @b;
GO

DECLARE @a INT;
DECLARE @b INT;
EXEC sp_babel_1261_2 @a OUT, @b OUT;
SELECT @a+@b;
GO

CREATE PROCEDURE sp_babel_1307_1 (@a numeric(10,4) OUTPUT) AS
BEGIN
  SET @a=100.41;
  select @a as a;
END;
GO

exec sp_babel_1307_1 2.000;
GO

CREATE PROCEDURE sp_babel_1307_2 (@a numeric(10,4) OUTPUT, @b numeric(10,4) OUTPUT) AS
BEGIN
  SET @a=100.41;
  SET @b=200.82;
  select @a+@b as r;
END;
GO

EXEC sp_babel_1307_2 2.000, 3.000;
GO

DECLARE @a INT;
EXEC sp_babel_1307_2 @a OUT, 3.000;
SELECT @a;
GO

DECLARE @b INT;
EXEC sp_babel_1307_2 2.000, @b OUT;
SELECT @b;
GO

DECLARE @a INT;
DECLARE @b INT;
EXEC sp_babel_1307_2 @a OUT, @b OUT;
SELECT @a+@b;
GO
