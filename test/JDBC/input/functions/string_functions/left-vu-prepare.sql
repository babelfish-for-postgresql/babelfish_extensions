CREATE TABLE babel_4489_left_t1(a NCHAR(50))
GO
INSERT INTO babel_4489_left_t1 VALUES(N'abc🙂defghi🙂🙂')
INSERT INTO babel_4489_left_t1 VALUES(N'比尔·拉莫斯')
GO

CREATE TABLE babel_4489_left_t2(a NVARCHAR(50))
GO
INSERT INTO babel_4489_left_t2 VALUES(N'abc🙂defghi🙂🙂')
GO

CREATE TABLE babel_4489_left_t3(a CHAR(50))
GO
INSERT INTO babel_4489_left_t3 VALUES('  abcdefghi    ')
GO

CREATE TABLE babel_4489_left_t4(a VARCHAR(50))
GO
INSERT INTO babel_4489_left_t4 VALUES('  abcdefghi    ')
GO

CREATE TABLE babel_4489_left_t5(a VARBINARY(50))
GO
INSERT INTO babel_4489_left_t5 VALUES(0x2020616263642020)
GO

CREATE TABLE babel_4489_left_chinese_prc_ci_as(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS)
GO
INSERT INTO babel_4489_left_chinese_prc_ci_as VALUES(N'比尔·拉莫斯')
GO

CREATE TABLE babel_4489_left_chinese_prc_cs_as(a VARCHAR(50) COLLATE CHINESE_PRC_CS_AS)
GO
INSERT INTO babel_4489_left_chinese_prc_cs_as VALUES(N'比尔·拉莫斯')
GO

CREATE TABLE babel_4489_left_chinese_prc_ci_ai(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AI)
GO
INSERT INTO babel_4489_left_chinese_prc_ci_ai VALUES(N'比尔·拉莫斯')
GO

CREATE TABLE babel_4489_left_arabic_ci_as(a VARCHAR(50) COLLATE ARABIC_CI_AS)
GO
INSERT INTO babel_4489_left_arabic_ci_as VALUES(N'الله مع المتقين')
GO

CREATE TABLE babel_4489_left_arabic_cs_as(a VARCHAR(50) COLLATE ARABIC_CS_AS)
GO
INSERT INTO babel_4489_left_arabic_cs_as VALUES(N'الله مع المتقين')
GO

CREATE TABLE babel_4489_left_arabic_ci_ai(a VARCHAR(50) COLLATE ARABIC_CI_AI)
GO
INSERT INTO babel_4489_left_arabic_ci_ai VALUES(N'الله مع المتقين')
GO

CREATE TABLE babel_4489_left_image(a IMAGE)
GO
INSERT INTO babel_4489_left_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

CREATE TABLE babel_4489_left_text(a TEXT, b NTEXT)
GO
INSERT INTO babel_4489_left_text VALUES (N'abc🙂defghi🙂🙂', N'abc🙂defghi🙂🙂')
GO

CREATE TYPE dbo.babel_4489_left_imageUDT FROM image;
GO

CREATE TYPE dbo.babel_4489_left_varUDT FROM varchar(50);
GO

CREATE TABLE babel_4489_left_UDT(a dbo.babel_4489_left_imageUDT, b dbo.babel_4489_left_varUDT)
GO
INSERT INTO babel_4489_left_UDT VALUES(CAST('abcdef' as dbo.babel_4489_left_imageUDT), CAST('abcdef' as dbo.babel_4489_left_varUDT))
GO

CREATE VIEW babel_4489_left_dep_view AS
    SELECT LEFT(a, 5) as result from babel_4489_left_t2
GO

CREATE PROCEDURE babel_4489_left_dep_proc AS
    SELECT LEFT(a, 5) as result from babel_4489_left_t2
GO

CREATE FUNCTION babel_4489_left_dep_func()
RETURNS NVARCHAR(50)
AS
BEGIN
RETURN (SELECT TOP 1 LEFT(a, 5) from babel_4489_left_t2)
END
GO

CREATE VIEW babel_4489_left_dep_view_1 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_t1
GO

CREATE VIEW babel_4489_left_dep_view_2 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_t2
GO

CREATE VIEW babel_4489_left_dep_view_3 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_t3
GO

CREATE VIEW babel_4489_left_dep_view_4 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_t4
GO

CREATE VIEW babel_4489_left_dep_view_5 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_t5
GO

CREATE VIEW babel_4489_left_dep_view_6 AS
    SELECT LEFT(a, 5) as result FROM babel_4489_left_text
GO

CREATE VIEW babel_4489_left_dep_view_7 AS
    SELECT LEFT(b, 5) as result FROM babel_4489_left_text
GO

CREATE FUNCTION babel_4489_left_itvf_func()
RETURNS TABLE
AS
RETURN (SELECT LEFT(a, 5) as result from babel_4489_left_t2)
GO