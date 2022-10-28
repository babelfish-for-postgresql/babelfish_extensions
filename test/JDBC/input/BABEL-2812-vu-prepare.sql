CREATE PROCEDURE babel_2812_vu_p1 @dt1 VARCHAR(20), @dt2 VARCHAR(20)
AS
SELECT CONVERT(DATETIME, @dt1,14) + @dt2 AS NextTime;
GO

CREATE PROCEDURE babel_2812_vu_p2 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT @dt1 + @dt2 AS NextTime;
GO

CREATE PROCEDURE babel_2812_vu_p3 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT DATEADD(day ,DATEDIFF(day, 0, @dt2) ,@dt1) as NextTime;
GO
