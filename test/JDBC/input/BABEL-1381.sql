CREATE PROCEDURE p_babel_1381_tinyint (@a tinyint OUTPUT) AS
BEGIN
  SET @a=42;
  select @a as a;
END;
GO

EXEC p_babel_1381_tinyint 1;
GO

CREATE PROCEDURE p_babel_1381_nchar (@a nchar OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_nchar 'a';
GO

CREATE PROCEDURE p_babel_1381_nchar_10 (@a nchar(10) OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_nchar_10 'a';
GO

CREATE PROCEDURE p_babel_1381_varchar (@a varchar OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_varchar 'a';
GO

CREATE PROCEDURE p_babel_1381_varchar_10 (@a varchar(10) OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_varchar_10 'a';
GO

CREATE PROCEDURE p_babel_1381_nvarchar (@a nvarchar OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_varchar 'a';
GO

CREATE PROCEDURE p_babel_1381_nvarchar_10 (@a nvarchar(10) OUTPUT) AS
BEGIN
  SET @a='helloworld';
  select @a as a;
END;
GO

EXEC p_babel_1381_nvarchar_10 'a';
GO

CREATE PROCEDURE p_babel_1381_binary (@a binary OUTPUT) AS
BEGIN
  SET @a=0xabcdef;
  select @a as a;
END;
GO

EXEC p_babel_1381_binary 0x1;
GO

CREATE PROCEDURE p_babel_1381_varbinary (@a varbinary OUTPUT) AS
BEGIN
  SET @a=0xabcdef;
  select @a as a;
END;
GO

EXEC p_babel_1381_varbinary 0x1;
GO

CREATE PROCEDURE p_babel_1381_varbinary_10 (@a varbinary(10) OUTPUT) AS
BEGIN
  SET @a=0xabcdef;
  select @a as a;
END;
GO

EXEC p_babel_1381_varbinary_10 0x1;
GO
