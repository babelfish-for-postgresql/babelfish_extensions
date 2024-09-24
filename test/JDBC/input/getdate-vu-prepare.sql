Create procedure sysdatetime_dep_proc
AS 
    WITH
        Pass0 as (select sys.sysdatetime() as C union all select sys.sysdatetime()), --2 rows
        Pass1 as (select sys.sysdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
        Pass2 as (select sys.sysdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
        Pass3 as (select sys.sysdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
        Pass4 as (select sys.sysdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
        Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetime()
GO

Create procedure sysdatetimeoffset_dep_proc
AS 
    WITH
    Pass0 as (select sys.sysdatetimeoffset() as C union all select sys.sysdatetimeoffset()), --2 rows
    Pass1 as (select sys.sysdatetimeoffset() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysdatetimeoffset() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysdatetimeoffset() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysdatetimeoffset() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetimeoffset()
GO

Create procedure sysutcdatetime_dep_proc
AS 
    WITH
    Pass0 as (select sys.sysutcdatetime() as C union all select sys.sysutcdatetime()), --2 rows
    Pass1 as (select sys.sysutcdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysutcdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysutcdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysutcdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sysutcdatetime()
GO

Create procedure getdate_dep_proc 
AS 
    WITH
    Pass0 as (select sys.getdate() as C union all select sys.getdate()), --2 rows
    Pass1 as (select sys.getdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getdate()
GO

Create procedure getutcdate_dep_proc
AS
    WITH
    Pass0 as (select sys.getutcdate() as C union all select sys.getutcdate()), --2 rows
    Pass1 as (select sys.getutcdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getutcdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getutcdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getutcdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getutcdate()
GO

Create view sysdatetime_dep_view
AS 
    WITH
        Pass0 as (select sys.sysdatetime() as C union all select sys.sysdatetime()), --2 rows
        Pass1 as (select sys.sysdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
        Pass2 as (select sys.sysdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
        Pass3 as (select sys.sysdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
        Pass4 as (select sys.sysdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
        Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetime()
GO

Create view sysdatetimeoffset_dep_view
AS 
    WITH
    Pass0 as (select sys.sysdatetimeoffset() as C union all select sys.sysdatetimeoffset()), --2 rows
    Pass1 as (select sys.sysdatetimeoffset() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysdatetimeoffset() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysdatetimeoffset() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysdatetimeoffset() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.sysdatetimeoffset()
GO

Create view sysutcdatetime_dep_view
AS 
    WITH
    Pass0 as (select sys.sysutcdatetime() as C union all select sys.sysutcdatetime()), --2 rows
    Pass1 as (select sys.sysutcdatetime() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.sysutcdatetime() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.sysutcdatetime() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.sysutcdatetime() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sysutcdatetime()
GO

Create view getdate_dep_view
AS
    WITH
    Pass0 as (select sys.getdate() as C union all select sys.getdate()), --2 rows
    Pass1 as (select sys.getdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getdate()
GO

Create view getutcdate_dep_view
AS
    WITH
    Pass0 as (select sys.getutcdate() as C union all select sys.getutcdate()), --2 rows
    Pass1 as (select sys.getutcdate() as C from Pass0 as A, Pass0 as B),--4 rows
    Pass2 as (select sys.getutcdate() as C from Pass1 as A, Pass1 as B),--16 rows
    Pass3 as (select sys.getutcdate() as C from Pass2 as A, Pass2 as B),--256 rows
    Pass4 as (select sys.getutcdate() as C from Pass3 as A, Pass3 as B),--65536 rows
    Tally as (select row_number() over(order by C) as Number, min(C) over () as min_getdate from Pass4)
    SELECT count(min_getdate)
    FROM Tally
    WHERE min_getdate = sys.getutcdate()
GO

CREATE PROCEDURE dbo.GetSysDatetimeDiff
AS
BEGIN
    DECLARE @x datetime2 = SYSDATETIME();
    select set_config('timezone', 'US/Pacific', false);
    DECLARE @y datetime2 = SYSDATETIME()
    select set_config('timezone', 'UTC', false);
    SELECT DATEDIFF(MINUTE, @y, @x);
END;
GO

CREATE PROCEDURE dbo.GetSysDatetimeOffsetDiff
AS
BEGIN
    DECLARE @x datetime2 = sysdatetimeoffset();
    select set_config('timezone', 'US/Pacific', false);
    DECLARE @y datetime2 = sysdatetimeoffset()
    select set_config('timezone', 'UTC', false);
    SELECT DATEDIFF(MINUTE, @y, @x);
END;
GO

CREATE PROCEDURE dbo.GetDateDiff
AS
BEGIN
    DECLARE @x datetime2 = getdate();
    select set_config('timezone', 'US/Pacific', false);
    DECLARE @y datetime2 = getdate()
    select set_config('timezone', 'UTC', false);
    SELECT DATEDIFF(MINUTE, @y, @x);
END;
GO

CREATE PROCEDURE dbo.GetCurrTimestampDiff
AS
BEGIN
    DECLARE @x datetime2 = CURRENT_TIMESTAMP;
    select set_config('timezone', 'US/Pacific', false);
    DECLARE @y datetime2 = CURRENT_TIMESTAMP
    select set_config('timezone', 'UTC', false);
    SELECT DATEDIFF(MINUTE, @y, @x);
END;
GO

CREATE TABLE datetimediffTable(sysdatetime int, sysdatetimeoffset int, getdate int, currtimestamp int)
GO

DECLARE @sysdatetime1 datetime2, @sysdatetimeoffset1 datetime2, @getdate1 datetime2, @currtimestamp1 datetime2;
DECLARE @sysdatetime2 datetime2, @sysdatetimeoffset2 datetime2, @getdate2 datetime2, @currtimestamp2 datetime2;
SELECT @sysdatetime1 = SYSDATETIME(), @sysdatetimeoffset1 = sysdatetimeoffset(), @getdate1 = getdate(), @currtimestamp1 = CURRENT_TIMESTAMP;
select set_config('timezone', 'US/Pacific', false);
SELECT @sysdatetime2 = SYSDATETIME(), @sysdatetimeoffset2 = sysdatetimeoffset(), @getdate2 = getdate(), @currtimestamp2 = CURRENT_TIMESTAMP;
select set_config('timezone', 'UTC', false);
INSERT INTO datetimediffTable values (DATEDIFF(MINUTE, @sysdatetime2, @sysdatetime1), DATEDIFF(MINUTE, @sysdatetimeoffset2, @sysdatetimeoffset1), DATEDIFF(MINUTE, @getdate2, @getdate1), DATEDIFF(MINUTE, @currtimestamp2, @currtimestamp1))
GO

CREATE VIEW dbo.datetimediffView AS SELECT * FROM datetimediffTable;
GO

CREATE FUNCTION dbo.GetSysDatetimeDiffFunc(@sysdatetime1 datetime2)
RETURNS int
AS
BEGIN
    DECLARE @x datetime2 = SYSDATETIME();
    RETURN DATEDIFF(MINUTE, @sysdatetime1, @x);
END;
GO

CREATE FUNCTION dbo.GetSysDatetimeOffsetDiffFunc(@sysdatetimeoffset1 datetime2)
RETURNS int
AS
BEGIN
    DECLARE @x datetime2 = sysdatetimeoffset();
    RETURN DATEDIFF(MINUTE, @sysdatetimeoffset1, @x);
END;
GO

CREATE FUNCTION dbo.GetDateDiffFunc(@getdate1 datetime2)
RETURNS int
AS
BEGIN
    DECLARE @x datetime2 = getdate();
    RETURN DATEDIFF(MINUTE, @getdate1, @x);
END;
GO

CREATE FUNCTION dbo.GetCurrTimestampDiffFunc(@currtimestamp1 datetime2)
RETURNS int
AS
BEGIN
    DECLARE @x datetime2 = CURRENT_TIMESTAMP;
    RETURN DATEDIFF(MINUTE, @currtimestamp1, @x);
END;
GO

CREATE TABLE trgdatetimediffTestTab(sysdatetime int, sysdatetimeoffset int, getdate int, currtimestamp int)
GO

CREATE TRIGGER trgdatetimediff
ON datetimediffTable
AFTER INSERT
AS
BEGIN
    DECLARE @sysdatetime1 datetime2, @sysdatetimeoffset1 datetime2, @getdate1 datetime2, @currtimestamp1 datetime2;
    DECLARE @sysdatetime2 datetime2, @sysdatetimeoffset2 datetime2, @getdate2 datetime2, @currtimestamp2 datetime2;
    SELECT @sysdatetime1 = SYSDATETIME(), @sysdatetimeoffset1 = sysdatetimeoffset(), @getdate1 = getdate(), @currtimestamp1 = CURRENT_TIMESTAMP;
    select set_config('timezone', 'US/Pacific', false);
    SELECT @sysdatetime2 = SYSDATETIME(), @sysdatetimeoffset2 = sysdatetimeoffset(), @getdate2 = getdate(), @currtimestamp2 = CURRENT_TIMESTAMP;
    select set_config('timezone', 'UTC', false);
    INSERT INTO trgdatetimediffTestTab values (DATEDIFF(MINUTE, @sysdatetime2, @sysdatetime1), DATEDIFF(MINUTE, @sysdatetimeoffset2, @sysdatetimeoffset1), DATEDIFF(MINUTE, @getdate2, @getdate1), DATEDIFF(MINUTE, @currtimestamp2, @currtimestamp1))
END;
GO
