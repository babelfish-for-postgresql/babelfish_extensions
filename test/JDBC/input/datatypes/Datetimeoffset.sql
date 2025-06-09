-- sla 200000
-- 1. Basic Testing:
-- Create TimeTest table with different scale precisions
CREATE TABLE DatetimeoffsetTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    DateTimeOffset0 DATETIMEOFFSET(0),  -- Precision: seconds
    DateTimeOffset3 DATETIMEOFFSET(3),  -- Precision: milliseconds
    DateTimeOffset7 DATETIMEOFFSET(7)   -- Precision: 100 nanoseconds
);
GO

-- NULL and empty values
INSERT INTO DatetimeoffsetTest (Description, InputString, DateTimeOffset0, DateTimeOffset3, DateTimeOffset7)
VALUES ('NULL value', NULL, NULL, NULL, NULL);
GO

DECLARE @EmptyDateTimeOffset DATETIMEOFFSET;
INSERT INTO DatetimeoffsetTest (Description, InputString, DateTimeOffset0, DateTimeOffset3, DateTimeOffset7)
VALUES ('Empty DATETIMEOFFSET variable', NULL, @EmptyDateTimeOffset, @EmptyDateTimeOffset, @EmptyDateTimeOffset);
GO

SELECT * FROM DatetimeoffsetTest WHERE DateTimeOffset0 IS NULL ORDER BY ID;
GO
SELECT * FROM DatetimeoffsetTest ORDER BY ID;
GO

-- Default values
CREATE TABLE DatetimeoffsetDefaultTest (
    ID INT PRIMARY KEY,
    DateTimeOffsetCol DATETIMEOFFSET,
    DateTimeOffset1 DATETIMEOFFSET(4),
    DateTimeOffset2 DATETIMEOFFSET(6)
);
INSERT INTO DatetimeoffsetDefaultTest VALUES (1, CAST('19:00:00' As DATETIMEOFFSET), CAST('19:00:00' As DATETIMEOFFSET), CAST('19:00:00' As DATETIMEOFFSET));
INSERT INTO DatetimeoffsetDefaultTest VALUES (2, CAST('1910-01-01' As DATETIMEOFFSET), CAST('1910-01-01' As DATETIMEOFFSET), CAST('1910-01-01' As DATETIMEOFFSET));
SELECT * FROM DatetimeoffsetDefaultTest ORDER BY ID;
GO

-- Character length tests for DATETIMEOFFSET
-- Basic format without offset
DECLARE @d DATETIMEOFFSET = '2023-06-16 19:00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- With positive offset
DECLARE @d DATETIMEOFFSET = '2023-06-16 19:00:00 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- With negative offset
DECLARE @d DATETIMEOFFSET = '2023-06-16 19:00:00 -08:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- With different precisions
DECLARE @d DATETIMEOFFSET(0) = '2023-06-16 19:00:00 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(1) = '2023-06-16 19:00:00.1 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(2) = '2023-06-16 19:00:00.12 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(3) = '2023-06-16 19:00:00.123 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(4) = '2023-06-16 19:00:00.1234 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(5) = '2023-06-16 19:00:00.12345 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(6) = '2023-06-16 19:00:00.123456 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIMEOFFSET(7) = '2023-06-16 19:00:00.1234567 +00:00';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- With leading and trailing spaces
DECLARE @d DATETIMEOFFSET = '  2023-06-16 19:00:00 +00:00  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- Edge case values with different scales
-- Minimum values
DECLARE @dto1 DATETIMEOFFSET(0) = '0001-01-01 00:00:00 +00:00';
DECLARE @dto2 DATETIMEOFFSET(7) = '0001-01-01 00:00:00.0000000 +00:00';
DECLARE @dto3 DATETIMEOFFSET(0) = '0001-01-01 00:00:00 -14:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Maximum values
DECLARE @dto1 DATETIMEOFFSET(0) = '9999-12-31 23:59:59 +00:00';
DECLARE @dto2 DATETIMEOFFSET(7) = '9999-12-31 23:59:59.9999999 +00:00';
DECLARE @dto3 DATETIMEOFFSET(0) = '9999-12-31 23:59:59 +14:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Different offset combinations
DECLARE @dto1 DATETIMEOFFSET = '2023-06-16 19:00:00 +00:00';  -- UTC
DECLARE @dto2 DATETIMEOFFSET = '2023-06-16 19:00:00 +05:30';  -- India
DECLARE @dto3 DATETIMEOFFSET = '2023-06-16 19:00:00 -08:00';  -- PST
SELECT @dto1, @dto2, @dto3;
GO

-- Fractional seconds with different offsets
DECLARE @dto1 DATETIMEOFFSET(3) = '2023-06-16 19:00:00.123 +00:00';
DECLARE @dto2 DATETIMEOFFSET(3) = '2023-06-16 19:00:00.123 +05:30';
DECLARE @dto3 DATETIMEOFFSET(3) = '2023-06-16 19:00:00.123 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Maximum precision with different offsets
DECLARE @dto1 DATETIMEOFFSET(7) = '2023-06-16 19:00:00.1234567 +00:00';
DECLARE @dto2 DATETIMEOFFSET(7) = '2023-06-16 19:00:00.1234567 +05:30';
DECLARE @dto3 DATETIMEOFFSET(7) = '2023-06-16 19:00:00.1234567 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Zero values with different precisions and offsets
DECLARE @dto1 DATETIMEOFFSET(0) = '2023-06-16 00:00:00 +00:00';
DECLARE @dto2 DATETIMEOFFSET(3) = '2023-06-16 00:00:00.000 +00:00';
DECLARE @dto3 DATETIMEOFFSET(7) = '2023-06-16 00:00:00.0000000 +00:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Boundary minutes with different offsets
DECLARE @dto1 DATETIMEOFFSET = '2023-06-16 23:59:00 +00:00';
DECLARE @dto2 DATETIMEOFFSET = '2023-06-16 23:59:00 +05:30';
DECLARE @dto3 DATETIMEOFFSET = '2023-06-16 23:59:00 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Boundary seconds with different offsets
DECLARE @dto1 DATETIMEOFFSET = '2023-06-16 23:59:59 +00:00';
DECLARE @dto2 DATETIMEOFFSET = '2023-06-16 23:59:59 +05:30';
DECLARE @dto3 DATETIMEOFFSET = '2023-06-16 23:59:59 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Boundary milliseconds with different offsets
DECLARE @dto1 DATETIMEOFFSET(3) = '2023-06-16 23:59:59.999 +00:00';
DECLARE @dto2 DATETIMEOFFSET(3) = '2023-06-16 23:59:59.999 +05:30';
DECLARE @dto3 DATETIMEOFFSET(3) = '2023-06-16 23:59:59.999 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Maximum precision boundary with different offsets
DECLARE @dto1 DATETIMEOFFSET(7) = '2023-06-16 23:59:59.9999999 +00:00';
DECLARE @dto2 DATETIMEOFFSET(7) = '2023-06-16 23:59:59.9999999 +05:30';
DECLARE @dto3 DATETIMEOFFSET(7) = '2023-06-16 23:59:59.9999999 -08:00';
SELECT @dto1, @dto2, @dto3;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d DATETIMEOFFSET;
SET @d = '2023-06-16 19:00:00.1234567 +00:00';
SELECT @d, CAST('2023-06-16 19:00:00.1234567 +00:00' AS DATETIMEOFFSET), CONVERT(DATETIMEOFFSET, '2023-06-16 19:00:00.1234567 +00:00');
GO

-- Create a test table for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetFormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(100),
    ParsedDateTimeOffset DATETIMEOFFSET
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeOffsetTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTimeOffsetFormatTest (Description, InputString, ParsedDateTimeOffset)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIMEOFFSET));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Standard 24-hour format tests with timezone offset
EXEC InsertDateTimeOffsetTest '24hr - Full precision UTC', '2023-06-16 14:30:20.1234567 +00:00';
GO

EXEC InsertDateTimeOffsetTest '24hr - Seconds only PST', '2023-06-16 14:30:20 -07:00';
GO

EXEC InsertDateTimeOffsetTest '24hr - Minutes only EST', '2023-06-16 14:30 -04:00';
GO

EXEC InsertDateTimeOffsetTest '24hr - Hours only IST', '2023-06-16 14 +05:30';
GO

-- 2. AM/PM format tests with timezone offset
EXEC InsertDateTimeOffsetTest '12hr - AM Full UTC', '2023-06-16 10:30:20.1234567 AM +00:00';
GO

EXEC InsertDateTimeOffsetTest '12hr - PM Full PST', '2023-06-16 02:30:20.1234567 PM -07:00';
GO

EXEC InsertDateTimeOffsetTest '12hr - AM Simple EST', '2023-06-16 10:30 AM -04:00';
GO

EXEC InsertDateTimeOffsetTest '12hr - PM Simple IST', '2023-06-16 02:30 PM +05:30';
GO

-- 3. Different separators with timezone offset
EXEC InsertDateTimeOffsetTest 'Separator - Colon UTC', '2023-06-16 14:30:20 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Separator - Period PST', '2023-06-16 14.30.20 -07:00';
GO

EXEC InsertDateTimeOffsetTest 'Separator - Space EST', '2023-06-16 14 30 20 -04:00';
GO

-- 4. Precision variations with timezone offset
EXEC InsertDateTimeOffsetTest 'Precision - 7 digits UTC', '2023-06-16 14:30:20.1234567 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Precision - 6 digits PST', '2023-06-16 14:30:20.123456 -07:00';
GO

EXEC InsertDateTimeOffsetTest 'Precision - 5 digits EST', '2023-06-16 14:30:20.12345 -04:00';
GO

EXEC InsertDateTimeOffsetTest 'Precision - 4 digits IST', '2023-06-16 14:30:20.1234 +05:30';
GO

EXEC InsertDateTimeOffsetTest 'Precision - 3 digits UTC', '2023-06-16 14:30:20.123 +00:00';
GO

-- 5. Edge cases with timezone offset
EXEC InsertDateTimeOffsetTest 'Edge - Midnight UTC', '2023-06-16 00:00:00 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Edge - Almost midnight PST', '2023-06-16 23:59:59.9999999 -07:00';
GO

EXEC InsertDateTimeOffsetTest 'Edge - Noon EST', '2023-06-16 12:00:00 -04:00';
GO

EXEC InsertDateTimeOffsetTest 'Edge - Almost noon IST', '2023-06-16 11:59:59.9999999 +05:30';
GO

-- 6. Leading zeros variations with timezone offset
EXEC InsertDateTimeOffsetTest 'Zeros - With leading UTC', '2023-06-16 08:05:02 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Zeros - Without leading PST', '2023-06-16 8:5:2 -07:00';
GO

-- 7. AM/PM variations with timezone offset
EXEC InsertDateTimeOffsetTest 'AMPM - AM variations UTC', '2023-06-16 8:30 AM +00:00';
GO

EXEC InsertDateTimeOffsetTest 'AMPM - AM no space PST', '2023-06-16 8:30AM -07:00';
GO

EXEC InsertDateTimeOffsetTest 'AMPM - PM variations EST', '2023-06-16 8:30 PM -04:00';
GO

EXEC InsertDateTimeOffsetTest 'AMPM - PM no space IST', '2023-06-16 8:30PM +05:30';
GO

-- 8. ISO 8601 format with timezone offset
EXEC InsertDateTimeOffsetTest 'ISO - Basic', '2023-06-16T14:30:20+00:00';
GO

EXEC InsertDateTimeOffsetTest 'ISO - With milliseconds', '2023-06-16T14:30:20.1234567+00:00';
GO

-- 9. Different timezone offset formats
EXEC InsertDateTimeOffsetTest 'Offset - Positive hours only', '2023-06-16 14:30:20 +05';
GO

EXEC InsertDateTimeOffsetTest 'Offset - Negative hours only', '2023-06-16 14:30:20 -07';
GO

EXEC InsertDateTimeOffsetTest 'Offset - Half hour', '2023-06-16 14:30:20 +05:30';
GO

EXEC InsertDateTimeOffsetTest 'Offset - Quarter hour', '2023-06-16 14:30:20 +05:45';
GO

-- 10. Different cultures/formats with timezone offset
SET LANGUAGE French;
GO
EXEC InsertDateTimeOffsetTest 'French format', '16/06/2023 14.30.20 +02:00';
GO

SET LANGUAGE German;
GO
EXEC InsertDateTimeOffsetTest 'German format', '16.06.2023 14.30.20 +02:00';
GO

SET LANGUAGE us_english;
GO

-- 11. Invalid formats (these should fail)
EXEC InsertDateTimeOffsetTest 'Invalid - Hour too high', '2023-06-16 25:00:00 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Invalid - Too many fractional digits', '2023-06-16 14:30:20.12345678 +00:00';
GO

-- 12. Fractional seconds variations with timezone offset
EXEC InsertDateTimeOffsetTest 'Fractional - Trailing zeros', '2023-06-16 14:30:20.1000000 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Fractional - Mixed precision', '2023-06-16 14:30:20.123456 +00:00';
GO

-- 13. Special cases with timezone offset
EXEC InsertDateTimeOffsetTest 'Special - Midnight AM UTC', '2023-06-16 12:00:00 AM +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Special - Noon PM UTC', '2023-06-16 12:00:00 PM +00:00';
GO

-- 14. Date boundary cases with timezone offset
EXEC InsertDateTimeOffsetTest 'Boundary - Year start UTC', '2023-01-01 00:00:00 +00:00';
GO

EXEC InsertDateTimeOffsetTest 'Boundary - Year end UTC', '2023-12-31 23:59:59.9999999 +00:00';
GO

-- 15. Timezone transition cases
EXEC InsertDateTimeOffsetTest 'DST - Start PST', '2023-03-12 02:00:00 -08:00';
GO

