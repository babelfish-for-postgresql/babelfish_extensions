CREATE TABLE babel_4489_ltrim_t1(a NCHAR(50))
GO
INSERT INTO babel_4489_ltrim_t1 VALUES(N'  abc🙂defghi🙂🙂    ')
INSERT INTO babel_4489_ltrim_t1 VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_ltrim_t2(a NVARCHAR(50))
GO
INSERT INTO babel_4489_ltrim_t2 VALUES(N'  abc🙂defghi🙂🙂    ')
GO

CREATE TABLE babel_4489_ltrim_t3(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS)
GO
INSERT INTO babel_4489_ltrim_t3 VALUES(N'  比尔·拉莫斯    ')
GO

CREATE TABLE babel_4489_ltrim_image(a IMAGE)
GO
INSERT INTO babel_4489_ltrim_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

CREATE TABLE babel_4489_ltrim_text(a TEXT, b NTEXT)
GO
INSERT INTO babel_4489_ltrim_text VALUES (N'  abc🙂defghi🙂🙂    ', N'  abc🙂defghi🙂🙂    ')
GO

CREATE VIEW babel_4489_ltrim_dep_view AS
    SELECT ('|' + LTRIM(a) + '|') as result FROM babel_4489_ltrim_t2
GO

CREATE PROCEDURE babel_4489_ltrim_dep_proc AS
    SELECT ('|' + LTRIM(a) + '|') as result FROM babel_4489_ltrim_t2
GO

CREATE FUNCTION babel_4489_ltrim_dep_func()
RETURNS NVARCHAR(50)
AS
BEGIN
RETURN (SELECT TOP 1 ('|' + LTRIM(a) + '|') FROM babel_4489_ltrim_t2)
END
GO

CREATE FUNCTION babel_4489_ltrim_itvf_func()
RETURNS TABLE
AS
RETURN (SELECT ('|' + LTRIM(a) + '|') as result FROM babel_4489_ltrim_t2)
GO