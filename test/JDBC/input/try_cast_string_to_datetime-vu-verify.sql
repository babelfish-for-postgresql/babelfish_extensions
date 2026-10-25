SET DATEFORMAT mdy;
GO

CREATE VIEW try_cast_string_to_datetime_v AS
SELECT id,
    TRY_CAST(v AS date) AS date_value,
    TRY_CAST(v AS time) AS time_value,
    TRY_CAST(v AS datetime) AS datetime_value,
    TRY_CAST(v AS datetime2) AS datetime2_value,
    TRY_CAST(v AS smalldatetime) AS smalldatetime_value,
    TRY_CAST(v AS datetimeoffset) AS datetimeoffset_value
FROM try_cast_string_to_datetime_t;
GO

SELECT id, date_value, time_value, datetime_value, datetime2_value, smalldatetime_value, datetimeoffset_value
FROM try_cast_string_to_datetime_v ORDER BY id;
GO

-- nvarchar columns use the same conversion as CAST.
SELECT id,
       TRY_CAST(nv AS date),
       TRY_CAST(nv AS time),
       TRY_CAST(nv AS datetime),
       TRY_CAST(nv AS datetime2),
       TRY_CAST(nv AS smalldatetime),
       TRY_CAST(nv AS datetimeoffset)
FROM try_cast_string_to_datetime_t ORDER BY id;
GO

-- char columns use the same conversion as CAST.
SELECT id,
       TRY_CAST(c AS date),
       TRY_CAST(c AS time),
       TRY_CAST(c AS datetime),
       TRY_CAST(c AS datetime2),
       TRY_CAST(c AS smalldatetime),
       TRY_CAST(c AS datetimeoffset)
FROM try_cast_string_to_datetime_t WHERE id NOT IN (1, 2) ORDER BY id;
GO

-- nchar columns use the same conversion as CAST.
SELECT id,
       TRY_CAST(nc AS date),
       TRY_CAST(nc AS time),
       TRY_CAST(nc AS datetime),
       TRY_CAST(nc AS datetime2),
       TRY_CAST(nc AS smalldatetime),
       TRY_CAST(nc AS datetimeoffset)
FROM try_cast_string_to_datetime_t WHERE id NOT IN (1, 2) ORDER BY id;
GO

EXEC try_cast_string_to_datetime_p;
GO

-- String literals include empty strings and invalid syntax.
SELECT TRY_CAST('' AS date),
       TRY_CAST('' AS time),
       TRY_CAST('' AS datetime),
       TRY_CAST('' AS datetime2),
       TRY_CAST('' AS smalldatetime),
       TRY_CAST('' AS datetimeoffset);
GO
SELECT TRY_CAST(N'not-a-date' AS date),
       TRY_CAST(N'not-a-date' AS time),
       TRY_CAST(N'not-a-date' AS datetime),
       TRY_CAST(N'not-a-date' AS datetime2),
       TRY_CAST(N'not-a-date' AS smalldatetime),
       TRY_CAST(N'not-a-date' AS datetimeoffset);
GO

-- Precision coercions run inside the soft-error path.
DECLARE @s varchar(60) = '2026-01-02 12:34:56.123456';
SELECT
    CASE WHEN TRY_CAST(@s AS time(0)) = CAST(@s AS time(0)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(1)) = CAST(@s AS time(1)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(2)) = CAST(@s AS time(2)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(3)) = CAST(@s AS time(3)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(4)) = CAST(@s AS time(4)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(5)) = CAST(@s AS time(5)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(6)) = CAST(@s AS time(6)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS time(7)) = CAST(@s AS time(7)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(0)) = CAST(@s AS datetime2(0)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(1)) = CAST(@s AS datetime2(1)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(2)) = CAST(@s AS datetime2(2)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(3)) = CAST(@s AS datetime2(3)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(4)) = CAST(@s AS datetime2(4)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(5)) = CAST(@s AS datetime2(5)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(6)) = CAST(@s AS datetime2(6)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetime2(7)) = CAST(@s AS datetime2(7)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(0)) = CAST(@s AS datetimeoffset(0)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(1)) = CAST(@s AS datetimeoffset(1)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(2)) = CAST(@s AS datetimeoffset(2)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(3)) = CAST(@s AS datetimeoffset(3)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(4)) = CAST(@s AS datetimeoffset(4)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(5)) = CAST(@s AS datetimeoffset(5)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(6)) = CAST(@s AS datetimeoffset(6)) THEN 1 ELSE 0 END,
    CASE WHEN TRY_CAST(@s AS datetimeoffset(7)) = CAST(@s AS datetimeoffset(7)) THEN 1 ELSE 0 END;
GO

-- Invalid punctuation, long inputs and overflow must not abort the statement.
DECLARE @s varchar(1000) = REPLICATE('x', 200);
SELECT TRY_CAST(@s AS date),
       TRY_CAST(@s AS time),
       TRY_CAST(@s AS datetime),
       TRY_CAST(@s AS datetime2),
       TRY_CAST(@s AS smalldatetime),
       TRY_CAST(@s AS datetimeoffset);
SELECT 1 AS continued;
GO

DECLARE @s varchar(60) = '2026-01-02 12:34:56 +05:30';
SELECT TRY_CAST(@s AS datetimeoffset(3));
SELECT TRY_CAST('0001-01-01 00:00:00 +14:00' AS datetimeoffset),
       TRY_CAST('9999-12-31 23:59:59 -14:00' AS datetimeoffset);
GO

-- TRY_CAST agrees with CAST under session settings.
SET DATEFORMAT dmy;
GO
DECLARE @s varchar(30) = '12/11/2026 12:34:56';
SELECT CASE WHEN TRY_CAST(@s AS date) = CAST(@s AS date) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@s AS time) = CAST(@s AS time) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@s AS datetime) = CAST(@s AS datetime) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@s AS datetime2) = CAST(@s AS datetime2) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@s AS smalldatetime) = CAST(@s AS smalldatetime) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@s AS datetimeoffset) = CAST(@s AS datetimeoffset) THEN 1 ELSE 0 END;
GO
SET DATEFORMAT mdy;
GO

-- Allowed non-string conversions continue to use the existing helpers.
DECLARE @i int = 1;
SELECT CASE WHEN TRY_CAST(@i AS datetime) = CAST(@i AS datetime) THEN 1 ELSE 0 END,
       CASE WHEN TRY_CAST(@i AS smalldatetime) = CAST(@i AS smalldatetime) THEN 1 ELSE 0 END,
       TRY_CAST('123' AS int), TRY_CAST('invalid' AS int);
GO
