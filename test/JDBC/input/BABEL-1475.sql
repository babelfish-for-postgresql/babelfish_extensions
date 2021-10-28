-- Test DAY function for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), day1 as DAY(dt1), day2 as DAY(dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
SELECT day1, day2 from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test MONTH function for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), month1 as MONTH(dt1), month2 as MONTH(dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
SELECT month1, month2 from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test YEAR function for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), year1 as YEAR(dt1), year2 as YEAR(dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
SELECT year1, year2 from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATEADD function for computed columns
-- WRONG OUTPUT with datetimeoffset
-- CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), addMonthInDate1 as DATEADD(month,1,dt1), addMonthInDate2 as DATEADD(month,1,dt2));
-- INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
-- SELECT addMonthInDate1, addMonthInDate2 from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO

-- Test DATEDIFF function with DATE datatype for computed columns
CREATE TABLE dateFunctions (dt1 date, dt2 date, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01', '1912-10-25');
SELECT diffMonthInDates from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATEDIFF function with DATETIME2 datatype for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetime2, diffMonthInDates as DATEDIFF(month,dt1,dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10', '1912-10-25 12:24:32');
SELECT diffMonthInDates from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATEDIFF function with DATETIMEOFFSET datatype for computed columns
-- CREATE TABLE dateFunctions (dt1 datetimeoffset(6), dt2 datetimeoffset(6), diffMonthInDates as DATEDIFF(month,dt1,dt2));
-- INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10', '1912-10-25 12:24:32');
-- SELECT diffMonthInDates from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO

-- Test DATEFROMPARTS function for computed columns
CREATE TABLE dateFunctions (year int, month int, day int, dateresult as DATEFROMPARTS(year, month, day));
INSERT INTO dateFunctions (year, month, day) values (1912, 10, 25);
SELECT dateresult from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATENAME function for computed columns
CREATE TABLE dateFunctions (dt date, year as DATENAME(year, dt), month as DATENAME(month, dt), weekday as DATENAME(dow, dt), dayofyear as DATENAME(dayofyear, dt), day as DATENAME(day, dt));
INSERT INTO dateFunctions (dt) values ('1912-10-25');
SELECT year, month, weekday, dayofyear, day from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATEPART function for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(month, dt1), datepart2 as DATEPART(month, dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.111111', '1912-10-25 12:24:32 +10:0');
SELECT datepart1, datepart2 from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATEPART function for computed columns
CREATE TABLE dateFunctions (dt1 datetime2, dt2 datetimeoffset(6), datepart1 as DATEPART(dow, dt1), datepart2 as DATEPART(dow, dt2));
INSERT INTO dateFunctions (dt1, dt2) values ('2007-01-01 13:10:10.1111111', '1912-10-25 12:24:32 +10:0');
SELECT datepart1, datepart2 from dateFunctions;
DROP TABLE dateFunctions;
GO

-- Test DATETIME2FROMPARTS function with numeric arguments for computed columns
-- WRONG OUTPUT
-- CREATE TABLE dateFunctions (year int, month int, day int, hour int, minute int, seconds int, fractions int, precision int, dateresult as DATETIME2FROMPARTS (year, month, day, hour, minute, seconds, fractions, precision));
-- INSERT INTO dateFunctions (year, month, day, hour, minute, seconds, fractions, precision) values (2011, 8, 15, 14, 23, 44, 5, 1 );
-- SELECT dateresult from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO

-- Test DATETIME2FROMPARTS function with textual arguments for computed columns
-- WRONG OUTPUT
-- CREATE TABLE dateFunctions (year text, month text, day text, hour text, minute text, seconds text, fractions text, precision text, dateresult as DATETIME2FROMPARTS (year, month, day, hour, minute, seconds, fractions, precision));
-- INSERT INTO dateFunctions (year, month, day, hour, minute, seconds, fractions, precision) values ('2011', '8', '15', '14', '23', '44', '5', '1');
-- SELECT dateresult from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO

-- Test DATETIMEFROMPARTS function with numeric arguments for computed columns
-- WRONG OUTPUT
-- CREATE TABLE dateFunctions (year int, month int, day int, hour int, minute int, seconds int, milliseconds int, dateresult as DATETIMEFROMPARTS (year, month, day, hour, minute, seconds, milliseconds));
-- INSERT INTO dateFunctions (year, month, day, hour, minute, seconds, milliseconds) values (2010, 12, 31, 23, 59, 59, 456);
-- SELECT dateresult from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO

-- Test DATETIMEFROMPARTS function with textual arguments for computed columns
-- WRONG OUTPUT
-- CREATE TABLE dateFunctions (year text, month text, day text, hour text, minute text, seconds text, milliseconds text, dateresult as DATETIMEFROMPARTS (year, month, day, hour, minute, seconds, milliseconds));
-- INSERT INTO dateFunctions (year, month, day, hour, minute, seconds, milliseconds) values ('2010', '12', '31', '23', '59', '59', '456');
-- SELECT dateresult from dateFunctions;
-- DROP TABLE dateFunctions;
-- GO