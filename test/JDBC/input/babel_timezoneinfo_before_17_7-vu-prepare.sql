CREATE VIEW vw_UTC_Zero AS
SELECT 
    'UTC' AS timezone_name,
    '+00:00' AS utc_offset,
    0 AS is_dst;
GO

CREATE VIEW v_test AS
SELECT name FROM sys.time_zone_info 
WHERE name = 'India Standard Time';
GO