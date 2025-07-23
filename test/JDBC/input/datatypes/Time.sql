-- sla 200000
-- 1. Basic Testing:
-- Create TimeTest table with different scale precisions
CREATE TABLE TimeTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    Time0 TIME(0),  -- Precision: seconds
    Time3 TIME(3),  -- Precision: milliseconds
    Time7 TIME(7)   -- Precision: 100 nanoseconds
);
GO

-- NULL and empty values
INSERT INTO TimeTest (Description, InputString, Time0, Time3, Time7)
VALUES ('NULL value', NULL, NULL, NULL, NULL);
GO

DECLARE @EmptyTime TIME;
INSERT INTO TimeTest (Description, InputString, Time0, Time3, Time7)
VALUES ('Empty TIME variable', NULL, @EmptyTime, @EmptyTime, @EmptyTime);
GO

SELECT * FROM TimeTest WHERE Time0 IS NULL ORDER BY ID;
GO
SELECT * FROM TimeTest ORDER BY ID;
GO

-- Default values
CREATE TABLE TimeDefaultTest (
    ID INT PRIMARY KEY,
    TimeCol Time,
    TimeCol1 Time(4),
    TimeCol2 Time(6)
);
INSERT INTO TimeDefaultTest VALUES (1, CAST('0001-01-01' As time), CAST('0001-01-01' As time), CAST('0001-01-01' As time));
SELECT * FROM TimeDefaultTest ORDER BY ID;
GO

-- Character length
DECLARE @d TIME = '  19:00:00  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

DECLARE @d TIME(3) = '  19:00:00.0000000  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

DECLARE @d TIME(7) = '  19:00:00.0000000  ';
SELECT LEN(CAST(@d AS VARCHAR(30)));
GO

-- Edge case values with different scales
DECLARE @t1 TIME(0) = '00:00:00';
DECLARE @t2 TIME(7) = '00:00:00.0000000';
DECLARE @t3 TIME(0) = '23:59:59';
-- DECLARE @t4 TIME(7) = '23:59:59.9999999';
SELECT @t1, @t2, @t3;
GO

-- Implicit/assignment/explicit type conversion
DECLARE @d TIME;
SET @d = '19:00:00';
SELECT @d, CAST('19:00:00' AS TIME), CONVERT(TIME, '19:00:00');
GO

