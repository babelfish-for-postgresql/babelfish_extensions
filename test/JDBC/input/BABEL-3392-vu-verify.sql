SELECT * FROM babel3392_v1 ORDER BY 1;
GO

SELECT * FROM babel3392_v2 ORDER BY 1;
GO

SELECT * FROM babel3392_v3 ORDER BY 1;
GO

SELECT babel3392_v1.* , babel3392_v2.*, babel3392_v3.* FROM babel3392_v1, babel3392_v2, babel3392_v3
UNION ALL
SELECT babel3392_v2.* , babel3392_v3.*, babel3392_v1.* FROM babel3392_v1, babel3392_v2, babel3392_v3
ORDER BY 1, 2, 3
GO

SELECT NULL, NULL
UNION ALL
SELECT * FROM (SELECT babel3392_v1.* , babel3392_v2.* FROM babel3392_v1, babel3392_v2) t1
ORDER BY 1, 2
GO

DROP view babel3392_v1;
DROP view babel3392_v2;
DROP view babel3392_v3;
GO

SELECT CAST('1' AS CHAR(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST('1' AS CHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST('1' AS NCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS BINARY(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST(1 AS BINARY(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS VARCHAR(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST(1 AS VARCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS VARCHAR(10)) AS Col1
UNION
SELECT CAST('2' AS CHAR(15))
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(15))
UNION
SELECT CAST(1 AS VARCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
UNION
SELECT CAST('2' AS CHAR(15))
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(15))
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS VARCHAR(10)) AS Col1
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(15))
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST(N'Жऌ' AS NCHAR(15))
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT NULL
UNION
SELECT CAST(1 AS VARCHAR(10)) AS Col1
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(15))
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
UNION
SELECT NULL
ORDER BY 1
GO

SELECT NULL
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10))
UNION
SELECT CAST(N'Жऌ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST(N'Жऌ' AS NCHAR(15))
UNION
SELECT NULL
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(10))
ORDER BY 1
GO

SELECT CAST(1 AS CHAR(1)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(255)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(15)) AS Col1
UNION
SELECT CAST('2' AS CHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(10)) AS Col1
UNION
SELECT CAST('2' AS CHAR(15)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(15)) AS Col1
UNION
SELECT CAST('2' AS NCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(10)) AS Col1
UNION
SELECT CAST('2' AS NCHAR(15)) AS Col1
ORDER BY 1
GO

SELECT CAST(N'ΘЖऌฒ' AS NCHAR(10)) AS Col1
UNION
SELECT NULL AS Col1
ORDER BY 1
GO

SELECT NULL AS Col1
UNION
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(10)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS BINARY(4)) AS Col1
UNION
SELECT CAST(2 AS BINARY(8)) AS Col1
ORDER BY 1
GO

SELECT CAST(1 AS BINARY(4)) AS Col1
UNION
SELECT CAST(2 AS BINARY(8)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(4)) AS Col1
UNION
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(8)) AS Col1
ORDER BY 1
GO

SELECT CAST(N'ΘЖऌฒ' AS NCHAR(8)) AS Col1
UNION
SELECT CAST('1' AS CHAR(4)) AS Col1
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(4))
INTERSECT
SELECT CAST('1' AS CHAR(8))
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(8))
INTERSECT
SELECT CAST('1' AS CHAR(4))
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(8))
INTERSECT
SELECT CAST(N'1' AS NCHAR(4))
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(4))
EXCEPT
SELECT CAST('1' AS CHAR(8))
ORDER BY 1
GO

SELECT CAST('1' AS CHAR(8))
EXCEPT
SELECT CAST('1' AS CHAR(4))
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(8))
EXCEPT
SELECT CAST('2' AS CHAR(4))
ORDER BY 1
GO

-- Multiple Unions --
SELECT CAST('1' AS CHAR(8))
UNION 
SELECT NULL
UNION
SELECT NULL
ORDER BY 1
GO

SELECT NULL
UNION 
SELECT CAST('1' AS CHAR(8))
UNION
SELECT NULL
ORDER BY 1
GO

SELECT NULL
UNION
SELECT NULL
GO

SELECT NULL
UNION ALL
SELECT NULL
GO

SELECT NULL
UNION 
SELECT NULL
UNION
SELECT CAST('1' AS CHAR(8))
ORDER BY 1
GO

