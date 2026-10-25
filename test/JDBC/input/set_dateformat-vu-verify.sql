-- The session's date order decides how CAST and CONVERT without a style read
-- date strings
SET DATEFORMAT dmy
GO

SELECT * FROM set_dateformat_v ORDER BY id
GO

SET DATEFORMAT mdy
GO

SELECT * FROM set_dateformat_v ORDER BY id
GO

SET DATEFORMAT ymd
GO

SELECT CAST('2026/01/02' AS DATE), CONVERT(DATETIME, '2026-01-02'), CAST('26/01/02' AS DATE)
GO

-- Under ymd, CONVERT without a style reads a year at the end of the string as
-- month, day, year, for every type and separator
SELECT CONVERT(DATE, '01/02/2026'), CONVERT(DATETIME2, '01/02/2026'), CONVERT(DATETIMEOFFSET, '01/02/2026'),
	CONVERT(TIME, '01/02/2026'), CONVERT(DATETIME, '01/02/2026'), CONVERT(SMALLDATETIME, '01/02/2026')
GO

SELECT CONVERT(DATE, '01-02-2026'), CONVERT(DATETIME2, '01.02.2026'), CONVERT(DATETIMEOFFSET, '01-02-2026'),
	CONVERT(TIME, '01.02.2026'), CONVERT(DATETIME, '01-02-2026'), CONVERT(SMALLDATETIME, '01.02.2026')
GO

SELECT CONVERT(DATE, '01/02/2026 10:30:15'), CONVERT(DATETIME2, '01/02/2026 10:30:15'),
	CONVERT(DATETIMEOFFSET, '01/02/2026 10:30:15 +01:00'), CONVERT(TIME, '01/02/2026 10:30:15'),
	CONVERT(DATETIME, '01/02/2026 10:30:15'), CONVERT(SMALLDATETIME, '01/02/2026 10:30:15')
GO

SELECT CONVERT(DATE, '12/31/2026'), CONVERT(DATETIME2, '12-31-2026'), CONVERT(DATETIMEOFFSET, '12.31.2026')
GO

DECLARE @s VARCHAR(30) = '03/04/2026'
SELECT CONVERT(DATE, @s), CONVERT(DATETIME2, @s), CONVERT(DATETIMEOFFSET, @s), CONVERT(TIME, @s)
GO

-- A year at the start of the string, or a style, is not affected
SELECT CONVERT(DATE, '2026/01/02'), CONVERT(DATETIME2, '26/01/02'), CONVERT(DATE, '01/02/2026', 103),
	CONVERT(DATETIME2, '01.02.2026', 104)
GO

-- Known difference: SQL Server reads the string of a CAST as month, day, year
-- too, but Babelfish raises error 33557097
SELECT CAST('01/02/2026' AS DATE)
GO

SELECT CAST('01/02/2026' AS DATETIME)
GO

-- Every date and time type follows it
SET DATEFORMAT dmy
GO

SELECT CAST('01/02/2026' AS DATE), CAST('01/02/2026' AS DATETIME), CAST('01/02/2026' AS DATETIME2),
	CAST('01/02/2026' AS SMALLDATETIME), CAST('01/02/2026 10:00 +01:00' AS DATETIMEOFFSET)
GO

-- So do implicit conversions and functions taking a date string
SELECT DATEPART(month, '01/02/2026'), ISDATE('13/02/2026'), ISDATE('02/13/2026')
GO

DECLARE @d DATE = '13/02/2026'
SELECT @d
GO

-- Unseparated dates are always ymd
SELECT CAST('20260102' AS DATE)
GO

-- Objects created before the SET follow it too
SELECT dbo.set_dateformat_f('01/02/2026')
GO

EXEC set_dateformat_p '01/02/2026'
GO

SET DATEFORMAT mdy
GO

-- The value can be upper case, quoted or a variable
SET DATEFORMAT DMY
GO

SELECT CAST('01/02/2026' AS DATE)
GO

SET DATEFORMAT 'ymd'
GO

SELECT CAST('2026/01/02' AS DATE)
GO

DECLARE @f VARCHAR(10) = 'dmy'
SET DATEFORMAT @f
SELECT CAST('01/02/2026' AS DATE)
GO

SET DATEFORMAT mdy
GO

-- A SET inside a procedure or EXEC() is reverted when it returns
EXEC set_dateformat_p_dmy '01/02/2026'
SELECT CAST('01/02/2026' AS DATE) AS after_proc
GO

EXEC('SET DATEFORMAT dmy; SELECT CAST(''01/02/2026'' AS DATE) AS inside_exec')
SELECT CAST('01/02/2026' AS DATE) AS after_exec
GO

EXEC sp_executesql N'SELECT CAST(@s AS DATE) AS sp_executesql_dmy', N'@s VARCHAR(30)', '01/02/2026'
GO

-- It is not undone by ROLLBACK
BEGIN TRAN
SET DATEFORMAT dmy
ROLLBACK
SELECT CAST('01/02/2026' AS DATE) AS after_rollback
GO

SET DATEFORMAT mdy
GO

-- A cached plan is parsed again when the date order changes
EXEC set_dateformat_p_literal
GO

SET DATEFORMAT dmy
GO

EXEC set_dateformat_p_literal
GO

