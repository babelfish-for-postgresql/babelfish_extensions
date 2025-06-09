-- sla 200000
-- 1. Basic Testing:
-- Create SmalldateTimeTest table
CREATE TABLE SmalldateTimeTest (
    ID INT IDENTITY PRIMARY KEY,
    SmalldateTimeCol SMALLDATETIME
);
GO

-- Empty/NULL values
INSERT INTO SmalldateTimeTest (SmalldateTimeCol) VALUES (NULL);
GO
Declare @a smalldatetime;
INSERT INTO SmalldateTimeTest (SmalldateTimeCol) VALUES (@a), ('');
GO
SELECT * FROM SmalldateTimeTest WHERE SmalldateTimeCol IS NULL ORDER BY ID;
GO
SELECT * FROM SmalldateTimeTest ORDER BY ID;
GO

-- Default values
CREATE TABLE SmalldateTimeDefaultTest (
    ID INT PRIMARY KEY,
    DateCol DATE
);
INSERT INTO SmalldateTimeDefaultTest VALUES (1, CAST('19:00:00' As smalldatetime));
INSERT INTO SmalldateTimeDefaultTest VALUES (2, CAST('1910-01-01' As smalldatetime));
SELECT * FROM SmalldateTimeDefaultTest ORDER BY ID;
GO

-- Character length
DECLARE @d SMALLDATETIME = '  2023-06-15 19:00:00  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO
DECLARE @d SMALLDATETIME = '  2023-06-15 19:00:00.004  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO
DECLARE @d SMALLDATETIME = '  2023-06-15  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

-- Edge case values
DECLARE @d1 SMALLDATETIME = '1753-01-01 00:00:00';
SELECT @d1;
GO
DECLARE @d2 SMALLDATETIME = '1753-01-01 23:59:59';
SELECT @d2;
GO
DECLARE @d3 SMALLDATETIME = '2079-06-06 00:00:00';
SELECT @d3;
GO
DECLARE @d4 SMALLDATETIME = '2079-06-06 23:59:58';
SELECT @d4;
GO
DECLARE @d5 SMALLDATETIME = '2079-06-06 23:59:59';
SELECT @d5;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d SMALLDATETIME;
SET @d = '2023-06-15 19:00:00';
SELECT @d, CAST('2023-06-15 19:00:00' AS SMALLDATETIME), CONVERT(SMALLDATETIME, '2023-06-15 19:00:00');
GO

-- DATEFORMAT tests
-- Create a test table
CREATE TABLE SmalldateTimeFormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ParsedDate SMALLDATETIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertSmalldateTimeTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO SmalldateTimeFormatTest (Description, InputString, ParsedDate)
        VALUES (@Description, @InputString, CAST(@InputString AS SMALLDATETIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Numeric Formats with All DATEFORMAT Settings
SET DATEFORMAT mdy;
GO
EXEC InsertSmalldateTimeTest 'MDY Slash Full', '04/15/1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'MDY Slash Short', '4/15/96 14:30';
GO
EXEC InsertSmalldateTimeTest 'MDY Hyphen Full', '04-15-1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'MDY Hyphen Short', '4-15-96 14:30';
GO
EXEC InsertSmalldateTimeTest 'MDY Period Full', '04.15.1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'MDY Period Short', '4.15.96 14:30';
GO
-- Test rounding behavior with seconds
EXEC InsertSmalldateTimeTest 'MDY Round Up', '04/15/1996 14:30:31';
GO
EXEC InsertSmalldateTimeTest 'MDY Round Down', '04/15/1996 14:30:29';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertSmalldateTimeTest 'DMY Slash Full', '15/04/1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'DMY Slash Short', '15/4/96 14:30';
GO
EXEC InsertSmalldateTimeTest 'DMY Hyphen Full', '15-04-1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'DMY Hyphen Short', '15-4-96 14:30';
GO
EXEC InsertSmalldateTimeTest 'DMY Period Full', '15.04.1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'DMY Period Short', '15.4.96 14:30';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertSmalldateTimeTest 'YMD Slash Full', '1996/04/15 14:30';
GO
EXEC InsertSmalldateTimeTest 'YMD Slash Short', '96/4/15 14:30';
GO
EXEC InsertSmalldateTimeTest 'YMD Hyphen Full', '1996-04-15 14:30';
GO
EXEC InsertSmalldateTimeTest 'YMD Hyphen Short', '96-4-15 14:30';
GO
EXEC InsertSmalldateTimeTest 'YMD Period Full', '1996.04.15 14:30';
GO
EXEC InsertSmalldateTimeTest 'YMD Period Short', '96.4.15 14:30';
GO

SET DATEFORMAT myd;
GO
EXEC InsertSmalldateTimeTest 'MYD Slash Full', '04/1996/15 14:30';
GO
EXEC InsertSmalldateTimeTest 'MYD Slash Short', '4/96/15 14:30';
GO

SET DATEFORMAT dym;
GO
EXEC InsertSmalldateTimeTest 'DYM Slash Full', '15/1996/04 14:30';
GO
EXEC InsertSmalldateTimeTest 'DYM Slash Short', '15/96/4 14:30';
GO

SET DATEFORMAT ydm;
GO
EXEC InsertSmalldateTimeTest 'YDM Slash Full', '1996/15/04 14:30';
GO
EXEC InsertSmalldateTimeTest 'YDM Slash Short', '96/15/4 14:30';
GO

-- 2. Time Formats (All Valid Variations)
EXEC InsertSmalldateTimeTest 'Time 24hr', '1996-04-15 14:30';
GO
EXEC InsertSmalldateTimeTest 'Time AM', '1996-04-15 09:30 AM';
GO
EXEC InsertSmalldateTimeTest 'Time PM', '1996-04-15 02:30 PM';
GO
EXEC InsertSmalldateTimeTest 'Time AM Short', '1996-04-15 9 AM';
GO
EXEC InsertSmalldateTimeTest 'Time PM Short', '1996-04-15 2 PM';
GO
EXEC InsertSmalldateTimeTest 'Time AM No Space', '1996-04-15 9:30AM';
GO
EXEC InsertSmalldateTimeTest 'Time PM No Space', '1996-04-15 2:30PM';
GO
EXEC InsertSmalldateTimeTest 'Midnight', '1996-04-15 00:00';
GO
EXEC InsertSmalldateTimeTest 'Noon', '1996-04-15 12:00';
GO

-- 3. Alphabetical Formats
-- Full month name variations
EXEC InsertSmalldateTimeTest 'Alpha Full MDY Comma', 'April 15, 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Full MDY No Comma', 'April 15 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Full DMY', '15 April 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Full YMD', '1996 April 15 14:30';
GO

-- Abbreviated month name variations
EXEC InsertSmalldateTimeTest 'Alpha Abbr MDY Comma', 'Apr 15, 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Abbr MDY No Comma', 'Apr 15 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Abbr DMY', '15 Apr 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Alpha Abbr YMD', '1996 Apr 15 14:30';
GO

-- 4. ISO 8601 Formats
EXEC InsertSmalldateTimeTest 'ISO8601 Basic', '19960415T1430';
GO
EXEC InsertSmalldateTimeTest 'ISO8601 Extended', '1996-04-15T14:30';
GO
EXEC InsertSmalldateTimeTest 'ISO8601 Basic With Space', '19960415 14:30';
GO
EXEC InsertSmalldateTimeTest 'ISO8601 Extended With Space', '1996-04-15 14:30';
GO

-- 5. ODBC Canonical Formats
EXEC InsertSmalldateTimeTest 'ODBC Timestamp', '{ts ''1996-04-15 14:30''}';
GO
EXEC InsertSmalldateTimeTest 'ODBC Date and Time', '{d ''1996-04-15''} {t ''14:30''}';
GO

-- 6. Language-Specific Formats
SET LANGUAGE French;
GO
EXEC InsertSmalldateTimeTest 'French Full', N'15 avril 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'French Abbreviated', N'15 avr. 1996 14:30';
GO

SET LANGUAGE German;
GO
EXEC InsertSmalldateTimeTest 'German Full', N'15. April 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'German Abbreviated', N'15. Apr 1996 14:30';
GO

SET LANGUAGE Spanish;
GO
EXEC InsertSmalldateTimeTest 'Spanish Full', N'15 de abril de 1996 14:30';
GO
EXEC InsertSmalldateTimeTest 'Spanish Abbreviated', N'15 abr. 1996 14:30';
GO

SET LANGUAGE us_english;
GO

-- 7. Edge Cases and Boundary Tests
EXEC InsertSmalldateTimeTest 'Min SmallDateTime', '1900-01-01 00:00';
GO
EXEC InsertSmalldateTimeTest 'Max SmallDateTime', '2079-06-06 23:59';
GO
EXEC InsertSmalldateTimeTest 'Leap Year', '2000-02-29 14:30';
GO
EXEC InsertSmalldateTimeTest 'Century Transition', '2000-01-01 00:00';
GO
-- Minute rounding tests
EXEC InsertSmalldateTimeTest 'Round 14:30:29', '1996-04-15 14:30:29';
GO
EXEC InsertSmalldateTimeTest 'Round 14:30:30', '1996-04-15 14:30:30';
GO
EXEC InsertSmalldateTimeTest 'Round 14:30:31', '1996-04-15 14:30:31';
GO

-- 8. Invalid Formats (These should fail)
EXEC InsertSmalldateTimeTest 'Invalid Before 1900', '1899-12-31 14:30';
GO
EXEC InsertSmalldateTimeTest 'Invalid After 2079', '2079-06-07 00:00';
GO
EXEC InsertSmalldateTimeTest 'Invalid Month', '1996-13-15 14:30';
GO
EXEC InsertSmalldateTimeTest 'Invalid Day', '1996-04-31 14:30';
GO
EXEC InsertSmalldateTimeTest 'Invalid Hour', '1996-04-15 24:30';
GO
EXEC InsertSmalldateTimeTest 'Invalid Minute', '1996-04-15 14:60';
GO
-- These should be rounded to minutes
EXEC InsertSmalldateTimeTest 'Invalid Seconds Specified', '1996-04-15 14:30:20';
GO
EXEC InsertSmalldateTimeTest 'Invalid Milliseconds Specified', '1996-04-15 14:30:20.123';
GO

-- 9. Two-Digit Year Tests
EXEC InsertSmalldateTimeTest 'Two-Digit Year 20th Century', '04/15/96 14:30';
GO
EXEC InsertSmalldateTimeTest 'Two-Digit Year 21st Century', '04/15/05 14:30';
GO

-- 10. Special Time Cases
EXEC InsertSmalldateTimeTest 'Midnight Start', '1996-04-15 00:00';
GO
EXEC InsertSmalldateTimeTest 'Midnight End', '1996-04-15 23:59';
GO
EXEC InsertSmalldateTimeTest 'Noon', '1996-04-15 12:00';
GO
EXEC InsertSmalldateTimeTest 'Almost Midnight', '1996-04-15 23:59:59'; -- Should round to next day
GO

-- Additional combinations
SET DATEFORMAT mdy;
GO

-- 1. Basic date variations with time
EXEC InsertSmalldateTimeTest 'SDT - Standard 24hr', '2023,06,05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT - Standard AM', '2023,06,05 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT - Standard PM', '2023,06,05 2:30 PM';
GO

-- d,mm,yyyy variations with time
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Comma with time', '5,06,2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Comma with AM', '5,06,2023 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Comma with PM', '5,06,2023 2:30 PM';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Period with time', '5.06.2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Hyphen with time', '5-06-2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - d,mm,yyyy - Space with time', '5 06 2023 14:30';
GO

-- dd,m,yy variations with time
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Comma with time', '05,6,23 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Comma with AM', '05,6,23 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Comma with PM', '05,6,23 2:30 PM';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Period with time', '05.6.23 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Hyphen with time', '05-6-23 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT MDY - dd,m,yy - Space with time', '05 6 23 14:30';
GO

SET DATEFORMAT dmy;
GO

-- DMY variations with time
EXEC InsertSmalldateTimeTest 'SDT DMY - d,mm,yyyy - Full time', '5,06,2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT DMY - d,mm,yyyy - AM time', '5,06,2023 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT DMY - d,mm,yyyy - PM time', '5,06,2023 2:30 PM';
GO
EXEC InsertSmalldateTimeTest 'SDT DMY - dd,m,yy - Basic time', '05,6,23 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT DMY - d,m,y - Short time AM', '5,6,3 10:30AM';
GO
EXEC InsertSmalldateTimeTest 'SDT DMY - d,m,y - Short time PM', '5,6,3 2:30PM';
GO

SET DATEFORMAT ymd;
GO

-- YMD variations with time
EXEC InsertSmalldateTimeTest 'SDT YMD - yyyy,m,d - Full time', '2023,6,5 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT YMD - yyyy,m,d - AM time', '2023,6,5 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT YMD - yyyy,m,d - PM time', '2023,6,5 2:30 PM';
GO
EXEC InsertSmalldateTimeTest 'SDT YMD - yy,mm,dd - Basic time', '23,06,05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT YMD - y,m,d - AM time', '3,6,5 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT YMD - y,m,d - PM time', '3,6,5 2:30 PM';
GO

-- ISO 8601 style combinations
EXEC InsertSmalldateTimeTest 'SDT ISO - Basic with T', '2023,06,05T14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT ISO - Extended with T', '2023-06-05T14:30';
GO

-- Mixed format variations
EXEC InsertSmalldateTimeTest 'SDT Mixed - Date/Time seps', '2023/06/05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Mixed - Date.Time seps', '2023.06.05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Mixed - Date Space seps', '2023 06 05 14:30';
GO

-- Alphabetical month formats with time
SET DATEFORMAT mdy;
GO
EXEC InsertSmalldateTimeTest 'SDT Alpha - Full month with time', 'June 5, 2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Alpha - Abbr month with time', 'Jun 5, 2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Alpha - Full month AM', 'June 5, 2023 10:30 AM';
GO
EXEC InsertSmalldateTimeTest 'SDT Alpha - Full month PM', 'June 5, 2023 2:30 PM';
GO

-- Language-specific formats with time
SET LANGUAGE French;
GO
EXEC InsertSmalldateTimeTest 'SDT French - Full with time', N'5 juin 2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT French - Abbr with time', N'5 juin. 2023 14:30';
GO

SET LANGUAGE German;
GO
EXEC InsertSmalldateTimeTest 'SDT German - Full with time', N'5. Juni 2023 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT German - Abbr with time', N'5. Jun 2023 14:30';
GO

SET LANGUAGE us_english;
GO

-- ODBC format variations
EXEC InsertSmalldateTimeTest 'SDT ODBC - Timestamp', '{ts ''2023-06-05 14:30''}';
GO
EXEC InsertSmalldateTimeTest 'SDT ODBC - Date and Time', '{d ''2023-06-05''} {t ''14:30''}';
GO

-- Edge cases
EXEC InsertSmalldateTimeTest 'SDT Edge - Min DateTime', '1900-01-01 00:00';
GO
EXEC InsertSmalldateTimeTest 'SDT Edge - Max DateTime', '2079-06-06 23:59';
GO
EXEC InsertSmalldateTimeTest 'SDT Edge - Midnight', '2023-06-05 00:00';
GO
EXEC InsertSmalldateTimeTest 'SDT Edge - Last Minute', '2023-06-05 23:59';
GO
EXEC InsertSmalldateTimeTest 'SDT Edge - Noon', '2023-06-05 12:00';
GO
EXEC InsertSmalldateTimeTest 'SDT Edge - Leap Year', '2024-02-29 14:30';
GO

-- AM/PM variations
EXEC InsertSmalldateTimeTest 'SDT AMPM - Standard', '2023-06-05 2:30 PM';
GO
EXEC InsertSmalldateTimeTest 'SDT AMPM - No space', '2023-06-05 2:30PM';
GO
EXEC InsertSmalldateTimeTest 'SDT AMPM - Lowercase', '2023-06-05 2:30 pm';
GO
EXEC InsertSmalldateTimeTest 'SDT AMPM - Mixed case', '2023-06-05 2:30 Pm';
GO

-- Rounding tests (should round to nearest minute)
EXEC InsertSmalldateTimeTest 'SDT Round - 14:30:29', '2023-06-05 14:30:29';
GO
EXEC InsertSmalldateTimeTest 'SDT Round - 14:30:31', '2023-06-05 14:30:31';
GO
EXEC InsertSmalldateTimeTest 'SDT Round - 14:30:45', '2023-06-05 14:30:45';
GO

-- Invalid formats (these should fail)
EXEC InsertSmalldateTimeTest 'SDT Invalid - Before 1900', '1899-12-31 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Invalid - After 2079', '2079-06-07 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT Invalid - Bad Hour', '2023-06-05 24:00';
GO
EXEC InsertSmalldateTimeTest 'SDT Invalid - Bad Minute', '2023-06-05 14:60';
GO
EXEC InsertSmalldateTimeTest 'SDT Invalid - With Seconds', '2023-06-05 14:30:20';
GO
EXEC InsertSmalldateTimeTest 'SDT Invalid - With MS', '2023-06-05 14:30:00.123';
GO

-- Two-digit year cutoff tests
EXEC InsertSmalldateTimeTest 'SDT TwoDigit - Current Century', '23-06-05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT TwoDigit - Previous Century', '99-06-05 14:30';
GO

-- Different time separators
EXEC InsertSmalldateTimeTest 'SDT TimeSep - Colon', '2023-06-05 14:30';
GO
EXEC InsertSmalldateTimeTest 'SDT TimeSep - Period', '2023-06-05 14.30';
GO
EXEC InsertSmalldateTimeTest 'SDT TimeSep - No Sep', '2023-06-05 1430';
GO

-- Helper procedure to insert test cases for SMALLDATETIME with collation
CREATE PROCEDURE InsertSmallDateTimeTest1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO SmalldateTimeFormatTest (Description, InputString, Collation, ParsedSmallDateTime)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS SMALLDATETIME))';
        
        EXEC sp_executesql @SQL, 
             N'@Description NVARCHAR(100), @InputString NVARCHAR(50), @Collation NVARCHAR(100)',
             @Description, @InputString, @Collation;
        
        PRINT 'Success: ' + @Description + ' - Collation: ' + @Collation;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - Collation: ' + @Collation + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Procedure to test each format with multiple collations
