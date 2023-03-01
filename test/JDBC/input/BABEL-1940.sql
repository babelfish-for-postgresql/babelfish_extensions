-- Earlier following queries were hanging indefinetely
SELECT CONVERT(VARCHAR(MAX), 0x123456789)
GO

SELECT CONVERT(VARCHAR(MAX), 0x80)
GO

SELECT CONVERT(VARCHAR(MAX), 0xaaa)
GO

declare @key varchar(20) = 'part1'
declare @email varchar(20) = 'part2'
SELECT CONVERT(VARCHAR(MAX), HASHBYTES('SHA1', @key + LOWER(@email)))
GO

create table babel_1940_t1 (a varbinary(9))
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

SELECT CAST(a as VARCHAR(MAX)) FROM babel_1940_t1
GO

DROP TABLE babel_1940_t1
GO
