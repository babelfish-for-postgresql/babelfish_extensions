SELECT DATEPART(dd, '07-18-2022')
GO

SELECT DATEPART(wk, '18 July 2022')
GO

SELECT DATEPART(yy, '07-18-2022')
GO

SELECT * FROM date_part_vu_prepare_view
GO

SELECT * FROM date_part_vu_prepare_func('07-18-2022')
GO

SELECT * FROM date_part_vu_prepare_func('18 July 2022')
GO

SELECT * FROM date_part_vu_prepare_func('7/18/2022')
GO

SELECT ISOWeek_3101(CAST('25 July 2022 01:23:45' AS datetime))
GO

-- should error out as expected
SELECT ISOWeek_3101('01-01-1790')
GO

EXECUTE date_part_vu_prepare_proc '07-18-2022'
GO

EXECUTE date_part_vu_prepare_proc '18 July 2022'
GO

EXECUTE date_part_vu_prepare_proc '7/18/2022'
GO

SELECT * FROM date_part_vu_prepare_sys_day_view
GO

SELECT * FROM date_part_vu_prepare_sys_day_func(CAST('07-18-2022' AS datetime))
GO

DECLARE @a datetime
SET @a = CAST('07-18-2022' AS datetime)
EXECUTE date_part_vu_prepare_proc @a
GO
