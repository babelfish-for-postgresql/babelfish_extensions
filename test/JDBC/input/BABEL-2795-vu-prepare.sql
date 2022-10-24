-- Original bug
CREATE VIEW BABEL_2795_vu_prepare_v1 AS (select datediff(dd,DATETIMEFROMPARTS(2021,12,10,1,50,59,0),DATEADD(minute,123456*1440,DATETIMEFROMPARTS(1900,1,1,0,0,0,0))));
GO

-- startdate < enddate; #full daydiff = 1, expected daydiff = 2
CREATE VIEW BABEL_2795_vu_prepare_v2 AS (SELECT DATEDIFF(day, '2011-12-29 23:00:00', '2011-12-31 01:00:00'));
GO

-- startdate < enddate; #full daydiff = 1, expected daydiff = 1
CREATE VIEW BABEL_2795_vu_prepare_v3 AS (SELECT DATEDIFF(dd, '2011-12-30 08:55:59.123', '2011-12-31 08:55:59.123'));
GO

-- startdate < enddate; #full daydiff = 0, expected daydiff = 1
CREATE VIEW BABEL_2795_vu_prepare_v4 AS (SELECT DATEDIFF(dd, '2011-12-30 08:55:59.123', '2011-12-31 00:00:00.000'));
GO

-- startdate > enddate; #full daydiff = 0, expected daydiff = -1
CREATE VIEW BABEL_2795_vu_prepare_v5 AS (SELECT DATEDIFF(dd, '2011-12-31 00:00:00.000', '2011-12-30 08:55:59.123'));
GO

-- NULL datediff checking; expected outcome is NULL
CREATE PROCEDURE BABEL_2795_vu_prepare_p1 AS (SELECT DATEDIFF(day, NULL, '2011-12-29 23:00:00'));
GO

-- NULL datediff checking; expected outcome is NULL
CREATE PROCEDURE BABEL_2795_vu_prepare_p2 AS (SELECT DATEDIFF(day, NULL, NULL));
GO

-- startdate < enddate across different years; #full daydiff = 0, expected daydiff = 1
CREATE PROCEDURE BABEL_2795_vu_prepare_p3 AS (SELECT DATEDIFF(day, '2011-12-31 23:00:00', '2012-01-01 01:00:00'));
GO

-- non-leap year daydiff around end of February; #full daydiff = 1, expected daydiff = 1
CREATE PROCEDURE BABEL_2795_vu_prepare_p4 AS (SELECT DATEDIFF(day, '2011-02-28 03:00:00', '2011-03-01 09:46:00'));
GO

-- Leap year daydiff around end of February; #full daydiff = 2, expected daydiff = 2
CREATE PROCEDURE BABEL_2795_vu_prepare_p5 AS (SELECT DATEDIFF(day, '2012-02-28 03:00:00', '2012-03-01 09:46:00'));
GO

-- negative hourdiff on different dates
CREATE FUNCTION BABEL_2795_vu_prepare_f1()
RETURNS INTEGER AS
BEGIN
RETURN (SELECT DATEDIFF(hour, '1986-03-03 00:05', '1986-03-01 08:55'));
END
GO

-- negative hourdiff on same date
CREATE FUNCTION BABEL_2795_vu_prepare_f2()
RETURNS INTEGER AS
BEGIN
RETURN (SELECT DATEDIFF(hour, '1992-10-30 02:01', '1992-10-30 01:23'));
END
GO

-- positive hourdiff on same date
CREATE FUNCTION BABEL_2795_vu_prepare_f3()
RETURNS INTEGER AS
BEGIN
RETURN (SELECT DATEDIFF(hour, '1992-10-30 01:23', '1992-10-30 02:01'));
END
GO

-- positive hourdiff on different dates; around leap-year dates
CREATE FUNCTION BABEL_2795_vu_prepare_f4()
RETURNS INTEGER AS
BEGIN
RETURN (SELECT DATEDIFF(hour, '2016-02-28 09:05', '2016-03-01 08:55'));
END
GO

-- positive hourdiff on different dates; around non-leap year dates
CREATE FUNCTION BABEL_2795_vu_prepare_f5()
RETURNS INTEGER AS
BEGIN
RETURN (SELECT DATEDIFF(hour, '2015-02-28 09:55', '2015-03-01 08:55'));
END
GO
