CREATE VIEW date_part_vu_prepare_view AS SELECT * FROM DATEPART(wk, '07-18-2022')
GO

CREATE FUNCTION date_part_vu_prepare_func(@date_str varchar(128))
RETURNS TABLE
AS
RETURN SELECT * FROM DATEPART(mm, @date_str);
GO

CREATE FUNCTION ISOweek_3101 (@date datetime)
RETURNS tinyint
AS
BEGIN
	DECLARE @ISOweek tinyint
	SET @ISOweek= DATEPART(wk,@date)+1-DATEPART(wk,CAST(DATEPART(yy,@date) as CHAR(4))+'0104')
	--Special cases: Jan 1-3 may belong to the previous year
	IF (@ISOweek=0)
		SET @ISOweek=dbo.ISOweek(CAST(DATEPART(yy,@date)-1 AS CHAR(4))+'12'+ CAST(24+DATEPART(DAY,@date) AS CHAR(2)))+1
	--Special case: Dec 29-31 may belong to the next year
	IF ((DATEPART(mm,@date)=12) AND ((DATEPART(dd,@date)-DATEPART(dw,@date))>= 28))
		SET @ISOweek=1
	RETURN(@ISOweek)
END
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

-- Test Case for Date Part Functions Timezone Invariance
CREATE TABLE date_part_vu_prepare_DateParts (DatePartName VARCHAR(20));
GO
CREATE TABLE date_part_vu_prepare_TestDates (
    TestDateTime DATETIME,
    TestDateTimeOffset DATETIMEOFFSET,
    TestDateTime2 DATETIME2,
    TestSmallDateTime SMALLDATETIME
);
GO
CREATE TABLE date_part_vu_prepare_TestTimezones (TimezoneName VARCHAR(50));
GO
CREATE TABLE date_part_vu_prepare_TestResults (
    TestCase VARCHAR(100),
    TimeZone VARCHAR(50),
    DataType VARCHAR(20),
    InputDate VARCHAR(50),
    DatePart VARCHAR(20),
    DatePartValue SQL_VARIANT,
    DateName NVARCHAR(100)
);
GO

-- -- Populate tables
INSERT INTO date_part_vu_prepare_DateParts (DatePartName) VALUES
('year'), ('quarter'), ('month'), ('dayofyear'), ('day'), 
('week'), ('weekday'), ('hour'), ('minute'), ('second'), 
('millisecond'), ('microsecond'), ('nanosecond'),
('tzoffset'), ('iso_week');
GO
INSERT INTO date_part_vu_prepare_TestDates VALUES 
('2025-01-01 05:30:45', '2025-01-01 05:30:45 +00:00', '2025-01-01 05:30:45.1234567', '2025-01-01 05:31:00'),
('2025-06-15 23:59:59', '2025-06-15 23:59:59 +00:00', '2025-06-15 23:59:59.9876543', '2025-06-15 23:59:00');
GO
INSERT INTO date_part_vu_prepare_TestTimezones (TimezoneName) VALUES
('UTC'),('America/New_York'), ('Europe/London'), ('Asia/Tokyo'), ('Africa/Nairobi');
GO

-- Test Case for Date Part Functions Timezone Invariance
DECLARE @timezone VARCHAR(50);
DECLARE @datepart VARCHAR(20);
DECLARE @datatype VARCHAR(20);
DECLARE @datecol VARCHAR(30);
DECLARE @testdate DATETIME;
DECLARE @sql NVARCHAR(MAX);

-- Cursor for timezones
DECLARE timezone_cursor CURSOR FOR SELECT TimezoneName FROM date_part_vu_prepare_TestTimezones;
OPEN timezone_cursor;
FETCH NEXT FROM timezone_cursor INTO @timezone;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Set the timezone
    EXEC('SELECT set_config(''timezone'', ''' + @timezone + ''', false)');

    -- Cursor for date parts
    DECLARE datepart_cursor CURSOR FOR SELECT DatePartName FROM date_part_vu_prepare_DateParts;
    OPEN datepart_cursor;
    FETCH NEXT FROM datepart_cursor INTO @datepart;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Cursor for data types
        DECLARE datatype_cursor CURSOR FOR 
        SELECT 'DATETIME', 'TestDateTime' UNION ALL
        SELECT 'DATETIMEOFFSET', 'TestDateTimeOffset' UNION ALL
        SELECT 'DATETIME2', 'TestDateTime2' UNION ALL
        SELECT 'SMALLDATETIME', 'TestSmallDateTime';
        OPEN datatype_cursor;
        FETCH NEXT FROM datatype_cursor INTO @datatype, @datecol;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Cursor for test dates
            DECLARE testdate_cursor CURSOR FOR SELECT TestDateTime FROM date_part_vu_prepare_TestDates;
            OPEN testdate_cursor;
            FETCH NEXT FROM testdate_cursor INTO @testdate;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @sql = N'
                INSERT INTO date_part_vu_prepare_TestResults (TestCase, TimeZone, DataType, InputDate, DatePart, DatePartValue, DateName)
                SELECT 
                    ''Test: '' + CONVERT(VARCHAR, ' + @datecol + ', 120) + '' in ' + @timezone + ''' AS TestCase,
                    ''' + @timezone + ''' AS TimeZone,
                    ''' + @datatype + ''' AS DataType,
                    CONVERT(VARCHAR, ' + @datecol + ', 120) AS InputDate,
                    ''' + @datepart + ''' AS DatePart,
                    DATEPART(' + @datepart + ', ' + @datecol + ') AS DatePartValue,
                    DATENAME(' + @datepart + ', ' + @datecol + ') AS DateName
                FROM date_part_vu_prepare_TestDates
                WHERE TestDateTime = ''' + CONVERT(VARCHAR, @testdate, 120) + '''';

                EXEC sp_executesql @sql;

                FETCH NEXT FROM testdate_cursor INTO @testdate;
            END

            CLOSE testdate_cursor;
            DEALLOCATE testdate_cursor;

            FETCH NEXT FROM datatype_cursor INTO @datatype, @datecol;
        END

        CLOSE datatype_cursor;
        DEALLOCATE datatype_cursor;

        FETCH NEXT FROM datepart_cursor INTO @datepart;
    END

    CLOSE datepart_cursor;
    DEALLOCATE datepart_cursor;

    FETCH NEXT FROM timezone_cursor INTO @timezone;
END

CLOSE timezone_cursor;
DEALLOCATE timezone_cursor;
GO


-- Reset Timezone
SELECT set_config('timezone', 'UTC', false)
GO