SELECT * FROM ATTIMEZONE_dep_vu_prepare_v1
GO

SELECT * FROM ATTIMEZONE_dep_vu_prepare_v2
GO

EXEC ATTIMEZONE_dep_vu_prepare_p1
GO

EXEC ATTIMEZONE_dep_vu_prepare_p2
GO

SELECT ATTIMEZONE_dep_vu_prepare_f1()
GO

SELECT ATTIMEZONE_dep_vu_prepare_f2()
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eastern standard time';
GO

Select convert(datetime2,'9999-12-31 15:59:59.000 +00:00') AT TIME ZONE 'Central Europe Standard Time';
GO

Select convert(datetimeoffset,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eastern standard time';
GO

Select convert(datetimeoffset,'9999-12-31 15:59:59.000 +00:00') AT TIME ZONE 'Central Europe Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T02:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T02:00:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

-- PG handles overlap ambiguity by prefering standard time over DST.
SELECT CONVERT(DATETIME2(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:00:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

select set_config('timezone', 'Asia/Kolkata', false);
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eastern standard time';
GO

Select convert(datetime2,'9999-12-31 15:59:59.000 +00:00') AT TIME ZONE 'Central Europe Standard Time';
GO

Select convert(datetimeoffset,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eastern standard time';
GO

Select convert(datetimeoffset,'9999-12-31 15:59:59.000 +00:00') AT TIME ZONE 'Central Europe Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T02:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T02:00:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

-- PG handles overlap ambiguity by prefering standard time over DST.
SELECT CONVERT(DATETIME2(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:00:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

select set_config('timezone', 'America/Los_Angeles', false);
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetimeoffset(0), '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T02:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-03-27T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T00:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T01:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T03:01:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 00:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 01:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 03:01:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T02:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-03-10T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T02:00:00', 126) AT TIME ZONE 'pacific standard time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T03:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

-- PG handles overlap ambiguity by prefering standard time over DST.
SELECT CONVERT(DATETIME2(0), '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(smalldatetime, '2022-10-30T02:00:00', 126) AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(datetime, '2022-10-30 02:00:00') AT TIME ZONE 'Central European Standard Time';
GO

SELECT CONVERT(DATETIME2(0), '2024-11-03T01:01:00', 126) AT TIME ZONE 'pacific standard time';
GO

select set_config('timezone', 'UTC', false);
GO