EXEC InsertDateTimeOffsetTest 'DST - End PST', '2023-11-05 02:00:00 -07:00';
GO

-- Helper procedure to insert test cases for DATETIMEOFFSET with collations
CREATE PROCEDURE InsertDateTimeOffsetTest1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO DateTimeOffsetFormatTest (Description, InputString, Collation, ParsedDateTimeOffset)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS DATETIMEOFFSET))';
        
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
CREATE PROCEDURE TestDateTimeOffsetFormat
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
        EXEC InsertDateTimeOffsetTest1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Standard time formats with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - 24hr full precision UTC', '14:30:20.1234567 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 24hr with seconds PST', '14:30:20 -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 24hr without seconds EST', '14:30 -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 24hr hours only IST', '14 +05:30';
GO

-- AM/PM formats with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - 12hr AM full UTC', '10:30:20.1234567 AM +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 12hr PM full PST', '02:30:20.1234567 PM -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 12hr AM simple EST', '10:30 AM -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 12hr PM simple IST', '02:30 PM +05:30';
GO

-- Different separators with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - Colon separator UTC', '14:30:20 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Period separator PST', '14.30.20 -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Space separator EST', '14 30 20 -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - No separator IST', '143020 +05:30';
GO

-- Precision variations with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - 1 decimal place UTC', '14:30:20.1 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 3 decimal places PST', '14:30:20.123 -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 5 decimal places EST', '14:30:20.12345 -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - 7 decimal places IST', '14:30:20.1234567 +05:30';
GO

-- Leading zeros variations with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - With leading zeros UTC', '04:05:06 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Without leading zeros PST', '4:5:6 -08:00';
GO

-- Edge cases with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - Midnight UTC', '00:00:00 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Almost midnight PST', '23:59:59.9999999 -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Noon EST', '12:00:00 -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Almost noon IST', '11:59:59.9999999 +05:30';
GO

-- ISO 8601 format with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - ISO basic UTC', 'T143020+0000';
GO

EXEC TestDateTimeOffsetFormat 'DTO - ISO extended PST', 'T14:30:20-08:00';
GO

-- ODBC canonical format with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - ODBC canonical UTC', '{t ''14:30:20+00:00''}';
GO

-- AM/PM variations with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - AM variations 1 UTC', '12:00 AM +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - AM variations 2 PST', '12:00AM -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - PM variations 1 EST', '12:00 PM -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - PM variations 2 IST', '12:00PM +05:30';
GO

-- Different hour formats with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - Hour 0 UTC', '00:30:20 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Hour 12 AM PST', '12:30:20 AM -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Hour 12 PM EST', '12:30:20 PM -05:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Hour 24 IST', '24:00:00 +05:30';
GO

