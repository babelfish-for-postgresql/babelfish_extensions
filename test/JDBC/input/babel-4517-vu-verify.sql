SET BABELFISH_SHOWPLAN_ALL on
GO

select * from view_4517_date;
GO

select * from view_4517_datetime
GO

select * from view_4517_datetime2
GO

select * from babel_4517 where date_col <= cast('2023-08-31' as date) and date_col >= cast('2023-08-31' as date);
GO

select * from babel_4517 where datetime_col <= cast('2023-08-31' as date) and datetime_col >= cast('2023-08-31' as date);
GO

select * from babel_4517 where datetime2_col <= cast('2023-08-31' as date) and datetime2_col >= cast('2023-08-31' as date);
GO

SET BABELFISH_SHOWPLAN_ALL off
GO