-- Create a test table for TIME
CREATE TABLE TimeFormatTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ParsedTime TIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertTimeTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO TimeFormatTest (Description, InputString, ParsedTime)
        VALUES (@Description, @InputString, CAST(@InputString AS TIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 1. Standard 24-hour format tests
EXEC InsertTimeTest '24hr - Full precision', '14:30:20.123456';
GO

EXEC InsertTimeTest '24hr - Seconds only', '14:30:20';
GO

EXEC InsertTimeTest '24hr - Minutes only', '14:30';
GO

EXEC InsertTimeTest '24hr - Hours only', '14';
GO

-- 2. AM/PM format tests
EXEC InsertTimeTest '12hr - AM Full', '10:30:20.123456 AM';
GO

EXEC InsertTimeTest '12hr - PM Full', '02:30:20.123456 PM';
GO

EXEC InsertTimeTest '12hr - AM Simple', '10:30 AM';
GO

EXEC InsertTimeTest '12hr - PM Simple', '02:30 PM';
GO

-- 3. Different separators
EXEC InsertTimeTest 'Separator - Colon', '14:30:20';
GO

EXEC InsertTimeTest 'Separator - Period', '14.30.20';
GO

EXEC InsertTimeTest 'Separator - Space', '14 30 20';
GO

-- 4. Precision variations
EXEC InsertTimeTest 'Precision - 7 digits', '14:30:20.123456';
GO

EXEC InsertTimeTest 'Precision - 6 digits', '14:30:20.123456';
GO

EXEC InsertTimeTest 'Precision - 5 digits', '14:30:20.12345';
GO

EXEC InsertTimeTest 'Precision - 4 digits', '14:30:20.1234';
GO

EXEC InsertTimeTest 'Precision - 3 digits', '14:30:20.123';
GO

EXEC InsertTimeTest 'Precision - 2 digits', '14:30:20.12';
GO

EXEC InsertTimeTest 'Precision - 1 digit', '14:30:20.1';
GO

-- 5. Edge cases
EXEC InsertTimeTest 'Edge - Midnight', '00:00:00';
GO

EXEC InsertTimeTest 'Edge - Almost midnight', '23:59:59.99999';
GO

EXEC InsertTimeTest 'Edge - Noon', '12:00:00';
GO

EXEC InsertTimeTest 'Edge - Almost noon', '11:59:59.99999';
GO

-- 6. Leading zeros variations
EXEC InsertTimeTest 'Zeros - With leading', '08:05:02';
GO

EXEC InsertTimeTest 'Zeros - Without leading', '8:5:2';
GO

-- 7. AM/PM variations
EXEC InsertTimeTest 'AMPM - AM variations 1', '8:30 AM';
GO

EXEC InsertTimeTest 'AMPM - AM variations 2', '8:30AM';
GO

EXEC InsertTimeTest 'AMPM - AM variations 3', '8:30 am';
GO

EXEC InsertTimeTest 'AMPM - AM variations 4', '8:30am';
GO

EXEC InsertTimeTest 'AMPM - PM variations 1', '8:30 PM';
GO

EXEC InsertTimeTest 'AMPM - PM variations 2', '8:30PM';
GO

EXEC InsertTimeTest 'AMPM - PM variations 3', '8:30 pm';
GO

EXEC InsertTimeTest 'AMPM - PM variations 4', '8:30pm';
GO

-- 8. ISO 8601 format
EXEC InsertTimeTest 'ISO - Basic', 'T14:30:20';
GO

EXEC InsertTimeTest 'ISO - With milliseconds', 'T14:30:20.123456';
GO

-- 9. ODBC canonical format
EXEC InsertTimeTest 'ODBC canonical', '{t ''14:30:20''}';
GO

-- 10. Different cultures/formats
SET LANGUAGE French;
GO
EXEC InsertTimeTest 'French time format', '14.30.20';
GO

SET LANGUAGE German;
GO
EXEC InsertTimeTest 'German time format', '14.30.20';
GO

SET LANGUAGE us_english;
GO

-- 11. Invalid formats (these should fail)
EXEC InsertTimeTest 'Invalid - Hour too high', '25:00:00';
GO

EXEC InsertTimeTest 'Invalid - Minute too high', '14:60:00';
GO

EXEC InsertTimeTest 'Invalid - Second too high', '14:30:60';
GO

EXEC InsertTimeTest 'Invalid - Too many fractional digits', '14:30:20.12345678';
GO

EXEC InsertTimeTest 'Invalid - Wrong separators', '14-30-20';
GO

EXEC InsertTimeTest 'Invalid - Extra spaces', '14 : 30 : 20';
GO

-- 12. Fractional seconds variations
EXEC InsertTimeTest 'Fractional - Trailing zeros', '14:30:20.1000000';
GO

EXEC InsertTimeTest 'Fractional - Mixed precision', '14:30:20.123456';
GO

EXEC InsertTimeTest 'Fractional - Single digit', '14:30:20.5';
GO

-- 13. Time with timezone (should fail as TIME doesn't store timezone)
EXEC InsertTimeTest 'Invalid - With timezone', '14:30:20-07:00';
GO

-- 14. Mixed format variations
EXEC InsertTimeTest 'Mixed - 24hr with ms', '14:30:20.1234567';
GO

EXEC InsertTimeTest 'Mixed - 12hr with ms AM', '02:30:20.1234567 AM';
GO

EXEC InsertTimeTest 'Mixed - 12hr with ms PM', '02:30:20.1234567 PM';
GO

-- 15. Special cases
EXEC InsertTimeTest 'Special - Midnight AM', '12:00:00 AM';
GO

EXEC InsertTimeTest 'Special - Noon PM', '12:00:00 PM';
GO

EXEC InsertTimeTest 'Special - Midnight 24hr', '00:00:00';
GO

EXEC InsertTimeTest 'Special - Noon 24hr', '12:00:00';
GO

-- Helper procedure to insert test cases for TIME
CREATE PROCEDURE InsertTimeTest1
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50),
    @Collation NVARCHAR(100)
AS
BEGIN
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO TimeFormatTest (Description, InputString, Collation, ParsedTime)
            VALUES (@Description, @InputString, @Collation, CAST(@InputString COLLATE ' + @Collation + N' AS TIME))';
        
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
CREATE PROCEDURE TestTimeFormat
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
        EXEC InsertTimeTest1 @Description, @InputString, @Collation;
        FETCH NEXT FROM collation_cursor INTO @Collation;
    END
    
    CLOSE collation_cursor;
    DEALLOCATE collation_cursor;
END
GO

-- Standard time formats
EXEC TestTimeFormat 'Time - 24hr full precision', '14:30:20.1234567';
GO
EXEC TestTimeFormat 'Time - 24hr with seconds', '14:30:20';
GO
EXEC TestTimeFormat 'Time - 24hr without seconds', '14:30';
GO
EXEC TestTimeFormat 'Time - 24hr hours only', '14';
GO

-- AM/PM formats
EXEC TestTimeFormat 'Time - 12hr AM full', '10:30:20.1234567 AM';
GO
EXEC TestTimeFormat 'Time - 12hr PM full', '02:30:20.1234567 PM';
GO
EXEC TestTimeFormat 'Time - 12hr AM simple', '10:30 AM';
GO
EXEC TestTimeFormat 'Time - 12hr PM simple', '02:30 PM';
GO

-- Different separators
EXEC TestTimeFormat 'Time - Colon separator', '14:30:20';
GO
EXEC TestTimeFormat 'Time - Period separator', '14.30.20';
GO
EXEC TestTimeFormat 'Time - Space separator', '14 30 20';
GO
EXEC TestTimeFormat 'Time - No separator', '143020';
GO

-- Precision variations
EXEC TestTimeFormat 'Time - 1 decimal place', '14:30:20.1';
GO
EXEC TestTimeFormat 'Time - 3 decimal places', '14:30:20.123';
GO
EXEC TestTimeFormat 'Time - 5 decimal places', '14:30:20.12345';
GO
EXEC TestTimeFormat 'Time - 7 decimal places', '14:30:20.1234567';
GO

-- Leading zeros variations
EXEC TestTimeFormat 'Time - With leading zeros', '04:05:06';
GO
EXEC TestTimeFormat 'Time - Without leading zeros', '4:5:6';
GO

-- Edge cases
EXEC TestTimeFormat 'Time - Midnight', '00:00:00';
GO
EXEC TestTimeFormat 'Time - Almost midnight', '23:59:59.999999';
GO
EXEC TestTimeFormat 'Time - Noon', '12:00:00';
GO
EXEC TestTimeFormat 'Time - Almost noon', '11:59:59.999999';
GO

-- ISO 8601 format
EXEC TestTimeFormat 'Time - ISO basic', 'T143020';
GO
EXEC TestTimeFormat 'Time - ISO extended', 'T14:30:20';
GO

-- ODBC canonical format
EXEC TestTimeFormat 'Time - ODBC canonical', '{t ''14:30:20''}';
GO

-- AM/PM variations
EXEC TestTimeFormat 'Time - AM variations 1', '12:00 AM';
GO
EXEC TestTimeFormat 'Time - AM variations 2', '12:00AM';
GO
EXEC TestTimeFormat 'Time - PM variations 1', '12:00 PM';
GO
EXEC TestTimeFormat 'Time - PM variations 2', '12:00PM';
GO

-- Different hour formats
EXEC TestTimeFormat 'Time - Hour 0', '00:30:20';
GO
EXEC TestTimeFormat 'Time - Hour 12 AM', '12:30:20 AM';
GO
EXEC TestTimeFormat 'Time - Hour 12 PM', '12:30:20 PM';
GO
EXEC TestTimeFormat 'Time - Hour 24', '24:00:00';
GO

-- Invalid formats (these should fail)
EXEC TestTimeFormat 'Invalid - Hour too high', '25:00:00';
GO
EXEC TestTimeFormat 'Invalid - Minute too high', '14:60:00';
GO
EXEC TestTimeFormat 'Invalid - Second too high', '14:30:60';
GO
EXEC TestTimeFormat 'Invalid - Too many decimals', '14:30:20.12345678';
GO
EXEC TestTimeFormat 'Invalid - Bad format', '14;30;20';
GO

-- Mixed formats
EXEC TestTimeFormat 'Mixed - Different separators', '14:30.20';
GO
EXEC TestTimeFormat 'Mixed - Partial precision', '14:30:20.';
GO

-- Language-specific formats
SET LANGUAGE French;
GO
EXEC TestTimeFormat 'French time format', '14:30:20';
GO

SET LANGUAGE German;
GO
EXEC TestTimeFormat 'German time format', '14:30:20';
GO

SET LANGUAGE us_english;
GO

-- Display results
SELECT * FROM TimeFormatTest ORDER BY ID;
GO

-- Create a test table for TIME
CREATE TABLE TimeConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    InputString NVARCHAR(50),
    ConvertedTime TIME
);
GO

-- Helper procedure to insert test cases
CREATE PROCEDURE InsertTimeConversionTest
    @Description NVARCHAR(100),
    @InputString NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        INSERT INTO TimeConversionTest (Description, InputString, ConvertedTime)
        VALUES (@Description, @InputString, CAST(@InputString AS TIME));
        PRINT 'Success: ' + @Description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @Description + ' - ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ODBC TIME
EXEC InsertTimeConversionTest 'ODBC TIME', '{t ''12:34:56''}';
GO

-- ODBC DATETIME (should extract time part)
EXEC InsertTimeConversionTest 'ODBC DATETIME', '{ts ''2023-06-16 12:34:56''}';
GO

-- Basic time formats
EXEC InsertTimeConversionTest 'Basic 24hr time', '14:30:00';
GO

EXEC InsertTimeConversionTest 'Basic AM time', '09:30:00 AM';
GO

EXEC InsertTimeConversionTest 'Basic PM time', '02:30:00 PM';
GO

-- Time with different precisions
EXEC InsertTimeConversionTest 'Time with hours only', '14';
GO

EXEC InsertTimeConversionTest 'Time with hours and minutes', '14:30';
GO

EXEC InsertTimeConversionTest 'Time with seconds', '14:30:45';
GO

EXEC InsertTimeConversionTest 'Time with milliseconds', '14:30:45.123';
GO

EXEC InsertTimeConversionTest 'Time with microseconds', '14:30:45.123456';
GO

EXEC InsertTimeConversionTest 'Time with nanoseconds', '14:30:45.123456789';
GO

-- Different time separators
EXEC InsertTimeConversionTest 'Time with colon separator', '14:30:45';
GO

EXEC InsertTimeConversionTest 'Time with period separator', '14.30.45';
GO

EXEC InsertTimeConversionTest 'Time with space separator', '14 30 45';
GO

-- AM/PM variations
EXEC InsertTimeConversionTest 'AM time with space', '09:30:00 AM';
GO

EXEC InsertTimeConversionTest 'AM time without space', '09:30:00AM';
GO

EXEC InsertTimeConversionTest 'PM time with space', '09:30:00 PM';
GO

EXEC InsertTimeConversionTest 'PM time without space', '09:30:00PM';
GO

EXEC InsertTimeConversionTest 'Lowercase am', '09:30:00 am';
GO

EXEC InsertTimeConversionTest 'Lowercase pm', '09:30:00 pm';
GO

EXEC InsertTimeConversionTest 'Mixed case AM', '09:30:00 Am';
GO

EXEC InsertTimeConversionTest 'Mixed case PM', '09:30:00 Pm';
GO

-- Edge cases
EXEC InsertTimeConversionTest 'Midnight start of day', '00:00:00';
GO

EXEC InsertTimeConversionTest 'Midnight end of day', '25:00:00';
GO

EXEC InsertTimeConversionTest 'Last moment of day', '23:59:59.999999';
GO

EXEC InsertTimeConversionTest 'Noon 24hr', '12:00:00';
GO

EXEC InsertTimeConversionTest 'Noon AM/PM', '12:00:00 PM';
GO

-- Time from full datetime string
EXEC InsertTimeConversionTest 'Time from datetime', '2023-06-16 14:30:45';
GO

EXEC InsertTimeConversionTest 'Time from datetime with ms', '2023-06-16 14:30:45.123';
GO

-- Invalid formats (should fail)
EXEC InsertTimeConversionTest 'Invalid hour', '25:00:00';
GO

EXEC InsertTimeConversionTest 'Invalid minute', '14:60:00';
GO

EXEC InsertTimeConversionTest 'Invalid second', '14:30:60';
GO

EXEC InsertTimeConversionTest 'Invalid millisecond', '14:30:45.1234567890';
GO

EXEC InsertTimeConversionTest 'Invalid format', '1430:45';
GO

-- Time zones (should extract time part)
EXEC InsertTimeConversionTest 'Time with timezone', '14:30:45 +05:30';
GO

EXEC InsertTimeConversionTest 'Time with timezone and ms', '14:30:45.123 +05:30';
GO

-- Different styles of writing time
EXEC InsertTimeConversionTest 'Military time', '1430';
GO

EXEC InsertTimeConversionTest 'Hours only AM', '9 AM';
GO

EXEC InsertTimeConversionTest 'Hours only PM', '2 PM';
GO

-- ISO 8601 format
EXEC InsertTimeConversionTest 'ISO 8601 basic', 'T143045';
GO

EXEC InsertTimeConversionTest 'ISO 8601 extended', 'T14:30:45';
GO

EXEC InsertTimeConversionTest 'ISO 8601 with ms', 'T14:30:45.123';
GO

-- Display results
SELECT 
    ID,
    Description,
    InputString,
    ConvertedTime,
    CAST(ConvertedTime AS NVARCHAR(30)) AS TimeString
FROM TimeConversionTest 
ORDER BY ID;
GO

-- Metadata in system views/catalogs
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, is_table_type FROM sys.types WHERE name = 'time';
GO

-- System catalog Views
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE DATA_TYPE = 'time' ORDER BY COLUMN_NAME, ORDINAL_POSITION, TABLE_NAME;
GO

-- Precedence Order of datatypes
SELECT CASE WHEN CAST('19:00:00' AS TIME) = '19:00:00' THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Basic binding value testing for prepare-exec/RPC calls
EXEC sp_executesql N'SELECT @d', N'@d TIME', @d = '19:00:00';
GO

-- 1. Create User-Defined Data Types based on TIME
CREATE TYPE BusinessTime FROM TIME(7);
CREATE TYPE ShiftTime FROM TIME(0);
CREATE TYPE PreciseTime FROM TIME(7);
GO

-- 2. Create a table using the User-Defined Data Types
CREATE TABLE UDDTTimeTest (
    ID INT PRIMARY KEY,
    RegularTime TIME,
    BusinessTimeCol BusinessTime,
    ShiftTimeCol ShiftTime,
    PreciseTimeCol PreciseTime
);
GO

-- 3. Insert data into the table
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES 
(1, '09:00:00', '09:00:00.000000', '09:00:00', '09:00:00.123456'),
(2, '12:30:45', '12:30:45.123456', '12:30:00', '12:30:45.123456'),
(3, '17:45:30', '17:45:30.000000', '17:45:00', '17:45:30.999999'),
(4, NULL, NULL, NULL, NULL);
GO

-- 4. Query the table
SELECT * FROM UDDTTimeTest ORDER BY ID;
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
WHERE TABLE_NAME = 'UDDTTimeTest' ORDER BY COLUMN_NAME;
GO

-- 6. Test conversions
SELECT 
    ID,
    CAST(RegularTime AS VARCHAR(20)) AS RegularTimeString,
    CAST(BusinessTimeCol AS VARCHAR(30)) AS BusinessTimeString,
    CAST(ShiftTimeCol AS VARCHAR(20)) AS ShiftTimeString,
    CAST(PreciseTimeCol AS VARCHAR(30)) AS PreciseTimeString,
    CAST(RegularTime AS DATETIME) AS RegularDateTime,
    CAST(BusinessTimeCol AS DATETIME) AS BusinessDateTime
FROM UDDTTimeTest ORDER BY ID;
GO

-- 7. Test time functions
SELECT 
    ID,
    DATEADD(HOUR, 1, RegularTime) AS RegularNextHour,
    DATEADD(HOUR, 1, BusinessTimeCol) AS BusinessNextHour,
    DATEADD(MINUTE, 30, ShiftTimeCol) AS ShiftNextHalfHour,
    DATEDIFF(MINUTE, ShiftTimeCol, BusinessTimeCol) AS MinutesBetween
FROM UDDTTimeTest ORDER BY ID;
GO

-- 8. Test constraints
ALTER TABLE UDDTTimeTest ADD CONSTRAINT CK_BusinessTime 
    CHECK (BusinessTimeCol >= '09:00:00' AND BusinessTimeCol <= '17:00:00');
GO

-- This should succeed
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES (5, '10:00:00', '10:00:00', '10:00:00', '10:00:00.123456');
GO

-- This should fail
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES (6, '18:00:00', '18:00:00', '18:00:00', '18:00:00.123456');
GO

-- 9. Create a stored procedure that uses the UDDTs
CREATE PROCEDURE TestUDDTTimeProc
    @BusinessTime BusinessTime,
    @ShiftTime ShiftTime
AS
BEGIN
    SELECT 
        @BusinessTime AS InputBusinessTime,
        @ShiftTime AS InputShiftTime,
        DATEDIFF(MINUTE, @ShiftTime, @BusinessTime) AS MinutesBetween;
END
GO

-- Execute the stored procedure
EXEC TestUDDTTimeProc @BusinessTime = '10:30:00', @ShiftTime = '09:00:00';
GO

-- 10. Test implicit conversions
DECLARE @RegularTime TIME = '10:30:00';
DECLARE @BusinessTime BusinessTime = @RegularTime;
DECLARE @ShiftTime ShiftTime = '09:00:00';
DECLARE @PreciseTime PreciseTime = '10:30:00.123456';

SELECT 
    @RegularTime AS RegularTime,
    @BusinessTime AS BusinessTime,
    @ShiftTime AS ShiftTime,
    @PreciseTime AS PreciseTime;
GO

-- 11. Test ordering and indexing
CREATE INDEX IX_BusinessTime ON UDDTTimeTest(BusinessTimeCol);
CREATE INDEX IX_ShiftTime ON UDDTTimeTest(ShiftTimeCol);
GO

-- Check if indexes are used
SET STATISTICS IO ON;
SELECT * FROM UDDTTimeTest WHERE BusinessTimeCol = '10:00:00';
SELECT * FROM UDDTTimeTest WHERE ShiftTimeCol = '09:00:00';
SET STATISTICS IO OFF;
GO

-- 12. Test with different time formats
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES 
(7, '13:00:00', '13:00:00', '13:00:00', '13:00:00.123456'),
(8, '1:00:00 PM', '13:00:00', '13:00:00', '13:00:00.123456');
GO

-- 13. Test precision handling
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES 
(9, '14:30:45.1234567', '14:30:45.123456', '14:30:00', '14:30:45.123456'),
(10, '14:30:45.999999', '14:30:45.999999', '14:30:00', '14:30:45.999999');
GO

-- 14. Test arithmetic operations
SELECT 
    ID,
    BusinessTimeCol,
    DATEADD(MILLISECOND, 500, BusinessTimeCol) AS AddMilliseconds,
    DATEADD(SECOND, 30, BusinessTimeCol) AS AddSeconds,
    DATEADD(MINUTE, -15, BusinessTimeCol) AS SubtractMinutes
FROM UDDTTimeTest ORDER BY ID;
GO

-- 15. Test boundary conditions
INSERT INTO UDDTTimeTest (ID, RegularTime, BusinessTimeCol, ShiftTimeCol, PreciseTimeCol)
VALUES 
(11, '00:00:00.000000', '00:00:00.000000', '00:00:00', '00:00:00.000000'),
(12, '23:59:59.999999', '23:59:59.999999', '23:59:00', '23:59:59.999999');
GO

-- 16. Test with different time components
SELECT 
    ID,
    DATEPART(HOUR, BusinessTimeCol) AS BusinessHour,
    DATEPART(MINUTE, BusinessTimeCol) AS BusinessMinute,
    DATEPART(SECOND, BusinessTimeCol) AS BusinessSecond,
    DATEPART(MILLISECOND, BusinessTimeCol) AS BusinessMillisecond
FROM UDDTTimeTest ORDER BY ID;
GO

-- Display final results
SELECT * FROM UDDTTimeTest ORDER BY ID;
GO

-- 2. Datatype Conversions:

-- CAST/CONVERT/TRY_CAST/TRY_CONVERT/FORMAT testing
SELECT 
    CAST('00:00:00' AS TIME),
    CONVERT(TIME, '00:00:00'),
    TRY_CAST('00:00:00' AS TIME),
    TRY_CONVERT(TIME, '00:00:00'),
    FORMAT(CAST('00:00:00' AS TIME), 'hh:mm:ss');
GO

-- Explicit Conversion to TIME
-- binary
SELECT CAST(CAST(0x0000A8C0 AS binary) AS TIME); -- Positive: 12:34:56
GO
SELECT CAST(CAST(0x AS binary) AS TIME);
GO
SELECT CAST(CAST(0xFFFFFFFF AS binary) AS TIME); -- Will raise an error
GO

-- varbinary
SELECT CAST(CAST(0x0000A8C0 AS VARBINARY) AS TIME); -- Positive: 12:34:56
GO
SELECT CAST(0x AS TIME); -- Will raise an error
GO
SELECT CAST(CAST(0xFFFFFFFF AS VARBINARY) AS TIME);
GO

-- char
SELECT CAST(CAST('12:34:56' AS char) AS TIME); -- Positive
GO
SELECT CAST(CAST('12:34:56.1234567' AS char) AS TIME); -- Positive with fraction
GO
SELECT CAST(CAST('12:34' AS char(5)) AS TIME); -- Positive: HH:MI
GO
SELECT CAST(CAST('invalid' AS char) AS TIME); -- Will raise an error
GO
SELECT CAST(CAST(NULL AS char) AS TIME);
GO
SELECT CAST(CAST('' AS char) AS TIME);
GO

-- varchar
SELECT CAST(CAST('23:59:59.999999' AS varchar) AS TIME); -- Edge: Max time
GO
SELECT CAST(CAST('25:00:00' AS varchar) AS TIME); -- Will raise an error
GO
SELECT CAST(CAST('12:34:56' AS varchar) AS TIME); -- Positive
GO
SELECT CAST(CAST('12:34' AS varchar(5)) AS TIME); -- Positive: HH:MI
GO
SELECT CAST(CAST('invalid' AS varchar) AS TIME); -- Will raise an error
GO
SELECT CAST(CAST(NULL AS varchar) AS TIME);
GO
SELECT CAST(CAST('' AS varchar) AS TIME);
GO

-- nchar
SELECT CAST(CAST(N'12:34:56' AS NCHAR) AS TIME); -- Positive
GO
SELECT CAST(CAST(N'12:34:56.123456' AS NCHAR) AS TIME); -- Positive with fraction
GO
SELECT CAST(CAST(N'00:00:00' AS NCHAR) AS TIME); -- Edge: Min time
GO
SELECT CAST(CAST(N'25:00:00' AS NCHAR) AS TIME); -- Will raise an error
GO
SELECT CAST(CAST(NULL AS nchar) AS TIME);
GO
SELECT CAST(CAST(N'' AS nchar) AS TIME);
GO

-- nvarchar
SELECT CAST(N'12:34:56' AS TIME); -- Positive
GO
SELECT CAST(N'12:34:56.123456' AS TIME); -- Positive with fraction
GO
SELECT CAST(N'invalid' AS TIME); -- Will raise an error
GO

-- time
SELECT CAST(CAST('12:34:56' AS TIME) AS TIME); -- Positive
GO
SELECT CAST(CAST('23:59:59.999999' AS TIME) AS TIME); -- Edge: Max time
GO

-- datetime
SELECT CAST(CAST('2023-06-16 12:34:56' AS DATETIME) AS TIME); -- Positive
GO
SELECT CAST(CAST('1753-01-01 00:00:00' AS DATETIME) AS TIME); -- Min datetime
GO

-- smalldatetime
SELECT CAST(CAST('2023-06-16 12:34:00' AS SMALLDATETIME) AS TIME); -- Positive
GO
SELECT CAST(CAST('1900-01-01 00:00:00' AS SMALLDATETIME) AS TIME); -- Min smalldatetime
GO

-- datetime2
SELECT CAST(CAST('2023-06-16 12:34:56.123457' AS DATETIME2) AS TIME); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.999999' AS DATETIME2) AS TIME); -- Max datetime2
GO

-- date
SELECT CAST(CAST('2023-06-16' AS DATE) AS TIME); -- Will return 00:00:00
GO

-- datetimeoffset
SELECT CAST(CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) AS TIME); -- Positive
GO
SELECT CAST(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET) AS TIME); -- Max datetimeoffset
GO

