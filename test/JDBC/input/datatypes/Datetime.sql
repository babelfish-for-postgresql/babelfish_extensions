-- sla 200000
-- 1. Basic Testing:
-- Create DateTimeTest table
CREATE TABLE DateTimeTest (
    ID INT IDENTITY PRIMARY KEY,
    DateTimeCol DATETIME
);
GO

-- Empty/NULL values
INSERT INTO DateTimeTest (DateTimeCol) VALUES (NULL);
GO
Declare @a datetime;
INSERT INTO DateTimeTest (DateTimeCol) VALUES (@a), ('');
GO
SELECT * FROM DateTimeTest WHERE DateTimeCol IS NULL ORDER BY ID;
GO
SELECT * FROM DateTimeTest ORDER BY ID;
GO

-- Default values
CREATE TABLE DateTimeDefaultTest (
    ID INT PRIMARY KEY,
    DateTimeCol DATETIME
);
INSERT INTO DateTimeDefaultTest VALUES (1, CAST('19:00:00' As datetime));
INSERT INTO DateTimeDefaultTest VALUES (2, CAST('1910-01-01' As datetime));
SELECT * FROM DateTimeDefaultTest ORDER BY ID;
GO

-- Character length
DECLARE @d DATETIME = '  2023-06-15 19:00:00  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO
DECLARE @d DATETIME = '  2023-06-15 19:00:00.004  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO
DECLARE @d DATETIME = '  2023-06-15  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO
DECLARE @d DATETIME = '  2023-06-15 19:00:00.0100  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

-- Edge case values
DECLARE @d1 DATETIME = '1753-01-01 00:00:00.000';
SELECT @d1;
GO
DECLARE @d2 DATETIME = '1753-01-01 23:59:59.997';
SELECT @d2;
GO
DECLARE @d3 DATETIME = '1753-01-01 23:59:59.999';
SELECT @d3;
GO
DECLARE @d4 DATETIME = '9999-12-31 23:59:59.997 +5:00';
SELECT @d4;
GO
DECLARE @d5 DATETIME = '9999-12-31 23:59:59.997 -5:00';
SELECT @d5;
GO
DECLARE @d6 DATETIME = '9999-12-31 23:59:59.999 +5:00';
SELECT @d6;
GO
DECLARE @d7 DATETIME = '9999-12-31 23:59:59.999 -5:00';
SELECT @d7;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d DATETIME;
SET @d = '2023-06-15 19:00:00.005';
SELECT @d, CAST('2023-06-15 19:00:00.005' AS DATETIME), CONVERT(DATETIME, '2023-06-15 19:00:00.005');
GO

-- DATEFORMAT tests
-- Create a test table
CREATE TABLE DateTimeFormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ParsedDate DATETIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTimeFormatTest (Description, InputString, ParsedDate)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Numeric Formats with All DATEFORMAT Settings
-- Testing each separator (/, -, .) with each date format order
SET DATEFORMAT mdy;
GO
EXEC InsertDateTimeTest 'MDY Slash Full', '04/15/1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY Slash Short', '4/15/96 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY Hyphen Full', '04-15-1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY Hyphen Short', '4-15-96 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY Period Full', '04.15.1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY Period Short', '4.15.96 14:30:20.123';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertDateTimeTest 'DMY Slash Full', '15/04/1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY Slash Short', '15/4/96 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY Hyphen Full', '15-04-1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY Hyphen Short', '15-4-96 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY Period Full', '15.04.1996 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY Period Short', '15.4.96 14:30:20.123';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertDateTimeTest 'YMD Slash Full', '1996/04/15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD Slash Short', '96/4/15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD Hyphen Full', '1996-04-15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD Hyphen Short', '96-4-15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD Period Full', '1996.04.15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD Period Short', '96.4.15 14:30:20.123';
GO

SET DATEFORMAT myd;
GO
EXEC InsertDateTimeTest 'MYD Slash Full', '04/1996/15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MYD Slash Short', '4/96/15 14:30:20.123';
GO

SET DATEFORMAT dym;
GO
EXEC InsertDateTimeTest 'DYM Slash Full', '15/1996/04 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DYM Slash Short', '15/96/4 14:30:20.123';
GO

SET DATEFORMAT ydm;
GO
EXEC InsertDateTimeTest 'YDM Slash Full', '1996/15/04 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YDM Slash Short', '96/15/4 14:30:20.123';
GO

-- 2. Time Formats (All Variations)
EXEC InsertDateTimeTest 'Time 24hr Full', '1996-04-15 14:30:20.123';
GO
EXEC InsertDateTimeTest 'Time 24hr No Seconds', '1996-04-15 14:30';
GO
EXEC InsertDateTimeTest 'Time 24hr No MS', '1996-04-15 14:30:20';
GO
EXEC InsertDateTimeTest 'Time AM Variations', '1996-04-15 4:30:20 AM';
GO
EXEC InsertDateTimeTest 'Time AM Short', '1996-04-15 4 AM';
GO
EXEC InsertDateTimeTest 'Time PM Variations', '1996-04-15 4:30:20 PM';
GO
EXEC InsertDateTimeTest 'Time PM Short', '1996-04-15 4 PM';
GO
EXEC InsertDateTimeTest 'Time AM No Space', '1996-04-15 4:30:20AM';
GO
EXEC InsertDateTimeTest 'Time PM No Space', '1996-04-15 4:30:20PM';
GO

-- 3. Alphabetical Formats (All Month Variations)
-- Full month name variations
EXEC InsertDateTimeTest 'Alpha Full MDY Comma', 'April 15, 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Full MDY No Comma', 'April 15 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Full DMY', '15 April 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Full YMD', '1996 April 15 14:30:20';
GO

-- Abbreviated month name variations
EXEC InsertDateTimeTest 'Alpha Abbr MDY Comma', 'Apr 15, 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Abbr MDY No Comma', 'Apr 15 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Abbr DMY', '15 Apr 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Alpha Abbr YMD', '1996 Apr 15 14:30:20';
GO

-- Mixed case variations
EXEC InsertDateTimeTest 'Alpha Mixed Case', 'aPrIl 15, 1996 14:30:20';
GO

-- 4. ISO 8601 Formats
EXEC InsertDateTimeTest 'ISO8601 Basic', '19960415T143020';
GO
EXEC InsertDateTimeTest 'ISO8601 Extended', '1996-04-15T14:30:20';
GO
EXEC InsertDateTimeTest 'ISO8601 With MS', '1996-04-15T14:30:20.123';
GO
EXEC InsertDateTimeTest 'ISO8601 Basic With Space', '19960415 14:30:20';
GO
EXEC InsertDateTimeTest 'ISO8601 Extended With Space', '1996-04-15 14:30:20';
GO

-- 5. ODBC Canonical Formats
EXEC InsertDateTimeTest 'ODBC Timestamp Full', '{ts ''1996-04-15 14:30:20.123''}';
GO
EXEC InsertDateTimeTest 'ODBC Timestamp No MS', '{ts ''1996-04-15 14:30:20''}';
GO
EXEC InsertDateTimeTest 'ODBC Date Only', '{d ''1996-04-15''}';
GO
EXEC InsertDateTimeTest 'ODBC Time Only', '{t ''14:30:20''}';
GO

-- 6. Precision/Rounding Tests
EXEC InsertDateTimeTest 'Round 000ms', '1996-04-15 14:30:20.000';
GO
EXEC InsertDateTimeTest 'Round 001ms', '1996-04-15 14:30:20.001';
GO
EXEC InsertDateTimeTest 'Round 002ms', '1996-04-15 14:30:20.002';
GO
EXEC InsertDateTimeTest 'Round 003ms', '1996-04-15 14:30:20.003';
GO
EXEC InsertDateTimeTest 'Round 004ms', '1996-04-15 14:30:20.004';
GO
EXEC InsertDateTimeTest 'Round 005ms', '1996-04-15 14:30:20.005';
GO
EXEC InsertDateTimeTest 'Round 997ms', '1996-04-15 14:30:20.997';
GO
EXEC InsertDateTimeTest 'Round 998ms', '1996-04-15 14:30:20.998';
GO
EXEC InsertDateTimeTest 'Round 999ms', '1996-04-15 14:30:20.999';
GO

-- 7. Language-Specific Formats
SET LANGUAGE French;
GO
EXEC InsertDateTimeTest 'French Full', N'15 avril 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'French Abbreviated', N'15 avr. 1996 14:30:20';
GO

SET LANGUAGE German;
GO
EXEC InsertDateTimeTest 'German Full', N'15. April 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'German Abbreviated', N'15. Apr 1996 14:30:20';
GO

SET LANGUAGE Spanish;
GO
EXEC InsertDateTimeTest 'Spanish Full', N'15 de abril de 1996 14:30:20';
GO
EXEC InsertDateTimeTest 'Spanish Abbreviated', N'15 abr. 1996 14:30:20';
GO

SET LANGUAGE us_english;
GO

-- 8. Edge Cases and Boundary Tests
EXEC InsertDateTimeTest 'Min DateTime', '1753-01-01 00:00:00';
GO
EXEC InsertDateTimeTest 'Max DateTime', '9999-12-31 23:59:59.997';
GO
EXEC InsertDateTimeTest 'Leap Year', '2000-02-29 14:30:20';
GO
EXEC InsertDateTimeTest 'Century Transition', '2000-01-01 00:00:00';
GO

-- 9. Invalid Formats (These should fail)
EXEC InsertDateTimeTest 'Invalid Before 1753', '1752-12-31 14:30:20';
GO
EXEC InsertDateTimeTest 'Invalid After 9999', '10000-01-01 14:30:20';
GO
EXEC InsertDateTimeTest 'Invalid Month', '1996-13-15 14:30:20';
GO
EXEC InsertDateTimeTest 'Invalid Day', '1996-04-31 14:30:20';
GO
EXEC InsertDateTimeTest 'Invalid Hour', '1996-04-15 24:30:20';
GO
EXEC InsertDateTimeTest 'Invalid Minute', '1996-04-15 14:60:20';
GO
EXEC InsertDateTimeTest 'Invalid Second', '1996-04-15 14:30:60';
GO
EXEC InsertDateTimeTest 'Invalid Millisecond', '1996-04-15 14:30:20.1234';
GO

-- Additional combinations
SET DATEFORMAT mdy;
GO

-- d,mm,yyyy variations with time
EXEC InsertDateTimeTest 'MDY - d,mm,yyyy - Comma with time', '5,06,2023 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY - d,mm,yyyy - Comma with AM/PM', '5,06,2023 2:30:20.123 PM';
GO
EXEC InsertDateTimeTest 'MDY - d,mm,yyyy - Period with time', '5.06.2023 14:30:20';
GO
EXEC InsertDateTimeTest 'MDY - d,mm,yyyy - Hyphen with time', '5-06-2023 14:30';
GO
EXEC InsertDateTimeTest 'MDY - d,mm,yyyy - Space with time', '5 06 2023 2:30PM';
GO

-- dd,m,yy variations with time
EXEC InsertDateTimeTest 'MDY - dd,m,yy - Comma with time', '05,6,23 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY - dd,m,yy - Comma with AM/PM', '05,6,23 2:30:20.123 PM';
GO
EXEC InsertDateTimeTest 'MDY - dd,m,yy - Period with time', '05.6.23 14:30:20';
GO
EXEC InsertDateTimeTest 'MDY - dd,m,yy - Hyphen with time', '05-6-23 14:30';
GO
EXEC InsertDateTimeTest 'MDY - dd,m,yy - Space with time', '05 6 23 2:30PM';
GO

-- Additional time format variations for each date format
-- Full pattern: date [time[:seconds[.milliseconds]]] [AM/PM]

-- d,m,yy variations with different time formats
EXEC InsertDateTimeTest 'MDY - d,m,yy - Basic time', '5,6,23 14:30';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - With seconds', '5,6,23 14:30:20';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - With milliseconds', '5,6,23 14:30:20.123';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - AM time', '5,6,23 10:30:20 AM';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - PM time', '5,6,23 2:30:20 PM';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - Short AM', '5,6,23 10AM';
GO
EXEC InsertDateTimeTest 'MDY - d,m,yy - Short PM', '5,6,23 2PM';
GO

-- Time variations with different separators
EXEC InsertDateTimeTest 'Time sep - Colon', '5,6,2023 14:30:20';
GO
EXEC InsertDateTimeTest 'Time sep - Period', '5,6,2023 14.30.20';
GO
EXEC InsertDateTimeTest 'Time sep - Mixed', '5,6,2023 14:30.20';
GO

SET DATEFORMAT dmy;
GO

