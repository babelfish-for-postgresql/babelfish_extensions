-- sla 200000
-- 1. Basic Testing:
-- Create DateTest table
CREATE TABLE DateTest (
    ID INT IDENTITY PRIMARY KEY,
    DateCol DATE
);
GO

-- Empty/NULL values
INSERT INTO DateTest (DateCol) VALUES (NULL);
GO
Declare @a date;
INSERT INTO DateTest (DateCol) VALUES (@a), ('');
GO
SELECT * FROM DateTest WHERE DateCol IS NULL;
GO
SELECT * FROM DateTest;
GO

-- Default values
CREATE TABLE DateDefaultTest (
    ID INT PRIMARY KEY,
    DateCol DATE
);
INSERT INTO DateDefaultTest VALUES (1, CAST('19:00:00' As date));
SELECT * FROM DateDefaultTest;
GO

-- Character length
DECLARE @d DATE = '  2023-06-15  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

-- Edge case values
DECLARE @d1 DATE = '0001-01-01 00:00:00.000';
DECLARE @d2 DATE = '9999-12-31 23:59:59.999';
DECLARE @d3 DATE = '9999-12-31 23:59:59.999 +5:00';
DECLARE @d4 DATE = '9999-12-31 23:59:59.999 -5:00';
SELECT @d1, @d2, @d3, @d4;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d DATE;
SET @d = '2023-06-15';
SELECT @d, CAST('2023-06-15' AS DATE), CONVERT(DATE, '2023-06-15');
GO

-- DATEFORMAT tests
-- Create a test table
CREATE TABLE DateFormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ParsedDate DATE
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateFormatTest (Description, InputString, ParsedDate)
        VALUES (@Description, @InputString, CAST(@InputString AS DATE));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Standard formats
EXEC InsertDateTest 'Standard - YYYY-MM-DD', '2023-06-16';
EXEC InsertDateTest 'Standard - YYYYMMDD', '20230616';
GO

-- 2. Month-day-year formats
SET DATEFORMAT mdy;
GO
EXEC InsertDateTest 'MDY - Slash format', '6/16/2023';
GO
EXEC InsertDateTest 'MDY - Hyphen format', '6-16-2023';
GO
EXEC InsertDateTest 'MDY - Period format', '6.16.2023';
GO
EXEC InsertDateTest 'MDY - Space format', '6 16 2023';
GO
EXEC InsertDateTest 'MDY - No separator', '6162023';
GO

-- 3. Day-month-year formats
SET DATEFORMAT dmy;
GO
EXEC InsertDateTest 'DMY - Slash format', '16/6/2023';
GO
EXEC InsertDateTest 'DMY - Hyphen format', '16-6-2023';
GO
EXEC InsertDateTest 'DMY - Period format', '16.6.2023';
GO
EXEC InsertDateTest 'DMY - Space format', '16 6 2023';
GO
EXEC InsertDateTest 'DMY - No separator', '16062023';
GO

-- 4. Year-month-day formats
SET DATEFORMAT ymd;
GO
EXEC InsertDateTest 'YMD - Slash format', '2023/6/16';
GO
EXEC InsertDateTest 'YMD - Hyphen format', '2023-6-16';
GO
EXEC InsertDateTest 'YMD - Period format', '2023.6.16';
GO
EXEC InsertDateTest 'YMD - Space format', '2023 6 16';
GO
EXEC InsertDateTest 'YMD - No separator', '20230616';
GO

-- 5. Month-year-day formats
SET DATEFORMAT myd;
GO
EXEC InsertDateTest 'MYD - Slash format', '6/2023/16';
GO
EXEC InsertDateTest 'MYD - Hyphen format', '6-2023-16';
GO
EXEC InsertDateTest 'MYD - Period format', '6.2023.16';
GO
EXEC InsertDateTest 'MYD - Space format', '6 2023 16';
GO

-- 6. Day-year-month formats
SET DATEFORMAT dym;
GO
EXEC InsertDateTest 'DYM - Slash format', '16/2023/6';
GO
EXEC InsertDateTest 'DYM - Hyphen format', '16-2023-6';
GO
EXEC InsertDateTest 'DYM - Period format', '16.2023.6';
GO
EXEC InsertDateTest 'DYM - Space format', '16 2023 6';
GO

-- 7. Alphabetical formats
SET DATEFORMAT mdy;
GO
EXEC InsertDateTest 'Alphabetical - Full month name, comma', 'June 16, 2023';
GO
EXEC InsertDateTest 'Alphabetical - Full month name, no comma', 'June 16 2023';
GO
EXEC InsertDateTest 'Alphabetical - Abbreviated month, comma', 'Jun 16, 2023';
GO
EXEC InsertDateTest 'Alphabetical - Abbreviated month, no comma', 'Jun 16 2023';
GO
EXEC InsertDateTest 'Alphabetical - Month first, full name', 'June 2023 16';
GO
EXEC InsertDateTest 'Alphabetical - Month first, abbreviated', 'Jun 2023 16';
GO
EXEC InsertDateTest 'Alphabetical - Year first, full month', '2023 June 16';
GO
EXEC InsertDateTest 'Alphabetical - Year first, abbreviated month', '2023 Jun 16';
GO
EXEC InsertDateTest 'Alphabetical - Day first, full month', '16 June 2023';
GO
EXEC InsertDateTest 'Alphabetical - Day first, abbreviated month', '16 Jun 2023';
GO
EXEC InsertDateTest 'Alphabetical - Full month name, year only', 'June 2023';
GO
EXEC InsertDateTest 'Alphabetical - Abbreviated month, year only', 'Jun 2023';
GO

-- 8. ISO 8601 formats
EXEC InsertDateTest 'ISO 8601 - Basic (no separators)', '20230616';
GO
EXEC InsertDateTest 'ISO 8601 - Extended (with separators)', '2023-06-16';
GO
EXEC InsertDateTest 'ISO 8601 - Week date format', '2023-W24-5';
GO
EXEC InsertDateTest 'ISO 8601 - Ordinal date format', '2023-167';
GO

-- 9. ODBC canonical format
EXEC InsertDateTest 'ODBC canonical', '{d ''2023-06-16''}';
GO

-- 10. Different century representations
EXEC InsertDateTest 'Two-digit year - 20th century', '6/16/99';
GO
EXEC InsertDateTest 'Two-digit year - 21st century', '6/16/01';
GO
EXEC InsertDateTest 'Four-digit year - 19th century', '1899-06-16';
GO
EXEC InsertDateTest 'Four-digit year - 20th century', '1999-06-16';
GO
EXEC InsertDateTest 'Four-digit year - 21st century', '2023-06-16';
GO

-- 11. Variations with leading zeros
EXEC InsertDateTest 'Leading zeros - MDY', '06/16/2023';
GO
EXEC InsertDateTest 'Leading zeros - DMY', '16/06/2023';
GO
EXEC InsertDateTest 'Leading zeros - YMD', '2023/06/16';
GO

-- 12. Variations without leading zeros
EXEC InsertDateTest 'No leading zeros - MDY', '6/16/2023';
GO
EXEC InsertDateTest 'No leading zeros - DMY', '16/6/2023';
GO
EXEC InsertDateTest 'No leading zeros - YMD', '2023/6/16';
GO

-- 13. Mixed separators (these should fail but are worth testing)
EXEC InsertDateTest 'Mixed separators - Slash and hyphen', '2023/06-16';
GO
EXEC InsertDateTest 'Mixed separators - Hyphen and period', '2023-06.16';
GO

-- 14. Unusual but valid formats
EXEC InsertDateTest 'Year only', '2023';
GO
EXEC InsertDateTest 'Year and month only', '2023-06';
GO
EXEC InsertDateTest 'Reversed full month name', '2023 16 June';
GO

-- 15. Language-specific formats
SET LANGUAGE French;
GO
EXEC InsertDateTest 'French - Full month name', '16 juin 2023';
GO
EXEC InsertDateTest 'French - Abbreviated month', '16 juin. 2023';
GO

SET LANGUAGE German;
GO
EXEC InsertDateTest 'German - Full month name', '16. Juni 2023';
GO
EXEC InsertDateTest 'German - Abbreviated month', '16. Jun 2023';
GO

SET LANGUAGE Spanish;
GO
EXEC InsertDateTest 'Spanish - Full month name', '16 de junio de 2023';
GO
EXEC InsertDateTest 'Spanish - Abbreviated month', '16 jun. 2023';
GO
SET LANGUAGE us_english;
GO

-- 16. Edge cases
EXEC InsertDateTest 'Minimum valid date', '0001-01-01';
GO
EXEC InsertDateTest 'Maximum valid date', '9999-12-31';
GO
EXEC InsertDateTest 'Leap year - February 29', '2024-02-29';
GO
EXEC InsertDateTest 'Non-leap year - February 28', '2023-02-28';
GO

-- 17. Invalid formats (these should fail)
EXEC InsertDateTest 'Invalid - Year out of range (low)', '0000-01-01';
GO
EXEC InsertDateTest 'Invalid - Year out of range (high)', '10000-01-01';
GO
EXEC InsertDateTest 'Invalid - Month out of range', '2023-13-01';
GO
EXEC InsertDateTest 'Invalid - Day out of range', '2023-06-31';
GO
EXEC InsertDateTest 'Invalid - Non-existent date', '2023-02-29';
GO
EXEC InsertDateTest 'Invalid - Incorrect separators', '2023/06-16';
GO
EXEC InsertDateTest 'Invalid - Letters in date', '2023-JUN-16';
GO
EXEC InsertDateTest 'Invalid - Incomplete date', '2023-06';
GO
EXEC InsertDateTest 'Invalid - Time included', '2023-06-16 12:00:00';
GO
EXEC InsertDateTest 'Invalid - Extra spaces', '2023 - 06 - 16';
GO
EXEC InsertDateTest 'Invalid - Reversed DMY', '2023 16 06';
GO

-- Additional combinations
SET DATEFORMAT mdy;
GO

-- d,mm,yyyy variations
EXEC InsertDateTest 'MDY - d,mm,yyyy - Comma', '5,06,2023';
GO
EXEC InsertDateTest 'MDY - d,mm,yyyy - Period', '5.06.2023';
GO
EXEC InsertDateTest 'MDY - d,mm,yyyy - Hyphen', '5-06-2023';
GO
EXEC InsertDateTest 'MDY - d,mm,yyyy - Space', '5 06 2023';
GO

-- dd,m,yy variations
EXEC InsertDateTest 'MDY - dd,m,yy - Comma', '05,6,23';
GO
EXEC InsertDateTest 'MDY - dd,m,yy - Period', '05.6.23';
GO
EXEC InsertDateTest 'MDY - dd,m,yy - Hyphen', '05-6-23';
GO
EXEC InsertDateTest 'MDY - dd,m,yy - Space', '05 6 23';
GO