-- decimal
SELECT CAST(CAST(123456 AS DECIMAL(6,0)) AS TIME); -- Positive
GO
SELECT CAST(CAST(235959 AS DECIMAL(6,0)) AS TIME); -- Edge: Max valid time
GO
SELECT CAST(CAST(240000 AS DECIMAL(6,0)) AS TIME); -- Will raise an error
GO

-- numeric
SELECT CAST(CAST(123456 AS NUMERIC(6,0)) AS TIME); -- Positive
GO
SELECT CAST(CAST(000000 AS NUMERIC(6,0)) AS TIME); -- Edge: Min time
GO
SELECT CAST(CAST(-1 AS NUMERIC(6,0)) AS TIME); -- Will raise an error
GO

-- float
SELECT CAST(CAST(123456 AS FLOAT) AS TIME); -- Positive
GO
SELECT CAST(CAST(235959.9999999 AS FLOAT) AS TIME); -- Edge case
GO
SELECT CAST(CAST(-1 AS FLOAT) AS TIME); -- Will raise an error
GO

-- real
SELECT CAST(CAST(123456 AS REAL) AS TIME); -- Positive
GO
SELECT CAST(CAST(235959.99 AS REAL) AS TIME); -- Edge case
GO
SELECT CAST(CAST(-1 AS REAL) AS TIME); -- Will raise an error
GO

-- bigint
SELECT CAST(CAST(123456 AS BIGINT) AS TIME); -- Positive
GO
SELECT CAST(CAST(235959 AS BIGINT) AS TIME); -- Edge: Max valid time
GO
SELECT CAST(CAST(-1 AS BIGINT) AS TIME); -- Will raise an error
GO

-- int
SELECT CAST(123456 AS TIME); -- Positive
GO
SELECT CAST(000000 AS TIME); -- Edge: Min time
GO
SELECT CAST(-1 AS TIME); -- Will raise an error
GO

-- smallint
SELECT CAST(CAST(1234 AS SMALLINT) AS TIME); -- Positive
GO
SELECT CAST(CAST(32767 AS SMALLINT) AS TIME); -- Max smallint
GO
SELECT CAST(CAST(-1 AS SMALLINT) AS TIME); -- Will raise an error
GO

-- tinyint
SELECT CAST(CAST(12 AS TINYINT) AS TIME); -- Positive
GO
SELECT CAST(CAST(255 AS TINYINT) AS TIME); -- Max tinyint
GO
SELECT CAST(CAST(0 AS TINYINT) AS TIME); -- Min time
GO

-- money
SELECT CAST(CAST(123456 AS MONEY) AS TIME); -- Positive
GO
SELECT CAST(CAST(235959.9999 AS MONEY) AS TIME); -- Edge case
GO
SELECT CAST(CAST(-1 AS MONEY) AS TIME); -- Will raise an error
GO

-- smallmoney
SELECT CAST(CAST(123456 AS SMALLMONEY) AS TIME); -- Positive
GO
SELECT CAST(CAST(214748.3647 AS SMALLMONEY) AS TIME); -- Max smallmoney
GO
SELECT CAST(CAST(-1 AS SMALLMONEY) AS TIME); -- Will raise an error
GO

-- bit
SELECT CAST(CAST(1 AS BIT) AS TIME); -- Will raise an error
GO
SELECT CAST(CAST(0 AS BIT) AS TIME); -- Will raise an error
GO

-- uniqueidentifier
SELECT CAST(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) AS TIME); -- Will raise an error
GO

-- text
SELECT CAST(CAST('12:34:56' AS TEXT) AS TIME); -- Positive
GO
SELECT CAST(CAST('invalid' AS TEXT) AS TIME); -- Will raise an error
GO

-- ntext
SELECT CAST(CAST(N'12:34:56' AS NTEXT) AS TIME); -- Positive
GO
SELECT CAST(CAST(N'invalid' AS NTEXT) AS TIME); -- Will raise an error
GO

-- xml
SELECT CAST(CAST('<time>12:34:56</time>' AS XML) AS TIME); -- Will raise an error
GO

-- sql_variant
SELECT CAST(CAST(CAST('12:34:56' AS TIME) AS SQL_VARIANT) AS TIME); -- Positive
GO

-- geometry
SELECT CAST(geometry::STGeomFromText('POINT(1 1)', 0) AS TIME); -- Will raise an error
GO

-- geography
SELECT CAST(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326) AS TIME); -- Will raise an error
GO

-- Create a function that takes a TIME parameter
CREATE FUNCTION dbo.TestTimeFunction(@TimeParam TIME)
RETURNS TIME
AS
BEGIN
    RETURN @TimeParam;
END
GO

-- binary
SELECT dbo.TestTimeFunction(CAST(0x0A1E2D3C AS binary)); -- Time equivalent
GO
SELECT dbo.TestTimeFunction(CAST(0x AS binary));
GO
SELECT dbo.TestTimeFunction(CAST(0xFFFFFFFF AS binary));
GO

-- varbinary
SELECT dbo.TestTimeFunction(CAST(0x0A1E2D3C AS VARBINARY)); -- Time equivalent
GO
SELECT dbo.TestTimeFunction(0x);
GO
SELECT dbo.TestTimeFunction(CAST(0xFFFFFFFF AS VARBINARY));
GO

-- char
SELECT dbo.TestTimeFunction(CAST('14:30:20' AS char)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('14:30:20.123456' AS char)); -- Positive with fractional seconds
GO
SELECT dbo.TestTimeFunction(CAST('14:30' AS char(5))); -- Positive without seconds
GO
SELECT dbo.TestTimeFunction(CAST('invalid' AS char));
GO
SELECT dbo.TestTimeFunction(CAST(NULL AS char));
GO
SELECT dbo.TestTimeFunction(CAST('' AS char));
GO

-- varchar
SELECT dbo.TestTimeFunction(CAST('23:59:59.999999' AS varchar)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST('25:00:00' AS varchar)); -- Negative: Invalid hour
GO
SELECT dbo.TestTimeFunction(CAST('14:30:20' AS varchar)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('14:30' AS varchar(5))); -- Positive without seconds
GO
SELECT dbo.TestTimeFunction(CAST('2:30 PM' AS varchar)); -- Positive: 12-hour format
GO
SELECT dbo.TestTimeFunction(CAST('invalid' AS varchar));
GO
SELECT dbo.TestTimeFunction(CAST(NULL AS varchar));
GO
SELECT dbo.TestTimeFunction(CAST('' AS varchar));
GO

-- nchar
SELECT dbo.TestTimeFunction(CAST(N'14:30:20' AS NCHAR)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST(N'14:30' AS NCHAR(5))); -- Positive without seconds
GO
SELECT dbo.TestTimeFunction(CAST(N'00:00:00' AS NCHAR)); -- Edge: Min time
GO
SELECT dbo.TestTimeFunction(CAST(N'25:00:00' AS NCHAR)); -- Negative: Invalid hour
GO
SELECT dbo.TestTimeFunction(CAST(NULL AS nchar));
GO
SELECT dbo.TestTimeFunction(CAST(N'' AS nchar));
GO

-- nvarchar
SELECT dbo.TestTimeFunction(N'14:30:20'); -- Positive
GO
SELECT dbo.TestTimeFunction(N'14:30:20.123456'); -- Positive with fractional seconds
GO
SELECT dbo.TestTimeFunction(N'2:30 PM'); -- Positive: 12-hour format
GO

-- time
SELECT dbo.TestTimeFunction(CAST('14:30:20' AS TIME)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('23:59:59.999999' AS TIME)); -- Edge: Max time
GO

-- datetime
SELECT dbo.TestTimeFunction(CAST('2023-06-16 14:30:20' AS DATETIME)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('1753-01-01 00:00:00' AS DATETIME)); -- Edge: Min datetime
GO

-- smalldatetime
SELECT dbo.TestTimeFunction(CAST('2023-06-16 14:30:00' AS SMALLDATETIME)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('1900-01-01 00:00:00' AS SMALLDATETIME)); -- Edge: Min smalldatetime
GO

-- datetime2
SELECT dbo.TestTimeFunction(CAST('2023-06-16 14:30:20.123456' AS DATETIME2)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('9999-12-31 23:59:59.999999' AS DATETIME2)); -- Edge: Max datetime2
GO

-- date
SELECT dbo.TestTimeFunction(CAST('2023-06-16' AS DATE)); -- Negative: Will raise an error
GO

-- datetimeoffset
SELECT dbo.TestTimeFunction(CAST('2023-06-16 14:30:20.1234567 +01:00' AS DATETIMEOFFSET)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('9999-12-31 23:59:59.9999999 +14:00' AS DATETIMEOFFSET)); -- Edge
GO

-- decimal
SELECT dbo.TestTimeFunction(CAST(143020 AS DECIMAL(6,0))); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959 AS DECIMAL(6,0))); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(0 AS DECIMAL(6,0))); -- Edge: Min time
GO

-- numeric
SELECT dbo.TestTimeFunction(CAST(143020 AS NUMERIC(6,0))); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(000000 AS NUMERIC(6,0))); -- Edge: Min time
GO
SELECT dbo.TestTimeFunction(CAST(-1 AS NUMERIC(6,0))); -- Negative: Invalid time
GO

