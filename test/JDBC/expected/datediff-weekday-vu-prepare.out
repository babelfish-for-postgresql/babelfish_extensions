-- Test DATEDIFF with weekday datepart (GitHub issue #2117)
-- In SQL Server, DATEDIFF(weekday, ...) counts day boundaries (same as day)

-- 0 (same day)
CREATE PROCEDURE datediff_weekday_p1 as (select datediff(weekday, cast('2020-01-01' as datetime), cast('2020-01-01' as datetime)));
GO

-- 1 (next day)
CREATE PROCEDURE datediff_weekday_p2 as (select datediff(weekday, cast('2020-01-01' as datetime), cast('2020-01-02' as datetime)));
GO

-- -10 (10 days back)
CREATE PROCEDURE datediff_weekday_p3 as (select datediff(weekday, cast('2020-01-11' as datetime), cast('2020-01-01' as datetime)));
GO

-- Test with dw abbreviation
-- 365
CREATE PROCEDURE datediff_dw_p1 as (select datediff(dw, cast('2020-01-01' as datetime), cast('2020-12-31' as datetime)));
GO

-- Test datediff_big with weekday
-- 10957 (30 years in days)
CREATE PROCEDURE datediff_big_weekday_p1 as (select datediff_big(weekday, cast('1990-01-01' as datetime), cast('2020-01-01' as datetime)));
GO

-- Test datediff_big with dw
-- -10957
CREATE PROCEDURE datediff_big_dw_p1 as (select datediff_big(dw, cast('2020-01-01' as datetime), cast('1990-01-01' as datetime)));
GO
