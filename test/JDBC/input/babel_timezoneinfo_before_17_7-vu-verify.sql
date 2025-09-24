-- Test Case 1: Basic query to verify time zone information
SELECT TOP 5 name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE current_utc_offset = '-04:00'
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
SELECT TOP 3 name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE is_currently_dst = 1
ORDER BY name;
GO
-- Test case 5: Time zones with unusual offsets (not full hours)
SELECT name, current_utc_offset
FROM sys.time_zone_info
WHERE current_utc_offset LIKE '%:30' 
ORDER BY name;
GO
-- Test function to specific pattern
SELECT * FROM dbo.FindZonesByPattern('Pacific') ORDER BY name;
GO
-- Test function to verify 
SELECT * FROM dbo.GetZonesInOffsetRange('+08:00', '+10:00') ORDER BY current_utc_offset;
GO
-- Test to check the UTC/GMT zones
SELECT * FROM dbo.ZeroOffsetZones;
GO
-- Test zones with numbers in names
SELECT * FROM dbo.NumericNameZones ORDER BY name;
GO
-- Test palindromic offset 
SELECT * FROM dbo.PalindromicOffsets;
GO
--Test case: Edge case for testing duplicate enteries (should not exist)
SELECT 
    name,
    current_utc_offset,
    is_currently_dst,
    COUNT(*) AS duplicate_count
FROM sys.time_zone_info
GROUP BY name, current_utc_offset, is_currently_dst
HAVING COUNT(*) > 1;
GO
-- Test case: Subquery to find "Lonely DST zone"
SELECT name, current_utc_offset
FROM sys.time_zone_info t1
WHERE EXISTS (
    SELECT 1 
    FROM sys.time_zone_info t2
    WHERE t2.current_utc_offset = '+05:45'
    AND t1.name = t2.name
);
GO
--Test cases to check valid/invalid                 
EXEC ValidateTimeZone 'Pacific Standard Time', '-07:00';
EXEC ValidateTimeZone 'UTC', '-08:00';   
EXEC ValidateTimeZone 'India Standard Time', '-05:00';
GO
-- Test case:  CTE for DST zones with specific offset
WITH DSTZones AS (
    SELECT name, current_utc_offset
    FROM sys.time_zone_info
    WHERE is_currently_dst = 1
    AND current_utc_offset IN ('-07:00', '-08:00', '-06:00')
)
SELECT * FROM DSTZones;
GO
--Trigger to test valid/invalid time zones
EXEC sp_ValidateTimeZoneData 'India Standard Time';
EXEC sp_ValidateTimeZoneData 'Title Zone';
GO
--Verify the null case
SELECT sys.timezone_mapping_pg_to_windows(' ');
GO