-- float
SELECT dbo.TestTimeFunction(CAST(143020 AS FLOAT)); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959.9999999 AS FLOAT)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-143020 AS FLOAT)); -- Negative: Invalid time
GO

-- real
SELECT dbo.TestTimeFunction(CAST(143020 AS REAL)); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959.99 AS REAL)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-143020 AS REAL)); -- Negative: Invalid time
GO

-- bigint
SELECT dbo.TestTimeFunction(CAST(143020 AS BIGINT)); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959 AS BIGINT)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-1 AS BIGINT)); -- Negative: Invalid time
GO

-- int
SELECT dbo.TestTimeFunction(143020); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(0); -- Edge: Min time
GO
SELECT dbo.TestTimeFunction(-1); -- Negative: Invalid time
GO

-- smallint
SELECT dbo.TestTimeFunction(CAST(1430 AS SMALLINT)); -- Positive (HHMM format)
GO
SELECT dbo.TestTimeFunction(CAST(2359 AS SMALLINT)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-1 AS SMALLINT)); -- Negative: Invalid time
GO

-- tinyint
SELECT dbo.TestTimeFunction(CAST(14 AS TINYINT)); -- Positive (HH format)
GO
SELECT dbo.TestTimeFunction(CAST(23 AS TINYINT)); -- Edge: Max hour
GO
SELECT dbo.TestTimeFunction(CAST(24 AS TINYINT)); -- Negative: Invalid hour
GO

-- money
SELECT dbo.TestTimeFunction(CAST(143020 AS MONEY)); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959.9999999 AS MONEY)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-1 AS MONEY)); -- Negative: Invalid time
GO

-- smallmoney
SELECT dbo.TestTimeFunction(CAST(143020 AS SMALLMONEY)); -- Positive (HHMMSS format)
GO
SELECT dbo.TestTimeFunction(CAST(235959.99 AS SMALLMONEY)); -- Edge: Max time
GO
SELECT dbo.TestTimeFunction(CAST(-1 AS SMALLMONEY)); -- Negative: Invalid time
GO

-- bit
SELECT dbo.TestTimeFunction(CAST(1 AS BIT)); -- Negative: Will raise an error
GO

-- uniqueidentifier
SELECT dbo.TestTimeFunction(CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER)); -- Negative
GO

-- text
SELECT dbo.TestTimeFunction(CAST('14:30:20' AS TEXT)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST('invalid' AS TEXT)); -- Negative: Invalid time
GO

-- ntext
SELECT dbo.TestTimeFunction(CAST(N'14:30:20' AS NTEXT)); -- Positive
GO
SELECT dbo.TestTimeFunction(CAST(N'invalid' AS NTEXT)); -- Negative: Invalid time
GO

-- xml
SELECT dbo.TestTimeFunction(CAST('<time>14:30:20</time>' AS XML)); -- Negative: Will raise an error
GO

-- sql_variant
SELECT dbo.TestTimeFunction(CAST(CAST('14:30:20' AS TIME) AS SQL_VARIANT)); -- Positive
GO

-- geometry
SELECT dbo.TestTimeFunction(geometry::STGeomFromText('POINT(1 1)', 0)); -- Negative: Will raise an error
GO

-- geography
SELECT dbo.TestTimeFunction(geography::STGeomFromText('POINT(47.65100 -122.34900)', 4326)); -- Negative
GO

-- Create a table to store test results for TIME
CREATE TABLE TimeImplicitConversionTest (
    ID INT IDENTITY PRIMARY KEY,
    TestType NVARCHAR(50),
    TestDescription NVARCHAR(255),
    InputValue NVARCHAR(MAX),
    OutputValue TIME NULL,
    IsSuccess BIT
);
GO

-- Helper procedure to insert test results
CREATE PROCEDURE InsertTimeTestResult
    @TestType NVARCHAR(50),
    @TestDescription NVARCHAR(255),
    @InputValue NVARCHAR(MAX),
    @OutputValue TIME = NULL,
    @IsSuccess BIT = 0
AS
BEGIN
    INSERT INTO TimeImplicitConversionTest (TestType, TestDescription, InputValue, OutputValue, IsSuccess)
    VALUES (@TestType, @TestDescription, @InputValue, @OutputValue, @IsSuccess);
END;
GO

-- Test cases
DECLARE @TimeValue TIME = '12:34:56.789';
DECLARE @StringTime NVARCHAR(20) = '14:30:00';
DECLARE @DateTimeValue DATETIME = '2023-06-20 15:45:30.123';
DECLARE @SmallDateTime SMALLDATETIME = '2023-06-20 16:30:00';

-- 1. UNION
BEGIN TRY
    DECLARE @Result TIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT @TimeValue AS Result
        UNION
        SELECT @StringTime
        UNION
        SELECT @DateTimeValue
        UNION
        SELECT @SmallDateTime
    ) AS UnionResult;
    EXEC InsertTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple time types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'UNION', 'Implicit conversion in UNION', 'Multiple time types', NULL, 0;
END CATCH;
GO

-- 2. UNION ALL
BEGIN TRY
    DECLARE @Result TIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('12:34:56.789' AS TIME) AS Result
        UNION ALL
        SELECT '14:30:00'
        UNION ALL
        SELECT CAST('2023-06-20 15:45:30.123' AS DATETIME)
        UNION ALL
        SELECT CAST('2023-06-20 16:30:00' AS SMALLDATETIME)
    ) AS UnionAllResult;
    EXEC InsertTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple time types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'UNION ALL', 'Implicit conversion in UNION ALL', 'Multiple time types', NULL, 0;
END CATCH;
GO

-- 3. CASE Expression
BEGIN TRY
    DECLARE @Result TIME = CASE 
        WHEN 1=0 THEN CAST('12:34:56.789' AS TIME)
        WHEN 1=0 THEN '14:30:00'
        ELSE CAST('2023-06-20 15:45:30.123' AS DATETIME)
    END;
    EXEC InsertTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple time types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'CASE', 'Implicit conversion in CASE', 'Multiple time types', NULL, 0;
END CATCH;
GO

-- 4. COALESCE
BEGIN TRY
    DECLARE @Result TIME = COALESCE(
        NULL, 
        CAST('12:34:56.789' AS TIME),
        '14:30:00',
        CAST('2023-06-20 15:45:30.123' AS DATETIME)
    );
    EXEC InsertTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple time types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'COALESCE', 'Implicit conversion in COALESCE', 'Multiple time types', NULL, 0;
END CATCH;
GO

-- 5. INTERSECT
BEGIN TRY
    DECLARE @Result TIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('12:34:56.789' AS TIME) AS Result
        INTERSECT
        SELECT '12:34:56.789'
    ) AS IntersectResult;
    EXEC InsertTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'TIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'INTERSECT', 'Implicit conversion in INTERSECT', 'TIME and String', NULL, 0;
END CATCH;
GO

-- 6. EXCEPT
BEGIN TRY
    DECLARE @Result TIME;
    SELECT TOP 1 @Result = Result
    FROM (
        SELECT CAST('12:34:56.789' AS TIME) AS Result
        EXCEPT
        SELECT '14:30:00'
    ) AS ExceptResult;
    EXEC InsertTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'TIME and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'EXCEPT', 'Implicit conversion in EXCEPT', 'TIME and String', NULL, 0;
END CATCH;
GO

-- 7. VALUES
BEGIN TRY
    DECLARE @Result TIME;
    SELECT TOP 1 @Result = Result
    FROM (VALUES 
        (CAST('12:34:56.789' AS TIME)),
        ('14:30:00'),
        (CAST('2023-06-20 15:45:30.123' AS DATETIME))
    ) AS ValuesResult(Result);
    EXEC InsertTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple time types', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'VALUES', 'Implicit conversion in VALUES', 'Multiple time types', NULL, 0;
END CATCH;
GO

-- 8. ISNULL
BEGIN TRY
    DECLARE @Result TIME = ISNULL(NULL, '14:30:00');
    EXEC InsertTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'ISNULL', 'Implicit conversion in ISNULL', 'NULL and String', NULL, 0;
END CATCH;
GO

-- Additional TIME-specific tests

-- 9. Different time formats
BEGIN TRY
    DECLARE @Result TIME = COALESCE(
        '12:34:56.7890123',  -- More precision than TIME
        '12:34:56 PM',       -- 12-hour format
        '12:34',             -- Hours and minutes only
        '12:34:56.789'       -- Exact TIME precision
    );
    EXEC InsertTimeTestResult 'TIME Formats', 'Different time format conversions', 'Various time formats', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'TIME Formats', 'Different time format conversions', 'Various time formats', NULL, 0;
END CATCH;
GO

-- 10. Edge cases
BEGIN TRY
    DECLARE @Result TIME = COALESCE(
        '00:00:00.0000000',  -- Midnight
        '23:59:59.9999999',  -- Just before midnight
        '12:00:00',          -- Noon
        '24:00:00'           -- Should fail
    );
    EXEC InsertTimeTestResult 'TIME Edge Cases', 'Edge case time values', 'Edge time values', @Result, 1;
END TRY
BEGIN CATCH
    EXEC InsertTimeTestResult 'TIME Edge Cases', 'Edge case time values', 'Edge time values', NULL, 0;
END CATCH;
GO

-- Display results
SELECT * FROM TimeImplicitConversionTest ORDER BY ID;
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
    SET @SQL = 'SELECT CONVERT(TIME, 0x07E3061014223B, ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''14:22:59'' AS VARBINARY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, ''14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, ''14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, N''14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, N''14:22:59'', ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''2023-06-16'' AS DATE), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''2023-06-16 14:22:59'' AS DATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''2023-06-16 14:22:00'' AS SMALLDATETIME), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''2023-06-16 14:22:59.1234567'' AS DATETIME2), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''2023-06-16 14:22:59.1234567 +01:00'' AS DATETIMEOFFSET), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS DECIMAL(6,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS NUMERIC(6,0)), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS FLOAT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS REAL), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS BIGINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259 AS INT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(1422 AS SMALLINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(14 AS TINYINT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(142259.0 AS MONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(1422.59 AS SMALLMONEY), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(''14:22:59'' AS TEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(N''14:22:59'' AS NTEXT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
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
    SET @SQL = 'SELECT CONVERT(TIME, CAST(CAST(''14:22:59'' AS TIME) AS SQL_VARIANT), ' + CAST(@Style AS NVARCHAR(3)) + ') AS Result';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM style_cursor INTO @Style;
END
CLOSE style_cursor;
DEALLOCATE style_cursor;
GO

-- 3. Operators:
-- Equal to (=) with TIME on left side
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(0x0C22380000000000 AS binary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS char(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS varchar(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS nchar(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS nvarchar(8)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('2023-06-16' AS date) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('2023-06-16 12:34:56' AS datetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS time) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS decimal(6,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS numeric(6,0)) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS float) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS real) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS bigint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS int) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(1234 AS smallint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(12 AS tinyint) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(123456 AS money) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(1234 AS smallmoney) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(1 AS bit) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(0x0C22380000000000 AS image) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS text) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('12:34:56' AS ntext) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56.1234567' AS TIME) = CAST('<time>12:34:56</time>' AS xml) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Equal to (=) with TIME on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS float) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS real) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS int) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS money) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) = CAST('12:34:56.1234567' AS TIME) THEN 'Equal' ELSE 'Not Equal' END;
GO

-- Not equal to (<>) with TIME on left side
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(0x0000000000000000 AS binary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(0x0000000000000000 AS varbinary(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS char(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS varchar(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS nchar(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS nvarchar(8)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('2023-06-16' AS date) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('2023-06-16 12:34:56' AS datetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS time) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS decimal(6,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS numeric(6,0)) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS float) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS real) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS bigint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS int) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(1234 AS smallint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(12 AS tinyint) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(123456 AS money) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(1234 AS smallmoney) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(1 AS bit) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(0x0000000000000000 AS image) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS text) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('12:34:56' AS ntext) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <> CAST('<time>12:34:56</time>' AS xml) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Not equal to (<>) with TIME on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS float) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS real) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS int) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(123456 AS money) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS image) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) <> CAST('12:34:56' AS TIME) THEN 'Not Equal' ELSE 'Equal' END;
GO

-- Less than (<) with TIME on left side
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(0x0000000000000000 AS binary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(0x0000000000000000 AS varbinary(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS char(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS varchar(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS nchar(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS nvarchar(8)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('2023-06-16' AS date) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS time) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS decimal(6,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS numeric(6,0)) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS float) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS real) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS bigint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS int) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(1234 AS smallint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(12 AS tinyint) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(123456 AS money) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(1234 AS smallmoney) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(1 AS bit) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(0x0000000000000000 AS image) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS text) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('12:34:56' AS ntext) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) < CAST('<time>12:34:56</time>' AS xml) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than (<) with TIME on right side
SELECT CASE WHEN CAST(0x0000000000000000 AS binary(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS varbinary(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS float) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS real) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS int) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS money) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(0x0000000000000000 AS image) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) < CAST('12:34:56' AS TIME) THEN 'Less Than' ELSE 'Not Less Than' END;
GO

