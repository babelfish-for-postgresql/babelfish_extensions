CREATE TABLE babel_4489_rtrim_t1(a NCHAR(50))
GO
INSERT INTO babel_4489_rtrim_t1 VALUES(N'  abc🙂defghi🙂🙂    ')
INSERT INTO babel_4489_rtrim_t1 VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_rtrim_t2(a NVARCHAR(50))
GO
INSERT INTO babel_4489_rtrim_t2 VALUES(N'  abc🙂defghi🙂🙂    ')
GO

CREATE TABLE babel_4489_rtrim_chinese_prc_ci_as(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS)
GO
INSERT INTO babel_4489_rtrim_chinese_prc_ci_as VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_rtrim_chinese_prc_cs_as(a VARCHAR(50) COLLATE CHINESE_PRC_CS_AS)
GO
INSERT INTO babel_4489_rtrim_chinese_prc_cs_as VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_rtrim_chinese_prc_ci_ai(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AI)
GO
INSERT INTO babel_4489_rtrim_chinese_prc_ci_ai VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_rtrim_arabic_ci_as(a VARCHAR(50) COLLATE ARABIC_CI_AS)
GO
INSERT INTO babel_4489_rtrim_arabic_ci_as VALUES(N'  الله مع المتقين    ')
GO

CREATE TABLE babel_4489_rtrim_arabic_cs_as(a VARCHAR(50) COLLATE ARABIC_CS_AS)
GO
INSERT INTO babel_4489_rtrim_arabic_cs_as VALUES(N'  الله مع المتقين    ')
GO

CREATE TABLE babel_4489_rtrim_arabic_ci_ai(a VARCHAR(50) COLLATE ARABIC_CI_AI)
GO
INSERT INTO babel_4489_rtrim_arabic_ci_ai VALUES(N'  الله مع المتقين    ')
GO

CREATE TABLE babel_4489_rtrim_image(a IMAGE)
GO
INSERT INTO babel_4489_rtrim_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

CREATE TABLE babel_4489_rtrim_text(a TEXT, b NTEXT)
GO
INSERT INTO babel_4489_rtrim_text VALUES (N'  abc🙂defghi🙂🙂    ', N'  abc🙂defghi🙂🙂    ')
GO

CREATE TYPE dbo.babel_4489_rtrim_imageUDT FROM image;
GO

CREATE TYPE dbo.babel_4489_rtrim_varUDT FROM varchar(50);
GO

CREATE TABLE babel_4489_rtrim_UDT(a dbo.babel_4489_rtrim_imageUDT, b dbo.babel_4489_rtrim_varUDT)
GO
INSERT INTO babel_4489_rtrim_UDT VALUES(CAST('abcdef' as dbo.babel_4489_rtrim_imageUDT), CAST('abcdef' as dbo.babel_4489_rtrim_varUDT))
GO

CREATE VIEW babel_4489_rtrim_dep_view AS
    SELECT ('|' + RTRIM(a) + '|') as result from babel_4489_rtrim_t2
GO

CREATE PROCEDURE babel_4489_rtrim_dep_proc AS
    SELECT ('|' + RTRIM(a) + '|') as result from babel_4489_rtrim_t2
GO

CREATE FUNCTION babel_4489_rtrim_dep_func()
RETURNS NVARCHAR(50)
AS
BEGIN
RETURN (SELECT TOP 1 ('|' + RTRIM(a) + '|') FROM babel_4489_rtrim_t2)
END
GO

CREATE FUNCTION babel_4489_rtrim_itvf_func()
RETURNS TABLE
AS
RETURN (SELECT ('|' + RTRIM(a) + '|') as result FROM babel_4489_rtrim_t2)
GO