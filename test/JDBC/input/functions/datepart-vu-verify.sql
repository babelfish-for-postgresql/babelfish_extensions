-- sla_for_parallel_query_enforced 180000
SELECT DATEPART(dd, '07-18-2022')
GO

SELECT DATEPART(wk, '18 July 2022')
GO

SELECT DATEPART(yy, '07-18-2022')
GO

SELECT * FROM date_part_vu_prepare_view
GO

SELECT * FROM date_part_vu_prepare_func('07-18-2022')
GO

SELECT * FROM date_part_vu_prepare_func('18 July 2022')
GO

SELECT * FROM date_part_vu_prepare_func('7/18/2022')
GO

SELECT ISOWeek_3101(CAST('25 July 2022 01:23:45' AS datetime))
GO

-- should error out as expected
SELECT ISOWeek_3101('01-01-1790')
GO

EXECUTE date_part_vu_prepare_proc '07-18-2022'
GO

EXECUTE date_part_vu_prepare_proc '18 July 2022'
GO

EXECUTE date_part_vu_prepare_proc '7/18/2022'
GO

SELECT * FROM date_part_vu_prepare_sys_day_view
GO

SELECT * FROM date_part_vu_prepare_sys_day_func(CAST('07-18-2022' AS datetime))
GO

DECLARE @a datetime
SET @a = CAST('07-18-2022' AS datetime)
EXECUTE date_part_vu_prepare_proc @a
GO

-- time

-- min
SELECT DATEPART(dd, '00:00:00.0000000')
GO

-- max
SELECT DATEPART(wk, '23:59:59.9999999')
GO

-- invalid
SELECT DATEPART(wk, '23:59:66')
GO

SELECT DATEPART(hh, '01:01:01.1234567 AM')
GO

SELECT DATEPART(mm, '01:01:01.1234567 PM')
GO

SELECT DATEPART(ss, '01:01:01.1234567PM')
GO

SELECT DATEPART(wk, '01:01:01.1234567')
GO

SELECT DATEPART(hh, '01:01:01.1234567 +01:01')
GO

-- date

-- min
SELECT DATEPART(mm, '0001-01-01')
GO

-- max
SELECT DATEPART(ss, '9999-12-31')
GO

-- invalid
SELECT DATEPART(ss, '99999-12-31')
GO

SELECT DATEPART(dd, '07-18-2022')
GO

SELECT DATEPART(wk, '07/18/2022')
GO

SELECT DATEPART(hh, 'Jul 18, 22')
GO

SELECT DATEPART(mm, '18 July 2022')
GO

SELECT DATEPART(yy, '220101')
GO

-- datetime

-- min
SELECT DATEPART(mm, '01-01-1753 00:00:00.000')
GO

-- max
SELECT DATEPART(ss, '12-31-9999 23:59:59.997')
GO

-- invalid
SELECT DATEPART(dd, '01-01-00000 12:44:45.034')
GO

SELECT DATEPART(ss, 'Nov 1999 01 AM')
GO

SELECT DATEPART(yy, '220101 14:30')
GO

-- smalldatetime

-- min
SELECT DATEPART(mm, '01-01-1900 00:00:00')
GO

-- max
SELECT DATEPART(ss, '06-06-2079 23:59:59')
GO

-- invalid
SELECT DATEPART(dd, '01-01-1900 12:44:63')
GO

SELECT DATEPART(wk, '07/18/2022 12:35:00')
GO

SELECT DATEPART(hh, 'Jul 18, 22 01:01:00')
GO

SELECT DATEPART(yy, '18 July 2022 01:02:00')
GO

SELECT DATEPART(ss, 'Nov 1999 01:02:00')
GO

SELECT DATEPART(yy, '220101 14:30:00')
GO

-- datetime2

-- min
SELECT DATEPART(mm, '01-01-0001 00:00:00.0000000')
GO

-- max
SELECT DATEPART(ss, '12-31-9999 23:59:59.999999')
GO

-- invalid
SELECT DATEPART(dd, '01-01-00091 12:44:33.1234567')
GO

SELECT DATEPART(wk, '07/18/2022 12:35:00.0000001')
GO

SELECT DATEPART(hh, 'Jul 18, 22 01:01:00.1234567')
GO

SELECT DATEPART(yy, '18 July 2022 01:02:00.9876543')
GO

SELECT DATEPART(ss, 'Nov 1999 01:02:00.7651112')
GO

SELECT DATEPART(yy, '220101 14:30:00.97531086')
GO

-- datetimeoffset

-- min
SELECT DATEPART(mm, '01-01-0001 00:00:00.0000000 -14:00')
GO

-- max
SELECT DATEPART(ss, '12-31-9999 23:59:59.9999999 +14:00')
GO

-- invalid
SELECT DATEPART(dd, '01-01-12345 12:44:33.1234567 -14:01')
GO

SELECT DATEPART(wk, '07/18/2022 12:35:00.0000001 +4:56')
GO

SELECT DATEPART(hh, 'Jul 18, 22 01:01:00.1234567 -7:8')
GO

SELECT DATEPART(yy, '18 July 2022 01:02:00.9876543 +9:10')
GO

SELECT DATEPART(ss, 'Nov 1999 01:02:00.7651112 -11:12')
GO

SELECT DATEPART(yy, '220101 14:30:00.97531086 +13:14')
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

-- Analyze results
SELECT * FROM date_part_vu_prepare_TestResults
ORDER BY DataType, InputDate, TimeZone, DatePart;
GO

-- Check for any discrepancies
SELECT 
    DataType,
    InputDate,
    DatePart,
    COUNT(DISTINCT DatePartValue) AS UniqueDatePartValues,
    COUNT(DISTINCT DateName) AS UniqueDateNames
FROM date_part_vu_prepare_TestResults
GROUP BY DataType, InputDate, DatePart
HAVING 
    COUNT(DISTINCT DatePartValue) > 1 OR 
    COUNT(DISTINCT DateName) > 1;
GO

-- Reset Timezone
SELECT set_config('timezone', 'UTC', false)
GO