-- Less than or equal to (<=) with TIME on left side
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(0x0C22380000000000 AS binary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS char(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS varchar(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS nchar(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS nvarchar(8)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('2023-06-16' AS date) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS time) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS decimal(6,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS numeric(6,0)) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS float) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS real) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS bigint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS int) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(1234 AS smallint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(12 AS tinyint) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(123456 AS money) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(1234 AS smallmoney) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(1 AS bit) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(0x0C22380000000000 AS image) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS text) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('12:34:56' AS ntext) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) <= CAST('<time>12:34:56</time>' AS xml) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Less than or equal to (<=) with TIME on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS float) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS real) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS int) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS money) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) <= CAST('12:34:56' AS TIME) THEN 'Less Than or Equal' ELSE 'Greater Than' END;
GO

-- Greater than (>) with TIME on left side
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS char(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS varchar(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS nchar(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS nvarchar(8)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('2023-06-16' AS date) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS time) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS decimal(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS numeric(6,0)) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS float) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS real) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS bigint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS int) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(1234 AS smallint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(12 AS tinyint) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(123456 AS money) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(1234 AS smallmoney) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(1 AS bit) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(0x0C22380000000000 AS image) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS text) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('12:34:56' AS ntext) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) > CAST('<time>12:34:56</time>' AS xml) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than (>) with TIME on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS float) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS real) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS int) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(12 AS tinyint) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(123456 AS money) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) > CAST('12:34:56' AS TIME) THEN 'Greater Than' ELSE 'Not Greater Than' END;
GO

-- Greater than or equal to (>=) with TIME on left side
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(0x0C22380000000000 AS binary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(0x0C22380000000000 AS varbinary(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS char(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS varchar(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS nchar(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS nvarchar(8)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('2023-06-16' AS date) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('2023-06-16 12:34:56' AS datetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('2023-06-16 12:34:00' AS smalldatetime) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('2023-06-16 12:34:56.1234567' AS datetime2) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS time) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS decimal(6,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS numeric(6,0)) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS float) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS real) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS bigint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS int) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(1234 AS smallint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(56 AS tinyint) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(123456 AS money) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(1234 AS smallmoney) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(1 AS bit) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(0x0C22380000000000 AS image) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS text) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('12:34:56' AS ntext) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST(CAST('12:34:56' AS time) AS sql_variant) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS TIME) >= CAST('<time>12:34:56</time>' AS xml) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- Greater than or equal to (>=) with TIME on right side
SELECT CASE WHEN CAST(0x0C22380000000000 AS binary(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS varbinary(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS char(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS varchar(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nchar(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS nvarchar(8)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16' AS date) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56' AS datetime) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:00' AS smalldatetime) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567' AS datetime2) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS time) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('2023-06-16 12:34:56.1234567 +01:00' AS datetimeoffset) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS decimal(6,0)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS numeric(6,0)) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS float) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS real) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS bigint) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS int) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallint) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(56 AS tinyint) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(123456 AS money) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1234 AS smallmoney) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(1 AS bit) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS uniqueidentifier) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(0x0C22380000000000 AS image) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS text) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('12:34:56' AS ntext) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST(CAST('12:34:56' AS time) AS sql_variant) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO
SELECT CASE WHEN CAST('<time>12:34:56</time>' AS xml) >= CAST('12:34:56' AS TIME) THEN 'Greater Than or Equal' ELSE 'Less Than' END;
GO

-- BETWEEN operator with TIME
SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) BETWEEN CAST('14:29:00' AS TIME) AND CAST('14:31:00' AS TIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) BETWEEN CAST('14:29:00.123' AS TIME) AND CAST('14:31:00.123' AS TIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) BETWEEN CAST('14:29:00.1234567' AS TIME(7)) AND CAST('14:31:00.1234567' AS TIME(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Different precision tests for BETWEEN
SELECT CASE 
    WHEN CAST('14:30:00.1234567' AS TIME(7)) BETWEEN CAST('14:30:00' AS TIME) AND CAST('14:31:00' AS TIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) BETWEEN CAST('14:30:00.0000000' AS TIME(7)) AND CAST('14:31:00.0000000' AS TIME(7)) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Edge cases for BETWEEN
SELECT CASE 
    WHEN CAST('00:00:00' AS TIME) BETWEEN CAST('23:59:59' AS TIME) AND CAST('00:00:01' AS TIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

SELECT CASE 
    WHEN CAST('23:59:59.9999999' AS TIME(7)) BETWEEN CAST('23:59:59' AS TIME) AND CAST('00:00:00' AS TIME) 
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- IN operator with TIME
SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) IN (CAST('14:29:00' AS TIME), CAST('14:30:00' AS TIME), CAST('14:31:00' AS TIME)) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00.123' AS TIME(3)) IN (
        CAST('14:29:00.123' AS TIME(3)), 
        CAST('14:30:00.123' AS TIME(3)), 
        CAST('14:31:00.123' AS TIME(3))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00.1234567' AS TIME(7)) IN (
        CAST('14:29:00.1234567' AS TIME(7)), 
        CAST('14:30:00.1234567' AS TIME(7)), 
        CAST('14:31:00.1234567' AS TIME(7))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- Different precision tests for IN
SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) IN (
        CAST('14:30:00.0000000' AS TIME(7)), 
        CAST('14:30:00.1234567' AS TIME(7)), 
        CAST('14:30:00.9999999' AS TIME(7))
    ) 
    THEN 'In Set' 
    ELSE 'Not In Set' 
END;
GO

-- IS NULL and IS NOT NULL with TIME
DECLARE @NullTime TIME;
SELECT CASE 
    WHEN @NullTime IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

DECLARE @NullTime TIME;
SELECT CASE 
    WHEN @NullTime IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) IS NULL 
    THEN 'Is Null' 
    ELSE 'Is Not Null' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) IS NOT NULL 
    THEN 'Is Not Null' 
    ELSE 'Is Null' 
END;
GO