-- DMY variations with time components
EXEC InsertDateTimeTest 'DMY - d,mm,yyyy - Full time', '5,06,2023 14:30:20.123';
GO
EXEC InsertDateTimeTest 'DMY - d,mm,yyyy - AM/PM', '5,06,2023 2:30:20.123 PM';
GO
EXEC InsertDateTimeTest 'DMY - dd,m,yy - Basic time', '05,6,23 14:30';
GO
EXEC InsertDateTimeTest 'DMY - dd,m,yy - With seconds', '05,6,23 14:30:20';
GO
EXEC InsertDateTimeTest 'DMY - d,m,y - Short time AM', '5,6,3 10AM';
GO
EXEC InsertDateTimeTest 'DMY - d,m,y - Short time PM', '5,6,3 2PM';
GO

SET DATEFORMAT ymd;
GO

-- YMD variations with time components
EXEC InsertDateTimeTest 'YMD - yyyy,m,d - Full time', '2023,6,5 14:30:20.123';
GO
EXEC InsertDateTimeTest 'YMD - yyyy,m,d - AM/PM', '2023,6,5 2:30:20.123 PM';
GO
EXEC InsertDateTimeTest 'YMD - yy,mm,dd - Basic time', '23,06,05 14:30';
GO
EXEC InsertDateTimeTest 'YMD - yy,mm,dd - With seconds', '23,06,05 14:30:20';
GO
EXEC InsertDateTimeTest 'YMD - y,m,d - Short time AM', '3,6,5 10AM';
GO
EXEC InsertDateTimeTest 'YMD - y,m,d - Short time PM', '3,6,5 2PM';
GO

-- ISO 8601 style combinations
EXEC InsertDateTimeTest 'ISO - Basic with T', '2023,06,05T14:30:20.123';
GO
EXEC InsertDateTimeTest 'ISO - Extended with T', '2023-06-05T14:30:20.123';
GO

-- Mixed format variations
EXEC InsertDateTimeTest 'Mixed - Date/Time separators', '2023/06/05 14:30:20.123';
GO
EXEC InsertDateTimeTest 'Mixed - Date.Time separators', '2023.06.05 14:30:20.123';
GO
EXEC InsertDateTimeTest 'Mixed - Date Time separators', '2023 06 05 14:30:20.123';
GO

-- Time precision variations
EXEC InsertDateTimeTest 'Time - Hours only', '2023,06,05 14';
GO
EXEC InsertDateTimeTest 'Time - Hours minutes', '2023,06,05 14:30';
GO
EXEC InsertDateTimeTest 'Time - Full precision', '2023,06,05 14:30:20.123';
GO
EXEC InsertDateTimeTest 'Time - Partial milliseconds', '2023,06,05 14:30:20.1';
GO

-- AM/PM variations
EXEC InsertDateTimeTest 'AMPM - Standard', '2023,06,05 2:30:20 PM';
GO
EXEC InsertDateTimeTest 'AMPM - No space', '2023,06,05 2:30:20PM';
GO
EXEC InsertDateTimeTest 'AMPM - Lowercase', '2023,06,05 2:30:20 pm';
GO
EXEC InsertDateTimeTest 'AMPM - Mixed case', '2023,06,05 2:30:20 Pm';
GO

-- Edge cases with time
EXEC InsertDateTimeTest 'Edge - Midnight', '2023,06,05 00:00:00.000';
GO
EXEC InsertDateTimeTest 'Edge - Almost midnight', '2023,06,05 23:59:59.997';
GO
EXEC InsertDateTimeTest 'Edge - Noon', '2023,06,05 12:00:00.000';
GO
EXEC InsertDateTimeTest 'Edge - Almost noon', '2023,06,05 11:59:59.997';
GO

-- Invalid time formats (these should fail)
EXEC InsertDateTimeTest 'Invalid - Bad hour', '2023,06,05 24:00:00';
GO
EXEC InsertDateTimeTest 'Invalid - Bad minute', '2023,06,05 14:60:00';
GO
EXEC InsertDateTimeTest 'Invalid - Bad second', '2023,06,05 14:30:60';
GO
EXEC InsertDateTimeTest 'Invalid - Bad millisecond', '2023,06,05 14:30:20.1234';
GO
EXEC InsertDateTimeTest 'Invalid - Bad AM/PM', '2023,06,05 14:30:20 AMM';
GO

-- Helper procedure to insert test cases for DATETIME with collation
CREATE PROCEDURE InsertDateTimeTest1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO DateTimeFormatTest (Description, InputString, Collation, ParsedDateTime)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS DATETIME))';
        
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
CREATE PROCEDURE TestDateTimeFormat
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
        EXEC InsertDateTimeTest1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Now run tests with different collations for each format

-- Standard formats with time
EXEC TestDateTimeFormat 'Standard - YYYY-MM-DD HH:MI:SS.MSS', '2023-06-16 14:30:20.123';
GO
EXEC TestDateTimeFormat 'Standard - YYYYMMDD HH:MI:SS.MSS', '20230616 14:30:20.123';
GO

-- Month-day-year formats with time
SET DATEFORMAT mdy;
GO
EXEC TestDateTimeFormat 'MDY - Slash 24hr', '6/16/2023 14:30:20.123';
GO
EXEC TestDateTimeFormat 'MDY - Slash AM', '6/16/2023 10:30:20.123 AM';
GO
EXEC TestDateTimeFormat 'MDY - Slash PM', '6/16/2023 2:30:20.123 PM';
GO

-- Day-month-year formats with time
SET DATEFORMAT dmy;
GO
EXEC TestDateTimeFormat 'DMY - Slash 24hr', '16/6/2023 14:30:20.123';
GO
EXEC TestDateTimeFormat 'DMY - Hyphen AM', '16-6-2023 10:30:20.123 AM';
GO
EXEC TestDateTimeFormat 'DMY - Period PM', '16.6.2023 2:30:20.123 PM';
GO

-- Year-month-day formats with time
SET DATEFORMAT ymd;
GO
EXEC TestDateTimeFormat 'YMD - Slash 24hr', '2023/6/16 14:30:20.123';
GO
EXEC TestDateTimeFormat 'YMD - Hyphen AM', '2023-6-16 10:30:20.123 AM';
GO
EXEC TestDateTimeFormat 'YMD - Period PM', '2023.6.16 2:30:20.123 PM';
GO

-- Alphabetical formats with time
SET DATEFORMAT mdy;
GO
EXEC TestDateTimeFormat 'Alpha - Full month 24hr', 'June 16, 2023 14:30:20.123';
GO
EXEC TestDateTimeFormat 'Alpha - Full month AM', 'June 16, 2023 10:30:20.123 AM';
GO
EXEC TestDateTimeFormat 'Alpha - Abbr PM', 'Jun 16, 2023 2:30:20.123 PM';
GO

-- ISO 8601 formats with time
EXEC TestDateTimeFormat 'ISO 8601 - Basic', '20230616T143020.123';
GO
EXEC TestDateTimeFormat 'ISO 8601 - Extended', '2023-06-16T14:30:20.123';
GO

-- ODBC canonical format with time
EXEC TestDateTimeFormat 'ODBC canonical', '{ts ''2023-06-16 14:30:20.123''}';
GO

-- Different time precision tests
EXEC TestDateTimeFormat 'Time - Hours only', '2023-06-16 14';
GO
EXEC TestDateTimeFormat 'Time - Hours Minutes', '2023-06-16 14:30';
GO
EXEC TestDateTimeFormat 'Time - With Seconds', '2023-06-16 14:30:20';
GO
EXEC TestDateTimeFormat 'Time - With Milliseconds', '2023-06-16 14:30:20.123';
GO

-- Language-specific formats with time
SET LANGUAGE French;
GO
EXEC TestDateTimeFormat 'French - Full with time', N'16 juin 2023 14:30:20,123';
GO

SET LANGUAGE German;
GO
EXEC TestDateTimeFormat 'German - Full with time', N'16. Juni 2023 14:30:20,123';
GO

SET LANGUAGE us_english;
GO

-- Time separator variations
EXEC TestDateTimeFormat 'Time sep - Colon', '2023-06-16 14:30:20.123';
GO
EXEC TestDateTimeFormat 'Time sep - Period', '2023-06-16 14.30.20.123';
GO

-- Rounding tests
EXEC TestDateTimeFormat 'Round - 997ms', '2023-06-16 14:30:20.997';
GO
EXEC TestDateTimeFormat 'Round - 993ms', '2023-06-16 14:30:20.993';
GO
EXEC TestDateTimeFormat 'Round - 990ms', '2023-06-16 14:30:20.990';
GO

-- Edge cases with time
EXEC TestDateTimeFormat 'Edge - Minimum', '1753-01-01 00:00:00.000';
GO
EXEC TestDateTimeFormat 'Edge - Maximum', '9999-12-31 23:59:59.997';
GO
EXEC TestDateTimeFormat 'Edge - Leap Year', '2024-02-29 14:30:20.123';
GO

-- Invalid formats (these should fail across all collations)
EXEC TestDateTimeFormat 'Invalid - Bad Hour', '2023-06-16 24:00:00';
GO
EXEC TestDateTimeFormat 'Invalid - Bad Minute', '2023-06-16 14:60:00';
GO
EXEC TestDateTimeFormat 'Invalid - Bad Second', '2023-06-16 14:30:60';
GO
EXEC TestDateTimeFormat 'Invalid - Bad MS', '2023-06-16 14:30:20.1234';
GO

-- Display results
SELECT * FROM DateTimeFormatTest ORDER BY ID;
GO

-- Create a test table
CREATE TABLE DateTimeConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedDateTime DATETIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeConversionTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTimeConversionTest (Description, InputString, ConvertedDateTime)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC Formats
EXEC InsertDateTimeConversionTest 'ODBC DATE', '{d ''2023-06-16''}';
GO
EXEC InsertDateTimeConversionTest 'ODBC TIME', '{t ''12:34:56.123''}';
GO
EXEC InsertDateTimeConversionTest 'ODBC DATETIME', '{ts ''2023-06-16 12:34:56.123''}';
GO

-- ISO 8601 Formats
EXEC InsertDateTimeConversionTest 'ISO8601 Basic', '20230616T123456.123';
GO
EXEC InsertDateTimeConversionTest 'ISO8601 Extended', '2023-06-16T12:34:56.123';
GO
EXEC InsertDateTimeConversionTest 'ISO8601 Basic with space', '20230616 12:34:56.123';
GO
EXEC InsertDateTimeConversionTest 'ISO8601 Extended with space', '2023-06-16 12:34:56.123';
GO

-- Standard DateTime Formats
EXEC InsertDateTimeConversionTest 'Standard 24hr full', '2023-06-16 12:34:56.123';
GO
EXEC InsertDateTimeConversionTest 'Standard 12hr AM', '2023-06-16 10:34:56.123 AM';
GO
EXEC InsertDateTimeConversionTest 'Standard 12hr PM', '2023-06-16 2:34:56.123 PM';
GO

-- Different Time Precisions
EXEC InsertDateTimeConversionTest 'Time - Hours only', '2023-06-16 14';
GO
EXEC InsertDateTimeConversionTest 'Time - Hours Minutes', '2023-06-16 14:30';
GO
EXEC InsertDateTimeConversionTest 'Time - With Seconds', '2023-06-16 14:30:20';
GO
EXEC InsertDateTimeConversionTest 'Time - With Milliseconds', '2023-06-16 14:30:20.123';
GO

-- Different Date Separators with Time
EXEC InsertDateTimeConversionTest 'Date Slash with Time', '2023/06/16 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Date Hyphen with Time', '2023-06-16 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Date Period with Time', '2023.06.16 14:30:20.123';
GO

-- Different Time Separators
EXEC InsertDateTimeConversionTest 'Time Colon Sep', '2023-06-16 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Time Period Sep', '2023-06-16 14.30.20.123';
GO

-- Alphabetic Month Formats
EXEC InsertDateTimeConversionTest 'Full Month Name', 'June 16, 2023 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Abbreviated Month', 'Jun 16, 2023 14:30:20.123';
GO

-- Different Date Formats with Time
SET DATEFORMAT mdy;
GO
EXEC InsertDateTimeConversionTest 'MDY Format', '06/16/2023 14:30:20.123';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertDateTimeConversionTest 'DMY Format', '16/06/2023 14:30:20.123';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertDateTimeConversionTest 'YMD Format', '2023/06/16 14:30:20.123';
GO

SET DATEFORMAT mdy;
GO

-- Millisecond Rounding Tests
EXEC InsertDateTimeConversionTest 'Round 997ms', '2023-06-16 14:30:20.997';
GO
EXEC InsertDateTimeConversionTest 'Round 993ms', '2023-06-16 14:30:20.993';
GO
EXEC InsertDateTimeConversionTest 'Round 990ms', '2023-06-16 14:30:20.990';
GO

