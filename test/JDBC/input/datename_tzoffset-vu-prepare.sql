CREATE TABLE datename_tzoffset_test_cases (
    date_value VARCHAR(50),
    offset_value NVARCHAR(100)
);
GO

-- Create view for date inputs without offset specified
CREATE VIEW datename_tzoffset_no_offset_tests_view AS 
SELECT 
    datename(TZOFFSET, '2025-06-03 14:30:15.1234567') AS datetime2_offset,
    datename(TZOFFSET, '2025-06-03') AS date_offset,
    datename(TZOFFSET, '14:30:15.1234567') AS timestamp_offset,
    datename(TZOFFSET, '') AS empty_string_offset;
GO