-- Additional precision tests
SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) = CAST('14:30:00.0000000' AS TIME(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00.1234567' AS TIME(7)) = CAST('14:30:00.1234567' AS TIME(7))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Boundary tests
SELECT CASE 
    WHEN CAST('00:00:00.0000000' AS TIME(7)) BETWEEN 
        CAST('00:00:00' AS TIME) AND 
        CAST('23:59:59.9999999' AS TIME(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Fractional seconds tests
SELECT CASE 
    WHEN CAST('14:30:00.1234567' AS TIME(7)) BETWEEN 
        CAST('14:30:00.1234566' AS TIME(7)) AND 
        CAST('14:30:00.1234568' AS TIME(7))
    THEN 'Within Range' 
    ELSE 'Outside Range' 
END;
GO

-- Mixed precision comparisons
SELECT CASE 
    WHEN CAST('14:30:00' AS TIME) = CAST('14:30:00.000' AS TIME(3))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

SELECT CASE 
    WHEN CAST('14:30:00.123' AS TIME(3)) = CAST('14:30:00.123000' AS TIME(6))
    THEN 'Equal' 
    ELSE 'Not Equal' 
END;
GO

-- Arithmetic operators
-- Addition with TIME on left side
SELECT CAST('12:34:56' AS TIME) + CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('12:34:56' AS TIME) + CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS CHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS VARCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS NCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16' AS DATE);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16 12:34:56' AS DATETIME);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16 12:34:00' AS SMALLDATETIME);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16 12:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('13:34:56' AS TIME);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS FLOAT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS REAL);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS BIGINT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS INT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS SMALLINT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS TINYINT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS MONEY);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS SMALLMONEY);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(1 AS BIT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS TEXT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('1' AS NTEXT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('12:34:56' AS TIME) + CAST('<number>1</number>' AS XML);
GO

-- Addition with TIME on right side
SELECT CAST(0x07E30610 AS BINARY(8)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS CHAR(10)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS VARCHAR(10)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NCHAR(10)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16' AS DATE) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56' AS DATETIME) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:00' AS SMALLDATETIME) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567' AS DATETIME2) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('13:34:56' AS TIME) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 12:34:56.1234567 +01:00' AS DATETIMEOFFSET) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS FLOAT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS REAL) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS BIGINT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS INT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS SMALLINT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS TINYINT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS MONEY) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS SMALLMONEY) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS BIT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(0x07E30610 AS IMAGE) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS TEXT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NTEXT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) + CAST('12:34:56' AS TIME);
GO
SELECT CAST('<number>1</number>' AS XML) + CAST('12:34:56' AS TIME);
GO

-- Subtraction with TIME on left side
SELECT CAST('12:34:56' AS TIME) - CAST(0x07E30610 AS BINARY(8));
GO
SELECT CAST('12:34:56' AS TIME) - CAST(0x07E30610 AS VARBINARY(8));
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS CHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS VARCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS NCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS NVARCHAR(10));
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16' AS DATE);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16 11:34:56' AS DATETIME);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16 11:34:00' AS SMALLDATETIME);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16 11:34:56.1234567' AS DATETIME2);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('11:34:56' AS TIME);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('2023-06-16 11:34:56.1234567 +01:00' AS DATETIMEOFFSET);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS DECIMAL(8,0));
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS NUMERIC(8,0));
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS FLOAT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS REAL);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS BIGINT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS INT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS SMALLINT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS TINYINT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS MONEY);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS SMALLMONEY);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(1 AS BIT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(0x07E30610 AS IMAGE);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS TEXT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('1' AS NTEXT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST(CAST(1 AS INT) AS SQL_VARIANT);
GO
SELECT CAST('12:34:56' AS TIME) - CAST('<number>1</number>' AS XML);
GO

-- Subtraction with TIME on right side
SELECT CAST(0x07E30610 AS BINARY(8)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(0x07E30610 AS VARBINARY(8)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS CHAR(10)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS VARCHAR(10)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NCHAR(10)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NVARCHAR(10)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16' AS DATE) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 13:34:56' AS DATETIME) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 13:34:00' AS SMALLDATETIME) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 13:34:56.1234567' AS DATETIME2) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('13:34:56' AS TIME) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('2023-06-16 13:34:56.1234567 +01:00' AS DATETIMEOFFSET) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS DECIMAL(8,0)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS NUMERIC(8,0)) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS FLOAT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS REAL) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS BIGINT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS INT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS SMALLINT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS TINYINT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS MONEY) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS SMALLMONEY) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(1 AS BIT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('F129AB9C-F2A0-4A9D-8B7F-C52746C9A280' AS UNIQUEIDENTIFIER) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(0x07E30610 AS IMAGE) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS TEXT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('1' AS NTEXT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST(CAST(1 AS INT) AS SQL_VARIANT) - CAST('12:34:56' AS TIME);
GO
SELECT CAST('<number>1</number>' AS XML) - CAST('12:34:56' AS TIME);
GO

-- 4. DDL testing:

-- 1. Table column with TIME
CREATE TABLE TimeTest1 (
    ID INT PRIMARY KEY,
    TimeColumn TIME(7),  -- Maximum precision
    DefaultTimeColumn TIME DEFAULT GETDATE(),
    ComputedTimeColumn AS DATEADD(hour, 1, TimeColumn),
    CHECK (TimeColumn > '12:00:00')
);
GO

-- Verify column properties
SELECT 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    DATETIME_PRECISION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TimeTest1' ORDER BY COLUMN_NAME;
GO

-- 2. Partitioned table for TIME
CREATE PARTITION FUNCTION TIME_partition_func (TIME) 
    AS RANGE RIGHT FOR VALUES(
        '06:00:00', 
        '12:00:00', 
        '18:00:00'
    );
GO

CREATE PARTITION SCHEME TIME_partition_scheme
    AS PARTITION TIME_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE TIME_partition(
    a TIME(7),
    type VARCHAR(10))
ON TIME_partition_scheme(a);
GO

-- Insert test data for different time periods
INSERT INTO TIME_partition (a, type) VALUES ('03:30:00', 'Early');
GO
INSERT INTO TIME_partition (a, type) VALUES ('09:30:00', 'Morning');
GO
INSERT INTO TIME_partition (a, type) VALUES ('15:30:00', 'Afternoon');
GO
INSERT INTO TIME_partition (a, type) VALUES ('21:30:00', 'Night');
GO

-- Query to show times in each partition
SELECT a, type, $PARTITION.TIME_partition_func(a) AS PartitionNumber
    FROM TIME_partition ORDER BY PartitionNumber;
GO

-- Query to show count of entries by partition
SELECT $PARTITION.TIME_partition_func(a) AS PartitionNumber, type, COUNT(*) AS TimeCount
    FROM TIME_partition
    GROUP BY $PARTITION.TIME_partition_func(a), type
    ORDER BY PartitionNumber;
GO

-- 3. Function returning Time types
CREATE FUNCTION dbo.GetCurrentTime()
RETURNS TIME
AS
BEGIN
    RETURN CAST('14:30:00' AS TIME);
END;
GO

-- Verify function return type
SELECT 
    SPECIFIC_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_NAME = 'GetCurrentTime' AND ROUTINE_TYPE = 'FUNCTION';
GO

-- 4. Function takes Time types input
CREATE FUNCTION dbo.AddHoursToTime(
    @InputTime TIME,
    @HoursToAdd INT
)
RETURNS TIME
AS
BEGIN
    RETURN DATEADD(HOUR, @HoursToAdd, @InputTime);
END;
GO

-- Test the function
SELECT dbo.AddHoursToTime('14:30:00', 2) AS Result;  -- Should return 16:30:00
GO
SELECT dbo.AddHoursToTime('14:30:00', -2) AS Result; -- Should return 12:30:00
GO
SELECT dbo.AddHoursToTime('14:30:00', 0) AS Result;  -- Should return 14:30:00
GO

-- 5. Procedure takes Time types input
CREATE PROCEDURE dbo.ProcessTime
    @InputTime TIME
AS
BEGIN
    SELECT DATEADD(HOUR, 1, @InputTime) AS NextHour;
END;
GO

-- 6. Constraints
ALTER TABLE TimeTest1
ADD CONSTRAINT DF_TimeTest_DefaultTimeColumn DEFAULT '00:00:00' FOR DefaultTimeColumn;

ALTER TABLE TimeTest1
ADD CONSTRAINT CK_TimeTest_TimeColumn CHECK (TimeColumn > '00:00:00');

-- Verify constraints
SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'TimeTest1'
ORDER BY CONSTRAINT_NAME;
GO

-- 7. Primary Key columns
SELECT 
    CONSTRAINT_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'TimeTest1' AND CONSTRAINT_NAME LIKE 'PK_%';
GO

-- 8. Views
CREATE VIEW dbo.TimeView
AS
SELECT
    ID,
    TimeColumn,
    DefaultTimeColumn,
    ComputedTimeColumn
FROM TimeTest1;
GO

-- Verify view
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TimeView' ORDER BY COLUMN_NAME;
GO

-- Insert some test data with different precisions
INSERT INTO TimeTest1 (ID, TimeColumn) VALUES 
(1, '14:30:00'),
(2, '14:30:00.1'),
(3, '14:30:00.12'),
(4, '14:30:00.123'),
(5, '14:30:00.1234'),
(6, '14:30:00.12345'),
(7, '14:30:00.123456'),
(8, '14:30:00.1234567');
GO

-- Test all the objects we created
-- Basic table operations
SELECT * FROM TimeTest1 ORDER BY ID;
GO

-- Partitioned table
SELECT * FROM TIME_partition Order BY type;
GO

-- Functions
SELECT dbo.GetCurrentTime() AS CurrentTime;
GO
SELECT dbo.AddHoursToTime('14:30:00', 2) AS TimeAfter2Hours;
GO

-- Procedure
EXEC dbo.ProcessTime @InputTime = '14:30:00';
GO

-- View
SELECT * FROM dbo.TimeView ORDER BY ID;
GO

-- Additional time-specific tests
-- Test different time formats
INSERT INTO TimeTest1 (ID, TimeColumn) VALUES 
(9, '2:30 PM'),
(10, '14:30'),
(11, '14:30:00.0000000');
GO

-- Test boundary conditions
INSERT INTO TimeTest1 (ID, TimeColumn) VALUES 
(12, '00:00:00'),
(13, '23:59:59.9999999');
GO

-- Test invalid times (these should fail)
INSERT INTO TimeTest1 (ID, TimeColumn) VALUES 
(14, '24:00:00'),
(15, '23:60:00'),
(16, '23:59:60');
GO

-- Test time arithmetic
SELECT 
    TimeColumn,
    DATEADD(HOUR, 1, TimeColumn) AS Plus1Hour,
    DATEADD(MINUTE, 30, TimeColumn) AS Plus30Minutes,
    DATEADD(SECOND, 15, TimeColumn) AS Plus15Seconds,
    DATEADD(MILLISECOND, 500, TimeColumn) AS Plus500Milliseconds
FROM TimeTest1 ORDER BY TimeColumn;
GO

-- Test time comparisons
SELECT TimeColumn
FROM TimeTest1
WHERE TimeColumn BETWEEN '12:00:00' AND '16:00:00'
ORDER BY TimeColumn;
GO

-- 5. DML testing:
-- Create test tables for TIME
CREATE TABLE TimeDMLTest (
    ID INT IDENTITY PRIMARY KEY,
    SimpleTime TIME,
    DefaultTime TIME DEFAULT NULL,
    ComputedTime AS DATEADD(minute, 30, SimpleTime),
    Description NVARCHAR(100)
);
GO

CREATE TABLE TimeDMLTestChild (
    ID INT IDENTITY PRIMARY KEY,
    ParentID INT,
    ChildTime TIME,
    FOREIGN KEY (ParentID) REFERENCES TimeDMLTest(ID) ON DELETE CASCADE
);
GO

-- 1. INSERT operations

-- Single row insertion
INSERT INTO TimeDMLTest (SimpleTime, Description) 
VALUES ('14:30:20.1234567', 'Single row insertion');
GO

-- Bulk insertion
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES 
('09:15:00', 'Bulk insertion 1'),
('12:30:45.123', 'Bulk insertion 2'),
('17:45:30.5567', 'Bulk insertion 3');
GO

-- Insert with type casting
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES (CAST('143020' AS TIME), 'Insert with type casting');
GO

-- Insert with expressions
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES (DATEADD(minute, 30, CAST('14:30:20' AS TIME)), 'Insert with expression');
GO

-- Insert with DEFAULT values
INSERT INTO TimeDMLTest (SimpleTime, DefaultTime, Description)
VALUES ('15:45:00', DEFAULT, 'Insert with DEFAULT');
GO

-- Verify insertions
SELECT * FROM TimeDMLTest ORDER BY ID;
GO

-- 2. UPDATE operations

-- Single column update
UPDATE TimeDMLTest
SET SimpleTime = '16:00:00'
WHERE ID = 1;
GO

-- Multiple column update
UPDATE TimeDMLTest
SET SimpleTime = '16:30:00',
    Description = 'Updated multiple columns'
WHERE ID = 2;
GO

-- Update with calculations
UPDATE TimeDMLTest
SET SimpleTime = DATEADD(hour, 1, SimpleTime)
WHERE ID = 3;
GO

-- Mass update
UPDATE TimeDMLTest
SET Description = 'Mass updated';
GO

-- Conditional update
UPDATE TimeDMLTest
SET SimpleTime = '09:00:00'
WHERE SimpleTime < '12:00:00';
GO

-- Verify updates
SELECT * FROM TimeDMLTest ORDER BY ID;
GO

-- 3. DELETE operations

-- Insert some data into child table for delete testing
INSERT INTO TimeDMLTestChild (ParentID, ChildTime)
VALUES 
(1, '09:00:00'),
(2, '10:15:30'),
(3, '11:45:00'),
(4, '13:20:15'),
(5, '15:00:00');
GO

-- Single row deletion
DELETE FROM TimeDMLTest WHERE ID = 1;
GO

-- Bulk deletion
DELETE TOP (2) FROM TimeDMLTest;
GO

-- Conditional deletion
DELETE FROM TimeDMLTest WHERE SimpleTime < '12:00:00';
GO

-- Cascade deletion (will delete from child table as well)
DELETE FROM TimeDMLTest WHERE ID = 4;
GO

-- Verify deletions
SELECT * FROM TimeDMLTest ORDER BY ID;
SELECT * FROM TimeDMLTestChild ORDER BY ID;
GO

-- 4. COMPUTED columns

-- Insert data to test computed column
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES ('14:00:00', 'Testing computed column');
GO

-- Verify computed column
SELECT ID, SimpleTime, ComputedTime, Description
FROM TimeDMLTest
WHERE SimpleTime = '14:00:00';
GO

-- Try to update computed column (this will fail)
BEGIN TRY
    UPDATE TimeDMLTest
    SET ComputedTime = '15:00:00'
    WHERE SimpleTime = '14:00:00';
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH
GO

-- Update base column and check computed column
UPDATE TimeDMLTest
SET SimpleTime = '15:00:00'
WHERE SimpleTime = '14:00:00';
GO

SELECT ID, SimpleTime, ComputedTime, Description
FROM TimeDMLTest
WHERE SimpleTime = '15:00:00';
GO

-- 5. Additional DML scenarios

-- Insert with subquery
INSERT INTO TimeDMLTest (SimpleTime, Description)
SELECT DATEADD(hour, 1, MAX(SimpleTime)), 'Inserted from subquery'
FROM TimeDMLTest;
GO

-- Update with JOIN
UPDATE t
SET t.SimpleTime = DATEADD(minute, 30, c.ChildTime)
FROM TimeDMLTest t
JOIN TimeDMLTestChild c ON t.ID = c.ParentID;
GO

-- Delete with subquery
DELETE FROM TimeDMLTest
WHERE SimpleTime IN (
    SELECT ChildTime
    FROM TimeDMLTestChild
);
GO

-- Insert various time formats
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES 
('13:30', 'Hours and minutes only'),
('13:30:45', 'Hours, minutes, and seconds'),
('13:30:45.1234567', 'Full precision'),
('1:30PM', 'AM/PM format'),
('13:30:45.1234567', 'Maximum precision');
GO

-- Test boundary values
INSERT INTO TimeDMLTest (SimpleTime, Description)
VALUES 
('00:00:00.0000000', 'Minimum time'),
('23:59:59.999999', 'Maximum time'),
('12:00:00', 'Noon'),
('25:00:00', 'Midnight next day');
GO

-- Test time arithmetic
UPDATE TimeDMLTest
SET SimpleTime = DATEADD(millisecond, 500, SimpleTime)
WHERE ID IN (SELECT TOP 1 ID FROM TimeDMLTest ORDER BY ID);
GO

-- Test time comparisons
DELETE FROM TimeDMLTest
WHERE SimpleTime BETWEEN '12:00:00' AND '13:00:00';
GO

-- Final verification
SELECT * FROM TimeDMLTest ORDER BY ID;
SELECT * FROM TimeDMLTestChild ORDER BY ID;
GO

-- 6. Index testing:
-- Create test table for TIME
CREATE TABLE TimeIndexTest (
    ID INT IDENTITY PRIMARY KEY,
    TimeColumn TIME(7),
    TimeColumn2 TIME(7),
    Description NVARCHAR(100),
    NumericColumn INT
);
GO

-- Insert test data
INSERT INTO TimeIndexTest (TimeColumn, TimeColumn2, Description, NumericColumn)
VALUES 
('00:00:00', '12:00:00', 'Midnight to Noon', 1),
('06:15:30.1234567', '18:15:30.1234567', 'Morning to Evening', 2),
('09:30:45.5555555', '21:30:45.5555555', 'Work hours', 3),
('12:45:15.7777777', '23:45:15.7777777', 'Lunch time', 4),
('15:20:10.9999999', '03:20:10.9999999', 'Afternoon', 5);
GO

-- 1. Index on single column
CREATE INDEX IX_TimeIndexTest_TimeColumn ON TimeIndexTest(TimeColumn);
GO

-- Test single column index
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = '00:00:00';
SET STATISTICS IO OFF;
GO

-- 2. Index involving multiple columns
CREATE INDEX IX_TimeIndexTest_TimeColumn_TimeColumn2 ON TimeIndexTest(TimeColumn, TimeColumn2);
GO

-- Test multi-column index
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = '00:00:00' AND TimeColumn2 = '12:00:00';
SET STATISTICS IO OFF;
GO

-- 3. Usability of index with different operators in predicate

-- Equality
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = '00:00:00';
SET STATISTICS IO OFF;
GO

-- Range
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn BETWEEN '09:00:00' AND '17:00:00' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- LIKE (converted to string)
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE CAST(TimeColumn AS VARCHAR(20)) LIKE '09:%';
SET STATISTICS IO OFF;
GO

-- IN
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn IN ('00:00:00', '06:15:30.1234567', '12:00:00') ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- 4. Comparing different data types with implicit conversions

-- TIME to VARCHAR
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = '000000';
SET STATISTICS IO OFF;
GO

-- TIME to DATETIME
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = CAST('1900-01-01 00:00:00' AS TIME);
SET STATISTICS IO OFF;
GO

-- TIME arithmetic (adding minutes)
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = DATEADD(MINUTE, 360, '00:00:00');
SET STATISTICS IO OFF;
GO

-- 5. DML operations with indexes

-- INSERT
SET STATISTICS IO ON;
INSERT INTO TimeIndexTest (TimeColumn, TimeColumn2, Description, NumericColumn)
VALUES ('18:30:00', '06:30:00', 'Evening', 6);
SET STATISTICS IO OFF;
GO

-- UPDATE
SET STATISTICS IO ON;
UPDATE TimeIndexTest SET TimeColumn = '19:00:00' WHERE TimeColumn = '18:30:00';
SET STATISTICS IO OFF;
GO

-- DELETE
SET STATISTICS IO ON;
DELETE FROM TimeIndexTest WHERE TimeColumn = '19:00:00';
SET STATISTICS IO OFF;
GO

-- 6. Additional index scenarios

-- Create a filtered index for business hours
CREATE INDEX IX_TimeIndexTest_Filtered ON TimeIndexTest(TimeColumn)
WHERE TimeColumn >= '09:00:00' AND TimeColumn <= '17:00:00';
GO

-- Test filtered index
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = '12:00:00';
SET STATISTICS IO OFF;
GO

-- Create an index with included columns
CREATE INDEX IX_TimeIndexTest_TimeColumn_Include ON TimeIndexTest(TimeColumn)
INCLUDE (Description, NumericColumn);
GO

-- Test index with included columns
SET STATISTICS IO ON;
SELECT TimeColumn, Description, NumericColumn 
FROM TimeIndexTest 
WHERE TimeColumn = '09:30:45.5555555';
SET STATISTICS IO OFF;
GO

-- 7. Index usage for time functions

-- DATEPART function
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE DATEPART(HOUR, TimeColumn) = 12;
SET STATISTICS IO OFF;
GO

-- DATEADD function
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WHERE TimeColumn = DATEADD(MINUTE, 30, '12:00:00');
SET STATISTICS IO OFF;
GO

-- 8. Index hints

-- Force index usage
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WITH (INDEX(IX_TimeIndexTest_TimeColumn))
WHERE TimeColumn = '00:00:00';
SET STATISTICS IO OFF;
GO

-- Ignore index
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest WITH (INDEX(0))
WHERE TimeColumn = '00:00:00';
SET STATISTICS IO OFF;
GO

-- 9. Time-specific scenarios

-- Range queries within a day
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest 
WHERE TimeColumn >= '09:00:00' 
AND TimeColumn <= '17:00:00' ORDER BY ID;
SET STATISTICS IO OFF;
GO

-- Precision comparisons
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest 
WHERE TimeColumn = '06:15:30.1234567';
SET STATISTICS IO OFF;
GO

-- Cross-midnight ranges
SET STATISTICS IO ON;
SELECT * FROM TimeIndexTest 
WHERE TimeColumn >= '22:00:00' 
OR TimeColumn <= '02:00:00';
SET STATISTICS IO OFF;
GO

-- Time arithmetic
SET STATISTICS IO ON;
SELECT *, 
    DATEADD(HOUR, 1, TimeColumn) AS HourLater,
    DATEADD(MINUTE, -30, TimeColumn) AS HalfHourEarlier
FROM TimeIndexTest 
WHERE TimeColumn = '12:00:00';
SET STATISTICS IO OFF;
GO

-- 7. Expression Testing:
-- Create test table for TIME
CREATE TABLE TimeExpressionTest (
    ID INT IDENTITY PRIMARY KEY,
    TimeColumn TIME(7),
    NullableTimeColumn TIME(7) NULL,
    Description NVARCHAR(100)
);
GO

-- Insert test data
INSERT INTO TimeExpressionTest (TimeColumn, NullableTimeColumn, Description)
VALUES 
('00:00:00', '00:00:00', 'Midnight'),
('06:00:00', '06:00:00', 'Morning'),
('09:30:00', NULL, 'Morning Break'),
('12:00:00', '12:00:00', 'Noon'),
('13:30:00', NULL, 'Afternoon Break'),
('15:45:30.1234567', '15:45:30.1234567', 'Late Afternoon'),
('17:30:00', '17:30:00', 'End of Day'),
('18:15:00', NULL, 'Evening'),
('20:00:00', '20:00:00', 'Night'),
('21:30:45.9876543', '21:30:45.9876543', 'Late Night'),
('22:45:00', NULL, 'Late Night');
GO

-- 1. Conditional Expressions

-- CASE statements
SELECT 
    TimeColumn,
    CASE 
        WHEN TimeColumn BETWEEN '06:00' AND '11:59' THEN 'Morning'
        WHEN TimeColumn BETWEEN '12:00' AND '16:59' THEN 'Afternoon'
        WHEN TimeColumn BETWEEN '17:00' AND '20:59' THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    Description
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- COALESCE
SELECT 
    ID,
    COALESCE(NullableTimeColumn, TimeColumn, CAST('00:00' AS TIME)) AS CoalescedTime,
    Description
FROM TimeExpressionTest ORDER BY ID;
GO

-- NULLIF operations
SELECT 
    ID,
    NULLIF(TimeColumn, '00:00') AS NullIfMidnight,
    Description
FROM TimeExpressionTest ORDER BY ID;
GO

-- IIF statements
SELECT 
    TimeColumn,
    IIF(TimeColumn < '12:00', 'AM', 'PM') AS AMPM,
    Description
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- 2. Aggregate Expressions

-- MAX
SELECT MAX(TimeColumn) AS LatestTime FROM TimeExpressionTest;
GO

-- MIN
SELECT MIN(TimeColumn) AS EarliestTime FROM TimeExpressionTest;
GO

-- UNIONS
SELECT TimeColumn FROM TimeExpressionTest WHERE TimeColumn < '12:00'
UNION
SELECT TimeColumn FROM TimeExpressionTest WHERE TimeColumn > '20:00'
ORDER BY TimeColumn;
GO

-- COUNT
SELECT COUNT(TimeColumn) AS TotalTimes, COUNT(DISTINCT TimeColumn) AS UniqueTimes FROM TimeExpressionTest;
GO

-- 3. Additional Expression Tests

-- Time arithmetic
SELECT 
    TimeColumn,
    DATEADD(HOUR, 1, CAST(TimeColumn AS DATETIME)) AS OneHourLater,
    DATEADD(MINUTE, 30, CAST(TimeColumn AS DATETIME)) AS ThirtyMinutesLater,
    DATEADD(SECOND, 15, CAST(TimeColumn AS DATETIME)) AS FifteenSecondsLater
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Time parts
SELECT 
    TimeColumn,
    DATEPART(HOUR, TimeColumn) AS Hour,
    DATEPART(MINUTE, TimeColumn) AS Minute,
    DATEPART(SECOND, TimeColumn) AS Second,
    DATEPART(MILLISECOND, TimeColumn) AS Millisecond,
    DATEPART(MICROSECOND, TimeColumn) AS Microsecond,
    DATEPART(NANOSECOND, TimeColumn) AS Nanosecond
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Time differences
SELECT 
    t1.TimeColumn AS Time1,
    t2.TimeColumn AS Time2,
    DATEDIFF(HOUR, t1.TimeColumn, t2.TimeColumn) AS HoursDiff,
    DATEDIFF(MINUTE, t1.TimeColumn, t2.TimeColumn) AS MinutesDiff,
    DATEDIFF(SECOND, t1.TimeColumn, t2.TimeColumn) AS SecondsDiff
FROM TimeExpressionTest t1
CROSS JOIN TimeExpressionTest t2
WHERE t1.ID < t2.ID ORDER BY t2.TimeColumn;
GO

-- Complex conditional expressions
SELECT 
    TimeColumn,
    CASE 
        WHEN DATEPART(HOUR, TimeColumn) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, TimeColumn) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, TimeColumn) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS TimeOfDay,
    CASE 
        WHEN DATEPART(HOUR, TimeColumn) < 12 THEN 'AM'
        ELSE 'PM'
    END AS AMPM,
    IIF(TimeColumn BETWEEN '09:00' AND '17:00', 'Business Hours', 'Off Hours') AS BusinessHours
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Window functions with times
SELECT 
    TimeColumn,
    Description,
    LAG(TimeColumn) OVER (ORDER BY TimeColumn) AS PreviousTime,
    LEAD(TimeColumn) OVER (ORDER BY TimeColumn) AS NextTime,
    DATEDIFF(MINUTE, 
        LAG(TimeColumn) OVER (ORDER BY TimeColumn), 
        TimeColumn) AS MinutesSincePreviousTime
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Time grouping and aggregation
SELECT 
    DATEPART(HOUR, TimeColumn) AS Hour,
    COUNT(*) AS TimeCount,
    MIN(TimeColumn) AS EarliestTime,
    MAX(TimeColumn) AS LatestTime