SELECT NULL
UNION 
SELECT NULL
UNION
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(8))
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(16))
UNION 
SELECT CAST('1' AS CHAR(8))
UNION
SELECT NULL
ORDER BY 1
GO

SELECT CAST('2' AS CHAR(16))
UNION 
SELECT CAST('1' AS NCHAR(8))
UNION
SELECT NULL
ORDER BY 1
GO

SELECT CAST('2' AS NCHAR(16))
UNION 
SELECT CAST('1' AS NCHAR(8))
UNION
SELECT NULL
ORDER BY 1
GO

SELECT CAST('2' AS NCHAR(16))
UNION ALL
SELECT CAST('1' AS NCHAR(8))
UNION ALL
SELECT NULL
ORDER BY 1
GO

SELECT NULL
UNION ALL
SELECT NULL
UNION ALL
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(15))
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(16))
INTERSECT 
SELECT CAST('1' AS NCHAR(8))
INTERSECT
SELECT CAST('1' AS NCHAR(4))
ORDER BY 1
GO

SELECT CAST('1' AS NCHAR(16))
INTERSECT 
SELECT CAST('2' AS NCHAR(8))
INTERSECT
SELECT CAST('1' AS NCHAR(4))
ORDER BY 1
GO

SELECT NULL
INTERSECT 
SELECT NULL
INTERSECT
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(15))
ORDER BY 1
GO

SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

SET babelfish_showplan_all ON
GO

SELECT CAST(N'ΘЖऌฒ' AS NCHAR(8)) AS Col1
UNION
SELECT CAST('1' AS CHAR(4)) AS Col1
ORDER BY 1
GO

SELECT NULL
UNION
SELECT NULL
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(12)) AS Col1
ORDER BY 1
GO

SELECT cast('foo' as CHAR(3))
UNION
SELECT 'longer string'
ORDER BY 1
GO

SET babelfish_showplan_all OFF
GO

CREATE TABLE babel3392_nchar_tbl(a NCHAR(20))
GO

INSERT INTO babel3392_nchar_tbl (a)
    SELECT CAST(N'ΘЖऌฒ' AS NCHAR(10)) AS Col1
    UNION
    SELECT NULL AS Col1
    ORDER BY 1
GO

DROP TABLE babel3392_nchar_tbl
GO

-- Should error
WITH babel3392_recursive_cte(a)
AS (
    SELECT NULL
    UNION ALL
    SELECT CAST(a + 'a' AS CHAR(10)) from babel3392_recursive_cte where a != 'aaaaa'
)
SELECT a from babel3392_recursive_cte order by a
GO

WITH babel3392_recursive_cte(a)
AS (
    SELECT 'a'
    UNION ALL
    SELECT CAST(a + 'a' AS CHAR(10)) from babel3392_recursive_cte where a != 'aaaaa'
)
SELECT a from babel3392_recursive_cte order by a
GO

-- COALESCE / ISNULL
SELECT ISNULL(null, cast(N'ΘЖऌฒ' as NCHAR(15)))
GO

-- BABEL-4157
SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1 
    UNION
    SELECT CAST('varchar' AS VARCHAR(40)) AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('varchar' AS VARCHAR(40)) AS babel4157_c1
    UNION
    SELECT 'string' AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1 
    UNION
    SELECT CAST('varchar' AS VARCHAR(MAX)) AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(40)) AS babel4157_c1
    UNION
    SELECT 'string' AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1
    UNION
    SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(40)) AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(MAX)) AS babel4157_c1
    UNION
    SELECT 'string' AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

