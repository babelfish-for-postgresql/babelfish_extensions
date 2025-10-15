--Test case 1: To print the SST
SELECT * FROM dbo.vw_UTC;
GO
--Test case 2: To print the IST
SELECT * FROM v_test;
GO
--Test case 3: Check for any null values
SELECT COUNT(*) as null_value_count
FROM sys.time_zone_info
WHERE name IS NULL OR current_utc_offset IS NULL OR is_currently_dst IS NULL;
GO
--Test case 4: Count total number of timezones
SELECT * FROM dbo.vw_TimeZoneCount;
GO
--Test case 5: To print all the UTC timezones
SELECT name, current_utc_offset
FROM dbo.fn_GetUTCZonesWithOffset()
ORDER BY sort_order;
GO
--Test case 6: To print duplicates
SELECT name, COUNT(*) as name_count
FROM sys.time_zone_info
GROUP BY name
HAVING COUNT(*) > 1;
GO
--Test case 7: To print top 3 Timezone names
SELECT TOP 3 name
FROM sys.time_zone_info
ORDER BY name;
GO
--Test case 8: verify null case
SELECT sys.pltsql_timezone_mapping_pg_to_windows(' ');
GO
SELECT sys.pltsql_timezone_mapping_pg_to_windows('123');
GO
--Test case 9: Verify the timezone existance
EXEC sp_ValidateTimeZoneData 'Indian Standard Time';
GO
EXEC sp_ValidateTimeZoneData 'UTC-02';
GO
--Test case 10: To validate the utc format                  
SELECT dbo.validate_utc_offset(''); 
GO
SELECT dbo.validate_utc_offset('+02:00');
GO
--Test to loose test to validate the count of timezone name
SELECT CASE WHEN COUNT(name) >= 135 THEN 1 ELSE 0 END AS test FROM sys.time_zone_info;
GO
--Test case 11: To verify if there exists a timezone :The following timezone values have been commented out due to: Expected DST and non-DST offset values may change due to future timezone policy updates and to prevent potential flaky test cases
SELECT dbo.test_timezone_offset('Utc-11', '-11:00', '-11:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc', '+00:00', '+00:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc-09', '-09:00', '-09:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc-08', '-08:00', '-08:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc-02', '-02:00', '-02:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc+12', '+12:00', '+12:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Utc+13', '+13:00', '+13:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('Dateline standard time', '-12:00', '-12:00') AS test_result_utc;
GO
SELECT dbo.test_timezone_offset('India Standard Time', '+05:30', '+05:30') AS test_result_utc;
GO
-- SELECT dbo.test_timezone_offset('China standard time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Russian standard time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Arabian Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Singapore Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Tokyo standard time', '+09:00', '+09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Alaskan Standard Time', '-08:00', '-09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Pacific Standard Time', '-07:00', '-08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Mountain Standard Time', '-06:00', '-07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Central Standard Time', '-05:00', '-06:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Eastern Standard Time', '-04:00', '-05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Haiti Standard Time', '-04:00', '-05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Cuba Standard Time', '-04:00', '-05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('US Eastern Standard Time', '-04:00', '-05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Atlantic Standard Time', '-03:00', '-04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Pacific SA Standard Time', '-03:00', '-04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Newfoundland Standard Time', '-02:30', '-03:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Saint Pierre Standard Time', '-02:00', '-03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Azores Standard Time', '+00:00', '-01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Central Europe Standard Time', '+02:00', '+01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Romance Standard Time', '+02:00', '+01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Central European Standard Time', '+02:00', '+01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('GTB Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Egypt Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('E. Europe Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('West Bank Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('FLE Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Israel Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Cen. Australia Standard Time', '+10:30', '+09:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('AUS Eastern Standard Time', '+11:00', '+10:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Tasmania Standard Time', '+11:00', '+10:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Lord Howe Standard Time', '+11:00', '+10:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('New Zealand Standard Time', '+13:00', '+12:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Chatham Islands Standard Time', '+13:45', '+12:45') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Marquesas Standard Time', '-09:30', '-09:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Yukon Standard Time', '-07:00', '-07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Central Standard Time (Mexico)', '-06:00', '-06:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Canada Central Standard Time', '-6:00', '-06:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Venezuela Standard Time', '-04:00', '-04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('SA Eastern Standard Time', '-03:00', '-03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Argentina Standard Time', '-03:00', '-03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Bahia Standard Time', '-03:00', '-03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Cape Verde Standard Time', '-01:00', '-01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Sao Tome Standard Time', '+00:00', '+00:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('W. Central Africa Standard Time', '+01:00', '+01:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('South Africa Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('South Sudan Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Kaliningrad Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Sudan Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Libya Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Namibia Standard Time', '+02:00', '+02:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Jordan Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Arabic Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Turkey Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Arab Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('E. Africa Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Volgograd Standard Time', '+03:00', '+03:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Iran Standard Time', '+03:30', '+03:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Astrakhan Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Azerbaijan Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Russia Time Zone 3', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Mauritius Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Georgian Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Caucasus Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Afghanistan Standard Time', '+04:30', '+04:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('West Asia Standard Time', '+05:00', '+05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Ekaterinburg Standard Time', '+05:00', '+05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Pakistan Standard Time', '+05:00', '+05:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Sri Lanka Standard Time', '+05:30', '+05:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Nepal Standard Time', '+05:45', '+05:45') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Bangladesh Standard Time', '+06:00', '+06:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Omsk Standard Time', '+06:00', '+06:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Myanmar Standard Time', '+06:30', '+06:30') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('SE Asia Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Altai Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('W. Mongolia Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('North Asia Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('N. Central Asia Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Tomsk Standard Time', '+07:00', '+07:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('North Asia East Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Singapore Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('W. Australia Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Ulaanbaatar Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Tokyo Standard Time', '+09:00', '+09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('North Korea Standard Time', '+09:00', '+09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Korea Standard Time', '+09:00', '+09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Yakutsk Standard Time', '+09:00', '+09:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('West Pacific Standard Time', '+10:00', '+10:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Vladivostok Standard Time', '+10:00', '+10:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Bougainville Standard Time', '+11:00', '+11:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Russia Time Zone 10', '+11:00', '+11:00') AS test_result_utc;
-- GO
-- SELECT dbo.test_timezone_offset('Magadan Standard Time', '+11:00', '+11:00') AS test_result_utc;
-- GO
-- -- SELECT dbo.test_timezone_offset('Sakhalin Standard Time', '+11:00', '+11:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Qyzylorda Standard Time', '+05:00', '+05:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('AUS Central Standard Time', '+09:30', '+09:30') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Aus Central W. Standard Time', '+08:45', '+08:45') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Mountain Standard Time (Mexico)', '-06:00', '-07:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Arabian Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('E. Australia Standard Time', '+11:00', '+10:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Kamchatka Standard Time', '+13:00', '+12:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Greenwich Standard Time', 'N/A', '+00:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Taipei Standard Time', '+08:00', '+08:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Middle East Standard Time', '+03:00', '+02:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Saratov Standard Time', '+04:00', '+04:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Fiji Standard Time', '+12:00', '+12:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Belarus Standard Time', 'N/A', '+03:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Turks And Caicos Standard Time', '-04:00', '-05:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Central America Standard Time', 'N/A', '-06:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Greenland Standard Time', '-01:00', '-02:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Aleutian Standard Time', '-09:00', '-08:00') AS test_result_atc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('GMT Standard Time', '+01:00', '+00:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Pacific Standard Time (Mexico)', '-07:00', '-08:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Syria Standard Time', 'N/A', '+03:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Easter Island Standard Time', '-05:00', '-06:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Morocco Standard Time', '+01:00', '+00:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('SA Western Standard Time', 'N/A', '-04:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Tocantins Standard Time', 'N/A', '-03:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Norfolk Standard Time', '+12:00', '+11:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Nepal standard time', '+05:45', '+05:45') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Paraguay Standard Time', 'N/A', '-03:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('Mid-Atlantic Standard Time', 'N/A', '-02:00') AS test_result_utc;
-- -- GO
-- -- SELECT dbo.test_timezone_offset('W. Europe Standard Time', '+02:00', '+01:00') AS test_result_utc;
-- -- GO