-- Offset variations (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO - Positive whole hour', '14:30:20 +08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Negative whole hour', '14:30:20 -08:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Positive fractional hour', '14:30:20 +05:30';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Negative fractional hour', '14:30:20 -05:30';
GO

EXEC TestDateTimeOffsetFormat 'DTO - Zero offset', '14:30:20 +00:00';
GO

-- Invalid formats (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO Invalid - Hour too high', '25:00:00 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Invalid - Minute too high', '14:60:00 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Invalid - Second too high', '14:30:60 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Invalid - Too many decimals', '14:30:20.12345678 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Invalid - Bad offset format', '14:30:20 +8:00';
GO

-- Mixed formats with offset (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO Mixed - Different separators', '14:30.20 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Mixed - Partial precision', '14:30:20. +00:00';
GO

-- Offset format variations (test with all collations)
EXEC TestDateTimeOffsetFormat 'DTO Offset - No colon', '14:30:20 +0000';
GO

EXEC TestDateTimeOffsetFormat 'DTO Offset - With Z', '14:30:20Z';
GO

EXEC TestDateTimeOffsetFormat 'DTO Offset - Plus optional', '14:30:20 +00:00';
GO

EXEC TestDateTimeOffsetFormat 'DTO Offset - Minus required', '14:30:20 -00:00';
GO

-- Language-specific formats with offset (test with all collations)
SET LANGUAGE French;
GO
EXEC TestDateTimeOffsetFormat 'DTO French format', '14:30:20 +01:00';
GO

SET LANGUAGE German;
GO
EXEC TestDateTimeOffsetFormat 'DTO German format', '14:30:20 +01:00';
GO

SET LANGUAGE us_english;
GO

-- Display results
SELECT * FROM DateTimeOffsetFormatTest ORDER BY ID;
GO

-- Create a test table for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedDateTimeOffset DATETIMEOFFSET
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeOffsetTest2
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTimeOffsetConversionTest (Description, InputString, ConvertedDateTimeOffset)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIMEOFFSET));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC format tests
EXEC InsertDateTimeOffsetTest2 'ODBC DATETIME with offset', '{ts ''2023-06-16 12:34:56.789''} +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'ODBC DATETIME UTC', '{ts ''2023-06-16 12:34:56.789''} +00:00';
GO

-- ISO 8601 format tests
EXEC InsertDateTimeOffsetTest2 'ISO 8601 basic', '20230616T123456.789+0530';
GO

EXEC InsertDateTimeOffsetTest2 'ISO 8601 extended', '2023-06-16T12:34:56.789+05:30';
GO

EXEC InsertDateTimeOffsetTest2 'ISO 8601 UTC', '2023-06-16T12:34:56.789Z';
GO

EXEC InsertDateTimeOffsetTest2 'ISO 8601 negative offset', '2023-06-16T12:34:56.789-08:00';
GO

-- Standard format with different offsets
EXEC InsertDateTimeOffsetTest2 'Standard format IST', '2023-06-16 12:34:56.789 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Standard format PST', '2023-06-16 12:34:56.789 -08:00';
GO

EXEC InsertDateTimeOffsetTest2 'Standard format UTC', '2023-06-16 12:34:56.789 +00:00';
GO

-- Different precision tests
EXEC InsertDateTimeOffsetTest2 'Hours only with offset', '2023-06-16 14 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Hours and minutes with offset', '2023-06-16 14:30 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'With seconds', '2023-06-16 14:30:45 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'With milliseconds', '2023-06-16 14:30:45.123 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'With microseconds', '2023-06-16 14:30:45.123456 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'With nanoseconds', '2023-06-16 14:30:45.123456789 +05:30';
GO

-- AM/PM format tests
EXEC InsertDateTimeOffsetTest2 'AM time with offset', '2023-06-16 09:30:00 AM +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'PM time with offset', '2023-06-16 09:30:00 PM +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Lowercase am with offset', '2023-06-16 09:30:00 am +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Lowercase pm with offset', '2023-06-16 09:30:00 pm +05:30';
GO

-- Different date formats with offset
SET DATEFORMAT mdy;
GO
EXEC InsertDateTimeOffsetTest2 'MDY format with offset', '06-16-2023 14:30:45 +05:30';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertDateTimeOffsetTest2 'DMY format with offset', '16-06-2023 14:30:45 +05:30';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertDateTimeOffsetTest2 'YMD format with offset', '2023-06-16 14:30:45 +05:30';
GO

SET DATEFORMAT mdy;
GO

-- Edge cases
EXEC InsertDateTimeOffsetTest2 'Minimum date with offset', '0001-01-01 00:00:00 +00:00';
GO

EXEC InsertDateTimeOffsetTest2 'Maximum date with offset', '9999-12-31 23:59:59.9999999 +14:00';
GO

EXEC InsertDateTimeOffsetTest2 'Midnight with offset', '2023-06-16 00:00:00 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Last moment with offset', '2023-06-16 23:59:59.9999999 +05:30';
GO

-- Offset variations
EXEC InsertDateTimeOffsetTest2 'Maximum positive offset', '2023-06-16 12:34:56 +14:00';
GO

EXEC InsertDateTimeOffsetTest2 'Maximum negative offset', '2023-06-16 12:34:56 -14:00';
GO

EXEC InsertDateTimeOffsetTest2 'Half hour offset', '2023-06-16 12:34:56 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Quarter hour offset', '2023-06-16 12:34:56 +05:45';
GO

-- Daylight saving time transition
EXEC InsertDateTimeOffsetTest2 'DST Start', '2023-03-12 02:30:00 -07:00';
GO

EXEC InsertDateTimeOffsetTest2 'DST End', '2023-11-05 01:30:00 -07:00';
GO

-- Different separators
EXEC InsertDateTimeOffsetTest2 'Date with slashes', '2023/06/16 14:30:45 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Time with periods', '2023-06-16 14.30.45 +05:30';
GO

-- Invalid formats (should fail)
EXEC InsertDateTimeOffsetTest2 'Invalid offset minutes', '2023-06-16 14:30:45 +05:60';
GO

EXEC InsertDateTimeOffsetTest2 'Invalid time', '2023-06-16 24:00:00 +05:30';
GO

EXEC InsertDateTimeOffsetTest2 'Invalid date', '2023-13-16 14:30:45 +05:30';
GO

-- Special timezone designators
EXEC InsertDateTimeOffsetTest2 'UTC designator Z', '2023-06-16T14:30:45.123Z';
GO

EXEC InsertDateTimeOffsetTest2 'UTC offset +00:00', '2023-06-16T14:30:45.123+00:00';
GO

-- Roundtrip format
EXEC InsertDateTimeOffsetTest2 'Roundtrip format', '2023-06-16T14:30:45.1234567+05:30';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputString,
    ConvertedDateTimeOffset,
    CAST(ConvertedDateTimeOffset AS NVARCHAR(50)) AS DateTimeOffsetString
FROM DateTimeOffsetConversionTest 
ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'DATETIMEOFFSET';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'DATETIMEOFFSET' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- AT TIME ZONE

-- Create a test table for DATETIMEOFFSET with time zones
CREATE TABLE DateTimeOffsetZoneTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputDateTimeOffset DATETIMEOFFSET,
    TimeZone NVARCHAR(100),
    Result NVARCHAR(MAX)
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTimeOffsetZoneTest
    @Description NVARCHAR(100),
    @InputDateTimeOffset DATETIMEOFFSET,
    @TimeZone NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @Result NVARCHAR(MAX);
        SET @Result = CAST(@InputDateTimeOffset AT TIME ZONE @TimeZone AS NVARCHAR(MAX));
        
        INSERT INTO DateTimeOffsetZoneTest (Description, InputDateTimeOffset, TimeZone, Result)
        VALUES (@Description, @InputDateTimeOffset, @TimeZone, @Result);
        
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        INSERT INTO DateTimeOffsetZoneTest (Description, InputDateTimeOffset, TimeZone, Result)
        VALUES (@Description, @InputDateTimeOffset, @TimeZone, ERROR_MESSAGE());
        
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Standard time tests
EXEC InsertDateTimeOffsetZoneTest 'DTO Midnight UTC', '2023-06-16 00:00:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Noon UTC', '2023-06-16 12:00:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Evening UTC', '2023-06-16 18:30:00 +00:00', 'UTC';
GO

-- Different time zones with specific times
EXEC InsertDateTimeOffsetZoneTest 'DTO Morning PST', '2023-06-16 09:30:00 -07:00', 'Pacific Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Afternoon EST', '2023-06-16 14:30:00 -04:00', 'Eastern Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Evening CET', '2023-06-16 20:30:00 +02:00', 'Central European Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Night JST', '2023-06-16 23:30:00 +09:00', 'Tokyo Standard Time';
GO

-- Time precision tests
EXEC InsertDateTimeOffsetZoneTest 'DTO Precision Seconds', '2023-06-16 14:30:20 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Precision Milliseconds', '2023-06-16 14:30:20.123 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Precision Microseconds', '2023-06-16 14:30:20.123456 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Precision Nanoseconds', '2023-06-16 14:30:20.1234567 +00:00', 'UTC';
GO

-- DST transition times
EXEC InsertDateTimeOffsetZoneTest 'DTO DST Start PST Before', '2023-03-12 01:30:00 -08:00', 'Pacific Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO DST Start PST During', '2023-03-12 02:30:00 -07:00', 'Pacific Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO DST Start PST After', '2023-03-12 03:30:00 -07:00', 'Pacific Standard Time';
GO

-- Time zones with different offsets
EXEC InsertDateTimeOffsetZoneTest 'DTO IST Time', '2023-06-16 15:30:00 +05:30', 'India Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO NZ Time', '2023-06-16 15:30:00 +12:00', 'New Zealand Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Saudi Time', '2023-06-16 15:30:00 +03:00', 'Saudi Arabia Standard Time';
GO

-- Edge cases
EXEC InsertDateTimeOffsetZoneTest 'DTO Min Time', '0001-01-01 00:00:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Max Time', '9999-12-31 23:59:59.9999999 +00:00', 'UTC';
GO

-- Offset boundary tests
EXEC InsertDateTimeOffsetZoneTest 'DTO Max Positive Offset', '2023-06-16 12:00:00 +14:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Max Negative Offset', '2023-06-16 12:00:00 -14:00', 'UTC';
GO

-- Cross day boundary tests with offsets
EXEC InsertDateTimeOffsetZoneTest 'DTO Day Boundary 1', '2023-06-16 23:30:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Day Boundary 2', '2023-06-16 00:30:00 +00:00', 'UTC';
GO

-- Month boundary tests with offsets
EXEC InsertDateTimeOffsetZoneTest 'DTO Month Boundary 1', '2023-06-30 23:30:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Month Boundary 2', '2023-07-01 00:30:00 +00:00', 'UTC';
GO

-- Year boundary tests with offsets
EXEC InsertDateTimeOffsetZoneTest 'DTO Year Boundary 1', '2023-12-31 23:30:00 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Year Boundary 2', '2024-01-01 00:30:00 +00:00', 'UTC';
GO

-- Offset conversion tests
EXEC InsertDateTimeOffsetZoneTest 'DTO UTC to PST', '2023-06-16 12:00:00 +00:00', 'Pacific Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO PST to UTC', '2023-06-16 12:00:00 -07:00', 'UTC';
GO

-- Fractional seconds with offset tests
EXEC InsertDateTimeOffsetZoneTest 'DTO Fractional UTC', '2023-06-16 12:00:00.1234567 +00:00', 'UTC';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Fractional PST', '2023-06-16 12:00:00.1234567 -07:00', 'Pacific Standard Time';
GO

-- DST affected conversions
EXEC InsertDateTimeOffsetZoneTest 'DTO Summer Time PST', '2023-07-15 12:00:00 -07:00', 'Pacific Standard Time';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO Winter Time PST', '2023-12-15 12:00:00 -08:00', 'Pacific Standard Time';
GO

-- Invalid scenarios
EXEC InsertDateTimeOffsetZoneTest 'DTO Invalid Time Zone', '2023-06-16 12:00:00 +00:00', 'Invalid Time Zone';
GO

EXEC InsertDateTimeOffsetZoneTest 'DTO NULL Time Zone', '2023-06-16 12:00:00 +00:00', NULL;
GO

-- Offset arithmetic
DECLARE @dto DATETIMEOFFSET = '2023-06-16 12:00:00 +00:00';
SELECT 
    @dto AS OriginalDTO,
    @dto AT TIME ZONE 'UTC' AS UTCTime,
    @dto AT TIME ZONE 'Pacific Standard Time' AS PSTTime,
    @dto AT TIME ZONE 'Eastern Standard Time' AS ESTTime;
GO

-- Display results with offset information
SELECT 
    ID,
    Description,
    InputDateTimeOffset,
    TimeZone,
    Result,
    DATEDIFF(MINUTE, InputDateTimeOffset AT TIME ZONE 'UTC', InputDateTimeOffset) AS MinutesFromUTC
FROM DateTimeOffsetZoneTest 
ORDER BY ID;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d DATETIMEOFFSET', @d = '2023-06-16 19:00:00.1234567 +00:00';
GO

-- 1. Create User-Defined Data Types based on DATETIMEOFFSET
CREATE TYPE BusinessDateTimeOffset FROM DATETIMEOFFSET(7);
CREATE TYPE ShiftDateTimeOffset FROM DATETIMEOFFSET(0);
CREATE TYPE PreciseDateTimeOffset FROM DATETIMEOFFSET(7);
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTDateTimeOffsetTest (
    ID INT PRIMARY KEY,
    RegularDTO DATETIMEOFFSET,
    BusinessDTOCol BusinessDateTimeOffset,
    ShiftDTOCol ShiftDateTimeOffset,
    PreciseDTOCol PreciseDateTimeOffset
);
GO

-- 3. Insert data into the table
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES 
(1, '2023-06-16 09:00:00 +00:00', '2023-06-16 09:00:00.0000000 +00:00', '2023-06-16 09:00:00 +00:00', '2023-06-16 09:00:00.1234567 +00:00'),
(2, '2023-06-16 12:30:45 -07:00', '2023-06-16 12:30:45.1234567 -07:00', '2023-06-16 12:30:00 -07:00', '2023-06-16 12:30:45.1234567 -07:00'),
(3, '2023-06-16 17:45:30 +01:00', '2023-06-16 17:45:30.0000000 +01:00', '2023-06-16 17:45:00 +01:00', '2023-06-16 17:45:30.9999999 +01:00'),
(4, NULL, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTDateTimeOffsetTest ORDER BY ID;
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
WHERE TABLE_NAME = 'UDDTDateTimeOffsetTest' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularDTO AS VARCHAR(50)) AS RegularDTOString,
    CAST(BusinessDTOCol AS VARCHAR(50)) AS BusinessDTOString,
    CAST(ShiftDTOCol AS VARCHAR(50)) AS ShiftDTOString,
    CAST(PreciseDTOCol AS VARCHAR(50)) AS PreciseDTOString,
    CAST(RegularDTO AS DATETIME2) AS RegularDateTime2,
    CAST(BusinessDTOCol AS DATETIME2) AS BusinessDateTime2
FROM UDDTDateTimeOffsetTest ORDER BY ID;
GO

-- 7. Test time zone functions
SELECT 
    ID,
    DATEADD(HOUR, 1, RegularDTO) AS RegularNextHour,
    DATEADD(HOUR, 1, BusinessDTOCol) AS BusinessNextHour,
    DATEADD(MINUTE, 30, ShiftDTOCol) AS ShiftNextHalfHour,
    DATEDIFF(MINUTE, ShiftDTOCol, BusinessDTOCol) AS MinutesBetween,
    RegularDTO AT TIME ZONE 'UTC' AS RegularUTC,
    BusinessDTOCol AT TIME ZONE 'Pacific Standard Time' AS BusinessPST
FROM UDDTDateTimeOffsetTest ORDER BY ID;
GO

-- 8. Test constraints
ALTER TABLE UDDTDateTimeOffsetTest ADD CONSTRAINT CK_BusinessDTO 
    CHECK (CAST(BusinessDTOCol AT TIME ZONE 'UTC' AS TIME) >= '09:00:00' 
    AND CAST(BusinessDTOCol AT TIME ZONE 'UTC' AS TIME) <= '17:00:00');
GO

-- This should succeed
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES (5, '2023-06-16 10:00:00 +00:00', '2023-06-16 10:00:00 +00:00', '2023-06-16 10:00:00 +00:00', '2023-06-16 10:00:00.1234567 +00:00');
GO

-- This should fail
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES (6, '2023-06-16 18:00:00 +00:00', '2023-06-16 18:00:00 +00:00', '2023-06-16 18:00:00 +00:00', '2023-06-16 18:00:00.1234567 +00:00');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTDateTimeOffsetProc
    @BusinessDTO BusinessDateTimeOffset,
    @ShiftDTO ShiftDateTimeOffset
AS
BEGIN
    SELECT 
        @BusinessDTO AS InputBusinessDTO,
        @ShiftDTO AS InputShiftDTO,
        DATEDIFF(MINUTE, @ShiftDTO, @BusinessDTO) AS MinutesBetween,
        @BusinessDTO AT TIME ZONE 'UTC' AS BusinessUTC,
        @ShiftDTO AT TIME ZONE 'UTC' AS ShiftUTC;
END
GO

-- Execute the stored procedure
EXEC TestUDDTDateTimeOffsetProc 
    @BusinessDTO = '2023-06-16 10:30:00 -07:00', 
    @ShiftDTO = '2023-06-16 09:00:00 -07:00';
GO

-- 10. Test implicit conversions
DECLARE @RegularDTO DATETIMEOFFSET = '2023-06-16 10:30:00 -07:00';
DECLARE @BusinessDTO BusinessDateTimeOffset = @RegularDTO;
DECLARE @ShiftDTO ShiftDateTimeOffset = '2023-06-16 09:00:00 -07:00';
DECLARE @PreciseDTO PreciseDateTimeOffset = '2023-06-16 10:30:00.1234567 -07:00';

SELECT 
    @RegularDTO AS RegularDTO,
    @BusinessDTO AS BusinessDTO,
    @ShiftDTO AS ShiftDTO,
    @PreciseDTO AS PreciseDTO;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessDTO ON UDDTDateTimeOffsetTest(BusinessDTOCol);
CREATE INDEX IX_ShiftDTO ON UDDTDateTimeOffsetTest(ShiftDTOCol);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTDateTimeOffsetTest WHERE BusinessDTOCol = '2023-06-16 10:00:00 +00:00';
SELECT * FROM UDDTDateTimeOffsetTest WHERE ShiftDTOCol = '2023-06-16 09:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 12. Test with different time zones
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES 
(7, '2023-06-16 13:00:00 +00:00', '2023-06-16 13:00:00 +00:00', '2023-06-16 13:00:00 +00:00', '2023-06-16 13:00:00.1234567 +00:00'),
(8, '2023-06-16 13:00:00 -07:00', '2023-06-16 13:00:00 -07:00', '2023-06-16 13:00:00 -07:00', '2023-06-16 13:00:00.1234567 -07:00');
GO

-- 13. Test precision handling
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES 
(9, '2023-06-16 14:30:45.1234567 +00:00', '2023-06-16 14:30:45.1234567 +00:00', '2023-06-16 14:30:00 +00:00', '2023-06-16 14:30:45.1234567 +00:00'),
(10, '2023-06-16 14:30:45.9999999 +00:00', '2023-06-16 14:30:45.9999999 +00:00', '2023-06-16 14:30:00 +00:00', '2023-06-16 14:30:45.9999999 +00:00');
GO

-- 14. Test time zone arithmetic
SELECT 
    ID,
    BusinessDTOCol,
    BusinessDTOCol AT TIME ZONE 'UTC' AS UTC,
    BusinessDTOCol AT TIME ZONE 'Pacific Standard Time' AS PST,
    BusinessDTOCol AT TIME ZONE 'Eastern Standard Time' AS EST,
    DATEADD(HOUR, 1, BusinessDTOCol) AS AddHour
FROM UDDTDateTimeOffsetTest ORDER BY ID;
GO

-- 15. Test boundary conditions
INSERT INTO UDDTDateTimeOffsetTest (ID, RegularDTO, BusinessDTOCol, ShiftDTOCol, PreciseDTOCol)
VALUES 
(11, '0001-01-01 00:00:00 +00:00', '0001-01-01 00:00:00 +00:00', '0001-01-01 00:00:00 +00:00', '0001-01-01 00:00:00.0000000 +00:00'),
(12, '9999-12-31 23:59:59.9999999 +00:00', '9999-12-31 23:59:59.9999999 +00:00', '9999-12-31 23:59:00 +00:00', '9999-12-31 23:59:59.9999999 +00:00');
GO

-- 16. Test with different components and time zones
SELECT 
    ID,
    DATEPART(HOUR, BusinessDTOCol) AS BusinessHour,
    DATEPART(MINUTE, BusinessDTOCol) AS BusinessMinute,
    DATEPART(SECOND, BusinessDTOCol) AS BusinessSecond,
    DATEPART(MILLISECOND, BusinessDTOCol) AS BusinessMillisecond,
    DATEPART(TZOFFSET, BusinessDTOCol) AS BusinessOffset,
    BusinessDTOCol AT TIME ZONE 'UTC' AS BusinessUTC
FROM UDDTDateTimeOffsetTest;
GO

-- Display final results
SELECT * FROM UDDTDateTimeOffsetTest ORDER BY ID;
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing
SELECT 
    CAST('2023-06-16 19:00:00.1234567 +00:00' AS DATETIMEOFFSET),
    CONVERT(DATETIMEOFFSET, '2023-06-16 19:00:00.1234567 +00:00'),
    TRY_CAST('2023-06-16 19:00:00.1234567 +00:00' AS DATETIMEOFFSET),
    TRY_CONVERT(DATETIMEOFFSET, '2023-06-16 19:00:00.1234567 +00:00'),
    FORMAT(CAST('2023-06-16 19:00:00.1234567 +00:00' AS DATETIMEOFFSET), 'yyyy-MM-dd HH:mm:ss -hh:mm');
GO

-- Explicit Conversion to DATETIMEOFFSET
-- binary
SELECT CAST(CAST(0x0000A8C0 AS binary) AS DATETIMEOFFSET); 
GO
SELECT CAST(CAST(0x AS binary) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(0xFFFFFFFF AS binary) AS DATETIMEOFFSET);
GO

-- varbinary
SELECT CAST(CAST(0x0000A8C0 AS VARBINARY) AS DATETIMEOFFSET);
GO
SELECT CAST(0x AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(0xFFFFFFFF AS VARBINARY) AS DATETIMEOFFSET);
GO

-- char
SELECT CAST(CAST('2023-06-16 12:34:56 +00:00' AS char) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS char) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('2023-06-16 12:34 +02:00' AS char) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('invalid' AS char) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(NULL AS char) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('' AS char) AS DATETIMEOFFSET);
GO

-- varchar
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('0001-01-01 00:00:00 -14:00' AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('2023-06-16 12:34:56 +00:00' AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('2023-06-16 12:34 +01:00' AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('invalid' AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(NULL AS varchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('' AS varchar) AS DATETIMEOFFSET);
GO

-- nchar
SELECT CAST(CAST(N'2023-06-16 12:34:56 +00:00' AS NCHAR) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(N'2023-06-16 12:34:56.1234567 +01:00' AS NCHAR) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(N'0001-01-01 00:00:00 +00:00' AS NCHAR) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(N'9999-12-31 23:59:59.9999999 +14:00' AS NCHAR) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(NULL AS nchar) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(N'' AS nchar) AS DATETIMEOFFSET);
GO

-- nvarchar
SELECT CAST(N'2023-06-16 12:34:56 +00:00' AS DATETIMEOFFSET);
GO
SELECT CAST(N'2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(N'invalid' AS DATETIMEOFFSET);
GO

-- time
SELECT CAST(CAST('12:34:56' AS TIME) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('23:59:59.9999999' AS TIME) AS DATETIMEOFFSET);
GO

-- datetime
SELECT CAST(CAST('2023-06-16 12:34:56' AS DATETIME) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('1753-01-01 00:00:00' AS DATETIME) AS DATETIMEOFFSET);
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 12:34:00' AS SMALLDATETIME) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('1900-01-01 00:00:00' AS SMALLDATETIME) AS DATETIMEOFFSET);
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2) AS DATETIMEOFFSET);
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS DATETIMEOFFSET);
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS DATETIMEOFFSET);
GO

-- decimal
SELECT CAST(CAST(20230616 AS DECIMAL(8,0)) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(99991231 AS DECIMAL(8,0)) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(0 AS DECIMAL(8,0)) AS DATETIMEOFFSET);
GO

-- numeric
SELECT CAST(CAST(20230616 AS NUMERIC(8,0)) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(00010101 AS NUMERIC(8,0)) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS NUMERIC(8,0)) AS DATETIMEOFFSET);
GO

