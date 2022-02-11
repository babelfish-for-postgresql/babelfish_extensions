CREATE TABLE spExecutesqlTable1 (a INT, b VARCHAR(10));
CREATE TABLE spExecutesqlTable2 (a INT, b INT, c INT, d INT);
go

/* 1. Execute a string of statement */
DECLARE @SQLString NVARCHAR(100);
SET @SQLString = N'SELECT N''hello world'';';
EXEC sp_executesql @SQLString;
go

/* 2. Execute a statement string with parameters */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable1 VALUES (@a, @b);';
SET @ParamDef = N'@a INT, @b VARCHAR(10)';

DECLARE @p INT = 1;
EXEC sp_executesql @SQLString, @ParamDef, @p, @b = N'hello';
SELECT * FROM spExecutesqlTable1;
go

TRUNCATE TABLE spExecutesqlTable1;
go

/* 3. Execute a statement string with both unnamed params and named params */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c INT, @d INT';

EXEC sp_executesql @SQLString, @ParamDef, 1, 2, @d = 4, @c = 3;
SELECT * FROM spExecutesqlTable2;
go

TRUNCATE TABLE spExecutesqlTable2;
go

/* 4. Nested sp_executesql */
DECLARE @SQLString1 NVARCHAR(100);
DECLARE @SQLString2 NVARCHAR(max);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString1 = N'INSERT INTO spExecutesqlTable1 VALUES (@a, @b);'
SET @SQLString2 = @SQLString1 + N'EXEC sp_executesql N''INSERT INTO spExecutesqlTable1 VALUES (@c + @c, @d + @d);'', N''@c INT, @d VARCHAR(10)'', @a, @b;'
SET @ParamDef = N'@a INT, @b VARCHAR(10)';
EXEC sp_executesql @SQLString2, @ParamDef, @a = 10, @b = N'str';
SELECT * FROM spExecutesqlTable1;
go

TRUNCATE TABLE spExecutesqlTable1;
go

-- Nested with param name collision
DECLARE @SQLString1 NVARCHAR(100);
DECLARE @SQLString2 NVARCHAR(max);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString1 = N'INSERT INTO spExecutesqlTable1 VALUES (@a, @b);'
SET @SQLString2 = @SQLString1 + N'EXEC sp_executesql N''INSERT INTO spExecutesqlTable1 VALUES (@a + @a, @b + @b);'', N''@a INT, @b VARCHAR(10)'', @a, @b;'
SET @ParamDef = N'@a INT, @b VARCHAR(10)';
EXEC sp_executesql @SQLString2, @ParamDef, @a = 11, @b = N'rts';
SELECT * FROM spExecutesqlTable1;
go

TRUNCATE TABLE spExecutesqlTable1;
go

/* 5. Execute a statement string with OUT/INOUT param */
DECLARE @SQLString1 NVARCHAR(100);
DECLARE @SQLString2 NVARCHAR(max);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString1 = N'SET @a = @b + @b';
SET @SQLString2 = N'EXEC sp_executesql N''SET @a = @b + @b'', N''@a INT OUT, @b INT'', @a OUT, @b;';
SET @ParamDef = N'@a INT OUTPUT, @b INT';

DECLARE @p INT;
DECLARE @a INT;
-- OUT param
EXEC sp_executesql @SQLString1, @ParamDef, @a = @p OUT, @b = 10;
-- Nested with OUT param name collision
EXEC sp_executesql @SQLString2, @ParamDef, @a = @a OUT, @b = 11;
SELECT @p, @a;
go

DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @a = @a + 1;';
SET @ParamDef = N'@a INT OUT';

DECLARE @p1 INT = 1;
DECLARE @p2 INT = 1;
-- Declared as INOUT and called as OUT
EXEC sp_executesql @SQLString, @ParamDef, @a = @p1 OUT;
-- Declared as INOUT and called as IN
EXEC sp_executesql @SQLString, @ParamDef, @a = @p2;
SELECT @p1, @p2;
go

/* 6. Implicit cast for IN param */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @b = @a;';
SET @ParamDef = N'@a FLOAT, @b FLOAT OUT';

DECLARE @p FLOAT;
DECLARE @a MONEY = 3.14;
EXEC sp_executesql @SQLString, @ParamDef, @a = @a, @b = @p OUTPUT;
SELECT @p;
go

/* 7. Implicit cast for OUT param */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @a = CAST(''2020-01-01'' AS DATE); SET @b = @a;';
SET @ParamDef = N'@a DATE OUT, @b DATETIME OUT';

DECLARE @p1 DATETIME;
DECLARE @p2 DATETIME;
EXEC sp_executesql @SQLString, @ParamDef, @a = @p1 OUT, @b = @p2 OUT;
SELECT @p1, @p2;
go

/* Exceptions */
/* 1. Wrong order of named/unnamed params */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c INT, @d INT';
EXEC sp_executesql @SQLString, @ParamDef, @b = 2, @c = 3, 1, @d = 4;
go

/* 2. Number mismatch of param defs and given params */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c INT, @d INT';
EXEC sp_executesql @SQLString, @ParamDef, 1, 2, 3;
go

/* 3. Invalid param name */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c INT, @d INT';
EXEC sp_executesql @SQLString, @ParamDef, @a = 1, @b = 2, @c = 3, @e = 4;
go

/* 4. Invalid param def */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c, @d INT';
EXEC sp_executesql @SQLString, @ParamDef, 1, 2, 3, 4;
go

/* 5. Unsupported implicit cast */
-- IN param
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'INSERT INTO spExecutesqlTable2 VALUES (@a, @b, @c, @d);';
SET @ParamDef = N'@a INT, @b INT, @c INT, @d INT';
EXEC sp_executesql @SQLString, @ParamDef, 1, 3.14, 'hello', 4;
go

-- OUT param
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @a = CAST(''abc'' AS VARCHAR(3));';
SET @ParamDef = N'@a FLOAT OUT';

DECLARE @p FLOAT;
EXEC sp_executesql @SQLString, @ParamDef, @a = @p OUT;
go

/* 6. Invalid OUT param */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @a = 20';
SET @ParamDef = N'@a INT OUT';
EXEC sp_executesql @SQLString, @ParamDef, @a = 10 OUT;
go

/* 7. Param declared as IN but called as OUT */
DECLARE @SQLString NVARCHAR(100);
DECLARE @ParamDef NVARCHAR(100);
SET @SQLString = N'SET @a = 20';
SET @ParamDef = N'@a INT';

DECLARE @p INT;
EXEC sp_executesql @SQLString, @ParamDef, @a = @p OUT;
go

/* Clean up */
DROP TABLE spExecutesqlTable1;
DROP TABLE spExecutesqlTable2;
go
