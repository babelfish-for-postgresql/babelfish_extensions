-- Test DAY function for computed columns
SELECT day1, day2 from BABEL_1475_vu_prepare_day;
GO

-- Test MONTH function for computed columns
SELECT month1, month2 from BABEL_1475_vu_prepare_month;
GO

-- Test YEAR function for computed columns
SELECT year1, year2 from BABEL_1475_vu_prepare_year;
GO

-- Test DATEDIFF function with DATE datatype for computed columns
SELECT diffMonthInDates from BABEL_1475_vu_prepare_datediff_1;
GO

-- Test DATEDIFF function with DATETIME2 datatype for computed columns
SELECT diffMonthInDates from BABEL_1475_vu_prepare_datediff_2;
GO

-- Test DATEFROMPARTS function for computed columns
SELECT dateresult from BABEL_1475_vu_prepare_datefromparts;
GO

-- Test DATENAME function for computed columns
SELECT year, month, weekday, dayofyear, day from BABEL_1475_vu_prepare_datename;
GO

-- Test DATEPART function for computed columns
SELECT datepart1, datepart2 from BABEL_1475_vu_prepare_datepart_1;
GO

-- Test DATEPART function for computed columns
SELECT datepart1, datepart2 from BABEL_1475_vu_prepare_datepart_2;
GO
