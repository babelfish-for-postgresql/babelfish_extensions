-- sla 200000
-- 1. Basic Testing:
-- Create Datetime2Test table with different scale precisions
CREATE TABLE Datetime2Test (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    DateTime2_0 DATETIME2(0),  -- Precision: seconds
    DateTime2_3 DATETIME2(3),  -- Precision: milliseconds
    DateTime2_7 DATETIME2(7)   -- Precision: 100 nanoseconds
);
GO

-- NULL and empty values
INSERT INTO Datetime2Test (Description, InputString, DateTime2_0, DateTime2_3, DateTime2_7)
VALUES ('NULL value', NULL, NULL, NULL, NULL);
GO

DECLARE @EmptyDateTime2 DATETIME2;
INSERT INTO Datetime2Test (Description, InputString, DateTime2_0, DateTime2_3, DateTime2_7)
VALUES ('Empty DATETIME2 variable', NULL, @EmptyDateTime2, @EmptyDateTime2, @EmptyDateTime2);
GO

SELECT * FROM Datetime2Test WHERE DateTime2_0 IS NULL ORDER BY ID;
GO
SELECT * FROM Datetime2Test ORDER BY ID;
GO

-- Default values
CREATE TABLE Datetime2DefaultTest (
    ID INT PRIMARY KEY,
    DateTime2Col DATETIME2,
    DateTime2Col1 DATETIME2(4),
    DateTime2Col2 DATETIME2(6)
);
INSERT INTO Datetime2DefaultTest VALUES (1, CAST('19:00:00' As DATETIME2), CAST('19:00:00' As DATETIME2), CAST('19:00:00' As DATETIME2));
INSERT INTO Datetime2DefaultTest VALUES (2, CAST('1910-01-01' As DATETIME2), CAST('1910-01-01' As DATETIME2), CAST('1910-01-01' As DATETIME2));
SELECT * FROM Datetime2DefaultTest ORDER BY ID;
GO

-- Character length tests for DATETIME2
DECLARE @d DATETIME2(0) = '  2023-06-16 19:00:00  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(1) = '  2023-06-16 19:00:00.0  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(2) = '  2023-06-16 19:00:00.00  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(3) = '  2023-06-16 19:00:00.000  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(4) = '  2023-06-16 19:00:00.0000  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(5) = '  2023-06-16 19:00:00.00000  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(6) = '  2023-06-16 19:00:00.000000  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

DECLARE @d DATETIME2(7) = '  2023-06-16 19:00:00.0000000  ';
SELECT LEN(CAST(@d AS VARCHAR(50)));
GO

-- Edge case values with different scales
DECLARE @dt1 DATETIME2(0) = '0001-01-01 00:00:00';
DECLARE @dt2 DATETIME2(7) = '0001-01-01 00:00:00.0000000';
DECLARE @dt3 DATETIME2(0) = '9999-12-31 23:59:59';
DECLARE @dt4 DATETIME2(7) = '9999-12-31 23:59:59.9999999';
SELECT @dt1, @dt2, @dt3, @dt4;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d DATETIME2;
SET @d = '2023-06-16 19:00:00';
SELECT @d, CAST('2023-06-16 19:00:00' AS DATETIME2), CONVERT(DATETIME2, '2023-06-16 19:00:00');
GO

-- Create a test table for DATETIME2
CREATE TABLE DateTime2FormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ParsedDateTime2 DATETIME2
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTime2Test
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTime2FormatTest (Description, InputString, ParsedDateTime2)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIME2));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Standard 24-hour format tests
EXEC InsertDateTime2Test '24hr - Full precision', '2023-06-16 14:30:20.1234567';
GO

EXEC InsertDateTime2Test '24hr - Seconds only', '2023-06-16 14:30:20';
GO

EXEC InsertDateTime2Test '24hr - Minutes only', '2023-06-16 14:30';
GO

EXEC InsertDateTime2Test '24hr - Hours only', '2023-06-16 14';
GO

-- 2. AM/PM format tests
EXEC InsertDateTime2Test '12hr - AM Full', '2023-06-16 10:30:20.1234567 AM';
GO

EXEC InsertDateTime2Test '12hr - PM Full', '2023-06-16 02:30:20.1234567 PM';
GO

EXEC InsertDateTime2Test '12hr - AM Simple', '2023-06-16 10:30 AM';
GO

EXEC InsertDateTime2Test '12hr - PM Simple', '2023-06-16 02:30 PM';
GO

-- 3. Different separators
EXEC InsertDateTime2Test 'Separator - Colon', '2023-06-16 14:30:20';
GO

EXEC InsertDateTime2Test 'Separator - Period', '2023-06-16 14.30.20';
GO

EXEC InsertDateTime2Test 'Separator - Space', '2023-06-16 14 30 20';
GO

-- 4. Precision variations
EXEC InsertDateTime2Test 'Precision - 7 digits', '2023-06-16 14:30:20.1234567';
GO

EXEC InsertDateTime2Test 'Precision - 6 digits', '2023-06-16 14:30:20.123456';
GO

EXEC InsertDateTime2Test 'Precision - 5 digits', '2023-06-16 14:30:20.12345';
GO

EXEC InsertDateTime2Test 'Precision - 4 digits', '2023-06-16 14:30:20.1234';
GO

EXEC InsertDateTime2Test 'Precision - 3 digits', '2023-06-16 14:30:20.123';
GO

EXEC InsertDateTime2Test 'Precision - 2 digits', '2023-06-16 14:30:20.12';
GO

EXEC InsertDateTime2Test 'Precision - 1 digit', '2023-06-16 14:30:20.1';
GO

-- 5. Edge cases
EXEC InsertDateTime2Test 'Edge - Midnight', '2023-06-16 00:00:00';
GO

EXEC InsertDateTime2Test 'Edge - Almost midnight', '2023-06-16 23:59:59.9999999';
GO

EXEC InsertDateTime2Test 'Edge - Noon', '2023-06-16 12:00:00';
GO

EXEC InsertDateTime2Test 'Edge - Almost noon', '2023-06-16 11:59:59.9999999';
GO

-- 6. Leading zeros variations
EXEC InsertDateTime2Test 'Zeros - With leading', '2023-06-16 08:05:02';
GO

EXEC InsertDateTime2Test 'Zeros - Without leading', '2023-06-16 8:5:2';
GO

-- 7. AM/PM variations
EXEC InsertDateTime2Test 'AMPM - AM variations 1', '2023-06-16 8:30 AM';
GO

EXEC InsertDateTime2Test 'AMPM - AM variations 2', '2023-06-16 8:30AM';
GO

EXEC InsertDateTime2Test 'AMPM - AM variations 3', '2023-06-16 8:30 am';
GO

EXEC InsertDateTime2Test 'AMPM - AM variations 4', '2023-06-16 8:30am';
GO

EXEC InsertDateTime2Test 'AMPM - PM variations 1', '2023-06-16 8:30 PM';
GO

EXEC InsertDateTime2Test 'AMPM - PM variations 2', '2023-06-16 8:30PM';
GO

EXEC InsertDateTime2Test 'AMPM - PM variations 3', '2023-06-16 8:30 pm';
GO

EXEC InsertDateTime2Test 'AMPM - PM variations 4', '2023-06-16 8:30pm';
GO

-- 8. ISO 8601 format
EXEC InsertDateTime2Test 'ISO - Basic', '2023-06-16T14:30:20';
GO

EXEC InsertDateTime2Test 'ISO - With nanoseconds', '2023-06-16T14:30:20.1234567';
GO

-- 9. ODBC canonical format
EXEC InsertDateTime2Test 'ODBC canonical', '{ts ''2023-06-16 14:30:20''}';
GO

-- 10. Different cultures/formats
SET LANGUAGE French;
GO
EXEC InsertDateTime2Test 'French datetime format', '16/06/2023 14.30.20';
GO

SET LANGUAGE German;
GO
EXEC InsertDateTime2Test 'German datetime format', '16.06.2023 14.30.20';
GO

SET LANGUAGE us_english;
GO

-- 11. Invalid formats (these should fail)
EXEC InsertDateTime2Test 'Invalid - Hour too high', '2023-06-16 25:00:00';
GO

EXEC InsertDateTime2Test 'Invalid - Minute too high', '2023-06-16 14:60:00';
GO

EXEC InsertDateTime2Test 'Invalid - Second too high', '2023-06-16 14:30:60';
GO

EXEC InsertDateTime2Test 'Invalid - Too many fractional digits', '2023-06-16 14:30:20.12345678';
GO

-- 12. Fractional seconds variations
EXEC InsertDateTime2Test 'Fractional - Trailing zeros', '2023-06-16 14:30:20.1000000';
GO

EXEC InsertDateTime2Test 'Fractional - Mixed precision', '2023-06-16 14:30:20.123456';
GO

EXEC InsertDateTime2Test 'Fractional - Single digit', '2023-06-16 14:30:20.5';
GO

-- 13. Date boundary tests
EXEC InsertDateTime2Test 'Min DateTime2', '0001-01-01 00:00:00';
GO

EXEC InsertDateTime2Test 'Max DateTime2', '9999-12-31 23:59:59.9999999';
GO

-- 14. Mixed format variations
EXEC InsertDateTime2Test 'Mixed - 24hr with ns', '2023-06-16 14:30:20.1234567';
GO

EXEC InsertDateTime2Test 'Mixed - 12hr with ns AM', '2023-06-16 02:30:20.1234567 AM';
GO

EXEC InsertDateTime2Test 'Mixed - 12hr with ns PM', '2023-06-16 02:30:20.1234567 PM';
GO

-- 15. Special cases
EXEC InsertDateTime2Test 'Special - Midnight AM', '2023-06-16 12:00:00 AM';
GO

EXEC InsertDateTime2Test 'Special - Noon PM', '2023-06-16 12:00:00 PM';
GO

EXEC InsertDateTime2Test 'Special - Midnight 24hr', '2023-06-16 00:00:00';
GO

EXEC InsertDateTime2Test 'Special - Noon 24hr', '2023-06-16 12:00:00';
GO

-- 16. Different date formats with time
SET DATEFORMAT mdy;
GO
EXEC InsertDateTime2Test 'MDY format with time', '06-16-2023 14:30:20.1234567';
GO

SET DATEFORMAT dmy;
GO
EXEC InsertDateTime2Test 'DMY format with time', '16-06-2023 14:30:20.1234567';
GO

SET DATEFORMAT ymd;
GO
EXEC InsertDateTime2Test 'YMD format with time', '2023-06-16 14:30:20.1234567';
GO

SET DATEFORMAT mdy;
GO

-- Helper procedure to insert test cases for DATETIME2
CREATE PROCEDURE InsertDateTime2Test1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO DateTime2FormatTest (Description, InputString, Collation, ParsedDateTime2)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS DATETIME2))';
        
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
CREATE PROCEDURE TestDateTime2Format
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
        EXEC InsertDateTime2Test1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Standard time formats with date
EXEC TestDateTime2Format 'DT2 - 24hr full precision', '2023-06-16 14:30:20.1234567';
GO

EXEC TestDateTime2Format 'DT2 - 24hr with seconds', '2023-06-16 14:30:20';
GO

EXEC TestDateTime2Format 'DT2 - 24hr without seconds', '2023-06-16 14:30';
GO

EXEC TestDateTime2Format 'DT2 - 24hr hours only', '2023-06-16 14';
GO

-- AM/PM formats with date
EXEC TestDateTime2Format 'DT2 - 12hr AM full', '2023-06-16 10:30:20.1234567 AM';
GO

EXEC TestDateTime2Format 'DT2 - 12hr PM full', '2023-06-16 02:30:20.1234567 PM';
GO

EXEC TestDateTime2Format 'DT2 - 12hr AM simple', '2023-06-16 10:30 AM';
GO

EXEC TestDateTime2Format 'DT2 - 12hr PM simple', '2023-06-16 02:30 PM';
GO

-- Different separators
EXEC TestDateTime2Format 'DT2 - Colon separator', '2023-06-16 14:30:20';
GO

EXEC TestDateTime2Format 'DT2 - Period separator', '2023-06-16 14.30.20';
GO

EXEC TestDateTime2Format 'DT2 - Space separator', '2023-06-16 14 30 20';
GO

EXEC TestDateTime2Format 'DT2 - No separator', '20230616 143020';
GO

-- Precision variations
EXEC TestDateTime2Format 'DT2 - 1 decimal place', '2023-06-16 14:30:20.1';
GO

EXEC TestDateTime2Format 'DT2 - 3 decimal places', '2023-06-16 14:30:20.123';
GO

EXEC TestDateTime2Format 'DT2 - 5 decimal places', '2023-06-16 14:30:20.12345';
GO

EXEC TestDateTime2Format 'DT2 - 7 decimal places', '2023-06-16 14:30:20.1234567';
GO

-- Leading zeros variations
EXEC TestDateTime2Format 'DT2 - With leading zeros', '2023-06-16 04:05:06';
GO

EXEC TestDateTime2Format 'DT2 - Without leading zeros', '2023-06-16 4:5:6';
GO

-- Edge cases
EXEC TestDateTime2Format 'DT2 - Midnight', '2023-06-16 00:00:00';
GO

EXEC TestDateTime2Format 'DT2 - Almost midnight', '2023-06-16 23:59:59.9999999';
GO

EXEC TestDateTime2Format 'DT2 - Noon', '2023-06-16 12:00:00';
GO

EXEC TestDateTime2Format 'DT2 - Almost noon', '2023-06-16 11:59:59.9999999';
GO

-- ISO 8601 format
EXEC TestDateTime2Format 'DT2 - ISO basic', '20230616T143020';
GO

EXEC TestDateTime2Format 'DT2 - ISO extended', '2023-06-16T14:30:20';
GO

-- ODBC canonical format
EXEC TestDateTime2Format 'DT2 - ODBC canonical', '{ts ''2023-06-16 14:30:20''}';
GO

