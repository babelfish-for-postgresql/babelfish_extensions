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

-- Create table for stability testing of DATENAME
-- to store results under different configurations
CREATE TABLE datename_stability_test (
    config_type VARCHAR(20),
    config_value VARCHAR(30),
    test_date VARCHAR(50),
    datepart VARCHAR(20),
    result NVARCHAR(100)
);
GO


-- Testing SET LANGUAGE stability
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('Initial', 'default', '2025-06-30', 'weekday', DATENAME(weekday, '2025-06-30'));
GO

    -- SET LANGUAGE 'us_english' (default)
SET LANGUAGE 'us_english';
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('LANGUAGE', 'us_english', '2025-06-30', 'weekday', DATENAME(weekday, '2025-06-30'));
GO

    -- SET LANGUAGE 'French' (not fully supported but test anyway)
SET LANGUAGE 'French';
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('LANGUAGE', 'French', '2025-06-30', 'weekday', DATENAME(weekday, '2025-06-30'));
GO

    -- Restore default language
SET LANGUAGE 'us_english';
GO


-- Testing SET DATEFIRST stability
    -- SET DATEFIRST 7 (default - Sunday)
SET DATEFIRST 7;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFIRST', '7', '2025-01-05', 'week', DATENAME(week, '2025-01-05'));
GO

    -- SET DATEFIRST 1 (Monday)
SET DATEFIRST 1;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFIRST', '1', '2025-01-05', 'week', DATENAME(week, '2025-01-05'));
GO

    -- Restore default
SET DATEFIRST 7;
GO


-- Testing SET DATEFORMAT stability
    -- SET DATEFORMAT mdy (default)
SET DATEFORMAT mdy;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'mdy', '03-06-2025', 'month', DATENAME(month, '03-06-2025'));
GO

    -- SET DATEFORMAT dmy (not supported, treated as mdy)
SET DATEFORMAT dmy;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'dmy', '03-06-2025', 'month', DATENAME(month, '03-06-2025'));
GO


    -- SET DATEFORMAT ymd
SET DATEFORMAT ymd;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'ymd', '2025-03-06', 'month', DATENAME(month, '2025-03-06'));
GO

    -- SET DATEFORMAT ydm (not supported, treated as ymd)
SET DATEFORMAT ydm;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'ydm', '2025-03-06', 'month', DATENAME(month, '2025-03-06'));
GO


    -- SET DATEFORMAT myd (not supported currently)
SET DATEFORMAT myd;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'myd', '06-2025-03', 'month', DATENAME(month, '06-2025-03'));
GO

    -- SET DATEFORMAT dym (not supported currently)
SET DATEFORMAT dym;
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES ('DATEFORMAT', 'dym', '06-2025-03', 'month', DATENAME(month, '06-2025-03'));
GO

    -- Restore default
SET DATEFORMAT mdy;
GO


-- Testing SET_CONFIG('TIMEZONE') stability
    -- Set timezone to UTC
SELECT set_config('timezone', 'UTC', false);
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result) 
VALUES 
('TIMEZONE', 'UTC', '2025-06-30 12:00:00', 'hour', DATENAME(hour, '2025-06-30 12:00:00')),
('TIMEZONE', 'UTC', '2025-01-01 05:30:45', 'hour', DATENAME(hour, '2025-01-01 05:30:45'));
GO

    -- Set timezone to a different value
SELECT set_config('timezone', 'Africa/Nairobi', false)
GO
INSERT INTO datename_stability_test (config_type, config_value, test_date, datepart, result)
VALUES 
('TIMEZONE', 'Africa/Nairobi', '2025-06-30 12:00:00', 'hour', DATENAME(hour, '2025-06-30 12:00:00')),
('TIMEZONE', 'Africa/Nairobi', '2025-01-01 05:30:45', 'hour', DATENAME(hour, '2025-01-01 05:30:45'));
GO

    -- Reset timezone to UTC
SELECT set_config('timezone', 'UTC', false);
GO


-- Test table insertion
INSERT INTO datename_tzoffset_test_cases (date_value, offset_value)
VALUES 
('2025-06-03 14:30:15 +01:30', DATENAME(TZOFFSET, '2025-06-03 14:30:15 +01:30')),
('2025-06-03 14:30:15 -05:00', DATENAME(TZOFFSET, '2025-06-03 14:30:15 -05:00')),
('2016-12-26 23:30:05.523456+08:00', DATENAME(TZOFFSET, '2016-12-26 23:30:05.523456+08:00')),
('2016-12-26 23:30:05.523456+8', DATENAME(TZOFFSET, CAST('2016-12-26 23:30:05.523456+8' AS DATETIMEOFFSET)));
GO

CREATE TABLE datename_tzoffset_different_test_scenarios (
    test_description VARCHAR(100),
    test_input VARCHAR(100),
    test_result TEXT
);
GO

INSERT INTO datename_tzoffset_different_test_scenarios (test_description, test_input, test_result)
VALUES ('DATE type', 
        'datename(TZOFFSET, CAST(''2025-06-03 14:30:15 +01:30'' AS DATE))', 
        datename(TZOFFSET, CAST('2025-06-03 14:30:15 +01:30' AS DATE))),
       ('TIME type', 
        'datename(TZOFFSET, CAST(''14:30:15'' AS TIME))', 
        datename(TZOFFSET, CAST('14:30:15' AS TIME))),
       ('DATETIME type', 
        'datename(TZOFFSET, CAST(''2025-06-03 14:30:15'' AS DATETIME))', 
        datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIME))),
       ('SMALLDATETIME type', 
        'datename(TZOFFSET, CAST(''2025-06-03 14:30:15'' AS SMALLDATETIME))', 
        datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS SMALLDATETIME)));
GO

INSERT INTO datename_tzoffset_different_test_scenarios (test_description, test_input, test_result)
VALUES ('DATETIME2 type', 
        'datename(TZOFFSET, CAST(''2025-06-03 14:30:15'' AS DATETIME2))', 
        datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIME2))),
       ('DATETIMEOFFSET type', 
        'datename(TZOFFSET, CAST(''2025-06-03 14:30:15'' AS DATETIMEOFFSET))', 
        datename(TZOFFSET, CAST('2025-06-03 14:30:15' AS DATETIMEOFFSET)));
GO

INSERT INTO datename_tzoffset_different_test_scenarios (test_description, test_input, test_result)
VALUES ('out of range positive', 
        'DATENAME(TZOFFSET, CAST(''2025-06-03 14:30:15 +14:01'' AS DATETIMEOFFSET))', 
        DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 +14:01' AS DATETIMEOFFSET))),
       ('out of range negative', 
        'DATENAME(TZOFFSET, ''2025-06-03 14:30:15 -14:01'')', 
        DATENAME(TZOFFSET, '2025-06-03 14:30:15 -14:01'));
GO

INSERT INTO datename_tzoffset_different_test_scenarios (test_description, test_input, test_result)
VALUES ('boundary max value', 
        'DATENAME(TZOFFSET, CAST(''2025-06-03 14:30:15 +14:00'' AS DATETIMEOFFSET))', 
        DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 +14:00' AS DATETIMEOFFSET))),
       ('boundary min value', 
        'DATENAME(TZOFFSET, CAST(''2025-06-03 14:30:15 -14:00'' AS DATETIMEOFFSET))', 
        DATENAME(TZOFFSET, CAST('2025-06-03 14:30:15 -14:00' AS DATETIMEOFFSET)));
GO