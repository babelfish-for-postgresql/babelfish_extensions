-- Test DAY function for computed columns
CREATE TABLE BABEL_1475_vu_day (dt1 datetime2, dt2 datetimeoffset(6), day1 as DAY(dt1), day2 as DAY(dt2));
INSERT INTO BABEL_1475_vu_day (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

-- Test MONTH function for computed columns
CREATE TABLE BABEL_1475_vu_month (dt1 datetime2, dt2 datetimeoffset(6), month1 as MONTH(dt1), month2 as MONTH(dt2));
INSERT INTO BABEL_1475_vu_month (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

-- Test YEAR function for computed columns
CREATE TABLE BABEL_1475_vu_year (dt1 datetime2, dt2 datetimeoffset(6), year1 as YEAR(dt1), year2 as YEAR(dt2));
INSERT INTO BABEL_1475_vu_year (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

-- Test DATEDIFF function with DATE datatype for computed columns
CREATE TABLE BABEL_1475_vu_datediff_1 (dt1 date, dt2 date, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO BABEL_1475_vu_datediff_1 (dt1, dt2) values ('2007-01-01', '1912-10-25');
GO

-- Test DATEDIFF function with DATETIME2 datatype for computed columns
CREATE TABLE BABEL_1475_vu_datediff_2 (dt1 datetime2, dt2 datetime2, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO BABEL_1475_vu_datediff_2 (dt1, dt2) values ('2007-01-01 13:10:10', '1912-10-25 12:24:32');
GO

-- Test DATEFROMPARTS function for computed columns
CREATE TABLE BABEL_1475_vu_datefromparts (year int, month int, day int, dateresult as DATEFROMPARTS(year, month, day));
INSERT INTO BABEL_1475_vu_datefromparts (year, month, day) values (1912, 10, 25);
GO

-- Test DATENAME function for computed columns
CREATE TABLE BABEL_1475_vu_datename (dt date, year as DATENAME(year, dt), month as DATENAME(month, dt), weekday as DATENAME(dow, dt), dayofyear as DATENAME(dayofyear, dt), day as DATENAME(day, dt));
INSERT INTO BABEL_1475_vu_datename (dt) values ('1912-10-25');
GO

-- Test DATEPART function for computed columns
CREATE TABLE BABEL_1475_vu_datepart_1 (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(month, dt1), datepart2 as DATEPART(month, dt2));
INSERT INTO BABEL_1475_vu_datepart_1 (dt1, dt2) values ('2007-01-01 13:10:10.111111', '1912-10-25 12:24:32 +10:0');
GO

-- Test DATEPART function for computed columns
CREATE TABLE BABEL_1475_vu_datepart_2 (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(dow, dt1), datepart2 as DATEPART(dow, dt2));
INSERT INTO BABEL_1475_vu_datepart_2 (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

