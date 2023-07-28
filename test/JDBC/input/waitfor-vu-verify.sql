-- test WAITFOR DELAY with second
INSERT INTO Timecheck (NAME) values('a')
GO

WAITFOR DELAY '00:00:02'
GO

INSERT INTO Timecheck (NAME) values('b')
GO

-- Expect WAITFOR DELAY: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:02.900'
            THEN 'WAITFOR DELAY: Failed'
        ELSE 'WAITFOR DELAY: Passed'
    END AS CheckResult
FROM Timecheck
GO

-- test WAITFOR DELAY with millisecond
INSERT INTO Timecheck1 (NAME) values('a')
GO

WAITFOR DELAY '00:00:00.050'

INSERT INTO Timecheck1 (NAME) values('b')
GO

-- Expect WAITFOR DELAY: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:01'
            THEN 'WAITFOR DELAY: Failed'
        ELSE 'WAITFOR DELAY: Passed'
    END AS CheckResult
FROM Timecheck1
GO

-- test WAITFOR DELAY in variable
INSERT INTO Timecheck2 (NAME) values('a')
GO

DECLARE @v DATETIME
SET @v = '00:00:02.100'
WAITFOR DELAY @v
GO

INSERT INTO Timecheck2 (NAME) values('b')
GO

-- Expect WAITFOR DELAY: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:03'
            THEN 'WAITFOR DELAY: Failed'
        ELSE 'WAITFOR DELAY: Passed'
    END AS CheckResult
FROM Timecheck2
GO


-- test WAITFOR DELAY in PROCEDURE
INSERT INTO Timecheck3 (NAME) values('a')
GO

EXEC TimeDelay '00:00:02'
GO

INSERT INTO Timecheck3 (NAME) values('b')
GO

-- Expect WAITFOR DELAY: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:03'
            THEN 'WAITFOR DELAY: Failed'
        ELSE 'WAITFOR DELAY: Passed'
    END AS CheckResult
FROM Timecheck3
GO


-- test WAITFOR TIME
declare @pausetime datetime
declare @resumetime datetime
set @pausetime = current_timestamp
set @resumetime = @pausetime + '00:00:02'
INSERT INTO Timecheck4 values('a', @pausetime)
WAITFOR TIME @resumetime
GO

INSERT INTO Timecheck4 (NAME) values('b')
GO

-- Expect WAITFOR TIME: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:03'
            THEN 'WAITFOR Time: Failed'
        ELSE 'WAITFOR TIME: Passed'
    END AS CheckResult
FROM Timecheck4
GO

-- test WAITFOR TIME in Procedure
declare @pausetime datetime
declare @resumetime datetime
set @pausetime = current_timestamp
set @resumetime = @pausetime + '00:00:02'
INSERT INTO Timecheck5 values('a', @pausetime)
EXEC Wait2seconds @resumetime
GO

INSERT INTO Timecheck5 (NAME) values('b')
GO

-- Expect WAITFOR TIME: Passed
SELECT
    CASE
        WHEN (max(CheckTime) - min(CheckTime)) > '1900-01-01 00:00:03'
            THEN 'WAITFOR Time: Failed'
        ELSE 'WAITFOR TIME: Passed'
    END AS CheckResult
FROM Timecheck5
GO

EXEC sys.bbf_sleep_for '00:00:02'
GO

declare @resumetime datetime
set @resumetime = current_timestamp + '00:00:02'
EXEC sys.bbf_sleep_until @resumetime
GO