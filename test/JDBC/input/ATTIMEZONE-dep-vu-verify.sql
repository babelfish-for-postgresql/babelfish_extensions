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

select set_config('timezone', 'UTC', false);
GO
