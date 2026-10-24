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

-- So is a statement in a loop
DECLARE @i INT = 0, @f VARCHAR(3);
WHILE @i < 3
BEGIN
	SET @f = CASE @i WHEN 0 THEN 'mdy' WHEN 1 THEN 'dmy' ELSE 'ymd' END;
	SET DATEFORMAT @f;
	SELECT @f AS dateformat, CAST('01/02/03' AS DATE) AS cast_date, CONVERT(DATE, '01/02/03') AS convert_date;
	SET @i += 1;
END
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