FROM TimeExpressionTest
GROUP BY DATEPART(HOUR, TimeColumn)
ORDER BY Hour;
GO

-- Precision tests
SELECT 
    TimeColumn,
    CAST(TimeColumn AS TIME(0)) AS Precision0,
    CAST(TimeColumn AS TIME(1)) AS Precision1,
    CAST(TimeColumn AS TIME(2)) AS Precision2,
    CAST(TimeColumn AS TIME(3)) AS Precision3,
    CAST(TimeColumn AS TIME(4)) AS Precision4,
    CAST(TimeColumn AS TIME(5)) AS Precision5,
    CAST(TimeColumn AS TIME(6)) AS Precision6,
    CAST(TimeColumn AS TIME(7)) AS Precision7
FROM TimeExpressionTest
WHERE TimeColumn > '21:00' ORDER BY TimeColumn;
GO

-- Time conversion tests
SELECT 
    TimeColumn,
    CAST(TimeColumn AS VARCHAR(20)) AS StringTime,
    CAST(CAST(TimeColumn AS VARCHAR(20)) AS TIME) AS BackToTime,
    CAST('1900-01-01 ' + CAST(TimeColumn AS VARCHAR(20)) AS DATETIME) AS TimeToDateTime
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Error handling tests
BEGIN TRY
    DECLARE @t TIME = '24:00:00';
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