-- Edge Cases
EXEC InsertDateTimeConversionTest 'Minimum DateTime', '1753-01-01 00:00:00.000';
GO
EXEC InsertDateTimeConversionTest 'Maximum DateTime', '9999-12-31 23:59:59.997';
GO
EXEC InsertDateTimeConversionTest 'Leap Year DateTime', '2024-02-29 14:30:20.123';
GO

-- Language-Specific Formats
SET LANGUAGE French;
GO
EXEC InsertDateTimeConversionTest 'French DateTime', N'16 juin 2023 14:30:20,123';
GO

SET LANGUAGE German;
GO
EXEC InsertDateTimeConversionTest 'German DateTime', N'16. Juni 2023 14:30:20,123';
GO

SET LANGUAGE us_english;
GO

-- Invalid Conversions (these should fail)
EXEC InsertDateTimeConversionTest 'Invalid - Before 1753', '1752-12-31 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Invalid - After 9999', '10000-01-01 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Invalid Hour', '2023-06-16 24:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Invalid Minute', '2023-06-16 14:60:20.123';
GO
EXEC InsertDateTimeConversionTest 'Invalid Second', '2023-06-16 14:30:60.123';
GO
EXEC InsertDateTimeConversionTest 'Invalid Millisecond', '2023-06-16 14:30:20.1234';
GO

-- Mixed Format Tests
EXEC InsertDateTimeConversionTest 'Mixed Sep DateTime', '2023/06-16 14:30:20.123';
GO
EXEC InsertDateTimeConversionTest 'Mixed Time Format', '2023-06-16 14:30:20PM';
GO
EXEC InsertDateTimeConversionTest 'Mixed Style', '2023-June-16 14:30:20.123';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputString,
    ConvertedDateTime,
    FORMAT(ConvertedDateTime, 'yyyy-MM-dd HH:mm:ss.fff') as FormattedDateTime
FROM DateTimeConversionTest 
ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'datetime';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'datetime' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- AT TIME ZONE

-- Create a test table for DATETIME with time zones
CREATE TABLE DatetimeTimeZoneTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputDateTime DATETIME,
    TimeZone NVARCHAR(100),
    Result NVARCHAR(MAX)
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDatetimeTimeZoneTest
    @Description NVARCHAR(100),
    @InputDateTime DATETIME,
    @TimeZone NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @Result NVARCHAR(MAX);
        SET @Result = CAST(@InputDateTime AT TIME ZONE @TimeZone AS NVARCHAR(MAX));
        
        INSERT INTO DatetimeTimeZoneTest (Description, InputDateTime, TimeZone, Result)
        VALUES (@Description, @InputDateTime, @TimeZone, @Result);
        
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        INSERT INTO DatetimeTimeZoneTest (Description, InputDateTime, TimeZone, Result)
        VALUES (@Description, @InputDateTime, @TimeZone, ERROR_MESSAGE());
        
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Test cases with specific times
-- Standard time tests
EXEC InsertDatetimeTimeZoneTest 'Midnight UTC', '2023-06-16 00:00:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Noon UTC', '2023-06-16 12:00:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Evening UTC', '2023-06-16 18:30:00', 'UTC';
GO

-- Different time zones with specific times
EXEC InsertDatetimeTimeZoneTest 'Morning PST', '2023-06-16 09:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Afternoon EST', '2023-06-16 14:30:00', 'Eastern Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Evening CET', '2023-06-16 20:30:00', 'Central European Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Night JST', '2023-06-16 23:30:00', 'Tokyo Standard Time';
GO

-- DST transition times
EXEC InsertDatetimeTimeZoneTest 'DST Start PST Morning', '2023-03-12 01:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'DST Start PST Transition', '2023-03-12 02:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'DST Start PST After', '2023-03-12 03:30:00', 'Pacific Standard Time';
GO

EXEC InsertDatetimeTimeZoneTest 'DST End PST Before', '2023-11-05 01:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'DST End PST Transition', '2023-11-05 02:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'DST End PST After', '2023-11-05 03:30:00', 'Pacific Standard Time';
GO

-- Different times during summer
EXEC InsertDatetimeTimeZoneTest 'Summer Morning PST', '2023-07-15 09:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Summer Afternoon EST', '2023-07-15 14:30:00', 'Eastern Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Summer Evening CET', '2023-07-15 20:30:00', 'Central European Standard Time';
GO

-- Different times during winter
EXEC InsertDatetimeTimeZoneTest 'Winter Morning PST', '2023-12-15 09:30:00', 'Pacific Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Winter Afternoon EST', '2023-12-15 14:30:00', 'Eastern Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Winter Evening CET', '2023-12-15 20:30:00', 'Central European Standard Time';
GO

-- Time precision tests
EXEC InsertDatetimeTimeZoneTest 'Precision Test 1', '2023-06-16 14:30:20.123', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Precision Test 2', '2023-06-16 14:30:20.997', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Precision Test 3', '2023-06-16 14:30:20.000', 'UTC';
GO

-- Edge cases
EXEC InsertDatetimeTimeZoneTest 'Min DateTime UTC', '1753-01-01 00:00:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Max DateTime UTC', '9999-12-31 23:59:59.997', 'UTC';
GO

-- Time zones with different offsets
EXEC InsertDatetimeTimeZoneTest 'IST Midnight', '2023-06-16 00:00:00', 'India Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'NZ Noon', '2023-06-16 12:00:00', 'New Zealand Standard Time';
GO
EXEC InsertDatetimeTimeZoneTest 'Saudi Night', '2023-06-16 23:00:00', 'Saudi Arabia Standard Time';
GO

-- Cross day boundary tests
EXEC InsertDatetimeTimeZoneTest 'Day Boundary 1', '2023-06-16 23:30:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Day Boundary 2', '2023-06-16 00:30:00', 'UTC';
GO

-- Month boundary tests
EXEC InsertDatetimeTimeZoneTest 'Month Boundary 1', '2023-06-30 23:30:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Month Boundary 2', '2023-07-01 00:30:00', 'UTC';
GO

-- Year boundary tests
EXEC InsertDatetimeTimeZoneTest 'Year Boundary 1', '2023-12-31 23:30:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Year Boundary 2', '2024-01-01 00:30:00', 'UTC';
GO

-- Leap year tests
EXEC InsertDatetimeTimeZoneTest 'Leap Year Eve', '2024-02-28 23:30:00', 'UTC';
GO
EXEC InsertDatetimeTimeZoneTest 'Leap Year Day', '2024-02-29 00:30:00', 'UTC';
GO

-- Invalid scenarios
EXEC InsertDatetimeTimeZoneTest 'Invalid Time Zone', '2023-06-16 12:00:00', 'Invalid Time Zone';
GO
EXEC InsertDatetimeTimeZoneTest 'NULL Time Zone', '2023-06-16 12:00:00', NULL;
GO

-- Display results
SELECT 
    ID,
    Description,
    InputDateTime,
    TimeZone,
    Result,
    CASE 
        WHEN ISDATE(Result) = 1 THEN 'Valid DateTime'
        ELSE 'Invalid/Error'
    END AS ResultStatus
FROM DatetimeTimeZoneTest 
ORDER BY ID;
GO

-- different timezone
select set_config('timezone', 'Asia/Kolkata', false);
GO
SELECT CAST('2023-06-15 19:00:00' AS DATETIME), CAST('20230615' AS DATETIME), CAST('June 15, 2023' AS DATETIME);
GO
BEGIN TRANSACTION;
select set_config('timezone', 'America/Los_Angeles', false);
GO
SELECT CAST('2023-06-15 19:00:00' AS DATETIME), CAST('20230615' AS DATETIME), CAST('June 15, 2023' AS DATETIME);
GO
COMMIT TRANSACTION;
GO
SELECT CAST('2023-06-15 19:00:00' AS DATETIME), CAST('20230615' AS DATETIME), CAST('June 15, 2023' AS DATETIME);
GO
select set_config('timezone', 'UTC', false);
GO

-- Precedence Order of datatypes
SELECT CASE WHEN CAST('2023-06-15 19:00:00' AS DATETIME) = '2023-06-15 19:00:00' THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d DATETIME', @d = '2023-06-15 19:00:00';
GO

-- User Defined Datatypes on date datatypes
CREATE TYPE MyDateTime FROM DATETIME;
GO
DECLARE @md MyDateTime = '2023-06-15 19:00:00';
SELECT @md;
GO

-- 1. Create User-Defined Data Types based on DATETIME
CREATE TYPE BusinessDateTime FROM DATETIME;
CREATE TYPE HistoricalDateTime FROM DATETIME;
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTDateTimeTest (
    ID INT PRIMARY KEY,
    RegularDateTime DATETIME,
    BusinessDateTimeCol BusinessDateTime,
    HistoricalDateTimeCol HistoricalDateTime
);
GO

-- 3. Insert data with time components
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES 
(1, '2023-06-16 14:30:20.123', '2023-06-16 14:30:20.123', '1776-07-04 12:00:00'),
(2, '2023-06-17 09:15:45.667', '2023-06-17 09:15:45.667', '1945-08-15 11:30:00'),
(3, '2023-06-18 18:45:30.890', '2023-06-18 18:45:30.890', '2000-01-01 00:00:00'),
(4, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTDateTimeTest ORDER BY ID;
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
WHERE TABLE_NAME = 'UDDTDateTimeTest' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularDateTime AS VARCHAR(30)) AS RegularDateTimeString,
    CAST(BusinessDateTimeCol AS VARCHAR(30)) AS BusinessDateTimeString,
    CAST(HistoricalDateTimeCol AS VARCHAR(30)) AS HistoricalDateTimeString,
    CAST(RegularDateTime AS DATE) AS RegularDate,
    CAST(BusinessDateTimeCol AS TIME) AS BusinessTime,
    CAST(HistoricalDateTimeCol AS SMALLDATETIME) AS HistoricalSmallDateTime
FROM UDDTDateTimeTest ORDER BY ID;
GO

-- 7. Test datetime functions
SELECT 
    ID,
    DATEADD(HOUR, 1, RegularDateTime) AS RegularNextHour,
    DATEADD(MINUTE, 30, BusinessDateTimeCol) AS BusinessNext30Min,
    DATEADD(SECOND, 45, HistoricalDateTimeCol) AS HistoricalNext45Sec,
    DATEDIFF(SECOND, HistoricalDateTimeCol, BusinessDateTimeCol) AS SecondsBetween
FROM UDDTDateTimeTest ORDER BY ID;
GO

-- 8. Test constraints with time components
ALTER TABLE UDDTDateTimeTest ADD CONSTRAINT CK_BusinessDateTime 
    CHECK (BusinessDateTimeCol >= '2000-01-01 00:00:00' 
    AND BusinessDateTimeCol <= '2099-12-31 23:59:59.997');
GO

-- This should succeed
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES (5, '2023-06-19 15:30:00', '2023-06-19 15:30:00', '1989-11-09 12:00:00');
GO

-- This should fail
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES (6, '2023-06-20 15:30:00', '1999-12-31 23:59:59', '1989-11-09 12:00:00');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTDateTimeProc
    @BusinessDateTime BusinessDateTime,
    @HistoricalDateTime HistoricalDateTime
AS
BEGIN
    SELECT 
        @BusinessDateTime AS InputBusinessDateTime,
        @HistoricalDateTime AS InputHistoricalDateTime,
        DATEDIFF(SECOND, @HistoricalDateTime, @BusinessDateTime) AS SecondsBetween,
        DATEADD(HOUR, 1, @BusinessDateTime) AS BusinessDateTimePlusHour;
END
GO

-- Execute the stored procedure
EXEC TestUDDTDateTimeProc 
    @BusinessDateTime = '2023-06-16 14:30:20.123', 
    @HistoricalDateTime = '1776-07-04 12:00:00';
GO

-- 10. Test implicit conversions
DECLARE @RegularDateTime DATETIME = '2023-06-16 14:30:20.123';
DECLARE @BusinessDateTime BusinessDateTime = @RegularDateTime;
DECLARE @HistoricalDateTime HistoricalDateTime = '1776-07-04 12:00:00';

SELECT 
    @RegularDateTime AS RegularDateTime,
    @BusinessDateTime AS BusinessDateTime,
    @HistoricalDateTime AS HistoricalDateTime;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessDateTime ON UDDTDateTimeTest(BusinessDateTimeCol);
CREATE INDEX IX_HistoricalDateTime ON UDDTDateTimeTest(HistoricalDateTimeCol);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTDateTimeTest 
WHERE BusinessDateTimeCol BETWEEN '2023-06-16 00:00:00' AND '2023-06-16 23:59:59.997';
SELECT * FROM UDDTDateTimeTest 
WHERE HistoricalDateTimeCol BETWEEN '1776-07-04 00:00:00' AND '1776-07-04 23:59:59.997';
SET STATISTICS IO OFF;
GO