-- float
SELECT CAST(CAST(20230616.1234567 AS FLOAT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(99991231.9999999 AS FLOAT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS FLOAT) AS DATETIMEOFFSET);
GO

-- real
SELECT CAST(CAST(20230616.123 AS REAL) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(99991231.999 AS REAL) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS REAL) AS DATETIMEOFFSET);
GO

-- bigint
SELECT CAST(CAST(20230616123456 AS BIGINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(99991231235959 AS BIGINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS BIGINT) AS DATETIMEOFFSET);
GO

-- int
SELECT CAST(20230616 AS DATETIMEOFFSET);
GO
SELECT CAST(00010101 AS DATETIMEOFFSET);
GO
SELECT CAST(-1 AS DATETIMEOFFSET);
GO

-- smallint
SELECT CAST(CAST(2023 AS SMALLINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(9999 AS SMALLINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS SMALLINT) AS DATETIMEOFFSET);
GO

-- tinyint
SELECT CAST(CAST(23 AS TINYINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(255 AS TINYINT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(0 AS TINYINT) AS DATETIMEOFFSET);
GO

-- money
SELECT CAST(CAST(20230616.1234 AS MONEY) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(99991231.9999 AS MONEY) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS MONEY) AS DATETIMEOFFSET);
GO

-- smallmoney
SELECT CAST(CAST(20230616 AS SMALLMONEY) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS DATETIMEOFFSET);
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(0 AS BIT) AS DATETIMEOFFSET);
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS DATETIMEOFFSET);
GO

-- text
SELECT CAST(CAST('2023-06-16 12:34:56 +00:00' AS TEXT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST('invalid' AS TEXT) AS DATETIMEOFFSET);
GO

-- ntext
SELECT CAST(CAST(N'2023-06-16 12:34:56 +00:00' AS NTEXT) AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS DATETIMEOFFSET);
GO

-- xml
SELECT CAST(CAST('<date>2023-06-16T12:34:56+00:00</date>' AS XML) AS DATETIMEOFFSET);
GO

-- sql_variant
SELECT CAST(CAST(CAST('2023-06-16 12:34:56 +00:00' AS DATETIMEOFFSET) AS SQL_VARIANT) AS DATETIMEOFFSET);
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS DATETIMEOFFSET);
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS DATETIMEOFFSET);
GO

-- Create a function that takes a DATETIMEOFFSET parameter
CREATE FUNCTION dbo.TestDateTimeOffsetFunction(@DTOParam DATETIMEOFFSET)
RETURNS DATETIMEOFFSET
AS
BEGIN
    RETURN @DTOParam;
END
GO

-- binary
SELECT dbo.TestDateTimeOffsetFunction(CAST(0x0A1E2D3C AS binary)); -- Time equivalent
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0x AS binary));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0xFFFFFFFF AS binary));
GO

-- varbinary
SELECT dbo.TestDateTimeOffsetFunction(CAST(0x0A1E2D3C AS VARBINARY));
GO
SELECT dbo.TestDateTimeOffsetFunction(0x);
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0xFFFFFFFF AS VARBINARY));
GO

-- char
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20 +01:00' AS char));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20.1234567 +01:00' AS char));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30 +01:00' AS char));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('invalid' AS char));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(NULL AS char));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestDateTimeOffsetFunction(CAST('9999-12-31 23:59:59.9999999 +14:00' AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20 +01:00' AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30 +01:00' AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 2:30 PM +01:00' AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('invalid' AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(NULL AS varchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'2023-06-16 14:30:20 +01:00' AS NCHAR));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'2023-06-16 14:30 +01:00' AS NCHAR));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'0001-01-01 00:00:00 +00:00' AS NCHAR));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(NULL AS nchar));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestDateTimeOffsetFunction(N'2023-06-16 14:30:20 +01:00');
GO
SELECT dbo.TestDateTimeOffsetFunction(N'2023-06-16 14:30:20.1234567 +01:00');
GO
SELECT dbo.TestDateTimeOffsetFunction(N'2023-06-16 2:30 PM +01:00');
GO

-- time
SELECT dbo.TestDateTimeOffsetFunction(CAST('14:30:20' AS TIME));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('23:59:59.9999999' AS TIME));
GO

-- datetime
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20' AS DATETIME));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('1753-01-01 00:00:00' AS DATETIME));
GO

-- smalldatetime
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:00' AS SMALLDATETIME));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('1900-01-01 00:00:00' AS SMALLDATETIME));
GO

-- datetime2
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20.1234567' AS DATETIME2));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2));
GO

-- date
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16' AS DATE));
GO

-- datetimeoffset
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET));
GO

-- decimal
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS DECIMAL(14,0)));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231235959 AS DECIMAL(14,0)));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0 AS DECIMAL(14,0)));
GO

-- numeric
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS NUMERIC(14,0)));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0 AS NUMERIC(14,0)));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-1 AS NUMERIC(14,0)));
GO

-- float
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS FLOAT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231235959.9999999 AS FLOAT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-20230616143020 AS FLOAT));
GO

-- real
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS REAL));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231235959.99 AS REAL));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-20230616143020 AS REAL));
GO

-- bigint
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS BIGINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231235959 AS BIGINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-1 AS BIGINT));
GO

-- int
SELECT dbo.TestDateTimeOffsetFunction(20230616);
GO
SELECT dbo.TestDateTimeOffsetFunction(0);
GO
SELECT dbo.TestDateTimeOffsetFunction(-1);
GO

-- smallint
SELECT dbo.TestDateTimeOffsetFunction(CAST(2023 AS SMALLINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(9999 AS SMALLINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-1 AS SMALLINT));
GO

-- tinyint
SELECT dbo.TestDateTimeOffsetFunction(CAST(23 AS TINYINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99 AS TINYINT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(0 AS TINYINT));
GO

-- money
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616143020 AS MONEY));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231235959.9999999 AS MONEY));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-1 AS MONEY));
GO

-- smallmoney
SELECT dbo.TestDateTimeOffsetFunction(CAST(20230616 AS SMALLMONEY));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(99991231 AS SMALLMONEY));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(-1 AS SMALLMONEY));
GO

-- bit
SELECT dbo.TestDateTimeOffsetFunction(CAST(1 AS BIT));
GO

-- uniqueidentifier
SELECT dbo.TestDateTimeOffsetFunction(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER));
GO

-- text
SELECT dbo.TestDateTimeOffsetFunction(CAST('2023-06-16 14:30:20 +01:00' AS TEXT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST('invalid' AS TEXT));
GO

-- ntext
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'2023-06-16 14:30:20 +01:00' AS NTEXT));
GO
SELECT dbo.TestDateTimeOffsetFunction(CAST(N'invalid' AS NTEXT));
GO

-- xml
SELECT dbo.TestDateTimeOffsetFunction(CAST('<date>2023-06-16T14:30:20+01:00</date>' AS XML));
GO

-- sql_variant
SELECT dbo.TestDateTimeOffsetFunction(CAST(CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET) AS SQL_VARIANT));
GO

-- geometry
SELECT dbo.TestDateTimeOffsetFunction(geometry::STGeomFromText('POINT(1 1)', 0));
GO

-- geography
SELECT dbo.TestDateTimeOffsetFunction(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326));
GO

-- Create a table to store test results for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue DATETIMEOFFSET NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertDateTimeOffsetTestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue DATETIMEOFFSET = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO DateTimeOffsetImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @DateTimeOffsetValue DATETIMEOFFSET = '2023-06-20 12:34:56.789 +01:00';
DECLARE @StringDTO NVARCHAR(50) = '2023-06-20 14:30:00 -07:00';
DECLARE @DateTimeValue DATETIME = '2023-06-20 15:45:30.123';
DECLARE @SmallDateTime SMALLDATETIME = '2023-06-20 16:30:00';

-- 1. UNION
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateTimeOffsetValue AS Result
        UNION
        SELECT @StringDTO
        UNION
        SELECT @DateTimeValue
        UNION
        SELECT @SmallDateTime
    ) AS UnionResult;
    EXEC InsertDateTimeOffsetTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 2. UNION ALL
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-20 12:34:56.789 +01:00' AS DATETIMEOFFSET) AS Result
        UNION ALL
        SELECT '2023-06-20 14:30:00 -07:00'
        UNION ALL
        SELECT CAST('2023-06-20 15:45:30.123' AS DATETIME)
        UNION ALL
        SELECT CAST('2023-06-20 16:30:00' AS SMALLDATETIME)
    ) AS UnionAllResult;
    EXEC InsertDateTimeOffsetTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 3. CASE Expression
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET = CASE 
        WHEN 1=0 THEN CAST('2023-06-20 12:34:56.789 +01:00' AS DATETIMEOFFSET)
        WHEN 1=0 THEN '2023-06-20 14:30:00 -07:00'
        ELSE CAST('2023-06-20 15:45:30.123' AS DATETIME)
    END;
    EXEC InsertDateTimeOffsetTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 4. COALESCE
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET = COALESCE(
        NULL, 
        CAST('2023-06-20 12:34:56.789 +01:00' AS DATETIMEOFFSET),
        '2023-06-20 14:30:00 -07:00',
        CAST('2023-06-20 15:45:30.123' AS DATETIME)
    );
    EXEC InsertDateTimeOffsetTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 6. EXCEPT
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-20 12:34:56.789 +01:00' AS DATETIMEOFFSET) AS Result
        EXCEPT
        SELECT '2023-06-20 14:30:00 -07:00'
    ) AS ExceptResult;
    EXEC InsertDateTimeOffsetTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIMEOFFSET and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIMEOFFSET and String', NULL, 0;
END CATCH;
GO

-- 7. VALUES
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET;
    SELECT TOP 1 @Result = Result
    FROM (VALUES 
        (CAST('2023-06-20 12:34:56.789 +01:00' AS DATETIMEOFFSET)),
        ('2023-06-20 14:30:00 -07:00'),
        (CAST('2023-06-20 15:45:30.123' AS DATETIME))
    ) AS ValuesResult(Result);
    EXEC InsertDateTimeOffsetTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime types', NULL, 0;
END CATCH;
GO

-- 8. ISNULL
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET = ISNULL(NULL, '2023-06-20 14:30:00 -07:00');
    EXEC InsertDateTimeOffsetTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;
GO

-- Additional DATETIMEOFFSET-specific tests

-- 9. Different offset formats
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET = COALESCE(
        '2023-06-20 12:34:56.7890123 +01:00',  -- More precision
        '2023-06-20 12:34:56 -07:00',          -- Different timezone
        '2023-06-20 12:34:56Z',                -- UTC
        '2023-06-20 12:34:56.789 +00:00'       -- Zero offset
    );
    EXEC InsertDateTimeOffsetTestResult 'Offset Formats', 'Different offset format conversions', 'Various offset formats', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'Offset Formats', 'Different offset format conversions', 'Various offset formats', NULL, 0;
END CATCH;
GO

-- 10. Edge cases
BEGIN TRY
    DECLARE @Result DATETIMEOFFSET = COALESCE(
        '0001-01-01 00:00:00.0000000 +00:00',  -- Minimum value
        '9999-12-31 23:59:59.9999999 +00:00',  -- Maximum value
        '2023-06-20 12:00:00 +14:00',          -- Maximum offset
        '2023-06-20 12:00:00 -14:00'           -- Minimum offset
    );
    EXEC InsertDateTimeOffsetTestResult 'DTO Edge Cases', 'Edge case datetime offset values', 'Edge values', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTimeOffsetTestResult 'DTO Edge Cases', 'Edge case datetime offset values', 'Edge values', NULL, 0;
END CATCH;
GO

-- Display results
SELECT * FROM DateTimeOffsetImplicitConversionTest ORDER BY ID;
GO