-- So is a statement in a loop, including when the order goes back to one it
-- had before
DECLARE @i INT = 0, @f VARCHAR(3);
WHILE @i < 5
BEGIN
	SET @f = CASE @i WHEN 0 THEN 'mdy' WHEN 1 THEN 'dmy' WHEN 2 THEN 'ymd' WHEN 3 THEN 'dmy' ELSE 'mdy' END;
	SET DATEFORMAT @f;
	SELECT @f AS dateformat, CAST('01/02/03' AS DATE) AS cast_date, CONVERT(DATE, '01/02/03') AS convert_date;
	SET @i += 1;
END
GO

-- A literal that is not valid in the new order raises its error each time the
-- procedure runs with that order, and the procedure works again with an order
-- it is valid in
SET DATEFORMAT dmy
EXEC set_dateformat_p_reparse
GO

SET DATEFORMAT mdy
EXEC set_dateformat_p_reparse
GO

SET DATEFORMAT ymd
EXEC set_dateformat_p_reparse
GO

SET DATEFORMAT mdy
EXEC set_dateformat_p_reparse
GO

EXEC set_dateformat_p_reparse
GO

SET DATEFORMAT dmy
EXEC set_dateformat_p_reparse
GO

SET DATEFORMAT mdy
GO

-- A procedure that is parsed again for another reason, such as ALTER TABLE,
-- is parsed with the date order at that time
EXEC set_dateformat_p_ddl
GO

SET DATEFORMAT dmy
GO

ALTER TABLE set_dateformat_t_ddl ADD b INT
GO

EXEC set_dateformat_p_ddl
GO

SET DATEFORMAT mdy
EXEC set_dateformat_p_ddl
GO

SET DATEFORMAT ymd
GO

ALTER TABLE set_dateformat_t_ddl DROP COLUMN b
GO

EXEC set_dateformat_p_ddl
GO

SET DATEFORMAT dmy
EXEC set_dateformat_p_ddl
GO

SET DATEFORMAT mdy
EXEC set_dateformat_p_ddl
GO

-- The order set inside a procedure does not reach the statements around the
-- call, whether they were parsed before or after it
DECLARE @i INT = 0
WHILE @i < 3
BEGIN
	SELECT 'before' AS who, CAST('01/02/2026' AS DATE) AS cast_date, CONVERT(DATETIME, '01/02/2026') AS convert_datetime
	EXEC set_dateformat_p_scope
	SELECT 'after' AS who, CAST('01/02/2026' AS DATE) AS cast_date, CONVERT(DATETIME, '01/02/2026') AS convert_datetime
	SET @i += 1
END
GO

SET DATEFORMAT ymd
GO

SELECT 'before' AS who, CAST('2026/01/02' AS DATE) AS cast_date, CONVERT(DATE, '01/02/03') AS convert_date
EXEC set_dateformat_p_scope
SELECT 'after' AS who, CAST('2026/01/02' AS DATE) AS cast_date, CONVERT(DATE, '01/02/03') AS convert_date
GO

SET DATEFORMAT mdy
GO

-- Invalid values raise error 2741, which ends only the statement
SET DATEFORMAT abc
GO

SET DATEFORMAT 'xyz'
GO

DECLARE @f VARCHAR(10) = 'Nope'
SET DATEFORMAT @f
SELECT CAST('01/02/2026' AS DATE) AS after_error
GO

BEGIN TRY
	SET DATEFORMAT dmyx
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER(), ERROR_MESSAGE()
END CATCH
GO

-- So does a NULL variable, caught or not, and the date order stays as it was
SET DATEFORMAT dmy
GO

DECLARE @f VARCHAR(10) = NULL
BEGIN TRY
	SET DATEFORMAT @f
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER(), ERROR_MESSAGE()
END CATCH
SELECT CAST('01/02/2026' AS DATE) AS after_caught
GO

DECLARE @f VARCHAR(10) = NULL
SET DATEFORMAT @f
SELECT 'same batch' AS batch, CAST('01/02/2026' AS DATE) AS after_uncaught
GO

SELECT 'next batch' AS batch, CAST('01/02/2026' AS DATE) AS after_uncaught
GO

SET DATEFORMAT mdy
GO

-- ydm, myd and dym are accepted while escape_hatch_session_settings is
-- ignore.  CONVERT without a style reads all six orders.
SET DATEFORMAT ydm
GO

SELECT CONVERT(DATETIME, '2-3-4'), CONVERT(DATETIME, '2026/13/02')
GO

-- The date, time, datetime2 and datetimeoffset types do not allow ydm
SELECT CONVERT(DATE, '2-3-4')
GO

BEGIN TRY
	SELECT CONVERT(DATETIME2, '2-3-4')
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER()
END CATCH
GO

SET DATEFORMAT myd
GO

SELECT CONVERT(DATETIME, '2-3-4'), CONVERT(DATE, '2-3-4')
GO

SET DATEFORMAT dym
GO

SELECT CONVERT(DATETIME, '2-3-4'), CONVERT(DATE, '2-3-4')
GO

SET DATEFORMAT mdy
GO

-- With the escape hatch set to strict they raise an error instead, and the
-- date order stays as it was
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict'
GO

SET DATEFORMAT ydm
GO

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore'
GO

SELECT CAST('01/02/2026' AS DATE)
GO
