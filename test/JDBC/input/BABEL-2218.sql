use master;
go

CREATE TABLE t2218(c1 INT)
INSERT INTO t2218 VALUES (2218);
INSERT INTO t2218 VALUES (2219);
GO

-- should throw an error
CREATE FUNCTION f2218()
RETURNS INT AS
BEGIN
  DECLARE @return INT
  SET @return = 0
  SELECT * from t2218
  RETURN @return
END
GO

-- if select statement has a destination, no error
CREATE FUNCTION f2218()
RETURNS INT AS
BEGIN
  DECLARE @return INT
  SET @return = 0
  SELECT @return=c1 from t2218
  RETURN @return
END
GO

-- we have an issue. see BABEL-2655
--SELECT f2218();
--GO

DECLARE @ret INT;
SET @ret = f2218();
SELECT @ret;

DROP FUNCTION f2218;
GO

-- Throw error if cursor for select doesn't have a destination(INTO @variable) inside a function BABEL-4586
CREATE FUNCTION f_getval()RETURNS INTEGER
AS
BEGIN
DECLARE temp_cursor CURSOR FOR SELECT a FROM t2218
  OPEN temp_cursor
  FETCH NEXT FROM temp_cursor
  CLOSE temp_cursor
  RETURN 1
  END
go

-- cursor for select work if the destination(INTO @variable) is provided inside a function BABEL-4586
CREATE FUNCTION f_getval() RETURNS INTEGER
AS
BEGIN
DECLARE @my_var int
DECLARE temp_cursor CURSOR FOR SELECT a FROM t2218
  OPEN temp_cursor
  FETCH NEXT FROM temp_cursor INTO @my_var
  CLOSE temp_cursor
  RETURN @my_var
  END
go

DROP FUNCTION f_getval;
GO

-- cursor for select work with multiple fetch if the destination(INTO @variable) is provided inside a function BABEL-4586
CREATE FUNCTION f_getval() RETURNS INTEGER
AS
BEGIN
DECLARE @my_var int
DECLARE temp_cursor CURSOR FOR SELECT a FROM t2218
  OPEN temp_cursor
  FETCH NEXT FROM temp_cursor INTO @my_var
  FETCH NEXT FROM temp_cursor INTO @my_var
  CLOSE temp_cursor
  RETURN @my_var
  END
go

DROP FUNCTION f_getval;
GO

-- cursor for select should throw error even if one fetch tries to return results to client
CREATE FUNCTION f_getval() RETURNS INTEGER
AS
BEGIN
DECLARE @my_var int
DECLARE temp_cursor CURSOR FOR SELECT a FROM t2218
  OPEN temp_cursor
  FETCH NEXT FROM temp_cursor INTO @my_var
  FETCH NEXT FROM temp_cursor
  CLOSE temp_cursor
  RETURN @my_var
  END
go

DROP TABLE t2218;
GO
