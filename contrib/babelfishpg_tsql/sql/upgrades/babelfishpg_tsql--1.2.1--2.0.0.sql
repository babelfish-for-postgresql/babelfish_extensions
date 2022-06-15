 -- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.0.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a function if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_function(schema_name varchar, func_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop function %s.%s', schema_name, func_name);
    query2 := format('drop function %s.%s', schema_name, func_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop function' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- Fix sys.syslanguages
truncate sys.syslanguages;

INSERT INTO sys.syslanguages
     VALUES (1,
             'ENGLISH',
             'ENGLISH (AUSTRALIA)',
             NULL,
             NULL,
             'AUSTRALIA',
             'EN_AU',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (2,
             'ENGLISH',
             'ENGLISH (BELGIUM)',
             NULL,
             NULL,
             'BELGIUM',
             'EN_BE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (3,
             'ENGLISH',
             'ENGLISH (BELIZE)',
             NULL,
             NULL,
             'BELIZE',
             'EN_BZ',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (4,
             'ENGLISH',
             'ENGLISH (BOTSWANA)',
             NULL,
             NULL,
             'BOTSWANA',
             'EN_BW',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (5,
             'ENGLISH',
             'ENGLISH (CAMEROON)',
             NULL,
             NULL,
             'CAMEROON',
             'EN_CM',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (6,
             'ENGLISH',
             'ENGLISH (CANADA)',
             NULL,
             NULL,
             'CANADA',
             'EN_CA',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (7,
             'ENGLISH',
             'ENGLISH (ERITREA)',
             NULL,
             NULL,
             'ERITREA',
             'EN_ER',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (8,
             'ENGLISH',
             'ENGLISH (INDIA)',
             NULL,
             NULL,
             'INDIA',
             'EN_IN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (9,
             'ENGLISH',
             'ENGLISH (IRELAND)',
             NULL,
             NULL,
             'IRELAND',
             'EN_IE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (10,
             'ENGLISH',
             'ENGLISH (JAMAICA)',
             NULL,
             NULL,
             'JAMAICA',
             'EN_IM',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (11,
             'ENGLISH',
             'ENGLISH (KENYA)',
             NULL,
             NULL,
             'KENYA',
             'EN_KE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (12,
             'ENGLISH',
             'ENGLISH (MALAYSIA)',
             NULL,
             NULL,
             'MALAYSIA',
             'EN_MY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (13,
             'ENGLISH',
             'ENGLISH (MALTA)',
             NULL,
             NULL,
             'MALTA',
             'EN_MT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (14,
             'ENGLISH',
             'ENGLISH (NEW ZEALAND)',
             NULL,
             NULL,
             'NEW ZEALAND',
             'EN_NZ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (15,
             'ENGLISH',
             'ENGLISH (NIGERIA)',
             NULL,
             NULL,
             'NIGERIA',
             'EN_NG',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (16,
             'ENGLISH',
             'ENGLISH (PAKISTAN)',
             NULL,
             NULL,
             'PAKISTAN',
             'EN_PK',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (17,
             'ENGLISH',
             'ENGLISH (PHILIPPINES)',
             NULL,
             NULL,
             'PHILIPPINES',
             'EN_PH',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (18,
             'ENGLISH',
             'ENGLISH (PUERTO RICO)',
             NULL,
             NULL,
             'PUERTO RICO',
             'EN_PR',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (19,
             'ENGLISH',
             'ENGLISH (SINGAPORE)',
             NULL,
             NULL,
             'SINGAPORE',
             'EN_SG',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (20,
             'ENGLISH',
             'ENGLISH (SOUTH AFRICA)',
             NULL,
             NULL,
             'SOUTH AFRICA',
             'EN_ZA',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (21,
             'ENGLISH',
             'ENGLISH (TRINIDAD & TOBAGO)',
             NULL,
             NULL,
             'TRINIDAD & TOBAGO',
             'EN_TT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (22,
             'ENGLISH',
             'ENGLISH (GREAT BRITAIN)',
             'BRITISH',
             'BRITISH ENGLISH',
             'GREAT BRITAIN',
             'EN_GB',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (23,
             'ENGLISH',
             'ENGLISH (UNITED KINGDOM)',
             NULL,
             NULL,
             'UNITED KINGDOM',
             'EN_UK',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (24,
             'ENGLISH',
             'ENGLISH (ENGLAND)',
             NULL,
             NULL,
             'ENGLAND',
             'EN_EN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (25,
             'ENGLISH',
             'ENGLISH (UNITED STATES)',
             'US_ENGLISH',
             'ENGLISH',
             'UNITED STATES',
             'EN_US',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 7,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (26,
             'ENGLISH',
             'ENGLISH (ZIMBABWE)',
             NULL,
             NULL,
             'ZIMBABWE',
             'EN_ZW',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (27,
             'GERMAN',
             'GERMAN (AUSTRIA)',
             NULL,
             NULL,
             'AUSTRIA',
             'DE_AT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (28,
             'GERMAN',
             'GERMAN (BELGIUM)',
             NULL,
             NULL,
             'BELGIUM',
             'DE_BE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (29,
             'GERMAN',
             'GERMAN (GERMANY)',
             'DEUTSCH',
             'GERMAN',
             'GERMANY',
             'DE_DE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (30,
             'GERMAN',
             'GERMAN (LIECHTENSTEIN)',
             NULL,
             NULL,
             'LIECHTENSTEIN',
             'DE_LI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (31,
             'GERMAN',
             'GERMAN (LUXEMBOURG)',
             NULL,
             NULL,
             'LUXEMBOURG',
             'DE_LU',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (32,
             'GERMAN',
             'GERMAN (SWITZERLAND)',
             NULL,
             NULL,
             'SWITZERLAND',
             'DE_CH',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'),
                                'days_names', jsonb_build_array('Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (33,
             'FRENCH',
             'FRENCH (ALGERIA)',
             NULL,
             NULL,
             'ALGERIA',
             'FR_DZ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (34,
             'FRENCH',
             'FRENCH (BELGIUM)',
             NULL,
             NULL,
             'BELGIUM',
             'FR_BE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (35,
             'FRENCH',
             'FRENCH (CAMEROON)',
             NULL,
             NULL,
             'CAMEROON',
             'FR_CM',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (36,
             'FRENCH',
             'FRENCH (CANADA)',
             NULL,
             NULL,
             'CANADA',
             'FR_CA',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (37,
             'FRENCH',
             'FRENCH (FRANCE)',
             'FRANÇAIS',
             'FRENCH',
             'FRANCE',
             'FR_FR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (38,
             'FRENCH',
             'FRENCH (HAITI)',
             NULL,
             NULL,
             'HAITI',
             'FR_HT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (39,
             'FRENCH',
             'FRENCH (LUXEMBOURG)',
             NULL,
             NULL,
             'LUXEMBOURG',
             'FR_LU',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (40,
             'FRENCH',
             'FRENCH (MALI)',
             NULL,
             NULL,
             'MALI',
             'FR_ML',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (41,
             'FRENCH',
             'FRENCH (MONACO)',
             NULL,
             NULL,
             'MONACO',
             'FR_MC',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (42,
             'FRENCH',
             'FRENCH (MOROCCO)',
             NULL,
             NULL,
             'MOROCCO',
             'FR_MA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (43,
             'FRENCH',
             'FRENCH (SENEGAL)',
             NULL,
             NULL,
             'SENEGAL',
             'FR_SN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (44,
             'FRENCH',
             'FRENCH (SWITZERLAND)',
             NULL,
             NULL,
             'SWITZERLAND',
             'FR_CH',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (45,
             'FRENCH',
             'FRENCH (SYRIA)',
             NULL,
             NULL,
             'SYRIA',
             'FR_SY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (46,
             'FRENCH',
             'FRENCH (TUNISIA)',
             NULL,
             NULL,
             'TUNISIA',
             'FR_TN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'),
                                'months_shortnames', jsonb_build_array('janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'),
                                'days_names', jsonb_build_array('lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (47,
             'JAPANESE',
             'JAPANESE (JAPAN)',
             '日本語',
             'JAPANESE',
             'JAPAN',
             'JA_JP',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 7,
                                'months_names', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (48,
             'DANISH',
             'DANISH (DENMARK)',
             'DANSK',
             'DANISH',
             'DENMARK',
             'DA_DK',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januar', 'februar', 'marts', 'april', 'maj', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (49,
             'DANISH',
             'DANISH (GREENLAND)',
             NULL,
             NULL,
             'GREENLAND',
             'DA_GL',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januar', 'februar', 'marts', 'april', 'maj', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'days_names', jsonb_build_array('mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (50,
             'SPANISH',
             'SPANISH (ARGENTINA)',
             NULL,
             NULL,
             'ARGENTINA',
             'ES_AR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (51,
             'SPANISH',
             'SPANISH (BOLIVIA)',
             NULL,
             NULL,
             'BOLIVIA',
             'ES_BO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (52,
             'SPANISH',
             'SPANISH (CHILE)',
             NULL,
             NULL,
             'CHILE',
             'ES_CL',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (53,
             'SPANISH',
             'SPANISH (COLOMBIA)',
             NULL,
             NULL,
             'COLOMBIA',
             'ES_CO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (54,
             'SPANISH',
             'SPANISH (COSTA RICA)',
             NULL,
             NULL,
             'COSTA RICA',
             'ES_CR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (55,
             'SPANISH',
             'SPANISH (CUBA)',
             NULL,
             NULL,
             'CUBA',
             'ES_CU',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (56,
             'SPANISH',
             'SPANISH (DOMINICAN REPUBLIC)',
             NULL,
             NULL,
             'DOMINICAN REPUBLIC',
             'ES_DO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (57,
             'SPANISH',
             'SPANISH (ECUADOR)',
             NULL,
             NULL,
             'ECUADOR',
             'ES_EC',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (58,
             'SPANISH',
             'SPANISH (EL SALVADOR)',
             NULL,
             NULL,
             'EL SALVADOR',
             'ES_SV',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (59,
             'SPANISH',
             'SPANISH (GUATEMALA)',
             NULL,
             NULL,
             'GUATEMALA',
             'ES_GT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (60,
             'SPANISH',
             'SPANISH (HONDURASALA)',
             NULL,
             NULL,
             'HONDURAS',
             'ES_HN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (61,
             'SPANISH',
             'SPANISH (MEXICO)',
             NULL,
             NULL,
             'MEXICO',
             'ES_MX',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (62,
             'SPANISH',
             'SPANISH (NICARAGUA)',
             NULL,
             NULL,
             'NICARAGUA',
             'ES_NI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (63,
             'SPANISH',
             'SPANISH (PANAMA)',
             NULL,
             NULL,
             'PANAMA',
             'ES_PA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (64,
             'SPANISH',
             'SPANISH (PARAGUAY)',
             NULL,
             NULL,
             'PARAGUAY',
             'ES_PY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (65,
             'SPANISH',
             'SPANISH (PERU)',
             NULL,
             NULL,
             'PERU',
             'ES_PE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (66,
             'SPANISH',
             'SPANISH (PHILIPPINES)',
             NULL,
             NULL,
             'PHILIPPINES',
             'ES_PH',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (67,
             'SPANISH',
             'SPANISH (PUERTO RICO)',
             NULL,
             NULL,
             'PUERTO RICO',
             'ES_PR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (68,
             'SPANISH',
             'SPANISH (SPAIN)',
             'ESPAÑOL',
             'SPANISH',
             'SPAIN',
             'ES_ES',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (69,
             'SPANISH',
             'SPANISH (UNITED STATES)',
             NULL,
             NULL,
             'UNITED STATES',
             'ES_US',
             jsonb_build_object('date_format', 'MDY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (70,
             'SPANISH',
             'SPANISH (URUGUAY)',
             NULL,
             NULL,
             'URUGUAY',
             'ES_UY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (71,
             'SPANISH',
             'SPANISH (VENEZUELA)',
             NULL,
             NULL,
             'VENEZUELA',
             'ES_VE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'),
                                'months_shortnames', jsonb_build_array('Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'),
                                'days_names', jsonb_build_array('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (72,
             'ITALIAN',
             'ITALIAN (ITALY)',
             'ITALIANO',
             'ITALIAN',
             'ITALY',
             'IT_IT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'),
                                'months_shortnames', jsonb_build_array('gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (73,
             'ITALIAN',
             'ITALIAN (SWITZERLAND)',
             NULL,
             NULL,
             'SWITZERLAND',
             'IT_CH',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno', 'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre'),
                                'months_shortnames', jsonb_build_array('gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'),
                                'days_names', jsonb_build_array('lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (74,
             'DUTCH',
             'DUTCH (BELGIUM)',
             NULL,
             NULL,
             'BELGIUM',
             'NL_BE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'days_names', jsonb_build_array('maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (75,
             'DUTCH',
             'DUTCH (NETHERLANDS)',
             'NEDERLANDS',
             'DUTCH',
             'NETHERLANDS',
             'NL_NL',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (76,
             'NORWEGIAN',
             'NORWEGIAN (NORWAY)',
             NULL,
             NULL,
             'NORWAY',
             'NO_NO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'mai', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'des'),
                                'days_names', jsonb_build_array('mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (77,
             'NORWEGIAN (MS SQL)',
             'NORWEGIAN NYNORSK (NORWAY)',
             'NORSK',
             'NORWEGIAN',
             'NORWAY',
             'NN_NO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januar', 'februar', 'mars', 'april', 'mai', 'juni', 'juli', 'august', 'september', 'oktober', 'november', 'desember'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'mai', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'des'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('mandag', 'tirsdag', 'onsdag', 'torsdag', 'fredag', 'lørdag', 'søndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (78,
             'PORTUGUESE',
             'PORTUGUESE (BRAZIL)',
             'PORTUGUESE',
             'BRAZILIAN',
             'BRAZIL',
             'PT_BR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 7,
                                'months_names', jsonb_build_array('janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'),
                                'months_shortnames', jsonb_build_array('jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (79,
             'PORTUGUESE',
             'PORTUGUESE (PORTUGAL)',
             'PORTUGUÊS',
             'PORTUGUESE',
             'PORTUGAL',
             'PT_PT',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 7,
                                'months_names', jsonb_build_array('janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'),
                                'months_shortnames', jsonb_build_array('jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (80,
             'FINNISH',
             'FINNISH (FINLAND)',
             NULL,
             NULL,
             'FINLAND',
             'FI_FI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('tammikuuta', 'helmikuuta', 'maaliskuuta', 'huhtikuuta', 'toukokuuta', 'kesäkuuta', 'heinäkuuta', 'elokuuta', 'syyskuuta', 'lokakuuta', 'marraskuuta', 'joulukuuta'),
                                'months_shortnames', jsonb_build_array('tammi', 'helmi', 'maalis', 'huhti', 'touko', 'kesä', 'heinä', 'elo', 'syys', 'loka', 'marras', 'joulu'),
                                'days_names', jsonb_build_array('maanantai', 'tiistai', 'keskiviikko', 'torstai', 'perjantai', 'lauantai', 'sunnuntai'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (81,
             'FINNISH (MS SQL)',
             'FINNISH (FINLAND)',
             'SUOMI',
             'FINNISH',
             'FINLAND',
             'FI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('tammikuuta', 'helmikuuta', 'maaliskuuta', 'huhtikuuta', 'toukokuuta', 'kesäkuuta', 'heinäkuuta', 'elokuuta', 'syyskuuta', 'lokakuuta', 'marraskuuta', 'joulukuuta'),
                                'months_shortnames', jsonb_build_array('tammi', 'helmi', 'maalis', 'huhti', 'touko', 'kesä', 'heinä', 'elo', 'syys', 'loka', 'marras', 'joulu'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('maanantai', 'tiistai', 'keskiviikko', 'torstai', 'perjantai', 'lauantai', 'sunnuntai'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (82,
             'SWEDISH',
             'SWEDISH (FINLAND)',
             NULL,
             NULL,
             'FINLAND',
             'SV_FI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 'augusti', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'days_names', jsonb_build_array('måndag', 'tisdag', 'onsdag', 'torsdag', 'fredag', 'lördag', 'söndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (83,
             'SWEDISH',
             'SWEDISH (SWEDEN)',
             'SVENSKA',
             'SWEDISH',
             'SWEDEN',
             'SV_SE',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 'augusti', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('måndag', 'tisdag', 'onsdag', 'torsdag', 'fredag', 'lördag', 'söndag'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (84,
             'CZECH',
             'CZECH (CZECH REPUBLIC)',
             'ČEŠTINA',
             'CZECH',
             'CZECHIA',
             'CS_CZ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('leden', 'únor', 'březen', 'duben', 'květen', 'červen', 'červenec', 'srpen', 'září', 'říjen', 'listopad', 'prosinec'),
                                'months_shortnames', jsonb_build_array('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota', 'neděle'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (85,
             'HUNGARIAN',
             'HUNGARIAN (HUNGARY)',
             'MAGYAR',
             'HUNGARIAN',
             'HUNGARY',
             'HU_HU',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('január', 'február', 'március', 'április', 'május', 'június', 'július', 'augusztus', 'szeptember', 'október', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
								'days_names', jsonb_build_array('hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat', 'vasárnap'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (86,
             'POLISH',
             'POLISH (POLAND)',
             'POLSKI',
             'POLISH',
             'POLAND',
             'PL_PL',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('styczeń', 'luty', 'marzec', 'kwiecień', 'maj', 'czerwiec', 'lipiec', 'sierpień', 'wrzesień', 'październik', 'listopad', 'grudzień'),
                                'months_shortnames', jsonb_build_array('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (87,
             'ROMANIAN',
             'ROMANIAN (MOLDOVA)',
             NULL,
             NULL,
             'MOLDOVA',
             'RO_MD',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'),
                                'months_shortnames', jsonb_build_array('Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('luni', 'marţi', 'miercuri', 'joi', 'vineri', 'sîmbătă', 'duminică'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (88,
             'ROMANIAN',
             'ROMANIAN (ROMANIA)',
             'ROMÂNĂ',
             'ROMANIAN',
             'ROMANIA',
             'RO_RO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'),
                                'months_shortnames', jsonb_build_array('Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('luni', 'marţi', 'miercuri', 'joi', 'vineri', 'sîmbătă', 'duminică'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (89,
             'CROATIAN',
             'CROATIAN (CROATIA)',
             'HRVATSKI',
             'CROATIAN',
             'CROATIA',
             'HR_HR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('siječanj', 'veljača', 'ožujak', 'travanj', 'svibanj', 'lipanj', 'srpanj', 'kolovoz', 'rujan', 'listopad', 'studeni', 'prosinac'),
                                'months_shortnames', jsonb_build_array('sij', 'vel', 'ožu', 'tra', 'svi', 'lip', 'srp', 'kol', 'ruj', 'lis', 'stu', 'pro'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('ponedjeljak', 'utorak', 'srijeda', 'četvrtak', 'petak', 'subota', 'nedjelja'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (90,
             'SLOVAK',
             'SLOVAK (SLOVAKIA)',
             'SLOVENČINA',
             'SLOVAK',
             'SLOVAKIA',
             'SK_SK',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('január', 'február', 'marec', 'apríl', 'máj', 'jún', 'júl', 'august', 'september', 'október', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('pondelok', 'utorok', 'streda', 'štvrtok', 'piatok', 'sobota', 'nedeľa'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (91,
             'SLOVENIAN',
             'SLOVENIAN (SLOVENIA)',
             'SLOVENSKI',
             'SLOVENIAN',
             'SLOVENIA',
             'SL_SI',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('januar', 'februar', 'marec', 'april', 'maj', 'junij', 'julij', 'avgust', 'september', 'oktober', 'november', 'december'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sept', 'okt', 'nov', 'dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('ponedeljek', 'torek', 'sreda', 'četrtek', 'petek', 'sobota', 'nedelja'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (92,
             'GREEK',
             'GREEK (GREECE)',
             'ΕΛΛΗΝΙΚΆ',
             'GREEK',
             'GREECE',
             'EL_GR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου', 'Μα_ου', 'Ιουνίου', 'Ιουλίου', 'Αυγούστου', 'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου'),
                                'months_shortnames', jsonb_build_array('Ιαν', 'Φεβ', 'Μαρ', 'Απρ', 'Μαϊ', 'Ιουν', 'Ιουλ', 'Αυγ', 'Σεπ', 'Οκτ', 'Νοε', 'Δεκ'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο', 'Κυριακή'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (93,
             'BULGARIAN',
             'BULGARIAN (BULGARIA)',
             'БЪЛГАРСКИ',
             'BULGARIAN',
             'BULGARIA',
             'BG_BG',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('януари', 'февруари', 'март', 'април', 'май', 'юни', 'юли', 'август', 'септември', 'октомври', 'ноември', 'декември'),
                                'months_shortnames', jsonb_build_array('януари', 'февруари', 'март', 'април', 'май', 'юни', 'юли', 'август', 'септември', 'октомври', 'ноември', 'декември'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('понеделник', 'вторник', 'сряда', 'четвъртък', 'петък', 'събота', 'неделя'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (94,
             'RUSSIAN',
             'RUSSIAN (BELARUS)',
             NULL,
             NULL,
             'BELARUS',
             'RU_BY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (95,
             'RUSSIAN',
             'RUSSIAN (KAZAKHSTAN)',
             NULL,
             NULL,
             'KAZAKHSTAN',
             'RU_KZ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (96,
             'RUSSIAN',
             'RUSSIAN (KYRGYZSTAN)',
             NULL,
             NULL,
             'KYRGYZSTAN',
             'RU_KG',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (97,
             'RUSSIAN',
             'RUSSIAN (MOLDOVA)',
             NULL,
             NULL,
             'MOLDOVA',
             'RU_MD',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (98,
             'RUSSIAN',
             'RUSSIAN (RUSSIA)',
             'РУССКИЙ',
             'RUSSIAN',
             'RUSSIA',
             'RU_RU',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (99,
             'RUSSIAN',
             'RUSSIAN (UKRAINE)',
             NULL,
             NULL,
             'UKRAINE',
             'RU_UA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'),
                                'months_shortnames', jsonb_build_array('янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'),
                                'days_names', jsonb_build_array('понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (100,
             'TURKISH',
             'TURKISH (TURKEY)',
             'TÜRKÇE',
             'TURKISH',
             'TURKEY',
             'TR_TR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'),
                                'months_shortnames', jsonb_build_array('Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (101,
             'ESTONIAN',
             'ESTONIAN (ESTONIA)',
             'EESTI',
             'ESTONIAN',
             'ESTONIA',
             'ET_EE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('jaanuar', 'veebruar', 'märts', 'aprill', 'mai', 'juuni', 'juuli', 'august', 'september', 'oktoober', 'november', 'detsember'),
                                'months_shortnames', jsonb_build_array('jaan', 'veebr', 'märts', 'apr', 'mai', 'juuni', 'juuli', 'aug', 'sept', 'okt', 'nov', 'dets'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('esmaspäev', 'teisipäev', 'kolmapäev', 'neljapäev', 'reede', 'laupäev', 'pühapäev'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (102,
             'LATVIAN',
             'LATVIAN (LATVIA)',
             'LATVIEŠU',
             'LATVIAN',
             'LATVIA',
             'LV_LV',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('janvāris', 'februāris', 'marts', 'aprīlis', 'maijs', 'jūnijs', 'jūlijs', 'augusts', 'septembris', 'oktobris', 'novembris', 'decembris'),
                                'months_shortnames', jsonb_build_array('jan', 'feb', 'mar', 'apr', 'mai', 'jūn', 'jūl', 'aug', 'sep', 'okt', 'nov', 'dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('pirmdiena', 'otrdiena', 'trešdiena', 'ceturtdiena', 'piektdiena', 'sestdiena', 'svētdiena'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (103,
             'LITHUANIAN',
             'LITHUANIAN (LITHUANIA)',
             'LIETUVIŲ',
             'LITHUANIAN',
             'LITHUANIA',
             'LT_LT',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 1,
                                'months_names', jsonb_build_array('sausis', 'vasaris', 'kovas', 'balandis', 'gegužė', 'birželis', 'liepa', 'rugpjūtis', 'rugsėjis', 'spalis', 'lapkritis', 'gruodis'),
                                'months_shortnames', jsonb_build_array('sau', 'vas', 'kov', 'bal', 'geg', 'bir', 'lie', 'rgp', 'rgs', 'spl', 'lap', 'grd'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
								'days_names', jsonb_build_array('pirmadienis', 'antradienis', 'trečiadienis', 'ketvirtadienis', 'penktadienis', 'šeštadienis', 'sekmadienis'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (104,
             'CHINESE (TRADITIONAL)',
             'CHINESE (TRADITIONAL, CHINA)',
             '繁體中文',
             'TRADITIONAL CHINESE',
             'CHINA',
             'ZH_TW',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 7,
                                'months_names', jsonb_build_array('一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'),
                                'months_shortnames', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (105,
             'KOREAN',
             'KOREAN (NORTH KOREA)',
             NULL,
             NULL,
             'NORTH KOREA',
             'KO_KP',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 7,
                                'months_names', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_shortnames', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'days_names', jsonb_build_array('월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (106,
             'KOREAN',
             'KOREAN (SOUTH KOREA)',
             '한국어',
             'KOREAN',
             'KOREA',
             'KO_KR',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 7,
                                'months_names', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_shortnames', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (107,
             'CHINESE (SIMPLIFIED)',
             'CHINESE (SIMPLIFIED, CHINA)',
             '简体中文',
             'SIMPLIFIED CHINESE',
             'CHINA',
             'ZH_CN',
             jsonb_build_object('date_format', 'YMD',
                                'date_first', 7,
                                'months_names', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_shortnames', jsonb_build_array('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'),
                                'days_extrashortnames', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')));

INSERT INTO sys.syslanguages
     VALUES (108,
             'ARABIC (MS SQL)',
             'ARABIC (ARABIC)',
             'GENERAL ARABIC',
             'GENERAL ARABIC',
             'ARABIC',
             'AR',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (109,
             'ARABIC',
             'ARABIC (ALGERIA)',
             NULL,
             NULL,
             'ALGERIA',
             'AR_DZ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (110,
             'ARABIC',
             'ARABIC (BAHRAIN)',
             NULL,
             NULL,
             'BAHRAIN',
             'AR_BH',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (111,
             'ARABIC',
             'ARABIC (EGYPT)',
             NULL,
             NULL,
             'EGYPT',
             'AR_EG',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (112,
             'ARABIC',
             'ARABIC (ERITREA)',
             NULL,
             NULL,
             'ERITREA',
             'AR_ER',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (113,
             'ARABIC',
             'ARABIC (IRAQ)',
             NULL,
             NULL,
             'IRAQ',
             'AR_IQ',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (114,
             'ARABIC',
             'ARABIC (ISRAEL)',
             NULL,
             NULL,
             'ISRAEL',
             'AR_IL',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (115,
             'ARABIC',
             'ARABIC (JORDAN)',
             NULL,
             NULL,
             'JORDAN',
             'AR_JO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (116,
             'ARABIC',
             'ARABIC (KUWAIT)',
             NULL,
             NULL,
             'KUWAIT',
             'AR_KW',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (117,
             'ARABIC',
             'ARABIC (LEBANON)',
             NULL,
             NULL,
             'LEBANON',
             'AR_LB',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (118,
             'ARABIC',
             'ARABIC (LIBYA)',
             NULL,
             NULL,
             'LIBYA',
             'AR_LY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (119,
             'ARABIC',
             'ARABIC (MOROCCO)',
             NULL,
             NULL,
             'MOROCCO',
             'AR_MA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (120,
             'ARABIC',
             'ARABIC (OMAN)',
             NULL,
             NULL,
             'OMAN',
             'AR_OM',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (121,
             'ARABIC',
             'ARABIC (QATAR)',
             NULL,
             NULL,
             'QATAR',
             'AR_QA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (122,
             'ARABIC',
             'ARABIC (SAUDI ARABIA)',
             'ARABIC',
             'ARABIC',
             'SAUDI ARABIA',
             'AR_SA',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (123,
             'ARABIC',
             'ARABIC (SOMALIA)',
             NULL,
             NULL,
             'SOMALIA',
             'AR_SO',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (124,
             'ARABIC',
             'ARABIC (SYRIA)',
             NULL,
             NULL,
             'SYRIA',
             'AR_SY',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (125,
             'ARABIC',
             'ARABIC (TUNISIA)',
             NULL,
             NULL,
             'TUNISIA',
             'AR_TN',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (126,
             'ARABIC',
             'ARABIC (UNITED ARAB EMIRATES)',
             NULL,
             NULL,
             'UNITED ARAB EMIRATES',
             'AR_AE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (127,
             'ARABIC',
             'ARABIC (YEMEN)',
             NULL,
             NULL,
             'YEMEN',
             'AR_YE',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('Muharram', 'Safar', 'Rabie I', 'Rabie II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaaban', 'Ramadan', 'Shawwal', 'Thou Alqadah', 'Thou Alhajja'),
                                'months_shortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (128,
             'THAI',
             'THAI (THAILAND)',
             'ไทย',
             'THAI',
             'THAILAND',
             'TH_TH',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 7,
                                'months_names', jsonb_build_array('มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'),
                                'months_shortnames', jsonb_build_array('ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

INSERT INTO sys.syslanguages
     VALUES (129,
             'HIJRI',
             'HIJRI (ISLAMIC)',
             'HIJRI',
             'ISLAMIC',
             'ISLAMIC',
             'HI_IS',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('محرم', 'صفر', 'ربيع الاول', 'ربيع الثاني', 'جمادى الاولى', 'جمادى الثانية', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'),
                                'months_shortnames', jsonb_build_array('محرم', 'صفر', 'ربيع الاول', 'ربيع الثاني', 'جمادى الاولى', 'جمادى الثانية', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));

-- Fix sys.babelfish_get_lang_metadata_json
CREATE OR REPLACE FUNCTION sys.babelfish_get_lang_metadata_json(IN p_lang_spec_culture TEXT)
RETURNS JSONB
AS
$BODY$
DECLARE
    v_locale_parts TEXT[];
    v_lang_data_jsonb JSONB;
    v_lang_spec_culture VARCHAR;
    v_is_cached BOOLEAN := FALSE;
BEGIN
    v_lang_spec_culture := upper(trim(p_lang_spec_culture));

    IF (char_length(v_lang_spec_culture) > 0)
    THEN
        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s',
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            v_lang_spec_culture := upper(regexp_replace(v_lang_spec_culture, '-\s*', '_', 'gi'));
            IF (v_lang_spec_culture IN ('AR', 'FI') OR
                v_lang_spec_culture ~ '_')
            THEN
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.syslanguages
                 WHERE spec_culture = v_lang_spec_culture;
            ELSE
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.syslanguages
                 WHERE lang_name_mssql = v_lang_spec_culture
                    OR lang_alias_mssql = v_lang_spec_culture;
            END IF;
        ELSE
            v_is_cached := TRUE;
        END IF;
    ELSE
        v_lang_spec_culture := current_setting('LC_TIME');

        v_lang_spec_culture := CASE
                                  WHEN (v_lang_spec_culture !~ '\.') THEN v_lang_spec_culture
                                  ELSE substring(v_lang_spec_culture, '(.*)(?:\.)')
                               END;

        v_lang_spec_culture := upper(regexp_replace(v_lang_spec_culture, ',\s*', '_', 'gi'));

        BEGIN
            v_lang_data_jsonb := nullif(current_setting(format('sys.lang_metadata_json.%s',
                                                               v_lang_spec_culture)), '')::JSONB;
        EXCEPTION
            WHEN undefined_object THEN
            v_lang_data_jsonb := NULL;
        END;

        IF (v_lang_data_jsonb IS NULL)
        THEN
            BEGIN
                IF (char_length(v_lang_spec_culture) = 5)
                THEN
                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
                ELSE
                    v_locale_parts := string_to_array(v_lang_spec_culture, '-');

                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.syslanguages
                     WHERE lang_name_pg = v_locale_parts[1]
                       AND territory = v_locale_parts[2];
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_lang_spec_culture := 'EN_US';

                    SELECT lang_data_jsonb
                      INTO v_lang_data_jsonb
                      FROM sys.syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
            END;
        ELSE
            v_is_cached := TRUE;
        END IF;
    END IF;

    IF (NOT v_is_cached) THEN
        PERFORM set_config(format('sys.lang_metadata_json.%s',
                                  v_lang_spec_culture),
                           v_lang_data_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_lang_data_jsonb;
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE USING MESSAGE := format('The language metadata JSON value extracted from chache is not a valid JSON object.',
                                      p_lang_spec_culture),
                    HINT := 'Drop the current session, fix the appropriate record in "sys.syslanguages" table, and try again after reconnection.';

    WHEN OTHERS THEN
        RAISE USING MESSAGE := format('"%s" is not a valid special culture or language name parameter.',
                                      p_lang_spec_culture),
                    DETAIL := 'Use of incorrect "lang_spec_culture" parameter value during conversion process.',
                    HINT := 'Change "lang_spec_culture" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- Rename function for dependencies
ALTER FUNCTION sys.tsql_stat_get_activity(text) RENAME TO tsql_stat_get_activity_deprecated_2_0;
ALTER FUNCTION sys.sp_datatype_info_helper(smallint, bool) RENAME TO sp_datatype_info_helper_deprecated_2_0;

-- Re-create the renamed functions
CREATE OR REPLACE FUNCTION sys.tsql_stat_get_activity(
  IN view_name text,
  OUT procid int,
  OUT client_version int,
  OUT library_name VARCHAR(32),
  OUT language VARCHAR(128),
  OUT quoted_identifier bool,
  OUT arithabort bool,
  OUT ansi_null_dflt_on bool,
  OUT ansi_defaults bool,
  OUT ansi_warnings bool,
  OUT ansi_padding bool,
  OUT ansi_nulls bool,
  OUT concat_null_yields_null bool,
  OUT textsize int,
  OUT datefirst int,
  OUT lock_timeout int,
  OUT transaction_isolation int2,
  OUT client_pid int,
  OUT row_count bigint,
  OUT error int,
  OUT trancount int,
  OUT protocol_version int,
  OUT packet_size int,
  OUT encrypyt_option VARCHAR(40),
  OUT database_id int2)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_stat_get_activity'
LANGUAGE C VOLATILE STRICT;

CREATE OR REPLACE FUNCTION sys.sp_datatype_info_helper(
    IN odbcVer smallint,
    IN is_100 bool,
    OUT TYPE_NAME VARCHAR(20),
    OUT DATA_TYPE INT,
    OUT "PRECISION" BIGINT,
    OUT LITERAL_PREFIX VARCHAR(20),
    OUT LITERAL_SUFFIX VARCHAR(20),
    OUT CREATE_PARAMS VARCHAR(20),
    OUT NULLABLE INT,
    OUT CASE_SENSITIVE INT,
    OUT SEARCHABLE INT,
    OUT UNSIGNED_ATTRIBUTE INT,
    OUT MONEY INT,
    OUT AUTO_INCREMENT INT,
    OUT LOCAL_TYPE_NAME VARCHAR(20),
    OUT MINIMUM_SCALE INT,
    OUT MAXIMUM_SCALE INT,
    OUT SQL_DATA_TYPE INT,
    OUT SQL_DATETIME_SUB INT,
    OUT NUM_PREC_RADIX INT,
    OUT INTERVAL_PRECISION INT,
    OUT USERTYPE INT,
    OUT LENGTH INT,
    OUT SS_DATA_TYPE smallint,
-- below column is added in order to join PG's information_schema.columns for sys.sp_columns_100_view
    OUT PG_TYPE_NAME VARCHAR(20)
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'sp_datatype_info_helper'
LANGUAGE C IMMUTABLE STRICT;

-- Re-create dependent objects for sys.tsql_stat_get_activity(text)
create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , coalesce(t.database_id, 0)::oid as dbid
  , a.usesysid as uid
  , 0 as cpu
  , 0 as physical_io
  , 0 as memusage
  , a.backend_start as login_time
  , a.query_start as last_batch
  , 0 as ecid
  , 0 as open_tran
  , a.state as status
  , null::bytea as sid
  , a.client_hostname as hostname
  , a.application_name as program_name
  , null::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , null::bytea as context_info
  , null::bytea as sql_handle
  , 0 as stmt_start
  , 0 as stmt_end
  , 0 as request_id
from pg_stat_activity a
left join sys.tsql_stat_get_activity('sessions') as t on a.pid = t.procid
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database(); /* current physical database will always be babelfish database */
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , a.client_hostname::sys.nvarchar(128) as host_name
    , a.application_name::sys.nvarchar(128) as program_name
    , d.client_pid as host_process_id
    , d.client_version as client_version
    , d.library_name::sys.nvarchar(32) as client_interface_name
    , null::sys.varbinary(85) as security_id
    , a.usename::sys.nvarchar(128) as login_name
    , (select sys.default_domain())::sys.nvarchar(128) as nt_domain
    , null::sys.nvarchar(128) as nt_user_name
    , a.state::sys.nvarchar(30) as status
    , null::sys.nvarchar(128) as context_info
    , null::integer as cpu_time
    , null::integer as memory_usage
    , null::integer as total_scheduled_time
    , null::integer as total_elapsed_time
    , a.client_port as endpoint_id
    , a.query_start::sys.datetime as last_request_start_time
    , a.state_change::sys.datetime as last_request_end_time
    , null::bigint as "reads"
    , null::bigint as "writes"
    , null::bigint as logical_reads
    , case when a.client_port > 0 then 1::sys.bit else 0::sys.bit end as is_user_process
    , d.textsize as text_size
    , d.language::sys.nvarchar(128) as language
    , 'ymd'::sys.nvarchar(3) as date_format-- Bld 173 lacks support for SET DATEFORMAT and always expects ymd
    , d.datefirst::smallint as date_first -- Bld 173 lacks support for SET DATEFIRST and always returns 7
    , CAST(CAST(d.quoted_identifier as integer) as sys.bit) as quoted_identifier
    , CAST(CAST(d.arithabort as integer) as sys.bit) as arithabort
    , CAST(CAST(d.ansi_null_dflt_on as integer) as sys.bit) as ansi_null_dflt_on
    , CAST(CAST(d.ansi_defaults as integer) as sys.bit) as ansi_defaults
    , CAST(CAST(d.ansi_warnings as integer) as sys.bit) as ansi_warnings
    , CAST(CAST(d.ansi_padding as integer) as sys.bit) as ansi_padding
    , CAST(CAST(d.ansi_nulls as integer) as sys.bit) as ansi_nulls
    , CAST(CAST(d.concat_null_yields_null as integer) as sys.bit) as concat_null_yields_null
    , d.transaction_isolation::smallint as transaction_isolation_level
    , d.lock_timeout as lock_timeout
    , 0 as deadlock_priority
    , d.row_count as row_count
    , d.error as prev_error
    , null::sys.varbinary(85) as original_security_id
    , a.usename::sys.nvarchar(128) as original_login_name
    , null::sys.datetime as last_successful_logon
    , null::sys.datetime as last_unsuccessful_logon
    , null::bigint as unsuccessful_logons
    , null::int as group_id
    , d.database_id::smallint as database_id
    , 0 as authenticating_database_id
    , d.trancount as open_transaction_count
  from pg_catalog.pg_stat_activity AS a
  RIGHT JOIN sys.tsql_stat_get_activity('sessions') AS d ON (a.pid = d.procid);
  GRANT SELECT ON sys.dm_exec_sessions TO PUBLIC;

create or replace view sys.dm_exec_connections
 as
 select a.pid as session_id
   , a.pid as most_recent_session_id
   , a.backend_start::sys.datetime as connect_time
   , 'TCP'::sys.nvarchar(40) as net_transport
   , 'TSQL'::sys.nvarchar(40) as protocol_type
   , d.protocol_version as protocol_version
   , 4 as endpoint_id
   , d.encrypyt_option::sys.nvarchar(40) as encrypt_option
   , null::sys.nvarchar(40) as auth_scheme
   , null::smallint as node_affinity
   , null::int as num_reads
   , null::int as num_writes
   , null::sys.datetime as last_read
   , null::sys.datetime as last_write
   , d.packet_size as net_packet_size
   , a.client_addr::varchar(48) as client_net_address
   , a.client_port as client_tcp_port
   , null::varchar(48) as local_net_address
   , null::int as local_tcp_port
   , null::sys.uniqueidentifier as connection_id
   , null::sys.uniqueidentifier as parent_connection_id
   , a.pid::sys.varbinary(64) as most_recent_sql_handle
 from pg_catalog.pg_stat_activity AS a
 RIGHT JOIN sys.tsql_stat_get_activity('connections') AS d ON (a.pid = d.procid);
 GRANT SELECT ON sys.dm_exec_connections TO PUBLIC;

-- Re-create dependent objects for sys.sp_datatype_info_helper(smallint, bool)
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT DISTINCT 
CAST(1 as smallint) AS SCOPE,
CAST(coalesce (split_part(pa.attoptions[1], '=', 2) ,c1.name) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS smallint) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN c1.is_identity = 1 AND (t8.name = 'decimal' or t8.name = 'numeric') 
	THEN CAST(CONCAT(t8.name, '() identity') AS sys.sysname)
	WHEN c1.is_identity = 1 AND (t8.name != 'decimal' AND t8.name != 'numeric')
	THEN CAST(CONCAT(t8.name, ' identity') AS sys.sysname)
	ELSE CAST(t8.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS int) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS smallint) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CAST(c1.is_nullable AS int) AS IS_NULLABLE,
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN idx.is_unique = 1 AND (idx.is_unique_constraint !=1 AND idx.is_primary_key != 1)
	THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
	ELSE CAST(t5.contype AS sys.sysname)
END AS CONSTRAINT_TYPE
        
FROM pg_catalog.pg_class t1 
	JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
	JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
	LEFT JOIN pg_constraint t5 ON t1.oid = t5.conrelid
	LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
	JOIN sys.columns c1 ON t1.oid = c1.object_id

	JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
	JOIN sys.types as t8 ON c1.user_type_id = t8.user_type_id 
	LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name OR t7.typname = t6.type_name --need in order to get accurate DATA_TYPE value
	LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname
	, sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
	, sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
	WHERE (t5.contype = 'p' OR t5.contype = 'u' 
	OR ((idx.is_unique = 1) AND (idx.is_primary_key !=1 AND idx.is_unique_constraint !=1))) -- Only looking for unique indexes
	AND (CAST(c1.column_id AS smallint) = ANY (t5.conkey) OR ((idx.is_unique = 1) AND (idx.is_primary_key !=1 AND idx.is_unique_constraint !=1)))
	AND has_schema_privilege(s1.schema_id, 'USAGE');
  
GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC;

-- === DROP deprecated functions (if exists)
CALL sys.babelfish_drop_deprecated_function('sys', 'tsql_stat_get_activity_deprecated_2_0');
CALL sys.babelfish_drop_deprecated_function('sys', 'sp_datatype_info_helper_deprecated_2_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_function(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);