CREATE PROCEDURE babel_701_sp (@a varbinary OUTPUT) AS
BEGIN
  SET @a=0x121;
  Select @a as a;
END;
GO

EXEC babel_701_sp 0x122
GO

DROP PROCEDURE babel_701_sp
GO
