USE string_typmod_derived_db
GO

-- declared length of a scalar UDF: a longer value is clipped, as in SQL Server
SELECT dbo.short_udf(v30) AS s5, dbo.nshort_udf(n15) AS n3 FROM dbo.t
GO

-- user functions named like built-ins return their whole value
SELECT dbo.[left](v10, 2) AS udf_left, [left](v10, 2) AS left_call, dbo.concat(v10, 'x') AS udf_concat, concat(v10, 'x') AS concat_call FROM dbo.t
GO

SELECT * FROM dbo.v
GO

EXEC dbo.p
GO

EXEC sp_executesql N'SELECT dbo.short_udf(@s) AS s5, v10 + @s AS c FROM dbo.t', N'@s VARCHAR(30)', 'xyzxyzxyz'
GO

WITH c AS (SELECT dbo.short_udf(v30) AS s FROM dbo.t) SELECT s FROM c
GO

USE master
GO

-- built-in functions and expressions return their whole value
SELECT LEFT('abcdefgh', 3) AS l, RIGHT('abcdefgh', 3) AS r, SUBSTRING('abcdefgh', 2, 4) AS s, 'abc' + 'defg' AS p, CONCAT('ab', 'cd') AS c, NULLIF('abc', 'x') AS n, STUFF('abcdef', 2, 2, 'XYZ') AS st, REPLACE('aaa', 'a', 'bb') AS rp
GO

SELECT CASE WHEN 1 = 1 THEN 'short' ELSE 'much longer' END AS cs, COALESCE(NULL, 'coalesced') AS co, DB_NAME() AS dbn
GO

SELECT 'a' AS u UNION SELECT 'abcdef' ORDER BY 1
GO

SELECT x FROM (SELECT 'abc' + 'defgh' AS x) s
GO

SELECT CAST('x' AS VARCHAR(MAX)) AS cmax, REPLICATE('x', 10) AS rep
GO
