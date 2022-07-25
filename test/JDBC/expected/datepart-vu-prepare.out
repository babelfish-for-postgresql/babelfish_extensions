CREATE VIEW date_part_vu_prepare_view AS SELECT * FROM DATEPART(wk, '07-18-2022')
GO

CREATE FUNCTION date_part_vu_prepare_func(@date_str varchar(128))
RETURNS TABLE
AS
RETURN SELECT * FROM DATEPART(mm, @date_str);
GO

CREATE PROCEDURE date_part_vu_prepare_proc @date_str varchar(128)
AS
SELECT DATEPART(dd, @date_str)
GO

-- sys.day() uses sys.datepart() internally, so creating objects
-- using sys.day() to see if they are not broken due to upgrade
CREATE VIEW date_part_vu_prepare_sys_day_view AS SELECT * FROM DAY(CAST ('07-18-2022' AS datetime))
GO

CREATE FUNCTION date_part_vu_prepare_sys_day_func(@a datetime)
RETURNS TABLE
AS
RETURN SELECT * FROM DAY(@a);
GO

CREATE PROCEDURE date_part_vu_prepare_sys_day_proc @a datetime
AS
SELECT DAY(@a)
GO
