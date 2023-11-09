-- Test is only valid when default server encoding is WIN1252

SELECT CONVERT(VARCHAR(MAX), 0x123456789)
GO

SELECT CONVERT(VARCHAR(10), 0x123456789)
GO

SELECT CONVERT(VARBINARY(10), '#Eg‰')
GO

SELECT CONVERT(VARCHAR(1), 0x99)
GO

SELECT CONVERT(VARCHAR(2), 0x999999)
GO

SELECT CONVERT(VARBINARY(1), '™')
GO

SELECT CAST('™' AS VARBINARY)
GO

SELECT CAST('™™™' AS VARBINARY(2))
GO

SELECT CONVERT(VARCHAR(10), 0x80)
GO

-- 0x81 does not exist is empty in some encodings
SELECT CONVERT(VARCHAR(10), 0x81)
GO

SELECT CONVERT(VARCHAR(10), 0x330033)
GO

SELECT CONVERT(VARBINARY(10), 'ｳ')
GO

SELECT CONVERT(VARBINARY(10), 'ﾊﾟ')
GO

SELECT CONVERT(VARBINARY(10), 'A')
GO

SELECT CONVERT(VARBINARY(10), 'ア')
GO

SELECT CONVERT(VARBINARY(10), 0x81)
GO

SELECT CONVERT(VARBINARY(10), 0x330033)
GO

DECLARE @key varchar(20) = 'part1'
DECLARE @email varchar(20) = 'part2'
SELECT CONVERT(VARCHAR(10), HASHBYTES('SHA1', @key + LOWER(@email)))
GO


CREATE TABLE babel_1940_t1 (a VARBINARY(9))
GO

INSERT INTO babel_1940_t1 VALUES(0x80)
INSERT INTO babel_1940_t1 VALUES(0xaaa)
INSERT INTO babel_1940_t1 VALUES(0x123456789)
GO

SELECT * FROM babel_1940_t1
GO

SELECT CONVERT(VARCHAR(9), a) FROM babel_1940_t1
GO

SELECT CAST(a as VARCHAR(9)) FROM babel_1940_t1
GO

SELECT CAST(a as VARCHAR(10)) FROM babel_1940_t1
GO


CREATE TABLE babel_1940_t2(a varchar(10) collate japanese_cs_as);
GO

-- only null bytes becomes empty string since we remove trailing nulls
INSERT INTO babel_1940_t2 VALUES (CAST (0x00 AS VARCHAR))
GO

SELECT * FROM babel_1940_t2 WHERE a = '';
GO

INSERT INTO babel_1940_t2 VALUES ('a'), ('b'), ('™'), ('ƀ'), ('ä');
GO

-- Characters with no mapping transform to Ox3F or ?
SELECT CONVERT(VARBINARY(10), a) FROM babel_1940_t2
GO

-- Truncate trailing null bytes
SELECT CAST(CAST(0x616263 as BINARY(128)) as VARCHAR)
GO

-- Block intermidiate null byte
SELECT CAST(CAST(0x610063 as BINARY(128)) as VARCHAR)
GO

DROP TABLE babel_1940_t2
GO

DROP TABLE babel_1940_t1
GO

