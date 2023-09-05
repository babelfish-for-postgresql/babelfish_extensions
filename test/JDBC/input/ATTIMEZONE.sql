Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE NULL
Go

Select NULL AT TIME ZONE 'Eastern Standard Time'
Go

Select convert(datetime,'2022-10-29 20:01:00.000') AT TIME ZONE NULL
GO

Select NULL AT TIME ZONE NULL
Go

Select NULL AT TIME ZONE 'NULL'
GO

Select 'NULL' AT TIME ZONE NULL
GO

Select 'NULL' AT TIME ZONE 'NULL'
GO

Select convert(datetime,'2022-10-29 20:01:00.000') AT TIME ZONE 'Eastern Standard Time' AT TIME ZONE 'Central Standard Time'
Go

Select '2022-10-29 20:01:00.000' AT TIME ZONE convert(datetime,'2022-10-29 20:01:00.000')
Go

Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE 23
Go

Select convert(datetimeoffset,'2022-10-29 20:01:00.000') AT TIME ZONE convert(int,23)
Go

Select '2022-10-29 20:01:00.000' AT TIME ZONE 'Eastern Standard Time'
Go

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'eAstern stAnDard tIMe'
GO

Select convert(datetimeoffset,'2022-10-29 20:01:00.0000000 -05:00') AT TIME ZONE 'Eastern  Standard  Time'
GO

Select convert(datetimeoffset,'2022-10-29 20:01:00.0000000 -05:00') AT TIME ZONE 'Eastern Standard Time '
GO

Select convert(datetime2,'2002-01-01 02:01:00.000 +00:00') AT TIME ZONE 'dgycgwycgqd'
GO

