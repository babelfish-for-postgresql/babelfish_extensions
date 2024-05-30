-- output from SQL Server :
-- 1900-01-02 00:00:00.000	1900-01-04 00:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 00:00:00.000	1900-01-03 12:00:00.000	1900-01-03 12:00:00.000	1900-01-02 00:00:00.000	1899-12-29 00:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	1899-12-30 00:00:00.000	1899-12-30 00:00:00.000	1899-12-30 00:00:00.000	1899-12-29 12:00:00.000	1899-12-29 12:00:00.000	null
SELECT * FROM Datetime_view3
GO
DROP VIEW Datetime_view3
GO

-- output from SQL Server :
-- 1900-01-02 00:00	1900-01-04 00:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 00:00	1900-01-03 12:00	1900-01-03 12:00	1900-01-02 00:00	null
SELECT * FROM Datetime_view4
GO
DROP VIEW Datetime_view4
GO

-- output from SQL Server :
-- 1900-01-04 00:01:00.000	1900-01-03 12:01:00.000	1900-01-03 12:01:00.000	1900-01-03 12:01:00.000	1900-01-03 00:01:00.000	1900-01-03 00:01:00.000	1900-01-03 00:01:00.000	1900-01-03 00:01:00.000	1900-01-03 12:01:00.000	1900-01-03 12:01:00.000	1899-12-28 23:59:00.000	1899-12-29 11:59:00.000	1899-12-29 11:59:00.000	1899-12-29 11:59:00.000	1899-12-29 23:59:00.000	1899-12-29 23:59:00.000	1899-12-29 23:59:00.000	1899-12-29 11:59:00.000	1899-12-29 11:59:00.000
SELECT * FROM Datetime_view5
GO
DROP VIEW Datetime_view5
GO

-- output from SQL Server :
-- 4	3	3	3	3	3	3	3	3	3	2	29	29	29	29	30	30	30	29	29	2
SELECT * FROM Datetime_view7
GO
DROP VIEW Datetime_view7
GO

-- output from SQL Server :
-- 4	3	3	3	3	3	3	3	3	3	2	29	29	29	29	30	30	30	29	29	2
SELECT * FROM Datetime_view8
GO
DROP VIEW Datetime_view8
GO

-- Procedures
EXEC Datetime_proc1 '1900-01-02 00:00:00', 3.1
GO
EXEC Datetime_proc1 '1900-01-02 00:00:00', 2
GO
EXEC Datetime_proc1 '1900-01-01 00:00:00', 0
GO
EXEC Datetime_proc1 '1900-01-02 00:00:00', -3.1
GO
DROP PROCEDURE Datetime_proc1
GO

EXEC SMALLDatetime_proc1 '1900-01-02 00:00:00', 3.1
GO
EXEC SMALLDatetime_proc1 '1900-01-02 00:00:00', 2
GO
EXEC SMALLDatetime_proc1 '1900-01-01 00:00:00', 0
GO
EXEC SMALLDatetime_proc1 '1900-01-02 00:00:00', -3.1
GO
DROP PROCEDURE SMALLDatetime_proc1
GO

SELECT * FROM dateadd_numeric_representation_helper_year_view
GO

DROP VIEW dateadd_numeric_representation_helper_year_view
GO

SELECT * FROM dateadd_numeric_representation_helper_quarter_view
GO

DROP VIEW dateadd_numeric_representation_helper_quarter_view
GO

SELECT * FROM dateadd_numeric_representation_helper_month_view
GO

DROP VIEW dateadd_numeric_representation_helper_month_view
GO

SELECT * FROM dateadd_numeric_representation_helper_dayofyear_view
GO

DROP VIEW dateadd_numeric_representation_helper_dayofyear_view
GO

SELECT * FROM dateadd_numeric_representation_helper_day_view
GO

DROP VIEW dateadd_numeric_representation_helper_day_view
GO

SELECT * FROM dateadd_numeric_representation_helper_week_view
GO

DROP VIEW dateadd_numeric_representation_helper_week_view
GO

SELECT * FROM dateadd_numeric_representation_helper_weekday_view
GO

DROP VIEW dateadd_numeric_representation_helper_weekday_view
GO

SELECT * FROM dateadd_numeric_representation_helper_hour_view
GO

DROP VIEW dateadd_numeric_representation_helper_hour_view
GO

SELECT * FROM dateadd_numeric_representation_helper_minute_view
GO

DROP VIEW dateadd_numeric_representation_helper_minute_view
GO

SELECT * FROM dateadd_numeric_representation_helper_second_view
GO

DROP VIEW dateadd_numeric_representation_helper_second_view
GO

SELECT * FROM dateadd_numeric_representation_helper_millisecond_view
GO

DROP VIEW dateadd_numeric_representation_helper_millisecond_view
GO

SELECT * FROM dateadd_view_1
GO

DROP VIEW dateadd_view_1
GO

SELECT * FROM dateadd_view_2
GO

DROP VIEW dateadd_view_2
GO

SELECT * FROM dateadd_view_3
GO

DROP VIEW dateadd_view_3
GO

SELECT * FROM dateadd_view_4
GO

DROP VIEW dateadd_view_4
GO

SELECT * FROM dateadd_view_5
GO

DROP VIEW dateadd_view_5
GO

SELECT * FROM dateadd_view_6
GO

DROP VIEW dateadd_view_6
GO
