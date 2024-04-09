CREATE TABLE babel_4489_trim_t1(a NCHAR(50), b NCHAR(20))
GO
INSERT INTO babel_4489_trim_t1 VALUES(N'  abc🙂defghi🙂🙂    ', N'ab🙂 ')
INSERT INTO babel_4489_trim_t1 VALUES(N'  比尔·拉莫斯    ', N'比拉斯 ')
GO

CREATE TABLE babel_4489_trim_t2(a NVARCHAR(50), b NVARCHAR(20))
GO
INSERT INTO babel_4489_trim_t2 VALUES(N'  abc🙂defghi🙂🙂    ', N'ab🙂 ')
GO

CREATE TABLE babel_4489_trim_t3(a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS, b VARCHAR(20) COLLATE CHINESE_PRC_CI_AS)
GO
INSERT INTO babel_4489_trim_t3 VALUES(N'  比尔·拉莫斯    ', N'比拉斯 ')
GO

CREATE TABLE babel_4489_trim_image(a IMAGE)
GO
INSERT INTO babel_4489_trim_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

CREATE TABLE babel_4489_trim_text(a TEXT, b NTEXT)
GO
INSERT INTO babel_4489_trim_text VALUES (N'  abc🙂defghi🙂🙂    ', N'  abc🙂defghi🙂🙂    ')
GO

CREATE VIEW babel_4489_trim_view AS
    SELECT ('|' + TRIM(b FROM a) + '|') as result from babel_4489_trim_t2
GO

CREATE PROCEDURE babel_4489_trim_proc AS
    SELECT ('|' + TRIM(b FROM a) + '|') as result from babel_4489_trim_t2
GO

CREATE FUNCTION babel_4489_trim_func()
RETURNS TABLE
AS
RETURN (SELECT CAST(('|' + TRIM(b FROM a) + '|') AS sys.NVARCHAR(50)) as result from babel_4489_trim_t2)
GO