-- AM/PM variations
EXEC TestDateTime2Format 'DT2 - AM variations 1', '2023-06-16 12:00 AM';
GO

EXEC TestDateTime2Format 'DT2 - AM variations 2', '2023-06-16 12:00AM';
GO

EXEC TestDateTime2Format 'DT2 - PM variations 1', '2023-06-16 12:00 PM';
GO

EXEC TestDateTime2Format 'DT2 - PM variations 2', '2023-06-16 12:00PM';
GO

-- Different hour formats
EXEC TestDateTime2Format 'DT2 - Hour 0', '2023-06-16 00:30:20';
GO

EXEC TestDateTime2Format 'DT2 - Hour 12 AM', '2023-06-16 12:30:20 AM';
GO

EXEC TestDateTime2Format 'DT2 - Hour 12 PM', '2023-06-16 12:30:20 PM';
GO

EXEC TestDateTime2Format 'DT2 - Hour 24', '2023-06-16 24:00:00';
GO

-- Date variations with time
SET DATEFORMAT mdy;
GO
EXEC TestDateTime2Format 'DT2 - MDY slash', '06/16/2023 14:30:20.1234567';
GO

SET DATEFORMAT dmy;
GO
EXEC TestDateTime2Format 'DT2 - DMY slash', '16/06/2023 14:30:20.1234567';
GO

SET DATEFORMAT ymd;
GO
EXEC TestDateTime2Format 'DT2 - YMD slash', '2023/06/16 14:30:20.1234567';
GO

SET DATEFORMAT mdy;
GO

-- Invalid formats (these should fail)
EXEC TestDateTime2Format 'DT2 Invalid - Hour too high', '2023-06-16 25:00:00';
GO

EXEC TestDateTime2Format 'DT2 Invalid - Minute too high', '2023-06-16 14:60:00';
GO

EXEC TestDateTime2Format 'DT2 Invalid - Second too high', '2023-06-16 14:30:60';
GO

EXEC TestDateTime2Format 'DT2 Invalid - Too many decimals', '2023-06-16 14:30:20.12345678';
GO

-- Mixed formats
EXEC TestDateTime2Format 'DT2 Mixed - Different separators', '2023-06-16 14:30.20';
GO

EXEC TestDateTime2Format 'DT2 Mixed - Partial precision', '2023-06-16 14:30:20.';
GO

-- Language-specific formats
SET LANGUAGE French;
GO
EXEC TestDateTime2Format 'DT2 French format', '16 juin 2023 14:30:20';
GO

SET LANGUAGE German;
GO
EXEC TestDateTime2Format 'DT2 German format', '16. Juni 2023 14:30:20';
GO

SET LANGUAGE us_english;
GO

-- Display results
SELECT * FROM DateTime2FormatTest ORDER BY ID;
GO

-- Create a test table for DATETIME2
CREATE TABLE DateTime2ConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedDateTime2 DATETIME2
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTime2ConversionTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO DateTime2ConversionTest (Description, InputString, ConvertedDateTime2)
        VALUES (@Description, @InputString, CAST(@InputString AS DATETIME2));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC formats
EXEC InsertDateTime2ConversionTest 'ODBC TIME', '{t ''12:34:56''}';
GO

EXEC InsertDateTime2ConversionTest 'ODBC DATETIME', '{ts ''2023-06-16 12:34:56''}';
GO

-- Basic datetime formats
EXEC InsertDateTime2ConversionTest 'Basic 24hr time', '2023-06-16 14:30:00';
GO

EXEC InsertDateTime2ConversionTest 'Basic AM time', '2023-06-16 09:30:00 AM';
GO

EXEC InsertDateTime2ConversionTest 'Basic PM time', '2023-06-16 02:30:00 PM';
GO

-- Time with different precisions
EXEC InsertDateTime2ConversionTest 'DateTime2 with hours only', '2023-06-16 14';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with hours and minutes', '2023-06-16 14:30';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with seconds', '2023-06-16 14:30:45';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with milliseconds', '2023-06-16 14:30:45.123';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with microseconds', '2023-06-16 14:30:45.123456';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with nanoseconds', '2023-06-16 14:30:45.123456789';
GO

-- Different time separators
EXEC InsertDateTime2ConversionTest 'DateTime2 with colon separator', '2023-06-16 14:30:45';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with period separator', '2023-06-16 14.30.45';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with space separator', '2023-06-16 14 30 45';
GO

-- AM/PM variations
EXEC InsertDateTime2ConversionTest 'AM time with space', '2023-06-16 09:30:00 AM';
GO

EXEC InsertDateTime2ConversionTest 'AM time without space', '2023-06-16 09:30:00AM';
GO

EXEC InsertDateTime2ConversionTest 'PM time with space', '2023-06-16 09:30:00 PM';
GO

EXEC InsertDateTime2ConversionTest 'PM time without space', '2023-06-16 09:30:00PM';
GO

EXEC InsertDateTime2ConversionTest 'Lowercase am', '2023-06-16 09:30:00 am';
GO

EXEC InsertDateTime2ConversionTest 'Lowercase pm', '2023-06-16 09:30:00 pm';
GO

EXEC InsertDateTime2ConversionTest 'Mixed case AM', '2023-06-16 09:30:00 Am';
GO

EXEC InsertDateTime2ConversionTest 'Mixed case PM', '2023-06-16 09:30:00 Pm';
GO

-- Edge cases
EXEC InsertDateTime2ConversionTest 'Midnight start of day', '2023-06-16 00:00:00';
GO

EXEC InsertDateTime2ConversionTest 'Last moment of day', '2023-06-16 23:59:59.9999999';
GO

EXEC InsertDateTime2ConversionTest 'Noon 24hr', '2023-06-16 12:00:00';
GO

EXEC InsertDateTime2ConversionTest 'Noon AM/PM', '2023-06-16 12:00:00 PM';
GO

-- Different date formats with time
EXEC InsertDateTime2ConversionTest 'ISO format', '2023-06-16T14:30:45.1234567';
GO

EXEC InsertDateTime2ConversionTest 'YMD with time', '20230616 14:30:45.1234567';
GO

-- Invalid formats (should fail)
EXEC InsertDateTime2ConversionTest 'Invalid hour', '2023-06-16 25:00:00';
GO

EXEC InsertDateTime2ConversionTest 'Invalid minute', '2023-06-16 14:60:00';
GO

EXEC InsertDateTime2ConversionTest 'Invalid second', '2023-06-16 14:30:60';
GO

EXEC InsertDateTime2ConversionTest 'Invalid nanosecond', '2023-06-16 14:30:45.1234567890';
GO

EXEC InsertDateTime2ConversionTest 'Invalid format', '2023-06-16 1430:45';
GO

-- Time zones (should handle the datetime part)
EXEC InsertDateTime2ConversionTest 'DateTime2 with timezone', '2023-06-16 14:30:45 +05:30';
GO

EXEC InsertDateTime2ConversionTest 'DateTime2 with timezone and ns', '2023-06-16 14:30:45.1234567 +05:30';
GO

-- Different styles of writing datetime
EXEC InsertDateTime2ConversionTest 'Military time style', '2023-06-16 1430';
GO

EXEC InsertDateTime2ConversionTest 'Hours only AM', '2023-06-16 9 AM';
GO

EXEC InsertDateTime2ConversionTest 'Hours only PM', '2023-06-16 2 PM';
GO

-- ISO 8601 format variations
EXEC InsertDateTime2ConversionTest 'ISO 8601 basic', '20230616T143045';
GO

EXEC InsertDateTime2ConversionTest 'ISO 8601 extended', '2023-06-16T14:30:45';
GO

EXEC InsertDateTime2ConversionTest 'ISO 8601 with ns', '2023-06-16T14:30:45.1234567';
GO

-- Additional precision tests
EXEC InsertDateTime2ConversionTest 'Precision 0', '2023-06-16 14:30:45';
GO

EXEC InsertDateTime2ConversionTest 'Precision 1', '2023-06-16 14:30:45.1';
GO

EXEC InsertDateTime2ConversionTest 'Precision 2', '2023-06-16 14:30:45.12';
GO

EXEC InsertDateTime2ConversionTest 'Precision 3', '2023-06-16 14:30:45.123';
GO

EXEC InsertDateTime2ConversionTest 'Precision 4', '2023-06-16 14:30:45.1234';
GO

EXEC InsertDateTime2ConversionTest 'Precision 5', '2023-06-16 14:30:45.12345';
GO

EXEC InsertDateTime2ConversionTest 'Precision 6', '2023-06-16 14:30:45.123456';
GO

EXEC InsertDateTime2ConversionTest 'Precision 7', '2023-06-16 14:30:45.1234567';
GO

-- Edge dates with time
EXEC InsertDateTime2ConversionTest 'Min DateTime2', '0001-01-01 00:00:00';
GO

EXEC InsertDateTime2ConversionTest 'Max DateTime2', '9999-12-31 23:59:59.9999999';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputString,
    ConvertedDateTime2,
    CAST(ConvertedDateTime2 AS NVARCHAR(30)) AS DateTime2String
FROM DateTime2ConversionTest 
ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'datetime2';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'datetime2' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- AT TIME ZONE

-- Create a test table for DATETIME2 with time zones
CREATE TABLE DateTime2ZoneTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputDateTime2 DATETIME2,
    TimeZone NVARCHAR(100),
    Result NVARCHAR(MAX)
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertDateTime2ZoneTest
    @Description NVARCHAR(100),
    @InputDateTime2 DATETIME2,
    @TimeZone NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @Result NVARCHAR(MAX);
        SET @Result = CAST(@InputDateTime2 AT TIME ZONE @TimeZone AS NVARCHAR(MAX));
        
        INSERT INTO DateTime2ZoneTest (Description, InputDateTime2, TimeZone, Result)
        VALUES (@Description, @InputDateTime2, @TimeZone, @Result);
        
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        INSERT INTO DateTime2ZoneTest (Description, InputDateTime2, TimeZone, Result)
        VALUES (@Description, @InputDateTime2, @TimeZone, ERROR_MESSAGE());
        
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Standard time tests
EXEC InsertDateTime2ZoneTest 'DT2 Midnight UTC', '2023-06-16 00:00:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Noon UTC', '2023-06-16 12:00:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Evening UTC', '2023-06-16 18:30:00.0000000', 'UTC';
GO

-- Different time zones with specific times
EXEC InsertDateTime2ZoneTest 'DT2 Morning PST', '2023-06-16 09:30:00.0000000', 'Pacific Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Afternoon EST', '2023-06-16 14:30:00.0000000', 'Eastern Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Evening CET', '2023-06-16 20:30:00.0000000', 'Central European Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Night JST', '2023-06-16 23:30:00.0000000', 'Tokyo Standard Time';
GO

-- Time precision tests
EXEC InsertDateTime2ZoneTest 'DT2 Precision Seconds', '2023-06-16 14:30:20.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Precision Milliseconds', '2023-06-16 14:30:20.1230000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Precision Microseconds', '2023-06-16 14:30:20.123456', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Precision Nanoseconds', '2023-06-16 14:30:20.1234567', 'UTC';
GO

-- DST transition times
EXEC InsertDateTime2ZoneTest 'DT2 DST Start PST 1:30 AM', '2023-03-12 01:30:00.0000000', 'Pacific Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 DST Start PST 2:30 AM', '2023-03-12 02:30:00.0000000', 'Pacific Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 DST End PST 1:30 AM', '2023-11-05 01:30:00.0000000', 'Pacific Standard Time';
GO

-- Time zones with different offsets
EXEC InsertDateTime2ZoneTest 'DT2 IST Time', '2023-06-16 15:30:00.0000000', 'India Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 NZ Time', '2023-06-16 15:30:00.0000000', 'New Zealand Standard Time';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Saudi Time', '2023-06-16 15:30:00.0000000', 'Saudi Arabia Standard Time';
GO

-- Edge cases
EXEC InsertDateTime2ZoneTest 'DT2 Min DateTime', '0001-01-01 00:00:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Max DateTime', '9999-12-31 23:59:59.9999999', 'UTC';
GO

-- Different time formats
EXEC InsertDateTime2ZoneTest 'DT2 24-hour format', '2023-06-16 14:30:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Fractional seconds', '2023-06-16 14:30:20.5000000', 'UTC';
GO

-- Hour boundary tests
EXEC InsertDateTime2ZoneTest 'DT2 Hour Start', '2023-06-16 14:00:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Hour End', '2023-06-16 14:59:59.9999999', 'UTC';
GO

-- Minute boundary tests
EXEC InsertDateTime2ZoneTest 'DT2 Minute Start', '2023-06-16 14:30:00.0000000', 'UTC';
GO

EXEC InsertDateTime2ZoneTest 'DT2 Minute End', '2023-06-16 14:30:59.9999999', 'UTC';
GO

-- Different time zones tests
SELECT CAST('2023-06-16 14:30:00' AS DATETIME2) AT TIME ZONE 'Asia/Kolkata';
GO

SELECT CAST('2023-06-16 14:30:00' AS DATETIME2) AT TIME ZONE 'America/Los_Angeles';
GO

SELECT CAST('2023-06-16 14:30:00' AS DATETIME2) AT TIME ZONE 'UTC';
GO

-- Invalid scenarios
EXEC InsertDateTime2ZoneTest 'DT2 Invalid Time Zone', '2023-06-16 14:30:00', 'Invalid Time Zone';
GO

EXEC InsertDateTime2ZoneTest 'DT2 NULL Time Zone', '2023-06-16 14:30:00', NULL;
GO

-- DateTime2 arithmetic across time zones
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:00.0000000';
SELECT 
    @dt2 AS OriginalDateTime,
    CAST(@dt2 AT TIME ZONE 'UTC' AS DATETIME2) AS UTCDateTime,
    CAST(@dt2 AT TIME ZONE 'Pacific Standard Time' AS DATETIME2) AS PSTDateTime,
    CAST(@dt2 AT TIME ZONE 'Eastern Standard Time' AS DATETIME2) AS ESTDateTime;
GO

