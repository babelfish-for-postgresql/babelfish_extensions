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


create table babel_1940_t2( a varchar(20) collate japanese_cs_as);
GO

insert into babel_1940_t2 values ('ｳ'), ('C'), ('ﾊﾟ'), ('３'), ('c'), ('ｲ'), ('Ｃ'),('ﾊ'),
('1'), ('ｱ'),('パ'), ('b'), ('2'), ('B'),('１'), ('Ａ'),('ア'),('A'), ('a'),('AbC'), ('aBc');
GO


SELECT CONVERT(varbinary(MAX), a) FROM babel_1940_t2
GO

SELECT CONVERT(varchar(MAX), CONVERT(varbinary(MAX), a)) FROM babel_1940_t2
GO

DROP TABLE babel_1940_t2
GO

DROP TABLE babel_1940_t1
GO