CREATE PROCEDURE TestSmallDateTimeFormat
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    DECLARE @Collations TABLE (Collation NVARCHAR(100));
    INSERT INTO @Collations (Collation) VALUES 
    ('SQL_Latin1_General_CP1_CI_AS'),
    ('Latin1_General_CI_AS'),
    ('Latin1_General_CS_AS'),
    ('Latin1_General_100_CI_AS'),
    ('Latin1_General_100_CS_AS'),
    ('Chinese_PRC_CI_AS'),
    ('Cyrillic_General_CI_AS'),
    ('Japanese_CI_AS');

    DECLARE @Collation NVARCHAR(100);
    
    DECLARE collation_cursor CURSOR FOR 
    SELECT Collation FROM @Collations;
    
    OPEN collation_cursor;
    FETCH NEXT FROM collation_cursor INTO @Collation;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC InsertSmallDateTimeTest1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Now run tests with different collations for each format

-- Standard formats with time
EXEC TestSmallDateTimeFormat 'SDT Standard - YYYY-MM-DD HH:MI', '2023-06-16 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT Standard - YYYYMMDD HH:MI', '20230616 14:30';
GO

-- Month-day-year formats with time
SET DATEFORMAT mdy;
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Slash 24hr', '6/16/2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Slash AM', '6/16/2023 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Slash PM', '6/16/2023 2:30 PM';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Hyphen 24hr', '6-16-2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Period AM', '6.16.2023 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - Space PM', '6 16 2023 2:30 PM';
GO

-- Day-month-year formats with time
SET DATEFORMAT dmy;
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - Slash 24hr', '16/6/2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - Hyphen AM', '16-6-2023 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - Period PM', '16.6.2023 2:30 PM';
GO

-- Year-month-day formats with time
SET DATEFORMAT ymd;
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - Slash 24hr', '2023/6/16 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - Hyphen AM', '2023-6-16 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - Period PM', '2023.6.16 2:30 PM';
GO

-- Alphabetical formats with time
SET DATEFORMAT mdy;
GO
EXEC TestSmallDateTimeFormat 'SDT Alpha - Full month 24hr', 'June 16, 2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT Alpha - Full month AM', 'June 16, 2023 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT Alpha - Abbr PM', 'Jun 16, 2023 2:30 PM';
GO

-- ISO 8601 formats with time
EXEC TestSmallDateTimeFormat 'SDT ISO 8601 - Basic', '20230616T1430';
GO
EXEC TestSmallDateTimeFormat 'SDT ISO 8601 - Extended', '2023-06-16T14:30';
GO

-- ODBC canonical format with time
EXEC TestSmallDateTimeFormat 'SDT ODBC canonical', '{ts ''2023-06-16 14:30''}';
GO

-- Different time precision tests (should round to nearest minute)
EXEC TestSmallDateTimeFormat 'SDT Time - Hours only', '2023-06-16 14';
GO
EXEC TestSmallDateTimeFormat 'SDT Time - With Seconds', '2023-06-16 14:30:29';
GO
EXEC TestSmallDateTimeFormat 'SDT Time - With Seconds Round Up', '2023-06-16 14:30:31';
GO

-- Language-specific formats with time
SET LANGUAGE French;
GO
EXEC TestSmallDateTimeFormat 'SDT French - Full with time', N'16 juin 2023 14:30';
GO

SET LANGUAGE German;
GO
EXEC TestSmallDateTimeFormat 'SDT German - Full with time', N'16. Juni 2023 14:30';
GO

SET LANGUAGE us_english;
GO

-- Time separator variations
EXEC TestSmallDateTimeFormat 'SDT Time sep - Colon', '2023-06-16 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT Time sep - Period', '2023-06-16 14.30';
GO

-- Edge cases with time
EXEC TestSmallDateTimeFormat 'SDT Edge - Minimum', '1900-01-01 00:00';
GO
EXEC TestSmallDateTimeFormat 'SDT Edge - Maximum', '2079-06-06 23:59';
GO
EXEC TestSmallDateTimeFormat 'SDT Edge - Leap Year', '2024-02-29 14:30';
GO

-- Additional combinations with time
SET DATEFORMAT mdy;
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - d,mm,yyyy 24hr', '5,06,2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - d,mm,yyyy AM', '5,06,2023 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT MDY - d,mm,yyyy PM', '5,06,2023 2:30 PM';
GO

SET DATEFORMAT dmy;
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - d,mm,yyyy 24hr', '5,06,2023 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - dd,m,yy AM', '05.6.23 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT DMY - d,m,yy PM', '5-6-23 2:30 PM';
GO

SET DATEFORMAT ymd;
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - yyyy,m,d 24hr', '2023,6,5 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - yy,mm,dd AM', '23.06.05 10:30 AM';
GO
EXEC TestSmallDateTimeFormat 'SDT YMD - y,m,d PM', '3-6-5 2:30 PM';
GO

-- Invalid formats (these should fail across all collations)
EXEC TestSmallDateTimeFormat 'SDT Invalid - Before 1900', '1899-12-31 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT Invalid - After 2079', '2079-06-07 14:30';
GO
EXEC TestSmallDateTimeFormat 'SDT Invalid - Bad Hour', '2023-06-16 24:00';
GO
EXEC TestSmallDateTimeFormat 'SDT Invalid - Bad Minute', '2023-06-16 14:60';
GO
EXEC TestSmallDateTimeFormat 'SDT Invalid - With Seconds', '2023-06-16 14:30:20';
GO
EXEC TestSmallDateTimeFormat 'SDT Invalid - With MS', '2023-06-16 14:30:00.123';
GO

-- Display results
SELECT * FROM SmalldateTimeFormatTest ORDER BY ID;
GO