-- 12. Test with different datetime formats
SET DATEFORMAT mdy;
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES (7, '06/21/2023 15:30:20.123', '06/21/2023 15:30:20.123', '07/04/1776 12:00:00');
GO

SET DATEFORMAT dmy;
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES (8, '21/06/2023 15:30:20.123', '21/06/2023 15:30:20.123', '04/07/1776 12:00:00');
GO

SET DATEFORMAT mdy;
GO

-- 13. Test time precision
INSERT INTO UDDTDateTimeTest (ID, RegularDateTime, BusinessDateTimeCol, HistoricalDateTimeCol)
VALUES 
(9, '2023-06-16 14:30:20.123', '2023-06-16 14:30:20.123', '2000-01-01 00:00:00.000'),
(10, '2023-06-16 14:30:20.997', '2023-06-16 14:30:20.997', '2000-01-01 00:00:00.997');
GO

-- 14. Test time parts
SELECT 
    ID,
    DATEPART(HOUR, BusinessDateTimeCol) AS BusinessHour,
    DATEPART(MINUTE, BusinessDateTimeCol) AS BusinessMinute,
    DATEPART(SECOND, BusinessDateTimeCol) AS BusinessSecond,
    DATEPART(MILLISECOND, BusinessDateTimeCol) AS BusinessMillisecond
FROM UDDTDateTimeTest
WHERE ID IN (9, 10) ORDER BY ID;
GO

SELECT * FROM UDDTDateTimeTest WHERE ID IN (7, 8, 9, 10) ORDER BY ID;
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing for DATETIME
SELECT 
    CAST('2023-06-15 14:30:20.123' AS DATETIME),
    CONVERT(DATETIME, '2023-06-15 14:30:20.123'),
    TRY_CAST('2023-06-31 14:30:20.123' AS DATETIME),
    TRY_CONVERT(DATETIME, '2023-06-31 14:30:20.123'),
    FORMAT(CAST('2023-06-15 14:30:20.123' AS DATETIME), 'yyyy-MM-dd HH:mm:ss.fff');
GO

-- Explicit Conversion Tests for DATETIME

-- binary
SELECT CAST(CAST(0x0000A5BE9335E340 AS binary) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(0x AS binary) AS DATETIME); -- Negative
GO
SELECT CAST(CAST(0xFFFFFFFFFFFFFFFF AS binary) AS DATETIME); -- Negative
GO

-- varbinary
SELECT CAST(CAST(0x0000A5BE9335E340 AS VARBINARY) AS DATETIME); -- Positive
GO
SELECT CAST(0x AS DATETIME); -- Negative
GO
SELECT CAST(CAST(0xFFFFFFFFFFFFFFFF AS VARBINARY) AS DATETIME); -- Negative
GO

-- char
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS char) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS char(23)) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('20230616 14:30:20.123' AS char) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS char) AS DATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS char) AS DATETIME); -- NULL
GO
SELECT CAST(CAST('' AS char) AS DATETIME); -- Negative
GO

-- varchar
SELECT CAST(CAST('9999-12-31 23:59:59.997' AS varchar) AS DATETIME); -- Edge: Max
GO
SELECT CAST(CAST('10000-01-01 00:00:00' AS varchar) AS DATETIME); -- Negative
GO
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS varchar) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('20230616 14:30:20.123' AS varchar) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS varchar) AS DATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS varchar) AS DATETIME); -- NULL
GO
SELECT CAST(CAST('' AS varchar) AS DATETIME); -- Negative
GO

-- nchar
SELECT CAST(CAST(N'2023-06-16 14:30:20.123' AS NCHAR) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(N'1753-01-01 00:00:00' AS NCHAR) AS DATETIME); -- Edge: Min
GO
SELECT CAST(CAST(N'1752-12-31 23:59:59' AS NCHAR) AS DATETIME); -- Negative
GO
SELECT CAST(CAST(NULL AS nchar) AS DATETIME); -- NULL
GO
SELECT CAST(CAST(N'' AS nchar) AS DATETIME); -- Negative
GO

-- nvarchar
SELECT CAST(N'2023-06-16 14:30:20.123' AS DATETIME); -- Positive
GO
SELECT CAST(N'2023/06/16 14:30:20.123' AS DATETIME); -- Positive
GO
SELECT CAST(N'16/06/2023 14:30:20.123' AS DATETIME); -- Format dependent
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('9999-12-31' AS DATE) AS DATETIME); -- Edge
GO

-- datetime
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS DATETIME) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('1753-01-01 00:00:00' AS DATETIME) AS DATETIME); -- Edge
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 14:30:00' AS SMALLDATETIME) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('1900-01-01 00:00:00' AS SMALLDATETIME) AS DATETIME); -- Edge
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 14:30:20.1234567' AS DATETIME2) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2) AS DATETIME); -- Edge
GO

-- time
SELECT CAST(CAST('14:30:20.1234567' AS TIME) AS DATETIME); -- Negative
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 14:30:20.123 +01:00' AS DATETIMEOFFSET) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS DATETIME); -- Edge
GO

-- decimal
SELECT CAST(CAST(20230616.143020 AS DECIMAL(14,6)) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(99991231.235959 AS DECIMAL(14,6)) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(0 AS DECIMAL(14,6)) AS DATETIME); -- Negative
GO

-- numeric
SELECT CAST(CAST(20230616.143020 AS NUMERIC(14,6)) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(17530101 AS NUMERIC(14,6)) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS NUMERIC(14,6)) AS DATETIME); -- Negative
GO

-- float
SELECT CAST(CAST(20230616.143020 AS FLOAT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(99991231.235959 AS FLOAT) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(1.23e5 AS FLOAT) AS DATETIME); -- Positive
GO

-- real
SELECT CAST(CAST(20230616.143020 AS REAL) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(99991231.235959 AS REAL) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(-20230616 AS REAL) AS DATETIME); -- Negative
GO

-- bigint
SELECT CAST(CAST(20230616143020 AS BIGINT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(99991231235959 AS BIGINT) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(0 AS BIGINT) AS DATETIME); -- Negative
GO

-- int
SELECT CAST(20230616 AS DATETIME); -- Positive
GO
SELECT CAST(17530101 AS DATETIME); -- Edge
GO
SELECT CAST(-1 AS DATETIME); -- Negative
GO

-- smallint
SELECT CAST(CAST(32767 AS SMALLINT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(-32768 AS SMALLINT) AS DATETIME); -- Negative
GO

-- tinyint
SELECT CAST(CAST(255 AS TINYINT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(0 AS TINYINT) AS DATETIME); -- Negative
GO

-- money
SELECT CAST(CAST(20230616.1430 AS MONEY) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(99991231.2359 AS MONEY) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS MONEY) AS DATETIME); -- Negative
GO

-- smallmoney
SELECT CAST(CAST(20230616.1430 AS SMALLMONEY) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS DATETIME); -- Edge
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS DATETIME); -- Negative
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS DATETIME); -- Negative
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS DATETIME); -- Negative
GO

-- text
SELECT CAST(CAST('2023-06-16 14:30:20.123' AS TEXT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS TEXT) AS DATETIME); -- Negative
GO

-- ntext
SELECT CAST(CAST(N'2023-06-16 14:30:20.123' AS NTEXT) AS DATETIME); -- Positive
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS DATETIME); -- Negative
GO

-- xml
SELECT CAST(CAST('<date>2023-06-16T14:30:20.123</date>' AS XML) AS DATETIME); -- Negative
GO

-- sql_variant
SELECT CAST(CAST(CAST('2023-06-16 14:30:20.123' AS DATETIME) AS SQL_VARIANT) AS DATETIME); -- Positive
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS DATETIME); -- Negative
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS DATETIME); -- Negative
GO

-- Implicit conversion
-- Create a function that takes a DATETIME parameter
CREATE FUNCTION dbo.TestDateTimeFunction(@DateTimeParam DATETIME)
RETURNS DATETIME
AS
BEGIN
    RETURN @DateTimeParam;
END
GO

-- binary
SELECT dbo.TestDateTimeFunction(CAST(0x0000A5F507E30610 AS binary(8))); -- Positive: 2023-06-16 12:34:56
GO
SELECT dbo.TestDateTimeFunction(CAST(0x AS binary));
GO
SELECT dbo.TestDateTimeFunction(CAST(0xFFFFFFFFFFFFFFFF AS binary(8))); -- Negative: Will raise an error
GO

-- varbinary
SELECT dbo.TestDateTimeFunction(CAST(0x0000A5F507E30610 AS varbinary(8))); -- Positive: 2023-06-16 12:34:56
GO
SELECT dbo.TestDateTimeFunction(0x); -- Negative: Will raise an error
GO
SELECT dbo.TestDateTimeFunction(CAST(0xFFFFFFFFFFFFFFFF AS varbinary(8)));
GO

