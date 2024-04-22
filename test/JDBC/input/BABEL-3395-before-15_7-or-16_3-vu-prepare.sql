CREATE TABLE upper_lower_dt (a VARCHAR(20), b NVARCHAR(24), c CHAR(20), d NCHAR(24))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N'Anikait ', N'Agrawal ', N'Anikait ', N'Agrawal ')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N' Anikait', N' Agrawal', N' Anikait', N' Agrawal')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N'   A',N'   🤣😃',N'   A',N'   🤣😃')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N' ',N' ',N' ',N' ')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N'',N'',N'',N'')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(N'a',N'A',N'a',N'A')
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(NULL,NULL,NULL,NULL)
GO
INSERT INTO upper_lower_dt(a, b, c, d) values(N'比尔·拉', N'比尔·拉', N'比尔·拉', N'比尔·拉')
GO

CREATE TABLE upper_lower_text(a TEXT)
GO
INSERT INTO upper_lower_text values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS text))
GO

CREATE TABLE upper_lower_ntext(a NTEXT)
GO
INSERT INTO upper_lower_ntext values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS ntext))
GO

CREATE TABLE upper_lower_image(a IMAGE)
GO
INSERT INTO upper_lower_image values(CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS image))
GO

-- UPPER
CREATE VIEW dep_view_upper AS
select UPPER(a) AS upper_a, UPPER(b) AS upper_b, UPPER(c) AS upper_c, UPPER(d) AS upper_d from upper_lower_dt WHERE UPPER(a) = N'ANIKAIT' and UPPER(b) = N'AGRAWAL' and UPPER(c) = N'ANIKAIT' and UPPER(d) = N'AGRAWAL';
GO

CREATE TABLE tab_arabic_ci_ai(col varchar(20) COLLATE arabic_ci_ai);
INSERT INTO tab_arabic_ci_ai VALUES ('لقد');
GO

CREATE TABLE tab_arabic_ci_as(col varchar(20) COLLATE arabic_ci_as);
INSERT INTO tab_arabic_ci_as VALUES ('لقد');
GO

CREATE TABLE tab_arabic_cs_as(col varchar(20) COLLATE arabic_cs_as);
INSERT INTO tab_arabic_cs_as VALUES ('لقد');
GO

CREATE TABLE tab_chinese_ci_ai(col varchar(20) COLLATE chinese_prc_ci_ai);
INSERT INTO tab_chinese_ci_ai VALUES ('比尔·拉');
GO

CREATE TABLE tab_chinese_ci_as(col varchar(20) COLLATE chinese_prc_ci_as);
INSERT INTO tab_chinese_ci_as VALUES ('比尔·拉');
GO

CREATE TABLE tab_chinese_cs_as(col varchar(20) COLLATE chinese_prc_cs_as);
INSERT INTO tab_chinese_cs_as VALUES ('比尔·拉');
GO

CREATE PROC dep_proc_upper AS
select UPPER(a), UPPER(b), UPPER(c), UPPER(d) from upper_lower_dt WHERE UPPER(a) = N'ANIKAIT' and UPPER(b) = N'AGRAWAL' and UPPER(c) = N'ANIKAIT' and UPPER(d) = N'AGRAWAL';
GO

CREATE FUNCTION dbo.dep_func_upper()
RETURNS VARCHAR(50)
AS
BEGIN
RETURN (select TOP 1 UPPER(a) from upper_lower_dt);
END
GO

CREATE VIEW dep_view_upper_lower AS
select UPPER(a) AS upper_a, LOWER(a) AS lower_a from upper_lower_text;
GO

CREATE PROC dep_proc_upper_lower AS
select UPPER(a), LOWER(a) from upper_lower_text;
GO

CREATE VIEW dep_view_upper_lower1 AS
select UPPER(a) AS upper_a, LOWER(a) AS lower_a from upper_lower_ntext;
GO

CREATE PROC dep_proc_upper_lower1 AS
select UPPER(a), LOWER(a) from upper_lower_ntext;
GO

-- LOWER
CREATE VIEW dep_view_lower AS
select LOWER(a) AS lower_a, LOWER(b) AS lower_b, LOWER(c) AS lower_c, LOWER(d) AS lower_d from upper_lower_dt WHERE LOWER(a) = N'anikait' and LOWER(b) = N'agrawal' and LOWER(c) = N'anikait' and LOWER(d) = N'agrawal';
GO

CREATE PROC dep_proc_lower AS
select LOWER(a), LOWER(b), LOWER(c), LOWER(d) from upper_lower_dt WHERE LOWER(a) = N'anikait' and LOWER(b) = N'agrawal' and LOWER(c) = N'anikait' and LOWER(d) = N'agrawal';
GO

CREATE FUNCTION dbo.dep_func_lower()
RETURNS VARCHAR(50)
AS
BEGIN
RETURN (select TOP 1 LOWER(a) from upper_lower_dt);
END
GO

CREATE FUNCTION dbo.tvp_func_upper_lower() 
RETURNS TABLE 
AS 
RETURN 
(
    SELECT CAST (UPPER(a) as VARCHAR) AS upper_a, CAST (LOWER(a) as VARCHAR) AS lower_a
    FROM upper_lower_dt
);
GO

CREATE VIEW dep_view_lower1 AS (
    select 
        lower(cast(N'ADJNFJH' as varchar(50))) as db1
    );
GO

CREATE TYPE dbo.MyUDT FROM image;
GO
