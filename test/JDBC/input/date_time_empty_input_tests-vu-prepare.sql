CREATE TABLE test_empty_strings (
    id int,
    dt date,
    tm time
);
GO

-- Create view to test empty string casts to date/time
CREATE VIEW empty_string_date_time_view AS
SELECT 
    CAST('' AS date) AS empty_date,
    CAST('   ' AS date) AS space_date,
    CAST('' AS time) AS empty_time,
    CAST('   ' AS time) AS space_time;
GO

-- Create view for varchar/nvarchar to date tests
CREATE VIEW string_vars_to_date_view AS
SELECT
    CAST(CAST('' AS VARCHAR) AS DATE) AS empty_varchar_date,
    CAST(CAST('   ' AS VARCHAR(10)) AS DATE) AS spaces_varchar_date, 
    CAST(CAST(N'' AS NVARCHAR) AS DATE) AS empty_nvarchar_date,
    CAST(CAST(N'   ' AS NVARCHAR(10)) AS DATE) AS spaces_nvarchar_date;
GO

-- Create view for varchar/nvarchar to time tests
CREATE VIEW string_vars_to_time_view AS
SELECT
    CAST(CAST('' AS VARCHAR) AS TIME) AS empty_varchar_time,
    CAST(CAST('   ' AS VARCHAR(10)) AS TIME) AS spaces_varchar_time, 
    CAST(CAST(N'' AS NVARCHAR) AS TIME) AS empty_nvarchar_time,
    CAST(CAST(N'   ' AS NVARCHAR(10)) AS TIME) AS spaces_nvarchar_time;
GO

CREATE VIEW tab_space_dates_view AS
SELECT
    CAST(CHAR(9) AS date) AS tab_date,
    CAST(CHAR(9) AS time) AS tab_time;
GO