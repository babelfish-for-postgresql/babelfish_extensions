---------------------------
-- UDT
---------------------------

CREATE TYPE nchar_type FROM NCHAR(30);
CREATE TYPE nvarchar_type FROM NVARCHAR(30);
CREATE TYPE char_type FROM CHAR(30);
CREATE TYPE varchar_type FROM VARCHAR(30);
CREATE TYPE binary_type FROM BINARY(10);
CREATE TYPE varbinary_type FROM VARBINARY(10);
GO

---------------------------
-- implicite function calls
---------------------------

CREATE FUNCTION babel_4803_varchar_func (@s VARCHAR(4000)) 
RETURNS VARCHAR(4000) 
AS 
BEGIN 
    RETURN @s; 
END 
GO

CREATE FUNCTION babel_4803_nvarchar_func (@s NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS
BEGIN
    RETURN @s;
END
GO

CREATE FUNCTION babel_4803_char_func (@s CHAR(50))
RETURNS CHAR(50)
AS
BEGIN
    RETURN @s;
END
GO

CREATE FUNCTION babel_4803_nchar_func (@s NCHAR(50))
RETURNS NCHAR(50)
AS
BEGIN
    RETURN @s;
END
GO


------------------------------------
-- Procedures with declare statement
------------------------------------
CREATE PROCEDURE babel_4803_proc_nchar
AS
BEGIN
    DECLARE @mixedString NCHAR(40) = N'Hello 🙂🙂世界'
    SELECT @mixedString AS 'Mixed String', LEN(@mixedString) AS 'Length'
END
GO

CREATE PROCEDURE babel_4803_proc_nvarchar
AS
BEGIN
    DECLARE @mixedString NVARCHAR(40) = N'Hello 🙂🙂世界'
    SELECT @mixedString AS 'Mixed String', LEN(@mixedString) AS 'Length'
END
GO

CREATE PROCEDURE babel_4803_proc_ntext
AS
BEGIN
    SELECT CAST(CAST(N'Hello 🙂🙂世界' AS NVARCHAR(MAX)) AS NTEXT) as result1
END
GO

CREATE PROCEDURE babel_4803_proc_char
AS
BEGIN
    DECLARE @mixedString CHAR(40) = 'Hello 🙂🙂 ??世界' 
    SELECT @mixedString
END
GO


CREATE PROCEDURE babel_4803_proc_varchar
AS
BEGIN
    DECLARE @mixedString VARCHAR(40) = 'Hello 🙂🙂 ??世界' 
    SELECT @mixedString
END
GO


------------------------------------
-- functions with declare statement
------------------------------------

CREATE FUNCTION babel_4803_nchar_func1()
RETURNS NCHAR(50)
AS
BEGIN
    DECLARE @inputString NCHAR(50) = N'  abc🙂defghi🙂🙂    '
    RETURN @inputString
END
GO

CREATE FUNCTION babel_4803_nvarchar_func1()
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @inputString NVARCHAR(50) = N'  abc🙂defghi🙂🙂    '
    RETURN @inputString
END
GO

CREATE FUNCTION babel_4803_char_func1() 
RETURNS CHAR(50) 
AS 
BEGIN  
    DECLARE @inputString CHAR(50) = '  Hello 🙂🙂世界    ' 
    RETURN @inputString 
END 
GO

CREATE FUNCTION babel_4803_varchar_func1()
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @inputString VARCHAR(50) = '  Hello 🙂🙂世界   '
    RETURN @inputString
END
GO