-- Display results with timezone offset information
SELECT 
    ID,
    Description,
    InputDateTime2,
    TimeZone,
    Result,
    CASE 
        WHEN Result LIKE '%[+-]%:%' THEN 'Contains Offset'
        ELSE 'No Offset'
    END AS HasOffset
FROM DateTime2ZoneTest 
ORDER BY ID;
GO

-- Time zone conversion chain
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:00.0000000';
SELECT 
    @dt2 AS OriginalDateTime,
    CAST(CAST(CAST(@dt2 AT TIME ZONE 'UTC' 
        AT TIME ZONE 'Pacific Standard Time' 
        AT TIME ZONE 'Eastern Standard Time' AS DATETIME2) AS DATETIME2) AS DATETIME2) AS ConvertedDateTime;
GO

-- Precedence Order of datatypes
SELECT CASE WHEN CAST('2023-06-16 19:00:00' AS DATETIME2) = '2023-06-16 19:00:00' THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d DATETIME2', @d = '2023-06-16 19:00:00';
GO

-- 1. Create User-Defined Data Types based on DATETIME2
CREATE TYPE BusinessDateTime2 FROM DATETIME2(7);
CREATE TYPE ShiftDateTime2 FROM DATETIME2(0);
CREATE TYPE PreciseDateTime2 FROM DATETIME2(7);
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTDateTime2Test (
    ID INT PRIMARY KEY,
    RegularDateTime2 DATETIME2,
    BusinessDateTime2Col BusinessDateTime2,
    ShiftDateTime2Col ShiftDateTime2,
    PreciseDateTime2Col PreciseDateTime2
);
GO

-- 3. Insert data into the table
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES 
(1, '2023-06-16 09:00:00', '2023-06-16 09:00:00.0000000', '2023-06-16 09:00:00', '2023-06-16 09:00:00.1234567'),
(2, '2023-06-16 12:30:45', '2023-06-16 12:30:45.1234567', '2023-06-16 12:30:00', '2023-06-16 12:30:45.1234567'),
(3, '2023-06-16 17:45:30', '2023-06-16 17:45:30.0000000', '2023-06-16 17:45:00', '2023-06-16 17:45:30.9999999'),
(4, NULL, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTDateTime2Test ORDER BY ID;
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
WHERE TABLE_NAME = 'UDDTDateTime2Test' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularDateTime2 AS VARCHAR(50)) AS RegularDateTime2String,
    CAST(BusinessDateTime2Col AS VARCHAR(50)) AS BusinessDateTime2String,
    CAST(ShiftDateTime2Col AS VARCHAR(50)) AS ShiftDateTime2String,
    CAST(PreciseDateTime2Col AS VARCHAR(50)) AS PreciseDateTime2String,
    CAST(RegularDateTime2 AS DATETIME) AS RegularDateTime,
    CAST(BusinessDateTime2Col AS DATETIME) AS BusinessDateTime
FROM UDDTDateTime2Test ORDER BY ID;
GO

-- 7. Test datetime functions
SELECT 
    ID,
    DATEADD(HOUR, 1, RegularDateTime2) AS RegularNextHour,
    DATEADD(HOUR, 1, BusinessDateTime2Col) AS BusinessNextHour,
    DATEADD(MINUTE, 30, ShiftDateTime2Col) AS ShiftNextHalfHour,
    DATEDIFF(MINUTE, ShiftDateTime2Col, BusinessDateTime2Col) AS MinutesBetween
FROM UDDTDateTime2Test ORDER BY ID;
GO

-- 8. Test constraints
ALTER TABLE UDDTDateTime2Test ADD CONSTRAINT CK_BusinessDateTime2 
    CHECK (CAST(BusinessDateTime2Col AS TIME) >= '09:00:00' AND CAST(BusinessDateTime2Col AS TIME) <= '17:00:00');
GO

-- This should succeed
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES (5, '2023-06-16 10:00:00', '2023-06-16 10:00:00', '2023-06-16 10:00:00', '2023-06-16 10:00:00.1234567');
GO

-- This should fail
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES (6, '2023-06-16 18:00:00', '2023-06-16 18:00:00', '2023-06-16 18:00:00', '2023-06-16 18:00:00.1234567');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTDateTime2Proc
    @BusinessDateTime2 BusinessDateTime2,
    @ShiftDateTime2 ShiftDateTime2
AS
BEGIN
    SELECT 
        @BusinessDateTime2 AS InputBusinessDateTime2,
        @ShiftDateTime2 AS InputShiftDateTime2,
        DATEDIFF(MINUTE, @ShiftDateTime2, @BusinessDateTime2) AS MinutesBetween;
END
GO

-- Execute the stored procedure
EXEC TestUDDTDateTime2Proc 
    @BusinessDateTime2 = '2023-06-16 10:30:00', 
    @ShiftDateTime2 = '2023-06-16 09:00:00';
GO

-- 10. Test implicit conversions
DECLARE @RegularDateTime2 DATETIME2 = '2023-06-16 10:30:00';
DECLARE @BusinessDateTime2 BusinessDateTime2 = @RegularDateTime2;
DECLARE @ShiftDateTime2 ShiftDateTime2 = '2023-06-16 09:00:00';
DECLARE @PreciseDateTime2 PreciseDateTime2 = '2023-06-16 10:30:00.1234567';

SELECT 
    @RegularDateTime2 AS RegularDateTime2,
    @BusinessDateTime2 AS BusinessDateTime2,
    @ShiftDateTime2 AS ShiftDateTime2,
    @PreciseDateTime2 AS PreciseDateTime2;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessDateTime2 ON UDDTDateTime2Test(BusinessDateTime2Col);
CREATE INDEX IX_ShiftDateTime2 ON UDDTDateTime2Test(ShiftDateTime2Col);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTDateTime2Test WHERE BusinessDateTime2Col = '2023-06-16 10:00:00';
SELECT * FROM UDDTDateTime2Test WHERE ShiftDateTime2Col = '2023-06-16 09:00:00';
SET STATISTICS IO OFF;
GO

-- 12. Test with different datetime formats
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES 
(7, '2023-06-16 13:00:00', '2023-06-16 13:00:00', '2023-06-16 13:00:00', '2023-06-16 13:00:00.1234567'),
(8, '2023-06-16 13:00:00', '2023-06-16 13:00:00', '2023-06-16 13:00:00', '2023-06-16 13:00:00.1234567');
GO

-- 13. Test precision handling
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES 
(9, '2023-06-16 14:30:45.1234567', '2023-06-16 14:30:45.1234567', '2023-06-16 14:30:00', '2023-06-16 14:30:45.1234567'),
(10, '2023-06-16 14:30:45.9999999', '2023-06-16 14:30:45.9999999', '2023-06-16 14:30:00', '2023-06-16 14:30:45.9999999');
GO

-- 14. Test arithmetic operations
SELECT 
    ID,
    BusinessDateTime2Col,
    DATEADD(MILLISECOND, 500, BusinessDateTime2Col) AS AddMilliseconds,
    DATEADD(SECOND, 30, BusinessDateTime2Col) AS AddSeconds,
    DATEADD(MINUTE, -15, BusinessDateTime2Col) AS SubtractMinutes
FROM UDDTDateTime2Test ORDER BY ID;
GO

-- 15. Test boundary conditions
INSERT INTO UDDTDateTime2Test (ID, RegularDateTime2, BusinessDateTime2Col, ShiftDateTime2Col, PreciseDateTime2Col)
VALUES 
(11, '0001-01-01 00:00:00.0000000', '0001-01-01 00:00:00.0000000', '0001-01-01 00:00:00', '0001-01-01 00:00:00.0000000'),
(12, '9999-12-31 23:59:59.9999999', '9999-12-31 23:59:59.9999999', '9999-12-31 23:59:00', '9999-12-31 23:59:59.9999999');
GO

-- 16. Test with different datetime components
SELECT 
    ID,
    DATEPART(YEAR, BusinessDateTime2Col) AS BusinessYear,
    DATEPART(MONTH, BusinessDateTime2Col) AS BusinessMonth,
    DATEPART(DAY, BusinessDateTime2Col) AS BusinessDay,
    DATEPART(HOUR, BusinessDateTime2Col) AS BusinessHour,
    DATEPART(MINUTE, BusinessDateTime2Col) AS BusinessMinute,
    DATEPART(SECOND, BusinessDateTime2Col) AS BusinessSecond,
    DATEPART(MICROSECOND, BusinessDateTime2Col) AS BusinessMicrosecond
FROM UDDTDateTime2Test ORDER BY ID;
GO

-- Display final results
SELECT * FROM UDDTDateTime2Test ORDER BY ID;
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing
SELECT 
    CAST('2023-06-16 00:00:00' AS DATETIME2),
    CONVERT(DATETIME2, '2023-06-16 00:00:00'),
    TRY_CAST('2023-06-16 00:00:00' AS DATETIME2),
    TRY_CONVERT(DATETIME2, '2023-06-16 00:00:00'),
    FORMAT(CAST('2023-06-16 00:00:00' AS DATETIME2), 'yyyy-MM-dd HH:mm:ss.fffffff');
GO

-- Explicit Conversion to DATETIME2
-- binary
SELECT CAST(CAST(0x0000A8C0 AS binary) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(0x AS binary) AS DATETIME2);
GO
SELECT CAST(CAST(0xFFFFFFFF AS binary) AS DATETIME2);
GO

-- varbinary
SELECT CAST(CAST(0x0000A8C0 AS VARBINARY) AS DATETIME2);
GO
SELECT CAST(0x AS DATETIME2);
GO
SELECT CAST(CAST(0xFFFFFFFF AS VARBINARY) AS DATETIME2);
GO

-- char
SELECT CAST(CAST('2023-06-16 12:34:56' AS char) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('2023-06-16 12:34:56.1234567' AS char) AS DATETIME2); -- Positive with fraction
GO
SELECT CAST(CAST('2023-06-16 12:34' AS char) AS DATETIME2); -- Positive: Date + HH:MI
GO
SELECT CAST(CAST('invalid' AS char) AS DATETIME2); -- Will raise an error
GO
SELECT CAST(CAST(NULL AS char) AS DATETIME2);
GO
SELECT CAST(CAST('' AS char) AS DATETIME2);
GO

-- varchar
SELECT CAST(CAST('9999-12-31 23:59:59.9999999' AS varchar) AS DATETIME2); -- Edge: Max datetime2
GO
SELECT CAST(CAST('0001-01-01 00:00:00' AS varchar) AS DATETIME2); -- Edge: Min datetime2
GO
SELECT CAST(CAST('2023-06-16 12:34:56' AS varchar) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('2023-06-16 12:34' AS varchar) AS DATETIME2); -- Positive: Date + HH:MI
GO
SELECT CAST(CAST('invalid' AS varchar) AS DATETIME2); -- Will raise an error
GO
SELECT CAST(CAST(NULL AS varchar) AS DATETIME2);
GO
SELECT CAST(CAST('' AS varchar) AS DATETIME2);
GO

-- nchar
SELECT CAST(CAST(N'2023-06-16 12:34:56' AS NCHAR) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(N'2023-06-16 12:34:56.1234567' AS NCHAR) AS DATETIME2); -- Positive with fraction
GO
SELECT CAST(CAST(N'0001-01-01 00:00:00' AS NCHAR) AS DATETIME2); -- Edge: Min datetime2
GO
SELECT CAST(CAST(NULL AS nchar) AS DATETIME2);
GO
SELECT CAST(CAST(N'' AS nchar) AS DATETIME2);
GO

-- nvarchar
SELECT CAST(N'2023-06-16 12:34:56' AS DATETIME2); -- Positive
GO
SELECT CAST(N'2023-06-16 12:34:56.1234567' AS DATETIME2); -- Positive with fraction
GO
SELECT CAST(N'invalid' AS DATETIME2); -- Will raise an error
GO

-- time
SELECT CAST(CAST('12:34:56' AS TIME) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('23:59:59.9999999' AS TIME) AS DATETIME2); -- Edge: Max time
GO

-- datetime
SELECT CAST(CAST('2023-06-16 12:34:56' AS DATETIME) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('1753-01-01 00:00:00' AS DATETIME) AS DATETIME2); -- Min datetime
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 12:34:00' AS SMALLDATETIME) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('1900-01-01 00:00:00' AS SMALLDATETIME) AS DATETIME2); -- Min smalldatetime
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2) AS DATETIME2); -- Max datetime2
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS DATETIME2);
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AS DATETIME2);
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS DATETIME2);
GO

-- decimal
SELECT CAST(CAST(20230616123456 AS DECIMAL(14,0)) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(99991231235959 AS DECIMAL(14,0)) AS DATETIME2); -- Edge: Max valid datetime2
GO
SELECT CAST(CAST(0 AS DECIMAL(14,0)) AS DATETIME2); -- Will be converted to base date
GO

-- numeric
SELECT CAST(CAST(20230616123456 AS NUMERIC(14,0)) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(00010101000000 AS NUMERIC(14,0)) AS DATETIME2); -- Edge: Min datetime2
GO
SELECT CAST(CAST(-1 AS NUMERIC(14,0)) AS DATETIME2); -- Will raise an error
GO

-- float
SELECT CAST(CAST(20230616123456 AS FLOAT) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(99991231235959.9999999 AS FLOAT) AS DATETIME2); -- Edge case
GO
SELECT CAST(CAST(-1 AS FLOAT) AS DATETIME2); -- Will raise an error
GO

-- real
SELECT CAST(CAST(20230616123456 AS REAL) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(99991231235959.99 AS REAL) AS DATETIME2); -- Edge case
GO
SELECT CAST(CAST(-1 AS REAL) AS DATETIME2); -- Will raise an error
GO

-- bigint
SELECT CAST(CAST(20230616123456 AS BIGINT) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(99991231235959 AS BIGINT) AS DATETIME2); -- Edge: Max valid datetime2
GO
SELECT CAST(CAST(-1 AS BIGINT) AS DATETIME2); -- Will raise an error
GO

