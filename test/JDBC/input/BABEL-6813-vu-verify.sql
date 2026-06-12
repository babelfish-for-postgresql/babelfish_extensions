-- BABEL-6813: Fix infinite CAST recursion and DATETRUNC regtype resolution

-- Verify CAST(numeric AS INT) in CHECK constraints worked
SELECT * FROM babel_6813_t1
GO

SELECT * FROM babel_6813_t2
GO

SELECT * FROM babel_6813_t3
GO

-- DATETRUNC tests with various datetime types
SELECT DATETRUNC(year, CAST('2023-06-15 10:30:00' AS datetime))
GO

SELECT DATETRUNC(month, CAST('2023-06-15 10:30:00' AS smalldatetime))
GO

SELECT DATETRUNC(day, CAST('2023-06-15 10:30:00.1234567' AS datetime2))
GO

SELECT DATETRUNC(hour, CAST('2023-06-15 10:30:00.1234567 +05:30' AS datetimeoffset))
GO

SELECT * FROM babel_6813_datetrunc
GO

SELECT * FROM babel_6813_date
GO

SELECT * FROM babel_6813_datetime
GO

SELECT * FROM babel_6813_time
GO

SELECT * FROM babel_6813_money
GO

SELECT * from babel_6813_float
GO