-- binary
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, 0x07E3061014223B, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:59 +01:00'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, ''2023-06-16 14:22:59 +01:00'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, ''2023-06-16 14:22:59 +01:00'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, N''2023-06-16 14:22:59 +01:00'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, N''2023-06-16 14:22:59 +01:00'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:59'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:00'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:59.1234567'' AS DATETIME2), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:59.1234567 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616142259 AS DECIMAL(14,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616142259 AS NUMERIC(14,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616142259 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616142259 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616142259 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616 AS INT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(2023 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(23 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(20230616.1422 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(2023.0616 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(''2023-06-16 14:22:59 +01:00'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIMEOFFSET, CAST(N''2023-06-16 14:22:59 +01:00'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(0x0C22380000000000 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS char(26)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS varchar(26)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS nchar(26)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS nvarchar(26)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('12:34:56' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS decimal(6,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS numeric(6,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(1234 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(12 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(123456 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(1234 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(0x0C22380000000000 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('2023-06-16 12:34:56' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) = CAST('<dateTimeOffset>2023-06-16T12:34:56.1234567+01:00</dateTimeOffset>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS char(26)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS varchar(26)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nchar(26)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nvarchar(26)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +02:00' AS datetimeoffset) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS decimal(6,0)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS float) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS real) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS int) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(12 AS tinyint) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS money) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(1 AS bit) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS image) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS text) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS ntext) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

SELECT CASE WHEN CAST('<dateTimeOffset>2023-06-16T12:34:56.1234567+01:00</dateTimeOffset>' AS xml) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(0x0000000000000000 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(0x0000000000000000 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('12:34:56' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS decimal(6,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS numeric(6,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(1234 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(12 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(123456 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(1234 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(0x0000000000000000 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <> CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS decimal(6,0)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS float) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS real) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS int) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(12 AS tinyint) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(123456 AS money) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(1 AS bit) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(0x0000000000000000 AS image) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

SELECT CASE WHEN CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(0x0000000000000000 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(0x0000000000000000 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('12:34:56' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Testing with different time zones
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +00:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 -08:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Numeric comparisons
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS decimal(6,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS numeric(6,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(1234 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(12 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(123456 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(1234 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Other data types
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(0x0000000000000000 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) < CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Date/Time types
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Different time zones
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +00:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 -08:00' AS DATETIMEOFFSET) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Numeric types
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS float) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS real) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS int) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(12 AS tinyint) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS money) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(1 AS bit) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Other types
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(0x0000000000000000 AS image) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AS sql_variant) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

SELECT CASE WHEN CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(0x0C22380000000000 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('12:34:56' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS decimal(6,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS numeric(6,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(1234 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(12 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(123456 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(1234 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(0x0C22380000000000 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) <= CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS decimal(6,0)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS float) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS real) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS int) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(12 AS tinyint) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS money) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(1 AS bit) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS image) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

SELECT CASE WHEN CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('12:34:56' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +02:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Numeric types
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS decimal(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS numeric(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(1234 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(12 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Money types
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(123456 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(1234 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Other types
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(0x0C22380000000000 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) > CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +02:00' AS datetimeoffset) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Numeric types
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS float) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS real) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(123456 AS int) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(12 AS tinyint) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Money types
SELECT CASE WHEN CAST(123456 AS money) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Other types
SELECT CASE WHEN CAST(1 AS bit) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS image) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

SELECT CASE WHEN CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with DATETIMEOFFSET on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('12:34:56' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Numeric type comparisons
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS decimal(6,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS numeric(6,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(1234 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(56 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Money comparisons
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(123456 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(1234 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Other types
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(0x0C22380000000000 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) >= CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with DATETIMEOFFSET on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS char(34)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS varchar(34)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nchar(34)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS nvarchar(34)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('12:34:56' AS time) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Numeric types
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS numeric(6,0)) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS float) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS real) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS bigint) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(123456 AS int) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallint) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(56 AS tinyint) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Money types
SELECT CASE WHEN CAST(123456 AS money) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(1234 AS smallmoney) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Other types
SELECT CASE WHEN CAST(1 AS bit) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(0x0C22380000000000 AS image) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS text) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS ntext) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) AS sql_variant) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

SELECT CASE WHEN CAST('<datetimeoffset>2023-06-16 12:34:56.1234567 +01:00</datetimeoffset>' AS xml) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator with DATETIMEOFFSET
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-06-16 14:29:00 +00:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 14:31:00 +00:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.123 +00:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-06-16 14:29:00.123 +00:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 14:31:00.123 +00:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567 +00:00' AS DATETIMEOFFSET(7)) 
        BETWEEN CAST('2023-06-16 14:29:00.1234567 +00:00' AS DATETIMEOFFSET(7)) 
        AND CAST('2023-06-16 14:31:00.1234567 +00:00' AS DATETIMEOFFSET(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Different precision tests for BETWEEN with different time zones
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567 +05:30' AS DATETIMEOFFSET(7)) 
        BETWEEN CAST('2023-06-16 14:30:00 +05:30' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 14:31:00 +05:30' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 -08:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-06-16 14:30:00.0000000 -08:00' AS DATETIMEOFFSET(7)) 
        AND CAST('2023-06-16 14:31:00.0000000 -08:00' AS DATETIMEOFFSET(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Edge cases for BETWEEN with time zones
SELECT CASE 
    WHEN CAST('2023-06-16 00:00:00 +00:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-06-15 23:59:59 +00:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 00:00:01 +00:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 23:59:59.9999999 +00:00' AS DATETIMEOFFSET(7)) 
        BETWEEN CAST('2023-06-16 23:59:59 +00:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-17 00:00:00 +00:00' AS DATETIMEOFFSET) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator with DATETIMEOFFSET
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) IN (
        CAST('2023-06-16 14:29:00 +00:00' AS DATETIMEOFFSET), 
        CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET), 
        CAST('2023-06-16 14:31:00 +00:00' AS DATETIMEOFFSET)
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- Different time zones in IN operator
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.123 +00:00' AS DATETIMEOFFSET(3)) IN (
        CAST('2023-06-16 20:00:00.123 +05:30' AS DATETIMEOFFSET(3)), 
        CAST('2023-06-16 14:30:00.123 +00:00' AS DATETIMEOFFSET(3)), 
        CAST('2023-06-16 06:30:00.123 -08:00' AS DATETIMEOFFSET(3))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- High precision with different time zones
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567 +00:00' AS DATETIMEOFFSET(7)) IN (
        CAST('2023-06-16 20:00:00.1234567 +05:30' AS DATETIMEOFFSET(7)), 
        CAST('2023-06-16 14:30:00.1234567 +00:00' AS DATETIMEOFFSET(7)), 
        CAST('2023-06-16 06:30:00.1234567 -08:00' AS DATETIMEOFFSET(7))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL with DATETIMEOFFSET
DECLARE @NullDateTimeOffset DATETIMEOFFSET;
SELECT CASE 
    WHEN @NullDateTimeOffset IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Additional precision tests with time zones
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) = 
         CAST('2023-06-16 14:30:00.0000000 +00:00' AS DATETIMEOFFSET(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Time zone conversion tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) = 
         CAST('2023-06-16 20:00:00 +05:30' AS DATETIMEOFFSET)
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Boundary tests with time zones
SELECT CASE 
    WHEN CAST('2023-06-16 00:00:00.0000000 +00:00' AS DATETIMEOFFSET(7)) 
        BETWEEN CAST('2023-06-16 00:00:00 -14:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 23:59:59.9999999 +14:00' AS DATETIMEOFFSET(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Fractional seconds tests with time zones
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567 +00:00' AS DATETIMEOFFSET(7)) 
        BETWEEN CAST('2023-06-16 14:30:00.1234566 +00:00' AS DATETIMEOFFSET(7)) 
        AND CAST('2023-06-16 14:30:00.1234568 +00:00' AS DATETIMEOFFSET(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Mixed precision comparisons with time zones
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +00:00' AS DATETIMEOFFSET) = 
         CAST('2023-06-16 14:30:00.000 +00:00' AS DATETIMEOFFSET(3))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Time zone offset boundary tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00 +14:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-06-16 14:30:00 -14:00' AS DATETIMEOFFSET) 
        AND CAST('2023-06-16 14:30:00 +14:00' AS DATETIMEOFFSET)
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- DST transition tests
SELECT CASE 
    WHEN CAST('2023-03-12 02:30:00 -08:00' AS DATETIMEOFFSET) 
        BETWEEN CAST('2023-03-12 02:00:00 -08:00' AS DATETIMEOFFSET) 
        AND CAST('2023-03-12 03:00:00 -07:00' AS DATETIMEOFFSET)
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Arithmetic operators
-- Addition with DATETIMEOFFSET on left side
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(0x07E30610 AS BINARY(8));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(0x07E30610 AS VARBINARY(8));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS CHAR(10));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS VARCHAR(10));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS NCHAR(10));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS NVARCHAR(10));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16' AS DATE);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:00' AS SMALLDATETIME);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('13:34:56' AS TIME);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:56.1234567 +02:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS DECIMAL(8,0));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS NUMERIC(8,0));
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS FLOAT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS REAL);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS BIGINT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS INT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS SMALLINT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS TINYINT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS MONEY);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS SMALLMONEY);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(1 AS BIT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(0x07E30610 AS IMAGE);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS TEXT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('1' AS NTEXT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('<number>1</number>' AS XML);
GO

-- Addition with DATETIMEOFFSET on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS CHAR(10)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS VARCHAR(10)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS NCHAR(10)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS NVARCHAR(10)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16 12:34:00' AS SMALLDATETIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('13:34:56' AS TIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('2023-06-16 12:34:56.1234567 +02:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS DECIMAL(8,0)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS NUMERIC(8,0)) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS FLOAT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS REAL) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS BIGINT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS INT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS SMALLINT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS TINYINT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS MONEY) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS SMALLMONEY) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(1 AS BIT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(0x07E30610 AS IMAGE) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS TEXT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('1' AS NTEXT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

SELECT CAST('<number>1</number>' AS XML) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

-- Subtraction with DATETIMEOFFSET on left side
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 11:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 11:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 11:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('11:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 11:34:56.1234567 +02:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with DATETIMEOFFSET on right side
SELECT CAST(0x07E30610 AS BINARY(8)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 13:34:56' AS DATETIME) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 13:34:00' AS SMALLDATETIME) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 13:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('13:34:56' AS TIME) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 13:34:56.1234567 +02:00' AS DATETIMEOFFSET) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS FLOAT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS REAL) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS BIGINT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS INT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS SMALLINT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS TINYINT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS MONEY) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(1 AS BIT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(0x07E30610 AS IMAGE) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS TEXT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('1' AS NTEXT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO

-- 4. DDL testing:

-- 1. Table column with DATETIMEOFFSET
CREATE TABLE DateTimeOffsetTest1 (
    ID INT PRIMARY KEY,
    DTOColumn DATETIMEOFFSET(7),  -- Maximum precision
    DefaultDTOColumn DATETIMEOFFSET DEFAULT SYSDATETIMEOFFSET(),
    ComputedDTOColumn AS DATEADD(hour, 1, DTOColumn),
    CHECK (DTOColumn > '2023-01-01 12:00:00 +00:00')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTimeOffsetTest1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table for DATETIMEOFFSET
CREATE PARTITION FUNCTION DTO_partition_func (DATETIMEOFFSET) 
    AS RANGE RIGHT FOR VALUES(
        '2023-01-01 06:00:00 +00:00', 
        '2023-01-01 12:00:00 +00:00', 
        '2023-01-01 18:00:00 +00:00'
    );
GO

CREATE PARTITION SCHEME DTO_partition_scheme
    AS PARTITION DTO_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE DTO_partition(
    a DATETIMEOFFSET(7),
    type VARCHAR(10))
ON DTO_partition_scheme(a);
GO

-- Insert test data for different time zones
INSERT INTO DTO_partition (a, type) VALUES ('2023-01-01 03:30:00 -08:00', 'PST');
GO
INSERT INTO DTO_partition (a, type) VALUES ('2023-01-01 09:30:00 -05:00', 'EST');
GO
INSERT INTO DTO_partition (a, type) VALUES ('2023-01-01 15:30:00 +00:00', 'UTC');
GO
INSERT INTO DTO_partition (a, type) VALUES ('2023-01-01 21:30:00 +08:00', 'CST');
GO

-- Query to show times in each partition
SELECT a, type, $PARTITION.DTO_partition_func(a) AS PartitionNumber
    FROM DTO_partition ORDER BY PartitionNumber, a, type;
GO

-- Query to show count of entries by partition
SELECT $PARTITION.DTO_partition_func(a) AS PartitionNumber, type, COUNT(*) AS DTOCount
    FROM DTO_partition
    GROUP BY $PARTITION.DTO_partition_func(a), type
    ORDER BY PartitionNumber, type;
GO

-- 3. Function returning DATETIMEOFFSET types
CREATE FUNCTION dbo.GetCurrentDTO()
RETURNS DATETIMEOFFSET
AS
BEGIN
    RETURN CAST('2023-01-01 14:30:00 +00:00' AS DATETIMEOFFSET);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentDTO' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes DATETIMEOFFSET types input
CREATE FUNCTION dbo.AddHoursToDTO(
    @InputDTO DATETIMEOFFSET,
    @HoursToAdd INT
)
RETURNS DATETIMEOFFSET
AS
BEGIN
    RETURN DATEADD(HOUR, @HoursToAdd, @InputDTO);
END;
GO

-- Test the function
SELECT dbo.AddHoursToDTO('2023-01-01 14:30:00 +00:00', 2) AS Result;
GO
SELECT dbo.AddHoursToDTO('2023-01-01 14:30:00 +00:00', -2) AS Result;
GO
SELECT dbo.AddHoursToDTO('2023-01-01 14:30:00 +00:00', 0) AS Result;
GO

-- 5. Procedure takes DATETIMEOFFSET types input
CREATE PROCEDURE dbo.ProcessDTO
    @InputDTO DATETIMEOFFSET
AS
BEGIN
    SELECT 
        @InputDTO AS Original,
        DATEADD(HOUR, 1, @InputDTO) AS NextHour,
        SWITCHOFFSET(@InputDTO, '+00:00') AS UTC,
        SWITCHOFFSET(@InputDTO, '-08:00') AS PST;
END;
GO

-- 6. Constraints
ALTER TABLE DateTimeOffsetTest1
ADD CONSTRAINT DF_DTOTest_DefaultDTOColumn 
    DEFAULT '2023-01-01 00:00:00 +00:00' FOR DefaultDTOColumn;

ALTER TABLE DateTimeOffsetTest1
ADD CONSTRAINT CK_DTOTest_DTOColumn 
    CHECK (DTOColumn > '2023-01-01 00:00:00 +00:00');

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'DateTimeOffsetTest1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key columns
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'DateTimeOffsetTest1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views
CREATE VIEW dbo.DTOView
AS
SELECT
    ID,
    DTOColumn,
    DefaultDTOColumn,
    ComputedDTOColumn,
    SWITCHOFFSET(DTOColumn, '+00:00') AS UTCTime,
    SWITCHOFFSET(DTOColumn, '-08:00') AS PSTTime,
    SWITCHOFFSET(DTOColumn, '+01:00') AS CESTTime
FROM DateTimeOffsetTest1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DTOView' ORDER BY COLUMN_NAME;
GO

-- Insert test data with different precisions and time zones
INSERT INTO DateTimeOffsetTest1 (ID, DTOColumn) VALUES 
(1, '2023-01-01 14:30:00 +00:00'),
(2, '2023-01-01 14:30:00.1 -08:00'),
(3, '2023-01-01 14:30:00.12 +01:00'),
(4, '2023-01-01 14:30:00.123 +05:30'),
(5, '2023-01-01 14:30:00.1234 -05:00'),
(6, '2023-01-01 14:30:00.12345 +08:00'),
(7, '2023-01-01 14:30:00.123456 +02:00'),
(8, '2023-01-01 14:30:00.1234567 -11:00');
GO

-- Test time zone specific operations
SELECT 
    DTOColumn,
    SWITCHOFFSET(DTOColumn, '+00:00') AS UTC,
    SWITCHOFFSET(DTOColumn, '-08:00') AS PST,
    SWITCHOFFSET(DTOColumn, '+01:00') AS CET,
    TODATETIMEOFFSET(DATEADD(HOUR, 1, DTOColumn), '+00:00') AS UTC_Plus1Hour
FROM DateTimeOffsetTest1;
GO

-- Test different time zone formats
INSERT INTO DateTimeOffsetTest1 (ID, DTOColumn) VALUES 
(9, '2023-01-01 14:30:00 +00:00'),
(10, '2023-01-01 14:30:00 -08:00'),
(11, '2023-01-01 14:30:00 +05:30'),
(12, '2023-01-01 14:30:00 +13:00');
GO

-- Test boundary conditions
INSERT INTO DateTimeOffsetTest1 (ID, DTOColumn) VALUES 
(13, '0001-01-01 00:00:00 +00:00'),
(14, '9999-12-31 23:59:59.9999999 +00:00');
GO

-- Test invalid values (these should fail)
INSERT INTO DateTimeOffsetTest1 (ID, DTOColumn) VALUES 
(15, '2023-01-01 24:00:00 +00:00')
GO

-- Test time zone arithmetic and comparisons
SELECT 
    a.DTOColumn,
    b.DTOColumn,
    DATEDIFF(HOUR, a.DTOColumn, b.DTOColumn) AS HourDiff,
    CASE 
        WHEN SWITCHOFFSET(a.DTOColumn, '+00:00') = SWITCHOFFSET(b.DTOColumn, '+00:00')
        THEN 'Same UTC time'
        ELSE 'Different UTC time'
    END AS UTCComparison
FROM DateTimeOffsetTest1 a
CROSS JOIN DateTimeOffsetTest1 b
WHERE a.ID < b.ID AND a.ID <= 5;
GO

-- Test all the objects we created
SELECT * FROM DateTimeOffsetTest1;
GO
SELECT * FROM DTO_partition ORDER BY type;
GO
SELECT dbo.GetCurrentDTO() AS CurrentDTO;
GO
SELECT dbo.AddHoursToDTO('2023-01-01 14:30:00 +00:00', 2) AS DTOAfter2Hours;
GO
EXEC dbo.ProcessDTO @InputDTO = '2023-01-01 14:30:00 +00:00';
GO
SELECT * FROM dbo.DTOView;
GO

-- 5. DML testing:
-- Create test tables for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetDMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleDTO DATETIMEOFFSET,
    DefaultDTO DATETIMEOFFSET DEFAULT NULL,
    ComputedDTO AS DATEADD(minute, 30, SimpleDTO),
    Description NVARCHAR(100)
);
GO

CREATE TABLE DateTimeOffsetDMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildDTO DATETIMEOFFSET,
    FOREIGN KEY (ParentID) REFERENCES DateTimeOffsetDMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description) 
VALUES ('2023-06-16 14:30:20.1234567 +00:00', 'Single row insertion');
GO

-- Bulk insertion with different time zones
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES 
('2023-06-16 09:15:00 -08:00', 'Bulk insertion PST'),
('2023-06-16 12:30:45.123 -05:00', 'Bulk insertion EST'),
('2023-06-16 17:45:30.5567 +01:00', 'Bulk insertion CET');
GO

-- Insert with type casting
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES (CAST('2023-06-16 14:30:20 +00:00' AS DATETIMEOFFSET), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES (DATEADD(minute, 30, CAST('2023-06-16 14:30:20 +00:00' AS DATETIMEOFFSET)), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, DefaultDTO, Description)
VALUES ('2023-06-16 15:45:00 +00:00', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM DateTimeOffsetDMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = '2023-06-16 16:00:00 +00:00'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = '2023-06-16 16:30:00 +00:00',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = DATEADD(hour, 1, SimpleDTO)
WHERE ID = 3;
GO

-- Mass update
UPDATE DateTimeOffsetDMLTest
SET Description = 'Mass updated';
GO

-- Conditional update
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = '2023-06-16 09:00:00 +00:00'
WHERE SimpleDTO < '2023-06-16 12:00:00 +00:00';
GO

-- Verify updates
SELECT * FROM DateTimeOffsetDMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO DateTimeOffsetDMLTestChild (ParentID, ChildDTO)
VALUES 
(1, '2023-06-16 09:00:00 +00:00'),
(2, '2023-06-16 10:15:30 -07:00'),
(3, '2023-06-16 11:45:00 +01:00'),
(4, '2023-06-16 13:20:15 +05:30'),
(5, '2023-06-16 15:00:00 +08:00');
GO

-- Single row deletion
DELETE FROM DateTimeOffsetDMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM DateTimeOffsetDMLTest;
GO

-- Conditional deletion
DELETE FROM DateTimeOffsetDMLTest 
WHERE SimpleDTO < '2023-06-16 12:00:00 +00:00';
GO

-- Cascade deletion
DELETE FROM DateTimeOffsetDMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM DateTimeOffsetDMLTest ORDER BY ID;
SELECT * FROM DateTimeOffsetDMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES ('2023-06-16 14:00:00 +00:00', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleDTO, ComputedDTO, Description
FROM DateTimeOffsetDMLTest
WHERE SimpleDTO = '2023-06-16 14:00:00 +00:00';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE DateTimeOffsetDMLTest
    SET ComputedDTO = '2023-06-16 15:00:00 +00:00'
    WHERE SimpleDTO = '2023-06-16 14:00:00 +00:00';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = '2023-06-16 15:00:00 +00:00'
WHERE SimpleDTO = '2023-06-16 14:00:00 +00:00';
GO

-- 5. Additional DML scenarios

-- Insert with different time zones
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES 
('2023-06-16 13:30:00 +00:00', 'UTC'),
('2023-06-16 13:30:00 -07:00', 'PDT'),
('2023-06-16 13:30:00 +05:30', 'IST'),
('2023-06-16 13:30:00 +08:00', 'CST'),
('2023-06-16 13:30:00 +10:00', 'AEST');
GO

-- Insert with subquery and time zone conversion
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
SELECT 
    DATEADD(hour, 1, MAX(SimpleDTO)), 
    'Inserted from subquery'
FROM DateTimeOffsetDMLTest;
GO

-- Update with time zone conversion
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = SimpleDTO AT TIME ZONE 'UTC' AT TIME ZONE 'Pacific Standard Time'
WHERE ID IN (SELECT TOP 1 ID FROM DateTimeOffsetDMLTest ORDER BY ID);
GO

-- Test boundary values
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES 
('0001-01-01 00:00:00 +00:00', 'Minimum date'),
('9999-12-31 23:59:59.9999999 +00:00', 'Maximum date'),
('2023-06-16 00:00:00 +00:00', 'Midnight UTC'),
('2023-06-16 23:59:59.9999999 +00:00', 'Last moment UTC');
GO

-- Test DST transitions
INSERT INTO DateTimeOffsetDMLTest (SimpleDTO, Description)
VALUES 
('2023-03-12 01:59:59 -08:00', 'Before DST Spring Forward'),
('2023-03-12 03:00:00 -07:00', 'After DST Spring Forward'),
('2023-11-05 01:59:59 -07:00', 'Before DST Fall Back'),
('2023-11-05 01:00:00 -08:00', 'After DST Fall Back');
GO

-- Test time zone arithmetic
UPDATE DateTimeOffsetDMLTest
SET SimpleDTO = DATEADD(hour, 
                       DATEPART(HOUR, SimpleDTO AT TIME ZONE 'UTC') - 
                       DATEPART(HOUR, SimpleDTO),
                       SimpleDTO)
WHERE ID IN (SELECT TOP 1 ID FROM DateTimeOffsetDMLTest ORDER BY ID);
GO

-- Test time zone comparisons
DELETE FROM DateTimeOffsetDMLTest
WHERE SimpleDTO AT TIME ZONE 'UTC' 
    BETWEEN '2023-06-16 12:00:00 +00:00' AND '2023-06-16 13:00:00 +00:00';
GO

-- Final verification
SELECT 
    ID,
    SimpleDTO,
    SimpleDTO AT TIME ZONE 'UTC' as UTC_Time,
    Description
FROM DateTimeOffsetDMLTest
ORDER BY ID, SimpleDTO AT TIME ZONE 'UTC';
GO

SELECT * FROM DateTimeOffsetDMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetIndexTest (
    ID INT IDENTITY PRIMARY KEY,
    DTOColumn DATETIMEOFFSET(7),
    DTOColumn2 DATETIMEOFFSET(7),
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data
INSERT INTO DateTimeOffsetIndexTest (DTOColumn, DTOColumn2, Description, NumericColumn)
VALUES 
('2023-01-01 00:00:00 +00:00', '2023-01-01 12:00:00 +00:00', 'Midnight to Noon UTC', 1),
('2023-01-01 06:15:30.1234567 +01:00', '2023-01-01 18:15:30.1234567 +01:00', 'Morning to Evening CET', 2),
('2023-01-01 09:30:45.5555555 -05:00', '2023-01-01 21:30:45.5555555 -05:00', 'Work hours EST', 3),
('2023-01-01 12:45:15.7777777 +05:30', '2023-01-01 23:45:15.7777777 +05:30', 'Lunch time IST', 4),
('2023-01-01 15:20:10.9999999 +08:00', '2023-01-02 03:20:10.9999999 +08:00', 'Afternoon CST', 5);
GO

-- 1. Index on single column
CREATE INDEX IX_DateTimeOffsetTest_DTOColumn 
ON DateTimeOffsetIndexTest(DTOColumn);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest 
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple columns
CREATE INDEX IX_DateTimeOffsetTest_DTOColumn_DTOColumn2 
ON DateTimeOffsetIndexTest(DTOColumn, DTOColumn2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest 
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00' 
AND DTOColumn2 = '2023-01-01 12:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 3. Usability of index with different operators

-- Equality with timezone conversion
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest 
WHERE DTOColumn AT TIME ZONE 'UTC' = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- IN with multiple timezones
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest 
WHERE DTOColumn IN (
    '2023-01-01 00:00:00 +00:00',
    '2023-01-01 06:15:30.1234567 +01:00',
    '2023-01-01 12:00:00 +00:00'
) ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Timezone conversion scenarios
SET STATISTICS IO ON;
SELECT *,
    DTOColumn AT TIME ZONE 'UTC' AS UTCTime,
    DTOColumn AT TIME ZONE 'Pacific Standard Time' AS PSTTime
FROM DateTimeOffsetIndexTest
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 5. DML operations with indexes

-- INSERT with timezone
SET STATISTICS IO ON;
INSERT INTO DateTimeOffsetIndexTest (DTOColumn, DTOColumn2, Description, NumericColumn)
VALUES ('2023-01-01 18:30:00 +00:00', '2023-01-02 06:30:00 +00:00', 'Evening UTC', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE with timezone conversion
SET STATISTICS IO ON;
UPDATE DateTimeOffsetIndexTest 
SET DTOColumn = CAST(DTOColumn AT TIME ZONE 'Pacific Standard Time' AS DATETIMEOFFSET)
WHERE DTOColumn = '2023-01-01 18:30:00 +00:00';
SET STATISTICS IO OFF;
GO

-- DELETE with timezone consideration
SET STATISTICS IO ON;
DELETE FROM DateTimeOffsetIndexTest 
WHERE DTOColumn AT TIME ZONE 'UTC' = '2023-01-01 19:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Filtered index for specific timezone
CREATE INDEX IX_DateTimeOffsetTest_Filtered ON DateTimeOffsetIndexTest(DTOColumn)
WHERE DATEPART(HOUR, DTOColumn AT TIME ZONE 'UTC') BETWEEN 9 AND 17;
GO

-- Index with included columns
CREATE INDEX IX_DateTimeOffsetTest_DTOColumn_Include 
ON DateTimeOffsetIndexTest(DTOColumn)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT DTOColumn, Description, NumericColumn 
FROM DateTimeOffsetIndexTest 
WHERE DTOColumn = '2023-01-01 09:30:45.5555555 -05:00';
SET STATISTICS IO OFF;
GO

-- 7. Timezone-specific functions

-- SWITCHOFFSET function
SET STATISTICS IO ON;
SELECT *, SWITCHOFFSET(DTOColumn, '+05:30') AS IndianTime
FROM DateTimeOffsetIndexTest
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- TODATETIMEOFFSET function
SET STATISTICS IO ON;
SELECT *
FROM DateTimeOffsetIndexTest
WHERE DTOColumn = TODATETIMEOFFSET('2023-01-01 00:00:00', '+00:00');
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest WITH (INDEX(IX_DateTimeOffsetTest_DTOColumn))
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest WITH (INDEX(0))
WHERE DTOColumn = '2023-01-01 00:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 9. Timezone-specific scenarios

-- Precision comparisons with timezone
SET STATISTICS IO ON;
SELECT * FROM DateTimeOffsetIndexTest 
WHERE DTOColumn = '2023-01-01 06:15:30.1234567 +01:00';
SET STATISTICS IO OFF;
GO

-- DST transition handling
SET STATISTICS IO ON;
SELECT *, 
    DTOColumn AT TIME ZONE 'Pacific Standard Time' AS PSTTime
FROM DateTimeOffsetIndexTest 
WHERE DTOColumn BETWEEN '2023-03-12 00:00:00 -08:00' AND '2023-03-12 04:00:00 -07:00';
SET STATISTICS IO OFF;
GO

-- Timezone arithmetic
SET STATISTICS IO ON;
SELECT *, 
    DATEADD(HOUR, 1, DTOColumn) AS HourLater,
    DATEADD(MINUTE, -30, DTOColumn) AS HalfHourEarlier
FROM DateTimeOffsetIndexTest 
WHERE DTOColumn = '2023-01-01 12:00:00 +00:00';
SET STATISTICS IO OFF;
GO

-- 7. Expression Testing:
-- Create test table for DATETIMEOFFSET
CREATE TABLE DateTimeOffsetExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    DTOColumn DATETIMEOFFSET(7),
    NullableDTOColumn DATETIMEOFFSET(7) NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data with various time zones
INSERT INTO DateTimeOffsetExpressionTest (DTOColumn, NullableDTOColumn, Description)
VALUES 
('2023-01-01 00:00:00 +00:00', '2023-01-01 00:00:00 +00:00', 'UTC Midnight'),
('2023-01-01 06:00:00 -08:00', '2023-01-01 06:00:00 -08:00', 'PST Morning'),
('2023-01-01 09:30:00 -05:00', NULL, 'EST Morning Break'),
('2023-01-01 12:00:00 +00:00', '2023-01-01 12:00:00 +00:00', 'UTC Noon'),
('2023-01-01 13:30:00 +01:00', NULL, 'CET Afternoon Break'),
('2023-01-01 15:45:30.1234567 +02:00', '2023-01-01 15:45:30.1234567 +02:00', 'EET Late Afternoon'),
('2023-01-01 17:30:00 +05:30', '2023-01-01 17:30:00 +05:30', 'IST End of Day'),
('2023-01-01 18:15:00 +08:00', NULL, 'CST Evening'),
('2023-01-01 20:00:00 +09:00', '2023-01-01 20:00:00 +09:00', 'JST Night'),
('2023-01-01 21:30:45.9876543 +10:00', '2023-01-01 21:30:45.9876543 +10:00', 'AEST Late Night'),
('2023-01-01 22:45:00 +11:00', NULL, 'AEDT Late Night'),
('2023-01-01 23:59:59.9999999 +12:00', '2023-01-01 23:59:59.9999999 +12:00', 'NZST Almost Midnight');
GO

-- 1. Conditional Expressions

-- CASE statements with timezone consideration
SELECT 
    DTOColumn,
    CASE 
        WHEN DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), CAST(DTOColumn AS DATETIME2)) 
            BETWEEN '06:00' AND '11:59' THEN 'Morning'
        WHEN DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), CAST(DTOColumn AS DATETIME2)) 
            BETWEEN '12:00' AND '16:59' THEN 'Afternoon'
        WHEN DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), CAST(DTOColumn AS DATETIME2)) 
            BETWEEN '17:00' AND '20:59' THEN 'Evening'
        ELSE 'Night'
    END AS LocalTimeOfDay,
    Description
FROM DateTimeOffsetExpressionTest ORDER BY ID;
GO

-- COALESCE with timezone awareness
SELECT 
    ID,
    COALESCE(NullableDTOColumn, DTOColumn, '2023-01-01 00:00:00 +00:00') AS CoalescedDTO,
    Description
FROM DateTimeOffsetExpressionTest;
GO

-- NULLIF operations with timezone consideration
SELECT 
    ID,
    NULLIF(DTOColumn, '2023-01-01 00:00:00 +00:00') AS NullIfUTCMidnight,
    Description
FROM DateTimeOffsetExpressionTest ORDER BY ID;
GO

-- IIF statements with timezone awareness
SELECT 
    DTOColumn,
    IIF(DATEPART(HOUR, DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn)) < 12, 'AM', 'PM') AS LocalAMPM,
    Description
FROM DateTimeOffsetExpressionTest ORDER BY ID;
GO

-- 2. Aggregate Expressions

-- MAX with timezone consideration
SELECT MAX(DTOColumn) AS LatestGlobalTime FROM DateTimeOffsetExpressionTest;
GO

-- MIN with timezone consideration
SELECT MIN(DTOColumn) AS EarliestGlobalTime FROM DateTimeOffsetExpressionTest;
GO

-- UNIONS with timezone awareness
SELECT DTOColumn 
FROM DateTimeOffsetExpressionTest 
WHERE DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn) < '2023-01-01 12:00:00'
UNION
SELECT DTOColumn 
FROM DateTimeOffsetExpressionTest 
WHERE DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn) > '2023-01-01 20:00:00'
ORDER BY DTOColumn;
GO

-- COUNT with timezone consideration
SELECT 
    COUNT(DTOColumn) AS TotalTimes, 
    COUNT(DISTINCT DTOColumn) AS UniqueTimes 
FROM DateTimeOffsetExpressionTest;
GO

-- 3. Additional Expression Tests

-- Time arithmetic with timezone awareness
SELECT 
    DTOColumn,
    DATEADD(HOUR, 1, DTOColumn) AS OneHourLater,
    DATEADD(MINUTE, 30, DTOColumn) AS ThirtyMinutesLater,
    DATEADD(SECOND, 15, DTOColumn) AS FifteenSecondsLater
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- Time parts with timezone consideration
SELECT 
    DTOColumn,
    DATEPART(HOUR, DTOColumn) AS UTCHour,
    DATEPART(MINUTE, DTOColumn) AS Minute,
    DATEPART(SECOND, DTOColumn) AS Second,
    DATEPART(MILLISECOND, DTOColumn) AS Millisecond,
    DATEPART(MICROSECOND, DTOColumn) AS Microsecond,
    DATEPART(NANOSECOND, DTOColumn) AS Nanosecond,
    DATEPART(TZOFFSET, DTOColumn) AS TimezoneOffsetHours
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- Time differences with timezone awareness
SELECT 
    t1.DTOColumn AS Time1,
    t2.DTOColumn AS Time2,
    DATEDIFF(HOUR, t1.DTOColumn, t2.DTOColumn) AS HoursDiff,
    DATEDIFF(MINUTE, t1.DTOColumn, t2.DTOColumn) AS MinutesDiff,
    DATEDIFF(SECOND, t1.DTOColumn, t2.DTOColumn) AS SecondsDiff
FROM DateTimeOffsetExpressionTest t1
CROSS JOIN DateTimeOffsetExpressionTest t2
WHERE t1.ID < t2.ID ORDER BY t2.DTOColumn;
GO

-- Complex conditional expressions with timezone awareness
SELECT 
    DTOColumn,
    CASE 
        WHEN DATEPART(HOUR, DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn)) 
            BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn)) 
            BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, DATEADD(HOUR, DATEPART(TZOFFSET, DTOColumn), DTOColumn)) 
            BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS LocalTimeOfDay,
    DATEPART(TZOFFSET, DTOColumn) AS TimezoneOffset
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- Window functions with timezone awareness
SELECT 
    DTOColumn,
    Description,
    LAG(DTOColumn) OVER (ORDER BY DTOColumn) AS PreviousTime,
    LEAD(DTOColumn) OVER (ORDER BY DTOColumn) AS NextTime,
    DATEDIFF(MINUTE, 
        LAG(DTOColumn) OVER (ORDER BY DTOColumn), 
        DTOColumn) AS MinutesSincePreviousTime
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- Time grouping and aggregation with timezone consideration
SELECT 
    DATEPART(TZOFFSET, DTOColumn) AS TimezoneOffset,
    COUNT(*) AS TimeCount,
    MIN(DTOColumn) AS EarliestTime,
    MAX(DTOColumn) AS LatestTime
FROM DateTimeOffsetExpressionTest
GROUP BY DATEPART(TZOFFSET, DTOColumn)
ORDER BY TimezoneOffset;
GO

-- Precision tests for DATETIMEOFFSET
SELECT 
    DTOColumn,
    CAST(DTOColumn AS DATETIMEOFFSET(0)) AS Precision0,
    CAST(DTOColumn AS DATETIMEOFFSET(1)) AS Precision1,
    CAST(DTOColumn AS DATETIMEOFFSET(2)) AS Precision2,
    CAST(DTOColumn AS DATETIMEOFFSET(3)) AS Precision3,
    CAST(DTOColumn AS DATETIMEOFFSET(4)) AS Precision4,
    CAST(DTOColumn AS DATETIMEOFFSET(5)) AS Precision5,
    CAST(DTOColumn AS DATETIMEOFFSET(6)) AS Precision6,
    CAST(DTOColumn AS DATETIMEOFFSET(7)) AS Precision7
FROM DateTimeOffsetExpressionTest
WHERE DATEPART(HOUR, DTOColumn) > 21 ORDER BY DTOColumn;
GO

-- Timezone conversion tests
SELECT 
    DTOColumn,
    SWITCHOFFSET(DTOColumn, '+00:00') AS ConvertedToUTC,
    SWITCHOFFSET(DTOColumn, '-08:00') AS ConvertedToPST,
    SWITCHOFFSET(DTOColumn, '+05:30') AS ConvertedToIST
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- Error handling tests
BEGIN TRY
    DECLARE @dto DATETIMEOFFSET = '2023-01-01 24:00:00 +00:00';
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

-- Format conversion tests with timezone awareness
SELECT 
    DTOColumn,
    FORMAT(DTOColumn, 'yyyy-MM-dd HH:mm:ss zzz') AS StandardFormat,
    FORMAT(SWITCHOFFSET(DTOColumn, '+00:00'), 'yyyy-MM-dd HH:mm:ss') AS UTCFormat
FROM DateTimeOffsetExpressionTest;
GO

-- Timezone arithmetic and conversions
SELECT 
    DTOColumn,
    SWITCHOFFSET(DTOColumn, '+00:00') AS UTC,
    DATEADD(HOUR, -8, SWITCHOFFSET(DTOColumn, '-08:00')) AS PST_Minus8Hours,
    DATEADD(HOUR, 5, SWITCHOFFSET(DTOColumn, '+05:30')) AS IST_Plus5Hours
FROM DateTimeOffsetExpressionTest ORDER BY DTOColumn;
GO

-- 10. Additional Tests:

-- Test DATE_BUCKET function with DATETIMEOFFSET
DECLARE @dto DATETIMEOFFSET = '2023-06-16 14:30:20.1234567 +01:00';
SELECT DATE_BUCKET(HOUR, 1, @dto), DATE_BUCKET(MINUTE, 1, @dto), DATE_BUCKET(SECOND, 1, @dto);
GO

-- Test with different precisions
SELECT 
    CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET) AS [Default],
    CAST('2023-06-16 14:30:20.1 +01:00' AS DATETIMEOFFSET(1)) AS [1 digit],
    CAST('2023-06-16 14:30:20.12 +01:00' AS DATETIMEOFFSET(2)) AS [2 digits],
    CAST('2023-06-16 14:30:20.123 +01:00' AS DATETIMEOFFSET(3)) AS [3 digits],
    CAST('2023-06-16 14:30:20.1234 +01:00' AS DATETIMEOFFSET(4)) AS [4 digits],
    CAST('2023-06-16 14:30:20.12345 +01:00' AS DATETIMEOFFSET(5)) AS [5 digits],
    CAST('2023-06-16 14:30:20.123456 +01:00' AS DATETIMEOFFSET(6)) AS [6 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(7)) AS [7 digits];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(DATETIMEOFFSET, '2023-06-16 14:30:20 +01:00', 127),    -- ISO with timezone
    CONVERT(DATETIMEOFFSET, '2023-06-16 02:30:20 PM +01:00', 100), -- AM/PM with timezone
    CONVERT(DATETIMEOFFSET, '2023-06-16 14.30.20 +01:00', 104);    -- European format with timezone
GO

-- Test AM/PM formats
SELECT 
    CAST('2023-06-16 2:30:20 PM +01:00' AS DATETIMEOFFSET) AS [PM time],
    CAST('2023-06-16 2:30:20 AM +01:00' AS DATETIMEOFFSET) AS [AM time],
    CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET) AS [24-hour format];
GO

-- Test with different separators
SELECT 
    CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET) AS [Colon separator],
    CAST('2023-06-16 14.30.20 +01:00' AS DATETIMEOFFSET) AS [Period separator],
    CAST('2023-06-16 14 30 20 +01:00' AS DATETIMEOFFSET) AS [Space separator];
GO

-- Test time arithmetic
DECLARE @dto DATETIMEOFFSET = '2023-06-16 14:30:20.1234567 +01:00';
SELECT 
    DATEADD(HOUR, 1, @dto) AS [Add 1 hour],
    DATEADD(HOUR, -1, @dto) AS [Subtract 1 hour],
    DATEADD(MINUTE, 30, @dto) AS [Add 30 minutes],
    DATEADD(SECOND, 15, @dto) AS [Add 15 seconds],
    DATEADD(MILLISECOND, 500, @dto) AS [Add 500 milliseconds];
GO

-- Test time extraction
DECLARE @dto DATETIMEOFFSET = '2023-06-16 14:30:20.1234567 +01:00';
SELECT 
    DATEPART(HOUR, @dto) AS [Hour],
    DATEPART(MINUTE, @dto) AS [Minute],
    DATEPART(SECOND, @dto) AS [Second],
    DATEPART(MILLISECOND, @dto) AS [Millisecond],
    DATEPART(MICROSECOND, @dto) AS [Microsecond],
    DATEPART(NANOSECOND, @dto) AS [Nanosecond],
    DATEPART(TZOFFSET, @dto) AS [TimeZoneOffset];
GO

-- Test with SET LANGUAGE (for AM/PM format)
SET LANGUAGE Italian;
SELECT CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET);
SET LANGUAGE English;
SELECT CAST('2023-06-16 2:30:20 PM +01:00' AS DATETIMEOFFSET);
GO

-- Test range
SELECT 
    CAST('0001-01-01 00:00:00.0000000 -14:00' AS DATETIMEOFFSET(7)) AS [Minimum DTO],
    CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET(7)) AS [Maximum DTO];
GO

-- Test rounding behavior
SELECT 
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(7)) AS [7 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(6)) AS [6 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(5)) AS [5 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(4)) AS [4 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(3)) AS [3 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(2)) AS [2 digits],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(1)) AS [1 digit],
    CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET(0)) AS [0 digits];