-- d,m,yy variations
EXEC InsertDateTest 'MDY - d,m,yy - Comma', '5,6,23';
GO
EXEC InsertDateTest 'MDY - d,m,yy - Period', '5.6.23';
GO
EXEC InsertDateTest 'MDY - d,m,yy - Hyphen', '5-6-23';
GO
EXEC InsertDateTest 'MDY - d,m,yy - Space', '5 6 23';
GO

-- d,m,y variations
EXEC InsertDateTest 'MDY - d,m,y - Comma', '5,6,3';
GO
EXEC InsertDateTest 'MDY - d,m,y - Period', '5.6.3';
GO
EXEC InsertDateTest 'MDY - d,m,y - Hyphen', '5-6-3';
GO
EXEC InsertDateTest 'MDY - d,m,y - Space', '5 6 3';
GO

-- m,d,yyyy variations
EXEC InsertDateTest 'MDY - m,d,yyyy - Comma', '6,5,2023';
GO
EXEC InsertDateTest 'MDY - m,d,yyyy - Period', '6.5.2023';
GO
EXEC InsertDateTest 'MDY - m,d,yyyy - Hyphen', '6-5-2023';
GO
EXEC InsertDateTest 'MDY - m,d,yyyy - Space', '6 5 2023';
GO

-- mm,dd,yy variations
EXEC InsertDateTest 'MDY - mm,dd,yy - Comma', '06,05,23';
GO
EXEC InsertDateTest 'MDY - mm,dd,yy - Period', '06.05.23';
GO
EXEC InsertDateTest 'MDY - mm,dd,yy - Hyphen', '06-05-23';
GO
EXEC InsertDateTest 'MDY - mm,dd,yy - Space', '06 05 23';
GO

-- yyyy,mm,d variations
EXEC InsertDateTest 'YMD - yyyy,mm,d - Comma', '2023,06,5';
GO
EXEC InsertDateTest 'YMD - yyyy,mm,d - Period', '2023.06.5';
GO
EXEC InsertDateTest 'YMD - yyyy,mm,d - Hyphen', '2023-06-5';
GO
EXEC InsertDateTest 'YMD - yyyy,mm,d - Space', '2023 06 5';
GO

-- yy,m,dd variations
EXEC InsertDateTest 'YMD - yy,m,dd - Comma', '23,6,05';
GO
EXEC InsertDateTest 'YMD - yy,m,dd - Period', '23.6.05';
GO
EXEC InsertDateTest 'YMD - yy,m,dd - Hyphen', '23-6-05';
GO
EXEC InsertDateTest 'YMD - yy,m,dd - Space', '23 6 05';
GO

SET DATEFORMAT dmy;
GO

-- d,mm,yyyy variations (DMY)
EXEC InsertDateTest 'DMY - d,mm,yyyy - Comma', '5,06,2023';
GO
EXEC InsertDateTest 'DMY - d,mm,yyyy - Period', '5.06.2023';
GO
EXEC InsertDateTest 'DMY - d,mm,yyyy - Hyphen', '5-06-2023';
GO
EXEC InsertDateTest 'DMY - d,mm,yyyy - Space', '5 06 2023';
GO

-- dd,m,yy variations (DMY)
EXEC InsertDateTest 'DMY - dd,m,yy - Comma', '05,6,23';
GO
EXEC InsertDateTest 'DMY - dd,m,yy - Period', '05.6.23';
GO
EXEC InsertDateTest 'DMY - dd,m,yy - Hyphen', '05-6-23';
GO
EXEC InsertDateTest 'DMY - dd,m,yy - Space', '05 6 23';
GO

-- d,m,yy variations (DMY)
EXEC InsertDateTest 'DMY - d,m,yy - Comma', '5,6,23';
GO
EXEC InsertDateTest 'DMY - d,m,yy - Period', '5.6.23';
GO
EXEC InsertDateTest 'DMY - d,m,yy - Hyphen', '5-6-23';
GO
EXEC InsertDateTest 'DMY - d,m,yy - Space', '5 6 23';
GO

-- d,m,y variations (DMY)
EXEC InsertDateTest 'DMY - d,m,y - Comma', '5,6,3';
GO
EXEC InsertDateTest 'DMY - d,m,y - Period', '5.6.3';
GO
EXEC InsertDateTest 'DMY - d,m,y - Hyphen', '5-6-3';
GO
EXEC InsertDateTest 'DMY - d,m,y - Space', '5 6 3';
GO

SET DATEFORMAT ymd;
GO

-- yyyy,m,d variations
EXEC InsertDateTest 'YMD - yyyy,m,d - Comma', '2023,6,5';
GO
EXEC InsertDateTest 'YMD - yyyy,m,d - Period', '2023.6.5';
GO
EXEC InsertDateTest 'YMD - yyyy,m,d - Hyphen', '2023-6-5';
GO
EXEC InsertDateTest 'YMD - yyyy,m,d - Space', '2023 6 5';
GO

-- yy,mm,dd variations
EXEC InsertDateTest 'YMD - yy,mm,dd - Comma', '23,06,05';
GO
EXEC InsertDateTest 'YMD - yy,mm,dd - Period', '23.06.05';
GO
EXEC InsertDateTest 'YMD - yy,mm,dd - Hyphen', '23-06-05';
GO
EXEC InsertDateTest 'YMD - yy,mm,dd - Space', '23 06 05';
GO

-- y,m,d variations
EXEC InsertDateTest 'YMD - y,m,d - Comma', '3,6,5';
GO
EXEC InsertDateTest 'YMD - y,m,d - Period', '3.6.5';
GO
EXEC InsertDateTest 'YMD - y,m,d - Hyphen', '3-6-5';
GO
EXEC InsertDateTest 'YMD - y,m,d - Space', '3 6 5';
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTest1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO DateFormatTest (Description, InputString, Collation, ParsedDate)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS DATE))';
        
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

-- List of collations to test
CREATE PROCEDURE TestDateFormat
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
        EXEC InsertDateTest1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Now let's run our tests with different collations

-- Standard formats
EXEC TestDateFormat 'Standard - YYYY-MM-DD', '2023-06-16';
GO
EXEC TestDateFormat 'Standard - YYYYMMDD', '20230616';
GO

-- Month-day-year formats
SET DATEFORMAT mdy;
GO
EXEC TestDateFormat 'MDY - Slash format', '6/16/2023';
GO
EXEC TestDateFormat 'MDY - Hyphen format', '6-16-2023';
GO
EXEC TestDateFormat 'MDY - Period format', '6.16.2023';
GO
EXEC TestDateFormat 'MDY - Space format', '6 16 2023';
GO
EXEC TestDateFormat 'MDY - No separator', '6162023';
GO

-- Day-month-year formats
SET DATEFORMAT dmy;
GO
EXEC TestDateFormat 'DMY - Slash format', '16/6/2023';
GO
EXEC TestDateFormat 'DMY - Hyphen format', '16-6-2023';
GO
EXEC TestDateFormat 'DMY - Period format', '16.6.2023';
GO
EXEC TestDateFormat 'DMY - Space format', '16 6 2023';
GO
EXEC TestDateFormat 'DMY - No separator', '16062023';
GO

-- Year-month-day formats
SET DATEFORMAT ymd;
GO
EXEC TestDateFormat 'YMD - Slash format', '2023/6/16';
GO
EXEC TestDateFormat 'YMD - Hyphen format', '2023-6-16';
GO
EXEC TestDateFormat 'YMD - Period format', '2023.6.16';
GO
EXEC TestDateFormat 'YMD - Space format', '2023 6 16';
GO
EXEC TestDateFormat 'YMD - No separator', '20230616';
GO

-- Alphabetical formats
SET DATEFORMAT mdy;
GO
EXEC TestDateFormat 'Alphabetical - Full month name, comma', 'June 16, 2023';
GO
EXEC TestDateFormat 'Alphabetical - Full month name, no comma', 'June 16 2023';
GO
EXEC TestDateFormat 'Alphabetical - Abbreviated month, comma', 'Jun 16, 2023';
GO
EXEC TestDateFormat 'Alphabetical - Abbreviated month, no comma', 'Jun 16 2023';
GO

-- ISO 8601 formats
EXEC TestDateFormat 'ISO 8601 - Basic (no separators)', '20230616';
GO
EXEC TestDateFormat 'ISO 8601 - Extended (with separators)', '2023-06-16';
GO

-- ODBC canonical format
EXEC TestDateFormat 'ODBC canonical', '{d ''2023-06-16''}';
GO

-- Different century representations
EXEC TestDateFormat 'Two-digit year - 20th century', '6/16/99';
GO
EXEC TestDateFormat 'Two-digit year - 21st century', '6/16/01';
GO
EXEC TestDateFormat 'Four-digit year - 19th century', '1899-06-16';
GO

-- Variations with leading zeros
EXEC TestDateFormat 'Leading zeros - MDY', '06/16/2023';
GO
EXEC TestDateFormat 'Leading zeros - DMY', '16/06/2023';
GO
EXEC TestDateFormat 'Leading zeros - YMD', '2023/06/16';
GO

-- Variations without leading zeros
EXEC TestDateFormat 'No leading zeros - MDY', '6/16/2023';
GO
EXEC TestDateFormat 'No leading zeros - DMY', '16/6/2023';
GO
EXEC TestDateFormat 'No leading zeros - YMD', '2023/6/16';
GO

-- Additional combinations
SET DATEFORMAT mdy;
GO
EXEC TestDateFormat 'MDY - d,mm,yyyy - Comma', '5,06,2023';
GO
EXEC TestDateFormat 'MDY - dd,m,yy - Period', '05.6.23';
GO
EXEC TestDateFormat 'MDY - d,m,yy - Hyphen', '5-6-23';
GO
EXEC TestDateFormat 'MDY - d,m,y - Space', '5 6 3';
GO

SET DATEFORMAT dmy;
GO
EXEC TestDateFormat 'DMY - d,mm,yyyy - Comma', '5,06,2023';
GO
EXEC TestDateFormat 'DMY - dd,m,yy - Period', '05.6.23';
GO
EXEC TestDateFormat 'DMY - d,m,yy - Hyphen', '5-6-23';
GO
EXEC TestDateFormat 'DMY - d,m,y - Space', '5 6 3';
GO

SET DATEFORMAT ymd;
GO
EXEC TestDateFormat 'YMD - yyyy,m,d - Comma', '2023,6,5';
GO
EXEC TestDateFormat 'YMD - yy,mm,dd - Period', '23.06.05';
GO
EXEC TestDateFormat 'YMD - y,m,d - Hyphen', '3-6-5';
GO

