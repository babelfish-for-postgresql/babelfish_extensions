Select todatetimeoffset('0000-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('9999-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('-1-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-0a-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('20sb-04-22 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-2c 16:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 1d:23:51.766890','+12:00')
GO

Select todatetimeoffset('2000-0a-22 16:2a:51.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 16:23:5d.766890','+12:00')
GO

Select todatetimeoffset('2000-04-22 16:23:51.7668c0','+12:00')
GO

Select todatetimeoffset('2000-05-22 16:23:51.766890','+1d:00')
GO

Select todatetimeoffset('2000-04-22 16:23:51.766890','+12:0e')
GO

Select todatetimeoffset('1-04-22 16:23:51.766890','+12:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45.3682170' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08' as datetime2), '-13:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '-15:00')
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), '+23:00')
GO

Select todatetimeoffset('2000-04-22 1d:23:51.766890',120)
GO

Select todatetimeoffset('2000-04-22 16:2a:51.766890',340)
GO

Select todatetimeoffset('2000-04-22 16:23:5d.766890',841)
GO

Select todatetimeoffset('2000-04-22 16:23:51.7668c0',-342)
GO

Select todatetimeoffset('2000-05-22 16:23:51.766890',234)
GO

Select todatetimeoffset('2000-04-22 16:23:51.766890',345)
GO

Select todatetimeoffset('1-04-22 16:23:51.766890',-4556)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45.3682170' as datetime2), -345)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08 16:06:45' as datetime2), -234)
GO

SELECT TODATETIMEOFFSET(cast('2023-08-08' as datetime2), 4556)
GO
