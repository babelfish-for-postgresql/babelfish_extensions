CREATE PROCEDURE babel_708_proc_1 AS
DECLARE @one varchar(2)
BEGIN
  SET @one = 'abcdef';
  SELECT @one;
END;
GO

EXEC babel_708_proc_1;
GO

CREATE PROCEDURE babel_708_proc_2(@one AS VARCHAR(2)) AS
BEGIN
  SET @one = 'abcdef';
  SELECT @one;
END;
GO

EXEC babel_708_proc_2 '';
GO

EXEC babel_708_proc_2 'zyxwvut';
GO

CREATE PROCEDURE babel_708_proc_3 AS
DECLARE @one numeric(10,4)
BEGIN
  SET @one = 12.3456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_3;
GO

CREATE PROCEDURE babel_708_proc_4(@one AS numeric(10,4)) AS
BEGIN
  SET @one = 12.3456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_4 0;
GO

EXEC babel_708_proc_4 99.9999999;
GO

CREATE PROCEDURE babel_708_proc_5 AS
DECLARE @one varbinary(2)
BEGIN
  SET @one = 0x0123456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_5;
GO

CREATE PROCEDURE babel_708_proc_6(@one AS VARBINARY(2)) AS
BEGIN
  SET @one = 0x0123456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_6 '';
GO

EXEC babel_708_proc_6 0xabcdefabcedf;
GO

CREATE PROCEDURE babel_708_proc_7 AS
DECLARE @one char(2)
BEGIN
  SET @one = 'abcede';
  SELECT @one;
END;
GO

EXEC babel_708_proc_7;
GO

CREATE PROCEDURE babel_708_proc_8(@one AS char(2)) AS
BEGIN
  SET @one = 'abcede';
  SELECT @one;
END;
GO

EXEC babel_708_proc_8 '';
GO

EXEC babel_708_proc_8 'abcedef';
GO

CREATE PROCEDURE babel_708_proc_9 AS
DECLARE @one binary(2)
BEGIN
  SET @one = 0x0123456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_9;
GO

CREATE PROCEDURE babel_708_proc_10(@one AS binary(2)) AS
BEGIN
  SET @one = 0x0123456789;
  SELECT @one;
END;
GO

EXEC babel_708_proc_10 '';
GO

EXEC babel_708_proc_10 0xabcdefabcdef;
GO

CREATE PROCEDURE babel_708_proc_11 AS
DECLARE @one datetimeoffset(2)
BEGIN
  SET @one = '2030-05-06 13:59:29.123456 -8:00';
  SELECT @one;
END;
GO

EXEC babel_708_proc_11;
GO

CREATE PROCEDURE babel_708_proc_12(@one AS datetimeoffset(2)) AS
BEGIN
  SET @one = '2030-05-06 13:59:29.123456 -8:00';
  SELECT @one;
END;
GO

EXEC babel_708_proc_12 '2040-05-06 13:59:29.567891 -8:00';
GO

CREATE PROCEDURE babel_708_proc_13 AS
DECLARE @one datetime2(2)
BEGIN
  SET @one = '2030-05-06 13:59:29.123456';
  SELECT @one;
END;
GO

EXEC babel_708_proc_13;
GO

CREATE PROCEDURE babel_708_proc_14(@one AS datetime2(2)) AS
BEGIN
  SET @one = '2030-05-06 13:59:29.123456';
  SELECT @one;
END;
GO

EXEC babel_708_proc_14 '2040-05-06 13:59:29.567891';
GO

DROP procedure babel_708_proc_1;
GO
DROP procedure babel_708_proc_2;
GO
DROP procedure babel_708_proc_3;
GO
DROP procedure babel_708_proc_4;
GO
DROP procedure babel_708_proc_5;
GO
DROP procedure babel_708_proc_6;
GO
DROP procedure babel_708_proc_7;
GO
DROP procedure babel_708_proc_8;
GO
DROP procedure babel_708_proc_9;
GO
DROP procedure babel_708_proc_10;
GO
DROP procedure babel_708_proc_11;
GO
DROP procedure babel_708_proc_12;
GO
DROP procedure babel_708_proc_13;
GO
DROP procedure babel_708_proc_14;
GO