-- Edge cases
EXEC TestDateFormat 'Minimum valid date', '0001-01-01';
GO
EXEC TestDateFormat 'Maximum valid date', '9999-12-31';
GO
EXEC TestDateFormat 'Leap year - February 29', '2024-02-29';
GO

-- Invalid formats (these should fail)
EXEC TestDateFormat 'Invalid - Year out of range (low)', '0000-01-01';
GO
EXEC TestDateFormat 'Invalid - Year out of range (high)', '10000-01-01';
GO
EXEC TestDateFormat 'Invalid - Month out of range', '2023-13-01';
GO
EXEC TestDateFormat 'Invalid - Day out of range', '2023-06-31';
GO
EXEC TestDateFormat 'Invalid - Non-existent date', '2023-02-29';
GO

SET DATEFORMAT mdy;
GO

-- Display results
SELECT * FROM DateFormatTest ORDER BY ID;
GO

-- String literal notations
SELECT CAST('2023-06-15' AS DATE), CAST('20230615' AS DATE), CAST('June 15, 2023' AS DATE);
GO

-- Create a test table
CREATE TABLE DateConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedDate DATE
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateConversionTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateConversionTest (Description, InputString, ConvertedDate)
        VALUES (@Description, @InputString, CAST(@InputString AS DATE));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC DATE
EXEC InsertDateConversionTest 'ODBC DATE', '{d ''2023-06-16''}';
GO

-- ODBC TIME (should use default date)
EXEC InsertDateConversionTest 'ODBC TIME', '{t ''12:34:56''}';
GO

-- ODBC DATETIME
EXEC InsertDateConversionTest 'ODBC DATETIME', '{ts ''2023-06-16 12:34:56''}';
GO

-- DATE only
EXEC InsertDateConversionTest 'DATE only', '2023-06-16';
GO

-- TIME only (should use default date)
EXEC InsertDateConversionTest 'TIME only', '12:34:56';
GO

-- TIMEZONE only (should use default date)
EXEC InsertDateConversionTest 'TIMEZONE only', '+05:30';
GO

-- DATE + TIME
EXEC InsertDateConversionTest 'DATE + TIME', '2023-06-16 12:34:56';
GO

-- DATE + TIMEZONE (should fail)
EXEC InsertDateConversionTest 'DATE + TIMEZONE', '2023-06-16 +05:30';
GO

-- TIME + TIMEZONE (should use default date)
EXEC InsertDateConversionTest 'TIME + TIMEZONE', '12:34:56 +05:30';
GO

-- DATE + TIME + TIMEZONE
EXEC InsertDateConversionTest 'DATE + TIME + TIMEZONE', '2023-06-16 12:34:56 +05:30';
GO

-- Additional tests for different date formats
EXEC InsertDateConversionTest 'ISO 8601 date', '2023-06-16';
GO
EXEC InsertDateConversionTest 'US date format', '06/16/2023';
GO
EXEC InsertDateConversionTest 'British date format', '16/06/2023';
GO
EXEC InsertDateConversionTest 'Verbal date format', 'June 16, 2023';
GO

-- Tests for edge cases
EXEC InsertDateConversionTest 'Minimum date', '0001-01-01';
GO
EXEC InsertDateConversionTest 'Maximum date', '9999-12-31';
GO
EXEC InsertDateConversionTest 'Leap year date', '2024-02-29';
GO

-- Tests for invalid conversions
EXEC InsertDateConversionTest 'Invalid date', '2023-02-30';
GO
EXEC InsertDateConversionTest 'Invalid format', '2023/16/06';
GO
EXEC InsertDateConversionTest 'Date out of range', '10000-01-01';
GO

-- Display results
SELECT * FROM DateConversionTest ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'date';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'date' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- AT TIME ZONE

-- Create a test table
CREATE TABLE DateTimeZoneTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputDate DATE,
    TimeZone NVARCHAR(100),
    Result NVARCHAR(MAX)
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeZoneTest
    @Description NVARCHAR(100),
    @InputDate DATE,
    @TimeZone NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @Result NVARCHAR(MAX);
        SET @Result = CAST(@InputDate AT TIME ZONE @TimeZone AS NVARCHAR(MAX));
        
        INSERT INTO DateTimeZoneTest (Description, InputDate, TimeZone, Result)
        VALUES (@Description, @InputDate, @TimeZone, @Result);
        
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        INSERT INTO DateTimeZoneTest (Description, InputDate, TimeZone, Result)
        VALUES (@Description, @InputDate, @TimeZone, ERROR_MESSAGE());
        
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO


-- Test cases
EXEC InsertDateTimeZoneTest 'Current date to UTC', '2023-06-16', 'UTC';
GO
EXEC InsertDateTimeZoneTest 'Current date to Pacific Standard Time', '2023-06-16', 'Pacific Standard Time';
GO
EXEC InsertDateTimeZoneTest 'Current date to Eastern Standard Time', '2023-06-16', 'Eastern Standard Time';
GO
EXEC InsertDateTimeZoneTest 'Current date to Central European Standard Time', '2023-06-16', 'Central European Standard Time';
GO
EXEC InsertDateTimeZoneTest 'Current date to Tokyo Standard Time', '2023-06-16', 'Tokyo Standard Time';
GO

-- Test with specific dates
EXEC InsertDateTimeZoneTest 'Summer date to Pacific Standard Time', '2023-07-15', 'Pacific Standard Time';
GO
EXEC InsertDateTimeZoneTest 'Winter date to Pacific Standard Time', '2023-12-15', 'Pacific Standard Time';
GO

-- Test with daylight saving time transition dates
EXEC InsertDateTimeZoneTest 'DST Start 2023 to Pacific Standard Time', '2023-03-12', 'Pacific Standard Time';
GO
EXEC InsertDateTimeZoneTest 'DST End 2023 to Pacific Standard Time', '2023-11-05', 'Pacific Standard Time';
GO

-- Test with minimum and maximum dates
EXEC InsertDateTimeZoneTest 'Minimum date to UTC', '0001-01-01', 'UTC';
GO
EXEC InsertDateTimeZoneTest 'Maximum date to UTC', '9999-12-31', 'UTC';
GO

-- Test with invalid time zone
EXEC InsertDateTimeZoneTest 'Invalid time zone', '2023-06-16', 'Invalid Time Zone';
GO

-- Test with time zones that have different offsets
EXEC InsertDateTimeZoneTest 'Date to India Standard Time', '2023-06-16', 'India Standard Time';
GO
EXEC InsertDateTimeZoneTest 'Date to New Zealand Standard Time', '2023-06-16', 'New Zealand Standard Time';
GO

-- Test with a time zone that doesn't observe DST
EXEC InsertDateTimeZoneTest 'Date to Saudi Arabia Standard Time', '2023-06-16', 'Saudi Arabia Standard Time';
GO

-- Display results
SELECT * FROM DateTimeZoneTest ORDER BY ID;
GO

-- different timezone
select set_config('timezone', 'Asia/Kolkata', false);
GO
SELECT CAST('2023-06-15' AS DATE), CAST('20230615' AS DATE), CAST('June 15, 2023' AS DATE);
GO
BEGIN TRANSACTION;
select set_config('timezone', 'America/Los_Angeles', false);
GO
SELECT CAST('2023-06-15' AS DATE), CAST('20230615' AS DATE), CAST('June 15, 2023' AS DATE);
GO
COMMIT TRANSACTION;
GO
SELECT CAST('2023-06-15' AS DATE), CAST('20230615' AS DATE), CAST('June 15, 2023' AS DATE);
GO
select set_config('timezone', 'UTC', false);
GO

-- Precedence Order of datatypes
SELECT CASE WHEN CAST('2023-06-15' AS DATE) = '2023-06-15' THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d DATE', @d = '2023-06-15';
GO

-- User Defined Datatypes on date datatypes
CREATE TYPE MyDate FROM DATE;
GO
DECLARE @md MyDate = '2023-06-15';
SELECT @md;
GO

-- 1. Create User-Defined Data Types based on DATE
CREATE TYPE BusinessDate FROM DATE;
CREATE TYPE HistoricalDate FROM DATE;
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTDateTest (
    ID INT PRIMARY KEY,
    RegularDate DATE,
    BusinessDateCol BusinessDate,
    HistoricalDateCol HistoricalDate
);
GO

-- 3. Insert data into the table
INSERT INTO UDDTDateTest (ID, RegularDate, BusinessDateCol, HistoricalDateCol)
VALUES 
(1, '2023-06-16', '2023-06-16', '1776-07-04'),
(2, '2023-06-17', '2023-06-17', '1945-08-15'),
(3, '2023-06-18', '2023-06-18', '2000-01-01'),
(4, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTDateTest ORDER BY ID;
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
WHERE TABLE_NAME = 'UDDTDateTest' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularDate AS VARCHAR(20)) AS RegularDateString,
    CAST(BusinessDateCol AS VARCHAR(20)) AS BusinessDateString,
    CAST(HistoricalDateCol AS VARCHAR(20)) AS HistoricalDateString,
    CAST(RegularDate AS DATETIME) AS RegularDateTime,
    CAST(BusinessDateCol AS DATETIME) AS BusinessDateTime,
    CAST(HistoricalDateCol AS DATETIME) AS HistoricalDateTime
FROM UDDTDateTest ORDER BY ID;
GO

-- 7. Test date functions
SELECT 
    ID,
    DATEADD(DAY, 1, RegularDate) AS RegularNextDay,
    DATEADD(DAY, 1, BusinessDateCol) AS BusinessNextDay,
    DATEADD(DAY, 1, HistoricalDateCol) AS HistoricalNextDay,
    DATEDIFF(YEAR, HistoricalDateCol, BusinessDateCol) AS YearsBetween
FROM UDDTDateTest ORDER BY ID;
GO

-- 8. Test constraints
ALTER TABLE UDDTDateTest ADD CONSTRAINT CK_BusinessDate 
    CHECK (BusinessDateCol >= '2000-01-01' AND BusinessDateCol <= '2099-12-31');
GO

-- This should succeed
INSERT INTO UDDTDateTest (ID, RegularDate, BusinessDateCol, HistoricalDateCol)
VALUES (5, '2023-06-19', '2023-06-19', '1989-11-09');
GO

-- This should fail
INSERT INTO UDDTDateTest (ID, RegularDate, BusinessDateCol, HistoricalDateCol)
VALUES (6, '2023-06-20', '1999-12-31', '1989-11-09');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTDateProc
    @BusinessDate BusinessDate,
    @HistoricalDate HistoricalDate
AS
BEGIN
    SELECT 
        @BusinessDate AS InputBusinessDate,
        @HistoricalDate AS InputHistoricalDate,
        DATEDIFF(YEAR, @HistoricalDate, @BusinessDate) AS YearsBetween;
