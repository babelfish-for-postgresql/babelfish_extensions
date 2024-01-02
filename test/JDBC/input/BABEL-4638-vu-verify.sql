-- arabic_ci_as
SELECT * FROM babel_4638_t1
GO

SELECT CAST(a AS CHAR(1)) + '|' FROM babel_4638_t1
GO

SELECT CAST(a AS CHAR(5)) + '|' FROM babel_4638_t1
GO

SELECT CAST(a AS NCHAR(1)) + '|' FROM babel_4638_t1
GO

SELECT CAST(a AS NCHAR(5)) + '|' FROM babel_4638_t1
GO

INSERT INTO babel_4638_char_t1 VALUES('ح'), ('غ'), ('سسس'), ('للل')
INSERT INTO babel_4638_nchar_t1 VALUES('ح'), ('غ'), ('سسس'), ('للل')
GO

-- here a is defined as CHAR(10) COLLATE arabic_ci_as
SELECT a + '|' FROM babel_4638_char_t1
GO

-- here a is defined as NCHAR(10) COLLATE arabic_ci_as
SELECT a + '|' FROM babel_4638_nchar_t1
GO

-- chinese_prc_ci_as
SELECT * FROM babel_4638_t2
GO

SELECT CAST(a AS CHAR(1)) + '|' FROM babel_4638_t2
GO

SELECT CAST(a AS CHAR(5)) + '|' FROM babel_4638_t2
GO

SELECT CAST(a AS NCHAR(1)) + '|' FROM babel_4638_t2
GO

SELECT CAST(a AS NCHAR(5)) + '|' FROM babel_4638_t2
GO

INSERT INTO babel_4638_char_t2 VALUES('五'), ('九'), ('乙乙乙'), ('魚魚魚')
INSERT INTO babel_4638_nchar_t2 VALUES('五'), ('九'), ('乙乙乙'), ('魚魚魚')
GO

-- here a is defined as CHAR(10) COLLATE chinese_prc_ci_as
SELECT a + '|' FROM babel_4638_char_t2
GO

-- here a is defined as NCHAR(10) COLLATE chinese_prc_ci_as
SELECT a + '|' FROM babel_4638_nchar_t2
GO

-- japanese_ci_as
SELECT * FROM babel_4638_t3
GO

SELECT CAST(a AS CHAR(1)) + '|' FROM babel_4638_t3
GO

SELECT CAST(a AS CHAR(5)) + '|' FROM babel_4638_t3
GO

SELECT CAST(a AS NCHAR(1)) + '|' FROM babel_4638_t3
GO

SELECT CAST(a AS NCHAR(5)) + '|' FROM babel_4638_t3
GO

INSERT INTO babel_4638_char_t3 VALUES('あ'), ('九'), ('ちちち'), ('さささ')
INSERT INTO babel_4638_nchar_t3 VALUES('あ'), ('九'), ('ちちち'), ('さささ')
GO

-- here a is defined as CHAR(10) COLLATE japanese_ci_as
SELECT a + '|' FROM babel_4638_char_t3
GO

-- here a is defined as NCHAR(10) COLLATE japanese_ci_as
SELECT a + '|' FROM babel_4638_nchar_t3
GO

-- hebrew_ci_as
SELECT * FROM babel_4638_t4
GO

SELECT CAST(a AS CHAR(1)) + '|' FROM babel_4638_t4
GO

SELECT CAST(a AS CHAR(5)) + '|' FROM babel_4638_t4
GO

SELECT CAST(a AS NCHAR(1)) + '|' FROM babel_4638_t4
GO

SELECT CAST(a AS NCHAR(5)) + '|' FROM babel_4638_t4
GO

INSERT INTO babel_4638_char_t4 VALUES('ב'), ('א'), ('קקק'), ('מממ');
INSERT INTO babel_4638_nchar_t4 VALUES('ב'), ('א'), ('קקק'), ('מממ');
GO

-- here a is defined as CHAR(10) COLLATE hebrew_ci_as
SELECT a + '|' FROM babel_4638_char_t4
GO

-- here a is defined as NCHAR(10) COLLATE hebrew_ci_as
SELECT a + '|' FROM babel_4638_nchar_t4
GO


-- Default
SELECT * FROM babel_4638_t5
GO

SELECT CAST(a as NVARCHAR(10)) FROM babel_4638_t5
GO

SELECT CAST(a AS CHAR(1)) + '|' FROM babel_4638_t5
GO

SELECT CAST(a AS CHAR(5)) + '|' FROM babel_4638_t5
GO

SELECT CAST(a AS NCHAR(1)) + '|' FROM babel_4638_t5
GO

SELECT CAST(a AS NCHAR(5)) + '|' FROM babel_4638_t5
GO

INSERT INTO babel_4638_char_t5 VALUES('a'), ('🙂'), ('🙂🙂🙂'), ('さささ');
INSERT INTO babel_4638_nchar_t5 VALUES('a'), ('🙂'), ('🙂🙂🙂'), ('さささ');
GO

-- here a is defined as CHAR(10)
SELECT a + '|' FROM babel_4638_char_t5
GO

-- here a is defined as NCHAR(10)
SELECT a + '|' FROM babel_4638_nchar_t5
GO

