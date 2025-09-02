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

CREATE PROCEDURE babel_4803_proc1 (@in NCHAR(30))
AS
BEGIN
    SELECT @in
END
GO


CREATE PROCEDURE babel_4803_proc2 (@in NVARCHAR(30))
AS
BEGIN
    SELECT @in
END
GO

CREATE PROCEDURE babel_4803_proc3 (@in CHAR(30))
AS
BEGIN
    SELECT @in
END
GO

CREATE PROCEDURE babel_4803_proc4 (@in VARCHAR(30))
AS
BEGIN
    SELECT @in
END
GO

CREATE PROCEDURE babel_4803_proc5 (@in NCHAR(30))
AS
BEGIN
    DECLARE @mixedString1 NVARCHAR(40) = @in
    DECLARE @mixedString2 VARCHAR(40) = @in
    DECLARE @mixedString3 CHAR(40) = @in
    SELECT  @mixedString1, @mixedString2, @mixedString3
END
GO

CREATE PROCEDURE babel_4803_proc6 (@in NVARCHAR(30))
AS
BEGIN
    DECLARE @mixedString1 NCHAR(40) = @in
    DECLARE @mixedString2 VARCHAR(40) = @in
    DECLARE @mixedString3 CHAR(40) = @in
    SELECT  @mixedString1, @mixedString2, @mixedString3
END
GO

CREATE PROCEDURE babel_4803_proc7 (@in VARCHAR(30))
AS
BEGIN
    DECLARE @mixedString1 NCHAR(40) = @in
    DECLARE @mixedString2 NVARCHAR(40) = @in
    DECLARE @mixedString3 CHAR(40) = @in
    SELECT  @mixedString1, @mixedString2, @mixedString3
END
GO

CREATE PROCEDURE babel_4803_proc8 (@in CHAR(30))
AS
BEGIN
    DECLARE @mixedString1 NCHAR(40) = @in
    DECLARE @mixedString2 NVARCHAR(40) = @in
    DECLARE @mixedString3 VARCHAR(40) = @in
    SELECT  @mixedString1, @mixedString2, @mixedString3
END
GO

-- testing with Collate Clause
CREATE PROCEDURE babel_4803_proc9
AS 
BEGIN
    DECLARE @char CHAR(30) = N'こん 世界';
    DECLARE @varchar VARCHAR(30) = N'こん 世界';
    DECLARE @nchar NCHAR(30) = N'こん 世界';
    DECLARE @nvarchar NVARCHAR(30) =N'こん 世界';

    SELECT 
        @char COLLATE Japanese_CI_AS, @varchar COLLATE Japanese_CI_AS, @nchar COLLATE Japanese_CI_AS, @nvarchar COLLATE Japanese_CI_AS,
        @char COLLATE Chinese_PRC_CI_AS, @varchar COLLATE Chinese_PRC_CI_AS, @nchar COLLATE Chinese_PRC_CI_AS, @nvarchar COLLATE Chinese_PRC_CI_AS
END
GO

CREATE PROCEDURE babel_4803_proc10 (@a VARCHAR(30), @b CHAR(30), @c NVARCHAR(30), @d NCHAR(30))
AS 
BEGIN
    SELECT 
        @a COLLATE Japanese_CI_AS, @b COLLATE Japanese_CI_AS, @c COLLATE Japanese_CI_AS, @d COLLATE Japanese_CI_AS,
        @a COLLATE Chinese_PRC_CI_AS, @b COLLATE Chinese_PRC_CI_AS, @c COLLATE Chinese_PRC_CI_AS, @d COLLATE Chinese_PRC_CI_AS
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

-------------------------------
-- functions with collate
-------------------------------
CREATE FUNCTION babel_4803_varchar_func2 (@s VARCHAR(50))  
RETURNS VARCHAR(50)
AS  
BEGIN  
    RETURN @s COLLATE Japanese_CI_AS;  
END 
GO

CREATE FUNCTION babel_4803_char_func2 (@s CHAR(50))
RETURNS CHAR(50)
AS
BEGIN
    RETURN @s COLLATE Japanese_CI_AS;
END
GO

------------------------------------
-- Views with various cast
------------------------------------

CREATE VIEW babel_4803_view1 AS SELECT babel_4803_nchar_func1();
GO

CREATE VIEW babel_4803_view2 AS SELECT babel_4803_nvarchar_func1();
GO

CREATE VIEW babel_4803_view3 AS SELECT babel_4803_char_func1();
GO

CREATE VIEW babel_4803_view4 AS SELECT babel_4803_varchar_func1();
GO

CREATE VIEW babel_4803_view5 AS SELECT CAST(N'你好世界 Text にち 😀😍🌟💖' AS NVARCHAR)
GO

CREATE VIEW babel_4803_view6 AS SELECT CAST(N'你好世界 Text 中文 😀😍🌟💖' AS NCHAR)
GO

CREATE VIEW babel_4803_view7 AS SELECT CAST(CAST(N'你好世界 Text 中文 😀😍🌟💖' AS NVARCHAR) AS NCHAR)
GO

CREATE VIEW babel_4803_view8 AS SELECT CAST(CAST(N'你好世界 Text 中文 😀😍🌟💖' AS VARCHAR) AS NVARCHAR)
GO

CREATE VIEW babel_4803_view9 AS SELECT CAST(CAST(N'你好世界 Text 中文 😀😍🌟💖' AS CHAR) AS NCHAR)
GO

CREATE VIEW babel_4803_view10 AS SELECT babel_4803_nvarchar_func(CAST(N'你好 Text 中文 😀💖' as NVARCHAR))
GO

CREATE VIEW babel_4803_view11 AS SELECT babel_4803_nchar_func(Cast(N'你好 Text 中文 😀💖' as NCHAR))
GO