GO

-- Test invalid formats (these should fail)
SELECT CAST('2023-06-16 25:00:00 +01:00' AS DATETIMEOFFSET);  -- Invalid hour
GO
SELECT CAST('2023-06-16 14:60:00 +01:00' AS DATETIMEOFFSET);  -- Invalid minute
GO
SELECT CAST('2023-06-16 14:30:60 +01:00' AS DATETIMEOFFSET);  -- Invalid second
GO

-- Test timezone offset variations
SELECT 
    CAST('2023-06-16 14:30:20 +00:00' AS DATETIMEOFFSET) AS [UTC],
    CAST('2023-06-16 14:30:20 +01:00' AS DATETIMEOFFSET) AS [UTC+1],
    CAST('2023-06-16 14:30:20 -08:00' AS DATETIMEOFFSET) AS [UTC-8],
    CAST('2023-06-16 14:30:20 +05:30' AS DATETIMEOFFSET) AS [UTC+5:30],
    CAST('2023-06-16 14:30:20 -03:30' AS DATETIMEOFFSET) AS [UTC-3:30];
GO

-- Test timezone conversions
DECLARE @dto DATETIMEOFFSET = '2023-06-16 14:30:20.1234567 +01:00';
SELECT 
    @dto AS [Original],
    @dto AT TIME ZONE 'UTC' AS [UTC],
    @dto AT TIME ZONE 'Pacific Standard Time' AS [PST],
    @dto AT TIME ZONE 'Eastern Standard Time' AS [EST],
    @dto AT TIME ZONE 'Tokyo Standard Time' AS [JST];
