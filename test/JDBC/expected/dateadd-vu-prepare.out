CREATE PROCEDURE dateadd_p1 as (select dateadd(day, 2, cast('1900-01-01' as date)));
GO

CREATE PROCEDURE dateadd_p2 as (select dateadd(hour, 2, cast('01:01:21' as time)));
GO

CREATE PROCEDURE dateadd_p3 as (select dateadd(hour, 5, cast('01:01:21 +10:00' as datetimeoffset)));
GO

CREATE PROCEDURE dateadd_p4 as (select dateadd(second, 1, cast('1999-12-31 23:59:59' as datetime)));
GO

CREATE PROCEDURE dateadd_p5 as (select dateadd(millisecond, 1, cast('1999-12-31 23:59:59' as datetime)));
GO

CREATE PROCEDURE dateadd_p6 as (select dateadd(millisecond, 1, cast('1999-12-31 23:59:59' as datetime2)));
GO

CREATE PROCEDURE dateadd_p7 as (select dateadd(day, 2, cast('01:01:21' as time)));
GO

CREATE PROCEDURE dateadd_p8 as (select dateadd(hour, 2, cast('1900-01-01' as date)));
GO

CREATE PROCEDURE dateadd_p9 as (select dateadd(minute, -70, cast('2016-12-26 00:30:05.523456+8' as datetimeoffset)));
GO

CREATE PROCEDURE dateadd_p10 as (select sys.dateadd_internal_datetime('day', 1, cast('2016-12-26 00:30:05' as datetime), 3));
GO