END
GO

-- Execute the stored procedure
EXEC TestUDDTDateProc @BusinessDate = '2023-06-16', @HistoricalDate = '1776-07-04';
GO

-- 10. Test implicit conversions
DECLARE @RegularDate DATE = '2023-06-16';
DECLARE @BusinessDate BusinessDate = @RegularDate;
DECLARE @HistoricalDate HistoricalDate = '1776-07-04';

SELECT 
    @RegularDate AS RegularDate,
    @BusinessDate AS BusinessDate,
    @HistoricalDate AS HistoricalDate;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessDate ON UDDTDateTest(BusinessDateCol);
CREATE INDEX IX_HistoricalDate ON UDDTDateTest(HistoricalDateCol);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTDateTest WHERE BusinessDateCol = '2023-06-16';
SELECT * FROM UDDTDateTest WHERE HistoricalDateCol = '1776-07-04';
SET STATISTICS IO OFF;
GO

-- 12. Test with different date formats
SET DATEFORMAT mdy;
INSERT INTO UDDTDateTest (ID, RegularDate, BusinessDateCol, HistoricalDateCol)
VALUES (7, '06/21/2023', '06/21/2023', '07/04/1776');
GO

SET DATEFORMAT dmy;
INSERT INTO UDDTDateTest (ID, RegularDate, BusinessDateCol, HistoricalDateCol)
VALUES (8, '21/06/2023', '21/06/2023', '04/07/1776');
GO

SET DATEFORMAT mdy;
GO

SELECT * FROM UDDTDateTest WHERE ID IN (7, 8);
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing
SELECT 
    CAST('2023-06-15' AS DATE),
    CONVERT(DATE, '2023-06-15'),
    TRY_CAST('2023-06-31' AS DATE),
    TRY_CONVERT(DATE, '2023-06-31'),
    FORMAT(CAST('2023-06-15' AS DATE), 'yyyy-MM-dd');
GO

-- Explicit Conversion
-- binary
SELECT CAST(CAST(0x07E30610 AS binary) AS DATE); -- Positive: 2023-06-16
GO
SELECT CAST(CAST(0x AS binary) AS DATE);
GO
SELECT CAST(CAST(0xFFFFFFFF AS binary) AS DATE); -- Negative: Will raise an error
GO

-- varbinary
SELECT CAST(CAST(0x07E30610 AS VARBINARY) AS DATE); -- Positive: 2023-06-16
GO
SELECT CAST(0x AS DATE); -- Negative: Will raise an error
GO
SELECT CAST(CAST(0xFFFFFFFF AS VARBINARY) AS DATE);
GO

-- char
SELECT CAST(CAST('2023-06-16' AS char) AS DATE); -- Positive
GO
SELECT CAST(CAST('2023-06-16' AS char(5)) AS DATE);
GO
SELECT CAST(CAST('20230616' AS char) AS DATE); -- Positive: YYYYMMDD format
GO
SELECT CAST(CAST('invalid' AS char) AS DATE); -- Negative: Will raise an error
GO
SELECT CAST(CAST(NULL AS char) AS DATE);
GO
SELECT CAST(CAST('' AS char) AS DATE);
GO

-- varchar
SELECT CAST(CAST('9999-12-31' AS varchar) AS DATE); -- Edge: Max date
GO
SELECT CAST(CAST('10000-01-01' AS varchar) AS DATE); -- Negative: Will raise an error
GO
SELECT CAST(CAST('2023-06-16' AS varchar) AS DATE); -- Positive
GO
SELECT CAST(CAST('2023-06-16' AS varchar(5)) AS DATE);
GO
SELECT CAST(CAST('20230616' AS varchar) AS DATE); -- Positive: YYYYMMDD format
GO
SELECT CAST(CAST('invalid' AS varchar) AS DATE); -- Negative: Will raise an error
GO
SELECT CAST(CAST(NULL AS varchar) AS DATE);
GO
SELECT CAST(CAST('' AS varchar) AS DATE);
GO

-- nchar
SELECT CAST(CAST(N'2023-06-16' AS NCHAR) AS DATE); -- Positive
GO
SELECT CAST(CAST(N'2023-06-16' AS NCHAR(5)) AS DATE);
GO
SELECT CAST(CAST(N'0001-01-01' AS NCHAR) AS DATE); -- Edge: Min date
GO
SELECT CAST(CAST(N'0000-12-31' AS NCHAR) AS DATE); -- Negative: Will raise an error
GO
SELECT CAST(CAST(NULL AS nchar) AS DATE);
GO
SELECT CAST(CAST(N'' AS nchar) AS DATE);
GO

-- nvarchar
SELECT CAST(N'2023-06-16' AS DATE); -- Positive
GO
SELECT CAST(N'2023/06/16' AS DATE); -- Positive: Different format
GO
SELECT CAST(N'16/06/2023' AS DATE); -- Negative: Will raise an error (ambiguous format)
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS DATE); -- Positive
GO
SELECT CAST(CAST('9999-12-31' AS DATE) AS DATE); -- Edge: Max date
GO

-- datetime
SELECT CAST(CAST('2023-06-16 12:34:56' AS DATETIME) AS DATE); -- Positive
GO
SELECT CAST(CAST('1753-01-01' AS DATETIME) AS DATE); -- Edge: Min datetime
GO
SELECT CAST(CAST('1752-01-01' AS DATETIME) AS DATE);
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 12:34:56' AS SMALLDATETIME) AS DATE); -- Positive
GO
SELECT CAST(CAST('1900-01-01' AS SMALLDATETIME) AS DATE); -- Edge: Min smalldatetime
GO
SELECT CAST(CAST('1899-01-01' AS SMALLDATETIME) AS DATE);
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) AS DATE); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2) AS DATE); -- Edge: Max datetime2
GO

-- time
SELECT CAST(CAST('12:34:56' AS TIME) AS DATE); -- Negative: Will raise an error
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AS DATE); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS DATE); -- Edge: Max datetimeoffset
GO

-- decimal
SELECT CAST(CAST(20230616 AS DECIMAL(8,0)) AS DATE); -- Positive
GO
SELECT CAST(CAST(99991231 AS DECIMAL(8,0)) AS DATE); -- Edge: Max date
GO
SELECT CAST(CAST(0 AS DECIMAL(8,0)) AS DATE); -- Negative: Will raise an error
GO

-- numeric
SELECT CAST(CAST(20230616 AS NUMERIC(8,0)) AS DATE); -- Positive
GO
SELECT CAST(CAST(00010101 AS NUMERIC(8,0)) AS DATE); -- Edge: Min date
GO
SELECT CAST(CAST(-1 AS NUMERIC(8,0)) AS DATE); -- Negative: Will raise an error
GO

-- float
SELECT CAST(CAST(20230616 AS FLOAT) AS DATE); -- Positive
GO
SELECT CAST(CAST(99991231.99 AS FLOAT) AS DATE); -- Edge: Max date (rounded)
GO
SELECT CAST(CAST(1.23e5 AS FLOAT) AS DATE); -- Negative: Will raise an error
GO

-- real
SELECT CAST(CAST(20230616 AS REAL) AS DATE); -- Positive
GO
SELECT CAST(CAST(99991231.99 AS REAL) AS DATE); -- Edge: Max date (rounded)
GO
SELECT CAST(CAST(-20230616 AS REAL) AS DATE); -- Negative: Will raise an error
GO

-- bigint
SELECT CAST(CAST(20230616 AS BIGINT) AS DATE); -- Positive
GO
SELECT CAST(CAST(99991231 AS BIGINT) AS DATE); -- Edge: Max date
GO
SELECT CAST(CAST(0 AS BIGINT) AS DATE); -- Negative: Will raise an error
GO

-- int
SELECT CAST(20230616 AS DATE); -- Positive
GO
SELECT CAST(00010101 AS DATE); -- Edge: Min date
GO
SELECT CAST(-1 AS DATE); -- Negative: Will raise an error
GO

-- smallint
SELECT CAST(CAST(20230 AS SMALLINT) AS DATE); -- Positive
GO
SELECT CAST(CAST(32767 AS SMALLINT) AS DATE); -- Edge: Max smallint
GO
SELECT CAST(CAST(-1 AS SMALLINT) AS DATE); -- Negative: Will raise an error
GO

-- tinyint
SELECT CAST(CAST(1 AS TINYINT) AS DATE); -- Positive
GO
SELECT CAST(CAST(255 AS TINYINT) AS DATE); -- Edge: Max tinyint
GO
SELECT CAST(CAST(0 AS TINYINT) AS DATE); -- Negative: Will raise an error
GO

-- money
SELECT CAST(CAST(20230616 AS MONEY) AS DATE); -- Positive
GO
SELECT CAST(CAST(99991231.9999 AS MONEY) AS DATE); -- Edge: Max date (rounded)
GO
SELECT CAST(CAST(-1 AS MONEY) AS DATE); -- Negative: Will raise an error
GO

-- smallmoney
SELECT CAST(CAST(20230616 AS SMALLMONEY) AS DATE); -- Positive
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS DATE); -- Edge: Max smallmoney
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS DATE); -- Negative: Will raise an error
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS DATE); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS DATE); -- Negative: Will raise an error
GO

-- text
SELECT CAST(CAST('2023-06-16' AS TEXT) AS DATE); -- Positive
GO
SELECT CAST(CAST('invalid' AS TEXT) AS DATE); -- Negative: Will raise an error
GO

-- ntext
SELECT CAST(CAST(N'2023-06-16' AS NTEXT) AS DATE); -- Positive
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS DATE); -- Negative: Will raise an error
GO

-- xml
SELECT CAST(CAST('<date>2023-06-16</date>' AS XML) AS DATE); -- Positive
GO
SELECT CAST(CAST('<date>invalid</date>' AS XML) AS DATE); -- Negative: Will raise an error
GO

-- sql_variant
SELECT CAST(CAST(CAST('2023-06-16' AS DATE) AS SQL_VARIANT) AS DATE); -- Positive
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS DATE); -- Negative: Will raise an error
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS DATE); -- Negative: Will raise an error
GO

-- Implicit conversion
-- Create a function that takes a DATE parameter
CREATE FUNCTION dbo.TestDateFunction(@DateParam DATE)
RETURNS DATE
AS
BEGIN
    RETURN @DateParam;
END
GO

-- binary
SELECT dbo.TestDateFunction(CAST(0x07E30610 AS binary)); -- Positive: 2023-06-16
GO
SELECT dbo.TestDateFunction(CAST(0x AS binary));
GO
SELECT dbo.TestDateFunction(CAST(0xFFFFFFFF AS binary)); -- Negative: Will raise an error
GO