-- Test invalid time values
BEGIN TRY
    SELECT CAST('25:00:00' AS TIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Test invalid formats
BEGIN TRY
    SELECT CAST('12:60:00' AS TIME);
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO

-- Time arithmetic with rollover
SELECT 
    TimeColumn,
    CAST(DATEADD(HOUR, 25, CAST(TimeColumn AS DATETIME)) AS TIME) AS Add25Hours,
    CAST(DATEADD(MINUTE, -120, CAST(TimeColumn AS DATETIME)) AS TIME) AS Subtract120Minutes
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- Format conversion tests
SELECT 
    TimeColumn,
    FORMAT(CAST('1900-01-01 ' + CAST(TimeColumn AS VARCHAR(20)) AS DATETIME), 'hh:mm:ss tt') AS Format12Hour,
    FORMAT(CAST('1900-01-01 ' + CAST(TimeColumn AS VARCHAR(20)) AS DATETIME), 'HH:mm:ss') AS Format24Hour
FROM TimeExpressionTest ORDER BY TimeColumn;
GO

-- 10. Additional Tests:

-- Test DATE_BUCKET function with TIME
DECLARE @t TIME = '14:30:20.1234567';
SELECT DATE_BUCKET(HOUR, 1, @t), DATE_BUCKET(MINUTE, 1, @t), DATE_BUCKET(SECOND, 1, @t);
GO

-- Test with different precisions
SELECT 
    CAST('14:30:20' AS TIME) AS [Default],
    CAST('14:30:20.1' AS TIME(1)) AS [1 digit],
    CAST('14:30:20.12' AS TIME(2)) AS [2 digits],
    CAST('14:30:20.123' AS TIME(3)) AS [3 digits],
    CAST('14:30:20.1234' AS TIME(4)) AS [4 digits],
    CAST('14:30:20.12345' AS TIME(5)) AS [5 digits],
    CAST('14:30:20.123456' AS TIME(6)) AS [6 digits],
    CAST('14:30:20.1234567' AS TIME(7)) AS [7 digits];
GO

-- Test with different styles in CONVERT function
SELECT 
    CONVERT(TIME, '14:30:20', 108),     -- hh:mm:ss
    CONVERT(TIME, '02:30:20 PM', 100),  -- hh:mm:ss AM/PM
    CONVERT(TIME, '14.30.20', 104),     -- hh.mm.ss
    CONVERT(TIME, '14:30:20.1234567', 114);  -- hh:mm:ss.nnnnnnn
GO

-- Test AM/PM formats
SELECT 
    CAST('2:30:20 PM' AS TIME) AS [PM time],
    CAST('2:30:20 AM' AS TIME) AS [AM time],
    CAST('14:30:20' AS TIME) AS [24-hour format];
GO

-- Test with different separators
SELECT 
    CAST('14:30:20' AS TIME) AS [Colon separator],
    CAST('14.30.20' AS TIME) AS [Period separator],
    CAST('14 30 20' AS TIME) AS [Space separator];
GO

-- Test time arithmetic
DECLARE @t TIME = '14:30:20.1234567';
SELECT 
    DATEADD(HOUR, 1, @t) AS [Add 1 hour],
    DATEADD(HOUR, -1, @t) AS [Subtract 1 hour],
    DATEADD(MINUTE, 30, @t) AS [Add 30 minutes],
    DATEADD(SECOND, 15, @t) AS [Add 15 seconds],
    DATEADD(MILLISECOND, 500, @t) AS [Add 500 milliseconds];
GO

-- Test time extraction
DECLARE @t TIME = '14:30:20.1234567';
SELECT 
    DATEPART(HOUR, @t) AS [Hour],
    DATEPART(MINUTE, @t) AS [Minute],
    DATEPART(SECOND, @t) AS [Second],
    DATEPART(MILLISECOND, @t) AS [Millisecond],
    DATEPART(MICROSECOND, @t) AS [Microsecond],
    DATEPART(NANOSECOND, @t) AS [Nanosecond];
GO

-- Test with SET LANGUAGE (for AM/PM format)
SET LANGUAGE Italian;
SELECT CAST('14:30:20' AS TIME);
SET LANGUAGE English;
SELECT CAST('2:30:20 PM' AS TIME);
GO

-- Test time range
SELECT 
    CAST('00:00:00.0000000' AS TIME(7)) AS [Minimum TIME],
    CAST('23:59:59.999999' AS TIME(7)) AS [Maximum TIME];
GO

-- Test rounding behavior
SELECT 
    CAST('14:30:20.123456' AS TIME(7)) AS [7 digits],
    CAST('14:30:20.123456' AS TIME(6)) AS [6 digits],
    CAST('14:30:20.123456' AS TIME(5)) AS [5 digits],
    CAST('14:30:20.123456' AS TIME(4)) AS [4 digits],
    CAST('14:30:20.123456' AS TIME(3)) AS [3 digits],
    CAST('14:30:20.123456' AS TIME(2)) AS [2 digits],
    CAST('14:30:20.123456' AS TIME(1)) AS [1 digit],
    CAST('14:30:20.123456' AS TIME(0)) AS [0 digits];
GO

-- Test invalid time formats (these should fail)
SELECT CAST('25:00:00' AS TIME);  -- Invalid hour
GO
SELECT CAST('14:60:00' AS TIME);  -- Invalid minute
GO
SELECT CAST('14:30:60' AS TIME);  -- Invalid second
GO

-- Test with fractional hours and minutes
SELECT 
    CAST('14:30.5:20' AS TIME) AS [Half minute],
    CAST('14.5:30:20' AS TIME) AS [Half hour];
GO

-- Test time zone conversion
DECLARE @t TIME = '14:30:20.1234567';
SELECT 
    @t AS [Original Time],
    CAST(CAST(@t AS DATETIMEOFFSET) AT TIME ZONE 'Pacific Standard Time' AS TIME) AS [Pacific Time];
GO

-- Test with different precision levels and DATEADD
DECLARE @t TIME(7) = '14:30:20.1234567';
SELECT 
    DATEADD(NANOSECOND, 1, @t) AS [Add 1 nanosecond],
    DATEADD(MICROSECOND, 1, @t) AS [Add 1 microsecond],
    DATEADD(MILLISECOND, 1, @t) AS [Add 1 millisecond];
GO

-- Test time arithmetic across midnight
DECLARE @t TIME = '23:30:00';
SELECT 
    DATEADD(HOUR, 1, @t) AS [Add 1 hour past midnight],
    DATEADD(MINUTE, -30, @t) AS [Subtract 30 minutes];
GO

-- Test with different formats of AM/PM
SELECT 
    CAST('2:30:20 pm' AS TIME) AS [lowercase pm],
    CAST('2:30:20 PM' AS TIME) AS [uppercase PM],
    CAST('2:30:20PM' AS TIME) AS [no space PM];
GO

-- Test precision overflow
SELECT CAST('14:30:20.1234567890' AS TIME(7));  -- More than 7 digits
GO

-- Create a test table for TIME precision testing
CREATE TABLE TimeScaleTest (
    ID INT IDENTITY PRIMARY KEY,
    Description NVARCHAR(100),
    TimeValue TIME(7),
    Scale INT,
    Precision INT,
    StorageBytes INT,
    FractionalPrecision INT,
    FormattedValue NVARCHAR(30)
);
GO

-- Helper function to calculate storage bytes
CREATE FUNCTION CalculateTimeStorageBytes(@scale INT)
RETURNS INT
AS
BEGIN
    RETURN CASE 
        WHEN @scale <= 2 THEN 3
        WHEN @scale <= 4 THEN 4
        ELSE 5
    END;
END;
GO

-- Helper procedure for testing time scales
CREATE PROCEDURE TestTimeScale
    @description NVARCHAR(100),
    @timeStr NVARCHAR(30),
    @scale INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @timeValue TIME(7);
    DECLARE @precision INT;
    DECLARE @fractionalPrecision INT;
    
    SET @sql = N'DECLARE @t TIME(' + CAST(@scale AS NVARCHAR(1)) + ') = ''' + @timeStr + ''';';
    SET @sql += N'SELECT @tv = CAST(@t AS TIME(7));';
    
    BEGIN TRY
        EXEC sp_executesql @sql, N'@tv TIME(7) OUTPUT', @tv = @timeValue OUTPUT;
        
        -- Calculate precision based on scale
        SET @precision = CASE @scale
            WHEN 0 THEN 8
            WHEN 1 THEN 10
            WHEN 2 THEN 11
            WHEN 3 THEN 12
            WHEN 4 THEN 13
            WHEN 5 THEN 14
            WHEN 6 THEN 15
            WHEN 7 THEN 16
        END;
        
        -- Calculate fractional precision
        SET @fractionalPrecision = CASE 
            WHEN @scale <= 2 THEN 2
            WHEN @scale <= 4 THEN 4
            ELSE 7
        END;
        
        INSERT INTO TimeScaleTest (
            Description, 
            TimeValue, 
            Scale, 
            Precision, 
            StorageBytes, 
            FractionalPrecision,
            FormattedValue
        )
        VALUES (
            @description,
            @timeValue,
            @scale,
            @precision,
            dbo.CalculateTimeStorageBytes(@scale),
            @fractionalPrecision,
            CONVERT(NVARCHAR(30), @timeValue, 121)
        );
        
        PRINT 'Success: ' + @description;
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + @description + ' - ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Test cases for each scale
-- Scale 0 (3 bytes, precision 8)
EXEC TestTimeScale 'TIME(0) Basic', '14:30:20', 0;
GO
EXEC TestTimeScale 'TIME(0) Round Down', '14:30:20.4', 0;
GO
EXEC TestTimeScale 'TIME(0) Round Up', '14:30:20.5', 0;
GO

-- Scale 1 (3 bytes, precision 10)
EXEC TestTimeScale 'TIME(1) Basic', '14:30:20.1', 1;
GO
EXEC TestTimeScale 'TIME(1) Round Down', '14:30:20.14', 1;
GO
EXEC TestTimeScale 'TIME(1) Round Up', '14:30:20.15', 1;
GO

-- Scale 2 (3 bytes, precision 11)
EXEC TestTimeScale 'TIME(2) Basic', '14:30:20.12', 2;
GO
EXEC TestTimeScale 'TIME(2) Round Down', '14:30:20.124', 2;
GO
EXEC TestTimeScale 'TIME(2) Round Up', '14:30:20.125', 2;
GO

-- Scale 3 (4 bytes, precision 12)
EXEC TestTimeScale 'TIME(3) Basic', '14:30:20.123', 3;
GO
EXEC TestTimeScale 'TIME(3) Round Down', '14:30:20.1234', 3;
GO
EXEC TestTimeScale 'TIME(3) Round Up', '14:30:20.1235', 3;
GO

-- Scale 4 (4 bytes, precision 13)
EXEC TestTimeScale 'TIME(4) Basic', '14:30:20.1234', 4;
GO
EXEC TestTimeScale 'TIME(4) Round Down', '14:30:20.12344', 4;
GO
EXEC TestTimeScale 'TIME(4) Round Up', '14:30:20.12345', 4;
GO

-- Scale 5 (5 bytes, precision 14)
EXEC TestTimeScale 'TIME(5) Basic', '14:30:20.12345', 5;
GO
EXEC TestTimeScale 'TIME(5) Round Down', '14:30:20.123454', 5;
GO
EXEC TestTimeScale 'TIME(5) Round Up', '14:30:20.123455', 5;
GO

-- Scale 6 (5 bytes, precision 15)
EXEC TestTimeScale 'TIME(6) Basic', '14:30:20.123456', 6;
GO
EXEC TestTimeScale 'TIME(6) Round Down', '14:30:20.1234564', 6;
GO
EXEC TestTimeScale 'TIME(6) Round Up', '14:30:20.1234565', 6;
GO

-- Scale 7 (5 bytes, precision 16)
EXEC TestTimeScale 'TIME(7) Basic', '14:30:20.1234567', 7;
GO
EXEC TestTimeScale 'TIME(7) Maximum', '23:59:59.999999', 7;
GO
EXEC TestTimeScale 'TIME(7) Minimum', '00:00:00.0000000', 7;
GO

-- Edge cases for each scale
-- Testing boundary values
EXEC TestTimeScale 'TIME(0) Boundary', '23:59:59', 0;
GO
EXEC TestTimeScale 'TIME(1) Boundary', '23:59:59', 1;
GO
EXEC TestTimeScale 'TIME(2) Boundary', '23:59:59', 2;
GO
EXEC TestTimeScale 'TIME(3) Boundary', '23:59:59', 3;
GO
EXEC TestTimeScale 'TIME(4) Boundary', '23:59:59', 4;
GO
EXEC TestTimeScale 'TIME(5) Boundary', '23:59:59', 5;
GO
EXEC TestTimeScale 'TIME(6) Boundary', '23:59:59', 6;
GO
EXEC TestTimeScale 'TIME(7) Boundary', '23:59:59', 7;
GO

-- Testing precision overflow
EXEC TestTimeScale 'TIME(0) Overflow', '14:30:20.1234567890', 0;
GO
EXEC TestTimeScale 'TIME(3) Overflow', '14:30:20.1234567890', 3;
GO
EXEC TestTimeScale 'TIME(7) Overflow', '14:30:20.1234567890', 7;
GO

-- Display results with detailed analysis
SELECT 
    ID,
    Description,
    TimeValue,
    Scale,
    Precision,
    StorageBytes,
    FractionalPrecision,
    FormattedValue,
    LEN(FormattedValue) AS FormattedLength,
    CASE 
        WHEN Scale <= 2 THEN '0-2'
        WHEN Scale <= 4 THEN '3-4'
        ELSE '5-7'
    END AS ScaleGroup
FROM TimeScaleTest
ORDER BY Scale, ID;
GO

-- Clean up: Drop all created objects
DROP FUNCTION CalculateTimeStorageBytes;
DROP PROCEDURE TestTimeScale;
DROP TABLE TimeScaleTest;
DROP INDEX IX_TimeIndexTest_TimeColumn ON TimeIndexTest;
DROP INDEX IX_TimeIndexTest_TimeColumn_TimeColumn2 ON TimeIndexTest;
DROP INDEX IX_TimeIndexTest_Filtered ON TimeIndexTest;
DROP INDEX IX_TimeIndexTest_TimeColumn_Include ON TimeIndexTest;
DROP TABLE TimeTest;
DROP TABLE TimeDefaultTest;
DROP FUNCTION dbo.GetCurrentTime;
DROP TABLE TimeFormatTest;
DROP PROCEDURE InsertTimeTest;
DROP PROCEDURE InsertTimeTest1;
DROP PROCEDURE TestTimeFormat;
DROP TABLE TimeConversionTest;
DROP PROCEDURE InsertTimeConversionTest;
DROP TABLE UDDTTimeTest;
DROP PROCEDURE TestUDDTTimeProc;
DROP TYPE BusinessTime;
DROP TYPE ShiftTime;
DROP TYPE PreciseTime;
DROP FUNCTION dbo.TestTimeFunction;
DROP TABLE TimeImplicitConversionTest;
DROP PROCEDURE InsertTimeTestResult;
DROP FUNCTION dbo.AddHoursToTime;
DROP PROCEDURE dbo.ProcessTime;
DROP VIEW dbo.TimeView;
DROP TABLE TimeDMLTestChild;
DROP TABLE TimeDMLTest;
DROP TABLE TimeIndexTest;
DROP TABLE TimeExpressionTest;
DROP TABLE TimeTest1;
DROP TABLE TIME_partition;
DROP PARTITION SCHEME TIME_partition_scheme;
DROP PARTITION FUNCTION TIME_partition_func;
GO