-- Create a test table
CREATE TABLE SmallDateTimeConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedSmallDateTime SMALLDATETIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertSmallDateTimeConversionTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO SmallDateTimeConversionTest (Description, InputString, ConvertedSmallDateTime)
        VALUES (@Description, @InputString, CAST(@InputString AS SMALLDATETIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC Formats
EXEC InsertSmallDateTimeConversionTest 'ODBC DATE', '{d ''2023-06-16''}';
GO
EXEC InsertSmallDateTimeConversionTest 'ODBC TIME', '{t ''12:34''}';
GO
EXEC InsertSmallDateTimeConversionTest 'ODBC DATETIME', '{ts ''2023-06-16 12:34''}';
GO

-- ISO 8601 Formats
EXEC InsertSmallDateTimeConversionTest 'ISO8601 Basic', '20230616T1234';
GO
EXEC InsertSmallDateTimeConversionTest 'ISO8601 Extended', '2023-06-16T12:34';
GO
EXEC InsertSmallDateTimeConversionTest 'ISO8601 Basic with space', '20230616 12:34';
GO
EXEC InsertSmallDateTimeConversionTest 'ISO8601 Extended with space', '2023-06-16 12:34';
GO

-- Standard DateTime Formats
EXEC InsertSmallDateTimeConversionTest 'Standard 24hr', '2023-06-16 12:34';
GO
EXEC InsertSmallDateTimeConversionTest 'Standard 12hr AM', '2023-06-16 10:34 AM';
GO
EXEC InsertSmallDateTimeConversionTest 'Standard 12hr PM', '2023-06-16 2:34 PM';
GO

-- Different Time Precisions (should round to nearest minute)
EXEC InsertSmallDateTimeConversionTest 'Time - Hours only', '2023-06-16 14';
GO
EXEC InsertSmallDateTimeConversionTest 'Time - Hours Minutes', '2023-06-16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Time - With Seconds Round Down', '2023-06-16 14:30:29';
GO
EXEC InsertSmallDateTimeConversionTest 'Time - With Seconds Round Up', '2023-06-16 14:30:31';
GO

-- Different Date Separators with Time
EXEC InsertSmallDateTimeConversionTest 'Date Slash with Time', '2023/06/16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Date Hyphen with Time', '2023-06-16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Date Period with Time', '2023.06.16 14:30';
GO

-- Different Time Separators
EXEC InsertSmallDateTimeConversionTest 'Time Colon Sep', '2023-06-16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Time Period Sep', '2023-06-16 14.30';
GO

-- Alphabetic Month Formats
EXEC InsertSmallDateTimeConversionTest 'Full Month Name', 'June 16, 2023 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Abbreviated Month', 'Jun 16, 2023 14:30';
GO

-- Different Date Formats with Time
SET DATEFORMAT mdy;
GO
EXEC InsertSmallDateTimeConversionTest 'MDY Format', '06/16/2023 14:30';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertSmallDateTimeConversionTest 'DMY Format', '16/06/2023 14:30';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertSmallDateTimeConversionTest 'YMD Format', '2023/06/16 14:30';
GO

SET DATEFORMAT mdy;
GO

-- Minute Rounding Tests
EXEC InsertSmallDateTimeConversionTest 'Round Down 29 sec', '2023-06-16 14:30:29';
GO
EXEC InsertSmallDateTimeConversionTest 'Round Up 31 sec', '2023-06-16 14:30:31';
GO
EXEC InsertSmallDateTimeConversionTest 'Round Middle 30 sec', '2023-06-16 14:30:30';
GO

-- Edge Cases
EXEC InsertSmallDateTimeConversionTest 'Minimum SmallDateTime', '1900-01-01 00:00';
GO
EXEC InsertSmallDateTimeConversionTest 'Maximum SmallDateTime', '2079-06-06 23:59';
GO
EXEC InsertSmallDateTimeConversionTest 'Leap Year DateTime', '2024-02-29 14:30';
GO

-- Language-Specific Formats
SET LANGUAGE French;
GO
EXEC InsertSmallDateTimeConversionTest 'French DateTime', N'16 juin 2023 14:30';
GO

SET LANGUAGE German;
GO
EXEC InsertSmallDateTimeConversionTest 'German DateTime', N'16. Juni 2023 14:30';
GO

SET LANGUAGE us_english;
GO

-- AM/PM Variations
EXEC InsertSmallDateTimeConversionTest 'AM Time', '2023-06-16 09:30 AM';
GO
EXEC InsertSmallDateTimeConversionTest 'PM Time', '2023-06-16 09:30 PM';
GO
EXEC InsertSmallDateTimeConversionTest 'Noon', '2023-06-16 12:00 PM';
GO
EXEC InsertSmallDateTimeConversionTest 'Midnight', '2023-06-16 12:00 AM';
GO

-- Two-Digit Year Tests
EXEC InsertSmallDateTimeConversionTest 'Two-Digit Year Current Century', '23-06-16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Two-Digit Year Previous Century', '99-06-16 14:30';
GO

-- Invalid Conversions (these should fail)
EXEC InsertSmallDateTimeConversionTest 'Invalid - Before 1900', '1899-12-31 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Invalid - After 2079', '2079-06-07 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Invalid Hour', '2023-06-16 24:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Invalid Minute', '2023-06-16 14:60';
GO
EXEC InsertSmallDateTimeConversionTest 'Invalid with Seconds', '2023-06-16 14:30:20';
GO
EXEC InsertSmallDateTimeConversionTest 'Invalid with Milliseconds', '2023-06-16 14:30:20.123';
GO

-- Mixed Format Tests
EXEC InsertSmallDateTimeConversionTest 'Mixed Sep DateTime', '2023/06-16 14:30';
GO
EXEC InsertSmallDateTimeConversionTest 'Mixed Time Format', '2023-06-16 14:30PM';
GO
EXEC InsertSmallDateTimeConversionTest 'Mixed Style', '2023-June-16 14:30';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputString,
    ConvertedSmallDateTime,
    FORMAT(ConvertedSmallDateTime, 'yyyy-MM-dd HH:mm') as FormattedSmallDateTime
FROM SmallDateTimeConversionTest 
ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'smalldatetime';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'smalldatetime' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- AT TIME ZONE

-- Create a test table for SMALLDATETIME with time zones
CREATE TABLE SmallDateTimeZoneTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputSmallDateTime SMALLDATETIME,
    TimeZone NVARCHAR(100),
    Result NVARCHAR(MAX)
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertSmallDateTimeZoneTest
    @Description NVARCHAR(100),
    @InputSmallDateTime SMALLDATETIME,
    @TimeZone NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @Result NVARCHAR(MAX);
        SET @Result = CAST(@InputSmallDateTime AT TIME ZONE @TimeZone AS NVARCHAR(MAX));
        
        INSERT INTO SmallDateTimeZoneTest (Description, InputSmallDateTime, TimeZone, Result)
        VALUES (@Description, @InputSmallDateTime, @TimeZone, @Result);
        
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        INSERT INTO SmallDateTimeZoneTest (Description, InputSmallDateTime, TimeZone, Result)
        VALUES (@Description, @InputSmallDateTime, @TimeZone, ERROR_MESSAGE());
        
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Standard time tests
EXEC InsertSmallDateTimeZoneTest 'SDT Midnight UTC', '2023-06-16 00:00', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Noon UTC', '2023-06-16 12:00', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Evening UTC', '2023-06-16 18:30', 'UTC';
GO

-- Different time zones with specific times
EXEC InsertSmallDateTimeZoneTest 'SDT Morning PST', '2023-06-16 09:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Afternoon EST', '2023-06-16 14:30', 'Eastern Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Evening CET', '2023-06-16 20:30', 'Central European Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Night JST', '2023-06-16 23:30', 'Tokyo Standard Time';
GO

-- DST transition times
EXEC InsertSmallDateTimeZoneTest 'SDT DST Start PST Before', '2023-03-12 01:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT DST Start PST During', '2023-03-12 02:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT DST Start PST After', '2023-03-12 03:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT DST End PST Before', '2023-11-05 01:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT DST End PST During', '2023-11-05 02:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT DST End PST After', '2023-11-05 03:30', 'Pacific Standard Time';
GO

-- Summer times
EXEC InsertSmallDateTimeZoneTest 'SDT Summer Morning PST', '2023-07-15 09:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Summer Afternoon EST', '2023-07-15 14:30', 'Eastern Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Summer Evening CET', '2023-07-15 20:30', 'Central European Standard Time';
GO

-- Winter times
EXEC InsertSmallDateTimeZoneTest 'SDT Winter Morning PST', '2023-12-15 09:30', 'Pacific Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Winter Afternoon EST', '2023-12-15 14:30', 'Eastern Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Winter Evening CET', '2023-12-15 20:30', 'Central European Standard Time';
GO

-- Edge cases
EXEC InsertSmallDateTimeZoneTest 'SDT Min DateTime UTC', '1900-01-01 00:00', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Max DateTime UTC', '2079-06-06 23:59', 'UTC';
GO

-- Time zones with different offsets
EXEC InsertSmallDateTimeZoneTest 'SDT IST Midnight', '2023-06-16 00:00', 'India Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT NZ Noon', '2023-06-16 12:00', 'New Zealand Standard Time';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Saudi Night', '2023-06-16 23:00', 'Saudi Arabia Standard Time';
GO

-- Cross day boundary tests
EXEC InsertSmallDateTimeZoneTest 'SDT Day Boundary 1', '2023-06-16 23:30', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Day Boundary 2', '2023-06-16 00:30', 'UTC';
GO

-- Month boundary tests
EXEC InsertSmallDateTimeZoneTest 'SDT Month Boundary 1', '2023-06-30 23:30', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Month Boundary 2', '2023-07-01 00:30', 'UTC';
GO

-- Year boundary tests
EXEC InsertSmallDateTimeZoneTest 'SDT Year Boundary 1', '2023-12-31 23:30', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Year Boundary 2', '2024-01-01 00:30', 'UTC';
GO

-- Leap year tests
EXEC InsertSmallDateTimeZoneTest 'SDT Leap Year Eve', '2024-02-28 23:30', 'UTC';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT Leap Year Day', '2024-02-29 00:30', 'UTC';
GO

-- Invalid scenarios
EXEC InsertSmallDateTimeZoneTest 'SDT Invalid Time Zone', '2023-06-16 12:00', 'Invalid Time Zone';
GO

EXEC InsertSmallDateTimeZoneTest 'SDT NULL Time Zone', '2023-06-16 12:00', NULL;
GO

-- Before minimum SMALLDATETIME (should fail)
EXEC InsertSmallDateTimeZoneTest 'SDT Before Min Date', '1899-12-31 23:59', 'UTC';
GO

-- After maximum SMALLDATETIME (should fail)
EXEC InsertSmallDateTimeZoneTest 'SDT After Max Date', '2079-06-06 23:60', 'UTC';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputSmallDateTime,
    TimeZone,
    Result,
    CASE 
        WHEN ISDATE(Result) = 1 THEN 'Valid DateTime'
        ELSE 'Invalid/Error'
    END AS ResultStatus
FROM SmallDateTimeZoneTest 
ORDER BY ID;
GO

-- different timezone
select set_config('timezone', 'Asia/Kolkata', false);
GO
SELECT CAST('2023-06-15 19:00:00' AS SMALLDATETIME), CAST('20230615' AS SMALLDATETIME), CAST('June 15, 2023' AS SMALLDATETIME);
GO
BEGIN TRANSACTION;
select set_config('timezone', 'America/Los_Angeles', false);
GO
SELECT CAST('2023-06-15 19:00:00' AS SMALLDATETIME), CAST('20230615' AS SMALLDATETIME), CAST('June 15, 2023' AS SMALLDATETIME);
GO
COMMIT TRANSACTION;
GO
SELECT CAST('2023-06-15 19:00:00' AS SMALLDATETIME), CAST('20230615' AS SMALLDATETIME), CAST('June 15, 2023' AS SMALLDATETIME);
GO
select set_config('timezone', 'UTC', false);
GO

-- Precedence Order of datatypes
SELECT CASE WHEN CAST('2023-06-15 19:00:00' AS SMALLDATETIME) = '2023-06-15 19:00:00' THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d SMALLDATETIME', @d = '2023-06-15 19:00:00';
GO

-- User Defined Datatypes on date datatypes
CREATE TYPE MySmallDateTime FROM SMALLDATETIME;
GO
DECLARE @md MySmallDateTime = '2023-06-15 19:00:00';
SELECT @md;
GO

-- 1. Create User-Defined Data Types based on SMALLDATETIME
CREATE TYPE BusinessSmallDateTime FROM SMALLDATETIME;
CREATE TYPE HistoricalSmallDateTime FROM SMALLDATETIME;
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTSmallDateTimeTest (
    ID INT PRIMARY KEY,
    RegularSmallDateTime SMALLDATETIME,
    BusinessSmallDateTimeCol BusinessSmallDateTime,
    HistoricalSmallDateTimeCol HistoricalSmallDateTime
);
GO

-- 3. Insert data with time components (note: SMALLDATETIME rounds to minutes)
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES 
(1, '2023-06-16 14:30', '2023-06-16 14:30', '1900-07-04 12:00'),
(2, '2023-06-17 09:15', '2023-06-17 09:15', '1945-08-15 11:30'),
(3, '2023-06-18 18:45', '2023-06-18 18:45', '2000-01-01 00:00'),
(4, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTSmallDateTimeTest ORDER BY ID;
GO

-- 5. Test data type information
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    CHARACTER_OCTET_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'UDDTSmallDateTimeTest' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularSmallDateTime AS VARCHAR(30)) AS RegularSmallDateTimeString,
    CAST(BusinessSmallDateTimeCol AS VARCHAR(30)) AS BusinessSmallDateTimeString,
    CAST(HistoricalSmallDateTimeCol AS VARCHAR(30)) AS HistoricalSmallDateTimeString,
    CAST(RegularSmallDateTime AS DATE) AS RegularDate,
    CAST(BusinessSmallDateTimeCol AS TIME) AS BusinessTime,
    CAST(HistoricalSmallDateTimeCol AS DATETIME) AS HistoricalDateTime
FROM UDDTSmallDateTimeTest ORDER BY ID;
GO

-- 7. Test datetime functions
SELECT 
    ID,
    DATEADD(HOUR, 1, RegularSmallDateTime) AS RegularNextHour,
    DATEADD(MINUTE, 30, BusinessSmallDateTimeCol) AS BusinessNext30Min,
    DATEDIFF(MINUTE, HistoricalSmallDateTimeCol, BusinessSmallDateTimeCol) AS MinutesBetween
FROM UDDTSmallDateTimeTest ORDER BY ID;
GO

-- 8. Test constraints with time components
ALTER TABLE UDDTSmallDateTimeTest ADD CONSTRAINT CK_BusinessSmallDateTime 
    CHECK (BusinessSmallDateTimeCol >= '2000-01-01 00:00' 
    AND BusinessSmallDateTimeCol <= '2079-06-06 23:59');
GO

-- This should succeed
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (5, '2023-06-19 15:30', '2023-06-19 15:30', '1989-11-09 12:00');
GO

-- This should fail (date beyond SMALLDATETIME range)
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (6, '2023-06-20 15:30', '2079-06-07 00:00', '1989-11-09 12:00');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTSmallDateTimeProc
    @BusinessSmallDateTime BusinessSmallDateTime,
    @HistoricalSmallDateTime HistoricalSmallDateTime
AS
BEGIN
    SELECT 
        @BusinessSmallDateTime AS InputBusinessSmallDateTime,
        @HistoricalSmallDateTime AS InputHistoricalSmallDateTime,
        DATEDIFF(MINUTE, @HistoricalSmallDateTime, @BusinessSmallDateTime) AS MinutesBetween,
        DATEADD(HOUR, 1, @BusinessSmallDateTime) AS BusinessSmallDateTimePlusHour;
END
GO

-- Execute the stored procedure
EXEC TestUDDTSmallDateTimeProc 
    @BusinessSmallDateTime = '2023-06-16 14:30', 
    @HistoricalSmallDateTime = '1900-07-04 12:00';
GO

-- 10. Test implicit conversions
DECLARE @RegularSmallDateTime SMALLDATETIME = '2023-06-16 14:30';
DECLARE @BusinessSmallDateTime BusinessSmallDateTime = @RegularSmallDateTime;
DECLARE @HistoricalSmallDateTime HistoricalSmallDateTime = '1900-07-04 12:00';

SELECT 
    @RegularSmallDateTime AS RegularSmallDateTime,
    @BusinessSmallDateTime AS BusinessSmallDateTime,
    @HistoricalSmallDateTime AS HistoricalSmallDateTime;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessSmallDateTime ON UDDTSmallDateTimeTest(BusinessSmallDateTimeCol);
CREATE INDEX IX_HistoricalSmallDateTime ON UDDTSmallDateTimeTest(HistoricalSmallDateTimeCol);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTSmallDateTimeTest 
WHERE BusinessSmallDateTimeCol BETWEEN '2023-06-16 00:00' AND '2023-06-16 23:59';
SELECT * FROM UDDTSmallDateTimeTest 
WHERE HistoricalSmallDateTimeCol BETWEEN '1900-07-04 00:00' AND '1900-07-04 23:59';
SET STATISTICS IO OFF;
GO

-- 12. Test with different datetime formats
SET DATEFORMAT mdy;
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (7, '06/21/2023 15:30', '06/21/2023 15:30', '07/04/1900 12:00');
GO

SET DATEFORMAT dmy;
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (8, '21/06/2023 15:30', '21/06/2023 15:30', '04/07/1900 12:00');
GO

SET DATEFORMAT mdy;
GO

-- 13. Test rounding behavior
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES 
(9, '2023-06-16 14:30:29', '2023-06-16 14:30:29', '2000-01-01 00:00:29'),  -- Should round down
(10, '2023-06-16 14:30:31', '2023-06-16 14:30:31', '2000-01-01 00:00:31'); -- Should round up
GO

-- 14. Test time parts
SELECT 
    ID,
    DATEPART(HOUR, BusinessSmallDateTimeCol) AS BusinessHour,
    DATEPART(MINUTE, BusinessSmallDateTimeCol) AS BusinessMinute
FROM UDDTSmallDateTimeTest
WHERE ID IN (9, 10) ORDER BY ID;
GO

-- 15. Test range limitations
-- Should fail (before 1900)
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (11, '1899-12-31 23:59', '2023-06-16 14:30', '1899-12-31 23:59');
GO

-- Should fail (after 2079)
INSERT INTO UDDTSmallDateTimeTest (ID, RegularSmallDateTime, BusinessSmallDateTimeCol, HistoricalSmallDateTimeCol)
VALUES (12, '2079-06-06 23:60', '2079-06-06 23:60', '1900-01-01 00:00');
GO

SELECT * FROM UDDTSmallDateTimeTest WHERE ID IN (7, 8, 9, 10) ORDER BY ID;
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing for SMALLDATETIME
SELECT 
    CAST('2023-06-15 14:30' AS SMALLDATETIME),
    CONVERT(SMALLDATETIME, '2023-06-15 14:30'),
    TRY_CAST('2023-06-31 14:30' AS SMALLDATETIME),
    TRY_CONVERT(SMALLDATETIME, '2023-06-31 14:30'),
    FORMAT(CAST('2023-06-15 14:30' AS SMALLDATETIME), 'yyyy-MM-dd HH:mm');
GO

-- Explicit Conversion Tests for SMALLDATETIME

-- binary
SELECT CAST(CAST(0x0000A5BE9335E340 AS binary) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(0x AS binary) AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST(0xFFFFFFFFFFFFFFFF AS binary) AS SMALLDATETIME); -- Negative
GO

-- varbinary
SELECT CAST(CAST(0x0000A5BE9335E340 AS VARBINARY) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(0x AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST(0xFFFFFFFFFFFFFFFF AS VARBINARY) AS SMALLDATETIME); -- Negative
GO

-- char
SELECT CAST(CAST('2023-06-16 14:30' AS char) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('2023-06-16 14:30:20' AS char) AS SMALLDATETIME); -- Rounds to minute
GO
SELECT CAST(CAST('20230616 14:30' AS char) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS char) AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS char) AS SMALLDATETIME); -- NULL
GO
SELECT CAST(CAST('' AS char) AS SMALLDATETIME); -- Negative
GO

-- varchar
SELECT CAST(CAST('2079-06-06 23:59' AS varchar) AS SMALLDATETIME); -- Edge: Max
GO
SELECT CAST(CAST('2079-06-07 00:00' AS varchar) AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST('2023-06-16 14:30' AS varchar) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('20230616 14:30' AS varchar) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS varchar) AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS varchar) AS SMALLDATETIME); -- NULL
GO
SELECT CAST(CAST('' AS varchar) AS SMALLDATETIME); -- Negative
GO