-- varbinary
SELECT dbo.TestDateFunction(CAST(0x07E30610 AS VARBINARY)); -- Positive: 2023-06-16
GO
SELECT dbo.TestDateFunction(0x); -- Negative: Will raise an error
GO
SELECT dbo.TestDateFunction(CAST(0xFFFFFFFF AS VARBINARY));
GO

-- char
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS char)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS char(5)));
GO
SELECT dbo.TestDateFunction(CAST('20230616' AS char)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestDateFunction(CAST('invalid' AS char)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateFunction(CAST(NULL AS char));
GO
SELECT dbo.TestDateFunction(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestDateFunction(CAST('9999-12-31' AS varchar)); -- Edge: Max date
GO
SELECT dbo.TestDateFunction(CAST('10000-01-01' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS varchar)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS varchar(5)));
GO
SELECT dbo.TestDateFunction(CAST('20230616' AS varchar)); -- Positive: YYYYMMDD format
GO
SELECT dbo.TestDateFunction(CAST('invalid' AS varchar)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateFunction(CAST(NULL AS varchar));
GO
SELECT dbo.TestDateFunction(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestDateFunction(CAST(N'2023-06-16' AS NCHAR)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(N'2023-06-16' AS NCHAR(5)));
GO
SELECT dbo.TestDateFunction(CAST(N'0001-01-01' AS NCHAR)); -- Edge: Min date
GO
SELECT dbo.TestDateFunction(CAST(N'0000-12-31' AS NCHAR)); -- Negative: Will raise an error
GO
SELECT dbo.TestDateFunction(CAST(NULL AS nchar));
GO
SELECT dbo.TestDateFunction(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestDateFunction(N'2023-06-16'); -- Positive
GO
SELECT dbo.TestDateFunction(N'2023/06/16'); -- Positive: Different format
GO
SELECT dbo.TestDateFunction(N'16/06/2023'); -- Negative: Will raise an error (ambiguous format)
GO

-- date
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS DATE)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('9999-12-31' AS DATE)); -- Edge: Max date
GO

-- datetime
SELECT dbo.TestDateFunction(CAST('2023-06-16 12:34:56' AS DATETIME)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('1753-01-01' AS DATETIME)); -- Edge: Min datetime
GO
SELECT dbo.TestDateFunction(CAST('1752-01-01' AS DATETIME));
GO

-- smalldatetime
SELECT dbo.TestDateFunction(CAST('2023-06-16 12:34:56' AS SMALLDATETIME)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('1900-01-01' AS SMALLDATETIME)); -- Edge: Min smalldatetime
GO
SELECT dbo.TestDateFunction(CAST('1899-01-01' AS SMALLDATETIME));
GO

-- datetime2
SELECT dbo.TestDateFunction(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2)); -- Edge: Max datetime2
GO

-- time
SELECT dbo.TestDateFunction(CAST('12:34:56' AS TIME)); -- Negative: Will raise an error
GO

-- datetimeoffset
SELECT dbo.TestDateFunction(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET)); -- Edge: Max datetimeoffset
GO

-- decimal
SELECT dbo.TestDateFunction(CAST(20230616 AS DECIMAL(8,0))); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(99991231 AS DECIMAL(8,0))); -- Edge: Max date
GO
SELECT dbo.TestDateFunction(CAST(0 AS DECIMAL(8,0))); -- Negative: Will raise an error
GO

-- numeric
SELECT dbo.TestDateFunction(CAST(20230616 AS NUMERIC(8,0))); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(00010101 AS NUMERIC(8,0))); -- Edge: Min date
GO
SELECT dbo.TestDateFunction(CAST(-1 AS NUMERIC(8,0))); -- Negative: Will raise an error
GO

-- float
SELECT dbo.TestDateFunction(CAST(20230616 AS FLOAT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(99991231.99 AS FLOAT)); -- Edge: Max date (rounded)
GO
SELECT dbo.TestDateFunction(CAST(1.23e5 AS FLOAT)); -- Negative: Will raise an error
GO

-- real
SELECT dbo.TestDateFunction(CAST(20230616 AS REAL)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(99991231.99 AS REAL)); -- Edge: Max date (rounded)
GO
SELECT dbo.TestDateFunction(CAST(-20230616 AS REAL)); -- Negative: Will raise an error
GO

-- bigint
SELECT dbo.TestDateFunction(CAST(20230616 AS BIGINT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(99991231 AS BIGINT)); -- Edge: Max date
GO
SELECT dbo.TestDateFunction(CAST(0 AS BIGINT)); -- Negative: Will raise an error
GO

-- int
SELECT dbo.TestDateFunction(20230616); -- Positive
GO
SELECT dbo.TestDateFunction(00010101); -- Edge: Min date
GO
SELECT dbo.TestDateFunction(-1); -- Negative: Will raise an error
GO

-- smallint
SELECT dbo.TestDateFunction(CAST(20230 AS SMALLINT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(32767 AS SMALLINT)); -- Edge: Max smallint
GO
SELECT dbo.TestDateFunction(CAST(-1 AS SMALLINT)); -- Negative: Will raise an error
GO

-- tinyint
SELECT dbo.TestDateFunction(CAST(1 AS TINYINT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(255 AS TINYINT)); -- Edge: Max tinyint
GO
SELECT dbo.TestDateFunction(CAST(0 AS TINYINT)); -- Negative: Will raise an error
GO

-- money
SELECT dbo.TestDateFunction(CAST(20230616 AS MONEY)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(99991231.9999 AS MONEY)); -- Edge: Max date (rounded)
GO
SELECT dbo.TestDateFunction(CAST(-1 AS MONEY)); -- Negative: Will raise an error
GO

-- smallmoney
SELECT dbo.TestDateFunction(CAST(20230616 AS SMALLMONEY)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(214748.3647 AS SMALLMONEY)); -- Edge: Max smallmoney
GO
SELECT dbo.TestDateFunction(CAST(-1 AS SMALLMONEY)); -- Negative: Will raise an error
GO

-- bit
SELECT dbo.TestDateFunction(CAST(1 AS BIT)); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT dbo.TestDateFunction(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER)); -- Negative: Will raise an error
GO

-- text
SELECT dbo.TestDateFunction(CAST('2023-06-16' AS TEXT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('invalid' AS TEXT)); -- Negative: Will raise an error
GO

-- ntext
SELECT dbo.TestDateFunction(CAST(N'2023-06-16' AS NTEXT)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST(N'invalid' AS NTEXT)); -- Negative: Will raise an error
GO

-- xml
SELECT dbo.TestDateFunction(CAST('<date>2023-06-16</date>' AS XML)); -- Positive
GO
SELECT dbo.TestDateFunction(CAST('<date>invalid</date>' AS XML)); -- Negative: Will raise an error
GO

-- sql_variant
SELECT dbo.TestDateFunction(CAST(CAST('2023-06-16' AS DATE) AS SQL_VARIANT)); -- Positive
GO

-- geometry
SELECT dbo.TestDateFunction(geometry::STGeomFromText('POINT(1 1)', 0)); -- Negative: Will raise an error
GO

-- geography
SELECT dbo.TestDateFunction(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326)); -- Negative: Will raise an error
GO

-- Create a table to store test results
CREATE TABLE DateImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue DATE NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertTestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue DATE = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO DateImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @DateValue DATE = '2023-06-16';
DECLARE @StringDate NVARCHAR(10) = '2023-06-17';
DECLARE @DateTimeValue DATETIME = '2023-06-20 12:34:56';

-- 1. UNION
BEGIN TRY
    DECLARE @Result DATE;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateValue AS Result
        UNION
        SELECT @StringDate
        UNION
        SELECT @DateTimeValue
    ) AS UnionResult;
    EXEC InsertTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple types', NULL, 0;
END CATCH;

-- 2. UNION ALL
BEGIN TRY
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateValue AS Result
        UNION ALL
        SELECT @StringDate
        UNION ALL
        SELECT @DateTimeValue
    ) AS UnionAllResult;
    EXEC InsertTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple types', NULL, 0;
END CATCH;

-- 3. CASE Expression
BEGIN TRY
    SET @Result = CASE 
        WHEN 1=0 THEN @DateValue
        WHEN 1=0 THEN @StringDate
        ELSE @DateTimeValue
    END;
    EXEC InsertTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple types', NULL, 0;
END CATCH;

-- 4. COALESCE
BEGIN TRY
    SET @Result = COALESCE(NULL, @DateValue, @StringDate, @DateTimeValue);
    EXEC InsertTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple types', NULL, 0;
END CATCH;

-- 5. INTERSECT
BEGIN TRY
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateValue AS Result
        INTERSECT
        SELECT @StringDate
    ) AS IntersectResult;
    EXEC InsertTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATE and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATE and String', NULL, 0;
END CATCH;

-- 6. EXCEPT
BEGIN TRY
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateValue AS Result
        EXCEPT
        SELECT @StringDate
    ) AS ExceptResult;
    EXEC InsertTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATE and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATE and String', NULL, 0;
END CATCH;

-- 7. VALUES
BEGIN TRY
    SELECT TOP 1 @Result = Result
    FROM (VALUES (@DateValue), (@StringDate), (@DateTimeValue)) AS ValuesResult(Result);
    EXEC InsertTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple types', NULL, 0;
END CATCH;

-- 8. ISNULL
BEGIN TRY
    SET @Result = ISNULL(NULL, @StringDate);
    EXEC InsertTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;

-- Display results
SELECT * FROM DateImplicitConversionTest ORDER BY ID;
GO

DECLARE @Styles TABLE (StyleID INT);
INSERT INTO @Styles (StyleID)
VALUES (0), (1), (2), (3), (4), (5), (6), (7), (10), (11), (12), (20), (21), (22), (23), (25),
       (100), (101), (102), (103), (104), (105), (106), (107), (110), (111), (112), (120), (121),
       (126), (127), (130), (131);

DECLARE @Style INT;
DECLARE @SQL NVARCHAR(MAX);

