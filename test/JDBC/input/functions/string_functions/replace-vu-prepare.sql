CREATE TABLE babel_4836_replace_t1(a NCHAR(50), b NCHAR(20), c NCHAR(20))
GO
INSERT INTO babel_4836_replace_t1 VALUES(N'  abc🙂defghi🙂🙂    ', N'🙂de', N'x🙂y')
INSERT INTO babel_4836_replace_t1 VALUES(N'  比尔·拉莫斯    ', N'拉莫', N'尔·比')
GO

CREATE TABLE babel_4836_replace_t2(a NVARCHAR(50), b NVARCHAR(20), c NVARCHAR(20))
GO
INSERT INTO babel_4836_replace_t2 VALUES(N'  abc🙂defghi🙂🙂    ', N'🙂de', N'x🙂y')
GO

CREATE TABLE babel_4836_replace_t3(a VARCHAR(50), b VARCHAR(20), c VARCHAR(20))
GO
INSERT INTO babel_4836_replace_t3 VALUES('  abc🙂defghi🙂🙂    ', '🙂de', 'x🙂y')
GO

CREATE TABLE babel_4836_replace_t4(a BINARY(50), b BINARY(20), c BINARY(20))
GO
INSERT INTO babel_4836_replace_t4 VALUES(0x6162636465, 0x6263, 0x747576)
GO

CREATE TABLE babel_4836_replace_t5(a VARBINARY(50), b VARBINARY(20), c VARBINARY(20))
GO
INSERT INTO babel_4836_replace_t5 VALUES(0x6162636465, 0x6263, 0x747576)
GO

CREATE TABLE babel_4836_replace_chinese_prc_ci_as(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS, b VARCHAR(20) COLLATE CHINESE_PRC_CI_AS, c VARCHAR(20) COLLATE CHINESE_PRC_CI_AS)
GO
INSERT INTO babel_4836_replace_chinese_prc_ci_as VALUES(N'  比尔·拉莫斯    ', N'拉莫', N'尔·比')
GO

CREATE TABLE babel_4836_replace_chinese_prc_cs_as(a VARCHAR(50) COLLATE CHINESE_PRC_CS_AS, b VARCHAR(20) COLLATE CHINESE_PRC_CS_AS, c VARCHAR(20) COLLATE CHINESE_PRC_CS_AS)
GO
INSERT INTO babel_4836_replace_chinese_prc_cs_as VALUES(N'  比尔·拉莫斯    ', N'拉莫', N'尔·比')
GO

CREATE TABLE babel_4836_replace_arabic_ci_as(a VARCHAR(50) COLLATE ARABIC_CI_AS, b VARCHAR(20) COLLATE ARABIC_CI_AS, c VARCHAR(20) COLLATE ARABIC_CI_AS)
GO
INSERT INTO babel_4836_replace_arabic_ci_as VALUES(N'  الله مع المتقين    ', N'ين', N'مع')
GO

CREATE TABLE babel_4836_replace_arabic_cs_as(a VARCHAR(50) COLLATE ARABIC_CS_AS, b VARCHAR(20) COLLATE ARABIC_CS_AS, c VARCHAR(20) COLLATE ARABIC_CS_AS)
GO
INSERT INTO babel_4836_replace_arabic_cs_as VALUES(N'  الله مع المتقين    ', N'ين', N'مع')
GO

CREATE TABLE babel_4836_replace_image(a IMAGE)
GO
INSERT INTO babel_4836_replace_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

CREATE TABLE babel_4836_replace_text(a TEXT, b TEXT, c TEXT)
GO
INSERT INTO babel_4836_replace_text VALUES (N'  abc🙂defghi🙂🙂    ', N'🙂def', N'jhi🙂')
GO

CREATE TABLE babel_4836_replace_ntext(a NTEXT, b NTEXT, c NTEXT)
GO
INSERT INTO babel_4836_replace_ntext VALUES (N'  abc🙂defghi🙂🙂    ', N'🙂def', N'jhi🙂')
GO

CREATE TYPE dbo.babel_4836_replace_imageUDT FROM image;
GO

CREATE TYPE dbo.babel_4836_replace_varUDT FROM varchar(50);
GO

CREATE TABLE babel_4836_replace_image_UDT_t(a dbo.babel_4836_replace_imageUDT, b dbo.babel_4836_replace_imageUDT, c dbo.babel_4836_replace_imageUDT)
GO
INSERT INTO babel_4836_replace_image_UDT_t VALUES(CAST('abcdef' as dbo.babel_4836_replace_imageUDT), CAST('bc' as dbo.babel_4836_replace_imageUDT), CAST('gh' as dbo.babel_4836_replace_imageUDT))
GO

CREATE TABLE babel_4836_replace_var_UDT_t(a dbo.babel_4836_replace_imageUDT, b dbo.babel_4836_replace_varUDT, c dbo.babel_4836_replace_varUDT)
GO
INSERT INTO babel_4836_replace_var_UDT_t VALUES(CAST('abcdef' as dbo.babel_4836_replace_imageUDT), CAST('bc' as dbo.babel_4836_replace_varUDT), CAST('gh' as dbo.babel_4836_replace_varUDT))
GO

CREATE VIEW babel_4836_replace_dep_view AS
    SELECT replace(a, b, c) as result FROM babel_4836_replace_t2
GO

CREATE VIEW babel_4836_replace_dep_view1 AS
    SELECT replace(a, b, c) as result FROM babel_4836_replace_t3
GO

CREATE PROCEDURE babel_4836_replace_dep_proc AS
    SELECT replace(a, b, c) as result FROM babel_4836_replace_t2
GO

CREATE FUNCTION babel_4836_replace_dep_func()
RETURNS NVARCHAR(50)
AS
BEGIN
RETURN (SELECT TOP 1 replace(a, b, c) FROM babel_4836_replace_t2)
END
GO

CREATE FUNCTION babel_4836_replace_itvf_func()
RETURNS TABLE
AS
RETURN (SELECT replace(a, b, c) as result FROM babel_4836_replace_t2)
GO