GO

-- Test DST transitions
SELECT 
    CAST('2023-03-12 01:30:00 -08:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS [DST Start],
    CAST('2023-11-05 01:30:00 -07:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS [DST End];
GO

-- Test with different precision levels and DATEADD
DECLARE @dto DATETIMEOFFSET(7) = '2023-06-16 14:30:20.1234567 +01:00';
SELECT 
    DATEADD(NANOSECOND, 1, @dto) AS [Add 1 nanosecond],
    DATEADD(MICROSECOND, 1, @dto) AS [Add 1 microsecond],
    DATEADD(MILLISECOND, 1, @dto) AS [Add 1 millisecond];
GO

-- Test date/time boundary cases
SELECT 
    CAST('2023-06-16 23:30:00 +01:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS [Day boundary],
    CAST('2023-12-31 23:30:00 +01:00' AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS [Year boundary];
GO

-- Test ISO 8601 format
SELECT 
    CAST('2023-06-16T14:30:20.1234567+01:00' AS DATETIMEOFFSET) AS [ISO format],
    CAST('20230616T143020.1234567+0100' AS DATETIMEOFFSET) AS [ISO compact format];
GO

-- Create a test table for DATETIMEOFFSET precision testing
CREATE TABLE DateTimeOffsetScaleTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    DateTimeOffsetValue DATETIMEOFFSET(7),
    Scale INT,
    Precision INT,
    StorageBytes INT,
    FractionalPrecision INT,
    FormattedValue NVARCHAR(50),
    TimeZoneOffset NVARCHAR(10)
);
GO

-- Helper function to calculate storage bytes for DATETIMEOFFSET
CREATE FUNCTION CalculateDateTimeOffsetStorageBytes(@scale INT)
RETURNS INT
AS
BEGIN
    RETURN CASE 
        WHEN @scale <= 2 THEN 8
        WHEN @scale <= 4 THEN 9
        ELSE 10
    END;
END;
GO

-- Helper procedure for testing DATETIMEOFFSET scales
CREATE PROCEDURE TestDateTimeOffsetScale
    @description NVARCHAR(100),
    @dateTimeOffsetStr NVARCHAR(50),
    @scale INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @dateTimeOffsetValue DATETIMEOFFSET(7);
    DECLARE @precision INT;
    DECLARE @fractionalPrecision INT;
    
    SET @sql = N'DECLARE @dto DATETIMEOFFSET(' + CAST(@scale AS NVARCHAR(1)) + ') = ''' + @dateTimeOffsetStr + ''';';
    SET @sql += N'SELECT @dtov = CAST(@dto AS DATETIMEOFFSET(7));';
    
    BEGIN TRY
        EXEC sp_executesql @sql, N'@dtov DATETIMEOFFSET(7) OUTPUT', @dtov = @dateTimeOffsetValue OUTPUT;
        
        -- Calculate precision based on scale
        SET @precision = CASE @scale
            WHEN 0 THEN 19
            WHEN 1 THEN 21
            WHEN 2 THEN 22
            WHEN 3 THEN 23
            WHEN 4 THEN 24
            WHEN 5 THEN 25
            WHEN 6 THEN 26
            WHEN 7 THEN 27
        END;
        
        -- Calculate fractional precision
        SET @fractionalPrecision = CASE 
            WHEN @scale <= 2 THEN 2
            WHEN @scale <= 4 THEN 4
            ELSE 7
        END;
        
        INSERT INTO DateTimeOffsetScaleTest (
            Description, 
            DateTimeOffsetValue, 
            Scale, 
            Precision, 
            StorageBytes, 
            FractionalPrecision,
            FormattedValue,
            TimeZoneOffset
        )
        VALUES (
            @description,
            @dateTimeOffsetValue,
            @scale,
            @precision,
            dbo.CalculateDateTimeOffsetStorageBytes(@scale),
            @fractionalPrecision,
            CONVERT(NVARCHAR(50), @dateTimeOffsetValue, 127),
            RIGHT(@dateTimeOffsetStr, 6)
        );
        
        PRINT 'Success: ' + @description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @description + ' - ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Test cases for each scale with different time zones
-- Scale 0 (8 bytes)
EXEC TestDateTimeOffsetScale 'DTO(0) UTC', '2023-06-16 14:30:20 +00:00', 0;
GO
EXEC TestDateTimeOffsetScale 'DTO(0) PST', '2023-06-16 14:30:20 -07:00', 0;
GO
EXEC TestDateTimeOffsetScale 'DTO(0) IST', '2023-06-16 14:30:20 +05:30', 0;
GO

-- Scale 1 (8 bytes)
EXEC TestDateTimeOffsetScale 'DTO(1) UTC', '2023-06-16 14:30:20.1 +00:00', 1;
GO
EXEC TestDateTimeOffsetScale 'DTO(1) PST', '2023-06-16 14:30:20.1 -07:00', 1;
GO
EXEC TestDateTimeOffsetScale 'DTO(1) IST', '2023-06-16 14:30:20.1 +05:30', 1;
GO

-- Scale 2 (8 bytes)
EXEC TestDateTimeOffsetScale 'DTO(2) UTC', '2023-06-16 14:30:20.12 +00:00', 2;
GO
EXEC TestDateTimeOffsetScale 'DTO(2) PST', '2023-06-16 14:30:20.12 -07:00', 2;
GO
EXEC TestDateTimeOffsetScale 'DTO(2) IST', '2023-06-16 14:30:20.12 +05:30', 2;
GO

-- Scale 3 (9 bytes)
EXEC TestDateTimeOffsetScale 'DTO(3) UTC', '2023-06-16 14:30:20.123 +00:00', 3;
GO
EXEC TestDateTimeOffsetScale 'DTO(3) PST', '2023-06-16 14:30:20.123 -07:00', 3;
GO
EXEC TestDateTimeOffsetScale 'DTO(3) IST', '2023-06-16 14:30:20.123 +05:30', 3;
GO

-- Scale 4 (9 bytes)
EXEC TestDateTimeOffsetScale 'DTO(4) UTC', '2023-06-16 14:30:20.1234 +00:00', 4;
GO
EXEC TestDateTimeOffsetScale 'DTO(4) PST', '2023-06-16 14:30:20.1234 -07:00', 4;
GO
EXEC TestDateTimeOffsetScale 'DTO(4) IST', '2023-06-16 14:30:20.1234 +05:30', 4;
GO

-- Scale 5 (10 bytes)
EXEC TestDateTimeOffsetScale 'DTO(5) UTC', '2023-06-16 14:30:20.12345 +00:00', 5;
GO
EXEC TestDateTimeOffsetScale 'DTO(5) PST', '2023-06-16 14:30:20.12345 -07:00', 5;
GO
EXEC TestDateTimeOffsetScale 'DTO(5) IST', '2023-06-16 14:30:20.12345 +05:30', 5;
GO

-- Scale 6 (10 bytes)
EXEC TestDateTimeOffsetScale 'DTO(6) UTC', '2023-06-16 14:30:20.123456 +00:00', 6;
GO
EXEC TestDateTimeOffsetScale 'DTO(6) PST', '2023-06-16 14:30:20.123456 -07:00', 6;
GO
EXEC TestDateTimeOffsetScale 'DTO(6) IST', '2023-06-16 14:30:20.123456 +05:30', 6;
GO

-- Scale 7 (10 bytes)
EXEC TestDateTimeOffsetScale 'DTO(7) UTC', '2023-06-16 14:30:20.1234567 +00:00', 7;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) PST', '2023-06-16 14:30:20.1234567 -07:00', 7;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) IST', '2023-06-16 14:30:20.1234567 +05:30', 7;
GO

-- Edge cases for each scale with different time zones
-- Testing boundary values
EXEC TestDateTimeOffsetScale 'DTO(0) Max UTC', '9999-12-31 23:59:59 +00:00', 0;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) Max UTC', '9999-12-31 23:59:59.9999999 +00:00', 7;
GO
EXEC TestDateTimeOffsetScale 'DTO(0) Min UTC', '0001-01-01 00:00:00 +00:00', 0;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) Min UTC', '0001-01-01 00:00:00.0000000 +00:00', 7;
GO

-- Testing extreme time zones
EXEC TestDateTimeOffsetScale 'DTO(7) Max TZ', '2023-06-16 14:30:20.1234567 +14:00', 7;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) Min TZ', '2023-06-16 14:30:20.1234567 -14:00', 7;
GO

-- Testing precision overflow
EXEC TestDateTimeOffsetScale 'DTO(0) Overflow', '2023-06-16 14:30:20.1234567890 +00:00', 0;
GO
EXEC TestDateTimeOffsetScale 'DTO(3) Overflow', '2023-06-16 14:30:20.1234567890 +00:00', 3;
GO
EXEC TestDateTimeOffsetScale 'DTO(7) Overflow', '2023-06-16 14:30:20.1234567890 +00:00', 7;
GO

-- Display results with detailed analysis
SELECT 
    ID,
    Description,
    DateTimeOffsetValue,
    Scale,
    Precision,
    StorageBytes,
    FractionalPrecision,
    FormattedValue,
    TimeZoneOffset,
    LEN(FormattedValue) AS FormattedLength,
    CASE 
        WHEN Scale <= 2 THEN '0-2 (8 bytes)'
        WHEN Scale <= 4 THEN '3-4 (9 bytes)'
        ELSE '5-7 (10 bytes)'
    END AS ScaleGroup
FROM DateTimeOffsetScaleTest
ORDER BY Scale, ID;
GO

-- Clean up: Drop all created objects
DROP FUNCTION CalculateDateTimeOffsetStorageBytes;
DROP PROCEDURE InsertDateTimeOffsetTest2;
DROP TABLE DateTimeOffsetExpressionTest;
DROP TABLE DateTimeOffsetScaleTest;
DROP PROCEDURE TestDateTimeOffsetScale;
DROP INDEX IX_DateTimeOffsetTest_DTOColumn ON DateTimeOffsetIndexTest;
DROP INDEX IX_DateTimeOffsetTest_DTOColumn_DTOColumn2 ON DateTimeOffsetIndexTest;
DROP INDEX IX_DateTimeOffsetTest_DTOColumn_Include ON DateTimeOffsetIndexTest;
DROP INDEX IX_BusinessDTO ON UDDTDateTimeOffsetTest;
DROP INDEX IX_ShiftDTO ON UDDTDateTimeOffsetTest;
DROP TABLE DatetimeoffsetTest;
DROP TABLE DatetimeoffsetDefaultTest;
DROP FUNCTION dbo.GetCurrentDTO;
DROP TABLE DateTimeOffsetFormatTest;
DROP PROCEDURE InsertDateTimeOffsetTest;
DROP PROCEDURE InsertDateTimeOffsetTest1;
DROP PROCEDURE TestDateTimeOffsetFormat;
DROP TABLE DateTimeOffsetConversionTest;
DROP TABLE DateTimeOffsetZoneTest;
DROP PROCEDURE InsertDateTimeOffsetZoneTest;
DROP TABLE UDDTDateTimeOffsetTest;
DROP PROCEDURE TestUDDTDateTimeOffsetProc;
DROP TYPE BusinessDateTimeOffset;
DROP TYPE ShiftDateTimeOffset;
DROP TYPE PreciseDateTimeOffset;
DROP FUNCTION dbo.TestDateTimeOffsetFunction;
DROP TABLE DateTimeOffsetImplicitConversionTest;
DROP PROCEDURE InsertDateTimeOffsetTestResult;
DROP FUNCTION dbo.AddHoursToDTO;
DROP PROCEDURE dbo.ProcessDTO;
DROP VIEW dbo.DTOView;
DROP TABLE DateTimeOffsetDMLTestChild;
DROP TABLE DateTimeOffsetDMLTest;
DROP TABLE DateTimeOffsetIndexTest;
DROP TABLE DateTimeOffsetTest1;
DROP TABLE DTO_partition;
DROP PARTITION SCHEME DTO_partition_scheme;
DROP PARTITION FUNCTION DTO_partition_func;
GO