-- int
SELECT CAST(20230616 AS DATETIME2); -- Positive (will be converted to date)
GO
SELECT CAST(00010101 AS DATETIME2); -- Edge: Min date
GO
SELECT CAST(-1 AS DATETIME2); -- Will raise an error
GO

-- smallint
SELECT CAST(CAST(2023 AS SMALLINT) AS DATETIME2); -- Positive (will be converted to year)
GO
SELECT CAST(CAST(9999 AS SMALLINT) AS DATETIME2); -- Max year
GO
SELECT CAST(CAST(-1 AS SMALLINT) AS DATETIME2); -- Will raise an error
GO

-- tinyint
SELECT CAST(CAST(23 AS TINYINT) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(255 AS TINYINT) AS DATETIME2); -- Max tinyint
GO
SELECT CAST(CAST(0 AS TINYINT) AS DATETIME2); -- Min value
GO

-- money
SELECT CAST(CAST(20230616.1234 AS MONEY) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(99991231.9999 AS MONEY) AS DATETIME2); -- Edge case
GO
SELECT CAST(CAST(-1 AS MONEY) AS DATETIME2); -- Will raise an error
GO

-- smallmoney
SELECT CAST(CAST(20230616 AS SMALLMONEY) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS DATETIME2); -- Max smallmoney
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS DATETIME2); -- Will raise an error
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS DATETIME2); -- Will be converted to base date
GO
SELECT CAST(CAST(0 AS BIT) AS DATETIME2); -- Will be converted to base date
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS DATETIME2); -- Will raise an error
GO

-- text
SELECT CAST(CAST('2023-06-16 12:34:56' AS TEXT) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST('invalid' AS TEXT) AS DATETIME2); -- Will raise an error
GO

-- ntext
SELECT CAST(CAST(N'2023-06-16 12:34:56' AS NTEXT) AS DATETIME2); -- Positive
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS DATETIME2); -- Will raise an error
GO

-- xml
SELECT CAST(CAST('<date>2023-06-16T12:34:56</date>' AS XML) AS DATETIME2); -- Will raise an error
GO

-- sql_variant
SELECT CAST(CAST(CAST('2023-06-16 12:34:56' AS DATETIME2) AS SQL_VARIANT) AS DATETIME2); -- Positive
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS DATETIME2); -- Will raise an error
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS DATETIME2); -- Will raise an error
GO

-- Create a function that takes a DATETIME2 parameter
CREATE FUNCTION dbo.TestDateTime2Function(@DateTime2Param DATETIME2)
RETURNS DATETIME2
AS
BEGIN
    RETURN @DateTime2Param;
END
GO

-- binary
SELECT dbo.TestDateTime2Function(CAST(0x0A1E2D3C AS binary)); -- DateTime2 equivalent
GO
SELECT dbo.TestDateTime2Function(CAST(0x AS binary));
GO
SELECT dbo.TestDateTime2Function(CAST(0xFFFFFFFF AS binary));
GO

-- varbinary
SELECT dbo.TestDateTime2Function(CAST(0x0A1E2D3C AS VARBINARY)); -- DateTime2 equivalent
GO
SELECT dbo.TestDateTime2Function(0x);
GO
SELECT dbo.TestDateTime2Function(CAST(0xFFFFFFFF AS VARBINARY));
GO

-- char
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20' AS char)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20.1234567' AS char)); -- Positive with fractional seconds
GO
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30' AS char)); -- Positive without seconds
GO
SELECT dbo.TestDateTime2Function(CAST('invalid' AS char));
GO
SELECT dbo.TestDateTime2Function(CAST(NULL AS char));
GO
SELECT dbo.TestDateTime2Function(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestDateTime2Function(CAST('9999-12-31 23:59:59.9999999' AS varchar)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST('0001-01-01 00:00:00.0000000' AS varchar)); -- Edge: Min datetime2
GO
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20' AS varchar)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30' AS varchar)); -- Positive without seconds
GO
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 2:30 PM' AS varchar)); -- Positive: 12-hour format
GO
SELECT dbo.TestDateTime2Function(CAST('invalid' AS varchar));
GO
SELECT dbo.TestDateTime2Function(CAST(NULL AS varchar));
GO
SELECT dbo.TestDateTime2Function(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestDateTime2Function(CAST(N'2023-06-16 14:30:20' AS NCHAR)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST(N'2023-06-16 14:30' AS NCHAR)); -- Positive without seconds
GO
SELECT dbo.TestDateTime2Function(CAST(N'0001-01-01 00:00:00' AS NCHAR)); -- Edge: Min datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(N'9999-12-31 23:59:59.9999999' AS NCHAR)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(NULL AS nchar));
GO
SELECT dbo.TestDateTime2Function(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestDateTime2Function(N'2023-06-16 14:30:20'); -- Positive
GO
SELECT dbo.TestDateTime2Function(N'2023-06-16 14:30:20.1234567'); -- Positive with fractional seconds
GO
SELECT dbo.TestDateTime2Function(N'2023-06-16 2:30 PM'); -- Positive: 12-hour format
GO

-- time
SELECT dbo.TestDateTime2Function(CAST('14:30:20' AS TIME)); -- Negative: Will raise an error
GO

-- datetime
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20' AS DATETIME)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('1753-01-01 00:00:00' AS DATETIME)); -- Edge: Min datetime
GO

-- smalldatetime
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:00' AS SMALLDATETIME)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('1900-01-01 00:00:00' AS SMALLDATETIME)); -- Edge: Min smalldatetime
GO

-- datetime2
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20.1234567' AS DATETIME2)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('9999-12-31 23:59:59.9999999' AS DATETIME2)); -- Edge: Max datetime2
GO

-- date
SELECT dbo.TestDateTime2Function(CAST('2023-06-16' AS DATE)); -- Positive
GO

-- datetimeoffset
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET)); -- Edge
GO

-- decimal
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS DECIMAL(14,0))); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959 AS DECIMAL(14,0))); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(00010101000000 AS DECIMAL(14,0))); -- Edge: Min datetime2
GO

-- numeric
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS NUMERIC(14,0))); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(00010101000000 AS NUMERIC(14,0))); -- Edge: Min datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-1 AS NUMERIC(14,0))); -- Negative: Invalid datetime2
GO

-- float
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS FLOAT)); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959.9999999 AS FLOAT)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-20230616143020 AS FLOAT)); -- Negative: Invalid datetime2
GO

-- real
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS REAL)); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959.99 AS REAL)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-20230616143020 AS REAL)); -- Negative: Invalid datetime2
GO

-- bigint
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS BIGINT)); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959 AS BIGINT)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-1 AS BIGINT)); -- Negative: Invalid datetime2
GO

-- int
SELECT dbo.TestDateTime2Function(20230616); -- Positive (YYYYMMDD format)
GO
SELECT dbo.TestDateTime2Function(0); -- Negative: Invalid datetime2
GO
SELECT dbo.TestDateTime2Function(-1); -- Negative: Invalid datetime2
GO

-- smallint
SELECT dbo.TestDateTime2Function(CAST(2023 AS SMALLINT)); -- Negative: Invalid datetime2
GO

-- tinyint
SELECT dbo.TestDateTime2Function(CAST(23 AS TINYINT)); -- Negative: Invalid datetime2
GO

-- money
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS MONEY)); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959.9999999 AS MONEY)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-1 AS MONEY)); -- Negative: Invalid datetime2
GO

-- smallmoney
SELECT dbo.TestDateTime2Function(CAST(20230616143020 AS SMALLMONEY)); -- Positive (YYYYMMDDHHMMSS format)
GO
SELECT dbo.TestDateTime2Function(CAST(99991231235959.99 AS SMALLMONEY)); -- Edge: Max datetime2
GO
SELECT dbo.TestDateTime2Function(CAST(-1 AS SMALLMONEY)); -- Negative: Invalid datetime2
GO

-- bit
SELECT dbo.TestDateTime2Function(CAST(1 AS BIT)); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT dbo.TestDateTime2Function(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER)); -- Negative
GO

-- text
SELECT dbo.TestDateTime2Function(CAST('2023-06-16 14:30:20' AS TEXT)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST('invalid' AS TEXT)); -- Negative: Invalid datetime2
GO

-- ntext
SELECT dbo.TestDateTime2Function(CAST(N'2023-06-16 14:30:20' AS NTEXT)); -- Positive
GO
SELECT dbo.TestDateTime2Function(CAST(N'invalid' AS NTEXT)); -- Negative: Invalid datetime2
GO

-- xml
SELECT dbo.TestDateTime2Function(CAST('<datetime>2023-06-16T14:30:20</datetime>' AS XML)); -- Negative
GO

-- sql_variant
SELECT dbo.TestDateTime2Function(CAST(CAST('2023-06-16 14:30:20' AS DATETIME2) AS SQL_VARIANT)); -- Positive
GO

-- geometry
SELECT dbo.TestDateTime2Function(geometry::STGeomFromText('POINT(1 1)', 0)); -- Negative
GO

-- geography
SELECT dbo.TestDateTime2Function(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326)); -- Negative
GO

-- Create a table to store test results for DATETIME2
CREATE TABLE DateTime2ImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue DATETIME2 NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertDateTime2TestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue DATETIME2 = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO DateTime2ImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @DateTime2Value DATETIME2 = '2023-06-20 12:34:56.1234567';
DECLARE @StringDateTime NVARCHAR(30) = '2023-06-20 14:30:00.0000000';
DECLARE @DateTimeValue DATETIME = '2023-06-20 15:45:30.123';
DECLARE @SmallDateTime SMALLDATETIME = '2023-06-20 16:30:00';

-- 1. UNION
BEGIN TRY
    DECLARE @Result DATETIME2;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @DateTime2Value AS Result
        UNION
        SELECT @StringDateTime
        UNION
        SELECT @DateTimeValue
        UNION
        SELECT @SmallDateTime
    ) AS UnionResult;
    EXEC InsertDateTime2TestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime2 types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'UNION', 'Implicit conversion in UNION', 'Multiple datetime2 types', NULL, 0;
END CATCH;
GO

-- 2. UNION ALL
BEGIN TRY
    DECLARE @Result DATETIME2;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-20 12:34:56.1234567' AS DATETIME2) AS Result
        UNION ALL
        SELECT '2023-06-20 14:30:00.0000000'
        UNION ALL
        SELECT CAST('2023-06-20 15:45:30.123' AS DATETIME)
        UNION ALL
        SELECT CAST('2023-06-20 16:30:00' AS SMALLDATETIME)
    ) AS UnionAllResult;
    EXEC InsertDateTime2TestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime2 types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple datetime2 types', NULL, 0;
END CATCH;
GO

-- 3. CASE Expression
BEGIN TRY
    DECLARE @Result DATETIME2 = CASE 
        WHEN 1=0 THEN CAST('2023-06-20 12:34:56.1234567' AS DATETIME2)
        WHEN 1=0 THEN '2023-06-20 14:30:00.0000000'
        ELSE CAST('2023-06-20 15:45:30.123' AS DATETIME)
    END;
    EXEC InsertDateTime2TestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime2 types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'CASE', 'Implicit conversion in CASE', 'Multiple datetime2 types', NULL, 0;
END CATCH;
GO

-- 4. COALESCE
BEGIN TRY
    DECLARE @Result DATETIME2 = COALESCE(
        NULL, 
        CAST('2023-06-20 12:34:56.1234567' AS DATETIME2),
        '2023-06-20 14:30:00.0000000',
        CAST('2023-06-20 15:45:30.123' AS DATETIME)
    );
    EXEC InsertDateTime2TestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime2 types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple datetime2 types', NULL, 0;
END CATCH;
GO

-- 5. INTERSECT
BEGIN TRY
    DECLARE @Result DATETIME2;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-20 12:34:56.1234567' AS DATETIME2) AS Result
        INTERSECT
        SELECT '2023-06-20 12:34:56.1234567'
    ) AS IntersectResult;
    EXEC InsertDateTime2TestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATETIME2 and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'DATETIME2 and String', NULL, 0;
END CATCH;
GO

-- 6. EXCEPT
BEGIN TRY
    DECLARE @Result DATETIME2;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('2023-06-20 12:34:56.1234567' AS DATETIME2) AS Result
        EXCEPT
        SELECT '2023-06-20 14:30:00.0000000'
    ) AS ExceptResult;
    EXEC InsertDateTime2TestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIME2 and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'DATETIME2 and String', NULL, 0;
END CATCH;
GO

-- 7. VALUES
BEGIN TRY
    DECLARE @Result DATETIME2;
    SELECT TOP 1 @Result = Result
    FROM (VALUES 
        (CAST('2023-06-20 12:34:56.1234567' AS DATETIME2)),
        ('2023-06-20 14:30:00.0000000'),
        (CAST('2023-06-20 15:45:30.123' AS DATETIME))
    ) AS ValuesResult(Result);
    EXEC InsertDateTime2TestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime2 types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple datetime2 types', NULL, 0;
END CATCH;
GO

-- 8. ISNULL
BEGIN TRY
    DECLARE @Result DATETIME2 = ISNULL(NULL, '2023-06-20 14:30:00.0000000');
    EXEC InsertDateTime2TestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;
GO

-- Additional DATETIME2-specific tests

-- 9. Different datetime2 formats
BEGIN TRY
    DECLARE @Result DATETIME2 = COALESCE(
        '2023-06-20 12:34:56.1234567890',  -- More precision than DATETIME2
        '2023-06-20 12:34:56 PM',          -- 12-hour format
        '2023-06-20 12:34',                -- Hours and minutes only
        '2023-06-20 12:34:56.1234567'      -- Exact DATETIME2(7) precision
    );
    EXEC InsertDateTime2TestResult 'DATETIME2 Formats', 'Different datetime2 format conversions', 'Various datetime2 formats', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'DATETIME2 Formats', 'Different datetime2 format conversions', 'Various datetime2 formats', NULL, 0;