-- binary
DECLARE style_cursor CURSOR FOR SELECT StyleID FROM @Styles;
OPEN style_cursor;
FETCH NEXT FROM style_cursor INTO @Style;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT CONVERT(DATE, 0x07E30610, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, ''2023-06-16'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, ''2023-06-16'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, N''2023-06-16'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, N''2023-06-16'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16 12:34:56'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16 12:34:00'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16 12:34:56.1234567'' AS DATETIME2), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16 12:34:56.1234567 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS DECIMAL(8,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS NUMERIC(8,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, 20230616, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(16 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230616 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(20230 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(''2023-06-16'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(N''2023-06-16'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATE, CAST(CAST(''2023-06-16'' AS DATE) AS SQL_VARIANT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(0x07E30610 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(0x07E30610 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS char(10)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS varchar(10)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS nchar(10)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS nvarchar(10)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16 12:34:56' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('12:34:56' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS decimal(8,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS numeric(8,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(16 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230616 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(20230 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(0x07E30610 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('2023-06-16' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) = CAST('<date>2023-06-16</date>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) = CAST('2023-06-16' AS DATE) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(0x07E30610 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(0x07E30610 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS char(10)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS varchar(10)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS nchar(10)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS nvarchar(10)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('12:34:56' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS decimal(8,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS numeric(8,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(16 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230616 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(20230 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(0x07E30610 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('2023-06-16' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <> CAST('<date>2023-06-16</date>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) <> CAST('2023-06-16' AS DATE) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(0x07E30610 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS char(10)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS varchar(10)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS nchar(10)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS nvarchar(10)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('12:34:56' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS decimal(8,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS numeric(8,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(16 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230616 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(20230 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(0x07E30610 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('2023-06-16' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) < CAST('<date>2023-06-16</date>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) < CAST('2023-06-16' AS DATE) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(0x07E30610 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(0x07E30610 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS char(10)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS varchar(10)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS nchar(10)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS nvarchar(10)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('12:34:56' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS decimal(8,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS numeric(8,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(16 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230616 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(20230 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(0x07E30610 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('2023-06-16' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) <= CAST('<date>2023-06-16</date>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) <= CAST('2023-06-16' AS DATE) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(0x07E30610 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(0x07E30610 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS char(10)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS varchar(10)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS nchar(10)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS nvarchar(10)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('12:34:56' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS decimal(8,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS numeric(8,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(16 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230616 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(20230 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(0x07E30610 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('2023-06-16' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) > CAST('<date>2023-06-16</date>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) > CAST('2023-06-16' AS DATE) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with DATE on left side
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(0x07E30610 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(0x07E30610 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS char(10)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS varchar(10)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS nchar(10)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS nvarchar(10)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('12:34:56' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS decimal(8,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS numeric(8,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(16 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230616 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(20230 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(0x07E30610 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('2023-06-16' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST(CAST('2023-06-16' AS date) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS DATE) >= CAST('<date>2023-06-16</date>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with DATE on right side
SELECT CASE WHEN CAST(0x07E30610 AS binary(8)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS varbinary(8)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS char(10)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS varchar(10)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nchar(10)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS nvarchar(10)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(16 AS tinyint) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x07E30610 AS image) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS text) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS ntext) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16' AS date) AS sql_variant) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('<date>2023-06-16</date>' AS xml) >= CAST('2023-06-16' AS DATE) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator
SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) BETWEEN CAST('2023-06-15' AS DATE) AND CAST('2023-06-17' AS DATE) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) BETWEEN CAST('2023-06-15 12:34:56' AS DATETIME) AND CAST('2023-06-17 12:34:56' AS DATETIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) BETWEEN CAST('2023-06-15 12:34:56.1234567' AS DATETIME2) AND CAST('2023-06-17 12:34:56.1234567' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) BETWEEN CAST('2023-06-15 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AND CAST('2023-06-17 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator
SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) IN (CAST('2023-06-15' AS DATE), CAST('2023-06-16' AS DATE), CAST('2023-06-17' AS DATE)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) IN (CAST('2023-06-15 12:34:56' AS DATETIME), CAST('2023-06-16 12:34:56' AS DATETIME), CAST('2023-06-17 12:34:56' AS DATETIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) IN (CAST('2023-06-15 12:34:56.1234567' AS DATETIME2), CAST('2023-06-16 12:34:56.1234567' AS DATETIME2), CAST('2023-06-17 12:34:56.1234567' AS DATETIME2)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL
DECLARE @NullDate DATE;
SELECT CASE 
    WHEN @NullDate IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

DECLARE @NullDate DATE;
SELECT CASE 
    WHEN @NullDate IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16' AS DATE) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Arithmetic operators
-- Addition with DATE on left side
SELECT CAST('2023-06-16' AS DATE) + CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS INT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('<number>1</number>' AS XML);
GO

-- Addition with DATE on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS CHAR(10)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS VARCHAR(10)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NCHAR(10)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NVARCHAR(10)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:00' AS SMALLDATETIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS DECIMAL(8,0)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS NUMERIC(8,0)) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS FLOAT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS REAL) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS BIGINT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS INT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS SMALLINT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS TINYINT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS MONEY) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS SMALLMONEY) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS BIT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(0x07E30610 AS IMAGE) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS TEXT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NTEXT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('<number>1</number>' AS XML) + CAST('2023-06-16' AS DATE);
GO

-- Subtraction with DATE on left side
SELECT CAST('2023-06-16' AS DATE) - CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-15' AS DATE);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-15 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-15 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-15 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-15 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS INT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with DATE on right side
SELECT CAST(0x07E30610 AS BINARY(8)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-17' AS DATE) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-17 12:34:56' AS DATETIME) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-17 12:34:00' AS SMALLDATETIME) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-17 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-17 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS FLOAT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS REAL) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS BIGINT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS INT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS SMALLINT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS TINYINT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS MONEY) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(1 AS BIT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(0x07E30610 AS IMAGE) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS TEXT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('1' AS NTEXT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('2023-06-16' AS DATE);
GO

-- 4. DDL testing:

-- 1. Table column
CREATE TABLE DateTest1 (
    ID INT PRIMARY KEY,
    DateColumn DATE,
    DefaultDateColumn DATE DEFAULT GETDATE(),
    ComputedDateColumn AS DATEADD(day, 1, DateColumn),
    CHECK (DateColumn > '2000-01-01')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTest1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table
-- partitioned table testing on date
CREATE PARTITION FUNCTION DATE_dt_partition_func (DATE) 
    AS RANGE RIGHT FOR VALUES(
        CAST('2022-01-01' AS date), 
        CAST('2023-01-01' AS date), 
        CAST('2024-01-01' AS date)
    );
GO

CREATE PARTITION SCHEME DATE_dt_partition_scheme
    AS PARTITION DATE_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE DATE_dt_partition(
    a DATE,
    type VARCHAR(10))
ON DATE_dt_partition_scheme(a);
GO

INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-06-15' AS date), 'PDF');
GO
INSERT INTO DATE_dt_partition (a, type) VALUES  (CAST('2021-12-31' AS date), 'PDF');
GO

INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-06-15' AS date), 'GIF');
GO
INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-12-31' AS date), 'GIF');
GO

INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-06-15' AS date), 'JPEG');
GO
INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-12-31' AS date), 'JPEG');
GO

INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-06-15' AS date), 'PNG');
GO
INSERT INTO DATE_dt_partition (a, type) VALUES (CAST('2021-12-31' AS date), 'PNG');
GO

-- Query to show files in each partition
SELECT a, type, $PARTITION.DATE_dt_partition_func(a) AS PartitionNumber
    FROM DATE_dt_partition ORDER BY PartitionNumber, type, a;
GO

-- Query to show count of files by partition
SELECT $PARTITION.DATE_dt_partition_func(a) AS PartitionNumber, type, COUNT(*) AS FileCount
    FROM DATE_dt_partition
    GROUP BY $PARTITION.DATE_dt_partition_func(a), type
    ORDER BY PartitionNumber, type;
GO

-- 3. Function returning Date types
CREATE FUNCTION dbo.GetCurrentDate()
RETURNS DATE
AS
BEGIN
    RETURN CAST('2023-06-17' AS DATE);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentDate' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes Date types input
-- Create function
CREATE FUNCTION dbo.AddDaysToDate(
    @InputDate DATE,
    @DaysToAdd INT
)
RETURNS DATE
AS
BEGIN
    RETURN DATEADD(DAY, @DaysToAdd, @InputDate);
END;
GO

SELECT  
    p.proname AS function_name,
    unnest(p.proargnames) AS parameter_name,
    pg_catalog.format_type(unnest(p.proargtypes), NULL) AS data_type
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'dbo' 
    AND p.proname = 'adddaystodate';
GO

-- Test the function
SELECT dbo.AddDaysToDate('2023-06-16', 5) AS Result;  -- Should return 2023-06-21
GO
SELECT dbo.AddDaysToDate('2023-06-16', -5) AS Result; -- Should return 2023-06-11
GO
SELECT dbo.AddDaysToDate('2023-06-16', 0) AS Result;  -- Should return 2023-06-16
GO

-- 5. Procedure takes Date types input
CREATE PROCEDURE dbo.ProcessDate
    @InputDate DATE
AS
BEGIN
    SELECT DATEADD(DAY, 1, @InputDate) AS NextDay;
END;
GO

-- Verify procedure parameter type
SELECT  
    p.proname AS function_name,
    unnest(p.proargnames) AS parameter_name,
    pg_catalog.format_type(unnest(p.proargtypes), NULL) AS data_type
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'dbo' 
    AND p.proname = 'ProcessDate';
GO

-- 6. Constraints (already added in step 1, but let's add more)
ALTER TABLE DateTest1
ADD CONSTRAINT DF_DateTest_DefaultDateColumn DEFAULT '2000-01-01' FOR DefaultDateColumn;

ALTER TABLE DateTest1
ADD CONSTRAINT CK_DateTest_DateColumn CHECK (DateColumn > '2000-01-01');

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'DateTest1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key columns (already added in step 1, but let's verify)
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'DateTest1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views
CREATE VIEW dbo.DateView
AS
SELECT
    ID,
    DateColumn,
    DefaultDateColumn,
    ComputedDateColumn
FROM DateTest1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateView' ORDER BY COLUMN_NAME;
GO

-- Insert some test data
INSERT INTO DateTest1 (ID, DateColumn) VALUES 
(1, '2023-06-16'),
(2, '2023-06-17'),
(3, '2023-06-18');

-- Test the objects we created
SELECT * FROM DateTest1 ORDER BY ID;
SELECT * FROM DATE_dt_partition ORDER BY a, type;
SELECT dbo.GetCurrentDate() AS CurrentDate;
SELECT dbo.AddDaysToDate('2023-06-16', 5) AS DateAfter5Days;
EXEC dbo.ProcessDate @InputDate = '2023-06-16';
SELECT * FROM dbo.DateView ORDER BY ID;
GO

-- 5. DML testing:
-- Create test tables
CREATE TABLE DateDMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleDate DATE,
    DefaultDate DATE DEFAULT NULL,
    ComputedDate AS DATEADD(day, 1, SimpleDate),
    Description NVARCHAR(100)
);
GO

CREATE TABLE DateDMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildDate DATE,
    FOREIGN KEY (ParentID) REFERENCES DateDMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion
INSERT INTO DateDMLTest (SimpleDate, Description) 
VALUES ('2023-06-16', 'Single row insertion');
GO

-- Bulk insertion
INSERT INTO DateDMLTest (SimpleDate, Description)
VALUES 
('2023-06-17', 'Bulk insertion 1'),
('2023-06-18', 'Bulk insertion 2'),
('2023-06-19', 'Bulk insertion 3');
GO

-- Insert with type casting
INSERT INTO DateDMLTest (SimpleDate, Description)
VALUES (CAST('20230620' AS DATE), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO DateDMLTest (SimpleDate, Description)
VALUES (DATEADD(day, 5, '2023-06-16'), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO DateDMLTest (SimpleDate, DefaultDate, Description)
VALUES ('2023-06-22', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM DateDMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE DateDMLTest
SET SimpleDate = '2023-07-01'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE DateDMLTest
SET SimpleDate = '2023-07-02',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE DateDMLTest
SET SimpleDate = DATEADD(month, 1, SimpleDate)
WHERE ID = 3;
GO

-- Mass update
UPDATE DateDMLTest
SET Description = 'Mass updated';
GO

-- Conditional update
UPDATE DateDMLTest
SET SimpleDate = '2023-08-01'
WHERE SimpleDate < '2023-07-01';
GO

-- Verify updates
SELECT * FROM DateDMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO DateDMLTestChild (ParentID, ChildDate)
VALUES 
(1, '2023-06-16'),
(2, '2023-06-17'),
(3, '2023-06-18'),
(4, '2023-06-19'),
(5, '2023-06-20');
GO

-- Single row deletion
DELETE FROM DateDMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM DateDMLTest;
GO

-- Conditional deletion
DELETE FROM DateDMLTest WHERE SimpleDate < '2023-07-01';
GO

-- Cascade deletion (will delete from child table as well)
DELETE FROM DateDMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM DateDMLTest ORDER BY ID;
SELECT * FROM DateDMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO DateDMLTest (SimpleDate, Description)
VALUES ('2023-09-01', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleDate, ComputedDate, Description
FROM DateDMLTest
WHERE SimpleDate = '2023-09-01';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE DateDMLTest
    SET ComputedDate = '2023-09-03'
    WHERE SimpleDate = '2023-09-01';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE DateDMLTest
SET SimpleDate = '2023-09-02'
WHERE SimpleDate = '2023-09-01';
GO

SELECT ID, SimpleDate, ComputedDate, Description
FROM DateDMLTest
WHERE SimpleDate = '2023-09-02';
GO

-- 5. Additional DML scenarios

-- Insert with subquery
INSERT INTO DateDMLTest (SimpleDate, Description)
SELECT DATEADD(year, 1, MAX(SimpleDate)), 'Inserted from subquery'
FROM DateDMLTest;
GO

-- Update with JOIN
UPDATE d
SET d.SimpleDate = DATEADD(day, 1, c.ChildDate)
FROM DateDMLTest d
JOIN DateDMLTestChild c ON d.ID = c.ParentID;
GO

-- Delete with subquery
DELETE FROM DateDMLTest
WHERE SimpleDate IN (
    SELECT ChildDate
    FROM DateDMLTestChild
);
GO

-- Insert data that violates constraint (this will fail)
BEGIN TRY
    INSERT INTO DateDMLTest (SimpleDate, Description)
    VALUES ('1900-01-01', 'This should fail');
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Final verification
SELECT * FROM DateDMLTest ORDER BY ID;
SELECT * FROM DateDMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table
CREATE TABLE DateIndexTest (
    ID INT IDENTITY PRIMARY KEY,
    DateColumn DATE,
    DateColumn2 DATE,
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data
INSERT INTO DateIndexTest (DateColumn, DateColumn2, Description, NumericColumn)
VALUES 
('2023-01-01', '2023-06-01', 'First half', 1),
('2023-02-15', '2023-07-15', 'Mid year', 2),
('2023-03-30', '2023-08-30', 'Third quarter', 3),
('2023-04-10', '2023-09-10', 'Fall season', 4),
('2023-05-20', '2023-10-20', 'Year end', 5);
GO

-- 1. Index on single column
CREATE INDEX IX_DateIndexTest_DateColumn ON DateIndexTest(DateColumn);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple columns
CREATE INDEX IX_DateIndexTest_DateColumn_DateColumn2 ON DateIndexTest(DateColumn, DateColumn2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = '2023-01-01' AND DateColumn2 = '2023-06-01';
SET STATISTICS IO OFF;
GO

-- 3. Usability of index with different operators in predicate

-- Equality
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- Range
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn BETWEEN '2023-01-01' AND '2023-03-31' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- LIKE (Note: LIKE is not typically used with DATE, but included for completeness)
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE CONVERT(VARCHAR(10), DateColumn, 120) LIKE '2023-01%';
SET STATISTICS IO OFF;
GO

-- IN
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn IN ('2023-01-01', '2023-02-15', '2023-03-30')  ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Comparing different data types with implicit conversions

-- DATE to VARCHAR
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = '20230101';
SET STATISTICS IO OFF;
GO

-- DATE to DATETIME
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = CAST('2023-01-01 12:00:00' AS DATETIME);
SET STATISTICS IO OFF;
GO

-- DATE to INT (days since 1900-01-01)
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = DATEADD(DAY, 45000, '1900-01-01');
SET STATISTICS IO OFF;
GO

-- 5. DML operations with indexes

-- INSERT
SET STATISTICS IO ON;
INSERT INTO DateIndexTest (DateColumn, DateColumn2, Description, NumericColumn)
VALUES ('2023-06-30', '2023-12-31', 'Year end', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE
SET STATISTICS IO ON;
UPDATE DateIndexTest SET DateColumn = '2023-07-01' WHERE DateColumn = '2023-06-30';
SET STATISTICS IO OFF;
GO

-- DELETE
SET STATISTICS IO ON;
DELETE FROM DateIndexTest WHERE DateColumn = '2023-07-01';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Create a filtered index
CREATE INDEX IX_DateIndexTest_Filtered ON DateIndexTest(DateColumn)
WHERE DateColumn >= '2023-01-01' AND DateColumn < '2024-01-01';
GO

-- Test filtered index
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = '2023-02-15';
SET STATISTICS IO OFF;
GO

-- Create an index with included columns
CREATE INDEX IX_DateIndexTest_DateColumn_Include ON DateIndexTest(DateColumn)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT DateColumn, Description, NumericColumn 
FROM DateIndexTest 
WHERE DateColumn = '2023-03-30';
SET STATISTICS IO OFF;
GO

-- 7. Index usage for date functions

-- YEAR function
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE YEAR(DateColumn) = 2023 ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- DATEADD function
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WHERE DateColumn = DATEADD(DAY, -1, '2023-01-02');
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WITH (INDEX(IX_DateIndexTest_DateColumn))
WHERE DateColumn = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM DateIndexTest WITH (INDEX(0))
WHERE DateColumn = '2023-01-01';
SET STATISTICS IO OFF;
GO

-- 9. Check index usage
-- Get index usage statistics in PostgreSQL
SELECT
    schemaname,
    relname as tablename,
    indexrelname as indexname,
    pg_size_pretty(pg_relation_size(schemaname || '.' || indexrelname::text)) as index_size
FROM pg_stat_all_indexes
WHERE relname = 'dateindextest'
AND schemaname = 'dbo';
GO

-- 7. Expression Testing:
-- Create test table
CREATE TABLE DateExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    DateColumn DATE,
    NullableDateColumn DATE NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO DateExpressionTest (DateColumn, NullableDateColumn, Description)
VALUES 
('2023-01-01', '2023-01-01', 'New Year'),
('2023-02-14', '2023-02-14', 'Valentine''s Day'),
('2023-03-17', NULL, 'St. Patrick''s Day'),
('2023-04-01', '2023-04-01', 'April Fool''s Day'),
('2023-05-01', NULL, 'May Day'),
('2023-06-21', '2023-06-21', 'Summer Solstice'),
('2023-07-04', '2023-07-04', 'Independence Day'),
('2023-08-15', NULL, 'August Holiday'),
('2023-09-22', '2023-09-22', 'Autumn Equinox'),
('2023-10-31', '2023-10-31', 'Halloween'),
('2023-11-23', NULL, 'Thanksgiving'),
('2023-12-25', '2023-12-25', 'Christmas');
GO

-- 1. Conditional Expressions

-- CASE statements
SELECT 
    DateColumn,
    CASE 
        WHEN DateColumn BETWEEN '2023-03-01' AND '2023-05-31' THEN 'Spring'
        WHEN DateColumn BETWEEN '2023-06-01' AND '2023-08-31' THEN 'Summer'
        WHEN DateColumn BETWEEN '2023-09-01' AND '2023-11-30' THEN 'Autumn'
        ELSE 'Winter'
    END AS Season,
    Description
FROM DateExpressionTest ORDER BY Description;
GO

-- COALESCE
SELECT 
    ID,
    COALESCE(NullableDateColumn, DateColumn, CAST('1900-01-01' AS DATE)) AS CoalescedDate,
    Description
FROM DateExpressionTest ORDER BY Description;
GO

-- NULLIF operations
SELECT 
    ID,
    NULLIF(DateColumn, '2023-01-01') AS NullIfNewYear,
    Description
FROM DateExpressionTest ORDER BY Description;
GO

-- IIF statements
SELECT 
    DateColumn,
    IIF(DATEPART(QUARTER, DateColumn) <= 2, 'First Half', 'Second Half') AS HalfOfYear,
    Description
FROM DateExpressionTest ORDER BY Description;
GO

-- 2. Aggregate Expressions

-- MAX
SELECT MAX(DateColumn) AS LatestDate FROM DateExpressionTest;
GO

-- MIN
SELECT MIN(DateColumn) AS EarliestDate FROM DateExpressionTest;
GO

-- UNIONS
SELECT DateColumn FROM DateExpressionTest WHERE MONTH(DateColumn) = 1
UNION
SELECT DateColumn FROM DateExpressionTest WHERE MONTH(DateColumn) = 12
ORDER BY DateColumn;
GO

-- COUNT
SELECT COUNT(DateColumn) AS TotalDates, COUNT(DISTINCT DateColumn) AS UniqueDates FROM DateExpressionTest;
GO

-- AVG (Note: AVG doesn't work directly with DATE, so we'll convert to a number first)
SELECT AVG(DATEDIFF(DAY, '1900-01-01', DateColumn)) AS AverageDaysSince1900 FROM DateExpressionTest;
GO

-- 3. Additional Expression Tests

-- Date arithmetic
SELECT 
    DateColumn,
    DATEADD(DAY, 7, DateColumn) AS OneWeekLater,
    DATEADD(MONTH, 1, DateColumn) AS OneMonthLater,
    DATEADD(YEAR, 1, DateColumn) AS OneYearLater
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Date parts
SELECT 
    DateColumn,
    YEAR(DateColumn) AS Year,
    MONTH(DateColumn) AS Month,
    DAY(DateColumn) AS Day,
    DATEPART(QUARTER, DateColumn) AS Quarter,
    DATEPART(DAYOFYEAR, DateColumn) AS DayOfYear,
    DATENAME(WEEKDAY, DateColumn) AS DayOfWeek
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Date differences
SELECT 
    DateColumn,
    DATEDIFF(DAY, '2023-01-01', DateColumn) AS DaysSinceNewYear,
    DATEDIFF(WEEK, '2023-01-01', DateColumn) AS WeeksSinceNewYear,
    DATEDIFF(MONTH, '2023-01-01', DateColumn) AS MonthsSinceNewYear
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Complex conditional expressions
SELECT 
    DateColumn,
    CASE 
        WHEN DATEPART(MONTH, DateColumn) IN (3, 4, 5) THEN 'Spring'
        WHEN DATEPART(MONTH, DateColumn) IN (6, 7, 8) THEN 'Summer'
        WHEN DATEPART(MONTH, DateColumn) IN (9, 10, 11) THEN 'Autumn'
        ELSE 'Winter'
    END AS Season,
    CASE 
        WHEN DATEPART(WEEKDAY, DateColumn) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    IIF(DateColumn < '2023-07-01', 'First Half', 'Second Half') AS YearHalf
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Combining multiple date functions
SELECT 
    DateColumn,
    EOMONTH(DateColumn) AS EndOfMonth,
    DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, DateColumn))) AS FirstDayOfMonth,
    DATEADD(DAY, -DATEPART(DAY, DateColumn) + 1, DateColumn) AS FirstDayOfCurrentMonth
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Window functions with dates
SELECT 
    DateColumn,
    Description,
    LAG(DateColumn) OVER (ORDER BY DateColumn) AS PreviousDate,
    LEAD(DateColumn) OVER (ORDER BY DateColumn) AS NextDate,
    DATEDIFF(DAY, LAG(DateColumn) OVER (ORDER BY DateColumn), DateColumn) AS DaysSincePreviousDate
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- Date grouping and aggregation
SELECT 
    YEAR(DateColumn) AS Year,
    DATEPART(QUARTER, DateColumn) AS Quarter,
    COUNT(*) AS DateCount,
    MIN(DateColumn) AS EarliestDate,
    MAX(DateColumn) AS LatestDate
FROM DateExpressionTest
GROUP BY YEAR(DateColumn), DATEPART(QUARTER, DateColumn)
ORDER BY Year, Quarter;
GO

-- Complex CASE with date ranges
SELECT 
    DateColumn,
    CASE 
        WHEN DateColumn BETWEEN '2023-01-01' AND '2023-03-31' THEN 'Q1'
        WHEN DateColumn BETWEEN '2023-04-01' AND '2023-06-30' THEN 'Q2'
        WHEN DateColumn BETWEEN '2023-07-01' AND '2023-09-30' THEN 'Q3'
        WHEN DateColumn BETWEEN '2023-10-01' AND '2023-12-31' THEN 'Q4'
        ELSE 'Unknown'
    END AS Quarter,
    Description
FROM DateExpressionTest ORDER BY DateColumn;
GO

-- 8. Additional DATE Specific Tests:

-- Test arithmetic operations
DECLARE @d DATE = '2023-06-15';
SELECT 
    DATEADD(YEAR, 1, @d),
    DATEADD(MONTH, 1, @d),
    DATEADD(DAY, 1, @d);
GO

-- Test DATEDIFF with different parts
DECLARE @d1 DATE = '2023-06-15';
DECLARE @d2 DATE = '2024-07-16';
SELECT 
    DATEDIFF(YEAR, @d1, @d2),
    DATEDIFF(MONTH, @d1, @d2),
    DATEDIFF(DAY, @d1, @d2);
GO

-- Test DATETRUNC function
DECLARE @d DATE = '2023-06-15';
SELECT 
    DATETRUNC(YEAR, @d),
    DATETRUNC(MONTH, @d);
GO

-- Test EOMONTH function
DECLARE @d DATE = '2023-06-15';
SELECT EOMONTH(@d), EOMONTH(@d, 1), EOMONTH(@d, -1);
GO

-- Test conversion to and from other date/time types
DECLARE @d DATE = '2023-06-15';
SELECT 
    CAST(@d AS DATETIME),
    CAST(@d AS DATETIME2),
    CAST(@d AS DATETIMEOFFSET);
GO

-- Test with different date formats
SET LANGUAGE us_english;
SELECT CAST('06/15/2023' AS DATE);
SET LANGUAGE British;
SELECT CAST('15/06/2023' AS DATE);
GO

-- Test with different language settings
SET LANGUAGE German;
SELECT DATENAME(MONTH, CAST('2023-06-15' AS DATE));
SET LANGUAGE French;
SELECT DATENAME(MONTH, CAST('2023-06-15' AS DATE));
GO
SET LANGUAGE us_english;
GO

-- Test with different DATEFIRST settings
SET DATEFIRST 1;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15' AS DATE));
SET DATEFIRST 7;
SELECT DATEPART(WEEKDAY, CAST('2023-06-15' AS DATE));
GO

-- 9. Error Handling:

-- Test out-of-range values
BEGIN TRY
    DECLARE @d DATE = '10000-01-01';
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

-- Test invalid string formats
BEGIN TRY
    SELECT CAST('2023-13-45' AS DATE);
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

-- Test invalid date values
BEGIN TRY
    SELECT CAST('2023-02-30' AS DATE);
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

-- 10. Additional Tests:

-- Test DATE_BUCKET function

DECLARE @d DATE = '2023-06-15';
SELECT DATE_BUCKET(WEEK, 1, @d), DATE_BUCKET(MONTH, 1, @d), DATE_BUCKET(YEAR, 1, @d);
GO

-- Test with different century dates
SELECT CAST('1899-12-31' AS DATE), CAST('1900-01-01' AS DATE), CAST('2000-01-01' AS DATE);
GO

-- Test leap year handling
SELECT 
    ISDATE('2023-02-29') AS [2023 (non-leap year)],
    ISDATE('2024-02-29') AS [2024 (leap year)];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(DATE, '06/15/2023', 101),  -- mm/dd/yyyy
    CONVERT(DATE, '15.06.2023', 104),  -- dd.mm.yyyy
    CONVERT(DATE, '15 Jun 2023', 106), -- dd mon yyyy
    CONVERT(DATE, '2023-06-15', 120);  -- yyyy-mm-dd
GO

-- Test with DATEFORMAT setting
SET DATEFORMAT mdy;
SELECT CAST('06/15/2023' AS DATE);
SET DATEFORMAT dmy;
SELECT CAST('15/06/2023' AS DATE);
GO

-- Test with different centuries
SELECT 
    CAST('06/15/23' AS DATE) AS [Interpreted as 2023],
    CAST('06/15/1923' AS DATE) AS [Explicitly 1923];
GO

-- Test with two-digit years and DATEFORMAT
SET DATEFORMAT ymd;
SELECT CAST('23/06/15' AS DATE);
GO

SET DATEFORMAT mdy;
GO

-- Test date arithmetic
DECLARE @d DATE = '2023-06-15';
SELECT 
    DATEADD(DAY, 1, @d) AS [Next day],
    DATEADD(DAY, -1, @d) AS [Previous day],
    DATEADD(MONTH, 1, @d) AS [Next month],
    DATEADD(YEAR, 1, @d) AS [Next year];
GO

-- Test date extraction
DECLARE @d DATE = '2023-06-15';
SELECT 
    YEAR(@d) AS [Year],
    MONTH(@d) AS [Month],
    DAY(@d) AS [Day],
    DATEPART(QUARTER, @d) AS [Quarter],
    DATEPART(DAYOFYEAR, @d) AS [Day of Year],
    DATEPART(WEEK, @d) AS [Week of Year],
    DATEPART(WEEKDAY, @d) AS [Day of Week];
GO

-- Test with SET LANGUAGE
SET LANGUAGE Italian;
SELECT DATENAME(MONTH, CAST('2023-06-15' AS DATE)) AS [Italian Month Name];
SET LANGUAGE English;
SELECT DATENAME(MONTH, CAST('2023-06-15' AS DATE)) AS [English Month Name];
GO

-- Test with different first day of week
SET DATEFIRST 1;  -- Monday
SELECT DATEPART(WEEKDAY, CAST('2023-06-15' AS DATE)) AS [Weekday (Monday first)];
SET DATEFIRST 7;  -- Sunday
SELECT DATEPART(WEEKDAY, CAST('2023-06-15' AS DATE)) AS [Weekday (Sunday first)];
GO

-- Test date range
SELECT 
    CAST('0001-01-01' AS DATE) AS [Minimum DATE],
    CAST('9999-12-31' AS DATE) AS [Maximum DATE];
GO

-- Test with time zone conversion (note: DATE doesn't store time zone information)
DECLARE @d DATE = '2023-06-15';
SELECT 
    @d AS [Original Date],
    CAST(CAST(@d AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS DATE) AS [Pacific Date];
GO

-- Clean up: Drop all created objects
DROP TABLE DateTest;
DROP TABLE DateDefaultTest;
DROP FUNCTION dbo.GetCurrentDate;
DROP TYPE MyDate;
DROP TABLE DateFormatTest;
DROP PROCEDURE InsertDateTest;
DROP PROCEDURE InsertDateTest1;
DROP PROCEDURE TestDateFormat;
DROP TABLE DateConversionTest;
DROP PROCEDURE InsertDateConversionTest;
DROP TABLE DateTimeZoneTest;
DROP PROCEDURE InsertDateTimeZoneTest;
DROP TABLE UDDTDateTest;
DROP PROCEDURE TestUDDTDateProc;
DROP TYPE BusinessDate;
DROP TYPE HistoricalDate;
DROP FUNCTION dbo.TestDateFunction;
DROP TABLE DateImplicitConversionTest;
DROP PROCEDURE InsertTestResult;
DROP FUNCTION dbo.AddDaysToDate;
DROP PROCEDURE dbo.ProcessDate;
DROP VIEW dbo.DateView;
DROP TABLE DateDMLTestChild;
DROP TABLE DateDMLTest;
DROP TABLE DateIndexTest;
DROP TABLE DateExpressionTest;
DROP TABLE DateTest1;
DROP TABLE DATE_dt_partition;
DROP PARTITION SCHEME DATE_dt_partition_scheme;
DROP PARTITION FUNCTION DATE_dt_partition_func;
GO
