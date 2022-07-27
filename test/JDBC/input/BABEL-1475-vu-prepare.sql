CREATE TABLE babel_1475_vu_prepare_t1 (dt1 datetime2, dt2 datetimeoffset(6), day1 as DAY(dt1), day2 as DAY(dt2));
INSERT INTO babel_1475_vu_prepare_t1 (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

CREATE TABLE babel_1475_vu_prepare_t2 (dt1 datetime2, dt2 datetimeoffset(6), month1 as MONTH(dt1), month2 as MONTH(dt2));
INSERT INTO babel_1475_vu_prepare_t2 (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

CREATE TABLE babel_1475_vu_prepare_t3 (dt1 datetime2, dt2 datetimeoffset(6), year1 as YEAR(dt1), year2 as YEAR(dt2));
INSERT INTO babel_1475_vu_prepare_t3 (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO

CREATE TABLE babel_1475_vu_prepare_t4 (dt1 date, dt2 date, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO babel_1475_vu_prepare_t4 (dt1, dt2) values ('2007-01-01', '1912-10-25');
GO

CREATE TABLE babel_1475_vu_prepare_t5 (dt1 datetime2, dt2 datetime2, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO babel_1475_vu_prepare_t5 (dt1, dt2) values ('2007-01-01 13:10:10', '1912-10-25 12:24:32');
GO

CREATE TABLE babel_1475_vu_prepare_t6 (year int, month int, day int, dateresult as DATEFROMPARTS(year, month, day));
INSERT INTO babel_1475_vu_prepare_t6 (year, month, day) values (1912, 10, 25);
GO

CREATE TABLE babel_1475_vu_prepare_t7 (dt date, year as DATENAME(year, dt), month as DATENAME(month, dt), weekday as DATENAME(dow, dt), dayofyear as DATENAME(dayofyear, dt), day as DATENAME(day, dt));
INSERT INTO babel_1475_vu_prepare_t7 (dt) values ('1912-10-25');
GO

CREATE TABLE babel_1475_vu_prepare_t8 (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(month, dt1), datepart2 as DATEPART(month, dt2));
INSERT INTO babel_1475_vu_prepare_t8 (dt1, dt2) values ('2007-01-01 13:10:10.111111', '1912-10-25 12:24:32 +10:0');
GO

CREATE TABLE babel_1475_vu_prepare_t9 (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(dow, dt1), datepart2 as DATEPART(dow, dt2));
INSERT INTO babel_1475_vu_prepare_t9 (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
GO