END CATCH;
GO

-- 10. Edge cases
BEGIN TRY
    DECLARE @Result DATETIME2 = COALESCE(
        '0001-01-01 00:00:00.0000000',     -- Minimum value
        '9999-12-31 23:59:59.9999999',     -- Maximum value
        '2023-06-20 24:00:00.0000000',     -- Should fail
        '2023-06-20 12:00:00.0000000'      -- Noon
    );
    EXEC InsertDateTime2TestResult 'DATETIME2 Edge Cases', 'Edge case datetime2 values', 'Edge datetime2 values', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertDateTime2TestResult 'DATETIME2 Edge Cases', 'Edge case datetime2 values', 'Edge datetime2 values', NULL, 0;
END CATCH;
GO

-- Display results
SELECT * FROM DateTime2ImplicitConversionTest ORDER BY ID;
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, 0x07E3061014223B, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16 14:22:59.1234567'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, ''2023-06-16 14:22:59.1234567'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, ''2023-06-16 14:22:59.1234567'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, N''2023-06-16 14:22:59.1234567'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, N''2023-06-16 14:22:59.1234567'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16 14:22:59.123'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16 14:22:00'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- time
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''14:22:59.1234567'' AS TIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16 14:22:59.1234567 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616.142259 AS DECIMAL(14,6)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(''2023-06-16 14:22:59.1234567'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616.142259 AS NUMERIC(14,6)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616.142259 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616.142259 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616142259 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616 AS INT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(2023 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(23 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(20230616.142259 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(2023.1422 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(DATETIME2, CAST(N''2023-06-16 14:22:59.1234567'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(0x0C22380000000000 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS char(19)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS varchar(19)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS nchar(19)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS nvarchar(19)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('12:34:56.1234567' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS decimal(8,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS numeric(8,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(202 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230616 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(20230 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(0x0C22380000000000 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('2023-06-16 12:34:56' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST(CAST('2023-06-16 12:34:56' AS datetime2) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) = CAST('<datetime>2023-06-16T12:34:56.1234567</datetime>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS char(19)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS varchar(19)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nchar(19)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nvarchar(19)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS time) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(202 AS tinyint) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS text) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS ntext) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56' AS datetime2) AS sql_variant) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56.1234567</datetime>' AS xml) = CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(0x0C22380000000000 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS char(19)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS varchar(19)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS nchar(19)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS nvarchar(19)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('12:34:56.1234567' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS decimal(8,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS numeric(8,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(202 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230616 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(20230 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(0x0C22380000000000 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('2023-06-16 12:34:56' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST(CAST('2023-06-16 12:34:56' AS datetime2) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <> CAST('<datetime>2023-06-16T12:34:56.1234567</datetime>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS char(19)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS varchar(19)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nchar(19)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS nvarchar(19)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS time) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallint) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(202 AS tinyint) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(20230 AS smallmoney) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS text) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS ntext) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56' AS datetime2) AS sql_variant) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('<datetime>2023-06-16T12:34:56.1234567</datetime>' AS xml) <> CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(0x0000000000000000 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(0x0000000000000000 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS char(26)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('12:34:56.1234567' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS decimal(8,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS numeric(8,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(1234 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(12 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(20230616 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(1234 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(0x0000000000000000 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('2023-06-16 12:34:56.1234567' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) < CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS char(26)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS time) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS image) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS text) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS ntext) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) < CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(0x0000000000000000 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(0x0000000000000000 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS char(26)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('12:34:56.1234567' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS decimal(8,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS numeric(8,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(1234 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(12 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(20230616 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(1234 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(0x0000000000000000 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('2023-06-16 12:34:56.1234567' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) <= CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS char(26)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS time) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS decimal(8,0)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS numeric(8,0)) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS float) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS real) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS bigint) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS money) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS image) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS text) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS ntext) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) <= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS char(26)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('12:34:56' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS decimal(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS numeric(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(1234 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(12 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(123456 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(1234 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(0x0C22380000000000 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('2023-06-16 12:34:56.1234567' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) > CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS char(26)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS float) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS real) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS int) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS money) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS text) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS ntext) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) > CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with DATETIME2 on left side
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS char(26)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('12:34:56' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616123456 AS decimal(14,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616123456 AS numeric(14,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616123456 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616123456 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616123456 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(1234 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(123 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(20230616.123456 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(1234.56 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(0x0C22380000000000 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('2023-06-16 12:34:56.1234567' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) >= CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with DATETIME2 on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS char(26)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS varchar(26)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nchar(26)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS nvarchar(26)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS decimal(14,0)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS numeric(14,0)) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS float) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS real) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616123456 AS bigint) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616 AS int) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123 AS tinyint) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(20230616.123456 AS money) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1234.56 AS smallmoney) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS text) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS ntext) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('2023-06-16 12:34:56.1234567' AS datetime2) AS sql_variant) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('<datetime2>2023-06-16 12:34:56.1234567</datetime2>' AS xml) >= CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator with DATETIME2
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) 
        BETWEEN CAST('2023-06-16 14:29:00' AS DATETIME2) 
        AND CAST('2023-06-16 14:31:00' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) 
        BETWEEN CAST('2023-06-16 14:29:00.123' AS DATETIME2(3)) 
        AND CAST('2023-06-16 14:31:00.123' AS DATETIME2(3)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) 
        BETWEEN CAST('2023-06-16 14:29:00.1234567' AS DATETIME2(7)) 
        AND CAST('2023-06-16 14:31:00.1234567' AS DATETIME2(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Different precision tests for BETWEEN
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)) 
        BETWEEN CAST('2023-06-16 14:30:00' AS DATETIME2) 
        AND CAST('2023-06-16 14:31:00' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) 
        BETWEEN CAST('2023-06-16 14:30:00.0000000' AS DATETIME2(7)) 
        AND CAST('2023-06-16 14:31:00.0000000' AS DATETIME2(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Edge cases for BETWEEN
SELECT CASE 
    WHEN CAST('2023-06-16 00:00:00' AS DATETIME2) 
        BETWEEN CAST('2023-06-15 23:59:59' AS DATETIME2) 
        AND CAST('2023-06-16 00:00:01' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 23:59:59.9999999' AS DATETIME2(7)) 
        BETWEEN CAST('2023-06-16 23:59:59' AS DATETIME2) 
        AND CAST('2023-06-17 00:00:00' AS DATETIME2) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator with DATETIME2
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) IN (
        CAST('2023-06-16 14:29:00' AS DATETIME2), 
        CAST('2023-06-16 14:30:00' AS DATETIME2), 
        CAST('2023-06-16 14:31:00' AS DATETIME2)
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.123' AS DATETIME2(3)) IN (
        CAST('2023-06-16 14:29:00.123' AS DATETIME2(3)), 
        CAST('2023-06-16 14:30:00.123' AS DATETIME2(3)), 
        CAST('2023-06-16 14:31:00.123' AS DATETIME2(3))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)) IN (
        CAST('2023-06-16 14:29:00.1234567' AS DATETIME2(7)), 
        CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)), 
        CAST('2023-06-16 14:31:00.1234567' AS DATETIME2(7))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- Different precision tests for IN
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) IN (
        CAST('2023-06-16 14:30:00.0000000' AS DATETIME2(7)), 
        CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)), 
        CAST('2023-06-16 14:30:00.9999999' AS DATETIME2(7))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL with DATETIME2
DECLARE @NullDateTime2 DATETIME2;
SELECT CASE 
    WHEN @NullDateTime2 IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

DECLARE @NullDateTime2 DATETIME2;
SELECT CASE 
    WHEN @NullDateTime2 IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Additional precision tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) = 
         CAST('2023-06-16 14:30:00.0000000' AS DATETIME2(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)) = 
         CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Boundary tests
