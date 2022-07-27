-- Test DAY function for computed columns
SELECT day1, day2 from dateFunctions_day;
GO

-- Test MONTH function for computed columns
SELECT month1, month2 from dateFunctions_month;
GO

-- Test YEAR function for computed columns
SELECT year1, year2 from dateFunctions_year;
GO

-- Test DATEDIFF function with DATE datatype for computed columns
SELECT diffMonthInDates from dateFunctions_datediff_1;
GO

-- Test DATEDIFF function with DATETIME2 datatype for computed columns
SELECT diffMonthInDates from dateFunctions_datediff_2;
GO

-- Test DATEFROMPARTS function for computed columns
SELECT dateresult from dateFunctions_datefromparts;
GO

-- Test DATENAME function for computed columns
SELECT year, month, weekday, dayofyear, day from dateFunctions_datename;
GO

-- Test DATEPART function for computed columns
SELECT datepart1, datepart2 from dateFunctions_datepart_1;
GO

-- Test DATEPART function for computed columns
SELECT datepart1, datepart2 from dateFunctions_datepart_2;
GO
