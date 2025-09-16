-- Function to find specific pattern
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

-- Function to get zones in offset range
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

--GMT/UTC zones
CREATE VIEW dbo.ZeroOffsetZones AS
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info 
WHERE current_utc_offset = '+00:00';
GO

-- Zone with number in names
CREATE VIEW dbo.NumericNameZones AS
SELECT name, current_utc_offset, is_currently_dst
FROM sys.time_zone_info
WHERE name LIKE '%[0-9]%';
GO

-- Palindromic offset detection
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

-- Procedure to find valid/invalid cases
CREATE PROCEDURE ValidateTimeZone
    @zoneName NVARCHAR(128),
    @expectedOffset VARCHAR(6)
AS
BEGIN
    
    IF EXISTS (
        SELECT 1 
        FROM sys.time_zone_info 
        WHERE name = @zoneName 
        AND current_utc_offset = @expectedOffset
    )
        SELECT 'pass' as result, 
               'Testing ' + @zoneName + ' for offset ' + @expectedOffset as test_description;
    ELSE
        SELECT 'fail' as result, 
               'Testing ' + @zoneName + ' for offset ' + @expectedOffset as test_description;
END;
GO

-- Trigger
CREATE PROCEDURE sp_ValidateTimeZoneData
    @zoneName NVARCHAR(128)
AS
BEGIN
    DECLARE @count INT;
    
    SELECT @count = COUNT(*)
    FROM sys.time_zone_info
    WHERE name = @zoneName;
    
    IF @count = 0
        SELECT 'Invalid' as validation_result, @zoneName as zone_name;
    ELSE
        SELECT 'Valid' as validation_result, @zoneName as zone_name;
END;
GO