-- DATEPART with 'day' and different data types

GO
SELECT DATEPART(day, CAST(100987 AS bit));
GO

SELECT DATEPART(day, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(day, CAST(6542 AS int));
GO

SELECT DATEPART(day, CAST(1111 AS smallint));
GO

SELECT DATEPART(day, CAST(999999 AS bigint));
GO

SELECT DATEPART(day, CAST(42 AS tinyint));
GO

SELECT DATEPART(day, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(day, CAST(987654.321 AS real));
GO

SELECT DATEPART(day, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(day, CAST(3.14159 AS float));
GO

-- DATEPART with 'month' and different data types

GO
SELECT DATEPART(month, CAST(100987 AS bit));
GO

SELECT DATEPART(month, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(month, CAST(6542 AS int));
GO

SELECT DATEPART(month, CAST(1111 AS smallint));
GO

SELECT DATEPART(month, CAST(999999 AS bigint));
GO

SELECT DATEPART(month, CAST(42 AS tinyint));
GO

SELECT DATEPART(month, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(month, CAST(987654.321 AS real));
GO

SELECT DATEPART(month, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(month, CAST(3.14159 AS float));
GO

-- DATEPART with 'week' and different data types
SELECT DATEPART(week, CAST(100987 AS bit));
GO

SELECT DATEPART(week, CAST(14 AS smallmoney));   
GO

SELECT DATEPART(week, CAST(6542 AS int));
GO

SELECT DATEPART(week, CAST(1111 AS smallint));
GO

SELECT DATEPART(week, CAST(999999 AS bigint));
GO

SELECT DATEPART(week, CAST(42 AS tinyint));
GO

SELECT DATEPART(week, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(week, CAST(987654.321 AS real));
GO

SELECT DATEPART(week, CAST(14 AS numeric));   
GO

SELECT DATEPART(week, CAST(3.14159 AS float));
GO

-- DATEPART with 'year' and different data types

GO
SELECT DATEPART(year, CAST(100987 AS bit));
GO

SELECT DATEPART(year, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(year, CAST(6542 AS int));
GO

SELECT DATEPART(year, CAST(1111 AS smallint));
GO

SELECT DATEPART(year, CAST(999999 AS bigint));
GO

SELECT DATEPART(year, CAST(42 AS tinyint));
GO

SELECT DATEPART(year, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(year, CAST(987654.321 AS real));
GO

SELECT DATEPART(year, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(year, CAST(3.14159 AS float));
GO

-- DATEPART with 'weekday' and different data types

GO
SELECT DATEPART(weekday, CAST(100987 AS bit)); 
GO

SELECT DATEPART(weekday, CAST(1234 AS smallmoney));    
GO

SELECT DATEPART(weekday, CAST(6542 AS int));    
GO

SELECT DATEPART(weekday, CAST(1111 AS smallint));    
GO

SELECT DATEPART(weekday, CAST(999999 AS bigint));    
GO

SELECT DATEPART(weekday, CAST(42 AS tinyint));    
GO

SELECT DATEPART(weekday, CAST(1234.789 AS decimal));    
GO

SELECT DATEPART(weekday, CAST(987654.321 AS real));    
GO

SELECT DATEPART(weekday, CAST(314159.432 AS numeric));    
GO

SELECT DATEPART(weekday, CAST(3.14159 AS float));    
GO

-- DATEPART with 'yy' (year without century) and different data types

GO
SELECT DATEPART(yy, CAST(100987 AS bit));
GO

SELECT DATEPART(yy, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(yy, CAST(6542 AS int));
GO

SELECT DATEPART(yy, CAST(1111 AS smallint));
GO

SELECT DATEPART(yy, CAST(999999 AS bigint));
GO

SELECT DATEPART(yy, CAST(42 AS tinyint));
GO

SELECT DATEPART(yy, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(yy, CAST(987654.321 AS real));
GO

SELECT DATEPART(yy, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(yy, CAST(3.14159 AS float));
GO

-- DATEPART with 'yyyy' (year with century) and different data types

GO
SELECT DATEPART(yyyy, CAST(100987 AS bit));
GO

SELECT DATEPART(yyyy, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(yyyy, CAST(6542 AS int));
GO

SELECT DATEPART(yyyy, CAST(1111 AS smallint));
GO

SELECT DATEPART(yyyy, CAST(999999 AS bigint));
GO

SELECT DATEPART(yyyy, CAST(42 AS tinyint));
GO

SELECT DATEPART(yyyy, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(yyyy, CAST(987654.321 AS real));
GO

SELECT DATEPART(yyyy, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(yyyy, CAST(3.14159 AS float));
GO

-- DATEPART with 'qq' (quarter) and different data types

GO
SELECT DATEPART(qq, CAST(100987 AS bit));
GO

SELECT DATEPART(qq, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(qq, CAST(6542 AS int));
GO

SELECT DATEPART(qq, CAST(1111 AS smallint));
GO

SELECT DATEPART(qq, CAST(999999 AS bigint));
GO

SELECT DATEPART(qq, CAST(42 AS tinyint));
GO

SELECT DATEPART(qq, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(qq, CAST(987654.321 AS real));
GO

SELECT DATEPART(qq, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(qq, CAST(3.14159 AS float));
GO

-- DATEPART with 'q' (quarter) and different data types

GO
SELECT DATEPART(q, CAST(100987 AS bit));
GO

SELECT DATEPART(q, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(q, CAST(6542 AS int));
GO

SELECT DATEPART(q, CAST(1111 AS smallint));
GO

SELECT DATEPART(q, CAST(999999 AS bigint));
GO

SELECT DATEPART(q, CAST(42 AS tinyint));
GO

SELECT DATEPART(q, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(q, CAST(987654.321 AS real));
GO

SELECT DATEPART(q, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(q, CAST(3.14159 AS float));
GO

-- DATEPART with 'mm' (month) and different data types

GO
SELECT DATEPART(mm, CAST(100987 AS bit));
GO

SELECT DATEPART(mm, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(mm, CAST(6542 AS int));
GO

SELECT DATEPART(mm, CAST(1111 AS smallint));
GO

SELECT DATEPART(mm, CAST(999999 AS bigint));
GO

SELECT DATEPART(mm, CAST(42 AS tinyint));
GO

SELECT DATEPART(mm, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(mm, CAST(987654.321 AS real));
GO

SELECT DATEPART(mm, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(mm, CAST(3.14159 AS float));
GO

-- DATEPART with 'm' (month) and different data types

GO
SELECT DATEPART(m, CAST(100987 AS bit));
GO

SELECT DATEPART(m, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(m, CAST(6542 AS int));
GO

SELECT DATEPART(m, CAST(1111 AS smallint));
GO

SELECT DATEPART(m, CAST(999999 AS bigint));
GO

SELECT DATEPART(m, CAST(42 AS tinyint));
GO

SELECT DATEPART(m, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(m, CAST(987654.321 AS real));
GO

SELECT DATEPART(m, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(m, CAST(3.14159 AS float));
GO

-- DATEPART with 'dy' (day of the year) and different data types

GO
SELECT DATEPART(dy, CAST(100987 AS bit));
GO

SELECT DATEPART(dy, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(dy, CAST(6542 AS int));
GO

SELECT DATEPART(dy, CAST(1111 AS smallint));
GO

SELECT DATEPART(dy, CAST(999999 AS bigint));
GO

SELECT DATEPART(dy, CAST(42 AS tinyint));
GO

SELECT DATEPART(dy, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(dy, CAST(987654.321 AS real));
GO

SELECT DATEPART(dy, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(dy, CAST(3.14159 AS float));
GO

-- DATEPART with 'y' (day of the year) and different data types

GO
SELECT DATEPART(y, CAST(100987 AS bit));
GO

SELECT DATEPART(y, CAST(1234 AS smallmoney));
GO

SELECT DATEPART(y, CAST(6542 AS int));
GO

SELECT DATEPART(y, CAST(1111 AS smallint));
GO

SELECT DATEPART(y, CAST(999999 AS bigint));
GO

SELECT DATEPART(y, CAST(42 AS tinyint));
GO

SELECT DATEPART(y, CAST(1234.789 AS decimal));
GO

SELECT DATEPART(y, CAST(987654.321 AS real));
GO

SELECT DATEPART(y, CAST(314159.432 AS numeric));
GO

SELECT DATEPART(y, CAST(3.14159 AS float));
GO

-- DATEPART with 'dd' (day of the month) and different data types

GO
SELECT DATEPART(dd, CAST(1234 AS bit));
GO

SELECT DATEPART(dd, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(dd, CAST(6542 AS int));
GO

SELECT DATEPART(dd, CAST(4567 AS smallint));
GO

SELECT DATEPART(dd, CAST(333333 AS bigint));
GO

SELECT DATEPART(dd, CAST(24 AS tinyint));
GO

SELECT DATEPART(dd, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(dd, CAST(321987.654 AS real));
GO

SELECT DATEPART(dd, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(dd, CAST(0.12345 AS float));
GO

-- DATEPART with 'd' (day of the month) and different data types

GO
SELECT DATEPART(d, CAST(1234 AS bit));
GO

SELECT DATEPART(d, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(d, CAST(6542 AS int));
GO

SELECT DATEPART(d, CAST(4567 AS smallint));
GO

SELECT DATEPART(d, CAST(333333 AS bigint));
GO

SELECT DATEPART(d, CAST(24 AS tinyint));
GO

SELECT DATEPART(d, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(d, CAST(321987.654 AS real));
GO

SELECT DATEPART(d, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(d, CAST(0.12345 AS float));
GO

-- DATEPART with 'wk' (week) and different data types

GO
SELECT DATEPART(wk, CAST(1234 AS bit));
GO

SELECT DATEPART(wk, CAST(7810 AS smallmoney));   
GO

SELECT DATEPART(wk, CAST(6542 AS int));
GO

SELECT DATEPART(wk, CAST(4567 AS smallint));
GO

SELECT DATEPART(wk, CAST(333333 AS bigint));
GO

SELECT DATEPART(wk, CAST(24 AS tinyint));
GO

SELECT DATEPART(wk, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(wk, CAST(3287.654 AS real));    
GO

SELECT DATEPART(wk, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(wk, CAST(0.12345 AS float));
GO

-- DATEPART with 'ww' (week) and different data types

GO
SELECT DATEPART(ww, CAST(1234 AS bit));
GO

SELECT DATEPART(ww, CAST(780 AS smallmoney));    
GO

SELECT DATEPART(ww, CAST(6542 AS int));
GO

SELECT DATEPART(ww, CAST(4567 AS smallint));
GO

SELECT DATEPART(ww, CAST(333333 AS bigint));
GO

SELECT DATEPART(ww, CAST(24 AS tinyint));
GO

SELECT DATEPART(ww, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(ww, CAST(3987.654 AS real));
GO

SELECT DATEPART(ww, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(ww, CAST(0.12345 AS float));
GO

-- DATEPART with 'dw' (weekday) and different data types    

GO
SELECT DATEPART(dw, CAST(1234 AS bit));
GO

SELECT DATEPART(dw, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(dw, CAST(6542 AS int));
GO

SELECT DATEPART(dw, CAST(4567 AS smallint));
GO

SELECT DATEPART(dw, CAST(333333 AS bigint));
GO

SELECT DATEPART(dw, CAST(24 AS tinyint));
GO

SELECT DATEPART(dw, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(dw, CAST(321987.654 AS real));
GO

SELECT DATEPART(dw, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(dw, CAST(0.12345 AS float));
GO

-- DATEPART with 'iso_week' (ISO week) and different data types

GO
SELECT DATEPART(iso_week, CAST(1234 AS bit));
GO

SELECT DATEPART(iso_week, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(iso_week, CAST(6542 AS int));
GO

SELECT DATEPART(iso_week, CAST(4567 AS smallint));
GO

SELECT DATEPART(iso_week, CAST(333333 AS bigint));
GO

SELECT DATEPART(iso_week, CAST(24 AS tinyint));
GO

SELECT DATEPART(iso_week, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(iso_week, CAST(197.64 AS real));   
GO

SELECT DATEPART(iso_week, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(iso_week, CAST(0.12345 AS float));
GO

-- DATEPART with 'isowk' (ISO week) and different data types

GO
SELECT DATEPART(isowk, CAST(1234 AS bit));
GO

SELECT DATEPART(isowk, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(isowk, CAST(6542 AS int));
GO

SELECT DATEPART(isowk, CAST(4567 AS smallint));
GO

SELECT DATEPART(isowk, CAST(333333 AS bigint));
GO

SELECT DATEPART(isowk, CAST(24 AS tinyint));
GO

SELECT DATEPART(isowk, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(isowk, CAST(327.654 AS real));   
GO

SELECT DATEPART(isowk, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(isowk, CAST(0.12345 AS float));
GO

-- DATEPART with 'isoww' (ISO week) and different data types

GO
SELECT DATEPART(isoww, CAST(1234 AS bit));
GO

SELECT DATEPART(isoww, CAST(7890 AS smallmoney));
GO

SELECT DATEPART(isoww, CAST(6542 AS int));
GO

SELECT DATEPART(isoww, CAST(4567 AS smallint));
GO

SELECT DATEPART(isoww, CAST(333333 AS bigint));
GO

SELECT DATEPART(isoww, CAST(24 AS tinyint));
GO

SELECT DATEPART(isoww, CAST(654321.987 AS decimal));
GO

SELECT DATEPART(isoww, CAST(97.65 AS real));    
GO

SELECT DATEPART(isoww, CAST(987654.321 AS numeric));
GO

SELECT DATEPART(isoww, CAST(0.12345 AS float));
GO

-- DATEPART with 'day' and different data types with negative values

GO
SELECT DATEPART(day, CAST(-5432 AS bit));
GO

SELECT DATEPART(day, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(day, CAST(-6542 AS int));
GO

SELECT DATEPART(day, CAST(-1111 AS smallint));
GO

SELECT DATEPART(day, CAST(-7655 AS bigint));
GO

SELECT DATEPART(day, CAST(22 AS tinyint));
GO

SELECT DATEPART(day, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(day, CAST(-729.321 AS real));
GO

SELECT DATEPART(day, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(day, CAST(-3.14159 AS float));
GO

-- DATEPART with 'month' and different data types with negative values

GO
SELECT DATEPART(month, CAST(-5432 AS bit));
GO

SELECT DATEPART(month, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(month, CAST(-6542 AS int));
GO

SELECT DATEPART(month, CAST(-1111 AS smallint));
GO

SELECT DATEPART(month, CAST(-7655 AS bigint));
GO

SELECT DATEPART(month, CAST(22 AS tinyint));
GO

SELECT DATEPART(month, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(month, CAST(-729.321 AS real));
GO

SELECT DATEPART(month, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(month, CAST(-3.14159 AS float));
GO

-- DATEPART with 'week' and different data types with negative values

GO
SELECT DATEPART(week, CAST(-5432 AS bit));
GO

SELECT DATEPART(week, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(week, CAST(-6542 AS int));
GO

SELECT DATEPART(week, CAST(-1111 AS smallint));
GO

SELECT DATEPART(week, CAST(-7655 AS bigint));
GO

SELECT DATEPART(week, CAST(22 AS tinyint));
GO

SELECT DATEPART(week, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(week, CAST(-729.321 AS real));
GO

SELECT DATEPART(week, CAST(-123.432 AS numeric));   
GO

SELECT DATEPART(week, CAST(-43.14 AS float));   
GO

-- DATEPART with 'year' and different data types with negative values

GO
SELECT DATEPART(year, CAST(-5432 AS bit));
GO

SELECT DATEPART(year, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(year, CAST(-6542 AS int));
GO

SELECT DATEPART(year, CAST(-1111 AS smallint));
GO

SELECT DATEPART(year, CAST(-7655 AS bigint));
GO

SELECT DATEPART(year, CAST(22 AS tinyint));
GO

SELECT DATEPART(year, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(year, CAST(-729.321 AS real));
GO

SELECT DATEPART(year, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(year, CAST(-3.14159 AS float));
GO

-- DATEPART with 'weekday' and different data types with negative values 

GO
SELECT DATEPART(weekday, CAST(-5432 AS bit));
GO

SELECT DATEPART(weekday, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(weekday, CAST(-6542 AS int));
GO

SELECT DATEPART(weekday, CAST(-1111 AS smallint));
GO

SELECT DATEPART(weekday, CAST(-7655 AS bigint));
GO

SELECT DATEPART(weekday, CAST(22 AS tinyint));
GO

SELECT DATEPART(weekday, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(weekday, CAST(-729.321 AS real));
GO

SELECT DATEPART(weekday, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(weekday, CAST(-3.14159 AS float));
GO

-- DATEPART with 'yy' (year without century) and different data types with negative values

GO
SELECT DATEPART(yy, CAST(-5432 AS bit));
GO

SELECT DATEPART(yy, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(yy, CAST(-6542 AS int));
GO

SELECT DATEPART(yy, CAST(-1111 AS smallint));
GO

SELECT DATEPART(yy, CAST(-7655 AS bigint));
GO

SELECT DATEPART(yy, CAST(22 AS tinyint));
GO

SELECT DATEPART(yy, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(yy, CAST(-729.321 AS real));
GO

SELECT DATEPART(yy, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(yy, CAST(-3.14159 AS float));
GO

-- DATEPART with 'yyyy' (year with century) and different data types with negative values

GO
SELECT DATEPART(yyyy, CAST(-5432 AS bit));
GO

SELECT DATEPART(yyyy, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(yyyy, CAST(-6542 AS int));
GO

SELECT DATEPART(yyyy, CAST(-1111 AS smallint));
GO

SELECT DATEPART(yyyy, CAST(-7655 AS bigint));
GO

SELECT DATEPART(yyyy, CAST(22 AS tinyint));
GO

SELECT DATEPART(yyyy, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(yyyy, CAST(-729.321 AS real));
GO

SELECT DATEPART(yyyy, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(yyyy, CAST(-3.14159 AS float));
GO

-- DATEPART with 'qq' (quarter) and different data types with negative values

GO
SELECT DATEPART(qq, CAST(-5432 AS bit));
GO

SELECT DATEPART(qq, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(qq, CAST(-6542 AS int));
GO

SELECT DATEPART(qq, CAST(-91 AS smallint));   
GO

SELECT DATEPART(qq, CAST(-7655 AS bigint));
GO

SELECT DATEPART(qq, CAST(22 AS tinyint));
GO

SELECT DATEPART(qq, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(qq, CAST(-729.321 AS real));
GO

SELECT DATEPART(qq, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(qq, CAST(-5433.14 AS float));   
GO

-- DATEPART with 'q' (quarter) and different data types with negative values

GO
SELECT DATEPART(q, CAST(-5432 AS bit));
GO

SELECT DATEPART(q, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(q, CAST(-6542 AS int));
GO

SELECT DATEPART(q, CAST(-311 AS smallint));   
GO

SELECT DATEPART(q, CAST(-7655 AS bigint));
GO

SELECT DATEPART(q, CAST(22 AS tinyint));
GO

SELECT DATEPART(q, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(q, CAST(-729.321 AS real));
GO

SELECT DATEPART(q, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(q, CAST(-33.149 AS float)); 
GO

-- DATEPART with 'mm' (month) and different data types with negative values

GO
SELECT DATEPART(mm, CAST(-5432 AS bit));
GO

SELECT DATEPART(mm, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(mm, CAST(-6542 AS int));
GO

SELECT DATEPART(mm, CAST(-1111 AS smallint));
GO

SELECT DATEPART(mm, CAST(-7655 AS bigint));
GO

SELECT DATEPART(mm, CAST(22 AS tinyint));
GO

SELECT DATEPART(mm, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(mm, CAST(-729.321 AS real));
GO

SELECT DATEPART(mm, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(mm, CAST(-3.14159 AS float));
GO

-- DATEPART with 'm' (month) and different data types with negative values

GO
SELECT DATEPART(m, CAST(-5432 AS bit));
GO

SELECT DATEPART(m, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(m, CAST(-6542 AS int));
GO

SELECT DATEPART(m, CAST(-1111 AS smallint));
GO

SELECT DATEPART(m, CAST(-7655 AS bigint));
GO

SELECT DATEPART(m, CAST(22 AS tinyint));
GO

SELECT DATEPART(m, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(m, CAST(-729.321 AS real));
GO

SELECT DATEPART(m, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(m, CAST(-3.14159 AS float));
GO

-- DATEPART with 'dy' (day of the year) and different data types with negative values

GO
SELECT DATEPART(dy, CAST(-5432 AS bit));
GO

SELECT DATEPART(dy, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(dy, CAST(-6542 AS int));
GO

SELECT DATEPART(dy, CAST(-1111 AS smallint));
GO

SELECT DATEPART(dy, CAST(-7655 AS bigint));
GO

SELECT DATEPART(dy, CAST(22 AS tinyint));
GO

SELECT DATEPART(dy, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(dy, CAST(-729.321 AS real));
GO

SELECT DATEPART(dy, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(dy, CAST(-3.14159 AS float));
GO

-- DATEPART with 'y' (day of the year) and different data types with negative values

GO
SELECT DATEPART(y, CAST(-5432 AS bit));
GO

SELECT DATEPART(y, CAST(-1234 AS smallmoney));
GO

SELECT DATEPART(y, CAST(-6542 AS int));
GO

SELECT DATEPART(y, CAST(-1111 AS smallint));
GO

SELECT DATEPART(y, CAST(-7655 AS bigint));
GO

SELECT DATEPART(y, CAST(22 AS tinyint));
GO

SELECT DATEPART(y, CAST(-1234.789 AS decimal));
GO

SELECT DATEPART(y, CAST(-729.321 AS real));
GO

SELECT DATEPART(y, CAST(-1238.432 AS numeric));
GO

SELECT DATEPART(y, CAST(-3.14159 AS float));
GO

-- DATEPART with 'dd' (day of the month) and different data types with negative values

GO
SELECT DATEPART(dd, CAST(-1234 AS bit));
GO

SELECT DATEPART(dd, CAST(-7890 AS smallmoney));
GO

SELECT DATEPART(dd, CAST(-6542 AS int));
GO

SELECT DATEPART(dd, CAST(-4567 AS smallint));
GO

SELECT DATEPART(dd, CAST(-333 AS bigint));
GO

SELECT DATEPART(dd, CAST(2 AS tinyint));
GO

SELECT DATEPART(dd, CAST(-6521.987 AS decimal));
GO

SELECT DATEPART(dd, CAST(-3217.654 AS real));
GO

SELECT DATEPART(dd, CAST(-94.321 AS numeric));
GO

SELECT DATEPART(dd, CAST(-0.12345 AS float));
GO

-- DATEPART with 'd' (day of the month) and different data types with negative values

GO
SELECT DATEPART(d, CAST(-1256 AS bit));
GO

SELECT DATEPART(d, CAST(-780 AS smallmoney));
GO

SELECT DATEPART(d, CAST(-985 AS int));
GO

SELECT DATEPART(d, CAST(-4567 AS smallint));
GO

SELECT DATEPART(d, CAST(-33 AS bigint));
GO

SELECT DATEPART(d, CAST(2 AS tinyint));
GO

SELECT DATEPART(d, CAST(-651.987 AS decimal));
GO

SELECT DATEPART(d, CAST(-37.654 AS real));
GO

SELECT DATEPART(d, CAST(-954.321 AS numeric));
GO

SELECT DATEPART(d, CAST(-0.12345 AS float));
GO

-- DATEPART with 'wk' (week) and different data types with negative values

GO
SELECT DATEPART(wk, CAST(-126 AS bit));
GO

SELECT DATEPART(wk, CAST(-780 AS smallmoney));
GO

SELECT DATEPART(wk, CAST(-95 AS int));
GO

SELECT DATEPART(wk, CAST(-45 AS smallint));   
GO

SELECT DATEPART(wk, CAST(-333 AS bigint));
GO

SELECT DATEPART(wk, CAST(2 AS tinyint));
GO

SELECT DATEPART(wk, CAST(-65.987 AS decimal));
GO

SELECT DATEPART(wk, CAST(-327.654 AS real));
GO

SELECT DATEPART(wk, CAST(-54.321 AS numeric));
GO

SELECT DATEPART(wk, CAST(-40.12 AS float));   
GO

-- DATEPART with 'ww' (week) and different data types with negative values

GO
SELECT DATEPART(ww, CAST(-156 AS bit));
GO

SELECT DATEPART(ww, CAST(-780 AS smallmoney));
GO

SELECT DATEPART(ww, CAST(-65 AS int));
GO

SELECT DATEPART(ww, CAST(-17 AS smallint));   
GO

SELECT DATEPART(ww, CAST(-33 AS bigint));
GO

SELECT DATEPART(ww, CAST(2 AS tinyint));
GO

SELECT DATEPART(ww, CAST(-61.9 AS decimal));   
GO

SELECT DATEPART(ww, CAST(-37.64 AS real));   
GO

SELECT DATEPART(ww, CAST(-84.321 AS numeric));   
GO

SELECT DATEPART(ww, CAST(-220.12345 AS float));   
GO

-- DATEPART with 'dw' (weekday) and different data types with negative values   

GO
SELECT DATEPART(dw, CAST(-156 AS bit));
GO

SELECT DATEPART(dw, CAST(-780 AS smallmoney));
GO

SELECT DATEPART(dw, CAST(-965 AS int));
GO

SELECT DATEPART(dw, CAST(-4567 AS smallint));
GO

SELECT DATEPART(dw, CAST(-33 AS bigint));
GO

SELECT DATEPART(dw, CAST(2 AS tinyint));
GO

SELECT DATEPART(dw, CAST(-651.987 AS decimal));
GO

SELECT DATEPART(dw, CAST(-321.654 AS real));
GO

SELECT DATEPART(dw, CAST(-984.321 AS numeric));
GO

SELECT DATEPART(dw, CAST(-0.12345 AS float));
GO

-- DATEPART with 'iso_week' (ISO week) and different data types with negative values

GO
SELECT DATEPART(iso_week, CAST(-156 AS bit));
GO

SELECT DATEPART(iso_week, CAST(-7890 AS smallmoney));
GO

SELECT DATEPART(iso_week, CAST(-985 AS int));
GO

SELECT DATEPART(iso_week, CAST(-4567 AS smallint));
GO

SELECT DATEPART(iso_week, CAST(-333 AS bigint));
GO

SELECT DATEPART(iso_week, CAST(2 AS tinyint));
GO

SELECT DATEPART(iso_week, CAST(-621.987 AS decimal));
GO

SELECT DATEPART(iso_week, CAST(-327.654 AS real));
GO

SELECT DATEPART(iso_week, CAST(-984.321 AS numeric));
GO

SELECT DATEPART(iso_week, CAST(-10.12 AS float));   
GO

-- DATEPART with 'isowk' (ISO week) and different data types with negative values

GO
SELECT DATEPART(isowk, CAST(-1256 AS bit));
GO

SELECT DATEPART(isowk, CAST(-70 AS smallmoney));   
GO

SELECT DATEPART(isowk, CAST(-965 AS int));
GO

SELECT DATEPART(isowk, CAST(-467 AS smallint));
GO

SELECT DATEPART(isowk, CAST(-33 AS bigint));
GO

SELECT DATEPART(isowk, CAST(2 AS tinyint));
GO

SELECT DATEPART(isowk, CAST(-51.97 AS decimal));   
GO

SELECT DATEPART(isowk, CAST(-37.65 AS real));   
GO

SELECT DATEPART(isowk, CAST(-96.31 AS numeric));
GO

SELECT DATEPART(isowk, CAST(-110.123 AS float));   
GO

-- DATEPART with 'isoww' (ISO week) and different data types with negative values

GO
SELECT DATEPART(isoww, CAST(-456 AS bit));
GO

SELECT DATEPART(isoww, CAST(-70 AS smallmoney));
GO

SELECT DATEPART(isoww, CAST(-965 AS int));
GO

SELECT DATEPART(isoww, CAST(-47 AS smallint));   
GO

SELECT DATEPART(isoww, CAST(-333 AS bigint));
GO

SELECT DATEPART(isoww, CAST(-621.987 AS decimal));
GO

SELECT DATEPART(isoww, CAST(-39.65 AS real));   
GO

SELECT DATEPART(isoww, CAST(-97.321 AS numeric));
GO

SELECT DATEPART(isoww, CAST(-11.12345 AS float));   
GO