-- char
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56' AS char)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56' AS char(19)));
GO
SELECT dbo.TestDateTimeFunction(CAST('20230616 12:34:56' AS char)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestDateTimeFunction(CAST('invalid' AS char)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateTimeFunction(CAST(NULL AS char));
GO
SELECT dbo.TestDateTimeFunction(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestDateTimeFunction(CAST('9999-12-31 23:59:59.997' AS varchar)); -- Edge: Max datetime
GO
SELECT dbo.TestDateTimeFunction(CAST('10000-01-01 00:00:00' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56.123' AS varchar)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56' AS varchar(19)));
GO
SELECT dbo.TestDateTimeFunction(CAST('20230616 12:34:56' AS varchar)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestDateTimeFunction(CAST('Jun 16 2023 12:34:56' AS varchar)); -- Positive: Month name format
GO
SELECT dbo.TestDateTimeFunction(CAST('invalid' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateTimeFunction(CAST(NULL AS varchar));
GO
SELECT dbo.TestDateTimeFunction(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestDateTimeFunction(CAST(N'2023-06-16 12:34:56' AS nchar)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(N'2023-06-16 12:34:56' AS nchar(19)));
GO
SELECT dbo.TestDateTimeFunction(CAST(N'1753-01-01 00:00:00' AS nchar)); -- Edge: Min datetime
GO
SELECT dbo.TestDateTimeFunction(CAST(N'1752-12-31 23:59:59' AS nchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateTimeFunction(CAST(NULL AS nchar));
GO
SELECT dbo.TestDateTimeFunction(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestDateTimeFunction(N'2023-06-16 12:34:56.123'); -- Positive
GO
SELECT dbo.TestDateTimeFunction(N'2023/06/16 12:34:56'); -- Positive: Different format
GO
SELECT dbo.TestDateTimeFunction(N'16/06/2023 12:34:56'); -- Depends on SET DATEFORMAT
GO

-- datetime
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56.123' AS DATETIME)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('1753-01-01 00:00:00' AS DATETIME)); -- Edge: Min datetime
GO
SELECT dbo.TestDateTimeFunction(CAST('9999-12-31 23:59:59.997' AS DATETIME)); -- Edge: Max datetime
GO

-- smalldatetime
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:00' AS SMALLDATETIME)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('1900-01-01 00:00:00' AS SMALLDATETIME)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestDateTimeFunction(CAST('2079-06-06 23:59:00' AS SMALLDATETIME)); -- Edge: Max smalldatetime
GO

-- datetime2
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2)); -- Edge: Max datetime2
GO

-- time
SELECT dbo.TestDateTimeFunction(CAST('12:34:56' AS TIME)); -- Negative: Will raise an error
GO

-- datetimeoffset
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56.123 +01:00' AS DATETIMEOFFSET)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('9999-12-31 23:59:59.997 +14:00' AS DATETIMEOFFSET)); -- Edge
GO

-- decimal
SELECT dbo.TestDateTimeFunction(CAST(20230616.1234 AS DECIMAL(12,4))); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(99991231.9999 AS DECIMAL(12,4))); -- Edge
GO
SELECT dbo.TestDateTimeFunction(CAST(0 AS DECIMAL(12,4))); -- Negative: Will raise an error
GO

-- numeric
SELECT dbo.TestDateTimeFunction(CAST(20230616.1234 AS NUMERIC(12,4))); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(17530101.0000 AS NUMERIC(12,4))); -- Edge: Min datetime
GO
SELECT dbo.TestDateTimeFunction(CAST(-1 AS NUMERIC(12,4))); -- Negative: Will raise an error
GO

-- float
SELECT dbo.TestDateTimeFunction(CAST(20230616.123456 AS FLOAT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(99991231.999999 AS FLOAT)); -- Edge
GO
SELECT dbo.TestDateTimeFunction(CAST(1.23e5 AS FLOAT)); -- Negative: Will raise an error
GO

-- real
SELECT dbo.TestDateTimeFunction(CAST(20230616.123456 AS REAL)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(99991231.999999 AS REAL)); -- Edge
GO
SELECT dbo.TestDateTimeFunction(CAST(-20230616 AS REAL)); -- Negative: Will raise an error
GO

-- bigint
SELECT dbo.TestDateTimeFunction(CAST(20230616123456 AS BIGINT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(99991231235959 AS BIGINT)); -- Edge
GO
SELECT dbo.TestDateTimeFunction(CAST(0 AS BIGINT)); -- Negative: Will raise an error
GO

-- int
SELECT dbo.TestDateTimeFunction(CAST(2023061612 AS INT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(1753010100 AS INT)); -- Edge: Min datetime
GO
SELECT dbo.TestDateTimeFunction(CAST(-1 AS INT)); -- Negative: Will raise an error
GO

-- smallint
SELECT dbo.TestDateTimeFunction(CAST(2023 AS SMALLINT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(32767 AS SMALLINT)); -- Edge: Max smallint
GO
SELECT dbo.TestDateTimeFunction(CAST(-1 AS SMALLINT)); -- Negative: Will raise an error
GO

-- tinyint
SELECT dbo.TestDateTimeFunction(CAST(123 AS TINYINT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(255 AS TINYINT)); -- Edge: Max tinyint
GO
SELECT dbo.TestDateTimeFunction(CAST(0 AS TINYINT)); -- Negative: Will raise an error
GO

-- money
SELECT dbo.TestDateTimeFunction(CAST(20230616.1234 AS MONEY)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(99991231.9999 AS MONEY)); -- Edge
GO
SELECT dbo.TestDateTimeFunction(CAST(-1 AS MONEY)); -- Negative: Will raise an error
GO

-- smallmoney
SELECT dbo.TestDateTimeFunction(CAST(20230.1234 AS SMALLMONEY)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(214748.3647 AS SMALLMONEY)); -- Edge: Max smallmoney
GO
SELECT dbo.TestDateTimeFunction(CAST(-1 AS SMALLMONEY)); -- Negative: Will raise an error
GO

-- bit
SELECT dbo.TestDateTimeFunction(CAST(1 AS BIT)); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT dbo.TestDateTimeFunction(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER)); -- Negative
GO

-- text
SELECT dbo.TestDateTimeFunction(CAST('2023-06-16 12:34:56.123' AS TEXT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST('invalid' AS TEXT)); -- Negative: Will raise an error
GO

-- ntext
SELECT dbo.TestDateTimeFunction(CAST(N'2023-06-16 12:34:56.123' AS NTEXT)); -- Positive
GO
SELECT dbo.TestDateTimeFunction(CAST(N'invalid' AS NTEXT)); -- Negative: Will raise an error
GO

-- xml
SELECT dbo.TestDateTimeFunction(CAST('<date>2023-06-16T12:34:56.123</date>' AS XML)); -- Negative
GO

-- sql_variant
SELECT dbo.TestDateTimeFunction(CAST(CAST('2023-06-16 12:34:56.123' AS DATETIME) AS SQL_VARIANT)); -- Positive
GO

-- geometry
SELECT dbo.TestDateTimeFunction(geometry::STGeomFromText('POINT(1 1)', 0)); -- Negative: Will raise an error
GO

-- geography
SELECT dbo.TestDateTimeFunction(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326)); -- Negative
GO

-- Create a table to store test results
CREATE TABLE DateTimeImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue DATETIME NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertDateTimeTestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue DATETIME = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO DateTimeImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @DateTimeValue DATETIME = '2023-06-16 14:30:20.123';
DECLARE @StringDateTime NVARCHAR(30) = '2023-06-17 15:45:30.456';
DECLARE @DateValue DATE = '2023-06-20';
DECLARE @SmallDateTime SMALLDATETIME = '2023-06-21 16:30';
DECLARE @DateTime2Value DATETIME2 = '2023-06-22 17:15:40.1234567';
DECLARE @TimeValue TIME = '18:45:50.123';

-- 1. UNION with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateTimeValue AS Result
        UNION
        SELECT @StringDateTime
        UNION
        SELECT @DateValue
        UNION
        SELECT @SmallDateTime
        UNION
        SELECT @DateTime2Value
    ) AS UnionResult;
    EXEC InsertDateTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 2. UNION ALL with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) AS Result
        UNION ALL
        SELECT '2023-06-17 15:45:30.456'
        UNION ALL
        SELECT CAST('2023-06-20' AS DATE)
        UNION ALL
        SELECT CAST('2023-06-21 16:30' AS SMALLDATETIME)
        UNION ALL
        SELECT CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    ) AS UnionAllResult;
    EXEC InsertDateTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 3. CASE Expression with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SET @Result = CASE 
        WHEN 1=0 THEN CAST('2023-06-16 14:30:20.123' AS DATETIME)
        WHEN 1=0 THEN '2023-06-17 15:45:30.456'
        WHEN 1=0 THEN CAST('2023-06-20' AS DATE)
        WHEN 1=0 THEN CAST('2023-06-21 16:30' AS SMALLDATETIME)
        ELSE CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    END;
    EXEC InsertDateTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 4. COALESCE with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SET @Result = COALESCE(
        NULL,
        CAST('2023-06-16 14:30:20.123' AS DATETIME),
        '2023-06-17 15:45:30.456',
        CAST('2023-06-20' AS DATE),
        CAST('2023-06-21 16:30' AS SMALLDATETIME),
        CAST('2023-06-22 17:15:40.1234567' AS DATETIME2)
    );
    EXEC InsertDateTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 5. INTERSECT with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) AS Result
        INTERSECT
        SELECT '2023-06-16 14:30:20.123'
    ) AS IntersectResult;
    EXEC InsertDateTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATETIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATETIME and String', NULL, 0;
END CATCH;
GO

-- 6. EXCEPT with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) AS Result
        EXCEPT
        SELECT '2023-06-16 14:30:20.123'
    ) AS ExceptResult;
    EXEC InsertDateTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIME and String', NULL, 0;
END CATCH;
GO

-- 7. VALUES with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SELECT TOP 1 @Result = Result
    FROM (VALUES 
        (CAST('2023-06-16 14:30:20.123' AS DATETIME)),
        ('2023-06-17 15:45:30.456'),
        (CAST('2023-06-20' AS DATE)),
        (CAST('2023-06-21 16:30' AS SMALLDATETIME)),
        (CAST('2023-06-22 17:15:40.1234567' AS DATETIME2))
    ) AS ValuesResult(Result);
    EXEC InsertDateTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 8. ISNULL with different datetime types
BEGIN TRY
    DECLARE @Result DATETIME;
    SET @Result = ISNULL(NULL, '2023-06-16 14:30:20.123');
    EXEC InsertDateTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;
GO

-- 9. Time component conversions
BEGIN TRY
    DECLARE @Result DATETIME;
    SET @Result = CAST('18:45:50.123' AS TIME);
    EXEC InsertDateTimeTestResult 'TIME', 'Implicit conversion from TIME', 'TIME to DATETIME', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeTestResult 'TIME', 'Implicit conversion from TIME', 'TIME to DATETIME', NULL, 0;
END CATCH;
GO

-- Display results
SELECT * FROM DateTimeImplicitConversionTest ORDER BY ID;
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
    SET @SQL = 'SELECT CONVERT(DATETIME, 0x07E3061014223B, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:59'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, ''2023-06-16 14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, ''2023-06-16 14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, N''2023-06-16 14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, N''2023-06-16 14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:59'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:00'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:59.1234567'' AS DATETIME2), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:59.1234567 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616.142259 AS DECIMAL(14,6)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616.142259 AS NUMERIC(14,6)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616.142259 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616.142259 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616142259 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, 20230616, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(16 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230616.142259 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(20230.142259 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(''2023-06-16 14:22:59'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(N''2023-06-16 14:22:59'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- sql_variant
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
    SET @SQL = 'SELECT CONVERT(DATETIME, CAST(CAST(''2023-06-16 14:22:59'' AS DATETIME) AS SQL_VARIANT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(0x07E30610 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(0x07E30610 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS char(23)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS varchar(23)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS nchar(23)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS nvarchar(23)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:00' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.1234567' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('14:30:20.123' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616.143020 AS decimal(14,6)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616.143020 AS numeric(14,6)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616.143020 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616.143020 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616143020 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(16 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230616.143020 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(20230.143020 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(0x07E30610 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('2023-06-16 14:30:20.123' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST(CAST('2023-06-16 14:30:20.123' AS datetime) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) = CAST('<datetime>2023-06-16T14:30:20.123</datetime>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS char(23)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS varchar(23)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS nchar(23)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS nvarchar(23)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS datetime) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS smalldatetime) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.1234567' AS datetime2) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('14:30:20.123' AS time) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123 +01:00' AS datetimeoffset) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS decimal(14,6)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS numeric(14,6)) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS float) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS real) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS bigint) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS money) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230.143020 AS smallmoney) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS text) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS ntext) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 14:30:20.123' AS datetime) AS sql_variant) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T14:30:20.123</datetime>' AS xml) = CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(0x07E30610 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(0x07E30610 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS char(23)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS varchar(23)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS nchar(23)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS nvarchar(23)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('12:34:56' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616.1234567 AS decimal(15,7)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616.1234567 AS numeric(15,7)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616.1234567 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616.1234567 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616123456 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(16 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230616.1234567 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(20230.1234567 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(0x07E30610 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('2023-06-16 12:34:56.789' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST(CAST('2023-06-16 12:34:56.789' AS datetime) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) <> CAST('<datetime>2023-06-16T12:34:56.789</datetime>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS char(23)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS varchar(23)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS nchar(23)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS nvarchar(23)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS decimal(15,7)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS numeric(15,7)) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS float) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS real) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS bigint) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS money) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230.1234567 AS smallmoney) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS text) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS ntext) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.789' AS datetime) AS sql_variant) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56.789</datetime>' AS xml) <> CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(0x07E30610 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS char(23)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS varchar(23)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS nchar(23)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS nvarchar(23)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('12:34:56' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616.1234 AS decimal(13,4)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616.1234 AS numeric(13,4)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616.1234 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616.1234 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616123456 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(16 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230616.1234 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(20230.1234 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(0x07E30610 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('2023-06-16 12:34:56.123' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST(CAST('2023-06-16 12:34:56.123' AS datetime) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) < CAST('<datetime>2023-06-16T12:34:56.123</datetime>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS char(23)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS varchar(23)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS nchar(23)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS nvarchar(23)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS decimal(13,4)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS numeric(13,4)) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS float) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS real) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS bigint) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS money) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230.1234 AS smallmoney) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS text) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS ntext) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.123' AS datetime) AS sql_variant) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56.123</datetime>' AS xml) < CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(0x07E30610 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS char(23)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS varchar(23)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS nchar(23)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS nvarchar(23)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('12:34:56' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616.1234 AS decimal(12,4)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616.1234 AS numeric(12,4)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616.1234 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616.1234 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616123456 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(16 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230616.1234 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(20230.1234 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(0x07E30610 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('2023-06-16 12:34:56.123' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST(CAST('2023-06-16 12:34:56.123' AS datetime) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS DATETIME) <= CAST('<datetime>2023-06-16T12:34:56.123</datetime>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS char(23)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS varchar(23)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS nchar(23)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS nvarchar(23)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS decimal(12,4)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS numeric(12,4)) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS float) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS real) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS bigint) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS money) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230.1234 AS smallmoney) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS text) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.123' AS ntext) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.123' AS datetime) AS sql_variant) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56.123</datetime>' AS xml) <= CAST('2023-06-16 12:34:56.123' AS DATETIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(0x07E30610 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(0x07E30610 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS char(19)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS varchar(19)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS nchar(19)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS nvarchar(19)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('12:34:56' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616.1234567 AS decimal(15,7)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616.1234567 AS numeric(15,7)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616.1234567 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616.1234567 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616123456 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(123 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230616.1234 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(20230.1234 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(0x07E30610 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('2023-06-16 12:34:56' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST(CAST('2023-06-16 12:34:56' AS datetime) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.789' AS DATETIME) > CAST('<datetime>2023-06-16T12:34:56</datetime>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS char(19)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS varchar(19)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nchar(19)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nvarchar(19)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS decimal(15,7)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS numeric(15,7)) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS float) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234567 AS real) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS bigint) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123 AS tinyint) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616.1234 AS money) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230.1234 AS smallmoney) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS text) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS ntext) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56' AS datetime) AS sql_variant) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56</datetime>' AS xml) > CAST('2023-06-16 12:34:56.789' AS DATETIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with DATETIME on left side
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(0x07E30610143020123 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(0x07E30610143020123 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS char(23)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS varchar(23)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS nchar(23)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS nvarchar(23)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:00' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.1234567' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('14:30:20.123' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616143020 AS decimal(14,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616143020 AS numeric(14,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616143020 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616143020 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616143020 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(16 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230616.143020 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(20230.143020 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(0x07E30610143020123 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('2023-06-16 14:30:20.123' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST(CAST('2023-06-16 14:30:20.123' AS datetime) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) >= CAST('<datetime>2023-06-16T14:30:20.123</datetime>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with DATETIME on right side
SELECT CASE WHEN CAST(0x07E30610143020123 AS binary(8)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610143020123 AS varbinary(8)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS char(23)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS varchar(23)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS nchar(23)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS nvarchar(23)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20' AS datetime) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:00' AS smalldatetime) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.1234567' AS datetime2) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('14:30:20.123' AS time) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123 +01:00' AS datetimeoffset) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS decimal(14,0)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS numeric(14,0)) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS float) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS real) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616143020 AS bigint) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.143020 AS money) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230.143020 AS smallmoney) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610143020123 AS image) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS text) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 14:30:20.123' AS ntext) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 14:30:20.123' AS datetime) AS sql_variant) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T14:30:20.123</datetime>' AS xml) >= CAST('2023-06-16 14:30:20.123' AS DATETIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator with DATETIME
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-15 14:30:20.123' AS DATETIME) 
        AND CAST('2023-06-17 14:30:20.123' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with different time parts
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-15 00:00:00.000' AS DATETIME) 
        AND CAST('2023-06-17 23:59:59.997' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with same date, different times
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-16 14:30:20.000' AS DATETIME) 
        AND CAST('2023-06-16 14:30:20.997' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with millisecond precision
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-16 14:30:20.120' AS DATETIME) 
        AND CAST('2023-06-16 14:30:20.127' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- BETWEEN with different data types
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-15 12:34:56.1234567' AS DATETIME2) 
        AND CAST('2023-06-17 12:34:56.1234567' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-15 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-17 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator with DATETIME
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) IN 
        (CAST('2023-06-15 14:30:20.123' AS DATETIME), 
         CAST('2023-06-16 14:30:20.123' AS DATETIME), 
         CAST('2023-06-17 14:30:20.123' AS DATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IN with different time parts
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) IN 
        (CAST('2023-06-16 14:30:20.000' AS DATETIME), 
         CAST('2023-06-16 14:30:20.123' AS DATETIME), 
         CAST('2023-06-16 14:30:20.997' AS DATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IN with different data types
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) IN 
        (CAST('2023-06-15 12:34:56.1234567' AS DATETIME2), 
         CAST('2023-06-16 12:34:56.1234567' AS DATETIME2), 
         CAST('2023-06-17 12:34:56.1234567' AS DATETIME2)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL with DATETIME
DECLARE @NullDateTime DATETIME;
SELECT CASE 
    WHEN @NullDateTime IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

DECLARE @NullDateTime DATETIME;
SELECT CASE 
    WHEN @NullDateTime IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Non-null DATETIME tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Edge cases with DATETIME
-- Minimum DATETIME value
SELECT CASE 
    WHEN CAST('1753-01-01 00:00:00.000' AS DATETIME) 
        BETWEEN CAST('1753-01-01 00:00:00.000' AS DATETIME) 
        AND CAST('1753-01-01 23:59:59.997' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Maximum DATETIME value
SELECT CASE 
    WHEN CAST('9999-12-31 23:59:59.997' AS DATETIME) 
        BETWEEN CAST('9999-12-31 00:00:00.000' AS DATETIME) 
        AND CAST('9999-12-31 23:59:59.997' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Millisecond rounding tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:20.123' AS DATETIME) 
        BETWEEN CAST('2023-06-16 14:30:20.120' AS DATETIME) 
        AND CAST('2023-06-16 14:30:20.127' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Cross-day boundary
SELECT CASE 
    WHEN CAST('2023-06-16 23:59:59.997' AS DATETIME) 
        BETWEEN CAST('2023-06-16 23:59:59.990' AS DATETIME) 
        AND CAST('2023-06-17 00:00:00.003' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Arithmetic operators
-- Addition with DATETIME on left side
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('2023-06-16 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) + CAST('<number>1</number>' AS XML);
GO

-- Addition with DATETIME on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS CHAR(10)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS VARCHAR(10)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NCHAR(10)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:00' AS SMALLDATETIME) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS FLOAT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS REAL) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS BIGINT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS INT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS SMALLINT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS TINYINT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS MONEY) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS SMALLMONEY) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS BIT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(0x07E30610 AS IMAGE) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS TEXT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NTEXT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('<number>1</number>' AS XML) + CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO

-- Subtraction with DATETIME on left side
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(0x07E30610143020 AS BINARY(8));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(0x07E30610143020 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('2023-06-15' AS DATE);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('2023-06-15 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('2023-06-15 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('2023-06-15 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('2023-06-15 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(0x07E30610143020 AS IMAGE);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with DATETIME on right side
SELECT CAST(0x07E30610143020 AS BINARY(8)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(0x07E30610143020 AS VARBINARY(8)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-17' AS DATE) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-17 12:34:56' AS DATETIME) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-17 12:34:00' AS SMALLDATETIME) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-17 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('2023-06-17 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS FLOAT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS REAL) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS BIGINT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS INT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS SMALLINT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS TINYINT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS MONEY) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(1 AS BIT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(0x07E30610143020 AS IMAGE) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS TEXT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('1' AS NTEXT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('2023-06-16 14:30:20.123' AS DATETIME);
GO

-- 4. DDL testing:

-- 1. Table column with DATETIME
CREATE TABLE DateTimeTest1 (
    ID INT PRIMARY KEY,
    DateTimeColumn DATETIME,
    DefaultDateTimeColumn DATETIME DEFAULT GETDATE(),
    ComputedDateTimeColumn AS DATEADD(day, 1, DateTimeColumn),
    CHECK (DateTimeColumn > '2000-01-01 00:00:00.000')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTimeTest1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table for DATETIME
CREATE PARTITION FUNCTION DATETIME_partition_func (DATETIME) 
    AS RANGE RIGHT FOR VALUES(
        '2022-01-01 00:00:00.000', 
        '2023-01-01 00:00:00.000', 
        '2024-01-01 00:00:00.000'
    );
GO

CREATE PARTITION SCHEME DATETIME_partition_scheme
    AS PARTITION DATETIME_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE DATETIME_partition(
    a DATETIME,
    type VARCHAR(10))
ON DATETIME_partition_scheme(a);
GO

-- Insert test data with time components
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-06-15 09:30:00.000', 'PDF');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-12-31 14:45:00.000', 'PDF');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-06-15 10:15:00.000', 'GIF');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-12-31 15:20:00.000', 'GIF');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-06-15 11:00:00.000', 'JPEG');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-12-31 16:30:00.000', 'JPEG');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-06-15 12:45:00.000', 'PNG');
GO
INSERT INTO DATETIME_partition (a, type) VALUES ('2021-12-31 17:15:00.000', 'PNG');
GO

-- Query to show data in each partition
SELECT a, type, $PARTITION.DATETIME_partition_func(a) AS PartitionNumber
    FROM DATETIME_partition ORDER BY PartitionNumber, a, type;
GO

-- Query to show count by partition
SELECT $PARTITION.DATETIME_partition_func(a) AS PartitionNumber, type, COUNT(*) AS FileCount
    FROM DATETIME_partition
    GROUP BY $PARTITION.DATETIME_partition_func(a), type
    ORDER BY PartitionNumber, type;
GO

-- 3. Function returning DATETIME
CREATE FUNCTION dbo.GetCurrentDateTime()
RETURNS DATETIME
AS
BEGIN
    RETURN CAST('2023-06-17 14:30:00.000' AS DATETIME);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentDateTime' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes DATETIME input
CREATE FUNCTION dbo.AddDaysToDateTime(
    @InputDateTime DATETIME,
    @DaysToAdd INT
)
RETURNS DATETIME
AS
BEGIN
    RETURN DATEADD(DAY, @DaysToAdd, @InputDateTime);
END;
GO

-- Test the function
SELECT dbo.AddDaysToDateTime('2023-06-16 14:30:00.000', 5) AS Result;
GO
SELECT dbo.AddDaysToDateTime('2023-06-16 14:30:00.000', -5) AS Result;
GO
SELECT dbo.AddDaysToDateTime('2023-06-16 14:30:00.000', 0) AS Result;
GO

-- 5. Procedure takes DATETIME input
CREATE PROCEDURE dbo.ProcessDateTime
    @InputDateTime DATETIME
AS
BEGIN
    SELECT 
        @InputDateTime AS InputDateTime,
        DATEADD(DAY, 1, @InputDateTime) AS NextDay,
        DATEADD(HOUR, 1, @InputDateTime) AS NextHour,
        DATEADD(MINUTE, 1, @InputDateTime) AS NextMinute,
        DATEADD(SECOND, 1, @InputDateTime) AS NextSecond,
        DATEADD(MILLISECOND, 1, @InputDateTime) AS NextMillisecond;
END;
GO

-- 6. Constraints
ALTER TABLE DateTimeTest1
ADD CONSTRAINT DF_DateTimeTest_DefaultColumn 
    DEFAULT '2000-01-01 00:00:00.000' FOR DefaultDateTimeColumn;
GO

ALTER TABLE DateTimeTest1
ADD CONSTRAINT CK_DateTimeTest_DateTimeColumn 
    CHECK (DateTimeColumn > '2000-01-01 00:00:00.000');
GO

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'DateTimeTest1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key verification
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'DateTimeTest1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views with DATETIME
CREATE VIEW dbo.DateTimeView
AS
SELECT
    ID,
    DateTimeColumn,
    DefaultDateTimeColumn,
    ComputedDateTimeColumn,
    DATEPART(YEAR, DateTimeColumn) AS Year,
    DATEPART(MONTH, DateTimeColumn) AS Month,
    DATEPART(DAY, DateTimeColumn) AS Day,
    DATEPART(HOUR, DateTimeColumn) AS Hour,
    DATEPART(MINUTE, DateTimeColumn) AS Minute,
    DATEPART(SECOND, DateTimeColumn) AS Second,
    DATEPART(MILLISECOND, DateTimeColumn) AS Millisecond
FROM DateTimeTest1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTimeView'
ORDER BY COLUMN_NAME;
GO

-- Insert test data with time components
INSERT INTO DateTimeTest1 (ID, DateTimeColumn) VALUES 
(1, '2023-06-16 14:30:20.123'),
(2, '2023-06-17 09:15:45.456'),
(3, '2023-06-18 18:45:30.789');
GO

-- Test all objects
SELECT * FROM DateTimeTest1 ORDER BY ID;
GO

SELECT * FROM DATETIME_partition ORDER BY a, type;
GO

SELECT dbo.GetCurrentDateTime() AS CurrentDateTime;
GO

SELECT dbo.AddDaysToDateTime('2023-06-16 14:30:20.123', 5) AS DateTimeAfter5Days;
GO

EXEC dbo.ProcessDateTime @InputDateTime = '2023-06-16 14:30:20.123';
GO

SELECT * FROM dbo.DateTimeView ORDER BY ID;
GO

-- Additional DATETIME-specific tests
-- Test rounding behavior
SELECT CAST('2023-06-16 14:30:20.123' AS DATETIME) AS Original,
       CAST('2023-06-16 14:30:20.127' AS DATETIME) AS RoundedUp,
       CAST('2023-06-16 14:30:20.120' AS DATETIME) AS RoundedDown;
GO

-- Test arithmetic operations
SELECT 
    DATEADD(MILLISECOND, 1, '2023-06-16 14:30:20.123') AS AddMillisecond,
    DATEADD(SECOND, 1, '2023-06-16 14:30:20.123') AS AddSecond,
    DATEADD(MINUTE, 1, '2023-06-16 14:30:20.123') AS AddMinute,
    DATEADD(HOUR, 1, '2023-06-16 14:30:20.123') AS AddHour;
GO

-- 5. DML testing:
-- Create test tables for DATETIME
CREATE TABLE DateTimeDMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleDateTime DATETIME,
    DefaultDateTime DATETIME DEFAULT NULL,
    ComputedDateTime AS DATEADD(hour, 1, SimpleDateTime),
    Description NVARCHAR(100)
);
GO

CREATE TABLE DateTimeDMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildDateTime DATETIME,
    FOREIGN KEY (ParentID) REFERENCES DateTimeDMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion with different time components
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description) 
VALUES ('2023-06-16 14:30:20.123', 'Single row insertion');
GO

-- Bulk insertion with various time formats
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
VALUES 
('2023-06-17 09:15:30.456', 'Bulk insertion 1'),
('2023-06-18 12:45:10.789', 'Bulk insertion 2'),
('2023-06-19 18:20:45.234', 'Bulk insertion 3');
GO

-- Insert with type casting
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
VALUES (CAST('20230620 15:30:20.123' AS DATETIME), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
VALUES (DATEADD(minute, 30, '2023-06-16 14:30:20.123'), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO DateTimeDMLTest (SimpleDateTime, DefaultDateTime, Description)
VALUES ('2023-06-22 10:15:30.123', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM DateTimeDMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE DateTimeDMLTest
SET SimpleDateTime = '2023-07-01 08:30:20.123'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE DateTimeDMLTest
SET SimpleDateTime = '2023-07-02 14:45:30.456',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE DateTimeDMLTest
SET SimpleDateTime = DATEADD(hour, 2, SimpleDateTime)
WHERE ID = 3;
GO

-- Mass update
UPDATE DateTimeDMLTest
SET Description = 'Mass updated';
GO

-- Conditional update based on time
UPDATE DateTimeDMLTest
SET SimpleDateTime = '2023-08-01 12:00:00.000'
WHERE SimpleDateTime < '2023-07-01 00:00:00.000';
GO

-- Verify updates
SELECT * FROM DateTimeDMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO DateTimeDMLTestChild (ParentID, ChildDateTime)
VALUES 
(1, '2023-06-16 10:30:20.123'),
(2, '2023-06-17 11:45:30.456'),
(3, '2023-06-18 14:20:45.789'),
(4, '2023-06-19 16:15:30.234'),
(5, '2023-06-20 09:30:20.567');
GO

-- Single row deletion
DELETE FROM DateTimeDMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM DateTimeDMLTest;
GO

-- Conditional deletion based on time
DELETE FROM DateTimeDMLTest 
WHERE SimpleDateTime < '2023-07-01 00:00:00.000';
GO

-- Cascade deletion (will delete from child table as well)
DELETE FROM DateTimeDMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM DateTimeDMLTest ORDER BY ID;
SELECT * FROM DateTimeDMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
VALUES ('2023-09-01 15:30:20.123', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleDateTime, ComputedDateTime, Description
FROM DateTimeDMLTest
WHERE CONVERT(DATE, SimpleDateTime) = '2023-09-01';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE DateTimeDMLTest
    SET ComputedDateTime = '2023-09-03 16:30:20.123'
    WHERE CONVERT(DATE, SimpleDateTime) = '2023-09-01';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE DateTimeDMLTest
SET SimpleDateTime = '2023-09-02 14:30:20.123'
WHERE CONVERT(DATE, SimpleDateTime) = '2023-09-01';
GO

SELECT ID, SimpleDateTime, ComputedDateTime, Description
FROM DateTimeDMLTest
WHERE CONVERT(DATE, SimpleDateTime) = '2023-09-02';
GO

-- 5. Additional DML scenarios

-- Insert with subquery
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
SELECT DATEADD(year, 1, MAX(SimpleDateTime)), 'Inserted from subquery'
FROM DateTimeDMLTest;
GO

-- Update with JOIN
UPDATE d
SET d.SimpleDateTime = DATEADD(hour, 1, c.ChildDateTime)
FROM DateTimeDMLTest d
JOIN DateTimeDMLTestChild c ON d.ID = c.ParentID;
GO

-- Delete with subquery based on time
DELETE FROM DateTimeDMLTest
WHERE SimpleDateTime IN (
    SELECT ChildDateTime
    FROM DateTimeDMLTestChild
);
GO

-- Insert data that violates datetime range (this will fail)
BEGIN TRY
    INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
    VALUES ('1753-01-01 00:00:00.000', 'This should fail');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Time precision tests
INSERT INTO DateTimeDMLTest (SimpleDateTime, Description)
VALUES 
('2023-06-16 14:30:20.123', 'Precision test 1'),
('2023-06-16 14:30:20.997', 'Precision test 2'),
('2023-06-16 14:30:20.000', 'Precision test 3');
GO

-- Update with different time precisions
UPDATE DateTimeDMLTest
SET SimpleDateTime = DATEADD(millisecond, 500, SimpleDateTime)
WHERE Description LIKE 'Precision test%';
GO

-- Final verification
SELECT * FROM DateTimeDMLTest ORDER BY ID;
SELECT * FROM DateTimeDMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table with DATETIME
CREATE TABLE DateTimeIndexTest (
    ID INT IDENTITY PRIMARY KEY,
    DateTimeColumn DATETIME,
    DateTimeColumn2 DATETIME,
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data with time components
INSERT INTO DateTimeIndexTest (DateTimeColumn, DateTimeColumn2, Description, NumericColumn)
VALUES 
('2023-01-01 12:30:45.123', '2023-06-01 08:15:30.456', 'First half', 1),
('2023-02-15 14:20:15.789', '2023-07-15 09:45:20.234', 'Mid year', 2),
('2023-03-30 16:45:30.567', '2023-08-30 11:30:15.678', 'Third quarter', 3),
('2023-04-10 18:10:45.890', '2023-09-10 13:20:40.123', 'Fall season', 4),
('2023-05-20 20:30:15.234', '2023-10-20 15:45:55.789', 'Year end', 5);
GO

-- 1. Index on single DATETIME column
CREATE INDEX IX_DateTimeIndexTest_DateTimeColumn 
ON DateTimeIndexTest(DateTimeColumn);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple DATETIME columns
CREATE INDEX IX_DateTimeIndexTest_DateTimeColumn_DateTimeColumn2 
ON DateTimeIndexTest(DateTimeColumn, DateTimeColumn2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45.123' 
AND DateTimeColumn2 = '2023-06-01 08:15:30.456';
SET STATISTICS IO OFF;
GO

-- 3. Different operators with DATETIME

-- Equality with precise time
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- Range including time
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn BETWEEN '2023-01-01 00:00:00.000' AND '2023-03-31 23:59:59.997' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- LIKE with converted DATETIME
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE CONVERT(VARCHAR(23), DateTimeColumn, 121) LIKE '2023-01%';
SET STATISTICS IO OFF;
GO

-- IN with precise timestamps
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn IN 
    ('2023-01-01 12:30:45.123', 
     '2023-02-15 14:20:15.789', 
     '2023-03-30 16:45:30.567') ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Data type conversions

-- DATETIME to VARCHAR
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '20230101 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- DATETIME to DATE
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE CAST(DateTimeColumn AS DATE) = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- DATETIME with different precision
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45';
SET STATISTICS IO OFF;
GO

-- 5. DML operations

-- INSERT with precise time
SET STATISTICS IO ON;
INSERT INTO DateTimeIndexTest 
    (DateTimeColumn, DateTimeColumn2, Description, NumericColumn)
VALUES 
    ('2023-06-30 22:15:30.123', '2023-12-31 23:59:59.997', 'Year end', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE with time component
SET STATISTICS IO ON;
UPDATE DateTimeIndexTest 
SET DateTimeColumn = '2023-07-01 00:00:00.000' 
WHERE DateTimeColumn = '2023-06-30 22:15:30.123';
SET STATISTICS IO OFF;
GO

-- DELETE with precise time
SET STATISTICS IO ON;
DELETE FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-07-01 00:00:00.000';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Filtered index with time range
CREATE INDEX IX_DateTimeIndexTest_Filtered ON DateTimeIndexTest(DateTimeColumn)
WHERE DateTimeColumn >= '2023-01-01 00:00:00.000' 
AND DateTimeColumn < '2024-01-01 00:00:00.000';
GO

-- Test filtered index
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-02-15 14:20:15.789';
SET STATISTICS IO OFF;
GO

-- Index with included columns
CREATE INDEX IX_DateTimeIndexTest_DateTimeColumn_Include 
ON DateTimeIndexTest(DateTimeColumn)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT DateTimeColumn, Description, NumericColumn 
FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-03-30 16:45:30.567';
SET STATISTICS IO OFF;
GO

-- 7. DateTime function tests

-- DATEADD
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = DATEADD(HOUR, -1, '2023-01-01 13:30:45.123');
SET STATISTICS IO OFF;
GO

-- DATEDIFF
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DATEDIFF(MINUTE, DateTimeColumn, '2023-01-01 12:30:45.123') = 0;
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest WITH (INDEX(IX_DateTimeIndexTest_DateTimeColumn))
WHERE DateTimeColumn = '2023-01-01 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest WITH (INDEX(0))
WHERE DateTimeColumn = '2023-01-01 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- 9. Time precision tests

-- Exact match
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45.123';
SET STATISTICS IO OFF;
GO

-- Rounded precision
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn = '2023-01-01 12:30:45.997';
SET STATISTICS IO OFF;
GO

-- Time range within a day
SET STATISTICS IO ON;
SELECT * FROM DateTimeIndexTest 
WHERE DateTimeColumn >= '2023-01-01 12:00:00.000'
AND DateTimeColumn < '2023-01-01 13:00:00.000';
SET STATISTICS IO OFF;
GO

-- 7. Expression Testing:
-- Create test table
-- Create table with DATETIME instead of DATE
CREATE TABLE DateTimeExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    DateTimeColumn DATETIME,
    NullableDateTimeColumn DATETIME NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data with time components
INSERT INTO DateTimeExpressionTest (DateTimeColumn, NullableDateTimeColumn, Description)
VALUES 
('2023-01-01 00:00:00.000', '2023-01-01 09:00:00.000', 'New Year'),
('2023-02-14 12:30:00.000', '2023-02-14 14:15:00.000', 'Valentine''s Day'),
('2023-03-17 15:45:00.000', NULL, 'St. Patrick''s Day'),
('2023-04-01 08:20:00.000', '2023-04-01 10:30:00.000', 'April Fool''s Day'),
('2023-05-01 14:00:00.000', NULL, 'May Day'),
('2023-06-21 12:00:00.000', '2023-06-21 13:45:00.000', 'Summer Solstice'),
('2023-07-04 18:30:00.000', '2023-07-04 20:00:00.000', 'Independence Day'),
('2023-08-15 09:15:00.000', NULL, 'August Holiday'),
('2023-09-22 16:45:00.000', '2023-09-22 17:30:00.000', 'Autumn Equinox'),
('2023-10-31 20:00:00.000', '2023-10-31 23:59:00.000', 'Halloween'),
('2023-11-23 11:30:00.000', NULL, 'Thanksgiving'),
('2023-12-25 07:00:00.000', '2023-12-25 12:00:00.000', 'Christmas');
GO

-- 1. Conditional Expressions with Time Components

-- CASE statements including time
SELECT 
    DateTimeColumn,
    CASE 
        WHEN DateTimeColumn BETWEEN '2023-03-01 00:00:00' AND '2023-05-31 23:59:59.997' THEN 'Spring'
        WHEN DateTimeColumn BETWEEN '2023-06-01 00:00:00' AND '2023-08-31 23:59:59.997' THEN 'Summer'
        WHEN DateTimeColumn BETWEEN '2023-09-01 00:00:00' AND '2023-11-30 23:59:59.997' THEN 'Autumn'
        ELSE 'Winter'
    END AS Season,
    CASE 
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    Description
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- COALESCE with time
SELECT 
    ID,
    COALESCE(NullableDateTimeColumn, DateTimeColumn, CAST('1900-01-01 00:00:00' AS DATETIME)) AS CoalescedDateTime,
    Description
FROM DateTimeExpressionTest ORDER BY ID;
GO

-- NULLIF with time precision
SELECT 
    ID,
    NULLIF(DateTimeColumn, '2023-01-01 00:00:00.000') AS NullIfNewYear,
    Description
FROM DateTimeExpressionTest ORDER BY ID;
GO

-- IIF with time components
SELECT 
    DateTimeColumn,
    IIF(DATEPART(HOUR, DateTimeColumn) < 12, 'AM', 'PM') AS AMPM,
    IIF(DATEPART(QUARTER, DateTimeColumn) <= 2, 'First Half', 'Second Half') AS HalfOfYear,
    Description
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- 2. Aggregate Expressions with Time

-- MAX/MIN including time
SELECT 
    MAX(DateTimeColumn) AS LatestDateTime,
    MIN(DateTimeColumn) AS EarliestDateTime
FROM DateTimeExpressionTest;
GO

-- Time-based grouping
SELECT 
    DATEPART(HOUR, DateTimeColumn) AS Hour,
    COUNT(*) AS EventCount
FROM DateTimeExpressionTest
GROUP BY DATEPART(HOUR, DateTimeColumn)
ORDER BY Hour;
GO

-- UNIONS with time
SELECT DateTimeColumn 
FROM DateTimeExpressionTest 
WHERE DATEPART(HOUR, DateTimeColumn) < 12
UNION
SELECT DateTimeColumn 
FROM DateTimeExpressionTest 
WHERE DATEPART(HOUR, DateTimeColumn) >= 12
ORDER BY DateTimeColumn;
GO

-- 3. DateTime-specific Functions

-- DateTime arithmetic
SELECT 
    DateTimeColumn,
    DATEADD(MILLISECOND, 100, DateTimeColumn) AS Plus100MS,
    DATEADD(SECOND, 30, DateTimeColumn) AS Plus30Seconds,
    DATEADD(MINUTE, 15, DateTimeColumn) AS Plus15Minutes,
    DATEADD(HOUR, 1, DateTimeColumn) AS PlusOneHour
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- DateTime parts
SELECT 
    DateTimeColumn,
    YEAR(DateTimeColumn) AS Year,
    MONTH(DateTimeColumn) AS Month,
    DAY(DateTimeColumn) AS Day,
    DATEPART(HOUR, DateTimeColumn) AS Hour,
    DATEPART(MINUTE, DateTimeColumn) AS Minute,
    DATEPART(SECOND, DateTimeColumn) AS Second,
    DATEPART(MILLISECOND, DateTimeColumn) AS Millisecond
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- DateTime differences with precision
SELECT 
    DateTimeColumn,
    DATEDIFF(MILLISECOND, '2023-01-01', DateTimeColumn) AS MSSinceNewYear,
    DATEDIFF(SECOND, '2023-01-01', DateTimeColumn) AS SecondsSinceNewYear,
    DATEDIFF(MINUTE, '2023-01-01', DateTimeColumn) AS MinutesSinceNewYear,
    DATEDIFF(HOUR, '2023-01-01', DateTimeColumn) AS HoursSinceNewYear
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- Complex time-based conditions
SELECT 
    DateTimeColumn,
    CASE 
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 0 AND 5 THEN 'Night'
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, DateTimeColumn) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS TimeOfDay,
    CASE 
        WHEN DATEPART(WEEKDAY, DateTimeColumn) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- Time-based window functions
SELECT 
    DateTimeColumn,
    Description,
    LAG(DateTimeColumn) OVER (ORDER BY DateTimeColumn) AS PreviousDateTime,
    LEAD(DateTimeColumn) OVER (ORDER BY DateTimeColumn) AS NextDateTime,
    DATEDIFF(MINUTE, LAG(DateTimeColumn) OVER (ORDER BY DateTimeColumn), DateTimeColumn) AS MinutesSincePrevious
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- DateTime grouping and aggregation
SELECT 
    DATEPART(HOUR, DateTimeColumn) AS Hour,
    COUNT(*) AS EventCount,
    MIN(DateTimeColumn) AS EarliestEvent,
    MAX(DateTimeColumn) AS LatestEvent,
    AVG(CAST(DATEPART(MINUTE, DateTimeColumn) AS FLOAT)) AS AvgMinute
FROM DateTimeExpressionTest
GROUP BY DATEPART(HOUR, DateTimeColumn)
ORDER BY Hour;
GO

-- Millisecond precision handling
SELECT 
    DateTimeColumn,
    DATEADD(MILLISECOND, -DATEPART(MILLISECOND, DateTimeColumn), DateTimeColumn) AS RoundedToSecond,
    DATEADD(SECOND, -DATEPART(SECOND, DateTimeColumn), 
        DATEADD(MILLISECOND, -DATEPART(MILLISECOND, DateTimeColumn), DateTimeColumn)) AS RoundedToMinute
FROM DateTimeExpressionTest ORDER BY DateTimeColumn;
GO

-- Time range overlaps
SELECT 
    a.DateTimeColumn AS DateTime1,
    b.DateTimeColumn AS DateTime2,
    CASE 
        WHEN a.DateTimeColumn BETWEEN b.DateTimeColumn AND DATEADD(HOUR, 1, b.DateTimeColumn) THEN 'Overlaps'
        ELSE 'No Overlap'
    END AS OverlapStatus
FROM DateTimeExpressionTest a
CROSS JOIN DateTimeExpressionTest b
WHERE a.ID < b.ID ORDER BY b.DateTimeColumn;
GO

-- 8. Additional DATE Specific Tests:

-- Test arithmetic operations with DATETIME
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    DATEADD(YEAR, 1, @dt) AS YearAdd,
    DATEADD(MONTH, 1, @dt) AS MonthAdd,
    DATEADD(DAY, 1, @dt) AS DayAdd,
    DATEADD(HOUR, 1, @dt) AS HourAdd,
    DATEADD(MINUTE, 1, @dt) AS MinuteAdd,
    DATEADD(SECOND, 1, @dt) AS SecondAdd,
    DATEADD(MILLISECOND, 1, @dt) AS MillisecondAdd;
GO

-- Test DATEDIFF with different parts
DECLARE @dt1 DATETIME = '2023-06-15 14:30:20.123';
DECLARE @dt2 DATETIME = '2024-07-16 16:45:30.456';
SELECT 
    DATEDIFF(YEAR, @dt1, @dt2) AS YearDiff,
    DATEDIFF(MONTH, @dt1, @dt2) AS MonthDiff,
    DATEDIFF(DAY, @dt1, @dt2) AS DayDiff,
    DATEDIFF(HOUR, @dt1, @dt2) AS HourDiff,
    DATEDIFF(MINUTE, @dt1, @dt2) AS MinuteDiff,
    DATEDIFF(SECOND, @dt1, @dt2) AS SecondDiff,
    DATEDIFF(MILLISECOND, @dt1, @dt2) AS MillisecondDiff;
GO

-- Test DATETRUNC function
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    DATETRUNC(YEAR, @dt) AS YearTrunc,
    DATETRUNC(MONTH, @dt) AS MonthTrunc,
    DATETRUNC(DAY, @dt) AS DayTrunc,
    DATETRUNC(HOUR, @dt) AS HourTrunc,
    DATETRUNC(MINUTE, @dt) AS MinuteTrunc,
    DATETRUNC(SECOND, @dt) AS SecondTrunc;
GO

-- Test EOMONTH function (converts to datetime)
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    CAST(EOMONTH(@dt) AS DATETIME) AS EndOfMonth,
    CAST(EOMONTH(@dt, 1) AS DATETIME) AS EndOfNextMonth,
    CAST(EOMONTH(@dt, -1) AS DATETIME) AS EndOfPreviousMonth;
GO

-- Test conversion to and from other date/time types
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    @dt AS Original,
    CAST(@dt AS DATE) AS ToDate,
    CAST(@dt AS DATETIME2) AS ToDateTime2,
    CAST(@dt AS DATETIMEOFFSET) AS ToDateTimeOffset,
    CAST(@dt AS TIME) AS ToTime;
GO

-- Test with different datetime formats
SET LANGUAGE us_english;
SELECT CAST('06/15/2023 14:30:20.123' AS DATETIME);
SET LANGUAGE British;
SELECT CAST('15/06/2023 14:30:20.123' AS DATETIME);
GO

-- Test with different language settings
SET LANGUAGE German;
SELECT DATENAME(MONTH, CAST('2023-06-15 14:30:20.123' AS DATETIME));
SET LANGUAGE French;
SELECT DATENAME(MONTH, CAST('2023-06-15 14:30:20.123' AS DATETIME));
GO
SET LANGUAGE us_english;
GO

-- Test with different DATEFIRST settings
SET DATEFIRST 1;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15 14:30:20.123' AS DATETIME));
SET DATEFIRST 7;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15 14:30:20.123' AS DATETIME));
GO

-- Error Handling Tests
-- Test out-of-range values
BEGIN TRY
    DECLARE @dt DATETIME = '10000-01-01 00:00:00';
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid datetime formats
BEGIN TRY
    SELECT CAST('2023-13-45 25:61:61' AS DATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid datetime values
BEGIN TRY
    SELECT CAST('2023-02-30 14:30:20.123' AS DATETIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test DATE_BUCKET function
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    DATE_BUCKET(WEEK, 1, @dt) AS WeekBucket,
    DATE_BUCKET(MONTH, 1, @dt) AS MonthBucket,
    DATE_BUCKET(YEAR, 1, @dt) AS YearBucket;
GO

-- Test with different century dates
SELECT 
    CAST('1753-01-01 00:00:00' AS DATETIME) AS MinDateTime,
    CAST('1900-01-01 00:00:00' AS DATETIME) AS Year1900,
    CAST('2000-01-01 00:00:00' AS DATETIME) AS Year2000;
GO

-- Test leap year handling
SELECT 
    ISDATE('2023-02-29 14:30:20.123') AS [2023 (non-leap year)],
    ISDATE('2024-02-29 14:30:20.123') AS [2024 (leap year)];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(DATETIME, '06/15/2023 14:30:20.123', 101) AS Style101,
    CONVERT(DATETIME, '15.06.2023 14:30:20.123', 104) AS Style104,
    CONVERT(DATETIME, '15 Jun 2023 14:30:20.123', 106) AS Style106,
    CONVERT(DATETIME, '2023-06-15 14:30:20.123', 120) AS Style120;
GO

-- Test with DATEFORMAT setting
SET DATEFORMAT mdy;
SELECT CAST('06/15/2023 14:30:20.123' AS DATETIME);
SET DATEFORMAT dmy;
SELECT CAST('15/06/2023 14:30:20.123' AS DATETIME);
GO
SET DATEFORMAT mdy;
GO

-- Test datetime parts extraction
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    YEAR(@dt) AS [Year],
    MONTH(@dt) AS [Month],
    DAY(@dt) AS [Day],
    DATEPART(HOUR, @dt) AS [Hour],
    DATEPART(MINUTE, @dt) AS [Minute],
    DATEPART(SECOND, @dt) AS [Second],
    DATEPART(MILLISECOND, @dt) AS [Millisecond],
    DATEPART(QUARTER, @dt) AS [Quarter],
    DATEPART(DAYOFYEAR, @dt) AS [DayOfYear],
    DATEPART(WEEK, @dt) AS [Week],
    DATEPART(WEEKDAY, @dt) AS [Weekday];
GO

-- Test with different languages for datetime parts
SET LANGUAGE Italian;
SELECT 
    DATENAME(MONTH, '2023-06-15 14:30:20.123') AS [Italian Month],
    DATENAME(WEEKDAY, '2023-06-15 14:30:20.123') AS [Italian Weekday];
SET LANGUAGE English;
SELECT 
    DATENAME(MONTH, '2023-06-15 14:30:20.123') AS [English Month],
    DATENAME(WEEKDAY, '2023-06-15 14:30:20.123') AS [English Weekday];
GO

-- Test datetime range
SELECT 
    CAST('1753-01-01 00:00:00' AS DATETIME) AS [Minimum DATETIME],
    CAST('9999-12-31 23:59:59.997' AS DATETIME) AS [Maximum DATETIME];
GO

-- Test with time zone conversion
DECLARE @dt DATETIME = '2023-06-15 14:30:20.123';
SELECT 
    @dt AS [Original DateTime],
    CAST(@dt AT TIME ZONE 'UTC' AS DATETIME) AS [UTC],
    CAST(@dt AT TIME ZONE 'Pacific Standard Time' AS DATETIME) AS [Pacific Time];
GO

-- Test millisecond rounding
SELECT 
    CAST('2023-06-15 14:30:20.123' AS DATETIME) AS [Original],
    CAST('2023-06-15 14:30:20.997' AS DATETIME) AS [Round Up],
    CAST('2023-06-15 14:30:20.000' AS DATETIME) AS [Round Down];
GO

-- Clean up: Drop all created objects
DROP TABLE DateTimeTest;
DROP TABLE DateTimeDefaultTest;
DROP FUNCTION dbo.GetCurrentDateTime();
DROP TYPE MyDateTime;
DROP TABLE DateTimeFormatTest;
DROP PROCEDURE InsertDateTimeTest;
DROP PROCEDURE InsertDateTimeTest1;
DROP PROCEDURE TestDateTimeFormat;
DROP TABLE DateTimeConversionTest;
DROP PROCEDURE InsertDateTimeConversionTest;
DROP TABLE DatetimeTimeZoneTest;
DROP PROCEDURE InsertDatetimeTimeZoneTest;
DROP TABLE UDDTDateTimeTest;
DROP PROCEDURE TestUDDTDateTimeProc;
DROP TYPE BusinessDateTime;
DROP TYPE HistoricalDateTime;
DROP FUNCTION dbo.TestDateTimeFunction;
DROP TABLE DateTimeImplicitConversionTest;
DROP PROCEDURE InsertDateTimeTestResult;
DROP FUNCTION dbo.AddDaysToDateTime;
DROP PROCEDURE dbo.ProcessDateTime;
DROP VIEW dbo.DateTimeView;
DROP TABLE DateTimeDMLTestChild;
DROP TABLE DateTimeDMLTest;
DROP TABLE DateTimeIndexTest;
DROP TABLE DateTimeExpressionTest;
DROP TABLE DateTimeTest1;
DROP TABLE DATETIME_partition;
DROP PARTITION SCHEME DATETIME_partition_scheme;
DROP PARTITION FUNCTION DATETIME_partition_func;
GO
