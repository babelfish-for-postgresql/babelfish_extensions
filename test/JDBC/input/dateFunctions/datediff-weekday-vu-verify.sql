-- 0
exec datediff_weekday_p1
GO

-- 1
exec datediff_weekday_p2
GO

-- -10
exec datediff_weekday_p3
GO

-- 365
exec datediff_dw_p1
GO

-- 10957
exec datediff_big_weekday_p1
GO

-- -10957
exec datediff_big_dw_p1
GO

-- DATE_BUCKET does not support weekday datepart (should error)
SELECT DATE_BUCKET(weekday, 1, cast('2020-01-01' as datetime))
GO

SELECT DATE_BUCKET(dw, 1, cast('2020-01-01' as datetime))
GO