-- nchar
SELECT CAST(CAST(N'2023-06-16 14:30' AS NCHAR) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(N'1900-01-01 00:00' AS NCHAR) AS SMALLDATETIME); -- Edge: Min
GO
SELECT CAST(CAST(N'1899-12-31 23:59' AS NCHAR) AS SMALLDATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS nchar) AS SMALLDATETIME); -- NULL
GO
SELECT CAST(CAST(N'' AS nchar) AS SMALLDATETIME); -- Negative
GO

-- nvarchar
SELECT CAST(N'2023-06-16 14:30' AS SMALLDATETIME); -- Positive
GO
SELECT CAST(N'2023/06/16 14:30' AS SMALLDATETIME); -- Positive
GO
SELECT CAST(N'16/06/2023 14:30' AS SMALLDATETIME); -- Format dependent
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('2079-06-06' AS DATE) AS SMALLDATETIME); -- Edge
GO

-- datetime
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS DATETIME) AS SMALLDATETIME); -- Rounds to minute
GO
SELECT CAST(CAST('1900-01-01 00:00:00' AS DATETIME) AS SMALLDATETIME); -- Edge
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 14:30' AS SMALLDATETIME) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('1900-01-01 00:00' AS SMALLDATETIME) AS SMALLDATETIME); -- Edge
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 14:30:20.1234567' AS DATETIME2) AS SMALLDATETIME); -- Rounds to minute
GO
SELECT CAST(CAST('2079-06-06 23:59:59.9999999' AS DATETIME2) AS SMALLDATETIME); -- Edge
GO

-- time
SELECT CAST(CAST('14:30:20.1234567' AS TIME) AS SMALLDATETIME); -- Negative
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 14:30:20.123 +01:00' AS DATETIMEOFFSET) AS SMALLDATETIME); -- Rounds to minute
GO
SELECT CAST(CAST('2079-06-06 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS SMALLDATETIME); -- Edge
GO

-- decimal
SELECT CAST(CAST(20230616.1430 AS DECIMAL(12,4)) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(20790606.2359 AS DECIMAL(12,4)) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(0 AS DECIMAL(12,4)) AS SMALLDATETIME); -- Negative
GO

-- numeric
SELECT CAST(CAST(20230616.1430 AS NUMERIC(12,4)) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(19000101 AS NUMERIC(12,4)) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS NUMERIC(12,4)) AS SMALLDATETIME); -- Negative
GO

-- float
SELECT CAST(CAST(20230616.1430 AS FLOAT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(20790606.2359 AS FLOAT) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(1.23e5 AS FLOAT) AS SMALLDATETIME); -- Positive
GO

-- real
SELECT CAST(CAST(20230616.1430 AS REAL) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(20790606.2359 AS REAL) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(-20230616 AS REAL) AS SMALLDATETIME); -- Negative
GO

-- bigint
SELECT CAST(CAST(202306161430 AS BIGINT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(207906062359 AS BIGINT) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(0 AS BIGINT) AS SMALLDATETIME); -- Negative
GO

-- int
SELECT CAST(20230616 AS SMALLDATETIME); -- Positive
GO
SELECT CAST(19000101 AS SMALLDATETIME); -- Edge
GO
SELECT CAST(-1 AS SMALLDATETIME); -- Negative
GO

-- smallint
SELECT CAST(CAST(32767 AS SMALLINT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(-32768 AS SMALLINT) AS SMALLDATETIME); -- Negative
GO

-- tinyint
SELECT CAST(CAST(255 AS TINYINT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(0 AS TINYINT) AS SMALLDATETIME); -- Negative
GO

-- money
SELECT CAST(CAST(20230616.1430 AS MONEY) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(20790606.2359 AS MONEY) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS MONEY) AS SMALLDATETIME); -- Negative
GO

-- smallmoney
SELECT CAST(CAST(20230616.1430 AS SMALLMONEY) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS SMALLDATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS SMALLDATETIME); -- Negative
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS SMALLDATETIME); -- Negative
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS SMALLDATETIME); -- Negative
GO

-- text
SELECT CAST(CAST('2023-06-16 14:30' AS TEXT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS TEXT) AS SMALLDATETIME); -- Negative
GO

-- ntext
SELECT CAST(CAST(N'2023-06-16 14:30' AS NTEXT) AS SMALLDATETIME); -- Positive
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS SMALLDATETIME); -- Negative
GO

-- xml
SELECT CAST(CAST('<date>2023-06-16T14:30</date>' AS XML) AS SMALLDATETIME); -- Negative
GO

-- sql_variant
SELECT CAST(CAST(CAST('2023-06-16 14:30' AS SMALLDATETIME) AS SQL_VARIANT) AS SMALLDATETIME); -- Positive
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS SMALLDATETIME); -- Negative
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS SMALLDATETIME); -- Negative
GO

-- Implicit conversion
-- Create a function that takes a SMALLDATETIME parameter
CREATE FUNCTION dbo.TestSmallDateTimeFunction(@SmallDateTimeParam SMALLDATETIME)
RETURNS SMALLDATETIME
AS
BEGIN
    RETURN @SmallDateTimeParam;
END
GO

-- binary
SELECT dbo.TestSmallDateTimeFunction(CAST(0x0000A5F507E306 AS binary(7))); -- Positive: 2023-06-16 12:34:00
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0x AS binary));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0xFFFFFFFFFFFF AS binary(6))); -- Negative: Will raise an error
GO

-- varbinary
SELECT dbo.TestSmallDateTimeFunction(CAST(0x0000A5F507E306 AS varbinary(7))); -- Positive: 2023-06-16 12:34:00
GO
SELECT dbo.TestSmallDateTimeFunction(0x); -- Negative: Will raise an error
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0xFFFFFFFFFFFF AS varbinary(6)));
GO

-- char
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34' AS char)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34' AS char(16)));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('20230616 12:34' AS char)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('invalid' AS char)); -- Negative: Will raise an error
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(NULL AS char));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-06 23:59' AS varchar)); -- Edge: Max smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-07 00:00' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34' AS varchar)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34:56' AS varchar)); -- Will round to minutes
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('20230616 12:34' AS varchar)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('Jun 16 2023 12:34' AS varchar)); -- Positive: Month name format
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('invalid' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(NULL AS varchar));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestSmallDateTimeFunction(CAST(N'2023-06-16 12:34' AS nchar)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(N'2023-06-16 12:34' AS nchar(16)));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(N'1900-01-01 00:00' AS nchar)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(N'1899-12-31 23:59' AS nchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(NULL AS nchar));
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestSmallDateTimeFunction(N'2023-06-16 12:34'); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(N'2023/06/16 12:34'); -- Positive: Different format
GO
SELECT dbo.TestSmallDateTimeFunction(N'16/06/2023 12:34'); -- Depends on SET DATEFORMAT
GO

-- datetime
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34:56' AS DATETIME)); -- Will round to minutes
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('1900-01-01 00:00:00' AS DATETIME)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-06 23:59:59' AS DATETIME)); -- Edge: Max smalldatetime
GO

-- smalldatetime
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34' AS SMALLDATETIME)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('1900-01-01 00:00' AS SMALLDATETIME)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-06 23:59' AS SMALLDATETIME)); -- Edge: Max smalldatetime
GO

-- datetime2
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2)); -- Will round to minutes
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-06 23:59:59.9999999' AS DATETIME2)); -- Edge
GO

-- time
SELECT dbo.TestSmallDateTimeFunction(CAST('12:34:56' AS TIME)); -- Negative: Will raise an error
GO

-- datetimeoffset
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34:56 +01:00' AS DATETIMEOFFSET)); -- Will round to minutes
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('2079-06-06 23:59:59 +14:00' AS DATETIMEOFFSET)); -- Edge
GO

-- decimal
SELECT dbo.TestSmallDateTimeFunction(CAST(20230616.1234 AS DECIMAL(12,4))); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(20790606.2359 AS DECIMAL(12,4))); -- Edge
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0 AS DECIMAL(12,4))); -- Negative: Will raise an error
GO

-- numeric
SELECT dbo.TestSmallDateTimeFunction(CAST(20230616.1234 AS NUMERIC(12,4))); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(19000101.0000 AS NUMERIC(12,4))); -- Edge: Min smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-1 AS NUMERIC(12,4))); -- Negative: Will raise an error
GO

-- float
SELECT dbo.TestSmallDateTimeFunction(CAST(20230616.1234 AS FLOAT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(20790606.2359 AS FLOAT)); -- Edge
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(1.23e5 AS FLOAT)); -- Negative: Will raise an error
GO

-- real
SELECT dbo.TestSmallDateTimeFunction(CAST(20230616.1234 AS REAL)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(20790606.2359 AS REAL)); -- Edge
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-20230616 AS REAL)); -- Negative: Will raise an error
GO

-- bigint
SELECT dbo.TestSmallDateTimeFunction(CAST(202306161234 AS BIGINT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(207906062359 AS BIGINT)); -- Edge
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0 AS BIGINT)); -- Negative: Will raise an error
GO

-- int
SELECT dbo.TestSmallDateTimeFunction(CAST(2023061612 AS INT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(1900010100 AS INT)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-1 AS INT)); -- Negative: Will raise an error
GO

-- smallint
SELECT dbo.TestSmallDateTimeFunction(CAST(2023 AS SMALLINT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(32767 AS SMALLINT)); -- Edge: Max smallint
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-1 AS SMALLINT)); -- Negative: Will raise an error
GO

-- tinyint
SELECT dbo.TestSmallDateTimeFunction(CAST(123 AS TINYINT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(255 AS TINYINT)); -- Edge: Max tinyint
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(0 AS TINYINT)); -- Negative: Will raise an error
GO

-- money
SELECT dbo.TestSmallDateTimeFunction(CAST(20230616.1234 AS MONEY)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(20790606.2359 AS MONEY)); -- Edge
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-1 AS MONEY)); -- Negative: Will raise an error
GO

-- smallmoney
SELECT dbo.TestSmallDateTimeFunction(CAST(20230.1234 AS SMALLMONEY)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(214748.3647 AS SMALLMONEY)); -- Edge: Max smallmoney
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(-1 AS SMALLMONEY)); -- Negative: Will raise an error
GO