SELECT CASE 
    WHEN CAST('0001-01-01 00:00:00.0000000' AS DATETIME2(7)) 
        BETWEEN CAST('0001-01-01 00:00:00' AS DATETIME2) 
        AND CAST('9999-12-31 23:59:59.9999999' AS DATETIME2(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Fractional seconds tests
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7)) 
        BETWEEN CAST('2023-06-16 14:30:00.1234566' AS DATETIME2(7)) 
        AND CAST('2023-06-16 14:30:00.1234568' AS DATETIME2(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Mixed precision comparisons
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2) = 
         CAST('2023-06-16 14:30:00.000' AS DATETIME2(3))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00.123' AS DATETIME2(3)) = 
         CAST('2023-06-16 14:30:00.123000' AS DATETIME2(6))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Additional DATETIME2-specific tests
-- Testing different precisions (0-7)
SELECT CASE 
    WHEN CAST('2023-06-16 14:30:00' AS DATETIME2(0)) = 
         CAST('2023-06-16 14:30:00.1234567' AS DATETIME2(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Testing minimum and maximum values
SELECT CASE 
    WHEN CAST('0001-01-01 00:00:00' AS DATETIME2) 
        BETWEEN CAST('0001-01-01 00:00:00' AS DATETIME2) 
        AND CAST('9999-12-31 23:59:59.9999999' AS DATETIME2(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Testing date boundaries
SELECT CASE 
    WHEN CAST('2023-06-16 23:59:59.9999999' AS DATETIME2(7)) < 
         CAST('2023-06-17 00:00:00' AS DATETIME2)
    THEN 'Correct Order' 
    ELSE 'Incorrect Order' 
END;
GO

-- Arithmetic operators
-- Addition with DATETIME2 on left side
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('13:34:56.1234567' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('<number>1</number>' AS XML);
GO

-- Addition with DATETIME2 on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS CHAR(10)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS VARCHAR(10)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NCHAR(10)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NVARCHAR(10)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:00' AS SMALLDATETIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('13:34:56.1234567' AS TIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS DECIMAL(8,0)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS NUMERIC(8,0)) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS FLOAT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS REAL) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS BIGINT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS INT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS SMALLINT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS TINYINT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS MONEY) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS SMALLMONEY) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS BIT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(0x07E30610 AS IMAGE) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS TEXT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NTEXT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('<number>1</number>' AS XML) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO

-- Subtraction with DATETIME2 on left side
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS CHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 11:34:56' AS DATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 11:34:00' AS SMALLDATETIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 11:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('11:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 11:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS FLOAT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS REAL);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS BIGINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS INT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS SMALLINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS TINYINT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS MONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(1 AS BIT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS TEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('1' AS NTEXT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with DATETIME2 on right side
SELECT CAST(0x07E30610 AS BINARY(8)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 13:34:56' AS DATETIME) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 13:34:00' AS SMALLDATETIME) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 13:34:56.1234567' AS DATETIME2) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('13:34:56' AS TIME) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('2023-06-16 13:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS FLOAT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS REAL) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS BIGINT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS INT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS SMALLINT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS TINYINT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS MONEY) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(1 AS BIT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(0x07E30610 AS IMAGE) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS TEXT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('1' AS NTEXT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO

-- 4. DDL testing:

-- 1. Table column with DATETIME2
CREATE TABLE DateTime2Test1 (
    ID INT PRIMARY KEY,
    DateTime2Column DATETIME2(7),  -- Maximum precision
    DefaultDateTime2Column DATETIME2 DEFAULT GETDATE(),
    ComputedDateTime2Column AS DATEADD(hour, 1, DateTime2Column),
    CHECK (DateTime2Column > '2023-01-01 12:00:00')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTime2Test1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table for DATETIME2
CREATE PARTITION FUNCTION DATETIME2_partition_func (DATETIME2) 
    AS RANGE RIGHT FOR VALUES(
        '2023-01-01 06:00:00', 
        '2023-01-01 12:00:00', 
        '2023-01-01 18:00:00'
    );
GO

CREATE PARTITION SCHEME DATETIME2_partition_scheme
    AS PARTITION DATETIME2_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE DATETIME2_partition(
    a DATETIME2(7),
    type VARCHAR(10))
ON DATETIME2_partition_scheme(a);
GO

-- Insert test data for different time periods
INSERT INTO DATETIME2_partition (a, type) VALUES ('2023-01-01 03:30:00', 'Early');
GO
INSERT INTO DATETIME2_partition (a, type) VALUES ('2023-01-01 09:30:00', 'Morning');
GO
INSERT INTO DATETIME2_partition (a, type) VALUES ('2023-01-01 15:30:00', 'Afternoon');
GO
INSERT INTO DATETIME2_partition (a, type) VALUES ('2023-01-01 21:30:00', 'Night');
GO

-- Query to show times in each partition
SELECT a, type, $PARTITION.DATETIME2_partition_func(a) AS PartitionNumber
    FROM DATETIME2_partition ORDER BY PartitionNumber;
GO

-- Query to show count of entries by partition
SELECT $PARTITION.DATETIME2_partition_func(a) AS PartitionNumber, type, COUNT(*) AS DateTime2Count
    FROM DATETIME2_partition
    GROUP BY $PARTITION.DATETIME2_partition_func(a), type
    ORDER BY PartitionNumber;
GO

-- 3. Function returning DateTime2 types
CREATE FUNCTION dbo.GetCurrentDateTime2()
RETURNS DATETIME2
AS
BEGIN
    RETURN CAST('2023-01-01 14:30:00.1234567' AS DATETIME2);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentDateTime2' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes DateTime2 types input
CREATE FUNCTION dbo.AddHoursToDateTime2(
    @InputDateTime2 DATETIME2,
    @HoursToAdd INT
)
RETURNS DATETIME2
AS
BEGIN
    RETURN DATEADD(HOUR, @HoursToAdd, @InputDateTime2);
END;
GO

-- Test the function
SELECT dbo.AddHoursToDateTime2('2023-01-01 14:30:00.1234567', 2) AS Result;
GO
SELECT dbo.AddHoursToDateTime2('2023-01-01 14:30:00.1234567', -2) AS Result;
GO
SELECT dbo.AddHoursToDateTime2('2023-01-01 14:30:00.1234567', 0) AS Result;
GO

-- 5. Procedure takes DateTime2 types input
CREATE PROCEDURE dbo.ProcessDateTime2
    @InputDateTime2 DATETIME2
AS
BEGIN
    SELECT DATEADD(HOUR, 1, @InputDateTime2) AS NextHour;
END;
GO

-- 6. Constraints
ALTER TABLE DateTime2Test1
ADD CONSTRAINT DF_DateTime2Test_DefaultDateTime2Column 
    DEFAULT '2023-01-01 00:00:00' FOR DefaultDateTime2Column;

ALTER TABLE DateTime2Test1
ADD CONSTRAINT CK_DateTime2Test_DateTime2Column 
    CHECK (DateTime2Column > '2023-01-01 00:00:00');

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'DateTime2Test1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key columns
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'DateTime2Test1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views
CREATE VIEW dbo.DateTime2View
AS
SELECT
    ID,
    DateTime2Column,
    DefaultDateTime2Column,
    ComputedDateTime2Column
FROM DateTime2Test1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DateTime2View' ORDER BY COLUMN_NAME;
GO

-- Insert test data with different precisions
INSERT INTO DateTime2Test1 (ID, DateTime2Column) VALUES 
(1, '2023-01-01 14:30:00'),
(2, '2023-01-01 14:30:00.1'),
(3, '2023-01-01 14:30:00.12'),
(4, '2023-01-01 14:30:00.123'),
(5, '2023-01-01 14:30:00.1234'),
(6, '2023-01-01 14:30:00.12345'),
(7, '2023-01-01 14:30:00.123456'),
(8, '2023-01-01 14:30:00.1234567');
GO

-- Test all objects
SELECT * FROM DateTime2Test1 ORDER BY ID;
GO

SELECT * FROM DATETIME2_partition ORDER BY type;
GO

SELECT dbo.GetCurrentDateTime2() AS CurrentDateTime2;
GO

SELECT dbo.AddHoursToDateTime2('2023-01-01 14:30:00.1234567', 2) AS DateTime2After2Hours;
GO

EXEC dbo.ProcessDateTime2 @InputDateTime2 = '2023-01-01 14:30:00.1234567';
GO

SELECT * FROM dbo.DateTime2View ORDER BY ID;
GO

-- Additional datetime2-specific tests
-- Test different datetime2 formats
INSERT INTO DateTime2Test1 (ID, DateTime2Column) VALUES 
(9, '2023-01-01 2:30 PM'),
(10, '2023-01-01 14:30'),
(11, '2023-01-01 14:30:00.0000000');
GO

-- Test boundary conditions
INSERT INTO DateTime2Test1 (ID, DateTime2Column) VALUES 
(12, '0001-01-01 00:00:00'),
(13, '9999-12-31 23:59:59.9999999');
GO

-- Test invalid datetime2 values (these should fail)
INSERT INTO DateTime2Test1 (ID, DateTime2Column) VALUES 
(14, '10000-01-01 00:00:00'),
(15, '2023-01-01 24:00:00'),
(16, '2023-01-01 23:60:00');
GO

-- Test datetime2 arithmetic
SELECT 
    DateTime2Column,
    DATEADD(HOUR, 1, DateTime2Column) AS Plus1Hour,
    DATEADD(MINUTE, 30, DateTime2Column) AS Plus30Minutes,
    DATEADD(SECOND, 15, DateTime2Column) AS Plus15Seconds,
    DATEADD(NANOSECOND, 500, DateTime2Column) AS Plus500Nanoseconds
FROM DateTime2Test1 ORDER BY DateTime2Column;
GO

-- Test datetime2 comparisons
SELECT DateTime2Column
FROM DateTime2Test1
WHERE DateTime2Column BETWEEN '2023-01-01 12:00:00' AND '2023-01-01 16:00:00'
ORDER BY DateTime2Column;
GO

-- Test datetime2 precision handling
SELECT 
    DateTime2Column,
    CAST(DateTime2Column AS DATETIME2(0)) AS Precision0,
    CAST(DateTime2Column AS DATETIME2(1)) AS Precision1,
    CAST(DateTime2Column AS DATETIME2(2)) AS Precision2,
    CAST(DateTime2Column AS DATETIME2(3)) AS Precision3,
    CAST(DateTime2Column AS DATETIME2(4)) AS Precision4,
    CAST(DateTime2Column AS DATETIME2(5)) AS Precision5,
    CAST(DateTime2Column AS DATETIME2(6)) AS Precision6,
    CAST(DateTime2Column AS DATETIME2(7)) AS Precision7
FROM DateTime2Test1 ORDER BY DateTime2Column;
GO

-- 5. DML testing:
-- Create test tables for DATETIME2
CREATE TABLE DateTime2DMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleDateTime DATETIME2,
    DefaultDateTime DATETIME2 DEFAULT NULL,
    ComputedDateTime AS DATEADD(minute, 30, SimpleDateTime),
    Description NVARCHAR(100)
);
GO

CREATE TABLE DateTime2DMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildDateTime DATETIME2,
    FOREIGN KEY (ParentID) REFERENCES DateTime2DMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description) 
VALUES ('2023-06-16 14:30:20.1234567', 'Single row insertion');
GO

-- Bulk insertion
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES 
('2023-06-16 09:15:00', 'Bulk insertion 1'),
('2023-06-16 12:30:45.123', 'Bulk insertion 2'),
('2023-06-16 17:45:30.5567', 'Bulk insertion 3');
GO

-- Insert with type casting
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES (CAST('2023-06-16 14:30:20' AS DATETIME2), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES (DATEADD(minute, 30, CAST('2023-06-16 14:30:20' AS DATETIME2)), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO DateTime2DMLTest (SimpleDateTime, DefaultDateTime, Description)
VALUES ('2023-06-16 15:45:00', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM DateTime2DMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE DateTime2DMLTest
SET SimpleDateTime = '2023-06-16 16:00:00'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE DateTime2DMLTest
SET SimpleDateTime = '2023-06-16 16:30:00',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE DateTime2DMLTest
SET SimpleDateTime = DATEADD(hour, 1, SimpleDateTime)
WHERE ID = 3;
GO

-- Mass update
UPDATE DateTime2DMLTest
SET Description = 'Mass updated';
GO

-- Conditional update
UPDATE DateTime2DMLTest
SET SimpleDateTime = '2023-06-16 09:00:00'
WHERE SimpleDateTime < '2023-06-16 12:00:00';
GO

-- Verify updates
SELECT * FROM DateTime2DMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO DateTime2DMLTestChild (ParentID, ChildDateTime)
VALUES 
(1, '2023-06-16 09:00:00'),
(2, '2023-06-16 10:15:30'),
(3, '2023-06-16 11:45:00'),
(4, '2023-06-16 13:20:15'),
(5, '2023-06-16 15:00:00');
GO

-- Single row deletion
DELETE FROM DateTime2DMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM DateTime2DMLTest;
GO

-- Conditional deletion
DELETE FROM DateTime2DMLTest 
WHERE SimpleDateTime < '2023-06-16 12:00:00';
GO

-- Cascade deletion
DELETE FROM DateTime2DMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM DateTime2DMLTest ORDER BY ID;
SELECT * FROM DateTime2DMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES ('2023-06-16 14:00:00', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleDateTime, ComputedDateTime, Description
FROM DateTime2DMLTest
WHERE SimpleDateTime = '2023-06-16 14:00:00';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE DateTime2DMLTest
    SET ComputedDateTime = '2023-06-16 15:00:00'
    WHERE SimpleDateTime = '2023-06-16 14:00:00';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE DateTime2DMLTest
SET SimpleDateTime = '2023-06-16 15:00:00'
WHERE SimpleDateTime = '2023-06-16 14:00:00';
GO

SELECT ID, SimpleDateTime, ComputedDateTime, Description
FROM DateTime2DMLTest
WHERE SimpleDateTime = '2023-06-16 15:00:00';
GO

-- 5. Additional DML scenarios

-- Insert with subquery
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
SELECT DATEADD(hour, 1, MAX(SimpleDateTime)), 'Inserted from subquery'
FROM DateTime2DMLTest;
GO

-- Update with JOIN
UPDATE t
SET t.SimpleDateTime = DATEADD(minute, 30, c.ChildDateTime)
FROM DateTime2DMLTest t
JOIN DateTime2DMLTestChild c ON t.ID = c.ParentID;
GO

-- Delete with subquery
DELETE FROM DateTime2DMLTest
WHERE SimpleDateTime IN (
    SELECT ChildDateTime
    FROM DateTime2DMLTestChild
);
GO

-- Insert various datetime2 formats
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES 
('2023-06-16 13:30', 'Date with hours and minutes only'),
('2023-06-16 13:30:45', 'Date with hours, minutes, and seconds'),
('2023-06-16 13:30:45.1234567', 'Date with full precision'),
('2023-06-16 13:30:45.1234567', 'Maximum precision');
GO

-- Test boundary values
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES 
('0001-01-01 00:00:00.0000000', 'Minimum datetime2'),
('9999-12-31 23:59:59.9999999', 'Maximum datetime2'),
('2023-06-16 12:00:00', 'Noon'),
('2023-06-16 00:00:00', 'Midnight');
GO

-- Test datetime2 arithmetic
UPDATE DateTime2DMLTest
SET SimpleDateTime = DATEADD(nanosecond, 100, SimpleDateTime)
WHERE ID IN (SELECT TOP 1 ID FROM DateTime2DMLTest ORDER BY ID);
GO

-- Test datetime2 comparisons
DELETE FROM DateTime2DMLTest
WHERE SimpleDateTime BETWEEN '2023-06-16 12:00:00' AND '2023-06-16 13:00:00';
GO

-- Test different precisions
INSERT INTO DateTime2DMLTest (SimpleDateTime, Description)
VALUES 
('2023-06-16 13:30:45.1', 'Precision 1'),
('2023-06-16 13:30:45.12', 'Precision 2'),
('2023-06-16 13:30:45.123', 'Precision 3'),
('2023-06-16 13:30:45.1234', 'Precision 4'),
('2023-06-16 13:30:45.12345', 'Precision 5'),
('2023-06-16 13:30:45.123456', 'Precision 6'),
('2023-06-16 13:30:45.1234567', 'Precision 7');
GO

-- Final verification
SELECT * FROM DateTime2DMLTest ORDER BY ID;
SELECT * FROM DateTime2DMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table for DATETIME2
CREATE TABLE DateTime2IndexTest (
    ID INT IDENTITY PRIMARY KEY,
    DateTime2Column DATETIME2(7),
    DateTime2Column2 DATETIME2(7),
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data with full date-time values
INSERT INTO DateTime2IndexTest (DateTime2Column, DateTime2Column2, Description, NumericColumn)
VALUES 
('2023-01-01 00:00:00.0000000', '2023-01-01 12:00:00.0000000', 'Midnight to Noon', 1),
('2023-01-01 06:15:30.1234567', '2023-01-01 18:15:30.1234567', 'Morning to Evening', 2),
('2023-01-01 09:30:45.5555555', '2023-01-01 21:30:45.5555555', 'Work hours', 3),
('2023-01-01 12:45:15.7777777', '2023-01-01 23:45:15.7777777', 'Lunch time', 4),
('2023-01-01 15:20:10.9999999', '2023-01-02 03:20:10.9999999', 'Afternoon', 5);
GO

-- 1. Index on single column
CREATE INDEX IX_DateTime2IndexTest_DateTime2Column 
ON DateTime2IndexTest(DateTime2Column);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 00:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple columns
CREATE INDEX IX_DateTime2IndexTest_DateTime2Column_DateTime2Column2 
ON DateTime2IndexTest(DateTime2Column, DateTime2Column2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 00:00:00.0000000' 
AND DateTime2Column2 = '2023-01-01 12:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- 3. Usability of index with different operators in predicate

-- Equality
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 00:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- Range
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column BETWEEN '2023-01-01 09:00:00' AND '2023-01-01 17:00:00' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- LIKE (converted to string)
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE CAST(DateTime2Column AS VARCHAR(30)) LIKE '2023-01-01 09:%';
SET STATISTICS IO OFF;
GO

-- IN
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column IN (
    '2023-01-01 00:00:00.0000000',
    '2023-01-01 06:15:30.1234567',
    '2023-01-01 12:00:00.0000000'
) ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Comparing different data types with implicit conversions

-- DATETIME2 to VARCHAR
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '20230101 00:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- DATETIME2 to DATETIME
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = CAST('2023-01-01 00:00:00' AS DATETIME);
SET STATISTICS IO OFF;
GO

-- DATETIME2 arithmetic
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = DATEADD(MINUTE, 360, '2023-01-01 00:00:00.0000000');
SET STATISTICS IO OFF;
GO

-- 5. DML operations with indexes

-- INSERT
SET STATISTICS IO ON;
INSERT INTO DateTime2IndexTest (DateTime2Column, DateTime2Column2, Description, NumericColumn)
VALUES ('2023-01-01 18:30:00.0000000', '2023-01-02 06:30:00.0000000', 'Evening', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE
SET STATISTICS IO ON;
UPDATE DateTime2IndexTest 
SET DateTime2Column = '2023-01-01 19:00:00.0000000' 
WHERE DateTime2Column = '2023-01-01 18:30:00.0000000';
SET STATISTICS IO OFF;
GO

-- DELETE
SET STATISTICS IO ON;
DELETE FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 19:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Create a filtered index for business hours
CREATE INDEX IX_DateTime2IndexTest_Filtered ON DateTime2IndexTest(DateTime2Column)
WHERE DateTime2Column >= '2023-01-01 09:00:00' 
AND DateTime2Column <= '2023-01-01 17:00:00';
GO

-- Test filtered index
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 12:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- Create an index with included columns
CREATE INDEX IX_DateTime2IndexTest_DateTime2Column_Include 
ON DateTime2IndexTest(DateTime2Column)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT DateTime2Column, Description, NumericColumn 
FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 09:30:45.5555555';
SET STATISTICS IO OFF;
GO

-- 7. Index usage for datetime functions

-- DATEPART function
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DATEPART(HOUR, DateTime2Column) = 12;
SET STATISTICS IO OFF;
GO

-- DATEADD function
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = DATEADD(MINUTE, 30, '2023-01-01 12:00:00.0000000');
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WITH (INDEX(IX_DateTime2IndexTest_DateTime2Column))
WHERE DateTime2Column = '2023-01-01 00:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WITH (INDEX(0))
WHERE DateTime2Column = '2023-01-01 00:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- 9. DateTime2-specific scenarios

-- Precision comparisons
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 06:15:30.1234567';
SET STATISTICS IO OFF;
GO

-- Date range queries
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE DateTime2Column >= '2023-01-01' 
AND DateTime2Column < '2023-01-02' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- Time component queries
SET STATISTICS IO ON;
SELECT * FROM DateTime2IndexTest 
WHERE CAST(DateTime2Column AS TIME) BETWEEN '09:00:00' AND '17:00:00' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- DateTime arithmetic
SET STATISTICS IO ON;
SELECT *, 
    DATEADD(HOUR, 1, DateTime2Column) AS HourLater,
    DATEADD(MINUTE, -30, DateTime2Column) AS HalfHourEarlier
FROM DateTime2IndexTest 
WHERE DateTime2Column = '2023-01-01 12:00:00.0000000';
SET STATISTICS IO OFF;
GO

-- 7. Expression Testing:
-- Create test table for DATETIME2
CREATE TABLE DateTime2ExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    DateTime2Column DATETIME2(7),
    NullableDateTime2Column DATETIME2(7) NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data with full datetime2 values
INSERT INTO DateTime2ExpressionTest (DateTime2Column, NullableDateTime2Column, Description)
VALUES 
('2023-06-16 00:00:00.0000000', '2023-06-16 00:00:00.0000000', 'Midnight'),
('2023-06-16 06:00:00.0000000', '2023-06-16 06:00:00.0000000', 'Morning'),
('2023-06-16 09:30:00.0000000', NULL, 'Morning Break'),
('2023-06-16 12:00:00.0000000', '2023-06-16 12:00:00.0000000', 'Noon'),
('2023-06-16 13:30:00.0000000', NULL, 'Afternoon Break'),
('2023-06-16 15:45:30.1234567', '2023-06-16 15:45:30.1234567', 'Late Afternoon'),
('2023-06-16 17:30:00.0000000', '2023-06-16 17:30:00.0000000', 'End of Day'),
('2023-06-16 18:15:00.0000000', NULL, 'Evening'),
('2023-06-16 20:00:00.0000000', '2023-06-16 20:00:00.0000000', 'Night'),
('2023-06-16 21:30:45.9876543', '2023-06-16 21:30:45.9876543', 'Late Night'),
('2023-06-16 22:45:00.0000000', NULL, 'Late Night'),
('2023-06-16 23:59:59.9999999', '2023-06-16 23:59:59.9999999', 'Almost Midnight');
GO

-- 1. Conditional Expressions

-- CASE statements
SELECT 
    DateTime2Column,
    CASE 
        WHEN CAST(DateTime2Column AS TIME) BETWEEN '06:00' AND '11:59' THEN 'Morning'
        WHEN CAST(DateTime2Column AS TIME) BETWEEN '12:00' AND '16:59' THEN 'Afternoon'
        WHEN CAST(DateTime2Column AS TIME) BETWEEN '17:00' AND '20:59' THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    Description
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- COALESCE
SELECT 
    ID,
    COALESCE(NullableDateTime2Column, DateTime2Column, '2023-06-16 00:00:00.0000000') AS CoalescedDateTime2,
    Description
FROM DateTime2ExpressionTest ORDER BY ID;
GO

-- NULLIF operations
SELECT 
    ID,
    NULLIF(DateTime2Column, '2023-06-16 00:00:00.0000000') AS NullIfMidnight,
    Description
FROM DateTime2ExpressionTest ORDER BY ID;
GO

-- IIF statements
SELECT 
    DateTime2Column,
    IIF(DATEPART(HOUR, DateTime2Column) < 12, 'AM', 'PM') AS AMPM,
    Description
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- 2. Aggregate Expressions

-- MAX
SELECT MAX(DateTime2Column) AS LatestDateTime2 FROM DateTime2ExpressionTest;
GO

-- MIN
SELECT MIN(DateTime2Column) AS EarliestDateTime2 FROM DateTime2ExpressionTest;
GO

-- UNIONS
SELECT DateTime2Column 
FROM DateTime2ExpressionTest 
WHERE DATEPART(HOUR, DateTime2Column) < 12
UNION
SELECT DateTime2Column 
FROM DateTime2ExpressionTest 
WHERE DATEPART(HOUR, DateTime2Column) > 20
ORDER BY DateTime2Column;
GO

-- COUNT
SELECT 
    COUNT(DateTime2Column) AS TotalDateTime2s, 
    COUNT(DISTINCT DateTime2Column) AS UniqueDateTime2s 
FROM DateTime2ExpressionTest;
GO

-- 3. Additional Expression Tests

-- DateTime2 arithmetic
SELECT 
    DateTime2Column,
    DATEADD(HOUR, 1, DateTime2Column) AS OneHourLater,
    DATEADD(MINUTE, 30, DateTime2Column) AS ThirtyMinutesLater,
    DATEADD(SECOND, 15, DateTime2Column) AS FifteenSecondsLater,
    DATEADD(NANOSECOND, 1000000, DateTime2Column) AS OneMillisecondLater
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- DateTime2 parts
SELECT 
    DateTime2Column,
    DATEPART(YEAR, DateTime2Column) AS Year,
    DATEPART(MONTH, DateTime2Column) AS Month,
    DATEPART(DAY, DateTime2Column) AS Day,
    DATEPART(HOUR, DateTime2Column) AS Hour,
    DATEPART(MINUTE, DateTime2Column) AS Minute,
    DATEPART(SECOND, DateTime2Column) AS Second,
    DATEPART(MILLISECOND, DateTime2Column) AS Millisecond,
    DATEPART(MICROSECOND, DateTime2Column) AS Microsecond,
    DATEPART(NANOSECOND, DateTime2Column) AS Nanosecond
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- DateTime2 differences
SELECT 
    t1.DateTime2Column AS DateTime2_1,
    t2.DateTime2Column AS DateTime2_2,
    DATEDIFF(HOUR, t1.DateTime2Column, t2.DateTime2Column) AS HoursDiff,
    DATEDIFF(MINUTE, t1.DateTime2Column, t2.DateTime2Column) AS MinutesDiff,
    DATEDIFF(SECOND, t1.DateTime2Column, t2.DateTime2Column) AS SecondsDiff,
    DATEDIFF(MILLISECOND, t1.DateTime2Column, t2.DateTime2Column) AS MillisecondsDiff,
    DATEDIFF(MICROSECOND, t1.DateTime2Column, t2.DateTime2Column) AS MicrosecondsDiff,
    DATEDIFF(NANOSECOND, t1.DateTime2Column, t2.DateTime2Column) AS NanosecondsDiff
FROM DateTime2ExpressionTest t1
CROSS JOIN DateTime2ExpressionTest t2
WHERE t1.ID < t2.ID ORDER BY t2.DateTime2Column;
GO

-- Complex conditional expressions
SELECT 
    DateTime2Column,
    CASE 
        WHEN DATEPART(HOUR, DateTime2Column) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, DateTime2Column) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, DateTime2Column) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    CASE 
        WHEN DATEPART(HOUR, DateTime2Column) < 12 THEN 'AM'
        ELSE 'PM'
    END AS AMPM,
    IIF(CAST(DateTime2Column AS TIME) BETWEEN '09:00' AND '17:00', 'Business Hours', 'Off Hours') AS BusinessHours
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- Window functions
SELECT 
    DateTime2Column,
    Description,
    LAG(DateTime2Column) OVER (ORDER BY DateTime2Column) AS PreviousDateTime2,
    LEAD(DateTime2Column) OVER (ORDER BY DateTime2Column) AS NextDateTime2,
    DATEDIFF(MINUTE, 
        LAG(DateTime2Column) OVER (ORDER BY DateTime2Column), 
        DateTime2Column) AS MinutesSincePrevious
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- Grouping and aggregation
SELECT 
    DATEPART(HOUR, DateTime2Column) AS Hour,
    COUNT(*) AS DateTime2Count,
    MIN(DateTime2Column) AS EarliestDateTime2,
    MAX(DateTime2Column) AS LatestDateTime2
FROM DateTime2ExpressionTest
GROUP BY DATEPART(HOUR, DateTime2Column)
ORDER BY Hour;
GO

-- Precision tests
SELECT 
    DateTime2Column,
    CAST(DateTime2Column AS DATETIME2(0)) AS Precision0,
    CAST(DateTime2Column AS DATETIME2(1)) AS Precision1,
    CAST(DateTime2Column AS DATETIME2(2)) AS Precision2,
    CAST(DateTime2Column AS DATETIME2(3)) AS Precision3,
    CAST(DateTime2Column AS DATETIME2(4)) AS Precision4,
    CAST(DateTime2Column AS DATETIME2(5)) AS Precision5,
    CAST(DateTime2Column AS DATETIME2(6)) AS Precision6,
    CAST(DateTime2Column AS DATETIME2(7)) AS Precision7
FROM DateTime2ExpressionTest
WHERE DATEPART(HOUR, DateTime2Column) > 21 ORDER BY DateTime2Column;
GO

-- Conversion tests
SELECT 
    DateTime2Column,
    CAST(DateTime2Column AS VARCHAR(50)) AS StringDateTime2,
    CAST(CAST(DateTime2Column AS VARCHAR(50)) AS DATETIME2) AS BackToDateTime2,
    CAST(DateTime2Column AS DATETIME) AS ToDateTime,
    CAST(DateTime2Column AS DATE) AS DateOnly,
    CAST(DateTime2Column AS TIME) AS TimeOnly
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- Error handling tests
BEGIN TRY
    DECLARE @dt2 DATETIME2 = '9999-12-31 23:59:59.9999999';
    SET @dt2 = DATEADD(DAY, 1, @dt2);
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

-- Test invalid datetime2 values
BEGIN TRY
    SELECT CAST('9999-13-31 23:59:59.9999999' AS DATETIME2);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid formats
BEGIN TRY
    SELECT CAST('2023-06-16 24:00:00' AS DATETIME2);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- DateTime2 arithmetic with date components
SELECT 
    DateTime2Column,
    DATEADD(DAY, 1, DateTime2Column) AS NextDay,
    DATEADD(MONTH, 1, DateTime2Column) AS NextMonth,
    DATEADD(YEAR, 1, DateTime2Column) AS NextYear,
    DATEADD(NANOSECOND, 100, DateTime2Column) AS Add100Nanoseconds
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- Format conversion tests
SELECT 
    DateTime2Column,
    FORMAT(DateTime2Column, 'yyyy-MM-dd HH:mm:ss.fffffff') AS FullFormat,
    FORMAT(DateTime2Column, 'MM/dd/yyyy hh:mm:ss tt') AS USFormat,
    FORMAT(DateTime2Column, 'dd/MM/yyyy HH:mm:ss') AS UKFormat
FROM DateTime2ExpressionTest ORDER BY DateTime2Column;
GO

-- 10. Additional Tests:

-- Test DATE_BUCKET function with DATETIME2
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:20.1234567';
SELECT 
    DATE_BUCKET(HOUR, 1, @dt2),
    DATE_BUCKET(MINUTE, 1, @dt2),
    DATE_BUCKET(SECOND, 1, @dt2);
GO

-- Test with different precisions
SELECT 
    CAST('2023-06-16 14:30:20' AS DATETIME2) AS [Default],
    CAST('2023-06-16 14:30:20.1' AS DATETIME2(1)) AS [1 digit],
    CAST('2023-06-16 14:30:20.12' AS DATETIME2(2)) AS [2 digits],
    CAST('2023-06-16 14:30:20.123' AS DATETIME2(3)) AS [3 digits],
    CAST('2023-06-16 14:30:20.1234' AS DATETIME2(4)) AS [4 digits],
    CAST('2023-06-16 14:30:20.12345' AS DATETIME2(5)) AS [5 digits],
    CAST('2023-06-16 14:30:20.123456' AS DATETIME2(6)) AS [6 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(7)) AS [7 digits];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(DATETIME2, '2023-06-16 14:30:20', 108),     -- yyyy-mm-dd hh:mm:ss
    CONVERT(DATETIME2, '2023-06-16 02:30:20 PM', 100),  -- mm/dd/yyyy hh:mm:ss AM/PM
    CONVERT(DATETIME2, '2023-06-16 14.30.20', 104),     -- dd.mm.yyyy hh.mm.ss
    CONVERT(DATETIME2, '2023-06-16 14:30:20.1234567', 114);  -- yyyy-mm-dd hh:mm:ss.nnnnnnn
GO

-- Test AM/PM formats
SELECT 
    CAST('2023-06-16 2:30:20 PM' AS DATETIME2) AS [PM time],
    CAST('2023-06-16 2:30:20 AM' AS DATETIME2) AS [AM time],
    CAST('2023-06-16 14:30:20' AS DATETIME2) AS [24-hour format];
GO

-- Test with different separators
SELECT 
    CAST('2023-06-16 14:30:20' AS DATETIME2) AS [Standard separators],
    CAST('2023.06.16 14.30.20' AS DATETIME2) AS [Period separators],
    CAST('2023 06 16 14 30 20' AS DATETIME2) AS [Space separators];
GO

-- Test datetime2 arithmetic
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:20.1234567';
SELECT 
    DATEADD(HOUR, 1, @dt2) AS [Add 1 hour],
    DATEADD(HOUR, -1, @dt2) AS [Subtract 1 hour],
    DATEADD(MINUTE, 30, @dt2) AS [Add 30 minutes],
    DATEADD(SECOND, 15, @dt2) AS [Add 15 seconds],
    DATEADD(MILLISECOND, 500, @dt2) AS [Add 500 milliseconds],
    DATEADD(MICROSECOND, 500, @dt2) AS [Add 500 microseconds],
    DATEADD(NANOSECOND, 500, @dt2) AS [Add 500 nanoseconds];
GO

-- Test datetime2 extraction
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:20.1234567';
SELECT 
    DATEPART(YEAR, @dt2) AS [Year],
    DATEPART(MONTH, @dt2) AS [Month],
    DATEPART(DAY, @dt2) AS [Day],
    DATEPART(HOUR, @dt2) AS [Hour],
    DATEPART(MINUTE, @dt2) AS [Minute],
    DATEPART(SECOND, @dt2) AS [Second],
    DATEPART(MILLISECOND, @dt2) AS [Millisecond],
    DATEPART(MICROSECOND, @dt2) AS [Microsecond],
    DATEPART(NANOSECOND, @dt2) AS [Nanosecond];
GO

-- Test with SET LANGUAGE (for date and AM/PM format)
SET LANGUAGE Italian;
SELECT CAST('2023-06-16 14:30:20' AS DATETIME2);
GO
SET LANGUAGE English;
SELECT CAST('2023-06-16 2:30:20 PM' AS DATETIME2);
GO

-- Test datetime2 range
SELECT 
    CAST('0001-01-01 00:00:00.0000000' AS DATETIME2(7)) AS [Minimum DATETIME2],
    CAST('9999-12-31 23:59:59.9999999' AS DATETIME2(7)) AS [Maximum DATETIME2];
GO

-- Test rounding behavior
SELECT 
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(7)) AS [7 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(6)) AS [6 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(5)) AS [5 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(4)) AS [4 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(3)) AS [3 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(2)) AS [2 digits],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(1)) AS [1 digit],
    CAST('2023-06-16 14:30:20.1234567' AS DATETIME2(0)) AS [0 digits];
GO

-- Test invalid datetime2 formats (these should fail)
SELECT CAST('2023-06-16 25:00:00' AS DATETIME2);  -- Invalid hour
GO
SELECT CAST('2023-06-16 14:60:00' AS DATETIME2);  -- Invalid minute
GO
SELECT CAST('2023-06-16 14:30:60' AS DATETIME2);  -- Invalid second
GO
SELECT CAST('2023-13-16 14:30:20' AS DATETIME2);  -- Invalid month
GO
SELECT CAST('2023-06-31 14:30:20' AS DATETIME2);  -- Invalid day
GO

-- Test with fractional time components
SELECT 
    CAST('2023-06-16 14:30.5:20' AS DATETIME2) AS [Half minute],
    CAST('2023-06-16 14.5:30:20' AS DATETIME2) AS [Half hour];
GO

-- Test timezone conversion
DECLARE @dt2 DATETIME2 = '2023-06-16 14:30:20.1234567';
SELECT 
    @dt2 AS [Original DateTime2],
    CAST(CAST(@dt2 AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS DATETIME2) AS [Pacific Time];
GO

-- Test with different date formats
SELECT CAST('20230616 14:30:20.1234567' AS DATETIME2) AS [YYYYMMDD],
       CAST('06/16/2023 14:30:20.1234567' AS DATETIME2) AS [MM/DD/YYYY],
       CAST('16.06.2023 14:30:20.1234567' AS DATETIME2) AS [DD.MM.YYYY];
GO

-- Test with different date styles
SET DATEFORMAT mdy;
SELECT CAST('06-16-2023 14:30:20.1234567' AS DATETIME2);
GO
SET DATEFORMAT dmy;
SELECT CAST('16-06-2023 14:30:20.1234567' AS DATETIME2);
GO
SET DATEFORMAT ymd;
SELECT CAST('2023-06-16 14:30:20.1234567' AS DATETIME2);
GO
SET DATEFORMAT mdy;
GO

-- Test with different language date formats
SET LANGUAGE French;
SELECT CAST('16 juin 2023 14:30:20.1234567' AS DATETIME2);
GO
SET LANGUAGE German;
SELECT CAST('16. Juni 2023 14:30:20.1234567' AS DATETIME2);
GO
SET LANGUAGE English;
SELECT CAST('June 16, 2023 14:30:20.1234567' AS DATETIME2);
GO

-- Create a test table for DATETIME2 precision testing
CREATE TABLE DateTime2ScaleTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    DateTime2Value DATETIME2(7),
    Scale INT,
    Precision INT,
    StorageBytes INT,
    FractionalPrecision INT,
    FormattedValue NVARCHAR(50)
);
GO

-- Helper function to calculate storage bytes for DATETIME2
CREATE FUNCTION CalculateDateTime2StorageBytes(@scale INT)
RETURNS INT
AS
BEGIN
    RETURN CASE 
        WHEN @scale <= 2 THEN 6
        WHEN @scale <= 4 THEN 7
        ELSE 8
    END;
END;
GO

-- Helper procedure for testing DATETIME2 scales
CREATE PROCEDURE TestDateTime2Scale
    @description NVARCHAR(100),
    @dateTimeStr NVARCHAR(50),
    @scale INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @dateTime2Value DATETIME2(7);
    DECLARE @precision INT;
    DECLARE @fractionalPrecision INT;
    
    SET @sql = N'DECLARE @dt DATETIME2(' + CAST(@scale AS NVARCHAR(1)) + ') = ''' + @dateTimeStr + ''';';
    SET @sql += N'SELECT @dtv = CAST(@dt AS DATETIME2(7));';
    
    BEGIN TRY
        EXEC sp_executesql @sql, N'@dtv DATETIME2(7) OUTPUT', @dtv = @dateTime2Value OUTPUT;
        
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
        SET @fractionalPrecision = @scale;
        
        INSERT INTO DateTime2ScaleTest (
            Description, 
            DateTime2Value, 
            Scale, 
            Precision, 
            StorageBytes, 
            FractionalPrecision,
            FormattedValue
        )
        VALUES (
            @description,
            @dateTime2Value,
            @scale,
            @precision,
            dbo.CalculateDateTime2StorageBytes(@scale),
            @fractionalPrecision,
            CONVERT(NVARCHAR(50), @dateTime2Value, 121)
        );
        
        PRINT 'Success: ' + @description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @description + ' - ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Test cases for each scale
-- Scale 0 (6 bytes)
EXEC TestDateTime2Scale 'DT2(0) Basic', '2023-06-16 14:30:20', 0;
GO
EXEC TestDateTime2Scale 'DT2(0) Round Down', '2023-06-16 14:30:20.4', 0;
GO
EXEC TestDateTime2Scale 'DT2(0) Round Up', '2023-06-16 14:30:20.5', 0;
GO

-- Scale 1 (6 bytes)
EXEC TestDateTime2Scale 'DT2(1) Basic', '2023-06-16 14:30:20.1', 1;
GO
EXEC TestDateTime2Scale 'DT2(1) Round Down', '2023-06-16 14:30:20.14', 1;
GO
EXEC TestDateTime2Scale 'DT2(1) Round Up', '2023-06-16 14:30:20.15', 1;
GO

-- Scale 2 (6 bytes)
EXEC TestDateTime2Scale 'DT2(2) Basic', '2023-06-16 14:30:20.12', 2;
GO
EXEC TestDateTime2Scale 'DT2(2) Round Down', '2023-06-16 14:30:20.124', 2;
GO
EXEC TestDateTime2Scale 'DT2(2) Round Up', '2023-06-16 14:30:20.125', 2;
GO

-- Scale 3 (7 bytes)
EXEC TestDateTime2Scale 'DT2(3) Basic', '2023-06-16 14:30:20.123', 3;
GO
EXEC TestDateTime2Scale 'DT2(3) Round Down', '2023-06-16 14:30:20.1234', 3;
GO
EXEC TestDateTime2Scale 'DT2(3) Round Up', '2023-06-16 14:30:20.1235', 3;
GO

-- Scale 4 (7 bytes)
EXEC TestDateTime2Scale 'DT2(4) Basic', '2023-06-16 14:30:20.1234', 4;
GO
EXEC TestDateTime2Scale 'DT2(4) Round Down', '2023-06-16 14:30:20.12344', 4;
GO
EXEC TestDateTime2Scale 'DT2(4) Round Up', '2023-06-16 14:30:20.12345', 4;
GO

-- Scale 5 (8 bytes)
EXEC TestDateTime2Scale 'DT2(5) Basic', '2023-06-16 14:30:20.12345', 5;
GO
EXEC TestDateTime2Scale 'DT2(5) Round Down', '2023-06-16 14:30:20.123454', 5;
GO
EXEC TestDateTime2Scale 'DT2(5) Round Up', '2023-06-16 14:30:20.123455', 5;
GO

-- Scale 6 (8 bytes)
EXEC TestDateTime2Scale 'DT2(6) Basic', '2023-06-16 14:30:20.123456', 6;
GO
EXEC TestDateTime2Scale 'DT2(6) Round Down', '2023-06-16 14:30:20.1234564', 6;
GO
EXEC TestDateTime2Scale 'DT2(6) Round Up', '2023-06-16 14:30:20.1234565', 6;
GO

-- Scale 7 (8 bytes)
EXEC TestDateTime2Scale 'DT2(7) Basic', '2023-06-16 14:30:20.1234567', 7;
GO
EXEC TestDateTime2Scale 'DT2(7) Maximum', '9999-12-31 23:59:59.9999999', 7;
GO
EXEC TestDateTime2Scale 'DT2(7) Minimum', '0001-01-01 00:00:00.0000000', 7;
GO

-- Edge cases for each scale
-- Testing boundary values
EXEC TestDateTime2Scale 'DT2(0) Boundary', '9999-12-31 23:59:59.999999', 0;
GO
EXEC TestDateTime2Scale 'DT2(1) Boundary', '9999-12-31 23:59:59.999999', 1;
GO
EXEC TestDateTime2Scale 'DT2(2) Boundary', '9999-12-31 23:59:59.999999', 2;
GO
EXEC TestDateTime2Scale 'DT2(3) Boundary', '9999-12-31 23:59:59.999999', 3;
GO
EXEC TestDateTime2Scale 'DT2(4) Boundary', '9999-12-31 23:59:59.999999', 4;
GO
EXEC TestDateTime2Scale 'DT2(5) Boundary', '9999-12-31 23:59:59.999999', 5;
GO
EXEC TestDateTime2Scale 'DT2(6) Boundary', '9999-12-31 23:59:59.999999', 6;
GO
EXEC TestDateTime2Scale 'DT2(7) Boundary', '9999-12-31 23:59:59.999999', 7;
GO

-- Testing precision overflow
EXEC TestDateTime2Scale 'DT2(0) Overflow', '2023-06-16 14:30:20.1234567890', 0;
GO
EXEC TestDateTime2Scale 'DT2(3) Overflow', '2023-06-16 14:30:20.1234567890', 3;
GO
EXEC TestDateTime2Scale 'DT2(7) Overflow', '2023-06-16 14:30:20.1234567890', 7;
GO

-- Display results with detailed analysis
SELECT 
    ID,
    Description,
    DateTime2Value,
    Scale,
    Precision,
    StorageBytes,
    FractionalPrecision,
    FormattedValue,
    LEN(FormattedValue) AS FormattedLength,
    CASE 
        WHEN Scale <= 2 THEN '0-2 (6 bytes)'
        WHEN Scale <= 4 THEN '3-4 (7 bytes)'
        ELSE '5-7 (8 bytes)'
    END AS ScaleGroup
FROM DateTime2ScaleTest
ORDER BY Scale, ID;
GO

-- Clean up: Drop all created objects
DROP FUNCTION CalculateDateTime2StorageBytes;
DROP PROCEDURE TestDateTime2Scale;
DROP TABLE DateTime2ScaleTest;
DROP INDEX IX_DateTime2IndexTest_DateTime2Column_Include ON DateTime2IndexTest;
DROP INDEX IX_DateTime2IndexTest_Filtered ON DateTime2IndexTest;
DROP INDEX IX_DateTime2IndexTest_DateTime2Column_DateTime2Column2 ON DateTime2IndexTest;
DROP INDEX IX_DateTime2IndexTest_DateTime2Column ON DateTime2IndexTest;
DROP INDEX IX_BusinessDateTime2 ON UDDTDateTime2Test;
DROP INDEX IX_ShiftDateTime2 ON UDDTDateTime2Test;
DROP TABLE Datetime2Test;
DROP TABLE Datetime2DefaultTest;
DROP FUNCTION dbo.GetCurrentDateTime2;
DROP TABLE DateTime2FormatTest;
DROP PROCEDURE InsertDateTime2Test;
DROP PROCEDURE InsertDateTime2Test1;
DROP PROCEDURE TestDateTime2Format;
DROP TABLE DateTime2ConversionTest;
DROP PROCEDURE InsertDateTime2ConversionTest;
DROP TABLE DateTime2ZoneTest;
DROP PROCEDURE InsertDateTime2ZoneTest;
DROP TABLE UDDTDateTime2Test;
DROP PROCEDURE TestUDDTDateTime2Proc;
DROP TYPE BusinessDateTime2;
DROP TYPE ShiftDateTime2;
DROP TYPE PreciseDateTime2;
DROP FUNCTION dbo.TestDateTime2Function;
DROP TABLE DateTime2ImplicitConversionTest;
DROP PROCEDURE InsertDateTime2TestResult;
DROP FUNCTION dbo.AddHoursToDateTime2;
DROP PROCEDURE dbo.ProcessDateTime2;
DROP VIEW dbo.DateTime2View;
DROP TABLE DateTime2DMLTestChild;
DROP TABLE DateTime2DMLTest;
DROP TABLE DateTime2IndexTest;
DROP TABLE DateTime2ExpressionTest;
DROP TABLE DateTime2Test1;
DROP TABLE DATETIME2_partition;
DROP PARTITION SCHEME DATETIME2_partition_scheme;
DROP PARTITION FUNCTION DATETIME2_partition_func;
GO
