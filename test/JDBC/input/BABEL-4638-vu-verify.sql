-- arabic_ci_as
SELECT * FROM babel_4638_t1
GO

SELECT CONCAT(CAST(a AS CHAR(1)), '|') FROM babel_4638_t1
GO

SELECT CONCAT(CAST(a AS CHAR(5)), '|') FROM babel_4638_t1
GO

-- chinese_prc_ci_as
SELECT * FROM babel_4638_t2
GO

SELECT CONCAT(CAST(a AS CHAR(1)), '|') FROM babel_4638_t2
GO

SELECT CONCAT(CAST(a AS CHAR(5)), '|') FROM babel_4638_t2
GO

-- japanese_ci_as
SELECT * FROM babel_4638_t3
GO

SELECT CONCAT(CAST(a AS CHAR(1)), '|') FROM babel_4638_t3
GO

SELECT CONCAT(CAST(a AS CHAR(5)), '|') FROM babel_4638_t3
GO

-- hebrew_ci_as
SELECT * FROM babel_4638_t4
GO

SELECT CONCAT(CAST(a AS CHAR(1)), '|') FROM babel_4638_t4
GO

SELECT CONCAT(CAST(a AS CHAR(5)), '|') FROM babel_4638_t4
GO
