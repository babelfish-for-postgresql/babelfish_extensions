-- Function to find specific pattern
DROP FUNCTION IF EXISTS dbo.FindZonesByPattern;
GO

-- Function to Get zones in offset range
DROP FUNCTION IF EXISTS dbo.GetZonesInOffsetRange;
GO

-- GMT/UTC zones
DROP VIEW IF EXISTS dbo.ZeroOffsetZones;
GO

-- Zones with numbers in names
DROP VIEW IF EXISTS dbo.NumericNameZones;
GO

-- Palindromic offset detection
DROP VIEW IF EXISTS dbo.PalindromicOffsets;
GO
 
-- Procedure to check valid and invalid cases
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'ValidateTimeZone')
    DROP PROCEDURE ValidateTimeZone;
GO

-- Trigger to find valid/invalid time zones
IF OBJECT_ID('sp_ValidateTimeZoneData', 'P') IS NOT NULL
    DROP PROCEDURE sp_ValidateTimeZoneData;
GO