-- bit
SELECT dbo.TestSmallDateTimeFunction(CAST(1 AS BIT)); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT dbo.TestSmallDateTimeFunction(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER)); -- Negative
GO

-- text
SELECT dbo.TestSmallDateTimeFunction(CAST('2023-06-16 12:34' AS TEXT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST('invalid' AS TEXT)); -- Negative: Will raise an error
GO

-- ntext
SELECT dbo.TestSmallDateTimeFunction(CAST(N'2023-06-16 12:34' AS NTEXT)); -- Positive
GO
SELECT dbo.TestSmallDateTimeFunction(CAST(N'invalid' AS NTEXT)); -- Negative: Will raise an error
GO

-- xml
SELECT dbo.TestSmallDateTimeFunction(CAST('<date>2023-06-16T12:34</date>' AS XML)); -- Negative
GO

-- sql_variant
SELECT dbo.TestSmallDateTimeFunction(CAST(CAST('2023-06-16 12:34' AS SMALLDATETIME) AS SQL_VARIANT)); -- Positive
GO

-- geometry
SELECT dbo.TestSmallDateTimeFunction(geometry::STGeomFromText('POINT(1 1)', 0)); -- Negative: Will raise an error
GO

-- geography
SELECT dbo.TestSmallDateTimeFunction(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326)); -- Negative
GO

-- Create a table to store test results
CREATE TABLE SmallDateTimeImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue SMALLDATETIME NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertSmallDateTimeTestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue SMALLDATETIME = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO SmallDateTimeImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @SmallDateTimeValue SMALLDATETIME = '2023-06-16 14:30';
DECLARE @StringDateTime NVARCHAR(30) = '2023-06-17 15:45';
DECLARE @DateValue DATE = '2023-06-20';
DECLARE @DateTimeValue DATETIME = '2023-06-21 16:30:20.123';
DECLARE @DateTime2Value DATETIME2 = '2023-06-22 17:15:40.1234567';
DECLARE @TimeValue TIME = '18:45:50.123';

-- 1. UNION with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @SmallDateTimeValue AS Result
        UNION
        SELECT @StringDateTime
        UNION
        SELECT @DateValue
        UNION
        SELECT @DateTimeValue
        UNION
        SELECT @DateTime2Value
    ) AS UnionResult;
    EXEC InsertSmallDateTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 2. UNION ALL with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) AS Result
        UNION ALL
        SELECT '2023-06-17 15:45'
        UNION ALL
        SELECT CAST('2023-06-20' AS DATE)
        UNION ALL
        SELECT CAST('2023-06-21 16:30:20.123' AS DATETIME)
        UNION ALL
        SELECT CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    ) AS UnionAllResult;
    EXEC InsertSmallDateTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 3. CASE Expression with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CASE 
        WHEN 1=0 THEN CAST('2023-06-16 14:30' AS SMALLDATETIME)
        WHEN 1=0 THEN '2023-06-17 15:45'
        WHEN 1=0 THEN CAST('2023-06-20' AS DATE)
        WHEN 1=0 THEN CAST('2023-06-21 16:30:20.123' AS DATETIME)
        ELSE CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    END;
    EXEC InsertSmallDateTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 4. COALESCE with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = COALESCE(
        NULL,
        CAST('2023-06-16 14:30' AS SMALLDATETIME),
        '2023-06-17 15:45',
        CAST('2023-06-20' AS DATE),
        CAST('2023-06-21 16:30:20.123' AS DATETIME),
        CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    );
    EXEC InsertSmallDateTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 5. INTERSECT with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) AS Result
        INTERSECT
        SELECT '2023-06-16 14:30'
    ) AS IntersectResult;
    EXEC InsertSmallDateTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'SMALLDATETIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'SMALLDATETIME and String', NULL, 0;
END CATCH;
GO

-- 6. EXCEPT with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) AS Result
        EXCEPT
        SELECT '2023-06-16 14:30'
    ) AS ExceptResult;
    EXEC InsertSmallDateTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'SMALLDATETIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'SMALLDATETIME and String', NULL, 0;
END CATCH;
GO

-- 7. VALUES with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SELECT TOP 1 @Result = Result
    FROM (VALUES 
        (CAST('2023-06-16 14:30' AS SMALLDATETIME)),
        ('2023-06-17 15:45'),
        (CAST('2023-06-20' AS DATE)),
        (CAST('2023-06-21 16:30:20.123' AS DATETIME)),
        (CAST('2023-06-22 17:15:40.1234567' AS DATETIME2))
    ) AS ValuesResult(Result);
    EXEC InsertSmallDateTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 8. ISNULL with different datetime types
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = ISNULL(NULL, '2023-06-16 14:30');
    EXEC InsertSmallDateTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;
GO

-- 9. Rounding tests
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('2023-06-16 14:30:29' AS SMALLDATETIME); -- Should round down
    EXEC InsertSmallDateTimeTestResult 'ROUND DOWN', 'Rounding test 29 seconds', '2023-06-16 14:30:29', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'ROUND DOWN', 'Rounding test 29 seconds', '2023-06-16 14:30:29', NULL, 0;
END CATCH;
GO

BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('2023-06-16 14:30:31' AS SMALLDATETIME); -- Should round up
    EXEC InsertSmallDateTimeTestResult 'ROUND UP', 'Rounding test 31 seconds', '2023-06-16 14:30:31', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'ROUND UP', 'Rounding test 31 seconds', '2023-06-16 14:30:31', NULL, 0;
END CATCH;
GO

-- 10. Range boundary tests
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('1900-01-01 00:00' AS SMALLDATETIME); -- Minimum value
    EXEC InsertSmallDateTimeTestResult 'MIN VALUE', 'Minimum SMALLDATETIME value', '1900-01-01 00:00', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'MIN VALUE', 'Minimum SMALLDATETIME value', '1900-01-01 00:00', NULL, 0;
END CATCH;
GO

BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('2079-06-06 23:59' AS SMALLDATETIME); -- Maximum value
    EXEC InsertSmallDateTimeTestResult 'MAX VALUE', 'Maximum SMALLDATETIME value', '2079-06-06 23:59', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'MAX VALUE', 'Maximum SMALLDATETIME value', '2079-06-06 23:59', NULL, 0;
END CATCH;
GO

-- 11. Invalid conversions (should fail)
BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('1899-12-31 23:59' AS SMALLDATETIME); -- Before minimum
    EXEC InsertSmallDateTimeTestResult 'INVALID MIN', 'Before minimum SMALLDATETIME', '1899-12-31 23:59', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'INVALID MIN', 'Before minimum SMALLDATETIME', '1899-12-31 23:59', NULL, 0;
END CATCH;
GO

BEGIN TRY
    DECLARE @Result SMALLDATETIME;
    SET @Result = CAST('2079-06-07 00:00' AS SMALLDATETIME); -- After maximum
    EXEC InsertSmallDateTimeTestResult 'INVALID MAX', 'After maximum SMALLDATETIME', '2079-06-07 00:00', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertSmallDateTimeTestResult 'INVALID MAX', 'After maximum SMALLDATETIME', '2079-06-07 00:00', NULL, 0;
END CATCH;
GO

-- Display results
SELECT * FROM SmallDateTimeImplicitConversionTest ORDER BY ID;
GO

DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);