CREATE TABLE babel4157_tbl2 (c1 varchar(40) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1
    UNION
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

CREATE TABLE babel4157_tbl2 (c1 nvarchar(40) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT N'ΘЖऌฒ' AS babel4157_c1
    UNION ALL
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

CREATE TABLE babel4157_tbl2 (c1 varchar(max) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1
    UNION
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

CREATE TABLE babel4157_tbl2 (c1 varchar(max) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('string' AS VARCHAR(40)) AS babel4157_c1
    UNION ALL
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

CREATE TABLE babel4157_tbl2 (c1 nvarchar(max) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT N'ΘЖऌฒ' AS babel4157_c1
    UNION
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

CREATE TABLE babel4157_tbl2 (c1 nvarchar(max) not null);
go

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(40)) AS babel4157_c1
    UNION ALL
    SELECT c1 from babel4157_tbl2
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
DROP TABLE babel4157_tbl2
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1
    UNION
    SELECT CAST(N'ΘЖऌฒ' AS NCHAR(40)) AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT 'string' AS babel4157_c1 
    UNION
    SELECT CAST('char' AS CHAR(40)) AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('char' AS CHAR(15))  AS babel4157_c1
    UNION
    SELECT CAST(N'Жऌ' AS NCHAR(20))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('char' AS CHAR(20))  AS babel4157_c1
    UNION
    SELECT CAST('varchar' AS VARCHAR(15))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('char' AS CHAR(20))  AS babel4157_c1
    UNION
    SELECT CAST(N'Жऌ' AS NVARCHAR(15))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('char' AS CHAR(20))  AS babel4157_c1
    UNION
    SELECT CAST(N'Жऌ' AS NVARCHAR(MAX))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

-- Currently gives wrong typmod, need to support nvarchar literals
SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('char' AS CHAR(20))  AS babel4157_c1
    UNION
    SELECT N'Жऌ' AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST(N'Жऌ' AS NCHAR(20))  AS babel4157_c1
    UNION
    SELECT CAST('varchar' AS VARCHAR(15))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST(N'Жऌ' AS NCHAR(20))  AS babel4157_c1
    UNION
    SELECT CAST('nvarchar' AS NVARCHAR(15))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT CAST('varchar' AS VARCHAR(15))  AS babel4157_c1
    UNION
    SELECT CAST(N'Жऌ' AS NVARCHAR(20))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO


SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT cast(17 as binary(1))  AS babel4157_c1
    UNION
    SELECT cast(10 as binary(2))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT cast(11 as varbinary(1))  AS babel4157_c1
    UNION
    SELECT cast(10 as varbinary(2))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT cast(11 as varbinary(1))  AS babel4157_c1
    UNION
    SELECT cast(10 as varbinary(max))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT cast(17 as binary(1))  AS babel4157_c1
    UNION
    SELECT cast(10 as varbinary(3))  AS babel4157_c1
) AS tbl
ORDER BY 1
GO

SELECT * FROM babel4157_tbl ORDER BY 1
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT 'string' AS babel4157_c1 
UNION
SELECT CAST('varchar' AS VARCHAR(40)) AS babel4157_c1
ORDER BY 1
GO

SELECT CAST('long string test' AS VARCHAR(MAX)) AS babel4157_c1 
UNION
SELECT CAST('foo' AS VARCHAR(4)) AS babel4157_c1
ORDER BY 1
GO

SELECT 'string' AS babel4157_c1
UNION
SELECT CAST('char' AS CHAR(15)) AS babel4157_c1
ORDER BY 1
GO

SELECT 'string' AS babel4157_c1
UNION
SELECT CAST(N'ΘЖऌฒ' AS NCHAR(15)) AS babel4157_c1
ORDER BY 1
GO

SELECT 'string' AS babel4157_c1
UNION
SELECT CAST(N'ΘЖऌฒ' AS NVARCHAR(40)) AS babel4157_c1
ORDER BY 1
GO

SELECT 'char'
ORDER BY 1
GO

SELECT 'char'
GO

SELECT 'foo'
UNION
SELECT 'longer string'
ORDER BY 1
GO

SELECT 'foo'
UNION
SELECT CAST('bar' AS VARCHAR(20))
ORDER BY 1
GO

SELECT 'longer string'
UNION
SELECT CAST('foo' as CHAR(3))
ORDER BY 1
GO

SELECT CAST('foo' as CHAR(3))
UNION
SELECT 'longer string'
ORDER BY 1
GO

SELECT 'longer string'
UNION
SELECT CAST('ऌฒ' as NCHAR(2))
ORDER BY 1
GO

SELECT CAST('ऌฒ' as NCHAR(2))
UNION
SELECT 'longer string'
ORDER BY 1
GO

-- VALUES
select tbl.babel3392_c1 into babel3392_vals from (
    values (CAST('1' AS CHAR(10))), (CAST(N'ΘЖऌฒ' AS NCHAR(15))), (NULL)
) as tbl(babel3392_c1)
GO

SELECT * FROM babel3392_vals;
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel3392_c1'
GO

DROP TABLE babel3392_vals;
GO

-- IN
SELECT 1 WHERE CAST('1' AS CHAR(10)) IN (
    CAST(N'1' AS NCHAR(10)),  CAST('2' AS CHAR(20)), CAST('3' AS VARCHAR), '4', NULL
);
GO

-- TEXT
SELECT CAST('foo' AS TEXT) UNION SELECT CAST('bar' as CHAR(10)) UNION SELECT NULL ORDER BY 1;
GO

-- BINARY 
select cast(17 as binary(1)) 
UNION
select cast(10 as binary(2))
ORDER BY 1
GO

select NULL
UNION
select cast(10 as binary(2))
ORDER BY 1
GO

-- Incorrect length
select cast(17 as varbinary(1)) UNION select cast(10 as varbinary(2)) ORDER BY 1;
GO

select cast(17 as varbinary(MAX)) UNION select cast(10 as varbinary(2)) ORDER BY 1;
GO

select cast(17 as varbinary(1)) UNION select cast(10 as varbinary(2)) union select cast(N'a' as NCHAR(10));  
GO

SELECT CAST(N'ΘЖऌฒ' AS NCHAR(15)) UNION select cast(10 as varbinary(2));
GO

SELECT CAST(1 as BIT) UNION SELECT cast(N'ab' as NCHAR(10)) UNION SELECT CAST('bar' as CHAR(10));
go

SELECT 'foo'
UNION
SELECT cast(17 as varbinary(2))
GO

SELECT 'foo'
UNION
SELECT cast(17 as varbinary(2))
ORDER BY 1
GO

SELECT cast(17 as varbinary(2))
UNION
SELECT 'foo'
ORDER BY 1
GO

SELECT 'foo'
UNION
SELECT 'bar'
UNION
SELECT cast(17 as varbinary(2))
ORDER BY 1
GO

-- BABEL-1874
SELECT DISTINCT CAST( 1 AS BIT) AS Col1
UNION
SELECT DISTINCT NULL
GO

SELECT DISTINCT NULL
UNION
SELECT CAST( 1 AS BIT) AS Col1
GO

SELECT DISTINCT 'longer string'
UNION
SELECT CAST('bar' as VARCHAR(3))
GO

CREATE TABLE babel1874 (a CHAR(3), b NVARCHAR(MAX), c BIT)
GO

INSERT INTO babel1874 VALUES ('foo', N'ΘЖऌฒ', 1)
GO

SELECT N'longer string' as c1, CAST('1' AS VARCHAR(10)) as c2, c as c3 FROM babel1874
UNION
SELECT a, COUNT(b), NULL as c3 FROM babel1874 GROUP BY a, c3
ORDER BY c3, c2, c1
GO

DROP TABLE babel1874
GO

CREATE TABLE babel3392_collation(c1 NVARCHAR(20) COLLATE japanese_cs_as, c2 NCHAR(10) COLLATE japanese_cs_as);
GO

INSERT INTO babel3392_collation VALUES ('う', 'ｳ')
go

SELECT * FROM babel3392_collation
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT c1 as babel4157_c1 FROM babel3392_collation 
    UNION
    SELECT c2 as babel4157_c1 FROM babel3392_collation
) tbl
GO

SELECT * FROM babel4157_tbl order by babel4157_c1 COLLATE japanese_cs_as
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT c1 as babel4157_c1 FROM babel3392_collation
    UNION
    SELECT 'foo' as babel4157_c1
) tbl
GO

SELECT * FROM babel4157_tbl order by babel4157_c1 COLLATE SQL_Latin1_General_CP1_CI_AS
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO

CREATE TABLE babel3392_nocol(c1 VARCHAR(30))
GO

INSERT INTO babel3392_nocol VALUES('foo')
GO

SELECT tbl.babel4157_c1 INTO babel4157_tbl FROM (
    SELECT c1 as babel4157_c1 FROM babel3392_nocol
    UNION
    SELECT c1 as babel4157_c1 FROM babel3392_collation 
) tbl
GO

SELECT * FROM babel4157_tbl order by babel4157_c1 COLLATE SQL_Latin1_General_CP1_CI_AS
GO

SELECT name, max_length FROM sys.columns WHERE name = 'babel4157_c1'
GO

DROP TABLE babel4157_tbl
GO
DROP TABLE babel3392_nocol
DROP TABLE babel3392_collation
GO
