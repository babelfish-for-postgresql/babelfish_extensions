select * from sys.time_zone_info;
GO
-- Test Case 1: Basic query to verify time zone information
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
ORDER BY name;
GO
--Test case 2: Find specific time zone
SELECT * FROM sys.time_zone_info 
WHERE name = 'Eastern Standard Time';
GO
-- Test Case 3: Find all time zones with specific UTC offset
SELECT name, current_utc_offset
FROM sys.time_zone_info
WHERE current_utc_offset = '-05:00';
GO
-- Test Case 4: Check Daylight Saving Time zones
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE is_currently_dst = 1;
GO

-- Test case 5: Time zones with unusual offsets (not full hours)
SELECT name, current_utc_offset
FROM sys.time_zone_info
WHERE current_utc_offset LIKE '%:30' 
   OR current_utc_offset LIKE '%:45'
ORDER BY current_utc_offset;
GO
-- Test case 6: Function to find specific pattern
DROP FUNCTION IF EXISTS dbo.FindZonesByPattern;
GO
CREATE FUNCTION dbo.FindZonesByPattern(@pattern NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        name,
        current_utc_offset,
        is_currently_dst,
        CASE 
            WHEN is_currently_dst = 1 THEN 'DST'
            ELSE 'STD'
        END AS time_type
    FROM sys.time_zone_info
    WHERE name LIKE '%' + @pattern + '%'
);
GO
-- Test
SELECT * FROM dbo.FindZonesByPattern('Pacific') ORDER BY name;
GO
-- Test case 7: Function to Get zones in offset range
DROP FUNCTION IF EXISTS dbo.GetZonesInOffsetRange;
GO
CREATE FUNCTION dbo.GetZonesInOffsetRange(@startOffset VARCHAR(6), @endOffset VARCHAR(6))
RETURNS TABLE
AS
RETURN
(
    SELECT name, current_utc_offset, is_currently_dst
    FROM sys.time_zone_info
    WHERE current_utc_offset BETWEEN @startOffset AND @endOffset
);
GO
SELECT * FROM dbo.GetZonesInOffsetRange('+08:00', '+10:00') ORDER BY current_utc_offset;
GO
-- Test case 8: GMT/UTC zones
DROP VIEW IF EXISTS dbo.ZeroOffsetZones;
GO
CREATE VIEW dbo.ZeroOffsetZones AS
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info 
WHERE current_utc_offset = '+00:00';
GO

SELECT * FROM dbo.ZeroOffsetZones;
GO

--Test Case 9: Zones with numbers in names
DROP VIEW IF EXISTS dbo.NumericNameZones;
GO
CREATE VIEW dbo.NumericNameZones AS
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE name LIKE '%[0-9]%';
GO

SELECT * FROM dbo.NumericNameZones ORDER BY name;
GO

--Test 10: Palindromic offset detection
DROP VIEW IF EXISTS dbo.PalindromicOffsets;
GO
CREATE VIEW dbo.PalindromicOffsets AS
SELECT 
    name,
    current_utc_offset,
    CASE 
        WHEN REVERSE(SUBSTRING(current_utc_offset, 2, 5)) = SUBSTRING(current_utc_offset, 2, 5) THEN 'Palindromic'
        ELSE 'Non-Palindromic'
    END AS palindrome_status
FROM sys.time_zone_info
WHERE REVERSE(SUBSTRING(current_utc_offset, 2, 5)) = SUBSTRING(current_utc_offset, 2, 5);
GO

SELECT * FROM dbo.PalindromicOffsets;
GO

--Test case 11: Edge case for testing duplicate enteries (should not exist)
SELECT 
    name,
    current_utc_offset,
    is_currently_dst,
    COUNT(*) AS duplicate_count
FROM sys.time_zone_info
GROUP BY name, current_utc_offset, is_currently_dst
HAVING COUNT(*) > 1;
GO


