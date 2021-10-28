CREATE TABLE babel_1096_t1 (a int)
GO

INSERT INTO babel_1096_t1 values (1);
GO

CREATE TABLE babel_1096_t2 (a int);
GO

CREATE PROCEDURE babel_1096_proc
AS
  INSERT INTO babel_1096_t2
  SELECT * FROM babel_1096_t1

  SELECT COUNT(*) FROM babel_1096_t2
GO

EXEC babel_1096_proc
GO

CREATE TABLE babel_956_t (a int, n int identity)
GO

CREATE PROCEDURE babel_956_proc
AS
  INSERT babel_956_t(a) SELECT 123
  SELECT @@identity
GO

CREATE FUNCTION babel_1095_proc ( @stringToSplit VARCHAR(MAX) )
RETURNS
  @returnList TABLE ([Name] [nvarchar] (500))
AS
BEGIN
  INSERT INTO @returnList
  SELECT ''

  SELECT @stringToSplit = ''
  RETURN;
END
GO

DROP PROCEDURE babel_1096_proc
GO

DROP TABLE babel_1096_t1
GO

DROP TABLE babel_1096_t2
GO

DROP PROCEDURE babel_956_proc
GO

DROP TABLE babel_956_t
GO

DROP FUNCTION babel_1095_proc
GO