-- binary
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, 0x07E30610142200, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- varbinary
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- char
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, ''2023-06-16 14:22'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- varchar
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, ''2023-06-16 14:22'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- nchar
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, N''2023-06-16 14:22'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- nvarchar
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, N''2023-06-16 14:22'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- date
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- datetime
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- smalldatetime
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- datetime2
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22:00'' AS DATETIME2), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- datetimeoffset
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22:00 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- decimal
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230616.1422 AS DECIMAL(12,4)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- numeric
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230616.1422 AS NUMERIC(12,4)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- float
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230616.1422 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- real
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230616.1422 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- bigint
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(202306161422 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- int
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, 20230616, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- smallint
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- tinyint
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(16 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- money
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230616.1422 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- smallmoney
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(20230.1422 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- text
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(''2023-06-16 14:22'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- ntext
DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);
DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(SMALLDATETIME, CAST(N''2023-06-16 14:22'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(0x07E30610 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(0x07E30610 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS char(16)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS varchar(16)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS nchar(16)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS nvarchar(16)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30:00' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30:00' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('14:30' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30:00 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS decimal(12,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS numeric(12,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(20230616 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(20230 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(16 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(202306161430 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(20230 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(0x07E30610 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('2023-06-16 14:30' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST(CAST('2023-06-16 14:30' AS smalldatetime) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) = CAST('<smalldatetime>2023-06-16T14:30</smalldatetime>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS char(16)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS varchar(16)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS nchar(16)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS nvarchar(16)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS datetime) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS smalldatetime) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS datetime2) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('14:30' AS time) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00 +01:00' AS datetimeoffset) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS decimal(12,0)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS numeric(12,0)) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS float) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS real) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS bigint) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202306161430 AS money) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS text) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS ntext) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 14:30' AS smalldatetime) AS sql_variant) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('<smalldatetime>2023-06-16T14:30</smalldatetime>' AS xml) = CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(0x07E30610 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(0x07E30610 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS char(16)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS varchar(16)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS nchar(16)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS nvarchar(16)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('12:34' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS decimal(12,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS numeric(12,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(20230616 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(20230 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(16 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(202306161234 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(20230 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(0x07E30610 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('2023-06-16 12:34' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <> CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS char(16)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS varchar(16)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nchar(16)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nvarchar(16)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS smalldatetime) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34' AS time) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS decimal(12,0)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS numeric(12,0)) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS float) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS real) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS bigint) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202306161234 AS money) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS text) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS ntext) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) <> CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(0x07E30610 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS char(16)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS varchar(16)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS nchar(16)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS nvarchar(16)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34:00.0000000' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('12:34' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS decimal(12,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS numeric(12,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(20230616 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(20230 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(16 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(202306161234 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(20230 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(0x07E30610 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('2023-06-16 12:34' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) < CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS char(16)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS varchar(16)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nchar(16)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nvarchar(16)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS smalldatetime) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00.0000000' AS datetime2) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34' AS time) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS decimal(12,0)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS numeric(12,0)) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS float) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS real) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS bigint) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS money) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS text) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS ntext) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) < CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(0x07E30610 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS char(16)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS varchar(16)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS nchar(16)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS nvarchar(16)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('12:34' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616.1234 AS decimal(12,4)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616.1234 AS numeric(12,4)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616.1234 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616.1234 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(202306161234 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(16 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230616.1234 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(20230.1234 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(0x07E30610 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('2023-06-16 12:34' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) <= CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS char(16)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS varchar(16)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nchar(16)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nvarchar(16)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS smalldatetime) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34' AS time) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS decimal(12,4)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS numeric(12,4)) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS float) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS real) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS bigint) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS money) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230.1234 AS smallmoney) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS text) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS ntext) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('<smalldatetime>2023-06-16T12:34</smalldatetime>' AS xml) <= CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(0x07E30610 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(0x07E30610 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS char(16)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS varchar(16)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS nchar(16)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS nvarchar(16)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34:00' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34:00' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('12:34' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS decimal(12,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS numeric(12,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(20230616 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(20230 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(123 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(202306161234 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(20230 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(0x07E30610 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('2023-06-16 12:34' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS SMALLDATETIME) > CAST('<datetime>2023-06-16T12:34</datetime>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS char(16)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS varchar(16)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nchar(16)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS nvarchar(16)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS datetime) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS smalldatetime) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS datetime2) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34' AS time) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00 +01:00' AS datetimeoffset) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS decimal(12,0)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS numeric(12,0)) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS float) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS real) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS bigint) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123 AS tinyint) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(202306161234 AS money) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS text) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34' AS ntext) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34' AS smalldatetime) AS sql_variant) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34</datetime>' AS xml) > CAST('2023-06-16 12:34' AS SMALLDATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with SMALLDATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(0x07E306101430 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(0x07E306101430 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS char(16)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS varchar(16)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS nchar(16)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS nvarchar(16)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30:00' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30:00' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('14:30' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30:00 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS decimal(12,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS numeric(12,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(20230616 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(20230 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(16 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(202306161430 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(20230.1430 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(0x07E306101430 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('2023-06-16 14:30' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST(CAST('2023-06-16 14:30' AS smalldatetime) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) >= CAST('<smalldatetime>2023-06-16T14:30</smalldatetime>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with SMALLDATETIME on right side
SELECT CASE WHEN CAST(0x07E306101430 AS binary(8)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E306101430 AS varbinary(8)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS char(16)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS varchar(16)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS nchar(16)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS nvarchar(16)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS datetime) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS smalldatetime) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS datetime2) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('14:30' AS time) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00 +01:00' AS datetimeoffset) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS decimal(12,0)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS numeric(12,0)) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS float) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS real) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS bigint) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(202306161430 AS money) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230.1430 AS smallmoney) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E306101430 AS image) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS text) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30' AS ntext) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 14:30' AS smalldatetime) AS sql_variant) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('<smalldatetime>2023-06-16T14:30</smalldatetime>' AS xml) >= CAST('2023-06-16 14:30' AS SMALLDATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator with SMALLDATETIME
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-15 14:30' AS SMALLDATETIME) 
        AND CAST('2023-06-17 14:30' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with different time parts
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-15 00:00' AS SMALLDATETIME) 
        AND CAST('2023-06-17 23:59' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with same date, different times
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-16 14:00' AS SMALLDATETIME) 
        AND CAST('2023-06-16 15:00' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with minute rounding
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:29' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        AND CAST('2023-06-16 14:31' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with different data types
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-15 14:30:00' AS DATETIME) 
        AND CAST('2023-06-17 14:30:00' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-15 14:30:00.0000000' AS DATETIME2) 
        AND CAST('2023-06-17 14:30:00.0000000' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-15 14:30:00 +01:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-17 14:30:00 +01:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator with SMALLDATETIME
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) IN 
        (CAST('2023-06-15 14:30' AS SMALLDATETIME), 
         CAST('2023-06-16 14:30' AS SMALLDATETIME), 
         CAST('2023-06-17 14:30' AS SMALLDATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IN with different time parts
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) IN 
        (CAST('2023-06-16 14:00' AS SMALLDATETIME), 
         CAST('2023-06-16 14:30' AS SMALLDATETIME), 
         CAST('2023-06-16 15:00' AS SMALLDATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IN with different data types
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) IN 
        (CAST('2023-06-15 14:30:00' AS DATETIME), 
         CAST('2023-06-16 14:30:00' AS DATETIME), 
         CAST('2023-06-17 14:30:00' AS DATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL with SMALLDATETIME
DECLARE @NullSmallDateTime SMALLDATETIME;
SELECT CASE 
    WHEN @NullSmallDateTime IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

DECLARE @NullSmallDateTime SMALLDATETIME;
SELECT CASE 
    WHEN @NullSmallDateTime IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Non-null SMALLDATETIME tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30' AS SMALLDATETIME) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Edge cases with SMALLDATETIME
-- Minimum SMALLDATETIME value
SELECT CASE 
    WHEN CAST('1900-01-01 00:00' AS SMALLDATETIME) 
        BETWEEN CAST('1900-01-01 00:00' AS SMALLDATETIME) 
        AND CAST('1900-01-01 23:59' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Maximum SMALLDATETIME value
SELECT CASE 
    WHEN CAST('2079-06-06 23:59' AS SMALLDATETIME) 
        BETWEEN CAST('2079-06-06 00:00' AS SMALLDATETIME) 
        AND CAST('2079-06-06 23:59' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Minute rounding tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:29' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        AND CAST('2023-06-16 14:31' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:31' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-16 14:30' AS SMALLDATETIME) 
        AND CAST('2023-06-16 14:31' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Cross-day boundary
SELECT CASE 
    WHEN CAST('2023-06-16 23:59' AS SMALLDATETIME) 
        BETWEEN CAST('2023-06-16 23:58' AS SMALLDATETIME) 
        AND CAST('2023-06-17 00:00' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Invalid range tests (these should fail or be rounded)
SELECT CASE 
    WHEN CAST('1899-12-31 23:59' AS SMALLDATETIME) 
        BETWEEN CAST('1899-12-31 23:59' AS SMALLDATETIME) 
        AND CAST('1900-01-01 00:00' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2079-06-06 23:60' AS SMALLDATETIME) 
        BETWEEN CAST('2079-06-06 23:59' AS SMALLDATETIME) 
        AND CAST('2079-06-07 00:00' AS SMALLDATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Arithmetic operators
-- Addition with SMALLDATETIME on left side
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('2023-06-16 12:34' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('12:34' AS TIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) + CAST('<number>1</number>' AS XML);
GO

-- Addition with SMALLDATETIME on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS CHAR(10)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS VARCHAR(10)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NCHAR(10)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34' AS SMALLDATETIME) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('12:34' AS TIME) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS FLOAT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS REAL) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS BIGINT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS INT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS SMALLINT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS TINYINT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS MONEY) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS SMALLMONEY) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS BIT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(0x07E30610 AS IMAGE) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS TEXT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NTEXT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('<number>1</number>' AS XML) + CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO

-- Subtraction with SMALLDATETIME on left side
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(0x07E306101430 AS BINARY(8));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(0x07E306101430 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('2023-06-15' AS DATE);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('2023-06-15 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('2023-06-15 12:34' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('2023-06-15 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('12:34' AS TIME);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('2023-06-15 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(0x07E306101430 AS IMAGE);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 14:30' AS SMALLDATETIME) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with SMALLDATETIME on right side
SELECT CAST(0x07E306101430 AS BINARY(8)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(0x07E306101430 AS VARBINARY(8)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-17' AS DATE) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-17 12:34:56' AS DATETIME) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-17 12:34' AS SMALLDATETIME) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-17 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('12:34' AS TIME) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-17 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS FLOAT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS REAL) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS BIGINT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS INT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS SMALLINT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS TINYINT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS MONEY) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(1 AS BIT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(0x07E306101430 AS IMAGE) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS TEXT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('1' AS NTEXT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('2023-06-16 14:30' AS SMALLDATETIME);
GO

-- Additional edge case tests for SMALLDATETIME
SELECT CAST('1900-01-01 00:00' AS SMALLDATETIME) - CAST(1 AS INT); -- Minimum date
GO
SELECT CAST('2079-06-06 23:59' AS SMALLDATETIME) - CAST(1 AS INT); -- Maximum date
GO
SELECT CAST('2023-06-16 14:29:59' AS DATETIME) - CAST('2023-06-16 14:30' AS SMALLDATETIME); -- Rounding test
GO
SELECT CAST('2023-06-16 14:30:29' AS DATETIME) - CAST('2023-06-16 14:30' AS SMALLDATETIME); -- Rounding test
GO
SELECT CAST('2023-06-16 14:30:31' AS DATETIME) - CAST('2023-06-16 14:31' AS SMALLDATETIME); -- Rounding test
GO

-- 4. DDL testing:

-- 1. Table column with SMALLDATETIME
CREATE TABLE SmallDateTimeTest1 (
    ID INT PRIMARY KEY,
    SmallDateTimeColumn SMALLDATETIME,
    DefaultSmallDateTimeColumn SMALLDATETIME DEFAULT GETDATE(),
    ComputedSmallDateTimeColumn AS DATEADD(day, 1, SmallDateTimeColumn),
    CHECK (SmallDateTimeColumn > '2000-01-01 00:00')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SmallDateTimeTest1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table for SMALLDATETIME
CREATE PARTITION FUNCTION SMALLDATETIME_partition_func (SMALLDATETIME) 
    AS RANGE RIGHT FOR VALUES(
        '2022-01-01 00:00', 
        '2023-01-01 00:00', 
        '2024-01-01 00:00'
    );
GO

CREATE PARTITION SCHEME SMALLDATETIME_partition_scheme
    AS PARTITION SMALLDATETIME_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE SMALLDATETIME_partition(
    a SMALLDATETIME,
    type VARCHAR(10))
ON SMALLDATETIME_partition_scheme(a);
GO

-- Insert test data with time components (minutes only)
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-06-15 09:30', 'PDF');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-12-31 14:45', 'PDF');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-06-15 10:15', 'GIF');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-12-31 15:20', 'GIF');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-06-15 11:00', 'JPEG');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-12-31 16:30', 'JPEG');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-06-15 12:45', 'PNG');
GO
INSERT INTO SMALLDATETIME_partition (a, type) VALUES ('2021-12-31 17:15', 'PNG');
GO

-- Query to show data in each partition
SELECT a, type, $PARTITION.SMALLDATETIME_partition_func(a) AS PartitionNumber
    FROM SMALLDATETIME_partition ORDER BY PartitionNumber, type, a;
GO

-- Query to show count by partition
SELECT $PARTITION.SMALLDATETIME_partition_func(a) AS PartitionNumber, type, COUNT(*) AS FileCount
    FROM SMALLDATETIME_partition
    GROUP BY $PARTITION.SMALLDATETIME_partition_func(a), type
    ORDER BY PartitionNumber, type;
GO

-- 3. Function returning SMALLDATETIME
CREATE FUNCTION dbo.GetCurrentSmallDateTime()
RETURNS SMALLDATETIME
AS
BEGIN
    RETURN CAST('2023-06-17 14:30' AS SMALLDATETIME);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentSmallDateTime' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes SMALLDATETIME input
CREATE FUNCTION dbo.AddDaysToSmallDateTime(
    @InputSmallDateTime SMALLDATETIME,
    @DaysToAdd INT
)
RETURNS SMALLDATETIME
AS
BEGIN
    RETURN DATEADD(DAY, @DaysToAdd, @InputSmallDateTime);
END;
GO

-- Test the function
SELECT dbo.AddDaysToSmallDateTime('2023-06-16 14:30', 5) AS Result;
GO
SELECT dbo.AddDaysToSmallDateTime('2023-06-16 14:30', -5) AS Result;
GO
SELECT dbo.AddDaysToSmallDateTime('2023-06-16 14:30', 0) AS Result;
GO

-- 5. Procedure takes SMALLDATETIME input
CREATE PROCEDURE dbo.ProcessSmallDateTime
    @InputSmallDateTime SMALLDATETIME
AS
BEGIN
    SELECT 
        @InputSmallDateTime AS InputSmallDateTime,
        DATEADD(DAY, 1, @InputSmallDateTime) AS NextDay,
        DATEADD(HOUR, 1, @InputSmallDateTime) AS NextHour,
        DATEADD(MINUTE, 1, @InputSmallDateTime) AS NextMinute;
END;
GO

-- 6. Constraints
ALTER TABLE SmallDateTimeTest1
ADD CONSTRAINT DF_SmallDateTimeTest_DefaultColumn 
    DEFAULT '2000-01-01 00:00' FOR DefaultSmallDateTimeColumn;
GO

ALTER TABLE SmallDateTimeTest1
ADD CONSTRAINT CK_SmallDateTimeTest_SmallDateTimeColumn 
    CHECK (SmallDateTimeColumn > '2000-01-01 00:00');
GO

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'SmallDateTimeTest1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key verification
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'SmallDateTimeTest1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views with SMALLDATETIME
CREATE VIEW dbo.SmallDateTimeView
AS
SELECT
    ID,
    SmallDateTimeColumn,
    DefaultSmallDateTimeColumn,
    ComputedSmallDateTimeColumn,
    DATEPART(YEAR, SmallDateTimeColumn) AS Year,
    DATEPART(MONTH, SmallDateTimeColumn) AS Month,
    DATEPART(DAY, SmallDateTimeColumn) AS Day,
    DATEPART(HOUR, SmallDateTimeColumn) AS Hour,
    DATEPART(MINUTE, SmallDateTimeColumn) AS Minute
FROM SmallDateTimeTest1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SmallDateTimeView'
ORDER BY COLUMN_NAME;
GO

-- Insert test data with time components (minutes only)
INSERT INTO SmallDateTimeTest1 (ID, SmallDateTimeColumn) VALUES 
(1, '2023-06-16 14:30'),
(2, '2023-06-17 09:15'),
(3, '2023-06-18 18:45');
GO

-- Test all objects
SELECT * FROM SmallDateTimeTest1 ORDER BY ID;
GO

SELECT * FROM SMALLDATETIME_partition ORDER BY a, type;
GO

SELECT dbo.GetCurrentSmallDateTime() AS CurrentSmallDateTime;
GO

SELECT dbo.AddDaysToSmallDateTime('2023-06-16 14:30', 5) AS SmallDateTimeAfter5Days;
GO

EXEC dbo.ProcessSmallDateTime @InputSmallDateTime = '2023-06-16 14:30';
GO

SELECT * FROM dbo.SmallDateTimeView ORDER BY ID;
GO

-- Additional SMALLDATETIME-specific tests
-- Test rounding behavior
SELECT CAST('2023-06-16 14:30:29' AS SMALLDATETIME) AS RoundedDown,
       CAST('2023-06-16 14:30:31' AS SMALLDATETIME) AS RoundedUp;
GO

-- Test arithmetic operations
SELECT 
    DATEADD(MINUTE, 1, '2023-06-16 14:30') AS AddMinute,
    DATEADD(HOUR, 1, '2023-06-16 14:30') AS AddHour;
GO

-- Test range limits
SELECT CAST('1900-01-01 00:00' AS SMALLDATETIME) AS MinValue;
GO
SELECT CAST('2079-06-06 23:59' AS SMALLDATETIME) AS MaxValue;
GO

-- Test invalid values (these will generate errors)
BEGIN TRY
    SELECT CAST('1899-12-31 23:59' AS SMALLDATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

BEGIN TRY
    SELECT CAST('2079-06-07 00:00' AS SMALLDATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
GO

-- Test seconds truncation
SELECT 
    CAST('2023-06-16 14:30:45' AS SMALLDATETIME) AS TruncatedSeconds;
GO

-- 5. DML testing:
-- Create test tables for SMALLDATETIME
CREATE TABLE SmallDateTimeDMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleSmallDateTime SMALLDATETIME,
    DefaultSmallDateTime SMALLDATETIME DEFAULT NULL,
    ComputedSmallDateTime AS DATEADD(hour, 1, SimpleSmallDateTime),
    Description NVARCHAR(100)
);
GO

CREATE TABLE SmallDateTimeDMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildSmallDateTime SMALLDATETIME,
    FOREIGN KEY (ParentID) REFERENCES SmallDateTimeDMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion (rounds to nearest minute)
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description) 
VALUES ('2023-06-16 14:30', 'Single row insertion');
GO

-- Bulk insertion with various time formats
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
VALUES 
('2023-06-17 09:15', 'Bulk insertion 1'),
('2023-06-18 12:45', 'Bulk insertion 2'),
('2023-06-19 18:20', 'Bulk insertion 3');
GO

-- Insert with type casting
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
VALUES (CAST('20230620 15:30' AS SMALLDATETIME), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
VALUES (DATEADD(minute, 30, '2023-06-16 14:30'), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, DefaultSmallDateTime, Description)
VALUES ('2023-06-22 10:15', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM SmallDateTimeDMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = '2023-07-01 08:30'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = '2023-07-02 14:45',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = DATEADD(hour, 2, SimpleSmallDateTime)
WHERE ID = 3;
GO

-- Mass update
UPDATE SmallDateTimeDMLTest
SET Description = 'Mass updated';
GO

-- Conditional update based on time
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = '2023-08-01 12:00'
WHERE SimpleSmallDateTime < '2023-07-01 00:00';
GO

-- Verify updates
SELECT * FROM SmallDateTimeDMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO SmallDateTimeDMLTestChild (ParentID, ChildSmallDateTime)
VALUES 
(1, '2023-06-16 10:30'),
(2, '2023-06-17 11:45'),
(3, '2023-06-18 14:20'),
(4, '2023-06-19 16:15'),
(5, '2023-06-20 09:30');
GO

-- Single row deletion
DELETE FROM SmallDateTimeDMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM SmallDateTimeDMLTest;
GO

-- Conditional deletion based on time
DELETE FROM SmallDateTimeDMLTest 
WHERE SimpleSmallDateTime < '2023-07-01 00:00';
GO

-- Cascade deletion (will delete from child table as well)
DELETE FROM SmallDateTimeDMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM SmallDateTimeDMLTest ORDER BY ID;
SELECT * FROM SmallDateTimeDMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
VALUES ('2023-09-01 15:30', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleSmallDateTime, ComputedSmallDateTime, Description
FROM SmallDateTimeDMLTest
WHERE CONVERT(DATE, SimpleSmallDateTime) = '2023-09-01';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE SmallDateTimeDMLTest
    SET ComputedSmallDateTime = '2023-09-03 16:30'
    WHERE CONVERT(DATE, SimpleSmallDateTime) = '2023-09-01';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = '2023-09-02 14:30'
WHERE CONVERT(DATE, SimpleSmallDateTime) = '2023-09-01';
GO

SELECT ID, SimpleSmallDateTime, ComputedSmallDateTime, Description
FROM SmallDateTimeDMLTest
WHERE CONVERT(DATE, SimpleSmallDateTime) = '2023-09-02';
GO

-- 5. Additional DML scenarios

-- Insert with subquery
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
SELECT DATEADD(year, 1, MAX(SimpleSmallDateTime)), 'Inserted from subquery'
FROM SmallDateTimeDMLTest;
GO

-- Update with JOIN
UPDATE d
SET d.SimpleSmallDateTime = DATEADD(hour, 1, c.ChildSmallDateTime)
FROM SmallDateTimeDMLTest d
JOIN SmallDateTimeDMLTestChild c ON d.ID = c.ParentID;
GO

-- Delete with subquery based on time
DELETE FROM SmallDateTimeDMLTest
WHERE SimpleSmallDateTime IN (
    SELECT ChildSmallDateTime
    FROM SmallDateTimeDMLTestChild
);
GO

-- Insert data that violates SMALLDATETIME range (this will fail)
BEGIN TRY
    INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
    VALUES ('1899-12-31 23:59', 'This should fail');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Minute rounding tests
INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
VALUES 
('2023-06-16 14:30:29', 'Round down test'),  -- Should round to 14:30
('2023-06-16 14:30:31', 'Round up test'),    -- Should round to 14:31
('2023-06-16 14:29:59', 'Round up test 2');  -- Should round to 14:30
GO

-- Update with different time values (testing rounding)
UPDATE SmallDateTimeDMLTest
SET SimpleSmallDateTime = DATEADD(second, 45, SimpleSmallDateTime)
WHERE Description LIKE 'Round%';
GO

-- Test maximum date
BEGIN TRY
    INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
    VALUES ('2079-06-06 23:59', 'Max valid date');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Test minimum date
BEGIN TRY
    INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
    VALUES ('1900-01-01 00:00', 'Min valid date');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Test invalid time components
BEGIN TRY
    INSERT INTO SmallDateTimeDMLTest (SimpleSmallDateTime, Description)
    VALUES ('2023-06-16 24:00', 'Invalid hour');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Final verification
SELECT * FROM SmallDateTimeDMLTest ORDER BY ID;
SELECT * FROM SmallDateTimeDMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table with SMALLDATETIME
CREATE TABLE SmallDateTimeIndexTest (
    ID INT IDENTITY PRIMARY KEY,
    SmallDateTimeColumn SMALLDATETIME,
    SmallDateTimeColumn2 SMALLDATETIME,
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data (note: SMALLDATETIME rounds to nearest minute)
INSERT INTO SmallDateTimeIndexTest (SmallDateTimeColumn, SmallDateTimeColumn2, Description, NumericColumn)
VALUES 
('2023-01-01 12:30', '2023-06-01 08:15', 'First half', 1),
('2023-02-15 14:20', '2023-07-15 09:45', 'Mid year', 2),
('2023-03-30 16:45', '2023-08-30 11:30', 'Third quarter', 3),
('2023-04-10 18:10', '2023-09-10 13:20', 'Fall season', 4),
('2023-05-20 20:30', '2023-10-20 15:45', 'Year end', 5);
GO

-- 1. Index on single SMALLDATETIME column
CREATE INDEX IX_SmallDateTimeIndexTest_SmallDateTimeColumn 
ON SmallDateTimeIndexTest(SmallDateTimeColumn);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple SMALLDATETIME columns
CREATE INDEX IX_SmallDateTimeIndexTest_SmallDateTimeColumn_SmallDateTimeColumn2 
ON SmallDateTimeIndexTest(SmallDateTimeColumn, SmallDateTimeColumn2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30' 
AND SmallDateTimeColumn2 = '2023-06-01 08:15';
SET STATISTICS IO OFF;
GO

-- 3. Different operators with SMALLDATETIME

-- Equality with minute precision
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30';
SET STATISTICS IO OFF;
GO

-- Range including time
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn BETWEEN '2023-01-01 00:00' AND '2023-03-31 23:59' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- LIKE with converted SMALLDATETIME
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE CONVERT(VARCHAR(16), SmallDateTimeColumn, 120) LIKE '2023-01%';
SET STATISTICS IO OFF;
GO

-- IN with minute precision
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn IN 
    ('2023-01-01 12:30', 
     '2023-02-15 14:20', 
     '2023-03-30 16:45') ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Data type conversions

-- SMALLDATETIME to VARCHAR
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '20230101 12:30';
SET STATISTICS IO OFF;
GO

-- SMALLDATETIME to DATE
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE CAST(SmallDateTimeColumn AS DATE) = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- DATETIME to SMALLDATETIME conversion (should round to minute)
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30:45';
SET STATISTICS IO OFF;
GO

-- 5. DML operations

-- INSERT with minute precision
SET STATISTICS IO ON;
INSERT INTO SmallDateTimeIndexTest 
    (SmallDateTimeColumn, SmallDateTimeColumn2, Description, NumericColumn)
VALUES 
    ('2023-06-30 22:15', '2023-12-31 23:59', 'Year end', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE with minute precision
SET STATISTICS IO ON;
UPDATE SmallDateTimeIndexTest 
SET SmallDateTimeColumn = '2023-07-01 00:00' 
WHERE SmallDateTimeColumn = '2023-06-30 22:15';
SET STATISTICS IO OFF;
GO

-- DELETE with minute precision
SET STATISTICS IO ON;
DELETE FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-07-01 00:00';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Filtered index with time range
CREATE INDEX IX_SmallDateTimeIndexTest_Filtered ON SmallDateTimeIndexTest(SmallDateTimeColumn)
WHERE SmallDateTimeColumn >= '2023-01-01 00:00' 
AND SmallDateTimeColumn < '2024-01-01 00:00';
GO

-- Test filtered index
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-02-15 14:20';
SET STATISTICS IO OFF;
GO

-- Index with included columns
CREATE INDEX IX_SmallDateTimeIndexTest_SmallDateTimeColumn_Include 
ON SmallDateTimeIndexTest(SmallDateTimeColumn)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT SmallDateTimeColumn, Description, NumericColumn 
FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-03-30 16:45';
SET STATISTICS IO OFF;
GO

-- 7. DateTime function tests

-- DATEADD with minute precision
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = DATEADD(HOUR, -1, '2023-01-01 13:30');
SET STATISTICS IO OFF;
GO

-- DATEDIFF with minute precision
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE DATEDIFF(MINUTE, SmallDateTimeColumn, '2023-01-01 12:30') = 0;
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest WITH (INDEX(IX_SmallDateTimeIndexTest_SmallDateTimeColumn))
WHERE SmallDateTimeColumn = '2023-01-01 12:30';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest WITH (INDEX(0))
WHERE SmallDateTimeColumn = '2023-01-01 12:30';
SET STATISTICS IO OFF;
GO

-- 9. Minute precision tests

-- Exact minute match
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30';
SET STATISTICS IO OFF;
GO

-- Rounding test (should round to nearest minute)
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2023-01-01 12:30:31';  -- Should round to 12:31
SET STATISTICS IO OFF;
GO

-- Time range within a day (hour precision)
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn >= '2023-01-01 12:00'
AND SmallDateTimeColumn < '2023-01-01 13:00';
SET STATISTICS IO OFF;
GO

-- 10. Edge cases

-- Minimum allowed value
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '1900-01-01 00:00';
SET STATISTICS IO OFF;
GO

-- Maximum allowed value
SET STATISTICS IO ON;
SELECT * FROM SmallDateTimeIndexTest 
WHERE SmallDateTimeColumn = '2079-06-06 23:59';
SET STATISTICS IO OFF;
GO

-- 7. Expression Testing:
-- Create table with SMALLDATETIME
CREATE TABLE SmallDateTimeExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    SmallDateTimeColumn SMALLDATETIME,
    NullableSmallDateTimeColumn SMALLDATETIME NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data (note: only hours and minutes, no seconds or milliseconds)
INSERT INTO SmallDateTimeExpressionTest (SmallDateTimeColumn, NullableSmallDateTimeColumn, Description)
VALUES 
('2023-01-01 00:00', '2023-01-01 09:00', 'New Year'),
('2023-02-14 12:30', '2023-02-14 14:15', 'Valentine''s Day'),
('2023-03-17 15:45', NULL, 'St. Patrick''s Day'),
('2023-04-01 08:20', '2023-04-01 10:30', 'April Fool''s Day'),
('2023-05-01 14:00', NULL, 'May Day'),
('2023-06-21 12:00', '2023-06-21 13:45', 'Summer Solstice'),
('2023-07-04 18:30', '2023-07-04 20:00', 'Independence Day'),
('2023-08-15 09:15', NULL, 'August Holiday'),
('2023-09-22 16:45', '2023-09-22 17:30', 'Autumn Equinox'),
('2023-10-31 20:00', '2023-10-31 23:59', 'Halloween'),
('2023-11-23 11:30', NULL, 'Thanksgiving'),
('2023-12-25 07:00', '2023-12-25 12:00', 'Christmas');
GO

-- 1. Conditional Expressions with Time Components

-- CASE statements including time
SELECT 
    SmallDateTimeColumn,
    CASE 
        WHEN SmallDateTimeColumn BETWEEN '2023-03-01 00:00' AND '2023-05-31 23:59' THEN 'Spring'
        WHEN SmallDateTimeColumn BETWEEN '2023-06-01 00:00' AND '2023-08-31 23:59' THEN 'Summer'
        WHEN SmallDateTimeColumn BETWEEN '2023-09-01 00:00' AND '2023-11-30 23:59' THEN 'Autumn'
        ELSE 'Winter'
    END AS Season,
    CASE 
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    Description
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- COALESCE with time
SELECT 
    ID,
    COALESCE(NullableSmallDateTimeColumn, SmallDateTimeColumn, CAST('1900-01-01 00:00' AS SMALLDATETIME)) AS CoalescedSmallDateTime,
    Description
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- NULLIF with time
SELECT 
    ID,
    NULLIF(SmallDateTimeColumn, '2023-01-01 00:00') AS NullIfNewYear,
    Description
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- IIF with time components
SELECT 
    SmallDateTimeColumn,
    IIF(DATEPART(HOUR, SmallDateTimeColumn) < 12, 'AM', 'PM') AS AMPM,
    IIF(DATEPART(QUARTER, SmallDateTimeColumn) <= 2, 'First Half', 'Second Half') AS HalfOfYear,
    Description
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- 2. Aggregate Expressions with Time

-- MAX/MIN including time
SELECT 
    MAX(SmallDateTimeColumn) AS LatestSmallDateTime,
    MIN(SmallDateTimeColumn) AS EarliestSmallDateTime
FROM SmallDateTimeExpressionTest;
GO

-- Time-based grouping
SELECT 
    DATEPART(HOUR, SmallDateTimeColumn) AS Hour,
    COUNT(*) AS EventCount
FROM SmallDateTimeExpressionTest
GROUP BY DATEPART(HOUR, SmallDateTimeColumn)
ORDER BY Hour;
GO

-- UNIONS with time
SELECT SmallDateTimeColumn 
FROM SmallDateTimeExpressionTest 
WHERE DATEPART(HOUR, SmallDateTimeColumn) < 12
UNION
SELECT SmallDateTimeColumn 
FROM SmallDateTimeExpressionTest 
WHERE DATEPART(HOUR, SmallDateTimeColumn) >= 12
ORDER BY SmallDateTimeColumn;
GO

-- 3. SmallDateTime-specific Functions

-- SmallDateTime arithmetic (note: minute precision)
SELECT 
    SmallDateTimeColumn,
    DATEADD(MINUTE, 15, SmallDateTimeColumn) AS Plus15Minutes,
    DATEADD(HOUR, 1, SmallDateTimeColumn) AS PlusOneHour,
    DATEADD(DAY, 1, SmallDateTimeColumn) AS PlusOneDay
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- SmallDateTime parts
SELECT 
    SmallDateTimeColumn,
    YEAR(SmallDateTimeColumn) AS Year,
    MONTH(SmallDateTimeColumn) AS Month,
    DAY(SmallDateTimeColumn) AS Day,
    DATEPART(HOUR, SmallDateTimeColumn) AS Hour,
    DATEPART(MINUTE, SmallDateTimeColumn) AS Minute
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- SmallDateTime differences
SELECT 
    SmallDateTimeColumn,
    DATEDIFF(MINUTE, '2023-01-01', SmallDateTimeColumn) AS MinutesSinceNewYear,
    DATEDIFF(HOUR, '2023-01-01', SmallDateTimeColumn) AS HoursSinceNewYear,
    DATEDIFF(DAY, '2023-01-01', SmallDateTimeColumn) AS DaysSinceNewYear
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- Complex time-based conditions
SELECT 
    SmallDateTimeColumn,
    CASE 
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 0 AND 5 THEN 'Night'
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS TimeOfDay,
    CASE 
        WHEN DATEPART(WEEKDAY, SmallDateTimeColumn) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- Time-based window functions
SELECT 
    SmallDateTimeColumn,
    Description,
    LAG(SmallDateTimeColumn) OVER (ORDER BY SmallDateTimeColumn) AS PreviousSmallDateTime,
    LEAD(SmallDateTimeColumn) OVER (ORDER BY SmallDateTimeColumn) AS NextSmallDateTime,
    DATEDIFF(MINUTE, LAG(SmallDateTimeColumn) OVER (ORDER BY SmallDateTimeColumn), SmallDateTimeColumn) AS MinutesSincePrevious
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- SmallDateTime grouping and aggregation
SELECT 
    DATEPART(HOUR, SmallDateTimeColumn) AS Hour,
    COUNT(*) AS EventCount,
    MIN(SmallDateTimeColumn) AS EarliestEvent,
    MAX(SmallDateTimeColumn) AS LatestEvent,
    AVG(CAST(DATEPART(MINUTE, SmallDateTimeColumn) AS FLOAT)) AS AvgMinute
FROM SmallDateTimeExpressionTest
GROUP BY DATEPART(HOUR, SmallDateTimeColumn)
ORDER BY Hour;
GO

-- Rounding to hour (since SMALLDATETIME is already minute-precise)
SELECT 
    SmallDateTimeColumn,
    DATEADD(HOUR, DATEDIFF(HOUR, 0, SmallDateTimeColumn), 0) AS RoundedToHour
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- Time range overlaps
SELECT 
    a.SmallDateTimeColumn AS SmallDateTime1,
    b.SmallDateTimeColumn AS SmallDateTime2,
    CASE 
        WHEN a.SmallDateTimeColumn BETWEEN b.SmallDateTimeColumn AND DATEADD(HOUR, 1, b.SmallDateTimeColumn) THEN 'Overlaps'
        ELSE 'No Overlap'
    END AS OverlapStatus
FROM SmallDateTimeExpressionTest a
CROSS JOIN SmallDateTimeExpressionTest b
WHERE a.ID < b.ID ORDER BY b.SmallDateTimeColumn;
GO

-- Edge cases specific to SMALLDATETIME
SELECT 
    SmallDateTimeColumn,
    CASE 
        WHEN SmallDateTimeColumn < '1900-01-01' THEN 'Invalid - Before Range'
        WHEN SmallDateTimeColumn > '2079-06-06' THEN 'Invalid - After Range'
        ELSE 'Valid'
    END AS DateRangeCheck
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- Business hour check (considering minute precision)
SELECT 
    SmallDateTimeColumn,
    CASE 
        WHEN DATEPART(HOUR, SmallDateTimeColumn) BETWEEN 9 AND 16 
             AND DATEPART(WEEKDAY, SmallDateTimeColumn) NOT IN (1, 7) THEN 'Business Hours'
        ELSE 'Non-Business Hours'
    END AS BusinessHourStatus
FROM SmallDateTimeExpressionTest ORDER BY SmallDateTimeColumn;
GO

-- 8. Additional DATE Specific Tests:

-- Test arithmetic operations with SMALLDATETIME
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    DATEADD(YEAR, 1, @sdt) AS YearAdd,
    DATEADD(MONTH, 1, @sdt) AS MonthAdd,
    DATEADD(DAY, 1, @sdt) AS DayAdd,
    DATEADD(HOUR, 1, @sdt) AS HourAdd,
    DATEADD(MINUTE, 1, @sdt) AS MinuteAdd;
GO

-- Test DATEDIFF with different parts
DECLARE @sdt1 SMALLDATETIME = '2023-06-15 14:30';
DECLARE @sdt2 SMALLDATETIME = '2024-07-16 16:45';
SELECT 
    DATEDIFF(YEAR, @sdt1, @sdt2) AS YearDiff,
    DATEDIFF(MONTH, @sdt1, @sdt2) AS MonthDiff,
    DATEDIFF(DAY, @sdt1, @sdt2) AS DayDiff,
    DATEDIFF(HOUR, @sdt1, @sdt2) AS HourDiff,
    DATEDIFF(MINUTE, @sdt1, @sdt2) AS MinuteDiff;
GO

-- Test DATETRUNC function
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    DATETRUNC(YEAR, @sdt) AS YearTrunc,
    DATETRUNC(MONTH, @sdt) AS MonthTrunc,
    DATETRUNC(DAY, @sdt) AS DayTrunc,
    DATETRUNC(HOUR, @sdt) AS HourTrunc,
    DATETRUNC(MINUTE, @sdt) AS MinuteTrunc;
GO

-- Test EOMONTH function (converts to smalldatetime)
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    CAST(EOMONTH(@sdt) AS SMALLDATETIME) AS EndOfMonth,
    CAST(EOMONTH(@sdt, 1) AS SMALLDATETIME) AS EndOfNextMonth,
    CAST(EOMONTH(@sdt, -1) AS SMALLDATETIME) AS EndOfPreviousMonth;
GO

-- Test conversion to and from other date/time types
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    @sdt AS Original,
    CAST(@sdt AS DATE) AS ToDate,
    CAST(@sdt AS DATETIME) AS ToDateTime,
    CAST(@sdt AS DATETIME2) AS ToDateTime2,
    CAST(@sdt AS DATETIMEOFFSET) AS ToDateTimeOffset,
    CAST(@sdt AS TIME) AS ToTime;
GO

-- Test with different datetime formats
SET LANGUAGE us_english;
SELECT CAST('06/15/2023 14:30' AS SMALLDATETIME);
SET LANGUAGE British;
SELECT CAST('15/06/2023 14:30' AS SMALLDATETIME);
GO

-- Test with different language settings
SET LANGUAGE German;
SELECT DATENAME(MONTH, CAST('2023-06-15 14:30' AS SMALLDATETIME));
SET LANGUAGE French;
SELECT DATENAME(MONTH, CAST('2023-06-15 14:30' AS SMALLDATETIME));
GO
SET LANGUAGE us_english;
GO

-- Test with different DATEFIRST settings
SET DATEFIRST 1;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15 14:30' AS SMALLDATETIME));
SET DATEFIRST 7;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15 14:30' AS SMALLDATETIME));
GO

-- Error Handling Tests
-- Test out-of-range values
BEGIN TRY
    DECLARE @sdt SMALLDATETIME = '2080-01-01 00:00';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid datetime formats
BEGIN TRY
    SELECT CAST('2023-13-45 25:61' AS SMALLDATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid datetime values
BEGIN TRY
    SELECT CAST('2023-02-30 14:30' AS SMALLDATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test DATE_BUCKET function
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    DATE_BUCKET(WEEK, 1, @sdt) AS WeekBucket,
    DATE_BUCKET(MONTH, 1, @sdt) AS MonthBucket,
    DATE_BUCKET(YEAR, 1, @sdt) AS YearBucket;
GO

-- Test with different century dates
SELECT 
    CAST('1900-01-01 00:00' AS SMALLDATETIME) AS MinSmallDateTime,
    CAST('2000-01-01 00:00' AS SMALLDATETIME) AS Year2000,
    CAST('2079-06-06 23:59' AS SMALLDATETIME) AS MaxSmallDateTime;
GO

-- Test leap year handling
SELECT 
    ISDATE('2023-02-29 14:30') AS [2023 (non-leap year)],
    ISDATE('2024-02-29 14:30') AS [2024 (leap year)];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(SMALLDATETIME, '06/15/2023 14:30', 101) AS Style101,
    CONVERT(SMALLDATETIME, '15.06.2023 14:30', 104) AS Style104,
    CONVERT(SMALLDATETIME, '15 Jun 2023 14:30', 106) AS Style106,
    CONVERT(SMALLDATETIME, '2023-06-15 14:30', 120) AS Style120;
GO

-- Test with DATEFORMAT setting
SET DATEFORMAT mdy;
SELECT CAST('06/15/2023 14:30' AS SMALLDATETIME);
SET DATEFORMAT dmy;
SELECT CAST('15/06/2023 14:30' AS SMALLDATETIME);
GO
SET DATEFORMAT mdy;
GO

-- Test datetime parts extraction
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    YEAR(@sdt) AS [Year],
    MONTH(@sdt) AS [Month],
    DAY(@sdt) AS [Day],
    DATEPART(HOUR, @sdt) AS [Hour],
    DATEPART(MINUTE, @sdt) AS [Minute],
    DATEPART(QUARTER, @sdt) AS [Quarter],
    DATEPART(DAYOFYEAR, @sdt) AS [DayOfYear],
    DATEPART(WEEK, @sdt) AS [Week],
    DATEPART(WEEKDAY, @sdt) AS [Weekday];
GO

-- Test with different languages for datetime parts
SET LANGUAGE Italian;
SELECT 
    DATENAME(MONTH, '2023-06-15 14:30') AS [Italian Month],
    DATENAME(WEEKDAY, '2023-06-15 14:30') AS [Italian Weekday];
SET LANGUAGE English;
SELECT 
    DATENAME(MONTH, '2023-06-15 14:30') AS [English Month],
    DATENAME(WEEKDAY, '2023-06-15 14:30') AS [English Weekday];
GO

-- Test SMALLDATETIME range
SELECT 
    CAST('1900-01-01 00:00' AS SMALLDATETIME) AS [Minimum SMALLDATETIME],
    CAST('2079-06-06 23:59' AS SMALLDATETIME) AS [Maximum SMALLDATETIME];
GO

-- Test with time zone conversion
DECLARE @sdt SMALLDATETIME = '2023-06-15 14:30';
SELECT 
    @sdt AS [Original SmallDateTime],
    CAST(@sdt AT TIME ZONE 'UTC' AS SMALLDATETIME) AS [UTC],
    CAST(@sdt AT TIME ZONE 'Pacific Standard Time' AS SMALLDATETIME) AS [Pacific Time];
GO

-- Test minute rounding
SELECT 
    CAST('2023-06-15 14:30:29' AS SMALLDATETIME) AS [Round Down],
    CAST('2023-06-15 14:30:31' AS SMALLDATETIME) AS [Round Up];
GO

-- Test boundary conditions
BEGIN TRY
    SELECT CAST('1899-12-31 23:59' AS SMALLDATETIME); -- Before minimum
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [Before Min Error];
END CATCH
GO

BEGIN TRY
    SELECT CAST('2079-06-06 24:00' AS SMALLDATETIME); -- After maximum
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS [After Max Error];
END CATCH
GO

-- Test minute precision
SELECT 
    CAST('2023-06-15 14:30:00' AS SMALLDATETIME) AS [Exact Minute],
    CAST('2023-06-15 14:30:29.999' AS SMALLDATETIME) AS [Round Down to Minute],
    CAST('2023-06-15 14:30:30.000' AS SMALLDATETIME) AS [Round Up to Minute];
GO

-- Test AM/PM format
SELECT 
    CAST('2023-06-15 2:30 PM' AS SMALLDATETIME) AS [PM Time],
    CAST('2023-06-15 2:30 AM' AS SMALLDATETIME) AS [AM Time];
GO

-- Clean up: Drop all created objects
DROP TABLE SmalldateTimeTest;
DROP TABLE SmalldateTimeDefaultTest;
DROP FUNCTION dbo.GetCurrentSmallDateTime;
DROP TYPE MySmallDateTime;
DROP TABLE SmalldateTimeFormatTest;
DROP PROCEDURE InsertSmalldateTimeTest;
DROP PROCEDURE InsertSmallDateTimeTest1;
DROP PROCEDURE TestSmallDateTimeFormat;
DROP TABLE SmallDateTimeConversionTest;
DROP PROCEDURE InsertSmallDateTimeConversionTest;
DROP TABLE SmallDateTimeZoneTest;
DROP PROCEDURE InsertSmallDateTimeZoneTest;
DROP TABLE UDDTSmallDateTimeTest;
DROP PROCEDURE TestUDDTSmallDateTimeProc;
DROP TYPE BusinessSmallDateTime;
DROP TYPE HistoricalSmallDateTime;
DROP FUNCTION dbo.TestSmallDateTimeFunction;
DROP TABLE SmallDateTimeImplicitConversionTest;
DROP PROCEDURE InsertSmallDateTimeTestResult;
DROP FUNCTION dbo.AddDaysToSmallDateTime;
DROP PROCEDURE dbo.ProcessSmallDateTime;
DROP VIEW dbo.SmallDateTimeView;
DROP TABLE SmallDateTimeDMLTestChild;
DROP TABLE SmallDateTimeDMLTest;
DROP TABLE SmallDateTimeIndexTest;
DROP TABLE SmallDateTimeExpressionTest;
DROP TABLE SmallDateTimeTest1;
DROP TABLE SMALLDATETIME_partition;
DROP PARTITION SCHEME SMALLDATETIME_partition_scheme;
DROP PARTITION FUNCTION SMALLDATETIME_partition_func;
GO
