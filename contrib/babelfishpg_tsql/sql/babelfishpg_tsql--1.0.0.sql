-- 1 "sql/babelfishpg_tsql.in"
-- 1 "<built-in>"
-- 1 "<command-line>"
-- 1 "sql/babelfishpg_tsql.in"




SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- 1 "sql/datatype.sql" 1
-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;

CREATE DOMAIN sys.CURSOR AS REFCURSOR;

RESET enable_domain_typmod;
-- 8 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/datatype_string_operators.sql" 1
CREATE OR REPLACE FUNCTION sys.hashbytes(IN alg VARCHAR, IN data VARCHAR) RETURNS sys.bbf_varbinary
AS 'babelfishpg_tsql', 'hashbytes' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.hashbytes(IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.hashbytes(IN alg VARCHAR, IN data sys.bbf_varbinary) RETURNS sys.bbf_varbinary
AS 'babelfishpg_tsql', 'hashbytes' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.hashbytes(IN VARCHAR, IN sys.bbf_varbinary) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.quotename(IN input_string VARCHAR, IN delimiter char default '[') RETURNS
sys.nvarchar AS 'babelfishpg_tsql', 'quotename' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.quotename(IN VARCHAR, IN char) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.unicode(IN str VARCHAR) returns INTEGER
as
$BODY$
 select ascii(str);
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.unicode(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.string_split(IN string VARCHAR, IN separator VARCHAR, OUT value VARCHAR) RETURNS SETOF VARCHAR AS
$body$
BEGIN
 if length(separator) != 1 then
  RAISE EXCEPTION 'Invalid separator: %', separator USING HINT =
  'Separator must be length 1';
else
  RETURN QUERY(SELECT cast(unnest(string_to_array(string, separator)) as varchar));
end if;
END
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.string_split(IN VARCHAR, IN VARCHAR, OUT VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.string_escape(IN str sys.NVARCHAR, IN type TEXT) RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'string_escape' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.string_escape(IN sys.NVARCHAR, IN TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str TEXT) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str VARCHAR) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str TEXT, VARIADIC "any") RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN TEXT, VARIADIC "any") TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.formatmessage(IN message_str VARCHAR, VARIADIC "any") RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'formatmessage' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.formatmessage(IN VARCHAR, VARIADIC "any") TO PUBLIC;
-- 9 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys.sql" 1

CREATE FUNCTION sys.sysdatetime() RETURNS datetime2
    AS $$select clock_timestamp()::datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetime() TO PUBLIC;

CREATE FUNCTION sys.sysdatetimeoffset() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(clock_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC;


CREATE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (clock_timestamp() AT TIME ZONE 'UTC')::sys.datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;


CREATE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp()::timestamp)::sys.datetime;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC;


CREATE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp() AT TIME ZONE 'UTC')::sys.datetime;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC;


CREATE FUNCTION sys.isnull(text,text) RETURNS text AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(text,text) TO PUBLIC;

CREATE FUNCTION sys.isnull(boolean,boolean) RETURNS boolean AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(boolean,boolean) TO PUBLIC;

CREATE FUNCTION sys.isnull(smallint,smallint) RETURNS smallint AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(smallint,smallint) TO PUBLIC;

CREATE FUNCTION sys.isnull(integer,integer) RETURNS integer AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(integer,integer) TO PUBLIC;

CREATE FUNCTION sys.isnull(bigint,bigint) RETURNS bigint AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(bigint,bigint) TO PUBLIC;

CREATE FUNCTION sys.isnull(real,real) RETURNS real AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(real,real) TO PUBLIC;

CREATE FUNCTION sys.isnull(double precision, double precision) RETURNS double precision AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(double precision, double precision) TO PUBLIC;

CREATE FUNCTION sys.isnull(numeric,numeric) RETURNS numeric AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(numeric,numeric) TO PUBLIC;

CREATE FUNCTION sys.isnull(date, date) RETURNS date AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(date,date) TO PUBLIC;

CREATE FUNCTION sys.isnull(timestamp,timestamp) RETURNS timestamp AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(timestamp,timestamp) TO PUBLIC;

CREATE FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) RETURNS timestamp with time zone AS $$
  SELECT COALESCE($1,$2);
$$
LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) TO PUBLIC;


CREATE TABLE IF NOT EXISTS sys.service_settings
(
    service character varying(50) NOT NULL
    ,setting character varying(100) NOT NULL
    ,value character varying
);
GRANT SELECT ON sys.service_settings TO PUBLIC;

comment on table sys.service_settings is 'Settings for Extension Pack services';
comment on column sys.service_settings.service is 'Service name';
comment on column sys.service_settings.setting is 'Setting name';
comment on column sys.service_settings.value is 'Setting value';

CREATE TABLE sys.versions
(
    extpackcomponentname VARCHAR(256) NOT NULL,
    componentversion VARCHAR(256)
);
GRANT SELECT ON sys.versions TO PUBLIC;

CREATE TABLE sys.syslanguages (
    lang_id SMALLINT,
    lang_name_pg VARCHAR(30),
    lang_alias_pg VARCHAR(30),
    lang_name_mssql VARCHAR(30),
    lang_alias_mssql VARCHAR(30),
    territory VARCHAR(50),
    spec_culture VARCHAR(10),
    lang_data_jsonb JSONB
) WITH (OIDS = FALSE);
GRANT SELECT ON sys.syslanguages TO PUBLIC;
-- 10 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_languages.sql" 1

INSERT INTO sys.syslanguages
     VALUES (1,
             'ENGLISH',
             'ENGLISH (AUSTRALIA)',
             NULL,
             NULL,
             'AUSTRALIA',
             'EN-AU',
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
             'EN-BE',
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
             'EN-BZ',
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
             'EN-BW',
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
             'EN-CM',
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
             'EN-CA',
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
             'EN-ER',
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
             'EN-IN',
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
             'EN-IE',
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
             'EN-IM',
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
             'EN-KE',
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
             'EN-MY',
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
             'EN-MT',
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
             'EN-NZ',
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
             'EN-NG',
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
             'EN-PK',
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
             'EN-PH',
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
             'EN-PR',
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
             'EN-SG',
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
             'EN-ZA',
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
             'EN-TT',
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
             'EN-GB',
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
             'EN-UK',
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
             'EN-EN',
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
             'EN-US',
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
             'EN-ZW',
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
             'DE-AT',
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
             'DE-BE',
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
             'DE-DE',
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
             'DE-LI',
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
             'DE-LU',
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
             'DE-CH',
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
             'FR-DZ',
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
             'FR-BE',
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
             'FR-CM',
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
             'FR-CA',
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
             'FR-FR',
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
             'FR-HT',
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
             'FR-LU',
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
             'FR-ML',
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
             'FR-MC',
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
             'FR-MA',
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
             'FR-SN',
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
             'FR-CH',
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
             'FR-SY',
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
             'FR-TN',
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
             'JA-JP',
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
             'DA-DK',
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
             'DA-GL',
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
             'ES-AR',
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
             'ES-BO',
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
             'ES-CL',
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
             'ES-CO',
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
             'ES-CR',
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
             'ES-CU',
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
             'ES-DO',
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
             'ES-EC',
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
             'ES-SV',
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
             'ES-GT',
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
             'ES-HN',
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
             'ES-MX',
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
             'ES-NI',
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
             'ES-PA',
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
             'ES-PY',
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
             'ES-PE',
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
             'ES-PH',
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
             'ES-PR',
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
             'ES-ES',
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
             'ES-US',
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
             'ES-UY',
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
             'ES-VE',
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
             'IT-IT',
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
             'IT-CH',
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
             'NL-BE',
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
             'NL-NL',
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
             'NO-NO',
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
             'NN-NO',
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
             'PT-BR',
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
             'PT-PT',
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
             'FI-FI',
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
             'SV-FI',
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
             'SV-SE',
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
             'CS-CZ',
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
             'HU-HU',
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
             'PL-PL',
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
             'RO-MD',
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
             'RO-RO',
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
             'HR-HR',
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
             'SK-SK',
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
             'SL-SI',
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
             'EL-GR',
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
             'BG-BG',
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
             'RU-BY',
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
             'RU-KZ',
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
             'RU-KG',
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
             'RU-MD',
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
             'RU-RU',
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
             'RU-UA',
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
             'TR-TR',
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
             'ET-EE',
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
             'LV-LV',
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
             'LT-LT',
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
             'ZH-TW',
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
             'KO-KP',
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
             'KO-KR',
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
             'ZH-CN',
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
             'AR-DZ',
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
             'AR-BH',
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
             'AR-EG',
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
             'AR-ER',
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
             'AR-IQ',
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
             'AR-IL',
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
             'AR-JO',
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
             'AR-KW',
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
             'AR-LB',
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
             'AR-LY',
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
             'AR-MA',
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
             'AR-OM',
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
             'AR-QA',
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
             'AR-SA',
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
             'AR-SO',
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
             'AR-SY',
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
             'AR-TN',
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
             'AR-AE',
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
             'AR-YE',
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
             'TH-TH',
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
             'HI-IS',
             jsonb_build_object('date_format', 'DMY',
                                'date_first', 1,
                                'months_names', jsonb_build_array('محرم', 'صفر', 'ربيع الاول', 'ربيع الثاني', 'جمادى الاولى', 'جمادى الثانية', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'),
                                'months_shortnames', jsonb_build_array('محرم', 'صفر', 'ربيع الاول', 'ربيع الثاني', 'جمادى الاولى', 'جمادى الثانية', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'),
                                'months_extranames', jsonb_build_array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'),
                                'months_extrashortnames', jsonb_build_array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'),
                                'days_names', jsonb_build_array('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
                                'days_shortnames', jsonb_build_array('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')));
-- 11 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_function_helpers.sql" 1



CREATE OR REPLACE FUNCTION sys.babelfish_get_last_identity()
RETURNS INT8
AS 'babelfishpg_tsql', 'get_last_identity'
LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.bbf_get_current_physical_schema_name(IN schemaname TEXT)
RETURNS TEXT
AS 'babelfishpg_tsql', 'get_current_physical_schema_name'
LANGUAGE C STABLE STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_set_role(IN role_name TEXT)
RETURNS INT4
AS 'babelfishpg_tsql', 'babelfish_set_role'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_last_identity_numeric()
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_last_identity()::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.get_min_id_from_table(IN id_colname TEXT,
              IN schemaname TEXT,
              IN tablename TEXT,
              OUT result INT8)
AS
$BODY$
BEGIN
 EXECUTE FORMAT('SELECT MIN(%I) FROM %I.%I', id_colname, schemaname, tablename) INTO result;
END
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.get_max_id_from_table(IN id_colname TEXT,
              IN schemaname TEXT,
              IN tablename TEXT,
              OUT result INT8)
AS
$BODY$
BEGIN
 EXECUTE FORMAT('SELECT MAX(%I) FROM %I.%I', id_colname, schemaname, tablename) INTO result;
END
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.user_name_sysname()
RETURNS sys.SYSNAME AS
$BODY$
 SELECT COALESCE(sys.user_name(), '');
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.babelfish_get_identity_param(IN tablename TEXT, IN optionname TEXT)
RETURNS INT8
AS 'babelfishpg_tsql', 'get_identity_param'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_identity_current(IN tablename TEXT)
RETURNS INT8
AS 'babelfishpg_tsql', 'get_identity_current'
LANGUAGE C STRICT;

create or replace function sys.babelfish_get_id_by_name(object_name text)
returns bigint as
$BODY$
declare res bigint;
begin
  execute 'select x''' || substring(encode(digest(object_name, 'sha1'), 'hex'), 1, 8) || '''::bigint' into res;
  return res;
end;
$BODY$
language plpgsql returns null on null input;

create or replace function sys.babelfish_get_sequence_value(in sequence_name character varying)
returns bigint as
$BODY$
declare
  v_res bigint;
begin
  execute 'select last_value from '|| sequence_name into v_res;
  return v_res;
end;
$BODY$
language plpgsql returns null on null input;

CREATE OR REPLACE FUNCTION sys.babelfish_get_login_default_db(IN login_name TEXT)
RETURNS TEXT
AS 'babelfishpg_tsql', 'bbf_get_login_default_db'
LANGUAGE C STRICT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT,
                                                                 IN p_dateval DATE,
                                                                 IN p_style NUMERIC DEFAULT 20)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_dateval DATE;
    v_style SMALLINT;
    v_month SMALLINT;
    v_resmask VARCHAR;
    v_datatype VARCHAR;
    v_language VARCHAR;
    v_monthname VARCHAR;
    v_resstring VARCHAR;
    v_lengthexpr VARCHAR;
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR;
    v_res_datatype VARCHAR;
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATATYPE_REGEXP CONSTANT VARCHAR := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 13) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 113) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF (v_style IN (8, 24, 108)) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_dateval := CASE
                    WHEN (v_style NOT IN (130, 131)) THEN p_dateval
                    ELSE sys.babelfish_conv_greg_to_hijri(p_dateval) + 1
                 END;

    v_day := ltrim(to_char(v_dateval, 'DD'), '0');
    v_month := to_char(v_dateval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    v_resmask := CASE
                    WHEN (v_style IN (1, 22)) THEN 'MM/DD/YY'
                    WHEN (v_style = 101) THEN 'MM/DD/YYYY'
                    WHEN (v_style = 2) THEN 'YY.MM.DD'
                    WHEN (v_style = 102) THEN 'YYYY.MM.DD'
                    WHEN (v_style = 3) THEN 'DD/MM/YY'
                    WHEN (v_style = 103) THEN 'DD/MM/YYYY'
                    WHEN (v_style = 4) THEN 'DD.MM.YY'
                    WHEN (v_style = 104) THEN 'DD.MM.YYYY'
                    WHEN (v_style = 5) THEN 'DD-MM-YY'
                    WHEN (v_style = 105) THEN 'DD-MM-YYYY'
                    WHEN (v_style = 6) THEN 'DD $mnme$ YY'
                    WHEN (v_style IN (13, 106, 113)) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 7) THEN '$mnme$ DD, YY'
                    WHEN (v_style = 107) THEN '$mnme$ DD, YYYY'
                    WHEN (v_style = 10) THEN 'MM-DD-YY'
                    WHEN (v_style = 110) THEN 'MM-DD-YYYY'
                    WHEN (v_style = 11) THEN 'YY/MM/DD'
                    WHEN (v_style = 111) THEN 'YYYY/MM/DD'
                    WHEN (v_style = 12) THEN 'YYMMDD'
                    WHEN (v_style = 112) THEN 'YYYYMMDD'
                    WHEN (v_style IN (20, 21, 23, 25, 120, 121, 126, 127)) THEN 'YYYY-MM-DD'
                    WHEN (v_style = 130) THEN 'DD $mnme$ YYYY'
                    WHEN (v_style = 131) THEN format('%s/MM/YYYY', lpad(v_day, 2, ' '))
                    WHEN (v_style IN (0, 9, 100, 109)) THEN format('$mnme$ %s YYYY', lpad(v_day, 2, ' '))
                 END;

    v_resstring := to_char(v_dateval, v_resmask);
    v_resstring := replace(v_resstring, '$mnme$', v_monthname);

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('%s is not a valid style number when converting from DATE to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := format('Error converting data type DATE to %s.', trim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr,
                                     lower(v_res_datatype),
                                     v_maxlength),
                   DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT -1)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_hour VARCHAR;
    v_month SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR;
    v_language VARCHAR;
    v_datatype VARCHAR;
    v_fseconds VARCHAR;
    v_fractsep VARCHAR;
    v_monthname VARCHAR;
    v_resstring VARCHAR;
    v_lengthexpr VARCHAR;
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR;
    v_src_datatype VARCHAR;
    v_res_datatype VARCHAR;
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATATYPE_REGEXP CONSTANT VARCHAR := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR := '^(?:DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    v_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE;
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT;

        v_src_datatype := rtrim(split_part(v_src_datatype, '(', 1));

        IF (v_src_datatype <> 'DATETIME2' AND v_scale IS NOT NULL) THEN
            RAISE invalid_indicator_parameter_value;
        ELSIF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;

        v_scale := coalesce(v_scale, 7);
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (-1, 120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP) THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

        v_maxlength := CASE
                          WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                          ELSE NVARCHAR_MAX
                       END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4)
        THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    v_datetimeval := CASE
                        WHEN (v_style NOT IN (130, 131)) THEN p_datetimeval
                        ELSE sys.babelfish_conv_greg_to_hijri(p_datetimeval) + INTERVAL '1 day'
                     END;

    v_day := ltrim(to_char(v_datetimeval, 'DD'), '0');
    v_hour := ltrim(to_char(v_datetimeval, 'HH12'), '0');
    v_month := to_char(v_datetimeval, 'MM')::SMALLINT;

    v_language := CASE
                     WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                     ELSE CONVERSION_LANG
                  END;
    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_monthname := (v_lang_metadata_json -> 'months_shortnames') ->> v_month - 1;

    IF (v_src_datatype IN ('DATETIME', 'SMALLDATETIME')) THEN
        v_fseconds := sys.babelfish_round_fractseconds(to_char(v_datetimeval, 'MS'));

        IF (v_fseconds::INTEGER = 1000) THEN
            v_fseconds := '000';
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        ELSE
            v_fseconds := lpad(v_fseconds, 3, '0');
        END IF;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(v_datetimeval, 'US'), v_scale);

        IF (v_scale = 7) THEN
            v_fseconds := concat(v_fseconds, '0');
        END IF;
    END IF;

    v_fractsep := CASE v_src_datatype
                     WHEN 'DATETIME2' THEN '.'
                     ELSE ':'
                  END;

    IF ((v_style = -1 AND v_src_datatype <> 'DATETIME2') OR
        v_style IN (0, 9, 100, 109))
    THEN
        v_resmask := format('$mnme$ %s YYYY %s:MI%s',
                            lpad(v_day, 2, ' '),
                            lpad(v_hour, 2, ' '),
                            CASE
                               WHEN (v_style IN (-1, 0, 100)) THEN 'AM'
                               ELSE format(':SS:%sAM', v_fseconds)
                            END);
    ELSIF (v_style = 1) THEN
        v_resmask := 'MM/DD/YY';
    ELSIF (v_style = 101) THEN
        v_resmask := 'MM/DD/YYYY';
    ELSIF (v_style = 2) THEN
        v_resmask := 'YY.MM.DD';
    ELSIF (v_style = 102) THEN
        v_resmask := 'YYYY.MM.DD';
    ELSIF (v_style = 3) THEN
        v_resmask := 'DD/MM/YY';
    ELSIF (v_style = 103) THEN
        v_resmask := 'DD/MM/YYYY';
    ELSIF (v_style = 4) THEN
        v_resmask := 'DD.MM.YY';
    ELSIF (v_style = 104) THEN
        v_resmask := 'DD.MM.YYYY';
    ELSIF (v_style = 5) THEN
        v_resmask := 'DD-MM-YY';
    ELSIF (v_style = 105) THEN
        v_resmask := 'DD-MM-YYYY';
    ELSIF (v_style = 6) THEN
        v_resmask := 'DD $mnme$ YY';
    ELSIF (v_style = 106) THEN
        v_resmask := 'DD $mnme$ YYYY';
    ELSIF (v_style = 7) THEN
        v_resmask := '$mnme$ DD, YY';
    ELSIF (v_style = 107) THEN
        v_resmask := '$mnme$ DD, YYYY';
    ELSIF (v_style IN (8, 24, 108)) THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style = 10) THEN
        v_resmask := 'MM-DD-YY';
    ELSIF (v_style = 110) THEN
        v_resmask := 'MM-DD-YYYY';
    ELSIF (v_style = 11) THEN
        v_resmask := 'YY/MM/DD';
    ELSIF (v_style = 111) THEN
        v_resmask := 'YYYY/MM/DD';
    ELSIF (v_style = 12) THEN
        v_resmask := 'YYMMDD';
    ELSIF (v_style = 112) THEN
        v_resmask := 'YYYYMMDD';
    ELSIF (v_style IN (13, 113)) THEN
        v_resmask := format('DD $mnme$ YYYY HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (14, 114)) THEN
        v_resmask := format('HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (20, 120)) THEN
        v_resmask := 'YYYY-MM-DD HH24:MI:SS';
    ELSIF ((v_style = -1 AND v_src_datatype = 'DATETIME2') OR
           v_style IN (21, 25, 121))
    THEN
        v_resmask := format('YYYY-MM-DD HH24:MI:SS.%s', v_fseconds);
    ELSIF (v_style = 22) THEN
        v_resmask := format('MM/DD/YY %s:MI:SS AM', lpad(v_hour, 2, ' '));
    ELSIF (v_style = 23) THEN
        v_resmask := 'YYYY-MM-DD';
    ELSIF (v_style IN (126, 127)) THEN
        v_resmask := CASE v_src_datatype
                        WHEN 'SMALLDATETIME' THEN 'YYYY-MM-DDT$rem$HH24:MI:SS'
                        ELSE format('YYYY-MM-DDT$rem$HH24:MI:SS.%s', v_fseconds)
                     END;
    ELSIF (v_style IN (130, 131)) THEN
        v_resmask := concat(CASE p_style
                               WHEN 131 THEN format('%s/MM/YYYY ', lpad(v_day, 2, ' '))
                               ELSE format('%s $mnme$ YYYY ', lpad(v_day, 2, ' '))
                            END,
                            format('%s:MI:SS%s%sAM', lpad(v_hour, 2, ' '), v_fractsep, v_fseconds));
    END IF;

    v_resstring := to_char(v_datetimeval, v_resmask);
    v_resstring := replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := replace(v_resstring, '$rem$', '');

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2'' or ''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "srcdatatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := format('Invalid attributes specified for data type %s.', v_src_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('%s is not a valid style number when converting from %s to a character string.',
                                      v_style, v_src_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                      v_lengthexpr, lower(v_res_datatype), v_maxlength),
                    DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                    HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_dateval DATE)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_greg_to_hijri(extract(day from p_dateval)::NUMERIC,
                                                extract(month from p_dateval)::NUMERIC,
                                                extract(year from p_dateval)::NUMERIC);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_year NUMERIC)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day SMALLINT;
    v_month SMALLINT;
    v_year INTEGER;
    v_jdnum DOUBLE PRECISION;
    v_lnum DOUBLE PRECISION;
    v_inum DOUBLE PRECISION;
    v_nnum DOUBLE PRECISION;
    v_jnum DOUBLE PRECISION;
BEGIN
    v_day := floor(p_day)::SMALLINT;
    v_month := floor(p_month)::SMALLINT;
    v_year := floor(p_year)::INTEGER;

    IF ((sign(v_day) = -1) OR (sign(v_month) = -1) OR (sign(v_year) = -1))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_year = 0) THEN
        RAISE null_value_not_allowed;
    END IF;

    IF ((p_year > 1582) OR ((p_year = 1582) AND (p_month > 10)) OR ((p_year = 1582) AND (p_month = 10) AND (p_day > 14)))
    THEN
        v_jdnum := sys.babelfish_get_int_part((1461 * (p_year + 4800 + sys.babelfish_get_int_part((p_month - 14) / 12))) / 4) +
                   sys.babelfish_get_int_part((367 * (p_month - 2 - 12 * (sys.babelfish_get_int_part((p_month - 14) / 12)))) / 12) -
                   sys.babelfish_get_int_part((3 * (sys.babelfish_get_int_part((p_year + 4900 +
                   sys.babelfish_get_int_part((p_month - 14) / 12)) / 100))) / 4) + p_day - 32075;
    ELSE
        v_jdnum := 367 * p_year - sys.babelfish_get_int_part((7 * (p_year + 5001 +
                   sys.babelfish_get_int_part((p_month - 9) / 7))) / 4) +
                   sys.babelfish_get_int_part((275 * p_month) / 9) + p_day + 1729777;
    END IF;

    v_lnum := v_jdnum - 1948440 + 10632;
    v_nnum := sys.babelfish_get_int_part((v_lnum - 1) / 10631);
    v_lnum := v_lnum - 10631 * v_nnum + 354;
    v_jnum := (sys.babelfish_get_int_part((10985 - v_lnum) / 5316)) * (sys.babelfish_get_int_part((50 * v_lnum) / 17719)) +
              (sys.babelfish_get_int_part(v_lnum / 5670)) * (sys.babelfish_get_int_part((43 * v_lnum) / 15238));
    v_lnum := v_lnum - (sys.babelfish_get_int_part((30 - v_jnum) / 15)) * (sys.babelfish_get_int_part((17719 * v_jnum) / 50)) -
              (sys.babelfish_get_int_part(v_jnum / 16)) * (sys.babelfish_get_int_part((15238 * v_jnum) / 43)) + 29;

    v_month := sys.babelfish_get_int_part((24 * v_lnum) / 709);
    v_day := v_lnum - sys.babelfish_get_int_part((709 * v_month) / 24);
    v_year := 30 * v_nnum + v_jnum - 30;

    RETURN to_date(concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'Could not convert Gregorian to Hijri date if any part of the date is negative.',
                    DETAIL := 'Some of the supplied date parts (day, month, year) is negative.',
                    HINT := 'Change the value of the date part (day, month, year) wich was found to be negative.';

    WHEN null_value_not_allowed THEN
        RAISE USING MESSAGE := 'Could not convert Gregorian to Hijri date if year value is equal to zero.',
                    DETAIL := 'Supplied year value is equal to zero.',
                    HINT := 'Change the value of the year so that it is greater than zero.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day TEXT,
                                                                IN p_month TEXT,
                                                                IN p_year TEXT)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_greg_to_hijri(p_day::NUMERIC,
                                                p_month::NUMERIC,
                                                p_year::NUMERIC);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_greg_to_hijri(extract(day from p_datetimeval)::SMALLINT,
                                                         extract(month from p_datetimeval)::SMALLINT,
                                                         extract(year from p_datetimeval)::INTEGER);

    RETURN to_timestamp(format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_dateval DATE)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_hijri_to_greg(extract(day from p_dateval)::NUMERIC,
                                                extract(month from p_dateval)::NUMERIC,
                                                extract(year from p_dateval)::NUMERIC);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_year NUMERIC)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day SMALLINT;
    v_month SMALLINT;
    v_year INTEGER;
    v_err_message VARCHAR;
    v_jdnum DOUBLE PRECISION;
    v_lnum DOUBLE PRECISION;
    v_inum DOUBLE PRECISION;
    v_nnum DOUBLE PRECISION;
    v_jnum DOUBLE PRECISION;
    v_knum DOUBLE PRECISION;
BEGIN
    v_day := floor(p_day)::SMALLINT;
    v_month := floor(p_month)::SMALLINT;
    v_year := floor(p_year)::INTEGER;

    IF ((sign(v_day) = -1) OR (sign(v_month) = -1) OR (sign(v_year) = -1))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_year = 0) THEN
        RAISE null_value_not_allowed;
    END IF;

    v_jdnum = sys.babelfish_get_int_part((11 * v_year + 3) / 30) + 354 * v_year + 30 * v_month -
              sys.babelfish_get_int_part((v_month - 1) / 2) + v_day + 1948440 - 385;

    IF (v_jdnum > 2299160)
    THEN
        v_lnum := v_jdnum + 68569;
        v_nnum := sys.babelfish_get_int_part((4 * v_lnum) / 146097);
        v_lnum := v_lnum - sys.babelfish_get_int_part((146097 * v_nnum + 3) / 4);
        v_inum := sys.babelfish_get_int_part((4000 * (v_lnum + 1)) / 1461001);
        v_lnum := v_lnum - sys.babelfish_get_int_part((1461 * v_inum) / 4) + 31;
        v_jnum := sys.babelfish_get_int_part((80 * v_lnum) / 2447);
        v_day := v_lnum - sys.babelfish_get_int_part((2447 * v_jnum) / 80);
        v_lnum := sys.babelfish_get_int_part(v_jnum / 11);
        v_month := v_jnum + 2 - 12 * v_lnum;
        v_year := 100 * (v_nnum - 49) + v_inum + v_lnum;
    ELSE
        v_jnum := v_jdnum + 1402;
        v_knum := sys.babelfish_get_int_part((v_jnum - 1) / 1461);
        v_lnum := v_jnum - 1461 * v_knum;
        v_nnum := sys.babelfish_get_int_part((v_lnum - 1) / 365) - sys.babelfish_get_int_part(v_lnum / 1461);
        v_inum := v_lnum - 365 * v_nnum + 30;
        v_jnum := sys.babelfish_get_int_part((80 * v_inum) / 2447);
        v_day := v_inum-sys.babelfish_get_int_part((2447 * v_jnum) / 80);
        v_inum := sys.babelfish_get_int_part(v_jnum / 11);
        v_month := v_jnum + 2 - 12 * v_inum;
        v_year := 4 * v_knum + v_nnum + v_inum - 4716;
    END IF;

    RETURN to_date(concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'Could not convert Hijri to Gregorian date if any part of the date is negative.',
                    DETAIL := 'Some of the supplied date parts (day, month, year) is negative.',
                    HINT := 'Change the value of the date part (day, month, year) wich was found to be negative.';

    WHEN null_value_not_allowed THEN
        RAISE USING MESSAGE := 'Could not convert Hijri to Gregorian date if year value is equal to zero.',
                    DETAIL := 'Supplied year value is equal to zero.',
                    HINT := 'Change the value of the year so that it is greater than zero.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day TEXT,
                                                                IN p_month TEXT,
                                                                IN p_year TEXT)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_hijri_to_greg(p_day::NUMERIC,
                                                p_month::NUMERIC,
                                                p_year::NUMERIC);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hijri_date DATE;
BEGIN
    v_hijri_date := sys.babelfish_conv_hijri_to_greg(extract(day from p_dateval)::NUMERIC,
                                                         extract(month from p_dateval)::NUMERIC,
                                                         extract(year from p_dateval)::NUMERIC);

    RETURN to_timestamp(format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
                                        to_char(p_datetimeval, ' HH24:MI:SS.US')),
                        'DD.MM.YYYY HH24:MI:SS.US');
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_date(IN p_datestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_year VARCHAR;
    v_month VARCHAR;
    v_hijridate DATE;
    v_style SMALLINT;
    v_leftpart VARCHAR;
    v_middlepart VARCHAR;
    v_rightpart VARCHAR;
    v_fractsecs VARCHAR;
    v_datestring VARCHAR;
    v_err_message VARCHAR;
    v_date_format VARCHAR;
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR;
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATE_FORMAT CONSTANT VARCHAR := '';
    DAYMM_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR := '\s*\d{1,9}';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP,
                                                    ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_DOTPART_REGEXP CONSTANT VARCHAR := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP,
                                                       ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR := concat('^', HHMMSSFS_PART_REGEXP, '$');
    HHMMSSFS_DOT_REGEXP CONSTANT VARCHAR := concat('^', HHMMSSFS_DOTPART_REGEXP, '$');
    v_defmask1_regexp VARCHAR := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    v_defmask2_regexp VARCHAR := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    v_defmask3_regexp VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    v_defmask4_regexp VARCHAR := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    v_defmask5_regexp VARCHAR := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask6_regexp VARCHAR := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    v_defmask7_regexp VARCHAR := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s*\,\s*', COMPYEAR_REGEXP, '$');
    v_defmask8_regexp VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask9_regexp VARCHAR := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    v_defmask10_regexp VARCHAR := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*($comp_month$)\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    DOT_SHORTYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', SHORTYEAR_REGEXP, '$');
    DOT_FULLYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '$');
    SLASH_SHORTYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', SHORTYEAR_REGEXP, '$');
    SLASH_FULLYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', FULLYEAR_REGEXP, '$');
    DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', SHORTYEAR_REGEXP, '$');
    DASH_FULLYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '$');
    DOT_SLASH_DASH_YEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    YEAR_DOTMASK_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    YEAR_SLASHMASK_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '$');
    YEAR_DASHMASK_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    YEAR_DOT_SLASH_DASH_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '$');
    DIGITMASK1_REGEXP CONSTANT VARCHAR := '^\d{6}$';
    DIGITMASK2_REGEXP CONSTANT VARCHAR := '^\d{8}$';
BEGIN
    v_style := floor(p_style)::SMALLINT;
    v_datestring := trim(p_datestring);

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    IF (v_datestring ~* HHMMSSFS_PART_REGEXP AND v_datestring !~* HHMMSSFS_REGEXP)
    THEN
        v_datestring := trim(regexp_replace(v_datestring, HHMMSSFS_PART_REGEXP, '', 'gi'));
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_character_value_for_cast;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    v_defmask1_regexp := replace(v_defmask1_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask2_regexp := replace(v_defmask2_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask3_regexp := replace(v_defmask3_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask4_regexp := replace(v_defmask4_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask5_regexp := replace(v_defmask5_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask6_regexp := replace(v_defmask6_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask7_regexp := replace(v_defmask7_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask8_regexp := replace(v_defmask8_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask9_regexp := replace(v_defmask9_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask10_regexp := replace(v_defmask10_regexp, '$comp_month$', v_compmonth_regexp);

    IF (v_datestring ~* v_defmask1_regexp OR
        v_datestring ~* v_defmask2_regexp OR
        v_datestring ~* v_defmask3_regexp OR
        v_datestring ~* v_defmask4_regexp OR
        v_datestring ~* v_defmask5_regexp OR
        v_datestring ~* v_defmask6_regexp OR
        v_datestring ~* v_defmask7_regexp OR
        v_datestring ~* v_defmask8_regexp OR
        v_datestring ~* v_defmask9_regexp OR
        v_datestring ~* v_defmask10_regexp)
    THEN
        IF (v_style IN (130, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* v_defmask1_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask1_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask2_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask2_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask3_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask3_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask4_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask4_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask5_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* v_defmask6_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask6_regexp, 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* v_defmask7_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask7_regexp, 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* v_defmask8_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask8_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* v_defmask9_regexp)
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask9_regexp, 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];
        ELSE
            v_regmatch_groups := regexp_matches(v_datestring, v_defmask10_regexp, 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSEIF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* DOT_FULLYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_FULLYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_FULLYEAR_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (20, 21, 23, 25, 102, 111, 120, 121, 126, 127)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_YEAR_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SHORTYEAR_REGEXP OR
            v_datestring ~* SLASH_SHORTYEAR_REGEXP OR
            v_datestring ~* DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22) AND v_date_format <> 'MDY') OR
                ((v_style IS NULL OR v_style IN (0, 1, 10, 22)) AND v_date_format NOT IN ('YDM', 'YMD', 'DMY', 'DYM', 'MYD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   ((v_style IS NULL OR v_style IN (0, 2, 11)) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   ((v_style IS NULL OR v_style IN (0, 3, 4, 5)) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day := v_leftpart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM') THEN
                RAISE character_not_in_repertoire;
            ELSIF (v_style IN (101, 103, 104, 105, 110, 131)) THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_year := v_rightpart;

            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (101, 110) AND v_date_format IN ('YDM', 'DMY', 'DYM')) OR
                       ((v_style IS NULL OR v_style IN (0, 101, 110)) AND v_date_format NOT IN ('YDM', 'DMY', 'DYM')))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22) AND v_date_format <> 'YDM') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22)) AND v_date_format = 'YDM'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 131) AND v_date_format <> 'DMY') OR
                    ((v_style IS NULL OR v_style IN (0, 103, 104, 105, 131)) AND v_date_format = 'DMY'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSIF ((v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 110) AND v_date_format = 'DMY') OR
                       ((v_style IS NULL OR v_style IN (0, 1, 2, 3, 4, 5, 10, 11, 22, 101, 110)) AND v_date_format <> 'DMY'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datestring ~* YEAR_DOTMASK_REGEXP OR
           v_datestring ~* YEAR_SLASHMASK_REGEXP OR
           v_datestring ~* YEAR_DASHMASK_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130)) THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, YEAR_DOT_SLASH_DASH_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

    ELSIF (v_datestring ~* DIGITMASK1_REGEXP OR
           v_datestring ~* DIGITMASK2_REGEXP)
    THEN
        IF (v_datestring ~* DIGITMASK1_REGEXP)
        THEN
            v_day := substring(v_datestring, 5, 2);
            v_month := substring(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substring(v_datestring, 1, 2));
        ELSE
            v_day := substring(v_datestring, 7, 2);
            v_month := substring(v_datestring, 5, 2);
            v_year := substring(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datestring ~* HHMMSSFS_REGEXP)
    THEN
        v_fractsecs := coalesce(sys.babelfish_get_timeunit_from_string(v_datestring, 'FRACTSECONDS'), '');
        IF (v_datestring !~* HHMMSSFS_DOT_REGEXP AND char_length(v_fractsecs) > 3) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datestring ~* HHMMSSFS_REGEXP OR v_datestring ~* DIGITMASK1_REGEXP OR v_datestring ~* DIGITMASK2_REGEXP) AND v_style IN (130, 131)) OR
        ((v_datestring ~* DOT_FULLYEAR_REGEXP OR v_datestring ~* SLASH_FULLYEAR_REGEXP OR v_datestring ~* DASH_FULLYEAR_REGEXP) AND v_style = 131))
    THEN
        IF ((v_day::SMALLINT NOT BETWEEN 1 AND 29) OR
            (v_month::SMALLINT NOT BETWEEN 1 AND 12))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_datestring := to_char(v_hijridate, 'DD.MM.YYYY');

        v_day := split_part(v_datestring, '.', 1);
        v_month := split_part(v_datestring, '.', 2);
        v_year := split_part(v_datestring, '.', 3);
    END IF;

    RETURN to_date(concat_ws('.', v_day, v_month, v_year), 'DD.MM.YYYY');
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 2 of conv_string_to_date function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to DATE.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_year VARCHAR;
    v_month VARCHAR;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR;
    v_hijridate DATE;
    v_minutes VARCHAR;
    v_seconds VARCHAR;
    v_fseconds VARCHAR;
    v_datatype VARCHAR;
    v_timepart VARCHAR;
    v_leftpart VARCHAR;
    v_middlepart VARCHAR;
    v_rightpart VARCHAR;
    v_datestring VARCHAR;
    v_err_message VARCHAR;
    v_date_format VARCHAR;
    v_res_datatype VARCHAR;
    v_datetimestring VARCHAR;
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR;
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATE_FORMAT CONSTANT VARCHAR := '';
    DAYMM_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{6}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{8}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))) AND
             v_res_datatype = 'DATETIME2')
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_timepart := trim(substring(v_datetimestring, HHMMSSFS_PART_REGEXP));
    v_datestring := trim(regexp_replace(v_datetimestring, HHMMSSFS_PART_REGEXP, '', 'gi'));

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(CONVERSION_LANG);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    IF (v_datetimestring ~* replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF ((v_style IN (127, 130, 131) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
            (v_style IN (130, 131) AND v_res_datatype = 'DATETIME2'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF ((v_datestring ~* replace(DEFMASK1_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK2_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK3_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK4_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK5_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK6_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK7_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11, 12) AND v_res_datatype = 'DATETIME2'))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10) AND v_date_format <> 'MDY' AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                (v_style IN (0, 1, 10, 22) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                (v_style IN (1, 10, 22) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YMD', 'YDM') AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11) AND v_date_format <> 'YMD') OR
                   (v_style IN (0, 2, 11) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5) AND v_date_format <> 'DMY') OR
                   (v_style IN (0, 3, 4, 5) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF (v_style = 0 AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF (v_style = 0 AND v_date_format = 'YDM')
            THEN
                IF (v_res_datatype = 'DATETIME2') THEN
                    RAISE character_not_in_repertoire;
                END IF;

                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            ELSE
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
                v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME') THEN
                RAISE invalid_character_value_for_cast;
            END IF;

            v_year := v_rightpart;
            IF (v_leftpart::SMALLINT <= 12)
            THEN
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;

                ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
                       (v_style IN (101, 110) AND v_date_format IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2') OR
                       (v_style IN (0, 101, 110) AND v_date_format NOT IN ('DMY', 'DYM', 'MYD', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_middlepart;
                    v_month := v_leftpart;
                END IF;
            ELSE
                IF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    (v_style IN (0, 103, 104, 105, 130, 131) AND ((v_date_format = 'DMY' AND v_res_datatype = 'DATETIME2') OR
                    (v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2'))) OR
                    (v_style IN (103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype = 'DATETIME2'))
                THEN
                    v_day := v_leftpart;
                    v_month := v_middlepart;
                ELSE
                    IF (v_res_datatype = 'DATETIME2') THEN
                        RAISE invalid_datetime_format;
                    END IF;

                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131) AND
            v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT <= 12) OR v_res_datatype = 'DATETIME2')
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM') AND v_res_datatype <> 'DATETIME2') OR
                (v_style IN (0, 20, 21, 23, 25, 101, 102, 110, 111, 120, 121, 126, 127) AND v_res_datatype = 'DATETIME2'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                    v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM'))
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
            END IF;
        ELSIF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME') AND v_rightpart::SMALLINT > 12)
        THEN
            IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format IN ('DMY', 'DYM', 'YDM')) OR
                (v_style IN (0, 20, 21, 101, 102, 110, 111, 120, 121) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (103, 104, 105, 130, 131) AND v_date_format NOT IN ('DMY', 'DYM', 'YDM')) OR
                   (v_style IN (0, 103, 104, 105, 130, 131) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_res_datatype <> 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{6}$')
        THEN
            v_day := substr(v_datestring, 5, 2);
            v_month := substr(v_datestring, 3, 2);
            v_year := sys.babelfish_get_full_year(substr(v_datestring, 1, 2));

        ELSIF (v_datestring ~* '^\d{8}$')
        THEN
            v_day := substr(v_datestring, 7, 2);
            v_month := substr(v_datestring, 5, 2);
            v_year := substr(v_datestring, 1, 4);
        END IF;
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (((v_datetimestring ~* HHMMSSFS_PART_REGEXP AND v_res_datatype = 'DATETIME2') OR
        (v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP OR
          v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP OR v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR1_0_REGEXP)) AND
        v_style IN (130, 131))
    THEN
        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
    v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
    v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
    v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

    IF ((v_res_datatype IN ('DATETIME', 'SMALLDATETIME') OR
         (v_res_datatype = 'DATETIME2' AND v_timepart !~* HHMMSSFS_DOT_PART_REGEXP)) AND
        char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        IF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                                 v_hours, v_minutes, v_seconds,
                                                                 rpad(v_fseconds, 3, '0'));
            IF (v_res_datatype = 'SMALLDATETIME' AND
                to_char(v_resdatetime, 'SS') <> '00')
            THEN
                IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
                    v_resdatetime := v_resdatetime + INTERVAL '1 minute';
                END IF;

                v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSIF (v_res_datatype = 'DATETIME2')
        THEN
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);

            v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN datetime_field_overflow THEN
            RAISE invalid_datetime_format;
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_character_value_for_cast;
        END IF;
    END;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_datetime function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to %s.', v_style, v_res_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to SMALLDATETIME data type.'
                                  ELSE 'Conversion failed when converting date and time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a VARCHAR data type to a DATETIME data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'The YDM date format isn''t supported when converting from this string format to date and time.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT,
                                                                 IN p_timestring TEXT,
                                                                 IN p_style NUMERIC DEFAULT 0)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_hours SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_daypart VARCHAR;
    v_seconds VARCHAR;
    v_minutes SMALLINT;
    v_fseconds VARCHAR;
    v_datatype VARCHAR;
    v_timestring VARCHAR;
    v_err_message VARCHAR;
    v_src_datatype VARCHAR;
    v_timeunit_mask VARCHAR;
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '$');
    DATATYPE_REGEXP CONSTANT VARCHAR := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
BEGIN
    v_datatype := trim(regexp_replace(p_datatype, 'DATETIME', 'TIME', 'gi'));
    v_timestring := upper(trim(p_timestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_src_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_src_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    v_daypart := substring(v_timestring, 'AM|PM');
    v_timestring := trim(regexp_replace(v_timestring, coalesce(v_daypart, ''), ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timestring ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timestring ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timestring ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timestring ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timestring ~* HH_REGEXP) THEN HH_REGEXP
        END;

    IF (v_timeunit_mask IS NULL) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_regmatch_groups := regexp_matches(v_timestring, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1]::SMALLINT;
    v_minutes := v_regmatch_groups[2]::SMALLINT;

    IF (v_timestring ~* HHMMFS_REGEXP) THEN
        v_fseconds := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fseconds := v_regmatch_groups[4];
    END IF;

   IF (v_daypart IS NOT NULL) THEN
      IF ((v_daypart = 'AM' AND v_hours NOT BETWEEN 0 AND 12) OR
          (v_daypart = 'PM' AND v_hours NOT BETWEEN 1 AND 23))
      THEN
          RAISE numeric_value_out_of_range;
      ELSIF (v_daypart = 'PM' AND v_hours < 12) THEN
          v_hours := v_hours + 12;
      ELSIF (v_daypart = 'AM' AND v_hours = 12) THEN
          v_hours := v_hours - 12;
      END IF;
   END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(v_fseconds, v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    RETURN make_time(v_hours, v_minutes, v_seconds::NUMERIC);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 3 of conv_string_to_time function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT,
                                                                 IN p_src_datatype TEXT,
                                                                 IN p_timeval TIME(6) WITHOUT TIME ZONE,
                                                                 IN p_style NUMERIC DEFAULT 25)
RETURNS TEXT
AS
$BODY$
DECLARE
    v_hours VARCHAR;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR;
    v_fseconds VARCHAR;
    v_datatype VARCHAR;
    v_resstring VARCHAR;
    v_lengthexpr VARCHAR;
    v_res_length SMALLINT;
    v_res_datatype VARCHAR;
    v_src_datatype VARCHAR;
    v_res_maxlength SMALLINT;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    -- We use the regex below to make sure input p_datatype is one of them
    DATATYPE_REGEXP CONSTANT VARCHAR := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    -- We use the regex below to get the length of the datatype, if specified
    -- For example, to get the '10' out of 'varchar(10)'
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR := '^\s*(?:TIME)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?\s*$';
BEGIN
    v_datatype := upper(trim(p_datatype));
    v_src_datatype := upper(trim(p_src_datatype));
    v_style := floor(p_style)::SMALLINT;

    IF (v_src_datatype ~* SRCDATATYPE_MASK_REGEXP)
    THEN
        v_scale := coalesce(substring(v_src_datatype, SRCDATATYPE_MASK_REGEXP)::SMALLINT, 7);

        IF (v_scale NOT BETWEEN 0 AND 7) THEN
            RAISE invalid_regular_expression;
        END IF;
    ELSE
        RAISE most_specific_type_mismatch;
    END IF;

    IF (v_datatype ~* DATATYPE_MASK_REGEXP)
    THEN
        v_res_datatype := rtrim(split_part(v_datatype, '(', 1));

        v_res_maxlength := CASE
                              WHEN (v_res_datatype IN ('CHAR', 'VARCHAR')) THEN VARCHAR_MAX
                              ELSE NVARCHAR_MAX
                           END;

        v_lengthexpr := substring(v_datatype, DATATYPE_MASK_REGEXP);

        IF (v_lengthexpr <> 'MAX' AND char_length(v_lengthexpr) > 4) THEN
            RAISE interval_field_overflow;
        END IF;

        v_res_length := CASE v_lengthexpr
                           WHEN 'MAX' THEN v_res_maxlength
                           ELSE v_lengthexpr::SMALLINT
                        END;
    ELSIF (v_datatype ~* DATATYPE_REGEXP) THEN
        v_res_datatype := v_datatype;
    ELSE
        RAISE datatype_mismatch;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE escape_character_conflict;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
                (v_style BETWEEN 20 AND 25) OR
                (v_style BETWEEN 100 AND 114) OR
                v_style IN (120, 121, 126, 127, 130, 131)))
    THEN
        RAISE invalid_parameter_value;
    ELSIF ((v_style BETWEEN 1 AND 7) OR
           (v_style BETWEEN 10 AND 12) OR
           (v_style BETWEEN 101 AND 107) OR
           (v_style BETWEEN 110 AND 112) OR
           v_style = 23)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_hours := ltrim(to_char(p_timeval, 'HH12'), '0');
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(to_char(p_timeval, 'US'), v_scale);

    IF (v_scale = 7) THEN
        v_fseconds := concat(v_fseconds, '0');
    END IF;

    IF (v_style IN (0, 100))
    THEN
        v_resmask := concat(v_hours, ':MIAM');
    ELSIF (v_style IN (8, 20, 24, 108, 120))
    THEN
        v_resmask := 'HH24:MI:SS';
    ELSIF (v_style IN (9, 109))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(v_hours, ':MI:SSAM')
                        ELSE format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
        v_resmask := format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
                     END;
    END IF;

    v_resstring := to_char(p_timeval, v_resmask);

    v_resstring := substring(v_resstring, 1, coalesce(v_res_length, char_length(v_resstring)));
    v_res_length := coalesce(v_res_length,
                             CASE v_res_datatype
                                WHEN 'CHAR' THEN 30
                                ELSE 60
                             END);
    RETURN CASE
              WHEN (v_res_datatype NOT IN ('CHAR', 'NCHAR')) THEN v_resstring
              ELSE rpad(v_resstring, v_res_length, ' ')
           END;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "src_datatype" parameter value during conversion process.',
                    HINT := 'Change "src_datatype" parameter to the proper value and try again.';

   WHEN invalid_regular_expression THEN
       RAISE USING MESSAGE := format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr, lower(v_res_datatype), v_res_maxlength),
                   DETAIL := 'Use of incorrect size value of target data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('%s is not a valid style number when converting from TIME to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := format('Error converting data type TIME to %s.',
                                      rtrim(split_part(trim(p_datatype), '(', 1))),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

create or replace function sys.babelfish_dbts()
returns bigint as
$BODY$
declare
  v_res bigint;
begin
  SELECT last_value INTO v_res FROM sys_data.inc_seq_rowversion;
  return v_res;
end;
$BODY$
language plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_full_year(IN p_short_year TEXT,
                                                           IN p_base_century TEXT DEFAULT '',
                                                           IN p_year_cutoff NUMERIC DEFAULT 49)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_full_year SMALLINT;
    v_short_year SMALLINT;
    v_base_century SMALLINT;
    v_result_param_set JSONB;
    v_full_year_res_jsonb JSONB;
BEGIN
    v_short_year := p_short_year::SMALLINT;

    BEGIN
        v_full_year_res_jsonb := nullif(current_setting('sys.full_year_res_json'), '')::JSONB;
    EXCEPTION
        WHEN undefined_object THEN
        v_full_year_res_jsonb := NULL;
    END;

    SELECT result
      INTO v_full_year
      FROM jsonb_to_recordset(v_full_year_res_jsonb) AS result_set (param1 SMALLINT,
                                                                    param2 TEXT,
                                                                    param3 NUMERIC,
                                                                    result VARCHAR)
     WHERE param1 = v_short_year
       AND param2 = p_base_century
       AND param3 = p_year_cutoff;

    IF (v_full_year IS NULL)
    THEN
        IF (v_short_year <= 99)
        THEN
            v_base_century := CASE
                                 WHEN (p_base_century ~ '^\s*([1-9]{1,2})\s*$') THEN concat(trim(p_base_century), '00')::SMALLINT
                                 ELSE trunc(extract(year from current_date)::NUMERIC, -2)
                              END;

            v_full_year = v_base_century + v_short_year;
            v_full_year = CASE
                             WHEN (v_short_year > p_year_cutoff) THEN v_full_year - 100
                             ELSE v_full_year
                          END;
        ELSE v_full_year := v_short_year;
        END IF;

        v_result_param_set := jsonb_build_object('param1', v_short_year,
                                                 'param2', p_base_century,
                                                 'param3', p_year_cutoff,
                                                 'result', v_full_year);
        v_full_year_res_jsonb := CASE
                                    WHEN (v_full_year_res_jsonb IS NULL) THEN jsonb_build_array(v_result_param_set)
                                    ELSE v_full_year_res_jsonb || v_result_param_set
                                 END;

        PERFORM set_config('sys.full_year_res_json',
                           v_full_year_res_jsonb::TEXT,
                           FALSE);
    END IF;

    RETURN v_full_year;
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_int_part(IN p_srcnumber DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS
$BODY$
BEGIN
    RETURN CASE
              WHEN (p_srcnumber < -0.0000001) THEN ceil(p_srcnumber - 0.0000001)
              ELSE floor(p_srcnumber + 0.0000001)
           END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_jobs ()
RETURNS table( job integer, what text, search_path varchar )
AS
$body$
DECLARE
  var_job integer;
  var_what text;
  var_search_path varchar;
BEGIN

  SELECT js.job_step_id, js.command, ''
    FROM sys.sysjobschedules s
   INNER JOIN sys.sysjobs j on j.job_id = s.job_id
   INNER JOIN sys.sysjobsteps js ON js.job_id = j.job_id
    INTO var_job, var_what, var_search_path
   WHERE (s.next_run_date + s.next_run_time) <= now()::timestamp
     AND j.enabled = 1
   ORDER BY (s.next_run_date + s.next_run_time) ASC
   LIMIT 1;

  IF var_job > 0
  THEN
    return query select var_job, var_what, var_search_path;
  END IF;

END;
$body$
LANGUAGE 'plpgsql';
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
            IF (v_lang_spec_culture IN ('AR', 'FI') OR
                v_lang_spec_culture ~ '-')
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

        v_lang_spec_culture := upper(regexp_replace(v_lang_spec_culture, '_|,\s*', '-', 'gi'));

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
                    v_lang_spec_culture := 'EN-US';

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

CREATE OR REPLACE FUNCTION sys.babelfish_get_microsecs_from_fractsecs(IN p_fractsecs TEXT,
                                                                          IN p_scale NUMERIC DEFAULT 7)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_scale SMALLINT;
    v_decplaces INTEGER;
    v_fractsecs VARCHAR;
    v_pureplaces VARCHAR;
    v_rnd_fractsecs INTEGER;
    v_fractsecs_len INTEGER;
    v_pureplaces_len INTEGER;
    v_err_message VARCHAR;
BEGIN
    v_fractsecs := trim(p_fractsecs);
    v_fractsecs_len := char_length(v_fractsecs);
    v_scale := floor(p_scale)::SMALLINT;

    IF (v_fractsecs_len < 7) THEN
        v_fractsecs := rpad(v_fractsecs, 7, '0');
        v_fractsecs_len := char_length(v_fractsecs);
    END IF;

    v_pureplaces := trim(leading '0' from v_fractsecs);
    v_pureplaces_len := char_length(v_pureplaces);

    v_decplaces := v_fractsecs_len - v_pureplaces_len;

    v_rnd_fractsecs := round(v_fractsecs::INTEGER, (v_pureplaces_len - (v_scale - (v_fractsecs_len - v_pureplaces_len))) * (-1));

    v_fractsecs := concat(replace(rpad('', v_decplaces), ' ', '0'), v_rnd_fractsecs);

    RETURN substring(v_fractsecs, 1, CASE
                                        WHEN (v_scale >= 7) THEN 6
                                        ELSE v_scale
                                     END);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_monthnum_by_name(IN p_monthname TEXT,
                                                                  IN p_lang_metadata_json JSONB)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_monthname TEXT;
    v_monthnum SMALLINT;
BEGIN
    v_monthname := lower(trim(p_monthname));

    v_monthnum := array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_shortnames'))), v_monthname);

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_names'))), v_monthname));

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_extrashortnames'))), v_monthname));

    v_monthnum := coalesce(v_monthnum,
                           array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'months_extranames'))), v_monthname));

    IF (v_monthnum IS NULL) THEN
        RAISE datetime_field_overflow;
    END IF;

    RETURN v_monthnum;
EXCEPTION
    WHEN datetime_field_overflow THEN
        RAISE USING MESSAGE := format('Can not convert value "%s" to a correct month number.',
                                      trim(p_monthname)),
                    DETAIL := 'Supplied month name is not valid.',
                    HINT := 'Correct supplied month name value and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_service_setting (
    IN p_service sys.service_settings.service%TYPE
  , IN p_setting sys.service_settings.setting%TYPE
)
RETURNS sys.service_settings.value%TYPE
AS
$BODY$
DECLARE
  settingValue sys.service_settings.value%TYPE;
BEGIN
  SELECT value
    INTO settingValue
    FROM sys.service_settings
   WHERE service = p_service
     AND setting = p_setting;

  RETURN settingValue;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_timeunit_from_string(IN p_timepart TEXT,
                                                                      IN p_timeunit TEXT)
RETURNS VARCHAR
AS
$BODY$
DECLARE
    v_hours VARCHAR;
    v_minutes VARCHAR;
    v_seconds VARCHAR;
    v_fractsecs VARCHAR;
    v_daypart VARCHAR;
    v_timepart VARCHAR;
    v_timeunit VARCHAR;
    v_err_message VARCHAR;
    v_timeunit_mask VARCHAR;
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR := concat('^', TIMEUNIT_REGEXP, '$');
BEGIN
    v_timepart := upper(trim(p_timepart));
    v_timeunit := upper(trim(p_timeunit));

    v_daypart := substring(v_timepart, 'AM|PM');
    v_timepart := trim(regexp_replace(v_timepart, coalesce(v_daypart, ''), ''));

    v_timeunit_mask :=
        CASE
           WHEN (v_timepart ~* HHMMSSFS_REGEXP) THEN HHMMSSFS_REGEXP
           WHEN (v_timepart ~* HHMMSS_REGEXP) THEN HHMMSS_REGEXP
           WHEN (v_timepart ~* HHMMFS_REGEXP) THEN HHMMFS_REGEXP
           WHEN (v_timepart ~* HHMM_REGEXP) THEN HHMM_REGEXP
           WHEN (v_timepart ~* HH_REGEXP) THEN HH_REGEXP
        END;

    v_regmatch_groups := regexp_matches(v_timepart, v_timeunit_mask, 'gi');

    v_hours := v_regmatch_groups[1];
    v_minutes := v_regmatch_groups[2];

    IF (v_timepart ~* HHMMFS_REGEXP) THEN
        v_fractsecs := v_regmatch_groups[3];
    ELSE
        v_seconds := v_regmatch_groups[3];
        v_fractsecs := v_regmatch_groups[4];
    END IF;

    IF (v_timeunit = 'HOURS' AND v_daypart IS NOT NULL)
    THEN
        IF ((v_daypart = 'AM' AND v_hours::SMALLINT NOT BETWEEN 0 AND 12) OR
            (v_daypart = 'PM' AND v_hours::SMALLINT NOT BETWEEN 1 AND 23))
        THEN
            RAISE numeric_value_out_of_range;
        ELSIF (v_daypart = 'PM' AND v_hours::SMALLINT < 12) THEN
            v_hours := (v_hours::SMALLINT + 12)::VARCHAR;
        ELSIF (v_daypart = 'AM' AND v_hours::SMALLINT = 12) THEN
            v_hours := (v_hours::SMALLINT - 12)::VARCHAR;
        END IF;
    END IF;

    RETURN CASE v_timeunit
              WHEN 'HOURS' THEN v_hours
              WHEN 'MINUTES' THEN v_minutes
              WHEN 'SECONDS' THEN v_seconds
              WHEN 'FRACTSECONDS' THEN v_fractsecs
           END;
EXCEPTION
    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := 'Could not extract correct hour value due to it''s inconsistency with AM|PM day part mark.',
                    DETAIL := 'Extracted hour value doesn''t fall in correct day part mark range: 0..12 for "AM" or 1..23 for "PM".',
                    HINT := 'Correct a hour value in the source string or remove AM|PM day part mark out of it.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_get_version(pComponentName VARCHAR(256))
  RETURNS VARCHAR(256) AS
$BODY$
DECLARE
  lComponentVersion VARCHAR(256);
BEGIN
 SELECT componentversion
   INTO lComponentVersion
   FROM sys.versions
  WHERE extpackcomponentname = pComponentName;

 RETURN lComponentVersion;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_get_weekdaynum_by_name(IN p_weekdayname TEXT,
                                                                    IN p_lang_metadata_json JSONB)
RETURNS SMALLINT
AS
$BODY$
DECLARE
    v_weekdayname TEXT;
    v_weekdaynum SMALLINT;
BEGIN
    v_weekdayname := lower(trim(p_weekdayname));

    v_weekdaynum := array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_names'))), v_weekdayname);

    v_weekdaynum := coalesce(v_weekdaynum,
                             array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_shortnames'))), v_weekdayname));

    v_weekdaynum := coalesce(v_weekdaynum,
                             array_position(ARRAY(SELECT lower(jsonb_array_elements_text(p_lang_metadata_json -> 'days_extrashortnames'))), v_weekdayname));

    IF (v_weekdaynum IS NULL) THEN
        RAISE datetime_field_overflow;
    END IF;

    RETURN v_weekdaynum;
EXCEPTION
    WHEN datetime_field_overflow THEN
        RAISE USING MESSAGE := format('Can not convert value "%s" to a correct weekday number.',
                                      trim(p_weekdayname)),
                    DETAIL := 'Supplied weekday name is not valid.',
                    HINT := 'Correct supplied weekday name value and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_is_ossp_present()
RETURNS BOOLEAN AS
$BODY$
DECLARE
    result SMALLINT;
BEGIN
 select
     case when exists
      (select 1 from pg_extension where extname = 'uuid-ossp')
       then 1
       else 0 end
     INTO result;

 RETURN (result = 1);
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_is_spatial_present()
RETURNS BOOLEAN AS
$BODY$
DECLARE
    result SMALLINT;
BEGIN
 select
     case when exists
      (select 1 from pg_extension where extname = 'postgis')
       then 1
       else 0 end
     INTO result;

 RETURN (result = 1);
END;
$BODY$
LANGUAGE plpgsql;

create or replace function sys.babelfish_istime(v text)
returns boolean
as
$body$
begin
  perform v::time;
  return true;
exception
  when others then
   return false;
end
$body$
language 'plpgsql';

-- Remove closing square brackets at both ends, otherwise do nothing.
CREATE OR REPLACE FUNCTION sys.babelfish_single_unbracket_name(IN name TEXT)
RETURNS TEXT AS
$BODY$
BEGIN
    IF length(name) >= 2 AND left(name, 1) = '[' AND right(name, 1) = ']' THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    END IF;
    RETURN name;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_openxml(IN DocHandle BIGINT)
   RETURNS TABLE (XmlData XML)
AS
$BODY$
DECLARE
   XmlDocument$data XML;
BEGIN

    SELECT t.XmlData
   INTO STRICT XmlDocument$data
   FROM sys$openxml t
  WHERE t.DocID = DocHandle;

   RETURN QUERY SELECT XmlDocument$data;

   EXCEPTION
   WHEN SQLSTATE '42P01' OR SQLSTATE 'P0002' THEN
       RAISE EXCEPTION '%','Could not find prepared statement with handle '||CASE
                                                                              WHEN DocHandle IS NULL THEN 'null'
                                                                                ELSE DocHandle::TEXT
                                                                             END;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_date(IN p_datestring TEXT,
                                                           IN p_culture TEXT DEFAULT '')
RETURNS DATE
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_year SMALLINT;
    v_month VARCHAR;
    v_res_date DATE;
    v_hijridate DATE;
    v_culture VARCHAR;
    v_dayparts TEXT[];
    v_resmask VARCHAR;
    v_raw_year VARCHAR;
    v_left_part VARCHAR;
    v_right_part VARCHAR;
    v_resmask_fi VARCHAR;
    v_datestring VARCHAR;
    v_timestring VARCHAR;
    v_correctnum VARCHAR;
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR;
    v_date_format VARCHAR;
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_seconds NUMERIC := 0;
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR;
    v_regmatch_groups TEXT[];
    v_compmonth_regexp VARCHAR;
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    DAYMM_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    ANNO_DOMINI_REGEXP VARCHAR := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATE_FORMAT CONSTANT VARCHAR := '';
BEGIN
    v_datestring := upper(trim(p_datestring));
    v_culture := coalesce(nullif(upper(trim(p_culture)), ''), 'EN-US');

    v_dayparts := ARRAY(SELECT upper(array_to_string(regexp_matches(v_datestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_datestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_datestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_datestring := replace(v_datestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_datestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_datestring := regexp_replace(v_datestring,
                                       ANNO_DOMINI_COMPREGEXP,
                                       regexp_replace(array_to_string(regexp_matches(v_datestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                      ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                       'gi');
    END IF;

    v_date_format := coalesce(nullif(upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_datestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_datestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                  CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                  AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                  '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                  CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask1_fi_regexp
                                                             ELSE v_defmask1_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_datestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                   '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                   '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                   '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask6_fi_regexp
                                                             ELSE v_defmask6_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                   '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                   '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                   AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask2_fi_regexp
                                                             ELSE v_defmask2_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_datestring ~* v_defmask4_1_regexp OR
           (v_datestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_datestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                  '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_datestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_datestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_datestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                   TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask3_fi_regexp
                                                             ELSE v_defmask3_regexp
                                                          END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                   TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                   '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_datestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                   MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                   '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                   '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask7_fi_regexp
                                                             ELSE v_defmask7_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                  MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                  TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                  '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                  TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                  '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                             WHEN 'FI' THEN v_defmask8_fi_regexp
                                                             ELSE v_defmask8_regexp
                                                          END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_datestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_datestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_datestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_resmask_fi
                                                                 ELSE v_resmask
                                                              END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
             v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), '')::NUMERIC, 0);
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    v_res_date := make_timestamp(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                 v_hours, v_minutes, v_seconds);

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (CASE date_part('dow', v_res_date)::SMALLINT
               WHEN 0 THEN 7
               ELSE date_part('dow', v_res_date)::SMALLINT
            END <> v_weekdaynum)
        THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    RETURN v_res_date;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := format('Error converting string value ''%s'' into data type DATE using culture ''%s''.',
                                      p_datestring, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_datetime(IN p_datatype TEXT,
                                                               IN p_datetimestring TEXT,
                                                               IN p_culture TEXT DEFAULT '')
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_year SMALLINT;
    v_month VARCHAR;
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR;
    v_dayparts TEXT[];
    v_resmask VARCHAR;
    v_datatype VARCHAR;
    v_raw_year VARCHAR;
    v_left_part VARCHAR;
    v_right_part VARCHAR;
    v_resmask_fi VARCHAR;
    v_timestring VARCHAR;
    v_correctnum VARCHAR;
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR;
    v_date_format VARCHAR;
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR;
    v_error_message VARCHAR;
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR;
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_datetimestring VARCHAR;
    v_seconds VARCHAR := '0';
    v_fseconds VARCHAR := '0';
    v_compmonth_regexp VARCHAR;
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_datetime TIMESTAMP(6) WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATE_FORMAT CONSTANT VARCHAR := '';
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_culture := coalesce(nullif(upper(trim(p_culture)), ''), 'EN-US');

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype <> 'DATETIME2' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    v_dayparts := ARRAY(SELECT upper(array_to_string(regexp_matches(v_datetimestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_datetimestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_datetimestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_datetimestring := replace(v_datetimestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_datetimestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_datetimestring := regexp_replace(v_datetimestring,
                                           ANNO_DOMINI_COMPREGEXP,
                                           regexp_replace(array_to_string(regexp_matches(v_datetimestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                          ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                           'gi');
    END IF;

    v_date_format := coalesce(nullif(upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_datetimestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_datetimestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                      AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask1_fi_regexp
                                                                 ELSE v_defmask1_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_datetimestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                       '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                       '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                       '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask6_fi_regexp
                                                                 ELSE v_defmask6_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                       '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                       '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                       AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask2_fi_regexp
                                                                 ELSE v_defmask2_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_datetimestring ~* v_defmask4_1_regexp OR
           (v_datetimestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_datetimestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                      '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datetimestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_datetimestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_datetimestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_datetimestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                       TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask3_fi_regexp
                                                                 ELSE v_defmask3_regexp
                                                              END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                       TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                       '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_datetimestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                       MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                       '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                       '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask7_fi_regexp
                                                                 ELSE v_defmask7_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_datetimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_datetimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_datetimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                      MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                 WHEN 'FI' THEN v_defmask8_fi_regexp
                                                                 ELSE v_defmask8_regexp
                                                              END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_datetimestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_datetimestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_datetimestring, CASE v_culture
                                                                     WHEN 'FI' THEN v_resmask_fi
                                                                     ELSE v_resmask
                                                                  END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
             v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_dayparts[1] = 'PM' AND v_hours < 12) THEN
                v_hours := v_hours + 12;
            ELSIF (v_dayparts[1] = 'AM' AND v_hours = 12) THEN
                v_hours := v_hours - 12;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), ''), '0');

            IF (v_seconds ~ '\.') THEN
                v_fseconds := split_part(v_seconds, '.', 2);
                v_seconds := split_part(v_seconds, '.', 1);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    BEGIN
        IF (v_res_datatype IN ('DATETIME', 'SMALLDATETIME'))
        THEN
            v_res_datetime := sys.datetimefromparts(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                                                  v_hours, v_minutes, v_seconds::SMALLINT,
                                                                  rpad(v_fseconds, 3, '0')::NUMERIC);
            IF (v_res_datatype = 'SMALLDATETIME' AND
                to_char(v_res_datetime, 'SS') <> '00')
            THEN
                IF (to_char(v_res_datetime, 'SS')::SMALLINT >= 30) THEN
                    v_res_datetime := v_res_datetime + INTERVAL '1 minute';
                END IF;

                v_res_datetime := to_timestamp(to_char(v_res_datetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
            END IF;
        ELSE
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(rpad(v_fseconds, 9, '0'), v_scale);
            v_seconds := concat_ws('.', v_seconds, v_fseconds);

            v_res_datetime := make_timestamp(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                             v_hours, v_minutes, v_seconds::NUMERIC);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;

        IF (v_err_message ~* 'Cannot construct data type') THEN
            RAISE invalid_datetime_format;
        END IF;
    END;

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (CASE date_part('dow', v_res_date)::SMALLINT
               WHEN 0 THEN 7
               ELSE date_part('dow', v_res_date)::SMALLINT
            END <> v_weekdaynum)
        THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    RETURN v_res_datetime;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_datetimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_to_time(IN p_datatype TEXT,
                                                           IN p_srctimestring TEXT,
                                                           IN p_culture TEXT DEFAULT '')
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_day VARCHAR;
    v_year SMALLINT;
    v_month VARCHAR;
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR;
    v_dayparts TEXT[];
    v_resmask VARCHAR;
    v_datatype VARCHAR;
    v_raw_year VARCHAR;
    v_left_part VARCHAR;
    v_right_part VARCHAR;
    v_resmask_fi VARCHAR;
    v_timestring VARCHAR;
    v_correctnum VARCHAR;
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR;
    v_date_format VARCHAR;
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_srctimestring VARCHAR;
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR;
    v_error_message VARCHAR;
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR;
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_seconds VARCHAR := '0';
    v_fseconds VARCHAR := '0';
    v_compmonth_regexp VARCHAR;
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_time TIME WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, TIMEUNIT_REGEXP, '\:', TIME_MASKSEP_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\s*\d{1,2}\.\d+(?!\d)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR :=
        concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?\.?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '(?!\d)', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, TIMEUNIT_REGEXP, '[\:\.]', TIME_MASKSEP_FI_REGEXP,
               AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '\s*\d{1,2}\.\d+(?!\d)\.?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?|',
               AMPM_REGEXP, '?');
    v_defmask1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR := '';
    DATE_FORMAT CONSTANT VARCHAR := '';
BEGIN
    v_datatype := trim(p_datatype);
    v_srctimestring := upper(trim(p_srctimestring));
    v_culture := coalesce(nullif(upper(trim(p_culture)), ''), 'EN-US');

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    v_dayparts := ARRAY(SELECT upper(array_to_string(regexp_matches(v_srctimestring, '[AP]M|ص|م', 'gi'), '')));

    IF (array_length(v_dayparts, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(coalesce(nullif(CONVERSION_LANG, ''), p_culture));
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_parameter_value;
    END;

    v_compday_regexp := array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_names')),
                                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_shortnames'))),
                                                  ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'days_extrashortnames'))), '|');

    v_weekdaynames := ARRAY(SELECT array_to_string(regexp_matches(v_srctimestring, v_compday_regexp, 'gi'), ''));

    IF (array_length(v_weekdaynames, 1) > 1) THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_weekdaynames[1] IS NOT NULL AND
        v_srctimestring ~* concat(WEEKDAYAMPM_START_REGEXP, '(', v_compday_regexp, ')', WEEKDAYAMPM_END_REGEXP))
    THEN
        v_srctimestring := replace(v_srctimestring, v_weekdaynames[1], ' ');
    END IF;

    IF (v_srctimestring ~* ANNO_DOMINI_COMPREGEXP)
    THEN
        IF (v_culture !~ 'EN[-_]US|DA[-_]DK|SV[-_]SE|EN[-_]GB|HI[-_]IS') THEN
            RAISE invalid_datetime_format;
        END IF;

        v_srctimestring := regexp_replace(v_srctimestring,
                                          ANNO_DOMINI_COMPREGEXP,
                                          regexp_replace(array_to_string(regexp_matches(v_srctimestring, ANNO_DOMINI_COMPREGEXP, 'gi'), ''),
                                                         ANNO_DOMINI_REGEXP, ' ', 'gi'),
                                          'gi');
    END IF;

    v_date_format := coalesce(nullif(upper(trim(DATE_FORMAT)), ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp :=
        array_to_string(array_cat(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))),
                                  array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extrashortnames')),
                                            ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_extranames')))
                                 ), '|');

    IF ((v_srctimestring ~* v_defmask1_regexp AND v_culture <> 'FI') OR
        (v_srctimestring ~* v_defmask1_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat(CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                     CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                     AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                     '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                     CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask1_fi_regexp
                                                                ELSE v_defmask1_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3],
                                 v_regmatch_groups[5], v_regmatch_groups[6]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[7];
        ELSE
            v_day := v_regmatch_groups[7];
            v_month := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
        ELSE
            v_year := to_char(current_date, 'YYYY')::SMALLINT;
        END IF;

    ELSIF ((v_srctimestring ~* v_defmask6_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask6_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                      '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                      '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask6_fi_regexp
                                                                ELSE v_defmask6_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[3];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[2]::SMALLINT - 543
                     ELSE v_regmatch_groups[2]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask2_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask2_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}',
                                      '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                      '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                      AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask2_fi_regexp
                                                                ELSE v_defmask2_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[2];
        v_correctnum := coalesce(v_regmatch_groups[1], v_regmatch_groups[3], v_regmatch_groups[5],
                                 v_regmatch_groups[6], v_regmatch_groups[8], v_regmatch_groups[9]);
        v_day := '01';
        v_month := v_regmatch_groups[7];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

    ELSIF (v_srctimestring ~* v_defmask4_1_regexp OR
           (v_srctimestring ~* v_defmask4_2_regexp AND v_culture !~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV') OR
           (v_srctimestring ~* v_defmask9_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask9_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat('\d+\s*\.?(?:,+|,*', AMPM_REGEXP, ')', TIME_MASKSEP_FI_REGEXP, '\.+', TIME_MASKSEP_REGEXP, '$|',
                                     '\d+\s*\.', TIME_MASKSEP_FI_REGEXP, '\.', TIME_MASKSEP_FI_REGEXP, '$') AND
            v_culture = 'FI')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_srctimestring ~* v_defmask4_0_regexp) THEN
            v_timestring := (regexp_matches(v_srctimestring, v_defmask4_0_regexp, 'gi'))[1];
        ELSE
            v_timestring := v_srctimestring;
        END IF;

        v_res_date := current_date;
        v_day := to_char(v_res_date, 'DD');
        v_month := to_char(v_res_date, 'MM');
        v_year := to_char(v_res_date, 'YYYY')::SMALLINT;

    ELSIF ((v_srctimestring ~* v_defmask3_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask3_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?',
                                      TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP, '|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask3_fi_regexp
                                                                ELSE v_defmask3_regexp
                                                             END, 'gi');
        v_timestring := v_regmatch_groups[1];
        v_day := '01';
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask5_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask5_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                      TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$|',
                                      '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, v_defmask5_regexp, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[4]::SMALLINT - 543
                     ELSE v_regmatch_groups[4]::SMALLINT
                  END;

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
        END IF;

    ELSIF ((v_srctimestring ~* v_defmask7_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask7_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA') OR
            (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                      MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{3,4}|',
                                      '\d{3,4}', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                      '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
             v_culture ~ 'DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask7_fi_regexp
                                                                ELSE v_defmask7_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);
        v_day := v_regmatch_groups[4];
        v_month := v_regmatch_groups[2];
        v_year := CASE
                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_regmatch_groups[3]::SMALLINT - 543
                     ELSE v_regmatch_groups[3]::SMALLINT
                  END;

    ELSIF ((v_srctimestring ~* v_defmask8_regexp AND v_culture <> 'FI') OR
           (v_srctimestring ~* v_defmask8_fi_regexp AND v_culture = 'FI'))
    THEN
        IF (v_srctimestring ~ concat('\s*\d{1,2}\.\s*(?:\.|\d+(?!\d)\s*\.)', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}',
                                     MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                     TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}|',
                                     '\d{1,2}', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}', MASKSEPTWO_REGEXP,
                                     TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '\d{1,2}\s*(?:\.)+|',
                                     '\d+\s*(?:\.)+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$') AND
            v_culture ~ 'FI|DE[-_]DE|NN[-_]NO|CS[-_]CZ|PL[-_]PL|RO[-_]RO|SK[-_]SK|SL[-_]SI|BG[-_]BG|RU[-_]RU|TR[-_]TR|ET[-_]EE|LV[-_]LV')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                WHEN 'FI' THEN v_defmask8_fi_regexp
                                                                ELSE v_defmask8_regexp
                                                             END, 'gi');
        v_timestring := concat(v_regmatch_groups[1], v_regmatch_groups[5]);

        IF (v_date_format = 'DMY' OR
            v_culture IN ('LV-LV', 'LV_LV'))
        THEN
            v_day := v_regmatch_groups[2];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[4];
        ELSIF (v_date_format = 'YMD')
        THEN
            v_day := v_regmatch_groups[4];
            v_month := v_regmatch_groups[3];
            v_raw_year := v_regmatch_groups[2];
        ELSE
            v_day := v_regmatch_groups[3];
            v_month := v_regmatch_groups[2];
            v_raw_year := v_regmatch_groups[4];
        END IF;

        IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
        THEN
            IF (v_day::SMALLINT > 30 OR
                v_month::SMALLINT > 12) THEN
                RAISE invalid_datetime_format;
            END IF;

            v_raw_year := sys.babelfish_get_full_year(v_raw_year, '14');
            v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

            v_day := to_char(v_hijridate, 'DD');
            v_month := to_char(v_hijridate, 'MM');
            v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;

        ELSIF (v_culture IN ('TH-TH', 'TH_TH')) THEN
            v_year := sys.babelfish_get_full_year(v_raw_year)::SMALLINT - 43;
        ELSE
            v_year := sys.babelfish_get_full_year(v_raw_year, '', 29)::SMALLINT;
        END IF;
    ELSE
        v_found := FALSE;
    END IF;

    WHILE (NOT v_found AND v_resmask_cnt < 20)
    LOOP
        v_resmask := replace(CASE v_resmask_cnt
                                WHEN 10 THEN v_defmask10_regexp
                                WHEN 11 THEN v_defmask11_regexp
                                WHEN 12 THEN v_defmask12_regexp
                                WHEN 13 THEN v_defmask13_regexp
                                WHEN 14 THEN v_defmask14_regexp
                                WHEN 15 THEN v_defmask15_regexp
                                WHEN 16 THEN v_defmask16_regexp
                                WHEN 17 THEN v_defmask17_regexp
                                WHEN 18 THEN v_defmask18_regexp
                                WHEN 19 THEN v_defmask19_regexp
                             END,
                             '$comp_month$', v_compmonth_regexp);

        v_resmask_fi := replace(CASE v_resmask_cnt
                                   WHEN 10 THEN v_defmask10_fi_regexp
                                   WHEN 11 THEN v_defmask11_fi_regexp
                                   WHEN 12 THEN v_defmask12_fi_regexp
                                   WHEN 13 THEN v_defmask13_fi_regexp
                                   WHEN 14 THEN v_defmask14_fi_regexp
                                   WHEN 15 THEN v_defmask15_fi_regexp
                                   WHEN 16 THEN v_defmask16_fi_regexp
                                   WHEN 17 THEN v_defmask17_fi_regexp
                                   WHEN 18 THEN v_defmask18_fi_regexp
                                   WHEN 19 THEN v_defmask19_fi_regexp
                                END,
                                '$comp_month$', v_compmonth_regexp);

        IF ((v_srctimestring ~* v_resmask AND v_culture <> 'FI') OR
            (v_srctimestring ~* v_resmask_fi AND v_culture = 'FI'))
        THEN
            v_found := TRUE;
            v_regmatch_groups := regexp_matches(v_srctimestring, CASE v_culture
                                                                    WHEN 'FI' THEN v_resmask_fi
                                                                    ELSE v_resmask
                                                                 END, 'gi');
            v_timestring := CASE
                               WHEN v_resmask_cnt IN (10, 11, 12, 13) THEN concat(v_regmatch_groups[1], v_regmatch_groups[4])
                               ELSE concat(v_regmatch_groups[1], v_regmatch_groups[5])
                            END;

            IF (v_resmask_cnt = 10)
            THEN
                IF (v_regmatch_groups[3] = 'MAR' AND
                    v_culture IN ('IT-IT', 'IT_IT'))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                IF (v_date_format = 'YMD' AND v_culture NOT IN ('SV-SE', 'SV_SE', 'LV-LV', 'LV_LV'))
                THEN
                    v_day := '01';
                    v_year := sys.babelfish_get_full_year(v_regmatch_groups[2], '', 29)::SMALLINT;
                ELSE
                    v_day := v_regmatch_groups[2];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := to_char(sys.babelfish_conv_greg_to_hijri(current_date + 1), 'YYYY');

            ELSIF (v_resmask_cnt = 11)
            THEN
                IF (v_date_format IN ('YMD', 'MDY') AND v_culture NOT IN ('SV-SE', 'SV_SE'))
                THEN
                    v_day := v_regmatch_groups[3];
                    v_year := to_char(current_date, 'YYYY')::SMALLINT;
                ELSE
                    v_day := '01';
                    v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_regmatch_groups[3])::SMALLINT - 43
                                 ELSE sys.babelfish_get_full_year(v_regmatch_groups[3], '', 29)::SMALLINT
                              END;
                END IF;

                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := sys.babelfish_get_full_year(substring(v_year::TEXT, 3, 2), '14');

            ELSIF (v_resmask_cnt = 12)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 13)
            THEN
                v_day := '01';
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];

            ELSIF (v_resmask_cnt IN (14, 15, 16))
            THEN
                IF (v_resmask_cnt = 14)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[3];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                ELSIF (v_resmask_cnt = 15)
                THEN
                    v_left_part := v_regmatch_groups[4];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                ELSE
                    v_left_part := v_regmatch_groups[3];
                    v_right_part := v_regmatch_groups[2];
                    v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                END IF;

                IF (char_length(v_left_part) <= 2)
                THEN
                    IF (v_date_format = 'YMD' AND v_culture NOT IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_left_part;
                        v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_right_part;
                            v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;

                    IF (v_date_format IN ('MDY', 'DMY') OR v_culture IN ('LV-LV', 'LV_LV'))
                    THEN
                        v_day := v_right_part;
                        v_raw_year := sys.babelfish_get_full_year(v_left_part, '14');
                        v_year := CASE
                                     WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_left_part)::SMALLINT - 43
                                     ELSE sys.babelfish_get_full_year(v_left_part, '', 29)::SMALLINT
                                  END;
                        BEGIN
                            v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);
                        EXCEPTION
                        WHEN OTHERS THEN
                            v_day := v_left_part;
                            v_raw_year := sys.babelfish_get_full_year(v_right_part, '14');
                            v_year := CASE
                                         WHEN v_culture IN ('TH-TH', 'TH_TH') THEN sys.babelfish_get_full_year(v_right_part)::SMALLINT - 43
                                         ELSE sys.babelfish_get_full_year(v_right_part, '', 29)::SMALLINT
                                      END;
                        END;
                    END IF;
                ELSE
                    v_day := v_right_part;
                    v_raw_year := v_left_part;
             v_year := CASE
                                 WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_left_part::SMALLINT - 543
                                 ELSE v_left_part::SMALLINT
                              END;
                END IF;

            ELSIF (v_resmask_cnt = 17)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 18)
            THEN
                v_day := v_regmatch_groups[3];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[4], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[2];

            ELSIF (v_resmask_cnt = 19)
            THEN
                v_day := v_regmatch_groups[4];
                v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
                v_raw_year := v_regmatch_groups[3];
            END IF;

            IF (v_resmask_cnt NOT IN (10, 11, 14, 15, 16))
            THEN
                v_year := CASE
                             WHEN v_culture IN ('TH-TH', 'TH_TH') THEN v_raw_year::SMALLINT - 543
                             ELSE v_raw_year::SMALLINT
                          END;
            END IF;

            IF (v_culture IN ('AR', 'AR-SA', 'AR_SA'))
            THEN
                IF (v_day::SMALLINT > 30 OR
                    (v_resmask_cnt NOT IN (10, 11, 14, 15, 16) AND v_year NOT BETWEEN 1318 AND 1501) OR
                    (v_resmask_cnt IN (14, 15, 16) AND v_raw_year::SMALLINT NOT BETWEEN 1318 AND 1501))
                THEN
                    RAISE invalid_datetime_format;
                END IF;

                v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_raw_year) - 1;

                v_day := to_char(v_hijridate, 'DD');
                v_month := to_char(v_hijridate, 'MM');
                v_year := to_char(v_hijridate, 'YYYY')::SMALLINT;
            END IF;
        END IF;

        v_resmask_cnt := v_resmask_cnt + 1;
    END LOOP;

    IF (NOT v_found) THEN
        RAISE invalid_datetime_format;
    END IF;

    v_res_date := make_date(v_year, v_month::SMALLINT, v_day::SMALLINT);

    IF (v_weekdaynames[1] IS NOT NULL) THEN
        v_weekdaynum := sys.babelfish_get_weekdaynum_by_name(v_weekdaynames[1], v_lang_metadata_json);

        IF (date_part('dow', v_res_date)::SMALLINT <> v_weekdaynum) THEN
            RAISE invalid_datetime_format;
        END IF;
    END IF;

    IF (char_length(v_timestring) > 0 AND v_timestring NOT IN ('AM', 'ص', 'PM', 'م'))
    THEN
        IF (v_culture = 'FI') THEN
            v_timestring := translate(v_timestring, '.,', ': ');

            IF (char_length(split_part(v_timestring, ':', 4)) > 0) THEN
                v_timestring := regexp_replace(v_timestring, ':(?=\s*\d+\s*:?\s*(?:[AP]M|ص|م)?\s*$)', '.');
            END IF;
        END IF;

        v_timestring := replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');

        BEGIN
            v_hours := coalesce(split_part(v_timestring, ':', 1)::SMALLINT, 0);

            IF ((v_dayparts[1] IN ('AM', 'ص') AND v_hours NOT BETWEEN 0 AND 12) OR
                (v_dayparts[1] IN ('PM', 'م') AND v_hours NOT BETWEEN 1 AND 23))
            THEN
                RAISE invalid_datetime_format;
            ELSIF (v_dayparts[1] = 'PM' AND v_hours < 12) THEN
                v_hours := v_hours + 12;
            ELSIF (v_dayparts[1] = 'AM' AND v_hours = 12) THEN
                v_hours := v_hours - 12;
            END IF;

            v_minutes := coalesce(nullif(split_part(v_timestring, ':', 2), '')::SMALLINT, 0);
            v_seconds := coalesce(nullif(split_part(v_timestring, ':', 3), ''), '0');

            IF (v_seconds ~ '\.') THEN
                v_fseconds := split_part(v_seconds, '.', 2);
                v_seconds := split_part(v_seconds, '.', 1);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
            RAISE invalid_datetime_format;
        END;
    ELSIF (v_dayparts[1] IN ('PM', 'م'))
    THEN
        v_hours := 12;
    END IF;

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs(rpad(v_fseconds, 9, '0'), v_scale);
    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    v_res_time := make_time(v_hours, v_minutes, v_seconds::NUMERIC);

    RETURN v_res_time;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN
        RAISE USING MESSAGE := format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_srctimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to SMALLINT data type.',
                                      v_err_message),
                    DETAIL := 'Supplied value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;





create or replace function sys.babelfish_ROUND3(x in numeric, y in int, z in int)returns numeric
AS
$body$
BEGIN



 if z = 0 or z is null then
  return round(x,y);
 else
  return trunc(x,y);
 end if;
END;
$body$
language plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_round_fractseconds(IN p_fractseconds NUMERIC)
RETURNS INTEGER
AS
$BODY$
DECLARE
   v_modpart INTEGER;
   v_decpart INTEGER;
   v_fractseconds INTEGER;
BEGIN
    v_fractseconds := floor(p_fractseconds)::INTEGER;
    v_modpart := v_fractseconds % 10;
    v_decpart := v_fractseconds - v_modpart;

    RETURN CASE
              WHEN (v_modpart BETWEEN 0 AND 1) THEN v_decpart
              WHEN (v_modpart BETWEEN 2 AND 4) THEN v_decpart + 3
              WHEN (v_modpart BETWEEN 5 AND 8) THEN v_decpart + 7
              ELSE v_decpart + 10 -- 9
           END;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_round_fractseconds(IN p_fractseconds TEXT)
RETURNS INTEGER
AS
$BODY$
BEGIN
    RETURN sys.babelfish_round_fractseconds(p_fractseconds::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', trim(p_fractseconds)),
                    DETAIL := 'Passed argument value contains illegal characters.',
                    HINT := 'Correct passed argument value, remove all illegal characters.';


END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_set_version(pComponentVersion VARCHAR(256),pComponentName VARCHAR(256))
  RETURNS void AS
$BODY$
DECLARE
  rowcount smallint;
BEGIN
 UPDATE sys.versions SET componentversion = pComponentVersion
  WHERE extpackcomponentname = pComponentName;
 GET DIAGNOSTICS rowcount = ROW_COUNT;

 IF rowcount < 1 THEN
  INSERT INTO sys.versions(extpackcomponentname,componentversion)
       VALUES (pComponentName,pComponentVersion);
 END IF;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_job (
  par_job_name varchar,
  par_enabled smallint = 1,
  par_description varchar = NULL::character varying,
  par_start_step_id integer = 1,
  par_category_name varchar = NULL::character varying,
  par_category_id integer = NULL::integer,
  par_owner_login_name varchar = NULL::character varying,
  par_notify_level_eventlog integer = 2,
  par_notify_level_email integer = 0,
  par_notify_level_netsend integer = 0,
  par_notify_level_page integer = 0,
  par_notify_email_operator_name varchar = NULL::character varying,
  par_notify_netsend_operator_name varchar = NULL::character varying,
  par_notify_page_operator_name varchar = NULL::character varying,
  par_delete_level integer = 0,
  inout par_job_id integer = NULL::integer,
  par_originating_server varchar = NULL::character varying,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_retval INT DEFAULT 0;
  var_notify_email_operator_id INT DEFAULT 0;
  var_notify_email_operator_name VARCHAR(128);
  var_notify_netsend_operator_id INT DEFAULT 0;
  var_notify_page_operator_id INT DEFAULT 0;
  var_owner_sid CHAR(85) ;
  var_originating_server_id INT DEFAULT 0;
BEGIN

  SELECT UPPER(LTRIM(RTRIM(par_originating_server))) INTO par_originating_server;
  SELECT LTRIM(RTRIM(par_job_name)) INTO par_job_name;
  SELECT LTRIM(RTRIM(par_description)) INTO par_description;
  SELECT '[Uncategorized (Local)]' INTO par_category_name;
  SELECT 0 INTO par_category_id;
  SELECT LTRIM(RTRIM(par_notify_email_operator_name)) INTO par_notify_email_operator_name;
  SELECT LTRIM(RTRIM(par_notify_netsend_operator_name)) INTO par_notify_netsend_operator_name;
  SELECT LTRIM(RTRIM(par_notify_page_operator_name)) INTO par_notify_page_operator_name;
  SELECT NULL INTO var_originating_server_id;
  SELECT NULL INTO par_job_id;

  IF (par_originating_server = '')
  THEN
    SELECT NULL INTO par_originating_server;
  END IF;

  IF (par_description = '')
  THEN
    SELECT NULL INTO par_description;
  END IF;

  IF (par_category_name = '')
  THEN
    SELECT NULL INTO par_category_name;
  END IF;

  IF (par_notify_email_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_email_operator_name;
  END IF;

  IF (par_notify_netsend_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_netsend_operator_name;
  END IF;

  IF (par_notify_page_operator_name = '')
  THEN
    SELECT NULL INTO par_notify_page_operator_name;
  END IF;


  SELECT t.par_owner_sid
       , t.par_notify_level_email
       , t.par_notify_level_netsend
       , t.par_notify_level_page
       , t.par_category_id
       , t.par_notify_email_operator_id
       , t.par_notify_netsend_operator_id
       , t.par_notify_page_operator_id
       , t.par_originating_server
       , t.returncode
    FROM sys.babelfish_sp_verify_job(
         par_job_id
       , par_job_name
       , par_enabled
       , par_start_step_id
       , par_category_name
       , var_owner_sid
       , par_notify_level_eventlog
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , par_notify_email_operator_name
       , par_notify_netsend_operator_name
       , par_notify_page_operator_name
       , par_delete_level
       , par_category_id
       , var_notify_email_operator_id
       , var_notify_netsend_operator_id
       , var_notify_page_operator_id
       , par_originating_server
       ) t
    INTO var_owner_sid
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , par_category_id
       , var_notify_email_operator_id
       , var_notify_netsend_operator_id
       , var_notify_page_operator_id
       , par_originating_server
       , var_retval;

  IF (var_retval <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;

  var_notify_email_operator_name := par_notify_email_operator_name;


  IF (par_description IS NULL)
  THEN
    SELECT 'No description available.' INTO par_description;
  END IF;

  var_originating_server_id := 0;
  var_owner_sid := '';

  INSERT
    INTO sys.sysjobs (
         originating_server_id
       , name
       , enabled
       , description
       , start_step_id
       , category_id
       , owner_sid
       , notify_level_eventlog
       , notify_level_email
       , notify_level_netsend
       , notify_level_page
       , notify_email_operator_id
       , notify_email_operator_name
       , notify_netsend_operator_id
       , notify_page_operator_id
       , delete_level
       , version_number
    )
  VALUES (
         var_originating_server_id
       , par_job_name
       , par_enabled
       , par_description
       , par_start_step_id
       , par_category_id
       , var_owner_sid
       , par_notify_level_eventlog
       , par_notify_level_email
       , par_notify_level_netsend
       , par_notify_level_page
       , var_notify_email_operator_id
       , var_notify_email_operator_name
       , var_notify_netsend_operator_id
       , var_notify_page_operator_id
       , par_delete_level
       , 1);


  SELECT LASTVAL() INTO par_job_id;




  returncode := var_retval;
  RETURN;

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_jobschedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_name varchar = NULL::character varying,
  par_enabled smallint = 1,
  par_freq_type integer = 1,
  par_freq_interval integer = 0,
  par_freq_subday_type integer = 0,
  par_freq_subday_interval integer = 0,
  par_freq_relative_interval integer = 0,
  par_freq_recurrence_factor integer = 0,
  par_active_start_date integer = 20000101,
  par_active_end_date integer = 99991231,
  par_active_start_time integer = 0,
  par_active_end_time integer = 235959,
  inout par_schedule_id integer = NULL::integer,
  par_automatic_post smallint = 1,
  inout par_schedule_uid char = NULL::bpchar,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_owner_login_name VARCHAR(128);
BEGIN

  -- Check that we can uniquely identify the job
  SELECT t.par_job_name
       , t.par_job_id
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers (
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'::character varying
       , NULL::bpchar
       ) t
    INTO par_job_name
       , par_job_id
       , var_retval;

  IF (var_retval <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;


  SELECT t.par_schedule_uid
       , t.par_schedule_id
       , t.returncode
    FROM sys.babelfish_sp_add_schedule(
         par_name
       , par_enabled
       , par_freq_type
       , par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_end_date
       , par_active_start_time
       , par_active_end_time
       , var_owner_login_name
       , par_schedule_uid
       , par_schedule_id
       , NULL
       ) t
    INTO par_schedule_uid
       , par_schedule_id
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_attach_schedule(
         par_job_id := par_job_id
       , par_job_name := NULL
       , par_schedule_id := par_schedule_id
       , par_schedule_name := NULL
       , par_automatic_post := par_automatic_post
       ) t
    INTO var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_aws_add_jobschedule(par_job_id, par_schedule_id) t
    INTO var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;


  returncode := (var_retval);
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_jobstep (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_step_id integer = NULL::integer,
  par_step_name varchar = NULL::character varying,
  par_subsystem varchar = 'TSQL'::bpchar,
  par_command text = NULL::text,
  par_additional_parameters text = NULL::text,
  par_cmdexec_success_code integer = 0,
  par_on_success_action smallint = 1,
  par_on_success_step_id integer = 0,
  par_on_fail_action smallint = 2,
  par_on_fail_step_id integer = 0,
  par_server varchar = NULL::character varying,
  par_database_name varchar = NULL::character varying,
  par_database_user_name varchar = NULL::character varying,
  par_retry_attempts integer = 0,
  par_retry_interval integer = 0,
  par_os_run_priority integer = 0,
  par_output_file_name varchar = NULL::character varying,
  par_flags integer = 0,
  par_proxy_id integer = NULL::integer,
  par_proxy_name varchar = NULL::character varying,
  inout par_step_uid char = NULL::bpchar,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_max_step_id INT;
  var_step_id INT;
BEGIN

  SELECT t.par_job_name
       , t.par_job_id
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers (
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'::character varying
       , NULL::bpchar
       ) t
    INTO par_job_name
       , par_job_id
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;

  -- Default step id (if not supplied)
  IF (par_step_id IS NULL)
  THEN
     SELECT COALESCE(MAX(step_id), 0) + 1
        INTO var_step_id
       FROM sys.sysjobsteps
      WHERE (job_id = par_job_id);
  ELSE
    var_step_id := par_step_id;
  END IF;

  -- Get current maximum step id
  SELECT COALESCE(MAX(step_id), 0)
    INTO var_max_step_id
    FROM sys.sysjobsteps
   WHERE (job_id = par_job_id);


  SELECT t.returncode
    FROM sys.babelfish_sp_verify_jobstep(
         par_job_id
       , var_step_id --par_step_id
       , par_step_name
       , par_subsystem
       , par_command
       , par_server
       , par_on_success_action
       , par_on_success_step_id
       , par_on_fail_action
       , par_on_fail_step_id
       , par_os_run_priority
       , par_flags
       , par_output_file_name
       , par_proxy_id
    ) t
    INTO var_retval;

  IF (var_retval <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;



  UPDATE sys.sysjobs
     SET version_number = version_number + 1
       --, date_modified = GETDATE()
   WHERE (job_id = par_job_id);



  IF (var_step_id <= var_max_step_id)
  THEN
    UPDATE sys.sysjobsteps
       SET step_id = step_id + 1
     WHERE (step_id >= var_step_id) AND (job_id = par_job_id);


    UPDATE sys.sysjobsteps
       SET on_success_step_id = on_success_step_id + 1
     WHERE (on_success_step_id >= var_step_id) AND (job_id = par_job_id);

    UPDATE sys.sysjobsteps
       SET on_fail_step_id = on_fail_step_id + 1
     WHERE (on_fail_step_id >= var_step_id) AND (job_id = par_job_id);

    UPDATE sys.sysjobsteps
       SET on_success_step_id = 0
         , on_success_action = 1
     WHERE (on_success_step_id = var_step_id)
       AND (job_id = par_job_id);

    UPDATE sys.sysjobsteps
       SET on_fail_step_id = 0
         , on_fail_action = 2
     WHERE (on_fail_step_id = var_step_id)
       AND (job_id = par_job_id);
  END IF;


  SELECT uuid_in(md5(random()::text || clock_timestamp()::text)::cstring) INTO par_step_uid;


  INSERT
    INTO sys.sysjobsteps (
         job_id
       , step_id
       , step_name
       , subsystem
       , command
       , flags
       , additional_parameters
       , cmdexec_success_code
       , on_success_action
       , on_success_step_id
       , on_fail_action
       , on_fail_step_id
       , server
       , database_name
       , database_user_name
       , retry_attempts
       , retry_interval
       , os_run_priority
       , output_file_name
       , last_run_outcome
       , last_run_duration
       , last_run_retries
       , last_run_date
       , last_run_time
       , proxy_id
       , step_uid
   )
  VALUES (
         par_job_id
       , var_step_id
       , par_step_name
       , par_subsystem
       , par_command
       , par_flags
       , par_additional_parameters
       , par_cmdexec_success_code
       , par_on_success_action
       , par_on_success_step_id
       , par_on_fail_action
       , par_on_fail_step_id
       , par_server
       , par_database_name
       , par_database_user_name
       , par_retry_attempts
       , par_retry_interval
       , par_os_run_priority
       , par_output_file_name
       , 0
       , 0
       , 0
       , 0
       , 0
       , par_proxy_id
       , par_step_uid
  );

  --PERFORM sys.sp_jobstep_create_proc (par_step_uid);

  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_add_schedule (
  par_schedule_name varchar,
  par_enabled smallint = 1,
  par_freq_type integer = 0,
  par_freq_interval integer = 0,
  par_freq_subday_type integer = 0,
  par_freq_subday_interval integer = 0,
  par_freq_relative_interval integer = 0,
  par_freq_recurrence_factor integer = 0,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = 99991231,
  par_active_start_time integer = 0,
  par_active_end_time integer = 235959,
  par_owner_login_name varchar = NULL::character varying,
  inout par_schedule_uid char = NULL::bpchar,
  inout par_schedule_id integer = NULL::integer,
  par_originating_server varchar = NULL::character varying,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_owner_sid CHAR(85);
  var_orig_server_id INT;
BEGIN

  SELECT LTRIM(RTRIM(par_schedule_name))
       , LTRIM(RTRIM(par_owner_login_name))
       , UPPER(LTRIM(RTRIM(par_originating_server)))
       , 0
    INTO par_schedule_name
       , par_owner_login_name
       , par_originating_server
       , par_schedule_id;


  SELECT t.par_freq_interval
       , t.par_freq_subday_type
       , t.par_freq_subday_interval
       , t.par_freq_relative_interval
       , t.par_freq_recurrence_factor
       , t.par_active_start_date
       , t.par_active_start_time
       , t.par_active_end_date
       , t.par_active_end_time
       , t.returncode
    FROM sys.babelfish_sp_verify_schedule(
         NULL::integer
       , par_schedule_name
       , par_enabled
       , par_freq_type
       , par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_start_time
       , par_active_end_date
       , par_active_end_time
       , var_owner_sid
       ) t
    INTO par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_start_time
       , par_active_end_date
       , par_active_end_time
       , var_retval ;

  IF (var_retval <> 0) THEN
    returncode := 1;
        RETURN;
    END IF;

  IF (par_schedule_uid IS NULL)
  THEN

    SELECT uuid_in(md5(random()::text || clock_timestamp()::text)::cstring) INTO par_schedule_uid;
  END IF;

  var_orig_server_id := 0;
  var_owner_sid := uuid_in(md5(random()::text || clock_timestamp()::text)::cstring);


  INSERT
    INTO sys.sysschedules (
         schedule_uid
       , originating_server_id
       , name
       , owner_sid
       , enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
   )
  VALUES (
         par_schedule_uid
       , var_orig_server_id
       , par_schedule_name
       , var_owner_sid
       , par_enabled
       , par_freq_type
       , par_freq_interval
       , par_freq_subday_type
       , par_freq_subday_interval
       , par_freq_relative_interval
       , par_freq_recurrence_factor
       , par_active_start_date
       , par_active_end_date
       , par_active_start_time
       , par_active_end_time
  );


  SELECT 0 , LASTVAL()
    INTO var_retval, par_schedule_id;


  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_attach_schedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_schedule_id integer = NULL::integer,
  par_schedule_name varchar = NULL::character varying,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_sched_owner_sid CHAR(85);
  var_job_owner_sid CHAR(85);
BEGIN

  SELECT t.par_job_name
       , t.par_job_id
       , t.par_owner_sid
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers(
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'
       , var_job_owner_sid) t
    INTO par_job_name
       , par_job_id
       , var_job_owner_sid
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;


  SELECT t.par_schedule_name
       , t.par_schedule_id
       , t.par_owner_sid
       --, t.par_orig_server_id
       , t.returncode
    FROM sys.babelfish_sp_verify_schedule_identifiers(
         '@schedule_name'::character varying
       , '@schedule_id'::character varying
       , par_schedule_name
       , par_schedule_id
       , var_sched_owner_sid
       , NULL::integer
       , NULL::integer) t
    INTO par_schedule_name
       , par_schedule_id
       , var_sched_owner_sid
       , var_retval ;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF

                                                     ;
  IF (
    NOT EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    INSERT
      INTO sys.sysjobschedules (schedule_id, job_id)
    VALUES (par_schedule_id, par_job_id);

    SELECT 0 INTO var_retval;
  END IF;


  PERFORM sys.babelfish_sp_set_next_run (par_job_id, par_schedule_id);


  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_aws_add_jobschedule (
  par_job_id integer = NULL::integer,
  par_schedule_id integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  proc_name_mask VARCHAR(100);
  var_owner_login_name VARCHAR(128);
  var_xml TEXT DEFAULT '';
  var_cron_expression VARCHAR(50);
  var_job_cmd VARCHAR(255);
  lambda_arn VARCHAR(255);
  return_message text;
  var_schedule_name VARCHAR(255);

  var_job_name VARCHAR(128);
  var_start_step_id INTEGER;
  var_notify_level_email INTEGER;
  var_notify_email_operator_id INTEGER;
  var_notify_email_operator_name VARCHAR(128);
  notify_email_sender VARCHAR(128);
  var_delete_level INTEGER;
BEGIN

  IF (EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    SELECT cron_expression
      FROM sys.babelfish_sp_schedule_to_cron (par_job_id, par_schedule_id)
      INTO var_cron_expression;

    SELECT name
      FROM sys.sysschedules
     WHERE schedule_id = par_schedule_id
      INTO var_schedule_name;

    SELECT name
         , start_step_id
         , COALESCE(notify_level_email,0)
         , COALESCE(notify_email_operator_id,0)
         , COALESCE(notify_email_operator_name,'')
         , COALESCE(delete_level,0)
      FROM sys.sysjobs
     WHERE job_id = par_job_id
      INTO var_job_name
         , var_start_step_id
         , var_notify_level_email
         , var_notify_email_operator_id
         , var_notify_email_operator_name
         , var_delete_level;

    proc_name_mask := 'sys_data.sql_agent$job_%s_step_%s';
    var_job_cmd := format(proc_name_mask, par_job_id, '1');
    notify_email_sender := 'aws_test_email_sender@dbbest.com';


    var_xml := CONCAT(var_xml, '{');
    var_xml := CONCAT(var_xml, '"mode": "add_job",');
    var_xml := CONCAT(var_xml, '"parameters": {');
    var_xml := CONCAT(var_xml, '"vendor": "postgresql",');
    var_xml := CONCAT(var_xml, '"job_name": "',var_schedule_name,'",');
    var_xml := CONCAT(var_xml, '"job_frequency": "',var_cron_expression,'",');
    var_xml := CONCAT(var_xml, '"job_cmd": "',var_job_cmd,'",');
    var_xml := CONCAT(var_xml, '"notify_level_email": ',var_notify_level_email,',');
    var_xml := CONCAT(var_xml, '"delete_level": ',var_delete_level,',');
    var_xml := CONCAT(var_xml, '"uid": "',par_job_id,'",');
    var_xml := CONCAT(var_xml, '"callback": "sys.babelfish_sp_job_log",');
    var_xml := CONCAT(var_xml, '"notification": {');
    var_xml := CONCAT(var_xml, '"notify_email_sender": "',notify_email_sender,'",');
    var_xml := CONCAT(var_xml, '"notify_email_recipient": "',var_notify_email_operator_name,'"');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');

    -- RAISE NOTICE '%', var_xml;


    SELECT sys.babelfish_get_service_setting ('JOB', 'LAMBDA_ARN')
      INTO lambda_arn;

    SELECT sys.awslambda_fn (lambda_arn, var_xml) INTO return_message;
    returncode := 0;
  ELSE
    returncode := 1;
    RAISE 'Job not fount' USING ERRCODE := '50000';
  END IF;

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_aws_del_jobschedule (
  par_job_id integer = NULL::integer,
  par_schedule_id integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  proc_name_mask VARCHAR(100);
  var_owner_login_name VARCHAR(128);
  var_xml TEXT DEFAULT '';
  var_cron_expression VARCHAR(50);
  var_job_cmd VARCHAR(255);
  lambda_arn VARCHAR(255);
  return_message text;
  var_schedule_name VARCHAR(255);
BEGIN

  IF (EXISTS (
      SELECT 1
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)
         AND (job_id = par_job_id)))
  THEN
    SELECT name
      FROM sys.sysschedules
     WHERE schedule_id = par_schedule_id
      INTO var_schedule_name;

    var_xml := CONCAT(var_xml, '{');
    var_xml := CONCAT(var_xml, '"mode": "del_schedule",');
    var_xml := CONCAT(var_xml, '"parameters": {');
    var_xml := CONCAT(var_xml, '"schedule_name": "',var_schedule_name,'",');
    var_xml := CONCAT(var_xml, '"force_delete": "TRUE"');
    var_xml := CONCAT(var_xml, '}');
    var_xml := CONCAT(var_xml, '}');

    SELECT sys.babelfish_get_service_setting ('JOB', 'LAMBDA_ARN')
      INTO lambda_arn;

    SELECT sys.awslambda_fn (lambda_arn, var_xml) INTO return_message;
    returncode := 0;
  ELSE
    returncode := 1;
    RAISE 'Job not fount' USING ERRCODE := '50000';
  END IF;

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_delete_job (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_originating_server varchar = NULL::character varying,
  par_delete_history smallint = 1,
  par_delete_unused_schedule smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_category_id INT;
  var_job_owner_sid CHAR(85);
  var_err INT;
  var_schedule_id INT;
BEGIN
  IF ((par_job_id IS NOT NULL) OR (par_job_name IS NOT NULL))
  THEN
    SELECT t.par_job_name
         , t.par_job_id
         , t.par_owner_sid
         , t.returncode
      FROM sys.babelfish_sp_verify_job_identifiers(
           '@job_name'
         , '@job_id'
         , par_job_name
         , par_job_id
         , 'TEST'
         , var_job_owner_sid
         ) t
      INTO par_job_name
         , par_job_id
         , var_job_owner_sid
         , var_retval;

    IF (var_retval <> 0) THEN
      returncode := (1);
      RETURN;
    END IF;
  END IF;




  SELECT category_id
    INTO var_category_id
    FROM sys.sysjobs
   WHERE job_id = par_job_id;


  IF (par_job_id IS NOT NULL)
  THEN
    --CREATE TEMPORARY TABLE "#temp_schedules_to_delete" (schedule_id INT NOT NULL);

    -- Delete all traces of the job
    -- BEGIN TRANSACTION
    -- Get the schedules to delete before deleting records from sysjobschedules



    --IF (par_delete_unused_schedule = 1)
    --THEN
      -- ZZZ optimize
      -- Get the list of schedules to delete
      --INSERT INTO "#temp_schedules_to_delete"
      --SELECT DISTINCT schedule_id
      -- FROM sys.sysschedules
      -- WHERE schedule_id IN (SELECT schedule_id
      -- FROM sys.sysjobschedules
      -- WHERE job_id = par_job_id);
      --INSERT INTO "#temp_schedules_to_delete"
      SELECT schedule_id
     FROM sys.sysjobschedules
       WHERE job_id = par_job_id
        INTO var_schedule_id;

    PERFORM sys.babelfish_sp_aws_del_jobschedule (par_job_id := par_job_id, par_schedule_id := var_schedule_id);


-- END IF;


    --DELETE FROM sys.sysschedules
    -- WHERE schedule_id IN (SELECT schedule_id FROM sys.sysjobschedules WHERE job_id = par_job_id);

    DELETE FROM sys.sysjobschedules
     WHERE job_id = par_job_id;

    DELETE FROM sys.sysjobsteps
     WHERE job_id = par_job_id;

    DELETE FROM sys.sysjobs
     WHERE job_id = par_job_id;

    SELECT 0 INTO var_err;


    IF (par_delete_unused_schedule = 1)
    THEN

      DELETE FROM sys.sysschedules
       WHERE schedule_id = var_schedule_id; --IN (SELECT schedule_id FROM "#temp_schedules_to_delete");

      --DELETE FROM sys.sysschedules
      -- WHERE schedule_id IN (SELECT schedule_id
      -- FROM "#temp_schedules_to_delete" AS sdel
      -- WHERE NOT EXISTS (SELECT *
      -- FROM sys.sysjobschedules AS js
      -- WHERE js.schedule_id = sdel.schedule_id));
    END IF;


    IF (par_delete_history = 1)
    THEN
      DELETE FROM sys.sysjobhistory
      WHERE job_id = par_job_id;
    END IF;



    --DROP TABLE "#temp_schedules_to_delete";
  END IF;


  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_delete_jobschedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_name varchar = NULL::character varying,
  par_keep_schedule integer = 0,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_sched_count INT;
  var_schedule_id INT;
  var_job_owner_sid CHAR(85);
BEGIN

  SELECT LTRIM(RTRIM(par_name)) INTO par_name;


  SELECT t.par_job_name
       , t.par_job_id
       , t.par_owner_sid
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers(
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'
       , var_job_owner_sid
       ) t
    INTO par_job_name
       , par_job_id
       , var_job_owner_sid
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;

  IF (LOWER(UPPER(par_name)) = LOWER('ALL'))
  THEN
    SELECT - 1 INTO var_schedule_id;



    CREATE TEMPORARY TABLE "#temp_schedules_to_delete" (schedule_id INT NOT NULL)

                                                    ;

    IF (par_keep_schedule = 0)
    THEN

      INSERT INTO "#temp_schedules_to_delete"
      SELECT DISTINCT schedule_id
        FROM sys.sysschedules
       WHERE (schedule_id IN (SELECT schedule_id
                                FROM sys.sysjobschedules
                               WHERE (job_id = par_job_id)));

      IF (EXISTS (SELECT *
                    FROM sys.sysjobschedules
                   WHERE (job_id <> par_job_id)
                     AND (schedule_id IN (SELECT schedule_id
                                            FROM "#temp_schedules_to_delete"))))
      THEN
        RAISE 'One or more schedules were not deleted because they are being used by at least one other job. Use "sp_detach_schedule" to remove schedules from a job.' USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;


    DELETE FROM sys.sysjobschedules
     WHERE (job_id = par_job_id);


    DELETE FROM sys.sysschedules
     WHERE schedule_id IN (SELECT schedule_id FROM "#temp_schedules_to_delete");
  ELSE ---- IF (LOWER(UPPER(par_name)) = LOWER('ALL'))

    -- Need to use sp_detach_schedule to remove this ambiguous schedule name
    IF(var_sched_count > 1)
    THEN
      RAISE 'More than one schedule named "%" is attached to job "%". Use "sp_detach_schedule" to remove schedules from a job.', par_name, par_job_name USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;

    --If user requests that the schedule be removed (the legacy behavoir)
    --make sure it isnt being used by another job
    IF (par_keep_schedule = 0)
    THEN
      IF(EXISTS(SELECT *
                  FROM sys.sysjobschedules
                 WHERE (schedule_id = var_schedule_id)
                   AND (job_id <> par_job_id)))
      THEN
        RAISE 'Schedule "%" was not deleted because it is being used by at least one other job. Use "sp_detach_schedule" to remove schedules from a job.', par_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;


    DELETE FROM sys.sysjobschedules
     WHERE (job_id = par_job_id)
       AND (schedule_id = var_schedule_id);


    IF (par_keep_schedule = 0)
    THEN

      DELETE FROM sys.sysschedules
       WHERE (schedule_id = var_schedule_id);
    END IF;

    SELECT t.returncode
    FROM sys.babelfish_sp_aws_del_jobschedule(par_job_id, var_schedule_id) t
    INTO var_retval;


  END IF;


  UPDATE sys.sysjobs
     SET version_number = version_number + 1
       -- , date_modified = GETDATE() /
   WHERE job_id = par_job_id;

  DROP TABLE IF EXISTS "#temp_schedules_to_delete";



  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_delete_jobstep (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_step_id integer = NULL::integer,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_max_step_id INT;
  var_valid_range VARCHAR(50);
  var_job_owner_sid CHAR(85);
BEGIN
  SELECT t.par_job_name
       , t.par_job_id
       , t.par_owner_sid
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers(
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'
       , var_job_owner_sid
       ) t
    INTO par_job_name
       , par_job_id
       , var_job_owner_sid
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;


  SELECT COALESCE(MAX(step_id), 0)
    INTO var_max_step_id
    FROM sys.sysjobsteps
   WHERE (job_id = par_job_id);


  IF (par_step_id < 0) OR (par_step_id > var_max_step_id)
  THEN
    SELECT CONCAT('0 (all steps) ..', CAST (var_max_step_id AS VARCHAR(1)))
      INTO var_valid_range;
     RAISE 'The specified "%" is invalid (valid values are: %).', 'step_id', var_valid_range USING ERRCODE := '50000';
     returncode := 1;
     RETURN;

    END IF;



    IF (par_step_id = 0)
    THEN
      DELETE FROM sys.sysjobsteps
       WHERE (job_id = par_job_id);
    ELSE
      DELETE FROM sys.sysjobsteps
       WHERE (job_id = par_job_id) AND (step_id = par_step_id);
    END IF;

    IF (par_step_id <> 0)
    THEN

      UPDATE sys.sysjobsteps
         SET step_id = step_id - 1
       WHERE (step_id > par_step_id)
         AND (job_id = par_job_id);


      UPDATE sys.sysjobsteps
         SET on_success_step_id = on_success_step_id - 1
       WHERE (on_success_step_id > par_step_id) AND (job_id = par_job_id);

      UPDATE sys.sysjobsteps
         SET on_fail_step_id = on_fail_step_id - 1
       WHERE (on_fail_step_id > par_step_id) AND (job_id = par_job_id);


      UPDATE sys.sysjobsteps
         SET on_success_step_id = 0
           , on_success_action = 1
       WHERE (on_success_step_id = par_step_id)
         AND (job_id = par_job_id);


      UPDATE sys.sysjobsteps
         SET on_fail_step_id = 0
           , on_fail_action = 2
       WHERE (on_fail_step_id = par_step_id) AND (job_id = par_job_id);
    END IF;


    UPDATE sys.sysjobs
       SET version_number = version_number + 1
         --, date_modified = GETDATE() /
     WHERE (job_id = par_job_id);




    returncode := 0;
    RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_delete_schedule (
  par_schedule_id integer = NULL::integer,
  par_schedule_name varchar = NULL::character varying,
  par_force_delete smallint = 0,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_job_count INT;
BEGIN

  SELECT COUNT(*)
    INTO var_job_count
    FROM sys.sysjobschedules
   WHERE (schedule_id = par_schedule_id);


  IF ((par_force_delete = 0) AND (var_job_count > 0))
  THEN
    RAISE 'The schedule was not deleted because it is being used by one or more jobs.' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  DELETE FROM sys.sysjobschedules
   WHERE schedule_id = par_schedule_id;


  DELETE FROM sys.sysschedules
   WHERE schedule_id = par_schedule_id;


  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_detach_schedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_schedule_id integer = NULL::integer,
  par_schedule_name varchar = NULL::character varying,
  par_delete_unused_schedule smallint = 0,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_retval INT;
  var_sched_owner_sid CHAR(85);
  var_job_owner_sid CHAR(85);
BEGIN

  SELECT t.par_job_name
       , t.par_job_id
       , t.par_owner_sid
       , t.returncode
    FROM sys.babelfish_sp_verify_job_identifiers(
         '@job_name'
       , '@job_id'
       , par_job_name
       , par_job_id
       , 'TEST'
       , var_job_owner_sid
       ) t
    INTO par_job_name
       , par_job_id
       , var_job_owner_sid
       , var_retval;

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;


  SELECT t.par_schedule_name
       , t.par_schedule_id
       , t.par_owner_sid
       , t.par_orig_server_id
       , t.returncode
    FROM sys.babelfish_sp_verify_schedule_identifiers(
         '@schedule_name'
       , '@schedule_id'
       , par_schedule_name
       , par_schedule_id
       , var_sched_owner_sid
       , NULL
       , par_job_id
       ) t
    INTO par_schedule_name
       , par_schedule_id
       , var_sched_owner_sid
       , var_retval;
       -- job_id_filter

  IF (var_retval <> 0) THEN
    returncode := 1;
    RETURN;
  END IF;


  IF (NOT EXISTS (
    SELECT *
      FROM sys.sysjobschedules
     WHERE (schedule_id = par_schedule_id)
       AND (job_id = par_job_id)))
  THEN
    RAISE 'The specified schedule name "%s" is not associated with the job "%s".', par_schedule_name, par_job_name USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_aws_del_jobschedule(par_job_id, par_schedule_id) t
    INTO var_retval;

  DELETE FROM sys.sysjobschedules
   WHERE (job_id = par_job_id)
     AND (schedule_id = par_schedule_id);

  SELECT 0 -- ZZZ
    INTO var_retval;


  IF (var_retval = 0 AND par_delete_unused_schedule = 1)
  THEN
    IF (NOT EXISTS (
      SELECT *
        FROM sys.sysjobschedules
       WHERE (schedule_id = par_schedule_id)))
    THEN
      DELETE FROM sys.sysschedules
       WHERE (schedule_id = par_schedule_id);
    END IF;
  END IF;
-- 7268 "sql/sys_function_helpers.sql"
  -- PERFORM sys.babelfish_sp_delete_job (par_job_id := par_job_id);


  returncode := var_retval;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_job_log (
    IN pid INTEGER
  , IN pstatus INTEGER
  , IN pmessage VARCHAR(255))
RETURNS void AS
$BODY$
BEGIN
  PERFORM sys.babelfish_update_job (pid, pmessage);

  -- INSERT INTO ms_test.jobs_log(id, t, status, message)
  -- VALUES (pid, CURRENT_TIMESTAMP, pstatus, pmessage);
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_schedule_to_cron (
  par_job_id integer,
  par_schedule_id integer,
  out cron_expression varchar
)
RETURNS VARCHAR AS
$body$
DECLARE
  var_enabled INTEGER;
  var_freq_type INTEGER;
  var_freq_interval INTEGER;
  var_freq_subday_type INTEGER;
  var_freq_subday_interval INTEGER;
  var_freq_relative_interval INTEGER;
  var_freq_recurrence_factor INTEGER;
  var_active_start_date INTEGER;
  var_active_end_date INTEGER;
  var_active_start_time INTEGER;
  var_active_end_time INTEGER;

  var_next_run_date date;
  var_next_run_time time;
  var_next_run_dt timestamp;

  var_tmp_interval varchar(50);
  var_current_dt timestamp;
  var_next_dt timestamp;
BEGIN

  SELECT enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
    FROM sys.sysschedules
    INTO var_enabled
       , var_freq_type
       , var_freq_interval
       , var_freq_subday_type
       , var_freq_subday_interval
       , var_freq_relative_interval
       , var_freq_recurrence_factor
       , var_active_start_date
       , var_active_end_date
       , var_active_start_time
       , var_active_end_time
   WHERE schedule_id = par_schedule_id;


  CASE var_freq_type
    WHEN 1 THEN
      NULL;

    WHEN 4 THEN
    BEGIN
        cron_expression :=
        CASE


          WHEN var_freq_subday_type = 4 THEN format('cron(*/%s * * * ? *)', var_freq_subday_interval::character varying)
          WHEN var_freq_subday_type = 8 THEN format('cron(0 */%s * * ? *)', var_freq_subday_interval::character varying)
          ELSE ''
        END;
    END;

    WHEN 8 THEN
      NULL;

    WHEN 16 THEN
      NULL;

    WHEN 32 THEN
      NULL;

    WHEN 64 THEN
      NULL;

    WHEN 128 THEN
     NULL;

  END CASE;

 -- return cron_expression;

END;
$body$
LANGUAGE 'plpgsql';

create or replace function sys.babelfish_sp_sequence_get_range(
  in par_sequence_name text,
  in par_range_size bigint,
  out par_range_first_value bigint,
  out par_range_last_value bigint,
  out par_range_cycle_count bigint,
  out par_sequence_increment bigint,
  out par_sequence_min_value bigint,
  out par_sequence_max_value bigint
) as
$body$
declare
  v_is_cycle character varying(3);
  v_current_value bigint;
begin
  select s.minimum_value, s.maximum_value, s.increment, s.cycle_option
    from information_schema.sequences s
    where s.sequence_name = $1
    into par_sequence_min_value, par_sequence_max_value, par_sequence_increment, v_is_cycle;

  par_range_first_value := sys.babelfish_get_sequence_value(par_sequence_name);

  if par_range_first_value > par_sequence_min_value then
    par_range_first_value := par_range_first_value + 1;
  end if;

  if v_is_cycle = 'YES' then
    par_range_cycle_count := 0;
  end if;

  for i in 1..$2 loop
    select nextval(par_sequence_name) into v_current_value;
    if (v_is_cycle = 'YES') and (v_current_value = par_sequence_min_value) and (par_range_first_value <> v_current_value) then
      par_range_cycle_count := par_range_cycle_count + 1;
    end if;
  end loop;

  par_range_last_value := sys.babelfish_get_sequence_value(par_sequence_name);
end;
$body$
language plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_set_next_run (
  par_job_id integer,
  par_schedule_id integer
)
RETURNS void AS
$body$
DECLARE
  var_enabled INTEGER;
  var_freq_type INTEGER;
  var_freq_interval INTEGER;
  var_freq_subday_type INTEGER;
  var_freq_subday_interval INTEGER;
  var_freq_relative_interval INTEGER;
  var_freq_recurrence_factor INTEGER;
  var_active_start_date INTEGER;
  var_active_end_date INTEGER;
  var_active_start_time INTEGER;
  var_active_end_time INTEGER;

  var_next_run_date date;
  var_next_run_time time;
  var_next_run_dt timestamp;

  var_tmp_interval varchar(50);
  var_current_dt timestamp;
  var_next_dt timestamp;
BEGIN

  SELECT enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
    FROM sys.sysschedules
    INTO var_enabled
       , var_freq_type
       , var_freq_interval
       , var_freq_subday_type
       , var_freq_subday_interval
       , var_freq_relative_interval
       , var_freq_recurrence_factor
       , var_active_start_date
       , var_active_end_date
       , var_active_start_time
       , var_active_end_time
   WHERE schedule_id = par_schedule_id;

  SELECT next_run_date
       , next_run_time
    FROM sys.sysjobschedules
    INTO var_next_run_date
       , var_next_run_time
   WHERE schedule_id = par_schedule_id
     AND job_id = par_job_id;


  CASE var_freq_type
    WHEN 1 THEN
      NULL;

    WHEN 4 THEN
    BEGIN


      IF (var_next_run_date IS NULL OR var_next_run_time IS NULL)
      THEN
        var_current_dt := now()::timestamp;

        UPDATE sys.sysjobschedules
           SET next_run_date = var_current_dt::date
             , next_run_time = var_current_dt::time
         WHERE schedule_id = par_schedule_id
           AND job_id = par_job_id;
        RETURN;
      ELSE
        var_tmp_interval :=
        CASE

          WHEN var_freq_subday_type = 2 THEN var_freq_subday_interval::character varying || ' second'
          WHEN var_freq_subday_type = 4 THEN var_freq_subday_interval::character varying || ' minute'
          WHEN var_freq_subday_type = 8 THEN var_freq_subday_interval::character varying || ' hour'
          ELSE ''
        END;

        var_next_dt := (var_next_run_date::date + var_next_run_time::time)::timestamp + var_tmp_interval::INTERVAL;
        UPDATE sys.sysjobschedules
           SET next_run_date = var_next_dt::date
             , next_run_time = var_next_dt::time
         WHERE schedule_id = par_schedule_id
           AND job_id = par_job_id;
        RETURN;
      END IF;
    END;

    WHEN 8 THEN
      NULL;

    WHEN 16 THEN
      NULL;

    WHEN 32 THEN
      NULL;

    WHEN 64 THEN
      NULL;

    WHEN 128 THEN
     NULL;

  END CASE;

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_job (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_description varchar = NULL::character varying,
  par_start_step_id integer = NULL::integer,
  par_category_name varchar = NULL::character varying,
  par_owner_login_name varchar = NULL::character varying,
  par_notify_level_eventlog integer = NULL::integer,
  par_notify_level_email integer = NULL::integer,
  par_notify_level_netsend integer = NULL::integer,
  par_notify_level_page integer = NULL::integer,
  par_notify_email_operator_name varchar = NULL::character varying,
  par_notify_netsend_operator_name varchar = NULL::character varying,
  par_notify_page_operator_name varchar = NULL::character varying,
  par_delete_level integer = NULL::integer,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_category_id INT;
    var_notify_email_operator_id INT;
    var_notify_netsend_operator_id INT;
    var_notify_page_operator_id INT;
    var_owner_sid CHAR(85);
    var_alert_id INT;
    var_cached_attribute_modified INT;
    var_is_sysadmin INT;
    var_current_owner VARCHAR(128);
    var_enable_only_used INT;
    var_x_new_name VARCHAR(128);
    var_x_enabled SMALLINT;
    var_x_description VARCHAR(512);
    var_x_start_step_id INT;
    var_x_category_name VARCHAR(128);
    var_x_category_id INT;
    var_x_owner_sid CHAR(85);
    var_x_notify_level_eventlog INT;
    var_x_notify_level_email INT;
    var_x_notify_level_netsend INT;
    var_x_notify_level_page INT;
    var_x_notify_email_operator_name VARCHAR(128);
    var_x_notify_netsnd_operator_name VARCHAR(128);
    var_x_notify_page_operator_name VARCHAR(128);
    var_x_delete_level INT;
    var_x_originating_server_id INT;
    var_x_master_server SMALLINT;
BEGIN


    SELECT
        LTRIM(RTRIM(par_job_name))
        INTO par_job_name;
    SELECT
        LTRIM(RTRIM(par_new_name))
        INTO par_new_name;
    SELECT
        LTRIM(RTRIM(par_description))
        INTO par_description;
    SELECT
        LTRIM(RTRIM(par_category_name))
        INTO par_category_name;
    SELECT
        LTRIM(RTRIM(par_notify_email_operator_name))
        INTO par_notify_email_operator_name;
    SELECT
        LTRIM(RTRIM(par_notify_netsend_operator_name))
        INTO par_notify_netsend_operator_name;
    SELECT
        LTRIM(RTRIM(par_notify_page_operator_name))
        INTO par_notify_page_operator_name
                                                                ;

    IF ((par_new_name IS NOT NULL) OR (par_enabled IS NOT NULL) OR (par_start_step_id IS NOT NULL) OR (par_owner_login_name IS NOT NULL) OR (par_notify_level_eventlog IS NOT NULL) OR (par_notify_level_email IS NOT NULL) OR (par_notify_level_netsend IS NOT NULL) OR (par_notify_level_page IS NOT NULL) OR (par_notify_email_operator_name IS NOT NULL) OR (par_notify_netsend_operator_name IS NOT NULL) OR (par_notify_page_operator_name IS NOT NULL) OR (par_delete_level IS NOT NULL)) THEN
        SELECT
            1
            INTO var_cached_attribute_modified;
    ELSE
        SELECT
            0
            INTO var_cached_attribute_modified;
    END IF
                                                                      ;

    IF ((par_enabled IS NOT NULL) AND (par_new_name IS NULL) AND (par_description IS NULL) AND (par_start_step_id IS NULL) AND (par_category_name IS NULL) AND (par_owner_login_name IS NULL) AND (par_notify_level_eventlog IS NULL) AND (par_notify_level_email IS NULL) AND (par_notify_level_netsend IS NULL) AND (par_notify_level_page IS NULL) AND (par_notify_email_operator_name IS NULL) AND (par_notify_netsend_operator_name IS NULL) AND (par_notify_page_operator_name IS NULL) AND (par_delete_level IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
                                                                                      ;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_new_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_description IS NULL) THEN
        SELECT
            var_x_description
            INTO par_description;
    END IF;

    IF (par_start_step_id IS NULL) THEN
        SELECT
            var_x_start_step_id
            INTO par_start_step_id;
    END IF;

    IF (par_category_name IS NULL) THEN
        SELECT
            var_x_category_name
            INTO par_category_name;
    END IF;

    IF (var_owner_sid IS NULL) THEN
        SELECT
            var_x_owner_sid
            INTO var_owner_sid;
    END IF;

    IF (par_notify_level_eventlog IS NULL) THEN
        SELECT
            var_x_notify_level_eventlog
            INTO par_notify_level_eventlog;
    END IF;

    IF (par_notify_level_email IS NULL) THEN
        SELECT
            var_x_notify_level_email
            INTO par_notify_level_email;
    END IF;

    IF (par_notify_level_netsend IS NULL) THEN
        SELECT
            var_x_notify_level_netsend
            INTO par_notify_level_netsend;
    END IF;

    IF (par_notify_level_page IS NULL) THEN
        SELECT
            var_x_notify_level_page
            INTO par_notify_level_page;
    END IF;

    IF (par_notify_email_operator_name IS NULL) THEN
        SELECT
            var_x_notify_email_operator_name
            INTO par_notify_email_operator_name;
    END IF;

    IF (par_notify_netsend_operator_name IS NULL) THEN
        SELECT
            var_x_notify_netsnd_operator_name
            INTO par_notify_netsend_operator_name;
    END IF;

    IF (par_notify_page_operator_name IS NULL) THEN
        SELECT
            var_x_notify_page_operator_name
            INTO par_notify_page_operator_name;
    END IF;

    IF (par_delete_level IS NULL) THEN
        SELECT
            var_x_delete_level
            INTO par_delete_level;
    END IF
                                                            ;

    IF (LOWER(par_description) = LOWER('')) THEN
        SELECT
            NULL
            INTO par_description;
    END IF;

    IF (par_category_name = '') THEN
        SELECT
            NULL
            INTO par_category_name;
    END IF;

    IF (par_notify_email_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_email_operator_name;
    END IF;

    IF (par_notify_netsend_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_netsend_operator_name;
    END IF;

    IF (par_notify_page_operator_name = '') THEN
        SELECT
            NULL
            INTO par_notify_page_operator_name;
    END IF
                          ;
    SELECT
        t.par_owner_sid, t.par_notify_level_email, t.par_notify_level_netsend, t.par_notify_level_page,
        t.par_category_id, t.par_notify_email_operator_id, t.par_notify_netsend_operator_id, t.par_notify_page_operator_id, t.par_originating_server, t.ReturnCode
        FROM sys.babelfish_sp_verify_job(par_job_id, par_new_name, par_enabled, par_start_step_id, par_category_name, var_owner_sid, par_notify_level_eventlog, par_notify_level_email, par_notify_level_netsend, par_notify_level_page, par_notify_email_operator_name, par_notify_netsend_operator_name, par_notify_page_operator_name, par_delete_level, var_category_id, var_notify_email_operator_id, var_notify_netsend_operator_id, var_notify_page_operator_id, NULL) t
        INTO var_owner_sid, par_notify_level_email, par_notify_level_netsend, par_notify_level_page, var_category_id, var_notify_email_operator_id, var_notify_netsend_operator_id, var_notify_page_operator_id, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF


                                                                                             ;

    IF (par_owner_login_name IS NOT NULL) THEN
        IF (EXISTS (SELECT
            1
            FROM sys.sysjobsteps
            WHERE (job_id = par_job_id) AND (LOWER(subsystem) = LOWER('TSQL')))) THEN

            UPDATE sys.sysjobsteps
            SET database_user_name = NULL
                WHERE (job_id = par_job_id) AND (LOWER(subsystem) = LOWER('TSQL'));
        END IF;
    END IF;
    UPDATE sys.sysjobs
    SET name = par_new_name, enabled = par_enabled, description = par_description, start_step_id = par_start_step_id, category_id = var_category_id
                                     , owner_sid = var_owner_sid, notify_level_eventlog = par_notify_level_eventlog, notify_level_email = par_notify_level_email, notify_level_netsend = par_notify_level_netsend, notify_level_page = par_notify_level_page, notify_email_operator_id = var_notify_email_operator_id
                                     , notify_netsend_operator_id = var_notify_netsend_operator_id
                                     , notify_page_operator_id = var_notify_page_operator_id
                                     , delete_level = par_delete_level, version_number = version_number + 1


        WHERE (job_id = par_job_id);
    SELECT
        0
        INTO var_retval

                            ;
    ReturnCode := (var_retval);
    RETURN
                         ;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_jobschedule (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_freq_type integer = NULL::integer,
  par_freq_interval integer = NULL::integer,
  par_freq_subday_type integer = NULL::integer,
  par_freq_subday_interval integer = NULL::integer,
  par_freq_relative_interval integer = NULL::integer,
  par_freq_recurrence_factor integer = NULL::integer,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = NULL::integer,
  par_active_start_time integer = NULL::integer,
  par_active_end_time integer = NULL::integer,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_sched_count INT;
    var_schedule_id INT;
    var_job_owner_sid CHAR(85);
    var_enable_only_used INT;
    var_x_name VARCHAR(128);
    var_x_enabled SMALLINT;
    var_x_freq_type INT;
    var_x_freq_interval INT;
    var_x_freq_subday_type INT;
    var_x_freq_subday_interval INT;
    var_x_freq_relative_interval INT;
    var_x_freq_recurrence_factor INT;
    var_x_active_start_date INT;
    var_x_active_end_date INT;
    var_x_active_start_time INT;
    var_x_active_end_time INT;
    var_owner_sid CHAR(85);
BEGIN

    SELECT
        LTRIM(RTRIM(par_name))
        INTO par_name;
    SELECT
        LTRIM(RTRIM(par_new_name))
        INTO par_new_name
                                                            ;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
                                                     ;
    SELECT
        t.par_job_name, t.par_job_id, t.par_owner_sid, t.ReturnCode
        FROM sys.babelfish_sp_verify_job_identifiers('@job_name', '@job_id', par_job_name, par_job_id, 'TEST', var_job_owner_sid) t
        INTO par_job_name, par_job_id, var_job_owner_sid, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF

                                                                      ;

    IF ((par_enabled IS NOT NULL) AND (par_name IS NULL) AND (par_new_name IS NULL) AND (par_freq_type IS NULL) AND (par_freq_interval IS NULL) AND (par_freq_subday_type IS NULL) AND (par_freq_subday_interval IS NULL) AND (par_freq_relative_interval IS NULL) AND (par_freq_recurrence_factor IS NULL) AND (par_active_start_date IS NULL) AND (par_active_end_date IS NULL) AND (par_active_start_time IS NULL) AND (par_active_end_time IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_freq_type IS NULL) THEN
        SELECT
            var_x_freq_type
            INTO par_freq_type;
    END IF;

    IF (par_freq_interval IS NULL) THEN
        SELECT
            var_x_freq_interval
            INTO par_freq_interval;
    END IF;

    IF (par_freq_subday_type IS NULL) THEN
        SELECT
            var_x_freq_subday_type
            INTO par_freq_subday_type;
    END IF;

    IF (par_freq_subday_interval IS NULL) THEN
        SELECT
            var_x_freq_subday_interval
            INTO par_freq_subday_interval;
    END IF;

    IF (par_freq_relative_interval IS NULL) THEN
        SELECT
            var_x_freq_relative_interval
            INTO par_freq_relative_interval;
    END IF;

    IF (par_freq_recurrence_factor IS NULL) THEN
        SELECT
            var_x_freq_recurrence_factor
            INTO par_freq_recurrence_factor;
    END IF;

    IF (par_active_start_date IS NULL) THEN
        SELECT
            var_x_active_start_date
            INTO par_active_start_date;
    END IF;

    IF (par_active_end_date IS NULL) THEN
        SELECT
            var_x_active_end_date
            INTO par_active_end_date;
    END IF;

    IF (par_active_start_time IS NULL) THEN
        SELECT
            var_x_active_start_time
            INTO par_active_start_time;
    END IF;

    IF (par_active_end_time IS NULL) THEN
        SELECT
            var_x_active_end_time
            INTO par_active_end_time;
    END IF
                                                         ;
    SELECT
        t.par_freq_interval, t.par_freq_subday_type, t.par_freq_subday_interval, t.par_freq_relative_interval, t.par_freq_recurrence_factor, t.par_active_start_date, t.par_active_start_time,
        t.par_active_end_date, t.par_active_end_time, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule(var_schedule_id
                          , par_new_name
                   , par_enabled
                      , par_freq_type
                        , par_freq_interval
                            , par_freq_subday_type
                               , par_freq_subday_interval
                                   , par_freq_relative_interval
                                     , par_freq_recurrence_factor
                                     , par_active_start_date
                                , par_active_start_time
                                , par_active_end_date
                              , par_active_end_time
                              , var_owner_sid) t
        INTO par_freq_interval, par_freq_subday_type, par_freq_subday_interval, par_freq_relative_interval, par_freq_recurrence_factor, par_active_start_date, par_active_start_time, par_active_end_date, par_active_end_time, var_retval ;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF

                                ;
    UPDATE sys.sysschedules
    SET name = par_new_name, enabled = par_enabled, freq_type = par_freq_type, freq_interval = par_freq_interval, freq_subday_type = par_freq_subday_type, freq_subday_interval = par_freq_subday_interval, freq_relative_interval = par_freq_relative_interval, freq_recurrence_factor = par_freq_recurrence_factor, active_start_date = par_active_start_date, active_end_date = par_active_end_date, active_start_time = par_active_start_time, active_end_time = par_active_end_time
                                             , version_number = version_number + 1
        WHERE (schedule_id = var_schedule_id);
    SELECT
        0
        INTO var_retval

                                                            ;
    UPDATE sys.sysjobs
    SET version_number = version_number + 1

        WHERE (job_id = par_job_id);
    ReturnCode := (var_retval);
    RETURN
                         ;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_jobstep (
  par_job_id integer = NULL::integer,
  par_job_name varchar = NULL::character varying,
  par_step_id integer = NULL::integer,
  par_step_name varchar = NULL::character varying,
  par_subsystem varchar = NULL::character varying,
  par_command text = NULL::text,
  par_additional_parameters text = NULL::text,
  par_cmdexec_success_code integer = NULL::integer,
  par_on_success_action smallint = NULL::smallint,
  par_on_success_step_id integer = NULL::integer,
  par_on_fail_action smallint = NULL::smallint,
  par_on_fail_step_id integer = NULL::integer,
  par_server varchar = NULL::character varying,
  par_database_name varchar = NULL::character varying,
  par_database_user_name varchar = NULL::character varying,
  par_retry_attempts integer = NULL::integer,
  par_retry_interval integer = NULL::integer,
  par_os_run_priority integer = NULL::integer,
  par_output_file_name varchar = NULL::character varying,
  par_flags integer = NULL::integer,
  par_proxy_id integer = NULL::integer,
  par_proxy_name varchar = NULL::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_os_run_priority_code INT;
    var_step_id_as_char VARCHAR(10);
    var_new_step_name VARCHAR(128);
    var_x_step_name VARCHAR(128);
    var_x_subsystem VARCHAR(40);
    var_x_command TEXT;
    var_x_flags INT;
    var_x_cmdexec_success_code INT;
    var_x_on_success_action SMALLINT;
    var_x_on_success_step_id INT;
    var_x_on_fail_action SMALLINT;
    var_x_on_fail_step_id INT;
    var_x_server VARCHAR(128);
    var_x_database_name VARCHAR(128);
    var_x_database_user_name VARCHAR(128);
    var_x_retry_attempts INT;
    var_x_retry_interval INT;
    var_x_os_run_priority INT;
    var_x_output_file_name VARCHAR(200);
    var_x_proxy_id INT;
    var_x_last_run_outcome SMALLINT;
    var_x_last_run_duration INT;
    var_x_last_run_retries INT;
    var_x_last_run_date INT;
    var_x_last_run_time INT;
    var_new_proxy_id INT;
    var_subsystem_id INT;
    var_auto_proxy_name VARCHAR(128);
    var_job_owner_sid CHAR(85);
    var_step_uid CHAR(85);
BEGIN
    SELECT NULL INTO var_new_proxy_id;

    SELECT LTRIM(RTRIM(par_step_name)) INTO par_step_name;
    SELECT LTRIM(RTRIM(par_subsystem)) INTO par_subsystem;
    SELECT LTRIM(RTRIM(par_command)) INTO par_command;
    SELECT LTRIM(RTRIM(par_server)) INTO par_server;
    SELECT LTRIM(RTRIM(par_database_name)) INTO par_database_name;
    SELECT LTRIM(RTRIM(par_database_user_name)) INTO par_database_user_name;
    SELECT LTRIM(RTRIM(par_output_file_name)) INTO par_output_file_name;
    SELECT LTRIM(RTRIM(par_proxy_name)) INTO par_proxy_name;





    SELECT
        t.par_job_name, t.par_job_id, t.par_owner_sid, t.ReturnCode
        FROM sys.babelfish_sp_verify_job_identifiers('@job_name'
                                     , '@job_id'
                                   , par_job_name
                       , par_job_id
                     , 'TEST'
                                     , var_job_owner_sid)
        INTO par_job_name, par_job_id, var_job_owner_sid, var_retval
                    ;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF;



    IF (NOT EXISTS (SELECT
        *
        FROM sys.sysjobsteps
        WHERE (job_id = par_job_id) AND (step_id = par_step_id))) THEN
        SELECT
            CAST (par_step_id AS VARCHAR(10))
            INTO var_step_id_as_char;
        RAISE 'Error %, severity %, state % was raised. Message: %. Argument: %. Argument: %', '50000', 0, 0, 'The specified %s ("%s") does not exist.', '@step_id', var_step_id_as_char USING ERRCODE := '50000';
        ReturnCode := (1);
        RETURN;

    END IF;

    SELECT
        step_name, subsystem, command, flags, cmdexec_success_code, on_success_action, on_success_step_id, on_fail_action, on_fail_step_id, server, database_name, database_user_name, retry_attempts, retry_interval, os_run_priority, output_file_name, proxy_id, last_run_outcome, last_run_duration, last_run_retries, last_run_date, last_run_time
        INTO var_x_step_name, var_x_subsystem, var_x_command, var_x_flags, var_x_cmdexec_success_code, var_x_on_success_action, var_x_on_success_step_id, var_x_on_fail_action, var_x_on_fail_step_id, var_x_server, var_x_database_name, var_x_database_user_name, var_x_retry_attempts, var_x_retry_interval, var_x_os_run_priority, var_x_output_file_name, var_x_proxy_id, var_x_last_run_outcome, var_x_last_run_duration, var_x_last_run_retries, var_x_last_run_date, var_x_last_run_time
        FROM sys.sysjobsteps
        WHERE (job_id = par_job_id) AND (step_id = par_step_id);

    IF ((par_step_name IS NOT NULL) AND (par_step_name <> var_x_step_name)) THEN
        SELECT
            par_step_name
            INTO var_new_step_name;
    END IF;


    IF (par_step_name IS NULL) THEN
        SELECT var_x_step_name INTO par_step_name;
    END IF;

    IF (par_subsystem IS NULL) THEN
        SELECT var_x_subsystem INTO par_subsystem;
    END IF;

    IF (par_command IS NULL) THEN
        SELECT var_x_command INTO par_command;
    END IF;

    IF (par_flags IS NULL) THEN
        SELECT var_x_flags INTO par_flags;
    END IF;

    IF (par_cmdexec_success_code IS NULL) THEN
        SELECT var_x_cmdexec_success_code INTO par_cmdexec_success_code;
    END IF;

    IF (par_on_success_action IS NULL) THEN
        SELECT var_x_on_success_action INTO par_on_success_action;
    END IF;

    IF (par_on_success_step_id IS NULL) THEN
        SELECT var_x_on_success_step_id INTO par_on_success_step_id;
    END IF;

    IF (par_on_fail_action IS NULL) THEN
        SELECT var_x_on_fail_action INTO par_on_fail_action;
    END IF;

    IF (par_on_fail_step_id IS NULL) THEN
        SELECT var_x_on_fail_step_id INTO par_on_fail_step_id;
    END IF;

    IF (par_server IS NULL) THEN
        SELECT var_x_server INTO par_server;
    END IF;

    IF (par_database_name IS NULL) THEN
        SELECT var_x_database_name INTO par_database_name;
    END IF;

    IF (par_database_user_name IS NULL) THEN
        SELECT var_x_database_user_name INTO par_database_user_name;
    END IF;

    IF (par_retry_attempts IS NULL) THEN
        SELECT var_x_retry_attempts INTO par_retry_attempts;
    END IF;

    IF (par_retry_interval IS NULL) THEN
        SELECT var_x_retry_interval INTO par_retry_interval;
    END IF;

    IF (par_os_run_priority IS NULL) THEN
        SELECT var_x_os_run_priority INTO par_os_run_priority;
    END IF;

    IF (par_output_file_name IS NULL) THEN
        SELECT var_x_output_file_name INTO par_output_file_name;
    END IF;

    IF (par_proxy_id IS NULL) THEN
        SELECT var_x_proxy_id INTO var_new_proxy_id;
    END IF;


    IF par_proxy_name = '' THEN
        SELECT NULL INTO var_new_proxy_id;
    END IF;


    IF (LOWER(par_command) = LOWER('')) THEN
        SELECT NULL INTO par_command;
    END IF;

    IF (par_server = '') THEN
        SELECT NULL INTO par_server;
    END IF;

    IF (par_database_name = '') THEN
        SELECT NULL INTO par_database_name;
    END IF;

    IF (par_database_user_name = '') THEN
        SELECT NULL INTO par_database_user_name;
    END IF;

    IF (LOWER(par_output_file_name) = LOWER('')) THEN
        SELECT NULL INTO par_output_file_name;
    END IF
                          ;
    SELECT
        t.par_database_name, t.par_database_user_name, t.ReturnCode
        FROM sys.babelfish_sp_verify_jobstep(par_job_id, par_step_id, var_new_step_name, par_subsystem, par_command, par_server, par_on_success_action, par_on_success_step_id, par_on_fail_action, par_on_fail_step_id, par_os_run_priority, par_database_name, par_database_user_name, par_flags, par_output_file_name, var_new_proxy_id) t
        INTO par_database_name, par_database_user_name, var_retval;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF

                                                            ;
    UPDATE sys.sysjobs
    SET version_number = version_number + 1

        WHERE (job_id = par_job_id)
                         ;
    UPDATE sys.sysjobsteps
    SET step_name = par_step_name, subsystem = par_subsystem, command = par_command, flags = par_flags, additional_parameters = par_additional_parameters, cmdexec_success_code = par_cmdexec_success_code, on_success_action = par_on_success_action, on_success_step_id = par_on_success_step_id, on_fail_action = par_on_fail_action, on_fail_step_id = par_on_fail_step_id, server = par_server, database_name = par_database_name, database_user_name = par_database_user_name, retry_attempts = par_retry_attempts, retry_interval = par_retry_interval, os_run_priority = par_os_run_priority, output_file_name = par_output_file_name, last_run_outcome = var_x_last_run_outcome, last_run_duration = var_x_last_run_duration, last_run_retries = var_x_last_run_retries, last_run_date = var_x_last_run_date, last_run_time = var_x_last_run_time, proxy_id = var_new_proxy_id
        WHERE (job_id = par_job_id) AND (step_id = par_step_id);

    SELECT step_uid
    FROM sys.sysjobsteps
    WHERE job_id = par_job_id AND step_id = par_step_id
    INTO var_step_uid;

    -- PERFORM sys.sp_jobstep_create_proc (var_step_uid);

    ReturnCode := (0);
    RETURN
                 ;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_update_schedule (
  par_schedule_id integer = NULL::integer,
  par_name varchar = NULL::character varying,
  par_new_name varchar = NULL::character varying,
  par_enabled smallint = NULL::smallint,
  par_freq_type integer = NULL::integer,
  par_freq_interval integer = NULL::integer,
  par_freq_subday_type integer = NULL::integer,
  par_freq_subday_interval integer = NULL::integer,
  par_freq_relative_interval integer = NULL::integer,
  par_freq_recurrence_factor integer = NULL::integer,
  par_active_start_date integer = NULL::integer,
  par_active_end_date integer = NULL::integer,
  par_active_start_time integer = NULL::integer,
  par_active_end_time integer = NULL::integer,
  par_owner_login_name varchar = NULL::character varying,
  par_automatic_post smallint = 1,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
    var_retval INT;
    var_owner_sid CHAR(85);
    var_cur_owner_sid CHAR(85);
    var_x_name VARCHAR(128);
    var_enable_only_used INT;
    var_x_enabled SMALLINT;
    var_x_freq_type INT;
    var_x_freq_interval INT;
    var_x_freq_subday_type INT;
    var_x_freq_subday_interval INT;
    var_x_freq_relative_interval INT;
    var_x_freq_recurrence_factor INT;
    var_x_active_start_date INT;
    var_x_active_end_date INT;
    var_x_active_start_time INT;
    var_x_active_end_time INT;
    var_schedule_uid CHAR(38);
BEGIN

    SELECT
        LTRIM(RTRIM(par_name))
        INTO par_name;
    SELECT
        LTRIM(RTRIM(par_new_name))
        INTO par_new_name;
    SELECT
        LTRIM(RTRIM(par_owner_login_name))
        INTO par_owner_login_name
                                                            ;

    IF (par_new_name = '') THEN
        SELECT
            NULL
            INTO par_new_name;
    END IF
                                                                                                                     ;
    SELECT
        t.par_schedule_name, t.par_schedule_id, t.par_owner_sid, t.par_orig_server_id, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule_identifiers('@name'
                                     , '@schedule_id'
                                   , par_name
                            , par_schedule_id
                          , var_cur_owner_sid
                        , NULL
                             , NULL) t
        INTO par_name, par_schedule_id, var_cur_owner_sid, var_retval
                        ;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF

                                                                      ;

    IF ((par_enabled IS NOT NULL) AND (par_new_name IS NULL) AND (par_freq_type IS NULL) AND (par_freq_interval IS NULL) AND (par_freq_subday_type IS NULL) AND (par_freq_subday_interval IS NULL) AND (par_freq_relative_interval IS NULL) AND (par_freq_recurrence_factor IS NULL) AND (par_active_start_date IS NULL) AND (par_active_end_date IS NULL) AND (par_active_start_time IS NULL) AND (par_active_end_time IS NULL) AND (par_owner_login_name IS NULL)) THEN
        SELECT
            1
            INTO var_enable_only_used;
    ELSE
        SELECT
            0
            INTO var_enable_only_used;
    END IF
                                                                                                                                   ;

    IF (var_owner_sid IS NULL) THEN
        SELECT
            var_cur_owner_sid
            INTO var_owner_sid;
    END IF
                                         ;
    SELECT
        name, enabled, freq_type, freq_interval, freq_subday_type, freq_subday_interval, freq_relative_interval, freq_recurrence_factor, active_start_date, active_end_date, active_start_time, active_end_time
        INTO var_x_name, var_x_enabled, var_x_freq_type, var_x_freq_interval, var_x_freq_subday_type, var_x_freq_subday_interval, var_x_freq_relative_interval, var_x_freq_recurrence_factor, var_x_active_start_date, var_x_active_end_date, var_x_active_start_time, var_x_active_end_time
        FROM sys.sysschedules
        WHERE (schedule_id = par_schedule_id)
                                                                                      ;

    IF (par_new_name IS NULL) THEN
        SELECT
            var_x_name
            INTO par_new_name;
    END IF;

    IF (par_enabled IS NULL) THEN
        SELECT
            var_x_enabled
            INTO par_enabled;
    END IF;

    IF (par_freq_type IS NULL) THEN
        SELECT
            var_x_freq_type
            INTO par_freq_type;
    END IF;

    IF (par_freq_interval IS NULL) THEN
        SELECT
            var_x_freq_interval
            INTO par_freq_interval;
    END IF;

    IF (par_freq_subday_type IS NULL) THEN
        SELECT
            var_x_freq_subday_type
            INTO par_freq_subday_type;
    END IF;

    IF (par_freq_subday_interval IS NULL) THEN
        SELECT
            var_x_freq_subday_interval
            INTO par_freq_subday_interval;
    END IF;

    IF (par_freq_relative_interval IS NULL) THEN
        SELECT
            var_x_freq_relative_interval
            INTO par_freq_relative_interval;
    END IF;

    IF (par_freq_recurrence_factor IS NULL) THEN
        SELECT
            var_x_freq_recurrence_factor
            INTO par_freq_recurrence_factor;
    END IF;

    IF (par_active_start_date IS NULL) THEN
        SELECT
            var_x_active_start_date
            INTO par_active_start_date;
    END IF;

    IF (par_active_end_date IS NULL) THEN
        SELECT
            var_x_active_end_date
            INTO par_active_end_date;
    END IF;

    IF (par_active_start_time IS NULL) THEN
        SELECT
            var_x_active_start_time
            INTO par_active_start_time;
    END IF;

    IF (par_active_end_time IS NULL) THEN
        SELECT
            var_x_active_end_time
            INTO par_active_end_time;
    END IF
                                                         ;
    SELECT
        t.par_freq_interval, t.par_freq_subday_type, t.par_freq_subday_interval, t.par_freq_relative_interval, t.par_freq_recurrence_factor, t.par_active_start_date,
        t.par_active_start_time, t.par_active_end_date, t.par_active_end_time, t.ReturnCode
        FROM sys.babelfish_sp_verify_schedule(par_schedule_id
                          , par_new_name
                   , par_enabled
                      , par_freq_type
                        , par_freq_interval
                            , par_freq_subday_type
                               , par_freq_subday_interval
                                   , par_freq_relative_interval
                                     , par_freq_recurrence_factor
                                     , par_active_start_date
                                , par_active_start_time
                                , par_active_end_date
                              , par_active_end_time
                              , var_owner_sid) t
        INTO par_freq_interval, par_freq_subday_type, par_freq_subday_interval, par_freq_relative_interval, par_freq_recurrence_factor, par_active_start_date, par_active_start_time, par_active_end_date, par_active_end_time, var_retval ;

    IF (var_retval <> 0) THEN
        ReturnCode := (1);
        RETURN;
    END IF

                                       ;
    UPDATE sys.sysschedules
    SET name = par_new_name, owner_sid = var_owner_sid, enabled = par_enabled, freq_type = par_freq_type, freq_interval = par_freq_interval, freq_subday_type = par_freq_subday_type, freq_subday_interval = par_freq_subday_interval, freq_relative_interval = par_freq_relative_interval, freq_recurrence_factor = par_freq_recurrence_factor, active_start_date = par_active_start_date, active_end_date = par_active_end_date, active_start_time = par_active_start_time, active_end_time = par_active_end_time
                                             , version_number = version_number + 1
        WHERE (schedule_id = par_schedule_id);
    SELECT
        0
        INTO var_retval;

    ReturnCode := (var_retval);
    RETURN
                         ;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job (
  par_job_id integer,
  par_name varchar,
  par_enabled smallint,
  par_start_step_id integer,
  par_category_name varchar,
  inout par_owner_sid char,
  par_notify_level_eventlog integer,
  inout par_notify_level_email integer,
  inout par_notify_level_netsend integer,
  inout par_notify_level_page integer,
  par_notify_email_operator_name varchar,
  par_notify_netsend_operator_name varchar,
  par_notify_page_operator_name varchar,
  par_delete_level integer,
  inout par_category_id integer,
  inout par_notify_email_operator_id integer,
  inout par_notify_netsend_operator_id integer,
  inout par_notify_page_operator_id integer,
  inout par_originating_server varchar,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_job_type INT;
  var_retval INT;
  var_current_date INT;
  var_res_valid_range VARCHAR(200);
  var_max_step_id INT;
  var_valid_range VARCHAR(50);
BEGIN

  SELECT LTRIM(RTRIM(par_name)) INTO par_name;
  SELECT LTRIM(RTRIM(par_category_name)) INTO par_category_name;
  SELECT UPPER(LTRIM(RTRIM(par_originating_server))) INTO par_originating_server;

  IF (
    EXISTS (
      SELECT *
        FROM sys.sysjobs AS job
       WHERE (name = par_name)

    )
  )
  THEN
    RAISE 'The specified % ("%") already exists.', 'par_name', par_name USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;


  IF (par_enabled <> 0) AND (par_enabled <> 1) THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'par_enabled', '0, 1' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;



  IF (par_job_id IS NULL) THEN
    IF (par_start_step_id <> 1) THEN
      RAISE 'The specified "%" is invalid (valid values are: %).', 'par_start_step_id', '1' USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
    END IF;
  ELSE

    SELECT COALESCE(MAX(step_id), 0)
      INTO var_max_step_id
      FROM sys.sysjobsteps
     WHERE (job_id = par_job_id);

    IF (par_start_step_id < 1) OR (par_start_step_id > var_max_step_id + 1) THEN
      SELECT '1..' || CAST (var_max_step_id + 1 AS VARCHAR(1))
        INTO var_valid_range;
      RAISE 'The specified "%" is invalid (valid values are: %).', 'par_start_step_id', var_valid_range USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;


  SELECT NULL INTO par_category_id;

  IF (par_category_name = '[DEFAULT]')
  THEN
    SELECT
      CASE COALESCE(var_job_type, 1)
        WHEN 1 THEN 0
        WHEN 2 THEN 2
      END
      INTO par_category_id;
  ELSE
    SELECT 0 INTO par_category_id;
  END IF;

  returncode := (0);
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_date (
  par_date integer,
  par_date_name varchar = 'date'::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
BEGIN

  SELECT LTRIM(RTRIM(par_date_name)) INTO par_date_name;


  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_job_name varchar,
  inout par_job_id integer,
  par_sqlagent_starting_test varchar = 'TEST'::character varying,
  inout par_owner_sid char = NULL::bpchar,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_retval INT;
  var_job_id_as_char VARCHAR(36);
BEGIN

  SELECT LTRIM(RTRIM(par_name_of_name_parameter)) INTO par_name_of_name_parameter;
  SELECT LTRIM(RTRIM(par_name_of_id_parameter)) INTO par_name_of_id_parameter;
  SELECT LTRIM(RTRIM(par_job_name)) INTO par_job_name;

  IF (par_job_name = '')
  THEN
    SELECT NULL INTO par_job_name;
  END IF;

  IF ((par_job_name IS NULL) AND (par_job_id IS NULL)) OR ((par_job_name IS NOT NULL) AND (par_job_id IS NOT NULL))
  THEN
    RAISE 'Supply either % or % to identify the job.', par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_job_id IS NOT NULL)
  THEN
    SELECT name
         , owner_sid
      INTO par_job_name
         , par_owner_sid
      FROM sys.sysjobs
     WHERE (job_id = par_job_id);


    IF (par_job_name IS NULL)
    THEN
      SELECT CAST (par_job_id AS VARCHAR(36))
        INTO var_job_id_as_char;

      RAISE 'The specified % ("%") does not exist.', 'job_id', var_job_id_as_char USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  ELSE

    IF (par_job_name IS NOT NULL)
    THEN

      IF (SELECT COUNT(*) FROM sys.sysjobs WHERE name = par_job_name) > 1
      THEN
        RAISE 'There are two or more jobs named "%". Specify % instead of % to uniquely identify the job.', par_job_name, par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;


      SELECT job_id
           , owner_sid
        INTO par_job_id
           , par_owner_sid
        FROM sys.sysjobs
       WHERE (name = par_job_name);


      IF (par_job_id IS NULL)
      THEN
        RAISE 'The specified % ("%") does not exist.', 'job_name', par_job_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;
  END IF;


  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_job_time (
  par_time integer,
  par_time_name varchar = 'time'::character varying,
  out returncode integer
)
RETURNS integer AS
$body$
DECLARE
  var_hour INT;
  var_minute INT;
  var_second INT;
BEGIN

  SELECT LTRIM(RTRIM(par_time_name)) INTO par_time_name;

  IF ((par_time < 0) OR (par_time > 235959))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', par_time_name, '000000..235959' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  SELECT (par_time / 10000) INTO var_hour;
  SELECT (par_time % 10000) / 100 INTO var_minute;
  SELECT (par_time % 100) INTO var_second;


  IF (var_hour > 23) THEN
    RAISE 'The "%" supplied has an invalid %.', par_time_name, 'hour' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (var_minute > 59) THEN
    RAISE 'The "%" supplied has an invalid %.', par_time_name, 'minute' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (var_second > 59) THEN
     RAISE 'The "%" supplied has an invalid %.', par_time_name, 'second' USING ERRCODE := '50000';
     returncode := 1;
     RETURN;
  END IF;

  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_jobstep (
  par_job_id integer,
  par_step_id integer,
  par_step_name varchar,
  par_subsystem varchar,
  par_command text,
  par_server varchar,
  par_on_success_action smallint,
  par_on_success_step_id integer,
  par_on_fail_action smallint,
  par_on_fail_step_id integer,
  par_os_run_priority integer,
  par_flags integer,
  par_output_file_name varchar,
  par_proxy_id integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_max_step_id INT;
  var_retval INT;
  var_valid_values VARCHAR(50);
  var_database_name_temp VARCHAR(258);
  var_database_user_name_temp VARCHAR(256);
  var_temp_command TEXT;
  var_iPos INT;
  var_create_count INT;
  var_destroy_count INT;
  var_is_olap_subsystem SMALLINT;
  var_owner_sid CHAR(85);
  var_owner_name VARCHAR(128);
BEGIN

  SELECT LTRIM(RTRIM(par_subsystem)) INTO par_subsystem;
  SELECT LTRIM(RTRIM(par_server)) INTO par_server;
  SELECT LTRIM(RTRIM(par_output_file_name)) INTO par_output_file_name;


  SELECT COALESCE(MAX(step_id), 0)
    INTO var_max_step_id
    FROM sys.sysjobsteps
   WHERE (job_id = par_job_id);


  IF (par_step_id < 1) OR (par_step_id > var_max_step_id + 1)
  THEN
    SELECT '1..' || CAST (var_max_step_id + 1 AS VARCHAR(1)) INTO var_valid_values;
      RAISE 'The specified "%" is invalid (valid values are: %).', '@step_id', var_valid_values USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;


  IF (
    EXISTS (
      SELECT *
        FROM sys.sysjobsteps
       WHERE (job_id = par_job_id) AND (step_name = par_step_name)
    )
  )
  THEN
    RAISE 'The specified % ("%") already exists.', 'step_name', par_step_name USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_on_success_action <> 1)
    AND (par_on_success_action <> 2)
    AND (par_on_success_action <> 3)
    AND (par_on_success_action <> 4)
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'on_success_action', '1, 2, 3, 4' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_on_success_action = 4) AND ((par_on_success_step_id < 1) OR (par_on_success_step_id = par_step_id))
  THEN
    RAISE 'The specified "%" is invalid (valid values are greater than 0 but excluding %ld).', 'on_success_step', par_step_id USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_on_fail_action <> 1)
    AND (par_on_fail_action <> 2)
    AND (par_on_fail_action <> 3)
    AND (par_on_fail_action <> 4)
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'on_failure_action', '1, 2, 3, 4' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_on_fail_action = 4) AND ((par_on_fail_step_id < 1) OR (par_on_fail_step_id = par_step_id))
  THEN
    RAISE 'The specified "%" is invalid (valid values are greater than 0 but excluding %).', 'on_failure_step', par_step_id USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF ((par_on_success_action = 4) AND (par_on_success_step_id > var_max_step_id))
  THEN
    RAISE 'Warning: Non-existent step referenced by %.', 'on_success_step_id' USING ERRCODE := '50000';
  END IF;

  IF ((par_on_fail_action = 4) AND (par_on_fail_step_id > var_max_step_id))
  THEN
    RAISE 'Warning: Non-existent step referenced by %.', '@on_fail_step_id' USING ERRCODE := '50000';
  END IF;



  IF (par_os_run_priority NOT IN (- 15, - 1, 0, 1, 15))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', '@os_run_priority', '-15, -1, 0, 1, 15' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF ((par_flags < 0) OR (par_flags > 114)) THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', '@flags', '0..114' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (LOWER(UPPER(par_subsystem)) <> LOWER('TSQL')) THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', '@subsystem', 'TSQL' USING ERRCODE := '50000';
    returncode := (1);
    RETURN;
  END IF;


  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_schedule (
  par_schedule_id integer,
  par_name varchar,
  par_enabled smallint,
  par_freq_type integer,
  inout par_freq_interval integer,
  inout par_freq_subday_type integer,
  inout par_freq_subday_interval integer,
  inout par_freq_relative_interval integer,
  inout par_freq_recurrence_factor integer,
  inout par_active_start_date integer,
  inout par_active_start_time integer,
  inout par_active_end_date integer,
  inout par_active_end_time integer,
  par_owner_sid char,
  out returncode integer
)
RETURNS record AS
$body$
DECLARE
  var_return_code INT;
  var_isAdmin INT;
BEGIN

  SELECT LTRIM(RTRIM(par_name)) INTO par_name;


  SELECT COALESCE(par_freq_interval, 0) INTO par_freq_interval;
  SELECT COALESCE(par_freq_subday_type, 0) INTO par_freq_subday_type;
  SELECT COALESCE(par_freq_subday_interval, 0) INTO par_freq_subday_interval;
  SELECT COALESCE(par_freq_relative_interval, 0) INTO par_freq_relative_interval;
  SELECT COALESCE(par_freq_recurrence_factor, 0) INTO par_freq_recurrence_factor;
  SELECT COALESCE(par_active_start_date, 0) INTO par_active_start_date;
  SELECT COALESCE(par_active_start_time, 0) INTO par_active_start_time;
  SELECT COALESCE(par_active_end_date, 0) INTO par_active_end_date;
  SELECT COALESCE(par_active_end_time, 0) INTO par_active_end_time;


  SELECT 0 INTO var_isAdmin;

  IF (
    EXISTS (
      SELECT *
        FROM sys.sysschedules
       WHERE (name = par_name)
    )
  )
  THEN
    RAISE 'The specified % ("%") already exists.', 'par_name', par_name USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  IF (UPPER(par_name) = 'ALL')
  THEN
    RAISE 'The specified "%" is invalid.', 'name' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_enabled <> 0) AND (par_enabled <> 1)
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', '@enabled', '0, 1' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_freq_type = 2)
  THEN
    RAISE 'Frequency Type 0x2 (OnDemand) is no longer supported.' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_freq_type NOT IN (1, 4, 8, 16, 32, 64, 128))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'freq_type', '1, 4, 8, 16, 32, 64, 128' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_freq_subday_type <> 0) AND (par_freq_subday_type NOT IN (1, 2, 4, 8))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'freq_subday_type', '1, 2, 4, 8' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_active_start_date = 0)
  THEN
    SELECT date_part('year', NOW()::TIMESTAMP) * 10000 + date_part('month', NOW()::TIMESTAMP) * 100 + date_part('day', NOW()::TIMESTAMP)
      INTO par_active_start_date;
  END IF;


  IF (par_active_end_date = 0)
  THEN

    SELECT 99991231 INTO par_active_end_date;
  END IF;

  IF (par_active_start_time = 0)
  THEN

    SELECT 000000 INTO par_active_start_time;
  END IF;

  IF (par_active_end_time = 0)
  THEN

    SELECT 235959 INTO par_active_end_time;
  END IF;


  IF (par_active_end_date = 0)
  THEN
    SELECT 99991231 INTO par_active_end_date;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_date(par_active_end_date, 'active_end_date') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_date(par_active_start_date, '@active_start_date') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;

  IF (par_active_end_date < par_active_start_date)
  THEN
    RAISE '% cannot be before %.', 'active_end_date', 'active_start_date' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_time(par_active_end_time, '@active_end_time') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;

  SELECT t.returncode
    FROM sys.babelfish_sp_verify_job_time(par_active_start_time, '@active_start_time') t
    INTO var_return_code;

  IF (var_return_code <> 0)
  THEN
    returncode := 1;
    RETURN;
  END IF;

  IF (par_active_start_time = par_active_end_time AND (par_freq_subday_type IN (2, 4, 8)))
  THEN
    RAISE 'The specified "%" is invalid (valid values are: %).', 'active_end_time', 'before or after active_start_time' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF ((par_freq_type = 1)
    OR (par_freq_type = 64)
    OR (par_freq_type = 128))
  THEN
    SELECT 0 INTO par_freq_interval;
    SELECT 0 INTO par_freq_subday_type;
    SELECT 0 INTO par_freq_subday_interval;
    SELECT 0 INTO par_freq_relative_interval;
    SELECT 0 INTO par_freq_recurrence_factor;

    returncode := 0;
    RETURN;
  END IF;

  IF (par_freq_subday_type = 0)
  THEN
    SELECT 1 INTO par_freq_subday_type;
  END IF;

  IF ((par_freq_subday_type <> 1)
    AND (par_freq_subday_type <> 2)
    AND (par_freq_subday_type <> 4)
    AND (par_freq_subday_type <> 8))
  THEN
    RAISE 'The schedule for this job is invalid (reason: The specified @freq_subday_type is invalid (valid values are: 0x1, 0x2, 0x4, 0x8).).' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF ((par_freq_subday_type <> 1) AND (par_freq_subday_interval < 1))
    OR ((par_freq_subday_type = 2) AND (par_freq_subday_interval < 10))
  THEN
    RAISE 'The schedule for this job is invalid (reason: The specified @freq_subday_interval is invalid).' USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;

  IF (par_freq_type = 4)
  THEN
    SELECT 0 INTO par_freq_recurrence_factor;

    IF (par_freq_interval < 1) THEN
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be at least 1 for a daily job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 8)
  THEN
    IF (par_freq_interval < 1) OR (par_freq_interval > 127)
    THEN
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be a valid day of the week bitmask [Sunday = 1 .. Saturday = 64] for a weekly job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 16)
  THEN
    IF (par_freq_interval < 1) OR (par_freq_interval > 31)
    THEN
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be between 1 and 31 for a monthly job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 32)
  THEN
    IF (par_freq_relative_interval <> 1)
      AND (par_freq_relative_interval <> 2)
      AND (par_freq_relative_interval <> 4)
      AND (par_freq_relative_interval <> 8)
      AND (par_freq_relative_interval <> 16)
    THEN
      RAISE 'The schedule for this job is invalid (reason: @freq_relative_interval must be one of 1st (0x1), 2nd (0x2), 3rd [0x4], 4th (0x8) or Last (0x10).).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF (par_freq_type = 32)
  THEN
    IF (par_freq_interval <> 1)
      AND (par_freq_interval <> 2)
      AND (par_freq_interval <> 3)
      AND (par_freq_interval <> 4)
      AND (par_freq_interval <> 5)
      AND (par_freq_interval <> 6)
      AND (par_freq_interval <> 7)
      AND (par_freq_interval <> 8)
      AND (par_freq_interval <> 9)
      AND (par_freq_interval <> 10)
    THEN
      RAISE 'The schedule for this job is invalid (reason: @freq_interval must be between 1 and 10 (1 = Sunday .. 7 = Saturday, 8 = Day, 9 = Weekday, 10 = Weekend-day) for a monthly-relative job.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  END IF;

  IF ((par_freq_type = 8)
    OR (par_freq_type = 16)
    OR (par_freq_type = 32))
    AND (par_freq_recurrence_factor < 1)
  THEN
    RAISE 'The schedule for this job is invalid (reason: @freq_recurrence_factor must be at least 1.).' USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
  END IF;

  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_verify_schedule_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_schedule_name varchar,
  inout par_schedule_id integer,
  inout par_owner_sid char,
  inout par_orig_server_id integer,
  par_job_id_filter integer = NULL::integer,
  out returncode integer
)
AS
$body$
DECLARE
  var_retval INT;
  var_schedule_id_as_char VARCHAR(36);
  var_sch_name_count INT;
BEGIN

  SELECT LTRIM(RTRIM(par_name_of_name_parameter)) INTO par_name_of_name_parameter;
  SELECT LTRIM(RTRIM(par_name_of_id_parameter)) INTO par_name_of_id_parameter;
  SELECT LTRIM(RTRIM(par_schedule_name)) INTO par_schedule_name;
  SELECT 0 INTO var_sch_name_count;

  IF (par_schedule_name = '')
  THEN
    SELECT NULL INTO par_schedule_name;
  END IF;

  IF ((par_schedule_name IS NULL) AND (par_schedule_id IS NULL)) OR ((par_schedule_name IS NOT NULL) AND (par_schedule_id IS NOT NULL))
  THEN
    RAISE 'Supply either % or % to identify the schedule.', par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
    returncode := 1;
    RETURN;
  END IF;


  IF (par_schedule_id IS NOT NULL)
  THEN

    SELECT name
         , owner_sid
         , originating_server_id
      INTO par_schedule_name
         , par_owner_sid
         , par_orig_server_id
      FROM sys.sysschedules
     WHERE (schedule_id = par_schedule_id);

    IF (par_schedule_name IS NULL)
    THEN
      SELECT CAST (par_schedule_id AS VARCHAR(36))
        INTO var_schedule_id_as_char;

      RAISE 'The specified % ("%") does not exist.', 'schedule_id', var_schedule_id_as_char USING ERRCODE := '50000';
      returncode := 1;
      RETURN;
    END IF;
  ELSE
    IF (par_schedule_name IS NOT NULL)
    THEN

      IF (SELECT COUNT(*) FROM sys.sysschedules WHERE name = par_schedule_name) > 1
      THEN
        RAISE 'There are two or more sysschedules named "%". Specify % instead of % to uniquely identify the sysschedules.', par_job_name, par_name_of_id_parameter, par_name_of_name_parameter USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;


      SELECT schedule_id
           , owner_sid
        INTO par_schedule_id, par_owner_sid
        FROM sys.sysschedules
       WHERE (name = par_schedule_name);


      IF (par_schedule_id IS NULL)
      THEN
        RAISE 'The specified % ("%") does not exist.', 'par_schedule_name', par_schedule_name USING ERRCODE := '50000';
        returncode := 1;
        RETURN;
      END IF;
    END IF;
  END IF;


  returncode := 0;
  RETURN;
END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_sp_xml_preparedocument(IN XmlDocument TEXT,OUT DocHandle BIGINT)
AS
$BODY$
DECLARE
   XmlDocument$data XML;
BEGIN

     CREATE TEMPORARY SEQUENCE IF NOT EXISTS sys$seq_openmxl_id MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 INCREMENT BY 1 CACHE 5;

     CREATE TEMPORARY TABLE IF NOT EXISTS sys$openxml
          (DocID BigInt NOT NULL DEFAULT NEXTVAL('sys$seq_openmxl_id'),
           XmlData XML not NULL,
           CONSTRAINT pk_sys$doc_id PRIMARY KEY(DocID)
          ) ON COMMIT PRESERVE ROWS;

     IF xml_is_well_formed(XmlDocument) THEN
       XmlDocument$data := XmlDocument::XML;
     ELSE
       RAISE EXCEPTION '%','The XML parse error occurred';
     END IF;

     INSERT INTO sys$openxml(XmlData)
          VALUES (XmlDocument$data)
       RETURNING DocID INTO DocHandle;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_sp_xml_removedocument(IN DocHandle BIGINT) RETURNS VOID
AS
$BODY$
DECLARE
  lt_error_text TEXT := 'Could not find prepared statement with handle '||CASE
                                                                            WHEN DocHandle IS NULL THEN 'null'
                                                                              ELSE DocHandle::TEXT
                                                                           END;
BEGIN
 DELETE FROM sys$openxml t
  WHERE t.DocID = DocHandle;

 IF NOT FOUND THEN
      RAISE EXCEPTION '%', lt_error_text;
 END IF;

 EXCEPTION
   WHEN SQLSTATE '42P01' THEN
       RAISE EXCEPTION '%',lt_error_text;
END;
$BODY$
LANGUAGE plpgsql;





create or replace function sys.babelfish_STRPOS3(p_str text, p_substr text, p_loc int)returns int
AS
$body$
DECLARE
 v_loc int := case when p_loc > 0 then p_loc else 1 end;
 v_cnt int := length(p_str) - v_loc + 1;
BEGIN



 if v_cnt > 0 then
  return case when 0!= strpos(substr(p_str, v_loc, v_cnt), p_substr)
              then strpos(substr(p_str, v_loc, v_cnt), p_substr) + v_loc - 1
             else strpos(substr(p_str, v_loc, v_cnt), p_substr)
         end;
 else
  return 0;
 end if;
END;
$body$
language plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_tomsbit(in_str NUMERIC)
RETURNS SMALLINT
AS
$BODY$
BEGIN
  CASE
    WHEN in_str < 0 OR in_str > 0 THEN RETURN 1;
    ELSE RETURN 0;
  END CASE;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_tomsbit(in_str VARCHAR)
RETURNS SMALLINT
AS
$BODY$
BEGIN
  CASE
    WHEN LOWER(in_str) = 'true' OR in_str = '1' THEN RETURN 1;
    WHEN LOWER(in_str) = 'false' OR in_str = '0' THEN RETURN 0;
    ELSE RETURN 0;
  END CASE;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_date_to_string(IN p_datatype TEXT,
                                                                     IN p_dateval DATE,
                                                                     IN p_style NUMERIC DEFAULT 20)
RETURNS TEXT
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_date_to_string(p_datatype,
                                                 p_dateval,
                                                 p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_datetime_to_string(IN p_datatype TEXT,
                                                                         IN p_src_datatype TEXT,
                                                                         IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE,
                                                                         IN p_style NUMERIC DEFAULT -1)
RETURNS TEXT
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_datetime_to_string(p_datatype,
                                                     p_src_datatype,
                                                     p_datetimeval,
                                                     p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_date(IN p_datestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_date(p_datestring,
                                                 p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetime(IN p_datatype TEXT,
                                                                         IN p_datetimestring TEXT,
                                                                         IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetime(p_datatype,
                                                     p_datetimestring ,
                                                     p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_time(IN p_datatype TEXT,
                                                                     IN p_timestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_time(p_datatype,
                                                 p_timestring,
                                                 p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_time_to_string(IN p_datatype TEXT,
                                                                     IN p_src_datatype TEXT,
                                                                     IN p_timeval TIME WITHOUT TIME ZONE,
                                                                     IN p_style NUMERIC DEFAULT 25)
RETURNS TEXT
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_time_to_string(p_datatype,
                                                 p_src_datatype,
                                                 p_timeval,
                                                 p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

-- convertion to date
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_date(arg, p_style);
    ELSE
     RETURN sys.babelfish_conv_string_to_date(arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg anyelement,
                                                        IN try BOOL,
                    IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_date(arg);
    ELSE
     RETURN CAST(arg AS DATE);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_date(IN arg anyelement)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN CAST(arg AS DATE);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- convertion to time
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN arg TEXT,
                                                        IN try BOOL,
                    IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    IF try THEN
     RETURN sys.babelfish_try_conv_string_to_time('TIME', arg, p_style);
    ELSE
     RETURN sys.babelfish_conv_string_to_time('TIME', arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN arg anyelement,
                                                        IN try BOOL,
                    IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_time(arg);
    ELSE
     RETURN CAST(arg AS TIME);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_time(IN arg anyelement)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS TIME);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- convertion to datetime
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg TEXT,
                                                            IN try BOOL,
                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP
AS
$BODY$
BEGIN
    IF try THEN
     RETURN sys.babelfish_try_conv_string_to_datetime('DATETIME', arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime('DATETIME', arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg anyelement,
                                                            IN try BOOL,
                     IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_to_datetime(arg);
    ELSE
        RETURN CAST(arg AS TIMESTAMP);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;


CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement)
RETURNS TIMESTAMP
AS
$BODY$
BEGIN
    RETURN CAST(arg AS TIMESTAMP);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

-- convertion to varchar
CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
 IF try THEN
     RETURN sys.babelfish_try_conv_to_varchar(typename, arg, p_style);
    ELSE
     RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg ANYELEMENT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
 IF try THEN
     RETURN sys.babelfish_try_conv_to_varchar(typename, arg, p_style);
    ELSE
     RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
              IN arg TEXT,
              IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.VARCHAR);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
              IN arg anyelement,
              IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
 CASE pg_typeof(arg)
 WHEN 'date'::regtype THEN
  RETURN sys.babelfish_try_conv_date_to_string(typename, arg, p_style);
 WHEN 'time'::regtype THEN
  RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg, p_style);
 WHEN 'sys.datetime'::regtype THEN
  RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp, p_style);
 WHEN 'float'::regtype THEN
  RETURN sys.babelfish_try_conv_float_to_string(typename, arg, p_style);
 WHEN 'sys.money'::regtype THEN
  RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4)::pg_catalog.money, p_style);
 ELSE
        RETURN CAST(arg AS sys.VARCHAR);
 END CASE;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT,
              IN arg TEXT,
              IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT,
              IN arg anyelement,
              IN p_style NUMERIC DEFAULT 0)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_to_varchar(typename, arg, p_style);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_helper_to_date(IN arg TEXT, IN try BOOL, IN culture TEXT DEFAULT '')
RETURNS DATE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_parse_to_date(arg, culture);
    ELSE
        RETURN sys.babelfish_parse_to_date(arg, culture);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_helper_to_time(IN arg TEXT, IN try BOOL, IN culture TEXT DEFAULT '')
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_parse_to_time('TIME', arg, culture);
    ELSE
        RETURN sys.babelfish_parse_to_time('TIME', arg, culture);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_parse_helper_to_datetime(IN arg TEXT, IN try BOOL, IN culture TEXT DEFAULT '')
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_parse_to_datetime('DATETIME', arg, culture);
    ELSE
        RETURN sys.babelfish_parse_to_datetime('DATETIME', arg, culture);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT,
              IN p_moneyval PG_CATALOG.MONEY,
              IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
 v_style SMALLINT;
 v_format VARCHAR;
 v_moneyval NUMERIC(19,4) := p_moneyval::NUMERIC(19,4);
 v_moneysign NUMERIC(19,4) := sign(v_moneyval);
 v_moneyabs NUMERIC(19,4) := abs(v_moneyval);
 v_digits SMALLINT;
 v_integral_digits SMALLINT;
 v_decimal_digits SMALLINT;
 v_res_length SMALLINT;
 MASK_REGEXP CONSTANT VARCHAR := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
 v_result TEXT;
BEGIN
 v_style := floor(p_style)::SMALLINT;
 v_digits := length(v_moneyabs::TEXT);
 v_decimal_digits := scale(v_moneyabs);
 IF (v_decimal_digits > 0) THEN
  v_integral_digits := v_digits - v_decimal_digits - 1;
 ELSE
  v_integral_digits := v_digits;
 END IF;
 IF (v_style = 0) THEN
  v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D99';
  v_result := to_char(v_moneyval, v_format);
 ELSIF (v_style = 1) THEN
  IF (v_moneysign::SMALLINT = 1) THEN
   v_result := substring(p_moneyval::TEXT, 2);
  ELSE
   v_result := substring(p_moneyval::TEXT, 1, 1) || substring(p_moneyval::TEXT, 3);
  END IF;
 ELSIF (v_style = 2) THEN
  v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D9999';
  v_result := to_char(v_moneyval, v_format);
 ELSE
  RAISE invalid_parameter_value;
 END IF;
 v_res_length := substring(p_datatype, MASK_REGEXP)::SMALLINT;
 IF v_res_length IS NULL THEN
  RETURN v_result;
 ELSE
  RETURN rpad(v_result, v_res_length, ' ');
 END IF;
EXCEPTION
 WHEN invalid_parameter_value THEN
  RAISE USING MESSAGE := format('%s is not a valid style number when converting from MONEY to a character string.', v_style),
     DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
     HINT := 'Change "style" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT,
                IN p_floatval FLOAT,
                IN p_style NUMERIC DEFAULT 0)
RETURNS TEXT
AS
$BODY$
DECLARE
 v_style SMALLINT;
 v_format VARCHAR;
 v_floatval NUMERIC := abs(p_floatval);
 v_digits SMALLINT;
 v_integral_digits SMALLINT;
 v_decimal_digits SMALLINT;
 v_sign SMALLINT := sign(p_floatval);
 v_result TEXT;
 v_res_length SMALLINT;
 MASK_REGEXP CONSTANT VARCHAR := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
BEGIN
 v_style := floor(p_style)::SMALLINT;
 IF (v_style = 0) THEN
  v_digits := length(v_floatval::NUMERIC::TEXT);
  v_decimal_digits := scale(v_floatval);
  IF (v_decimal_digits > 0) THEN
   v_integral_digits := v_digits - v_decimal_digits - 1;
  ELSE
   v_integral_digits := v_digits;
  END IF;
  IF (v_floatval >= 999999.5) THEN
   v_format := '9D99999EEEE';
   v_result := to_char(v_sign * ceiling(v_floatval), v_format);
   v_result := to_char(substring(v_result, 1, 8)::NUMERIC, 'FM9D99999')::NUMERIC::TEXT || substring(v_result, 9);
  ELSE
   if (6 - v_integral_digits < v_decimal_digits) THEN
    v_decimal_digits := 6 - v_integral_digits;
   END IF;
   v_format := (pow(10, v_integral_digits)-1)::TEXT || 'D';
   IF (v_decimal_digits > 0) THEN
    v_format := v_format || (pow(10, v_decimal_digits)-1)::TEXT;
   END IF;
   v_result := to_char(p_floatval, v_format);
  END IF;
 ELSIF (v_style = 1) THEN
  v_format := '9D9999999EEEE';
  v_result := to_char(p_floatval, v_format);
 ELSIF (v_style = 2) THEN
  v_format := '9D999999999999999EEEE';
  v_result := to_char(p_floatval, v_format);
 ELSIF (v_style = 3) THEN
  v_format := '9D9999999999999999EEEE';
  v_result := to_char(p_floatval, v_format);
 ELSE
  RAISE invalid_parameter_value;
 END IF;

 v_res_length := substring(p_datatype, MASK_REGEXP)::SMALLINT;
 IF v_res_length IS NULL THEN
  RETURN v_result;
 ELSE
  RETURN rpad(v_result, v_res_length, ' ');
 END IF;
EXCEPTION
 WHEN invalid_parameter_value THEN
  RAISE USING MESSAGE := format('%s is not a valid style number when converting from FLOAT to a character string.', v_style),
     DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
     HINT := 'Change "style" parameter to the proper value and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_parse_to_date(IN p_datestring TEXT,
                                                               IN p_culture TEXT DEFAULT NULL)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_parse_to_date(p_datestring, p_culture);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_parse_to_datetime(IN p_datatype TEXT,
                                                                   IN p_datetimestring TEXT,
                                                                   IN p_culture TEXT DEFAULT '')
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_parse_to_datetime(p_datatype, p_datetimestring, p_culture);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_parse_to_time(IN p_datatype TEXT,
                                                               IN p_srctimestring TEXT,
                                                               IN p_culture TEXT DEFAULT '')
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_parse_to_time(p_datatype, p_srctimestring, p_culture);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_update_job (
  p_job integer,
  p_error_message varchar
)
RETURNS void AS
$body$
DECLARE
  var_enabled smallint;
  var_freq_type integer;
  var_freq_interval integer;
  var_freq_subday_type integer;
  var_freq_subday_interval integer;
  var_freq_relative_interval integer;
  var_freq_recurrence_factor integer;
  var_tmp_interval varchar(50);
  var_job_id integer;
  var_schedule_id integer;
  var_job_step_id integer;
  var_step_id integer;
  var_step_name VARCHAR(128);
BEGIN
-- 9994 "sql/sys_function_helpers.sql"
  INSERT
    INTO sys.sysjobhistory (
         job_id
       , step_id
       , step_name
       , sql_message_id
       , sql_severity
       , message
       , run_status
       , run_date
       , run_time
       , run_duration
       , operator_id_emailed
       , operator_id_netsent
       , operator_id_paged
       , retries_attempted
       , server)
  VALUES (
         p_job
       , 0 -- var_step_id
       , ''--var_step_name
       , 0
       , 0
       , p_error_message
       , 0
       , now()::date
       , now()::time
       , 0
       , 0
       , 0
       , 0
       , 0
       , ''::character varying);

  -- PERFORM sys.babelfish_sp_set_next_run (var_job_id, var_schedule_id);

END;
$body$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys.babelfish_waitfor_delay(time_to_pass TEXT)
RETURNS void AS
$BODY$
  SELECT pg_sleep(EXTRACT(HOUR FROM $1::time)*60*60 +
                  EXTRACT(MINUTE FROM $1::time)*60 +
                  TRUNC(EXTRACT(SECOND FROM $1::time)) +
                  sys.babelfish_round_fractseconds(
                                                        (
                                                          EXTRACT(MILLISECONDS FROM $1::time)
                                                          - TRUNC(EXTRACT(SECOND FROM $1::time)) * 1000
                                                        )::numeric
                                                      )/1000::numeric);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.babelfish_waitfor_delay(time_to_pass TIMESTAMP WITHOUT TIME ZONE)
RETURNS void AS
$BODY$
  SELECT pg_sleep(EXTRACT(HOUR FROM $1::time)*60*60 +
                  EXTRACT(MINUTE FROM $1::time)*60 +
                  TRUNC(EXTRACT(SECOND FROM $1::time)) +
                  sys.babelfish_round_fractseconds(
                                                        (
                                                          EXTRACT(MILLISECONDS FROM $1::time)
                                                          - TRUNC(EXTRACT(SECOND FROM $1::time)) * 1000
                                                        )::numeric
                                                      )/1000::numeric);
$BODY$
LANGUAGE SQL;

-- internal table function for sp_cursor_list and sp_decribe_cursor
CREATE OR REPLACE FUNCTION sys.babelfish_cursor_list(cursor_source integer)
RETURNS table (
  reference_name text,
  cursor_name text,
  cursor_scope smallint,
  status smallint,
  model smallint,
  concurrency smallint,
  scrollable smallint,
  open_status smallint,
  cursor_rows bigint,
  fetch_status smallint,
  column_count smallint,
  row_count bigint,
  last_operation smallint,
  cursor_handle int,
  cursor_source smallint
) AS 'babelfishpg_tsql', 'cursor_list' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.babelfish_get_datetimeoffset_tzoffset(SYS.DATETIMEOFFSET)
RETURNS SMALLINT
AS 'babelfishpg_common', 'get_datetimeoffset_tzoffset_internal'
LANGUAGE C IMMUTABLE STRICT;

-- internal table function for querying the registered ENRs
CREATE OR REPLACE FUNCTION sys.babelfish_get_enr_list()
RETURNS table (
  reloid int,
  relname text
) AS 'babelfishpg_tsql', 'get_enr_list' LANGUAGE C;

-- internal table function for collation_list
CREATE OR REPLACE FUNCTION sys.babelfish_collation_list()
RETURNS table (
  oid int,
  collation_name text,
  l1_priority int,
  l2_priority int,
  l3_priority int,
  l4_priority int,
  l5_priority int
) AS 'babelfishpg_tsql', 'collation_list' LANGUAGE C;

-- internal function to truncate long identifier
CREATE OR REPLACE FUNCTION sys.babelfish_truncate_identifier(IN object_name TEXT)
RETURNS text
AS 'babelfishpg_tsql', 'pltsql_truncate_identifier_func' LANGUAGE C IMMUTABLE STRICT;

-- internal functions for debuggig/testing purpose
CREATE OR REPLACE FUNCTION sys.babelfish_pltsql_cursor_show_textptr_only_column_indexes(cursor_handle INT)
RETURNS text
AS 'babelfishpg_tsql', 'pltsql_cursor_show_textptr_only_column_indexes' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.babelfish_pltsql_get_last_cursor_handle()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_get_last_cursor_handle' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.babelfish_pltsql_get_last_stmt_handle()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_get_last_stmt_handle' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_tsql', 'get_server_collation_oid';
-- 12 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_functions.sql" 1
-- Helper functions to support the FOR XML clause
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml(query text, mode int, element_name text,
           binary_base64 boolean, root_name text)
RETURNS xml
AS 'babelfishpg_tsql', 'tsql_query_to_xml'
LANGUAGE C IMMUTABLE STRICT COST 100;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text(query text, mode int, element_name text,
           binary_base64 boolean, root_name text)
RETURNS ntext
AS 'babelfishpg_tsql', 'tsql_query_to_xml_text'
LANGUAGE C IMMUTABLE STRICT COST 100;

-- User and Login Functions
CREATE OR REPLACE FUNCTION sys.user_name(IN id OID DEFAULT NULL)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'user_name'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.user_id(IN user_name TEXT DEFAULT NULL)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID DEFAULT NULL)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT DEFAULT NULL)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

-- Matches and returns object name to Oid
CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
$BODY$
DECLARE
    object_name TEXT;
    object_oid Oid;
    cur_dat_id Oid;
BEGIN
    IF database_id is not NULL THEN
        SELECT Oid INTO cur_dat_id FROM pg_database WHERE datname = current_database();
        IF database_id::Oid != cur_dat_id THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;
    END IF;

    SELECT CAST(object_id AS Oid) INTO object_oid;

    -- First check for tables, sequences, views, etc.
    SELECT relname INTO object_name FROM pg_class WHERE Oid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;

 -- Check ENR for any matches
    SELECT relname INTO object_name FROM sys.babelfish_get_enr_list() WHERE reloid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;

    -- Next check for functions
    SELECT proname INTO object_name FROM pg_proc WHERE Oid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;

    -- Next check for types
    SELECT typname INTO object_name FROM pg_type WHERE Oid = object_oid;
    IF object_name IS NOT NULL THEN
        RETURN object_name::sys.SYSNAME;
    END IF;

    -- Apparently SYSNAME cannot be null so returning empty string
    RETURN '';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.scope_identity()
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_last_identity_numeric()::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_seed(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_identity_param(tablename, 'start'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_incr(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_identity_param(tablename, 'increment'::text)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.ident_current(IN tablename TEXT)
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_identity_current(tablename)::numeric(38,0);
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.checksum(IN _input TEXT) RETURNS INTEGER
AS
$BODY$
  SELECT ('x'||SUBSTR(MD5(_input),1,8))::pg_catalog.BIT(32)::INTEGER;
$BODY$
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year NUMERIC,
                                                                IN p_month NUMERIC,
                                                                IN p_day NUMERIC,
                                                                IN p_hour NUMERIC,
                                                                IN p_minute NUMERIC,
                                                                IN p_seconds NUMERIC,
                                                                IN p_fractions NUMERIC,
                                                                IN p_precision NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
   v_fractions VARCHAR;
   v_precision SMALLINT;
   v_err_message VARCHAR;
   v_calc_seconds NUMERIC;
BEGIN
   v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
   v_precision := p_precision::SMALLINT;

   IF (scale(p_precision) > 0) THEN
      RAISE most_specific_type_mismatch;
   ELSIF ((p_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
       (p_month::SMALLINT NOT BETWEEN 1 AND 12) OR
       (p_day::SMALLINT NOT BETWEEN 1 AND 31) OR
       (p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
       (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
       (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
       (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
   THEN
      RAISE invalid_datetime_format;
   ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
      RAISE invalid_parameter_value;
   END IF;

   v_calc_seconds := format('%s.%s',
                            floor(p_seconds)::SMALLINT,
                            substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

   RETURN make_timestamp(floor(p_year)::SMALLINT,
                         floor(p_month)::SMALLINT,
                         floor(p_day)::SMALLINT,
                         floor(p_hour)::SMALLINT,
                         floor(p_minute)::SMALLINT,
                         v_calc_seconds);
EXCEPTION
   WHEN most_specific_type_mismatch THEN
      RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_parameter_value THEN
      RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';

   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := format('Source value is out of %s data type range.', v_err_message),
                  HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                 v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetime2fromparts(IN p_year TEXT,
                                                                IN p_month TEXT,
                                                                IN p_day TEXT,
                                                                IN p_hour TEXT,
                                                                IN p_minute TEXT,
                                                                IN p_seconds TEXT,
                                                                IN p_fractions TEXT,
                                                                IN p_precision TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetime2fromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                                p_hour::NUMERIC, p_minute::NUMERIC, p_seconds::NUMERIC,
                                                p_fractions::NUMERIC, p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year NUMERIC,
                                                               IN p_month NUMERIC,
                                                               IN p_day NUMERIC,
                                                               IN p_hour NUMERIC,
                                                               IN p_minute NUMERIC,
                                                               IN p_seconds NUMERIC,
                                                               IN p_milliseconds NUMERIC)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
    v_milliseconds SMALLINT;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    -- Check if arguments are out of range
    IF ((floor(p_year)::SMALLINT NOT BETWEEN 1753 AND 9999) OR
        (floor(p_month)::SMALLINT NOT BETWEEN 1 AND 12) OR
        (floor(p_day)::SMALLINT NOT BETWEEN 1 AND 31) OR
        (floor(p_hour)::SMALLINT NOT BETWEEN 0 AND 23) OR
        (floor(p_minute)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_seconds)::SMALLINT NOT BETWEEN 0 AND 59) OR
        (floor(p_milliseconds)::SMALLINT NOT BETWEEN 0 AND 999))
    THEN
        RAISE invalid_datetime_format;
    END IF;

    v_milliseconds := sys.babelfish_round_fractseconds(p_milliseconds::INTEGER);

    v_calc_seconds := format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             CASE v_milliseconds
                                WHEN 1000 THEN '0'
                                ELSE lpad(v_milliseconds::VARCHAR, 3, '0')
                             END)::NUMERIC;

    v_resdatetime := make_timestamp(floor(p_year)::SMALLINT,
                                    floor(p_month)::SMALLINT,
                                    floor(p_day)::SMALLINT,
                                    floor(p_hour)::SMALLINT,
                                    floor(p_minute)::SMALLINT,
                                    v_calc_seconds);
    RETURN CASE
              WHEN (v_milliseconds != 1000) THEN v_resdatetime
              ELSE v_resdatetime + INTERVAL '1 second'
           END;
EXCEPTION
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.datetimefromparts(IN p_year TEXT,
                                                               IN p_month TEXT,
                                                               IN p_day TEXT,
                                                               IN p_hour TEXT,
                                                               IN p_minute TEXT,
                                                               IN p_seconds TEXT,
                                                               IN p_milliseconds TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.datetimefromparts(p_year::NUMERIC, p_month::NUMERIC, p_day::NUMERIC,
                                               p_hour::NUMERIC, p_minute::NUMERIC,
                                               p_seconds::NUMERIC, p_milliseconds::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr ANYELEMENT) RETURNS INTEGER AS
$BODY$
DECLARE
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
     RETURN 0;
    END IF;
    IF ($1::VARCHAR ~ '^\s*$') THEN
     RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
 THEN
  RETURN 1;
 END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE CALLED ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.isnumeric(IN expr TEXT) RETURNS INTEGER AS
$BODY$
DECLARE
    x NUMERIC;
    y MONEY;
BEGIN
    IF (expr IS NULL) THEN
     RETURN 0;
    END IF;
    IF ($1::VARCHAR ~ '^\s*$') THEN
     RETURN 0;
    END IF;
    IF pg_typeof(expr) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,
    'numeric'::regtype, 'float'::regtype, 'real'::regtype, 'sys.money'::regtype)
 THEN
  RETURN 1;
 END IF;
    x = $1::NUMERIC;
    RETURN 1;
EXCEPTION WHEN others THEN
    BEGIN
        y = $1::sys.MONEY;
        RETURN 1;
        EXCEPTION WHEN others THEN
            RETURN 0;
    END;
END;
$BODY$
LANGUAGE plpgsql
VOLATILE CALLED ON NULL INPUT;

-- Return the object ID given the object name. Can specify optional type.
CREATE OR REPLACE FUNCTION sys.object_id(IN object_name TEXT, IN object_type char(2) DEFAULT '')
RETURNS INTEGER AS
$BODY$
DECLARE
        id oid;
        lower_object_name text;
        names text[2];
        counter int;
        cur_pos int;
        db_name text;
        input_schema_name text;
  schema_name text;
        schema_oid oid;
        obj_name text;
        is_temp_object boolean;
BEGIN
        id = null;
        lower_object_name = lower(trim(object_name));
        counter = 1;
        cur_pos = position('.' in lower_object_name);
        schema_oid = NULL;

        -- Parse user input into names split by '.'
        WHILE cur_pos > 0 LOOP
            IF counter > 3 THEN
                -- Too many names provided
                RETURN NULL;
            END IF;
            names[counter] = sys.babelfish_single_unbracket_name(left(lower_object_name, cur_pos - 1));
            lower_object_name = substring(lower_object_name from cur_pos + 1);
            counter = counter + 1;
            cur_pos = position('.' in lower_object_name);
        END LOOP;

        -- Assign each name accordingly
        obj_name = sys.babelfish_truncate_identifier(sys.babelfish_single_unbracket_name(lower_object_name));
        CASE counter
            WHEN 1 THEN
                db_name = NULL;
                schema_name = NULL;
            WHEN 2 THEN
                db_name = NULL;
                input_schema_name = sys.babelfish_truncate_identifier(names[1]);
    schema_name = sys.bbf_get_current_physical_schema_name(input_schema_name);
            WHEN 3 THEN
                db_name = sys.babelfish_truncate_identifier(names[1]);
                input_schema_name = sys.babelfish_truncate_identifier(names[2]);
    schema_name = sys.bbf_get_current_physical_schema_name(input_schema_name);
            ELSE
                RETURN NULL;
        END CASE;

        -- Check if looking for temp object.
        is_temp_object = left(obj_name, 1) = '#';

        -- Can only search in current database. Allowing tempdb for temp objects.
        IF db_name IS NOT NULL AND db_name <> current_database() AND db_name <> 'tempdb' THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;

        IF schema_name IS NOT NULL AND schema_name <> '' THEN
            -- Searching within a schema. Get schema oid.
            schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
            IF schema_oid IS NULL THEN
                RETURN NULL;
            END IF;

            if object_type <> '' then
                case
                    -- Schema does not apply as much to temp objects.
                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                 id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);

                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                 id := (select oid from pg_class where lower(relname) = obj_name
                                and relnamespace = schema_oid limit 1);

                    when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                 id := (select oid from pg_constraint where lower(conname) = obj_name
                                and connamespace = schema_oid limit 1);

                    when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                 id := (select oid from pg_proc where lower(proname) = obj_name
                                and pronamespace = schema_oid limit 1);

                    when upper(object_type) in ('TR', 'TA') then
                 id := (select oid from pg_trigger where lower(tgname) = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when upper(object_type) in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported object_type
                    else id := null;
                end case;
            else
                if not is_temp_object then id := (
                                                select oid from pg_class where lower(relname) = obj_name
                                                    and relnamespace = schema_oid
                 union
                    select oid from pg_constraint where lower(conname) = obj_name
                 and connamespace = schema_oid
                                                    union
                    select oid from pg_proc where lower(proname) = obj_name
                 and pronamespace = schema_oid
                                                    union
                    select oid from pg_trigger where lower(tgname) = obj_name
                    limit 1);
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);
                end if;
            end if;
        ELSE
            -- Schema not specified.
            if object_type <> '' then
                case
                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
                 id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);

                    when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
                 id := (select oid from pg_class where lower(relname) = obj_name limit 1);

                    when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
                 id := (select oid from pg_constraint where lower(conname) = obj_name limit 1);

                    when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
                 id := (select oid from pg_proc where lower(proname) = obj_name limit 1);

                    when upper(object_type) in ('TR', 'TA') then
                 id := (select oid from pg_trigger where lower(tgname) = obj_name limit 1);

                    -- Throwing exception as a reminder to add support in the future.
                    when upper(object_type) in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                        RAISE EXCEPTION 'Object type currently unsupported.';

                    -- unsupported object_type
                    else id := null;
                end case;
            else
                if not is_temp_object then id := (
                                                select oid from pg_class where lower(relname) = obj_name
                 union
                    select oid from pg_constraint where lower(conname) = obj_name
                 union
                    select oid from pg_proc where lower(proname) = obj_name
                 union
                    select oid from pg_trigger where lower(tgname) = obj_name
                    limit 1);
                else
                    -- temp object without "object_type" in-argument
                    id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) = obj_name limit 1);
                end if;
            end if;
        END IF;

        RETURN id::integer;
END;
$BODY$
LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.parsename (
 object_name VARCHAR
 ,object_piece INT
 )
RETURNS VARCHAR AS $$



SELECT CASE
  WHEN char_length($1) < char_length(replace($1, '.', '')) + 4
   AND $2 BETWEEN 1
    AND 4
   THEN reverse(split_part(reverse($1), '.', $2))
  ELSE NULL
  END $$ immutable LANGUAGE 'sql';

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour NUMERIC,
                                                           IN p_minute NUMERIC,
                                                           IN p_seconds NUMERIC,
                                                           IN p_fractions NUMERIC,
                                                           IN p_precision NUMERIC)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_fractions VARCHAR;
    v_precision SMALLINT;
    v_err_message VARCHAR;
    v_calc_seconds NUMERIC;
BEGIN
    v_fractions := floor(p_fractions)::INTEGER::VARCHAR;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF ((p_hour::SMALLINT NOT BETWEEN 0 AND 23) OR
           (p_minute::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
           (p_fractions::SMALLINT NOT BETWEEN 0 AND 9999999) OR
           (p_fractions::SMALLINT != 0 AND char_length(v_fractions) > p_precision))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;

    v_calc_seconds := format('%s.%s',
                             floor(p_seconds)::SMALLINT,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    RETURN make_time(floor(p_hour)::SMALLINT,
                     floor(p_minute)::SMALLINT,
                     v_calc_seconds);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type DATETIME2 scale argument are integer constants and integer constant expressions.',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := format('Specified scale %s is invalid.', v_precision),
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type time, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.timefromparts(IN p_hour TEXT,
                                                           IN p_minute TEXT,
                                                           IN p_seconds TEXT,
                                                           IN p_fractions TEXT,
                                                           IN p_precision TEXT)
RETURNS TIME WITHOUT TIME ZONE
AS
$BODY$
DECLARE
    v_err_message VARCHAR;
BEGIN
    RETURN sys.timefromparts(p_hour::NUMERIC, p_minute::NUMERIC,
                                           p_seconds::NUMERIC, p_fractions::NUMERIC,
                                           p_precision::NUMERIC);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'numeric\:\s\"(.*)\"');

        RAISE USING MESSAGE := format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.has_dbaccess(database_name PG_CATALOG.TEXT) RETURNS INTEGER AS $$
DECLARE has_access BOOLEAN;
BEGIN
 has_access = has_database_privilege(database_name, 'CONNECT');
 IF has_access THEN
  RETURN 1;
 ELSE
  RETURN 0;
 END IF;
EXCEPTION WHEN others THEN
 RETURN NULL;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.is_srvrolemember(role PG_CATALOG.TEXT, login PG_CATALOG.TEXT DEFAULT CURRENT_USER) RETURNS INTEGER AS $$
DECLARE has_role BOOLEAN;
BEGIN
 has_role = pg_has_role(login, role, 'MEMBER');
 IF has_role THEN
  return 1;
 ELSE
  RETURN 0;
 END IF;
EXCEPTION WHEN others THEN
 RETURN NULL;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.datefromparts(IN year INT, IN month INT, IN day INT)
RETURNS DATE AS
$BODY$
SELECT make_date(year, month, day);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.charindex(expressionToFind PG_CATALOG.TEXT,
           expressionToSearch PG_CATALOG.TEXT,
           start_location INTEGER DEFAULT 0)
RETURNS INTEGER AS
$BODY$
SELECT
CASE
WHEN start_location <= 0 THEN
 strpos(expressionToSearch, expressionToFind)
ELSE
 CASE
 WHEN strpos(substr(expressionToSearch, start_location), expressionToFind) = 0 THEN
  0
 ELSE
  strpos(substr(expressionToSearch, start_location), expressionToFind) + start_location - 1
 END
END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.stuff(expr TEXT, start INTEGER, length INTEGER, replace_expr TEXT)
RETURNS TEXT AS
$BODY$
SELECT
CASE
WHEN start <= 0 or start > length(expr) or length < 0 THEN
 NULL
WHEN replace_expr is NULL THEN
 overlay (expr placing '' from start for length)
ELSE
 overlay (expr placing replace_expr from start for length)
END;
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.stuff(expr ANYELEMENT, start INTEGER, length INTEGER, replace_expr ANYELEMENT)
RETURNS ANYELEMENT AS
$BODY$
SELECT
CASE
WHEN start <= 0 or start > length(expr) or length < 0 THEN
 NULL
WHEN replace_expr is NULL THEN
 overlay (expr placing '' from start for length)
ELSE
 overlay (expr placing replace_expr from start for length)
END;
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.len(expr TEXT) RETURNS INTEGER AS
$BODY$
SELECT length(trim(trailing from expr));
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

-- DATALENGTH
CREATE OR REPLACE FUNCTION sys.datalength(ANYELEMENT) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- provide both additional functions here to avoid implicit casting between string literals with/without N''
CREATE OR REPLACE FUNCTION sys.datalength(text) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.datalength(char) RETURNS INTEGER
AS 'babelfishpg_tsql', 'datalength' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- TODO: in MSSQL datalength against varchar(max) will return BIGINT instead of INTEGER. However in PG we ignore typmods in functions.
-- However this is not a critical issue so we will just leave it. We may come back to this difference later once we find out solution to typmods.

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_round' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.round(number PG_CATALOG.NUMERIC, length INTEGER, function INTEGER)
RETURNS NUMERIC AS 'babelfishpg_common', 'tsql_numeric_trunc' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.day(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('day', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.month(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('month', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.year(date ANYELEMENT)
RETURNS INTEGER AS
$BODY$
SELECT sys.datepart('year', date);
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.space(IN number INTEGER, OUT result SYS.VARCHAR) AS $$
-- sys.varchar has default length of 1, so we have to pass in 'number' to be the
-- type modifier.
BEGIN
 EXECUTE format(E'SELECT repeat(\' \', %s)::SYS.VARCHAR(%s)', number, number) INTO result;
END;
$$
STRICT
LANGUAGE plpgsql;

create or replace function sys.isdate(v text)
returns integer
as
$body$
begin
    if v is NULL THEN
        return 0;
    else
        perform v::date;
        return 1;
    end if;
    EXCEPTION WHEN others THEN
    RETURN 0;
end
$body$
language 'plpgsql';

create or replace function sys.PATINDEX(in pattern character varying, in expression character varying) returns bigint as
$body$
declare
  v_find_result character varying;
  v_pos bigint;
  v_regexp_pattern character varying;
begin
  v_pos := null;
  if left(pattern, 1) = '%' then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"');
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if right(pattern, 1) = '%' then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%');
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
 end if;
  v_find_result := substring(expression from v_regexp_pattern for '#');
  if v_find_result <> '' then
    v_pos := strpos(expression, v_find_result);
  end if;
  return v_pos;
end;
$body$
language plpgsql returns null on null input;

create or replace function sys.RAND(x in int)returns double precision
AS 'babelfishpg_tsql', 'tsql_random'
LANGUAGE C IMMUTABLE STRICT COST 1 PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.datepart(IN datepart PG_CATALOG.TEXT, IN arg anyelement) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSE
        return sys.datepart_internal(datepart, arg);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal_df(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT
AS
$body$
BEGIN
    IF pg_typeof(startdate) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.dateadd_internal_df(datepart, num,
                     startdate);
    ELSE
        return sys.dateadd_internal(datepart, num,
                     startdate);
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datepart_internal(IN datepart PG_CATALOG.TEXT, IN arg anyelement,IN df_tz INTEGER DEFAULT 0) RETURNS INTEGER AS $$
DECLARE
 result INTEGER;
 first_day DATE;
 first_week_end INTEGER;
 day INTEGER;
BEGIN
 CASE datepart
 WHEN 'dow' THEN
  result = (date_part(datepart, arg)::INTEGER - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1;
 WHEN 'tsql_week' THEN
  first_day = make_date(date_part('year', arg)::INTEGER, 1, 1);
  first_week_end = 8 - sys.datepart_internal('dow', first_day)::INTEGER;
  day = date_part('doy', arg)::INTEGER;
  IF day <= first_week_end THEN
   result = 1;
  ELSE
   result = 2 + (day - first_week_end - 1) / 7;
  END IF;
 WHEN 'second' THEN
  result = TRUNC(date_part(datepart, arg))::INTEGER;
 WHEN 'millisecond' THEN
  result = right(date_part(datepart, arg)::TEXT, 3)::INTEGER;
 WHEN 'microsecond' THEN
  result = right(date_part(datepart, arg)::TEXT, 6)::INTEGER;
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  result = right(date_part('microsecond', arg)::TEXT, 6)::INTEGER * 1000;
 WHEN 'tzoffset' THEN
  -- timezone for datetimeoffset
  result = df_tz;
 ELSE
  result = date_part(datepart, arg)::INTEGER;
 END CASE;
 RETURN result;
EXCEPTION WHEN invalid_parameter_value THEN
    -- date_part() throws an exception when trying to get day/month/year etc. from
 -- TIME, so we just need to catch the exception in this case
 -- date_part() returns 0 when trying to get hour/minute/second etc. from
 -- DATE, which is the desirable behavior for datepart() as well.
    -- If the date argument data type does not have the specified datepart,
    -- date_part() will return the default value for that datepart.
    CASE datepart
 -- Case for datepart is year, yy and yyyy, all mappings are defined in gram.y.
    WHEN 'year' THEN RETURN 1900;
    -- Case for datepart is quater, qq and q
    WHEN 'quarter' THEN RETURN 1;
    -- Case for datepart is month, mm and m
    WHEN 'month' THEN RETURN 1;
    -- Case for datepart is day, dd and d
    WHEN 'day' THEN RETURN 1;
    -- Case for datepart is dayofyear, dy
    WHEN 'doy' THEN RETURN 1;
    -- Case for datepart is y(also refers to dayofyear)
    WHEN 'y' THEN RETURN 1;
    -- Case for datepart is week, wk and ww
    WHEN 'tsql_week' THEN RETURN 1;
    -- Case for datepart is iso_week, isowk and isoww
    WHEN 'week' THEN RETURN 1;
    -- Case for datepart is tzoffset and tz
    WHEN 'tzoffset' THEN RETURN 0;
    -- Case for datepart is weekday and dw, return dow according to datefirst
    WHEN 'dow' THEN
        RETURN (1 - current_setting('babelfishpg_tsql.datefirst')::INTEGER + 7) % 7 + 1 ;
 ELSE
        RAISE EXCEPTION '''%'' is not a recognized datepart option', datepart;
        RETURN -1;
 END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset) RETURNS datetimeoffset AS $$
BEGIN
 CASE datepart
 WHEN 'year' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(years => num);
 WHEN 'quarter' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(months => num * 3);
 WHEN 'month' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(months => num);
 WHEN 'dayofyear', 'y' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(days => num);
 WHEN 'day' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(days => num);
 WHEN 'week' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(weeks => num);
 WHEN 'weekday' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(days => num);
 WHEN 'hour' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(hours => num);
 WHEN 'minute' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(mins => num);
 WHEN 'second' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(secs => num);
 WHEN 'millisecond' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(secs => num * 0.001);
 WHEN 'microsecond' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(secs => num * 0.000001);
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  RETURN startdate;
 ELSE
  RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
 END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'date'::regtype AND
  datepart IN ('hour', 'minute', 'second', 'millisecond', 'microsecond', 'nanosecond') THEN
  RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type date.', datepart;
 END IF;
    IF pg_typeof(startdate) = 'time'::regtype AND
  datepart IN ('year', 'quarter', 'month', 'doy', 'day', 'week', 'weekday') THEN
  RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type time.', datepart;
 END IF;

 CASE datepart
 WHEN 'year' THEN
  RETURN startdate + make_interval(years => num);
 WHEN 'quarter' THEN
  RETURN startdate + make_interval(months => num * 3);
 WHEN 'month' THEN
  RETURN startdate + make_interval(months => num);
 WHEN 'dayofyear', 'y' THEN
  RETURN startdate + make_interval(days => num);
 WHEN 'day' THEN
  RETURN startdate + make_interval(days => num);
 WHEN 'week' THEN
  RETURN startdate + make_interval(weeks => num);
 WHEN 'weekday' THEN
  RETURN startdate + make_interval(days => num);
 WHEN 'hour' THEN
  RETURN startdate + make_interval(hours => num);
 WHEN 'minute' THEN
  RETURN startdate + make_interval(mins => num);
 WHEN 'second' THEN
  RETURN startdate + make_interval(secs => num);
 WHEN 'millisecond' THEN
  RETURN startdate + make_interval(secs => num * 0.001);
 WHEN 'microsecond' THEN
  RETURN startdate + make_interval(secs => num * 0.000001);
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  RETURN startdate;
 ELSE
  RAISE EXCEPTION '"%" is not a recognized dateadd option.', datepart;
 END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal_df(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
 result INTEGER;
 year_diff INTEGER;
 month_diff INTEGER;
 day_diff INTEGER;
 hour_diff INTEGER;
 minute_diff INTEGER;
 second_diff INTEGER;
 millisecond_diff INTEGER;
 microsecond_diff INTEGER;
BEGIN
 CASE datepart
 WHEN 'year' THEN
  year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
  result = year_diff;
 WHEN 'quarter' THEN
  year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
  month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
  result = (year_diff * 12 + month_diff) / 3;
 WHEN 'month' THEN
  year_diff = sys.datepart('year', enddate) - sys.datepart('year', startdate);
  month_diff = sys.datepart('month', enddate) - sys.datepart('month', startdate);
  result = year_diff * 12 + month_diff;
 WHEN 'doy', 'y' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  result = day_diff;
 WHEN 'day' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  result = day_diff;
 WHEN 'week' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  result = day_diff / 7;
 WHEN 'hour' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  result = day_diff * 24 + hour_diff;
 WHEN 'minute' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
  result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
 WHEN 'second' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
  second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
  result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
 WHEN 'millisecond' THEN
  -- millisecond result from date_part by default contains second value,
  -- so we don't need to add second_diff again
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
  second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
  result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
 WHEN 'microsecond' THEN
  -- microsecond result from date_part by default contains second and millisecond values,
  -- so we don't need to add second_diff and millisecond_diff again
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
  second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
  microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
  result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  day_diff = sys.datepart('day', enddate - startdate);
  hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
  minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
  second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
  microsecond_diff = TRUNC(sys.datepart('microsecond', enddate OPERATOR(sys.-) startdate));
  result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
 ELSE
  RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
 END CASE;

 return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS INTEGER AS $$
DECLARE
 result INTEGER;
 year_diff INTEGER;
 month_diff INTEGER;
 day_diff INTEGER;
 hour_diff INTEGER;
 minute_diff INTEGER;
 second_diff INTEGER;
 millisecond_diff INTEGER;
 microsecond_diff INTEGER;
BEGIN
 CASE datepart
 WHEN 'year' THEN
  year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
  result = year_diff;
 WHEN 'quarter' THEN
  year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
  month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
  result = (year_diff * 12 + month_diff) / 3;
 WHEN 'month' THEN
  year_diff = date_part('year', enddate)::INTEGER - date_part('year', startdate)::INTEGER;
  month_diff = date_part('month', enddate)::INTEGER - date_part('month', startdate)::INTEGER;
  result = year_diff * 12 + month_diff;
 WHEN 'doy', 'y' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = day_diff;
 WHEN 'day' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = day_diff;
 WHEN 'week' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = day_diff / 7;
 WHEN 'hour' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = day_diff * 24 + hour_diff;
 WHEN 'minute' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
 WHEN 'second' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
  second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
  result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
 WHEN 'millisecond' THEN
  -- millisecond result from date_part by default contains second value,
  -- so we don't need to add second_diff again
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
  second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
  result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
 WHEN 'microsecond' THEN
  -- microsecond result from date_part by default contains second and millisecond values,
  -- so we don't need to add second_diff and millisecond_diff again
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
  second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
  microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
  result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::INTEGER;
  minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::INTEGER;
  second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
  millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
  microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
  result = (((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff) * 1000;
 ELSE
  RAISE EXCEPTION '"%" is not a recognized datediff option.', datepart;
 END CASE;

 return result;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg anyelement) RETURNS TEXT AS
$BODY$
SELECT
    CASE
    WHEN dp = 'month'::text THEN
        to_char(arg::date, 'TMMonth')
    -- '1969-12-28' is a Sunday
    WHEN dp = 'dow'::text THEN
        to_char(arg::date, 'TMDay')
    ELSE
        sys.datepart(dp, arg)::TEXT
    END
$BODY$
STRICT
LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.GETUTCDATE() RETURNS sys.DATETIME AS
$BODY$
SELECT CAST(CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS sys.DATETIME);
$BODY$
LANGUAGE SQL PARALLEL SAFE;

-- These come from the built-in pg_catalog.count in pg_aggregate.dat
CREATE AGGREGATE sys.count(*)
(
 sfunc = int8inc,
 combinefunc = int8pl,
 msfunc = int8inc,
 minvfunc = int8dec,
 stype = int8,
 mstype = int8,
 initcond = 0,
 minitcond = 0,
 finalfunc = int4,
 mfinalfunc = int4,
 parallel = safe
);

CREATE AGGREGATE sys.count("any")
(
 sfunc = int8inc_any,
 combinefunc = int8pl,
 msfunc = int8inc_any,
 minvfunc = int8dec_any,
 stype = int8,
 mstype = int8,
 initcond = 0,
 minitcond = 0,
 finalfunc = int4,
 mfinalfunc = int4,
 parallel = safe
);

CREATE AGGREGATE sys.count_big(*)
(
 sfunc = int8inc,
 combinefunc = int8pl,
 msfunc = int8inc,
 minvfunc = int8dec,
 stype = int8,
 mstype = int8,
 initcond = 0,
 minitcond = 0,
 parallel = safe
);

CREATE AGGREGATE sys.count_big("any")
(
 sfunc = int8inc_any,
 combinefunc = int8pl,
 msfunc = int8inc_any,
 minvfunc = int8dec_any,
 stype = int8,
 mstype = int8,
 initcond = 0,
 minitcond = 0,
 parallel = safe
);

CREATE OR REPLACE FUNCTION sys.REPLICATE(string TEXT, number INTEGER)
RETURNS VARCHAR AS
$BODY$
SELECT
    CASE
        WHEN number >= 0 THEN repeat(string, number)
        ELSE null
    END;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- @@ functions
CREATE OR REPLACE FUNCTION sys.rowcount()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error()
    RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.pgerror()
    RETURNS VARCHAR AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.trancount()
    RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.datefirst()
    RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.options()
    RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.version()
        RETURNS sys.NVARCHAR(255) AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.servername()
        RETURNS sys.NVARCHAR(128) AS 'babelfishpg_tsql' LANGUAGE C;

-- In tsql @@max_precision represents max precision that server supports
-- As of now, we do not support change in max_precision. So, returning default value
CREATE OR REPLACE FUNCTION sys.max_precision()
RETURNS sys.TINYINT AS
$$
BEGIN
  RETURN 38;
END;
$$
LANGUAGE plpgsql;

-- not supported, only syntax support
CREATE OR REPLACE FUNCTION sys.PROCID()
 RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.spid()
RETURNS INTEGER AS
$BODY$
SELECT pg_backend_pid();
$BODY$
STRICT
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.nestlevel() RETURNS INTEGER AS
$$
DECLARE
    stack text;
    result integer;
BEGIN
    GET DIAGNOSTICS stack = PG_CONTEXT;
    result := array_length(string_to_array(stack, 'function'), 1) - 2;
    IF result < 0 THEN
        RAISE EXCEPTION 'Invalid output, check stack trace %', stack;
    ELSE
        RETURN result;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.fetch_status()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.cursor_rows()
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.cursor_status(text, text)
RETURNS INT AS 'babelfishpg_tsql' LANGUAGE C;

-- Floor for bit
CREATE OR REPLACE FUNCTION sys.floor(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Floor overloading for all int types
CREATE OR REPLACE FUNCTION sys.floor(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.floor(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_floor' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling for bit
CREATE OR REPLACE FUNCTION sys.ceiling(sys.bit) RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'bit_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Ceiling overloading for all int types
CREATE OR REPLACE FUNCTION sys.ceiling(bigint) RETURNS BIGINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(int) RETURNS INT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(smallint) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ceiling(tinyint) RETURNS TINYINT
AS 'babelfishpg_tsql', 'int_ceiling' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.microsoftversion()
RETURNS INTEGER AS
$BODY$
    SELECT NULL::INTEGER;
$BODY$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;
CREATE OR REPLACE FUNCTION sys.APPLOCK_MODE(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS TEXT
AS 'babelfishpg_tsql', 'APPLOCK_MODE' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.APPLOCK_TEST(IN "@dbprincipal" varchar(32),
                                            IN "@resource" varchar(255),
           IN "@lockmode" varchar(32),
                                            IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION')
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'APPLOCK_TEST' LANGUAGE C;

-- Error handling functions
CREATE OR REPLACE FUNCTION sys.xact_state()
RETURNS SMALLINT
AS 'babelfishpg_tsql', 'xact_state' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_line()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_line' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_message()
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'pltsql_error_message' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_number()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_number' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_procedure()
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'pltsql_error_procedure' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_severity()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_severity' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.error_state()
RETURNS INT
AS 'babelfishpg_tsql', 'pltsql_error_state' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.rand() RETURNS FLOAT AS
$$
 SELECT random();
$$
LANGUAGE SQL VOLATILE STRICT PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.DEFAULT_DOMAIN()
RETURNS TEXT
AS 'babelfishpg_tsql', 'default_domain' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.db_id(sys.nvarchar(128)) RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_id() RETURNS SMALLINT
AS 'babelfishpg_tsql', 'babelfish_db_id'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name(int) RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.db_name() RETURNS sys.nvarchar(128)
AS 'babelfishpg_tsql', 'babelfish_db_name'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

-- BABEL-1783: (partial) support for sys.fn_listextendedproperty
create table if not exists sys.extended_properties (
class sys.tinyint,
class_desc sys.nvarchar(60),
major_id int,
minor_id int,
name sys.sysname,
value sys.sql_variant
);
GRANT SELECT ON sys.extended_properties TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty (
property_name varchar(128),
level0_object_type varchar(128),
level0_object_name varchar(128),
level1_object_type varchar(128),
level1_object_name varchar(128),
level2_object_type varchar(128),
level2_object_name varchar(128)
)
returns table (
objtype sys.sysname,
objname sys.sysname,
name sys.sysname,
value sys.sql_variant
)
as $$
begin
-- currently only support COLUMN property
IF (((SELECT coalesce(property_name, '')) = '') or
    ((SELECT coalesce(property_name, '')) = 'COLUMN')) THEN
 IF (((SELECT coalesce(level0_object_type, '')) = 'schema') and
     ((SELECT coalesce(level1_object_type, '')) = 'table') and
     ((SELECT coalesce(level2_object_type, '')) = 'column')) THEN
  RETURN query
  select CAST('COLUMN' AS sys.sysname) as objtype,
         CAST(t3.column_name AS sys.sysname) as objname,
         t1.name as name,
         t1.value as value
  from sys.extended_properties t1, pg_catalog.pg_class t2, information_schema.columns t3
  where t1.major_id = t2.oid and
     t2.relname = t3.table_name and
        t2.relname = (SELECT coalesce(level1_object_name, '')) and
     t3.column_name = (SELECT coalesce(level2_object_name, ''));
 END IF;
END IF;
RETURN;
end;
$$
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty(
 varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128)
) TO PUBLIC;
-- 13 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_cast.sql" 1
-- CAST and related functions.
-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg TEXT)
RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS SMALLINT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT)
RETURNS SMALLINT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS SMALLINT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS SMALLINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg TEXT)
RETURNS INT
AS $BODY$ BEGIN
    RETURN CAST(arg AS INT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT)
RETURNS INT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS INT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS INT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg TEXT)
RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS BIGINT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT)
RETURNS BIGINT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS BIGINT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS BIGINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


-- TRY_CAST helper functions
CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_smallint(IN arg TEXT) RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_smallint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_smallint(IN arg ANYELEMENT) RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_smallint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_int(IN arg TEXT) RETURNS INT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_int(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_int(IN arg ANYELEMENT) RETURNS INT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_int(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_bigint(IN arg TEXT) RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_bigint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_bigint(IN arg ANYELEMENT) RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_bigint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg TEXT, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE format('SELECT CAST(%L AS %s)', arg, format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;
-- 14 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/coerce.sql" 1
-- Manually initialize translation table
CREATE OR REPLACE PROCEDURE babel_coercion_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_tsql_coerce_hash_tab';
CALL babel_coercion_initializer();

-- Manually initialize translation table
CREATE OR REPLACE PROCEDURE babel_datatype_precedence_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_tsql_datatype_precedence_hash_tab';
CALL babel_datatype_precedence_initializer();
-- 15 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_views.sql" 1

create or replace view sys.tables as
select
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U'::varchar(2) as type
  , 'USER_TABLE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , null::integer as filestream_data_space_id
  , relnatts as max_column_id_used
  , 0 as lock_on_bulk_load
  , 1 as uses_ansi_nulls
  , 0 as is_replicated
  , 0 as has_replication_filter
  , 0 as is_merge_published
  , 0 as is_sync_tran_subscribed
  , 0 as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , 0 as large_value_types_out_of_row
  , 0 as is_tracked_by_cdc
  , 0 as lock_escalation
  , 'TABLE'::varchar(60) as lock_escalation_desc
  , 0 as is_filetable
  , 0 as durability
  , 'SCHEMA_AND_DATA'::varchar(60) as durability_desc
  , 0 as is_memory_optimized
  , case relpersistence when 't' then 2 else 0 end as temporal_type
  , case relpersistence when 't' then 'SYSTEM_VERSIONED_TEMPORAL_TABLE' else 'NON_TEMPORAL_TABLE' end as temporal_type_desc
  , null::integer as history_table_id
  , 0 as is_remote_data_archive_enabled
  , 0 as is_external
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.tables TO PUBLIC;

create or replace view sys.views as
select
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , 0 as with_check_option
  , 0 as is_date_correlation_view
  , 0 as is_tracked_by_cdc
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.views TO PUBLIC;

create or replace view sys.all_columns as
select c.oid as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 0 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = t.typcollation
where not a.attisdropped
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.all_columns TO PUBLIC;

create or replace view sys.all_views as
select
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , 0 as with_check_option
  , 0 as is_date_correlation_view
  , 0 as is_tracked_by_cdc
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.all_views TO PUBLIC;

create or replace view sys.columns as
select c.oid as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 0 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = t.typcollation
where not a.attisdropped
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and s.nspname not in ('information_schema', 'pg_catalog')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.columns TO PUBLIC;

create or replace view sys.foreign_key_columns as
select distinct
  c.oid as constraint_object_id
  , c.confkey as constraint_column_id
  , c.conrelid as parent_object_id
  , a_con.attnum as parent_column_id
  , c.confrelid as referenced_object_id
  , a_conf.attnum as referenced_column_id
from pg_constraint c
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f';
GRANT SELECT ON sys.foreign_key_columns TO PUBLIC;

create or replace view sys.foreign_keys as
select
  c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F'::varchar(2) as type
  , 'FOREIGN_KEY_CONSTRAINT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , c.confrelid as referenced_object_id
  , c.confkey as key_index_id
  , 0 as is_disabled
  , 0 as is_not_for_replication
  , 0 as is_not_trusted
  , case c.confdeltype
      when 'a' then 0
      when 'r' then 0
      when 'c' then 1
      when 'n' then 2
      when 'd' then 3
    end as delete_referential_action
  , case c.confdeltype
      when 'a' then 'NO_ACTION'
      when 'r' then 'NO_ACTION'
      when 'c' then 'CASCADE'
      when 'n' then 'SET_NULL'
      when 'd' then 'SET_DEFAULT'
    end as delete_referential_action_desc
  , case c.confupdtype
      when 'a' then 0
      when 'r' then 0
      when 'c' then 1
      when 'n' then 2
      when 'd' then 3
    end as update_referential_action
  , case c.confupdtype
      when 'a' then 'NO_ACTION'
      when 'r' then 'NO_ACTION'
      when 'c' then 'CASCADE'
      when 'n' then 'SET_NULL'
      when 'd' then 'SET_DEFAULT'
    end as update_referential_action_desc
  , 1 as is_system_named
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where c.contype = 'f'
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

create or replace view sys.identity_columns as
select
  sys.babelfish_get_id_by_name(c.oid::text||a.attname) as object_id
  , a.attname as name
  , a.attnum as column_id
  , t.oid as system_type_id
  , t.oid as user_type_id
  , a.attlen as max_length
  , null::integer as precision
  , null::integer as scale
  , coll.collname as collation_name
  , case when a.attnotnull then 0 else 1 end as is_nullable
  , 0 as is_ansi_padded
  , 0 as is_rowguidcol
  , 1 as is_identity
  , 0 as is_computed
  , 0 as is_filestream
  , 0 as is_replicated
  , 0 as is_non_sql_subscribed
  , 0 as is_merge_published
  , 0 as is_dts_replicated
  , 0 as is_xml_document
  , 0 as xml_collection_id
  , coalesce(d.oid, 0) as default_object_id
  , coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as rule_object_id
  , 0 as is_sparse
  , 0 as is_column_set
  , 0 as generated_always_type
  , 'NOT_APPLICABLE'::varchar(60) as generated_always_type_desc
  , null::integer as encryption_type
  , null::varchar(64) as encryption_type_desc
  , null::varchar as encryption_algorithm_name
  , null::integer as column_encryption_key_id
  , null::varchar as column_encryption_key_database_name
  , 0 as is_hidden
  , 0 as is_masked
  , null::bigint as seed_value
  , null::bigint as increment_value
  , sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname)) as last_value
from pg_attribute a
left join pg_attrdef d on a.attrelid = d.adrelid and a.attnum = d.adnum
inner join pg_class c on c.oid = a.attrelid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_type t on t.oid = a.atttypid
left join pg_collation coll on coll.oid = t.typcollation
where not a.attisdropped
and pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname) is not null
and s.nspname not in ('information_schema', 'pg_catalog')
and has_sequence_privilege(pg_get_serial_sequence(quote_ident(s.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

create or replace view sys.indexes as
select
  i.indrelid as object_id
  , c.relname as name
  , case when i.indisclustered then 1 else 2 end as type
  , case when i.indisclustered then 'CLUSTERED'::varchar(60) else 'NONCLUSTERED'::varchar(60) end as type_desc
  , case when i.indisunique then 1 else 0 end as is_unique
  , c.reltablespace as data_space_id
  , 0 as ignore_dup_key
  , case when i.indisprimary then 1 else 0 end as is_primary_key
  , case when constr.oid is null then 0 else 1 end as is_unique_constraint
  , 0 as fill_factor
  , case when i.indpred is null then 0 else 1 end as is_padded
  , case when i.indisready then 0 else 1 end is_disabled
  , 0 as is_hypothetical
  , 1 as allow_row_locks
  , 1 as allow_page_locks
  , 0 as has_filter
  , null::varchar as filter_definition
  , 0 as auto_created
from pg_class c
inner join pg_namespace s on s.oid = c.relnamespace
inner join pg_index i on i.indexrelid = c.oid
left join pg_constraint constr on constr.conindid = c.oid
where c.relkind = 'i' and i.indislive
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.indexes TO PUBLIC;

create or replace view sys.key_constraints as
select
  c.conname as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , case contype
      when 'p' then 'PK'::varchar(2)
      when 'u' then 'UQ'::varchar(2)
    end as type
  , case contype
      when 'p' then 'PRIMARY_KEY_CONSTRAINT'::varchar(60)
      when 'u' then 'UNIQUE_CONSTRAINT'::varchar(60)
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , c.conindid as unique_index_id
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where c.contype = 'p';
GRANT SELECT ON sys.key_constraints TO PUBLIC;

create or replace view sys.procedures as
select
  p.proname as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , case format_type(p.prorettype, null)
      when 'void' then 'P'::varchar(2)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'::varchar(2)
          else 'FN'::varchar(2)
        end
    end as type
  , case format_type(p.prorettype, null)
      when 'void' then 'SQL_STORED_PROCEDURE'::varchar(60)
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'::varchar(60)
          else 'SQL_SCALAR_FUNCTION'::varchar(60)
        end
    end as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
where s.nspname not in ('information_schema', 'pg_catalog')
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

create or replace view sys.sql_modules as
select
  p.oid as object_id
  , pg_get_functiondef(p.oid) as definition
  , 1 as uses_ansi_nulls
  , 1 as uses_quoted_identifier
  , 0 as is_schema_bound
  , 0 as uses_database_collation
  , 0 as is_recompiled
  , case when p.proisstrict then 1 else 0 end as null_on_null_input
  , null::integer as execute_as_principal_id
  , 0 as uses_native_compilation
from pg_proc p
inner join pg_namespace s on s.oid = p.pronamespace
inner join pg_type t on t.oid = p.prorettype
left join pg_collation c on c.oid = t.typcollation
where s.nspname not in ('information_schema', 'pg_catalog')
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.sql_modules TO PUBLIC;

create or replace view sys.sysforeignkeys as
select
  c.conname as name
  , c.oid as object_id
  , c.conrelid as fkeyid
  , c.confrelid as rkeyid
  , a_con.attnum as fkey
  , a_conf.attnum as rkey
  , a_conf.attnum as keyno
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f'
and s.nspname not in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.sysforeignkeys TO PUBLIC;

create or replace view sys.sysindexes as
select
  i.object_id as id
  , null::integer as status
  , null::oid as first
  , i.type as indid
  , null::oid as root
  , 0 as minlen
  , 1 as keycnt
  , 0 as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0 as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0 as xmaxlen
  , null::integer as maxirow
  , 0 as OrigFillFactor
  , 0 as StatVersion
  , 0 as reserved2
  , null::integer as FirstIAM
  , 0 as impid
  , 0 as lockflags
  , 0 as pgmodctr
  , null::bytea as keys
  , i.name
  , null::bytea as statblob
  , 800 as maxlen
  , 0 as rows
from sys.indexes i;
GRANT SELECT ON sys.sysindexes TO PUBLIC;

create or replace view sys.sysprocesses as
select
  a.pid as spid
  , null::integer as kpid
  , coalesce(blocking_activity.pid, 0) as blocked
  , null::bytea as waittype
  , 0 as waittime
  , a.wait_event_type as lastwaittype
  , null::text as waitresource
  , a.datid as dbid
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
left join pg_catalog.pg_locks as blocked_locks on a.pid = blocked_locks.pid
left join pg_catalog.pg_locks blocking_locks
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
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid;
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

create or replace view sys.types As
select format_type(t.oid, null) as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , null::integer as principal_id
  , t.typlen as max_length
  , 0 as precision
  , 0 as scale
  , c.collname as collation_name
  , case when typnotnull then 0 else 1 end as is_nullable
  , case typcategory when 'U' then 1 else 0 end as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , 0 as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
left join pg_collation c on c.oid = t.typcollation;
GRANT SELECT ON sys.types TO PUBLIC;

create view sys.objects as
select
 t.name
    , t.object_id
    , t.principal_id
    , t.schema_id
    , t.parent_object_id
    , 'U' as type
    , 'USER_TABLE' as type_desc
    , t.create_date
    , t.modify_date
    , t.is_ms_shipped
    , t.is_published
    , t.is_schema_published
from sys.tables t
where has_schema_privilege(t.schema_id, 'USAGE')
union all
select
 v.name
    , v.object_id
    , v.principal_id
    , v.schema_id
    , v.parent_object_id
    , 'V' as type
    , 'VIEW' as type_desc
    , v.create_date
    , v.modify_date
    , v.is_ms_shipped
    , v.is_published
    , v.is_schema_published
from sys.views v
where has_schema_privilege(v.schema_id, 'USAGE')
union all
select
 f.name
    , f.object_id
    , f.principal_id
    , f.schema_id
    , f.parent_object_id
    , 'F' as type
    , 'FOREIGN_KEY_CONSTRAINT'
    , f.create_date
    , f.modify_date
    , f.is_ms_shipped
    , f.is_published
    , f.is_schema_published
 from sys.foreign_keys f
where has_schema_privilege(f.schema_id, 'USAGE')
 union all
select
 p.name
    , p.object_id
    , p.principal_id
    , p.schema_id
    , p.parent_object_id
    , 'PK' as type
    , 'PRIMARY_KEY_CONSTRAINT' as type_desc
    , p.create_date
    , p.modify_date
    , p.is_ms_shipped
    , p.is_published
    , p.is_schema_published
 from sys.key_constraints p
where has_schema_privilege(p.schema_id, 'USAGE')
union all
select
    pr.name
    , pr.object_id
    , pr.principal_id
    , pr.schema_id
    , pr.parent_object_id
    , pr.type
    , pr.type_desc
    , pr.create_date
    , pr.modify_date
    , pr.is_ms_shipped
    , pr.is_published
    , pr.is_schema_published
 from sys.procedures pr
where has_schema_privilege(pr.schema_id, 'USAGE')
union all
select
  p.relname as name
  ,p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where s.nspname not in ('information_schema', 'pg_catalog')
and p.relkind = 'S'
and has_schema_privilege(s.oid, 'USAGE');
GRANT SELECT ON sys.objects TO PUBLIC;

create or replace view sys.sysobjects as
select
  s.name
  , s.object_id as id
  , s.type as xtype
  , s.schema_id as uid
  , 0 as info
  , 0 as status
  , 0 as base_schema_ver
  , 0 as replinfo
  , s.parent_object_id as parent_obj
  , s.create_date as crdate
  , 0 as ftcatid
  , 0 as schema_ver
  , 0 as stats_schema_ver
  , s.type
  , 0 as userstat
  , 0 as sysstat
  , 0 as indexdel
  , s.modify_date as refdate
  , 0 as version
  , 0 as deltrig
  , 0 as instrig
  , 0 as updtrig
  , 0 as seltrig
  , 0 as category
  , 0 as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

create view sys.all_objects as
select
 t.name
    , t.object_id
    , t.principal_id
    , t.schema_id
    , t.parent_object_id
    , 'U' as type
    , 'USER_TABLE' as type_desc
    , t.create_date
    , t.modify_date
    , t.is_ms_shipped
    , t.is_published
    , t.is_schema_published
from sys.tables t
union all
select
 v.name
    , v.object_id
    , v.principal_id
    , v.schema_id
    , v.parent_object_id
    , 'V' as type
    , 'VIEW' as type_desc
    , v.create_date
    , v.modify_date
    , v.is_ms_shipped
    , v.is_published
    , v.is_schema_published
from sys.all_views v
union all
select
 f.name
    , f.object_id
    , f.principal_id
    , f.schema_id
    , f.parent_object_id
    , 'F' as type
    , 'FOREIGN_KEY_CONSTRAINT'
    , f.create_date
    , f.modify_date
    , f.is_ms_shipped
    , f.is_published
    , f.is_schema_published
 from sys.foreign_keys f
 union all
select
 p.name
    , p.object_id
    , p.principal_id
    , p.schema_id
    , p.parent_object_id
    , 'PK' as type
    , 'PRIMARY_KEY_CONSTRAINT' as type_desc
    , p.create_date
    , p.modify_date
    , p.is_ms_shipped
    , p.is_published
    , p.is_schema_published
 from sys.key_constraints p
union all
select
 pr.name
    , pr.object_id
    , pr.principal_id
    , pr.schema_id
    , pr.parent_object_id
    , pr.type
    , pr.type_desc
    , pr.create_date
    , pr.modify_date
    , pr.is_ms_shipped
    , pr.is_published
    , pr.is_schema_published
 from sys.procedures pr
union all
select
  p.relname as name
  ,p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'SO'::varchar(2) as type
  , 'SEQUENCE_OBJECT'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class p
inner join pg_namespace s on s.oid = p.relnamespace
where p.relkind = 'S';
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace view sys.system_objects as
select * from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname in ('information_schema', 'pg_catalog');
GRANT SELECT ON sys.system_objects TO PUBLIC;

CREATE VIEW sys.syscharsets
AS
SELECT 1001 as type,
  1 as id,
  0 as csid,
  0 as status,
  NULL::nvarchar(128) as name,
  NULL::nvarchar(255) as description ,
  NULL::varbinary(6000) binarydefinition ,
  NULL::image definition;
GRANT SELECT ON sys.syscharsets TO PUBLIC;
-- 16 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/collation.sql" 1
-- create babelfish collations

CREATE COLLATION IF NOT EXISTS sys.Arabic_CS_AS (provider = icu, locale = 'ar_SA');
CREATE COLLATION sys.Arabic_CI_AS (provider = icu, locale = 'ar_SA@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Arabic_CI_AI (provider = icu, locale = 'ar_SA@colStrength=primary', deterministic = false);

CREATE COLLATION sys.BBF_Unicode_BIN2 FROM "C";

CREATE COLLATION sys.BBF_Unicode_General_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_General_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_General_Pref_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1250_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1250_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1250_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1251_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1251_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1251_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1253_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1253_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1253_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1254_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1254_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1254_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1255_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1255_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1255_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1256_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1256_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1256_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1257_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1257_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1257_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP1258_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP1258_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP1258_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION sys.BBF_Unicode_CP874_CI_AS (provider = icu, locale = '@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CI_AI (provider = icu, locale = '@colStrength=primary', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CS_AI (provider = icu, locale = '@colStrength=primary;colCaseLevel=yes;colCaseFirst=upper', deterministic = false);
CREATE COLLATION sys.BBF_Unicode_CP874_CS_AS (provider = icu, locale = '@colStrength=tertiary', deterministic = true);
CREATE COLLATION sys.BBF_Unicode_Pref_CP874_CS_AS (provider = icu, locale = '@colStrength=tertiary;colCaseFirst=upper', deterministic = true);

CREATE COLLATION IF NOT EXISTS sys.Chinese_PRC_CS_AS (provider = icu, locale = 'zh_CN');
CREATE COLLATION sys.Chinese_PRC_CI_AS (provider = icu, locale = 'zh_CN@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Chinese_PRC_CI_AI (provider = icu, locale = 'zh_CN@colStrength=primary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Cyrillic_General_CS_AS (provider = icu, locale='ru_RU');
CREATE COLLATION sys.Cyrillic_General_CI_AS (provider = icu, locale='ru_RU@colStrength=secondary', deterministic = false);
CREATE COLLATION sys.Cyrillic_General_CI_AI (provider = icu, locale='ru_RU@colStrength=primary', deterministic = false);

CREATE COLLATION sys.Estonian_CS_AS (provider = icu, locale='et_EE');
CREATE COLLATION sys.Estonian_CI_AI (provider = icu, locale='et_EE@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Estonian_CI_AS (provider = icu, locale='et_EE@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Finnish_Swedish_CS_AS (provider = icu, locale = 'sv_SE');
CREATE COLLATION sys.Finnish_Swedish_CI_AI (provider = icu, locale = 'sv_SE@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Finnish_Swedish_CI_AS (provider = icu, locale = 'sv_SE@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.French_CS_AS (provider = icu, locale = 'fr_FR');
CREATE COLLATION sys.French_CI_AI (provider = icu, locale = 'fr_FR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.French_CI_AS (provider = icu, locale = 'fr_FR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Greek_CS_AS (provider = icu, locale = 'el_GR');
CREATE COLLATION sys.Greek_CI_AI (provider = icu, locale = 'el_GR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Greek_CI_AS (provider = icu, locale = 'el_GR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Hebrew_CS_AS (provider = icu, locale = 'he_IL');
CREATE COLLATION sys.Hebrew_CI_AI (provider = icu, locale = 'he_IL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Hebrew_CI_AS (provider = icu, locale = 'he_IL@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Korean_Wansung_CS_AS (provider = icu, locale = 'ko_KR');
CREATE COLLATION sys.Korean_Wansung_CI_AI (provider = icu, locale = 'ko_KR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Korean_Wansung_CI_AS (provider = icu, locale = 'ko_KR@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Modern_Spanish_CS_AS (provider = icu, locale = 'en_ES');
CREATE COLLATION sys.Modern_Spanish_CI_AI (provider = icu, locale='es_ES@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Modern_Spanish_CI_AS (provider = icu, locale='es_ES@colStrength=secondary', deterministic = false);

CREATE COLLATION sys.Mongolian_CS_AS (provider = icu, locale = 'mn_MN');
CREATE COLLATION sys.Mongolian_CI_AI (provider = icu, locale = 'mn_MN@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Mongolian_CI_AS (provider = icu, locale = 'mn_MN@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Polish_CS_AS (provider = icu, locale = 'pl_PL');
CREATE COLLATION sys.Polish_CI_AI (provider = icu, locale = 'pl_PL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Polish_CI_AS (provider = icu, locale = 'pl_PL@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Thai_CS_AS (provider = icu, locale = 'th_TH');
CREATE COLLATION sys.Thai_CI_AI (provider = icu, locale = 'th_TH@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Thai_CI_AS (provider = icu, locale = 'th_TH@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Traditional_Spanish_CS_AS (provider = icu, locale = 'es_TRADITIONAL');
CREATE COLLATION sys.Traditional_Spanish_CI_AI (provider = icu, locale = 'es_TRADITIONAL@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Traditional_Spanish_CI_AS (provider = icu, locale = 'es_TRADITIONAL@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Turkish_CS_AS (provider = icu, locale = 'tr_TR');
CREATE COLLATION sys.Turkish_CI_AI (provider = icu, locale = 'tr_TR@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Turkish_CI_AS (provider = icu, locale = 'tr_TR@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Ukrainian_CS_AS (provider = icu, locale = 'uk_UA');
CREATE COLLATION sys.Ukrainian_CI_AI (provider = icu, locale = 'uk_UA@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Ukrainian_CI_AS (provider = icu, locale = 'uk_UA@colStrength=secondary', deterministic = false);

CREATE COLLATION IF NOT EXISTS sys.Vietnamese_CS_AS (provider = icu, locale = 'vi_VN');
CREATE COLLATION sys.Vietnamese_CI_AI (provider = icu, locale = 'vi_VN@colStrength=primary', deterministic = false);
CREATE COLLATION sys.Vietnamese_CI_AS (provider = icu, locale = 'vi_VN@colStrength=secondary', deterministic = false);

-- collation catalog
create table sys.babelfish_helpcollation(
    Name VARCHAR(128) NOT NULL,
    Description VARCHAR(1000) NOT NULL
);
GRANT SELECT ON sys.babelfish_helpcollation TO PUBLIC;

create or replace function sys.fn_helpcollations()
returns table (Name VARCHAR(128), Description VARCHAR(1000))
AS
$$
BEGIN
    return query select * from sys.babelfish_helpcollation;
END
$$
LANGUAGE 'plpgsql';
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_cs_as', N'Arabic, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_ci_ai', N'Arabic, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'arabic_ci_as', N'Arabic, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_bin2', N'Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_ci_ai', N'Default locale, code page 1250, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_ci_as', N'Default locale, code page 1250, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_cs_ai', N'Default locale, code page 1250, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1250_cs_as', N'Default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1250_cs_as', N'Default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_ci_ai', N'Default locale, code page 1251, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_ci_as', N'Default locale, code page 1251, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_cs_ai', N'Default locale, code page 1251, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1251_cs_as', N'Default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1251_cs_as', N'Default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_ci_ai', N'Default locale, code page 1253, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_ci_as', N'Default locale, code page 1253, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_cs_ai', N'Default locale, code page 1253, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1253_cs_as', N'Default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1253_cs_as', N'Default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_ci_ai', N'Default locale, code page 1254, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_ci_as', N'Default locale, code page 1254, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_cs_ai', N'Default locale, code page 1254, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1254_cs_as', N'Default locale, code page 1254, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1254_cs_as', N'Default locale, code page 1254, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_ci_ai', N'Default locale, code page 1255, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_ci_as', N'Default locale, code page 1255, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_cs_ai', N'Default locale, code page 1255, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1255_cs_as', N'Default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1255_cs_as', N'Default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_ci_ai', N'Default locale, code page 1256, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_ci_as', N'Default locale, code page 1256, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_cs_ai', N'Default locale, code page 1256, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1256_cs_as', N'Default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1256_cs_as', N'Default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_ci_ai', N'Default locale, code page 1257, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_ci_as', N'Default locale, code page 1257, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_cs_ai', N'Default locale, code page 1257, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1257_cs_as', N'Default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1257_cs_as', N'Default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_ci_ai', N'Default locale, code page 1258, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_ci_as', N'Default locale, code page 1258, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_cs_ai', N'Default locale, code page 1258, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1258_cs_as', N'Default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1258_cs_as', N'Default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_ci_ai', N'Default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_ci_as', N'Default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_cs_ai', N'Default locale, code page 1252, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp1_cs_as', N'Default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp1_cs_as', N'Default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_ci_ai', N'Default locale, code page 847, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_ci_as', N'Default locale, code page 847, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_cs_ai', N'Default locale, code page 847, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_cp847_cs_as', N'Default locale, code page 847, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_pref_cp847_cs_as', N'Default locale, code page 847, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_ci_ai', N'Default locale, default code page, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_ci_as', N'Default locale, default code page, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_cs_ai', N'Default locale, default code page, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_cs_as', N'Default locale, default code page, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'bbf_unicode_general_pref_cs_as', N'Default locale, default code page, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_cs_as', N'Chinese-PRC, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_ci_ai', N'Chinese-PRC, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'chinese_prc_ci_as', N'Chinese-PRC, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_cs_as', N'Cyrillic-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_ci_ai', N'Cyrillic-General, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'cyrillic_general_ci_as', N'Cyrillic-General, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_cs_as', N'Finnish-Swedish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_as', N'Finnish-Swedish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'finnish_swedish_ci_ai', N'Finnish-Swedish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'french_cs_as', N'French, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_as', N'French, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'french_ci_ai', N'French, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_cs_as', N'Korean-Wansung, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_ci_as', N'Korean-Wansung, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'korean_wansung_ci_ai', N'Korean-Wansung, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_90_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_100_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_140_bin2', N'Virtual, Unicode-General, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_ci_as', N'Virtual, default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_cs_ai', N'Virtual, default locale, code page 1252, case-sensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'latin1_general_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_cs_as', N'Traditional-Spanish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_ci_as', N'Traditional-Spanish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'modern_spanish_ci_ai', N'Traditional-Spanish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_cs_as', N'Polish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_ci_as', N'Polish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'polish_ci_ai', N'Polish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1250_ci_as', N'Virtual, default locale, code page 1250, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1250_cs_as', N'Virtual, default locale, code page 1250, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1251_ci_as', N'Virtual, default locale, code page 1251, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1251_cs_as', N'Virtual, default locale, code page 1251, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_as', N'Virtual, default locale, code page 1252, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_ci_ai', N'Virtual, default locale, code page 1252, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_pref_cp1_cs_as', N'Virtual, default locale, code page 1252, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive, uppercase-first');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1253_ci_as', N'Virtual, default locale, code page 1253, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1253_cs_as', N'Virtual, default locale, code page 1253, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1254_ci_as', N'Virtual, default locale, code page 1254, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1254_cs_as', N'Virtual, default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1255_ci_as', N'Virtual, default locale, code page 1255, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1255_cs_as', N'Virtual, default locale, code page 1255, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1256_ci_as', N'Virtual, default locale, code page 1256, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1256_cs_as', N'Virtual, default locale, code page 1256, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1257_ci_as', N'Virtual, default locale, code page 1257, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1257_cs_as', N'Virtual, default locale, code page 1257, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1258_ci_as', N'Virtual, default locale, code page 1258, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp1258_cs_as', N'Virtual, default locale, code page 1258, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_cs_as', N'Thai, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_ci_as', N'Thai, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'thai_ci_ai', N'Thai, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_cs_as', N'Traditional-Spanish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_ci_as', N'Traditional-Spanish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'traditional_spanish_ci_ai', N'Traditional-Spanish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_cs_as', N'Turkish, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_ci_as', N'Turkish, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'turkish_ci_ai', N'Turkish, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_cs_as', N'Ukrainian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_ci_as', N'Ukrainian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'ukrainian_ci_ai', N'Ukrainian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_cs_as', N'Vietnamese, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_ci_as', N'Vietnamese, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'vietnamese_ci_ai', N'Vietnamese, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');

DROP FUNCTION IF EXISTS sys.get_babel_server_collation_oid;
CREATE OR REPLACE FUNCTION sys.get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_tsql', 'get_server_collation_oid';

DROP PROCEDURE IF EXISTS sys.init_database_collation_oid;
CREATE OR REPLACE PROCEDURE sys.init_server_collation_oid()
AS $$
DECLARE
    server_colloid OID;
BEGIN
    server_colloid = sys.get_babel_server_collation_oid();
    perform pg_catalog.set_config('babelfishpg_tsql.server_collation_oid', server_colloid::text, false);
    execute format('ALTER DATABASE %I SET babelfishpg_tsql.server_collation_oid FROM CURRENT', current_database());
END;
$$
LANGUAGE plpgsql;

CALL sys.init_server_collation_oid();

-- Fill in the oids in coll_infos
CREATE OR REPLACE PROCEDURE sys.babel_collation_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_collid_trans_tab';
CALL sys.babel_collation_initializer();
DROP PROCEDURE sys.babel_collation_initializer;

-- Manually initialize like mapping table
CREATE OR REPLACE PROCEDURE sys.babel_like_ilike_info_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_like_ilike_table';
CALL sys.babel_like_ilike_info_initializer();
DROP PROCEDURE sys.babel_like_ilike_info_initializer;
-- 17 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_procedures.sql" 1
CREATE PROCEDURE sys.sp_unprepare(IN prep_handle INTEGER)
AS 'babelfishpg_tsql', 'sp_unprepare'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_unprepare(IN INTEGER) TO PUBLIC;

CREATE PROCEDURE sys.sp_prepare(INOUT prep_handle INTEGER, IN params varchar(8000),
           IN stmt varchar(8000), IN options int default 1)
AS 'babelfishpg_tsql', 'sp_prepare'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_prepare(
 INOUT INTEGER, IN varchar(8000), IN varchar(8000), IN int
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_getapplock_function (IN "@resource" varchar(255),
                                               IN "@lockmode" varchar(32),
                                               IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                               IN "@locktimeout" INTEGER DEFAULT -99,
                                               IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
RETURNS INTEGER
AS 'babelfishpg_tsql', 'sp_getapplock_function' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.sp_getapplock_function(
 IN varchar(255), IN varchar(32), IN varchar(32), IN INTEGER, IN varchar(32)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_releaseapplock_function(IN "@resource" varchar(255),
                                                   IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                                   IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
RETURNS INTEGER
AS 'babelfishpg_tsql', 'sp_releaseapplock_function' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.sp_releaseapplock_function(
 IN varchar(255), IN varchar(32), IN varchar(32)
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_cursor_list (INOUT "@cursor_return" refcursor,
                                                IN "@cursor_scope" INTEGER)
AS $$
DECLARE
  cur refcursor;
BEGIN
  IF "@cursor_scope" >= 1 AND "@cursor_scope" <= 3 THEN
    OPEN cur FOR EXECUTE 'SELECT reference_name::name, cursor_name::name, cursor_scope::smallint, status::smallint, model::smallint, concurrency::smallint, scrollable::smallint, open_status::smallint, cursor_rows::numeric(10,0), fetch_status::smallint, column_count::smallint, row_count::numeric(10,0), last_operation::smallint, cursor_handle::int FROM sys.babelfish_cursor_list($1)' USING "@cursor_scope";
  ELSE
    RAISE 'invalid @cursor_scope: %', "@cursor_scope";
  END IF;

  -- PG cursor evaluates the query at first fetch. We need to evaluate table function now because cursor_list() depeneds on "current" tsql_estate().
  -- Running MOVE fowrard and backward to force evaluating sys.babelfish_cursor_list() now.
  MOVE NEXT FROM cur;
  MOVE PRIOR FROM cur;
  SELECT cur INTO "@cursor_return";
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_cursor_list(INOUT refcursor, IN INTEGER) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_describe_cursor (INOUT "@cursor_return" refcursor,
                                                   IN "@cursor_source" nvarchar(30),
                                                   IN "@cursor_identity" nvarchar(30))
AS $$
DECLARE
  cur refcursor;
  cursor_source int;
BEGIN
  IF lower("@cursor_source") = 'local' THEN
    cursor_source := 1;
  ELSIF lower("@cursor_source") = 'global' THEN
    cursor_source := 2;
  ELSIF lower("@cursor_source") = 'variable' THEN
    cursor_source := 3;
  ELSE
    RAISE 'invalid @cursor_source: %', "@cursor_source";
  END IF;

  OPEN cur FOR EXECUTE 'SELECT reference_name::name, cursor_name::name, cursor_scope::smallint, status::smallint, model::smallint, concurrency::smallint, scrollable::smallint, open_status::smallint, cursor_rows::numeric(10,0), fetch_status::smallint, column_count::smallint, row_count::numeric(10,0), last_operation::smallint, cursor_handle::int FROM sys.babelfish_cursor_list($1) WHERE cursor_source = $1 and reference_name = $2' USING cursor_source, "@cursor_identity";

  -- PG cursor evaluates the query at first fetch. We need to evaluate table function now because cursor_list() depeneds on "current" tsql_estate().
  -- Running MOVE fowrard and backward to force evaluating sys.babelfish_cursor_list() now.
  MOVE NEXT FROM cur;
  MOVE PRIOR FROM cur;
  SELECT cur INTO "@cursor_return";
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_describe_cursor(
 INOUT refcursor, IN nvarchar(30), IN nvarchar(30)
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure()
AS 'babelfishpg_tsql', 'sp_babelfish_configure'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure() TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128))
AS 'babelfishpg_tsql', 'sp_babelfish_configure'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(IN varchar(128)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128), IN "@option_value" varchar(128))
AS $$
BEGIN
  CALL sys.sp_babelfish_configure("@option_name", "@option_value", '');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(IN varchar(128), IN varchar(128)) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128), IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  cnt int;
  cur refcursor;
  eh_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';
  IF cnt = 0 THEN
    RAISE EXCEPTION 'unknown configuration: %', normalized_name;
  END IF;

  OPEN cur FOR SELECT name FROM pg_catalog.pg_settings WHERE name like normalized_name and name like '%escape_hatch%';

  LOOP
    FETCH NEXT FROM cur into eh_name;
    exit when not found;

    PERFORM pg_catalog.set_config(eh_name, "@option_value", 'false');
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      -- store the setting in PG master database so that it can be applied to all bbf databases
      EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), eh_name, "@option_value");
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(
 IN varchar(128), IN varchar(128), IN varchar(128)
) TO PUBLIC;
-- 18 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/ownership.sql" 1
-- BBF_SYSDATABASES
-- Note: change here requires change in FormData_sysdatabases too
CREATE TABLE sys.babelfish_sysdatabases (
 dbid SMALLINT NOT NULL UNIQUE,
 status INT NOT NULL,
 status2 INT NOT NULL,
 owner NAME NOT NULL,
 default_collation NAME NOT NULL,
 name TEXT NOT NULL COLLATE "C",
 crdate timestamptz NOT NULL,
 properties TEXT NOT NULL COLLATE "C",
 PRIMARY KEY (name)
);

GRANT SELECT on sys.babelfish_sysdatabases TO PUBLIC;

-- BABELFISH_NAMESPACE_EXT
CREATE TABLE sys.babelfish_namespace_ext (
    nspname NAME NOT NULL,
    dbid SMALLINT NOT NULL,
    orig_name sys.NVARCHAR(128) NOT NULL,
 properties TEXT NOT NULL COLLATE "C",
    PRIMARY KEY (nspname)
);
GRANT SELECT ON sys.babelfish_namespace_ext TO PUBLIC;

-- SYSDATABASES
CREATE OR REPLACE VIEW sys.sysdatabases AS
SELECT
t.name,
sys.db_id(t.name) AS dbid,
CAST(CAST(r.oid AS int) AS SYS.VARBINARY(85)) AS sid,
CAST(0 AS SMALLINT) AS mode,
t.status,
t.status2,
CAST(t.crdate AS SYS.DATETIME) AS crdate,
CAST('1900-01-01 00:00:00.000' AS SYS.DATETIME) AS reserved,
CAST(0 AS INT) AS category,
CAST(NULL AS SYS.TINYINT) AS cmptlevel,
CAST(NULL AS SYS.NVARCHAR(260)) AS filename,
CAST(NULL AS SMALLINT) AS version
FROM sys.babelfish_sysdatabases AS t
LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = t.owner;

GRANT SELECT ON sys.sysdatabases TO PUBLIC;

-- PG_NAMESPACE_EXT
CREATE VIEW sys.pg_namespace_ext AS
SELECT BASE.* , DB.name as dbname FROM
pg_catalog.pg_namespace AS base
LEFT OUTER JOIN sys.babelfish_namespace_ext AS EXT on BASE.nspname = EXT.nspname
INNER JOIN sys.babelfish_sysdatabases AS DB ON EXT.dbid = DB.dbid;

GRANT SELECT ON sys.pg_namespace_ext TO PUBLIC;

-- Logical Schema Views
create or replace view sys.schemas as
select
  CAST(ext.orig_name as sys.SYSNAME) as name
  , base.oid as schema_id
  , base.nspowner as principal_id
from pg_catalog.pg_namespace base INNER JOIN sys.babelfish_namespace_ext ext on base.nspname = ext.nspname
where base.nspname not in ('information_schema', 'pg_catalog', 'pg_toast', 'sys', 'public')
and ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT ON sys.schemas TO PUBLIC;
CREATE SEQUENCE sys.babelfish_db_seq MAXVALUE 32767 CYCLE;

-- CATALOG INITIALIZER
CREATE OR REPLACE PROCEDURE babel_catalog_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_catalog';

CALL babel_catalog_initializer();

CREATE OR REPLACE PROCEDURE babel_create_builtin_dbs(IN login TEXT)
LANGUAGE C
AS 'babelfishpg_tsql', 'create_builtin_dbs';

CREATE OR REPLACE PROCEDURE sys.babel_drop_all_dbs()
LANGUAGE C
AS 'babelfishpg_tsql', 'drop_all_dbs';

CREATE OR REPLACE PROCEDURE sys.babel_initialize_logins(IN login TEXT)
LANGUAGE C
AS 'babelfishpg_tsql', 'initialize_logins';

CREATE OR REPLACE PROCEDURE sys.babel_drop_all_logins()
LANGUAGE C
AS 'babelfishpg_tsql', 'drop_all_logins';

CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
 reserved_roles varchar[] := ARRAY['sysadmin', 'master_dbo', 'master_guest', 'master_db_owner', 'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner'];
 user_id oid := -1;
 db_name name := NULL;
 role_name varchar;
 dba_name varchar;
BEGIN
 -- check reserved roles
 FOREACH role_name IN ARRAY reserved_roles LOOP
 BEGIN
  SELECT oid INTO user_id FROM pg_roles WHERE rolname = role_name;
  IF user_id > 0 THEN
   SELECT datname INTO db_name FROM pg_shdepend AS s INNER JOIN pg_database AS d ON s.dbid = d.oid WHERE s.refobjid = user_id;
   IF db_name IS NOT NULL THEN
    RAISE E'Could not initialize babelfish in current database: Reserved role % used in database %.\nIf babelfish was initialized in %, please remove babelfish and try again.', role_name, db_name, db_name;
   ELSE
    RAISE E'Could not initialize babelfish in current database: Reserved role % exists. \nPlease rename or drop existing role and try again ', role_name;
   END IF;
  END IF;
 END;
 END LOOP;

 SELECT pg_get_userbyid(datdba) INTO dba_name FROM pg_database WHERE datname = CURRENT_DATABASE();
 IF sa_name <> dba_name THEN
  RAISE E'Could not initialize babelfish with given role name: % is not the DB owner of current database.', sa_name;
 END IF;

 EXECUTE format('CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE %I', sa_name);
 EXECUTE format('GRANT USAGE, SELECT ON SEQUENCE sys.babelfish_db_seq TO sysadmin WITH GRANT OPTION');
 EXECUTE format('GRANT CREATE, CONNECT, TEMPORARY ON DATABASE %s TO sysadmin WITH GRANT OPTION', CURRENT_DATABASE());
 EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = true', CURRENT_DATABASE());
 EXECUTE 'SET babelfishpg_tsql.enable_ownership_structure = true';
 CALL sys.babel_initialize_logins(sa_name);
 CALL sys.babel_create_builtin_dbs(sa_name);
END
$$;

CREATE OR REPLACE PROCEDURE remove_babelfish ()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL sys.babel_drop_all_dbs();
    CALL sys.babel_drop_all_logins();
    EXECUTE format('ALTER DATABASE %s SET babelfishpg_tsql.enable_ownership_structure = false', CURRENT_DATABASE());
 EXECUTE 'ALTER SEQUENCE sys.babelfish_db_seq RESTART';
 DROP OWNED BY sysadmin;
 DROP ROLE sysadmin;
END
$$;

-- LOGIN EXT
-- Note: change here requires change in FormData_authid_login_ext too
CREATE TABLE sys.babelfish_authid_login_ext (
rolname NAME NOT NULL, -- pg_authid.rolname
is_disabled INT NOT NULL DEFAULT 0, -- to support enable/disable login
type CHAR(1) NOT NULL DEFAULT 'S',
credential_id INT NOT NULL,
owning_principal_id INT NOT NULL,
is_fixed_role INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
default_database_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128) NOT NULL,
properties JSONB,
PRIMARY KEY (rolname));
GRANT SELECT ON sys.babelfish_authid_login_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_sysdatabases', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_db_seq', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_namespace_ext', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_authid_login_ext', '');

-- SERVER_PRINCIPALS
CREATE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
Ext.type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN' ELSE NULL END AS NVARCHAR(60)) AS type_desc,
Ext.is_disabled,
Ext.create_date,
Ext.modify_date,
Ext.default_database_name,
Ext.default_language_name,
Ext.credential_id,
Ext.owning_principal_id,
CAST(Ext.is_fixed_role AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

GRANT SELECT ON sys.server_principals TO PUBLIC;

-- internal table function for sp_helpdb with no arguments
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb()
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C;

-- internal table function for helpdb with dbname as input
CREATE OR REPLACE FUNCTION sys.babelfish_helpdb(varchar)
RETURNS table (
  name varchar(128),
  db_size varchar(13),
  owner varchar(128),
  dbid int,
  created varchar(11),
  status varchar(600),
  compatibility_level smallint
) AS 'babelfishpg_tsql', 'babelfish_helpdb' LANGUAGE C;

create or replace view sys.databases as
select
  d.name as name
  , sys.db_id(d.name) as database_id
  , null::integer as source_database_id
  , cast(cast(r.oid as int) as varbinary(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(NULL AS SYS.TINYINT) as compatibility_level
  , c.collname::sys.nvarchar(128) as collation_name
  , 0 as user_access
  , 'MULTI_USER'::varchar(60) as user_access_desc
  , 0 as is_read_only
  , 0 as is_auto_close_on
  , 0 as is_auto_shrink_on
  , 0 as state
  , 'ONLINE'::varchar(60) as state_desc
  , CASE
  WHEN pg_is_in_recovery() is false THEN 0
  WHEN pg_is_in_recovery() is true THEN 1
 END as is_in_standby
  , 0 as is_cleanly_shutdown
  , 0 as is_supplemental_logging_enabled
  , 1 as snapshot_isolation_state
  , 'ON'::varchar(60) as snapshot_isolation_state_desc
  , 1 as is_read_committed_snapshot_on
  , 1 as recovery_model
  , 'FULL'::varchar(60) as recovery_model_desc
  , 0 as page_verify_option
  , null::varchar(60) as page_verify_option_desc
  , 1 as is_auto_create_stats_on
  , 0 as is_auto_create_stats_incremental_on
  , 0 as is_auto_update_stats_on
  , 0 as is_auto_update_stats_async_on
  , 0 as is_ansi_null_default_on
  , 0 as is_ansi_nulls_on
  , 0 as is_ansi_padding_on
  , 0 as is_ansi_warnings_on
  , 0 as is_arithabort_on
  , 0 as is_concat_null_yields_null_on
  , 0 as is_numeric_roundabort_on
  , 0 as is_quoted_identifier_on
  , 0 as is_recursive_triggers_on
  , 0 as is_cursor_close_on_commit_on
  , 0 as is_local_cursor_default
  , 0 as is_fulltext_enabled
  , 0 as is_trustworthy_on
  , 0 as is_db_chaining_on
  , 0 as is_parameterization_forced
  , 0 as is_master_key_encrypted_by_server
  , 0 as is_query_store_on
  , 0 as is_published
  , 0 as is_subscribed
  , 0 as is_merge_published
  , 0 as is_distributor
  , 0 as is_sync_with_backup
  , null::sys.UNIQUEIDENTIFIER as service_broker_guid
  , 0 as is_broker_enabled
  , 0 as log_reuse_wait
  , 'NOTHING'::varchar(60) as log_reuse_wait_desc
  , 0 as is_date_correlation_on
  , 0 as is_cdc_enabled
  , 0 as is_encrypted
  , 0 as is_honor_broker_priority_on
  , null::sys.UNIQUEIDENTIFIER as replica_id
  , null::sys.UNIQUEIDENTIFIER as group_database_id
  , null::int as resource_pool_id
  , null::smallint as default_language_lcid
  , null::sys.nvarchar(128) as default_language_name
  , null::int as default_fulltext_language_lcid
  , null::sys.nvarchar(128) as default_fulltext_language_name
  , null::sys.bit as is_nested_triggers_on
  , null::sys.bit as is_transform_noise_words_on
  , null::smallint as two_digit_year_cutoff
  , 0 as containment
  , 'NONE'::varchar(60) as containment_desc
  , 0 as target_recovery_time_in_seconds
  , 0 as delayed_durability
  , null::sys.nvarchar(60) as delayed_durability_desc
  , 0 as is_memory_optimized_elevate_to_snapshot_on
  , 0 as is_federation_member
  , 0 as is_remote_data_archive_enabled
  , 0 as is_mixed_page_allocation_on
  , 0 as is_temporal_history_retention_enabled
  , 0 as catalog_collation_type
  , 'Not Applicable'::sys.nvarchar(60) as catalog_collation_type_desc
  , null::sys.nvarchar(128) as physical_database_name
  , 0 as is_result_set_caching_on
  , 0 as is_accelerated_database_recovery_on
  , 0 as is_tempdb_spill_to_remote_store
  , 0 as is_stale_page_detection_on
  , 0 as is_memory_optimized_enabled
  , 0 as is_ledger_on
 from sys.babelfish_sysdatabases d LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname
 LEFT OUTER JOIN pg_catalog.pg_roles r on r.rolname = d.owner;

GRANT SELECT ON sys.databases TO PUBLIC;

-- Babelfish Specific Metadata Consistency Check 
CREATE OR REPLACE FUNCTION sys.babelfish_inconsistent_metadata()
RETURNS table (
  object_type varchar(32),
  schema_name varchar(128),
  object_name varchar(128),
  detail text
) AS 'babelfishpg_tsql', 'babelfish_inconsistent_metadata' LANGUAGE C;
-- 19 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/import_export_compatibility.sql" 1
CREATE TABLE sys.assemblies(
 name VARCHAR(255),
 principal_id int,
 assembly_id int,
 is_nullable int,
 is_fixed_length int,
 max_length int
);
GRANT SELECT ON sys.assemblies TO PUBLIC;

CREATE TABLE sys.assembly_types (
 assembly_id int,
 assembly_class VARCHAR(255)
);
GRANT SELECT ON sys.assembly_types TO PUBLIC;

-- Cannot be implemented without a full implementation of assemblies.
-- However, a full implementation isn't needed for import-export support yet
CREATE OR REPLACE FUNCTION assemblyproperty(IN a VARCHAR, IN b VARCHAR) RETURNS sys.sql_variant
AS
$body$
 SELECT CAST('' AS sys.sql_variant);
$body$
LANGUAGE SQL IMMUTABLE STRICT;
GRANT EXECUTE ON FUNCTION assemblyproperty(IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION is_member(IN a VARCHAR) RETURNS INT
AS 'babelfishpg_tsql', 'is_member' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION is_member(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_id(IN schema_name VARCHAR) RETURNS INT
AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_id(IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_name(IN id oid) RETURNS VARCHAR
AS 'babelfishpg_tsql', 'schema_name' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_name(IN oid) TO PUBLIC;
-- 20 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/babelfishpg_tsql.sql" 1
CREATE FUNCTION pltsql_call_handler ()
    RETURNS language_handler AS 'babelfishpg_tsql' LANGUAGE C;

CREATE FUNCTION pltsql_validator (oid)
    RETURNS void AS 'babelfishpg_tsql' LANGUAGE C;

CREATE FUNCTION pltsql_inline_handler(internal)
    RETURNS void AS 'babelfishpg_tsql' LANGUAGE C;

-- language
CREATE TRUSTED LANGUAGE pltsql
       HANDLER pltsql_call_handler
       INLINE pltsql_inline_handler
       VALIDATOR pltsql_validator;
GRANT USAGE ON LANGUAGE pltsql TO public;

COMMENT ON LANGUAGE pltsql IS 'PL/TSQL procedural language';

CREATE FUNCTION serverproperty (TEXT)
    RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'serverproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION databasepropertyex (TEXT, TEXT)
    RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'databasepropertyex' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION connectionproperty (TEXT)
  RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'connectionproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION collationproperty (TEXT, TEXT)
        RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'collationproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sessionproperty (TEXT)
    RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'sessionproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- The procedures below requires return code as a RETURN statement which is
-- only possible in pltsql. Therefore, we create them here and call into the
-- corresponding internal functions.
CREATE OR REPLACE PROCEDURE sys.sp_getapplock(IN "@resource" varchar(255),
                                               IN "@lockmode" varchar(32),
                                               IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                               IN "@locktimeout" INTEGER DEFAULT -99,
                                               IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
LANGUAGE 'pltsql'
AS $$
begin
 declare @ret int;
 select @ret = sp_getapplock_function(@resource, @lockmode, @lockowner, @locktimeout, @dbprincipal);
    return @ret;
end;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_releaseapplock(IN "@resource" varchar(255),
                                                   IN "@lockowner" varchar(32) DEFAULT 'TRANSACTION',
                                                   IN "@dbprincipal" varchar(32) DEFAULT 'dbo')
LANGUAGE 'pltsql'
AS $$
begin
 declare @ret int;
 select @ret = sp_releaseapplock_function(@resource, @lockowner, @dbprincipal);
    return @ret;
end;
$$;

-- sys.sp_oledb_ro_usrname is needed for TDS v7.2
-- In tsql, sp_oledb_ro_usrname stored procedure returns the database read only status.
-- Return values:
-- 1. RO status (VARCHAR(1)) - "N" or "Y", "N" for not read only, "Y" for read only
-- 2. user_name (sysname or NVARCHAR(128)) - The current database user
CREATE OR REPLACE PROCEDURE sys.sp_oledb_ro_usrname()
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT CAST((SELECT CASE WHEN pg_is_in_recovery() = 'f' THEN 'N' ELSE 'Y' END) AS VARCHAR(1)) RO, CAST(current_user as NVARCHAR(128));
END ;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helpdb()
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT
  CAST(name AS sys.nvarchar(128)),
  CAST(db_size AS sys.nvarchar(13)),
  CAST(owner AS sys.nvarchar(128)),
  CAST(dbid AS sys.int),
  CAST(created AS sys.nvarchar(11)),
  CAST(status AS sys.nvarchar(600)),
  CAST(compatibility_level AS sys.tinyint)
  FROM sys.babelfish_helpdb();

  RETURN 0;
END;
$$;

CREATE OR REPLACE PROCEDURE sys.sp_helpdb(IN "@dbname" VARCHAR(32))
LANGUAGE 'pltsql'
AS $$
BEGIN
  SELECT
  CAST(name AS sys.nvarchar(128)),
  CAST(db_size AS sys.nvarchar(13)),
  CAST(owner AS sys.nvarchar(128)),
  CAST(dbid AS sys.int),
  CAST(created AS sys.nvarchar(11)),
  CAST(status AS sys.nvarchar(600)),
  CAST(compatibility_level AS sys.tinyint)
  FROM sys.babelfish_helpdb("@dbname");

  SELECT
  CAST(NULL AS sys.nchar(128)) AS name,
  CAST(NULL AS smallint) AS fileid,
  CAST(NULL AS sys.nchar(260)) AS filename,
  CAST(NULL AS sys.nvarchar(128)) AS filegroup,
  CAST(NULL AS sys.nvarchar(18)) AS size,
  CAST(NULL AS sys.nvarchar(18)) AS maxsize,
  CAST(NULL AS sys.nvarchar(18)) AS growth,
  CAST(NULL AS sys.varchar(9)) AS usage;

  RETURN 0;
END;
$$;

-- BABEL-1643
CREATE TABLE sys.spt_datatype_info_table
(TYPE_NAME VARCHAR(20), DATA_TYPE INT, PRECISION BIGINT,
LITERAL_PREFIX VARCHAR(20), LITERAL_SUFFIX VARCHAR(20),
CREATE_PARAMS CHAR(20), NULLABLE INT, CASE_SENSITIVE INT,
SEARCHABLE INT, UNSIGNED_ATTRIBUTE INT, MONEY INT,
AUTO_INCREMENT INT, LOCAL_TYPE_NAME VARCHAR(20),
MINIMUM_SCALE INT, MAXIMUM_SCALE INT, SQL_DATA_TYPE INT,
SQL_DATETIME_SUB INT, NUM_PREC_RADIX INT, INTERVAL_PRECISION INT,
USERTYPE INT, LENGTH INT, SS_DATA_TYPE SYS.TINYINT,
-- below column is added in order to join PG's information_schema.columns for sys.sp_columns_100_view
PG_TYPE_NAME VARCHAR(20)
);
GRANT SELECT ON sys.spt_datatype_info_table TO PUBLIC;

INSERT INTO sys.spt_datatype_info_table VALUES (N'datetimeoffset', -155, 34, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'datetimeoffset', 0, 7, -155, 0, NULL, NULL, 0, 68, 0, 'datetimeoffset');
INSERT INTO sys.spt_datatype_info_table VALUES (N'time', -154, 16, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'time', 0, 7, -154, 0, NULL, NULL, 0, 32, 0, 'time');
INSERT INTO sys.spt_datatype_info_table VALUES (N'xml', -152, 0, N'N''', N'''', NULL, 1, 1, 0, NULL, 0, NULL, N'xml', NULL, NULL, -152, NULL, NULL, NULL, 0, 2147483646, 0, N'xml');
INSERT INTO sys.spt_datatype_info_table VALUES (N'sql_variant', -150, 8000, NULL, NULL, NULL, 1, 0, 2, NULL, 0, NULL, N'sql_variant', 0, 0, -150, NULL, 10, NULL, 0, 8000, 39, 'sql_variant');
INSERT INTO sys.spt_datatype_info_table VALUES (N'uniqueidentifier', -11, 36, N'''', N'''', NULL, 1, 0, 2, NULL, 0, NULL, N'uniqueidentifier', NULL, NULL, -11, NULL, NULL, NULL, 0, 16, 37, 'uniqueidentifier');
INSERT INTO sys.spt_datatype_info_table VALUES (N'ntext', -10, 1073741823, N'N''', N'''', NULL, 1, 1, 1, NULL, 0, NULL, N'ntext', NULL, NULL, -10, NULL, NULL, NULL, 0, 2147483646, 35, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'nvarchar', -9, 4000, N'N''', N'''', N'max length          ', 1, 1, 3, NULL, 0, NULL, N'nvarchar', NULL, NULL, -9, NULL, NULL, NULL, 0, 2, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'sysname', -9, 128, N'N''', N'''', NULL, 0, 1, 3, NULL, 0, NULL, N'sysname', NULL, NULL, -9, NULL, NULL, NULL, 18, 256, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'nchar', -8, 4000, N'N''', N'''', N'length              ', 1, 1, 3, NULL, 0, NULL, N'nchar', NULL, NULL, -8, NULL, NULL, NULL, 0, 2, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'bit', -7, 1, NULL, NULL, NULL, 1, 0, 2, NULL, 0, NULL, N'bit', 0, 0, -7, NULL, NULL, NULL, 16, 1, 50, 'bit');
INSERT INTO sys.spt_datatype_info_table VALUES (N'tinyint', -6, 3, NULL, NULL, NULL, 1, 0, 2, 1, 0, 0, N'tinyint', 0, 0, -6, NULL, 10, NULL, 5, 1, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'tinyint identity', -6, 3, NULL, NULL, NULL, 0, 0, 2, 1, 0, 1, N'tinyint identity', 0, 0, -6, NULL, 10, NULL, 5, 1, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'bigint', -5, 19, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'bigint', 0, 0, -5, NULL, 10, NULL, 0, 8, 108, 'int8');
INSERT INTO sys.spt_datatype_info_table VALUES (N'bigint identity', -5, 19, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'bigint identity', 0, 0, -5, NULL, 10, NULL, 0, 8, 108, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'image', -4, 2147483647, N'0x', NULL, NULL, 1, 0, 0, NULL, 0, NULL, N'image', NULL, NULL, -4, NULL, NULL, NULL, 20, 2147483647, 34, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'varbinary', -3, 8000, N'0x', NULL, N'max length          ', 1, 0, 2, NULL, 0, NULL, N'varbinary', NULL, NULL, -3, NULL, NULL, NULL, 4, 1, 37, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'binary', -2, 8000, N'0x', NULL, N'length              ', 1, 0, 2, NULL, 0, NULL, N'binary', NULL, NULL, -2, NULL, NULL, NULL, 3, 1, 37, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'timestamp', -2, 8, N'0x', NULL, NULL, 0, 0, 2, NULL, 0, NULL, N'timestamp', NULL, NULL, -2, NULL, NULL, NULL, 80, 8, 45, 'timestamp');
INSERT INTO sys.spt_datatype_info_table VALUES (N'text', -1, 2147483647, N'''', N'''', NULL, 1, 1, 1, NULL, 0, NULL, N'text', NULL, NULL, -1, NULL, NULL, NULL, 19, 2147483647, 35, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'char', 1, 8000, N'''', N'''', N'length              ', 1, 1, 3, NULL, 0, NULL, N'char', NULL, NULL, 1, NULL, NULL, NULL, 1, 1, 39, N'bpchar');
INSERT INTO sys.spt_datatype_info_table VALUES (N'numeric', 2, 38, NULL, NULL, N'precision,scale     ', 1, 0, 2, 0, 0, 0, N'numeric', 0, 38, 2, NULL, 10, NULL, 10, 20, 108, 'numeric');
INSERT INTO sys.spt_datatype_info_table VALUES (N'numeric() identity', 2, 38, NULL, NULL, N'precision           ', 0, 0, 2, 0, 0, 1, N'numeric() identity', 0, 0, 2, NULL, 10, NULL, 10, 20, 108, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'decimal', 3, 38, NULL, NULL, N'precision,scale     ', 1, 0, 2, 0, 0, 0, N'decimal', 0, 38, 3, NULL, 10, NULL, 24, 20, 106, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'money', 3, 19, N'$', NULL, NULL, 1, 0, 2, 0, 1, 0, N'money', 4, 4, 3, NULL, 10, NULL, 11, 21, 110, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallmoney', 3, 10, N'$', NULL, NULL, 1, 0, 2, 0, 1, 0, N'smallmoney', 4, 4, 3, NULL, 10, NULL, 21, 12, 110, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'decimal() identity', 3, 38, NULL, NULL, N'precision           ', 0, 0, 2, 0, 0, 1, N'decimal() identity', 0, 0, 3, NULL, 10, NULL, 24, 20, 106, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'int', 4, 10, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'int', 0, 0, 4, NULL, 10, NULL, 7, 4, 38, N'int4');
INSERT INTO sys.spt_datatype_info_table VALUES (N'int identity', 4, 10, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'int identity', 0, 0, 4, NULL, 10, NULL, 7, 4, 38, N'');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallint', 5, 5, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'smallint', 0, 0, 5, NULL, 10, NULL, 6, 2, 38, 'int2');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smallint identity', 5, 5, NULL, NULL, NULL, 0, 0, 2, 0, 0, 1, N'smallint identity', 0, 0, 5, NULL, 10, NULL, 6, 2, 38, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'float', 6, 53, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'float', NULL, NULL, 6, NULL, 2, NULL, 8, 8, 109, 'float8');
INSERT INTO sys.spt_datatype_info_table VALUES (N'real', 7, 24, NULL, NULL, NULL, 1, 0, 2, 0, 0, 0, N'real', NULL, NULL, 7, NULL, 2, NULL, 23, 4, 109, 'float4');
INSERT INTO sys.spt_datatype_info_table VALUES (N'varchar', 12, 8000, N'''', N'''', N'max length          ', 1, 1, 3, NULL, 0, NULL, N'varchar', NULL, NULL, 12, NULL, NULL, NULL, 2, 1, 39, NULL);
INSERT INTO sys.spt_datatype_info_table VALUES (N'date', 91, 10, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'date', NULL, 0, 9, 1, NULL, NULL, 0, 20, 0, 'date');
INSERT INTO sys.spt_datatype_info_table VALUES (N'datetime2', 93, 27, N'''', N'''', N'scale               ', 1, 0, 3, NULL, 0, NULL, N'datetime2', 0, 7, 9, 3, NULL, NULL, 0, 54, 0, 'datetime2');
INSERT INTO sys.spt_datatype_info_table VALUES (N'datetime', 93, 23, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'datetime', 3, 3, 9, 3, NULL, NULL, 12, 16, 111, 'datetime');
INSERT INTO sys.spt_datatype_info_table VALUES (N'smalldatetime', 93, 16, N'''', N'''', NULL, 1, 0, 3, NULL, 0, NULL, N'smalldatetime', 0, 0, 9, 3, NULL, NULL, 22, 16, 111, 'smalldatetime');

-- ODBCVer ignored for now
CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
 "@data_type" int = 0,
 "@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS, NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
       from sys.spt_datatype_info_table where @data_type = 0 or data_type = @data_type;
END;
$$
LANGUAGE 'pltsql';
-- same as sp_datatype_info
CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
 "@data_type" int = 0,
 "@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
               CREATE_PARAMS, NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.spt_datatype_info_table where @data_type = 0 or data_type = @data_type;
END;
$$
LANGUAGE 'pltsql';


-- BABEL-1784: support for sp_columns/sp_columns_100
CREATE VIEW sys.sp_columns_100_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3.rolname AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4.column_name AS sys.sysname) AS COLUMN_NAME,
CAST(t5.data_type AS smallint) AS DATA_TYPE,
CAST(t5.type_name AS sys.sysname) AS TYPE_NAME,
CAST(t4.numeric_precision AS INT) AS PRECISION,
CAST(t5.length AS int) AS LENGTH,
CAST(t4.numeric_scale AS smallint) AS SCALE,
CAST(t4.numeric_precision_radix AS smallint) AS RADIX,
case
  when t4.is_nullable = 'YES' then CAST(1 AS smallint)
  else CAST(0 AS smallint)
end AS NULLABLE,
CAST(NULL AS varchar(254)) AS remarks,
CAST(t4.column_default AS sys.nvarchar(4000)) AS COLUMN_DEF,
CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,
CAST(t4.character_octet_length AS int) AS CHAR_OCTET_LENGTH,
CAST(t4.dtd_identifier AS int) AS ORDINAL_POSITION,
CAST(t4.is_nullable AS varchar(254)) AS IS_NULLABLE,
CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
CAST(0 AS smallint) AS SS_IS_SPARSE,
CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
case
  when t4.is_generated = 'NEVER' then CAST(0 AS smallint)
  else CAST(1 AS smallint)
end AS SS_IS_COMPUTED,
case
  when t4.is_identity = 'YES' then CAST(1 AS smallint)
  else CAST(0 AS smallint)
end AS SS_IS_IDENTITY,
CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME
FROM pg_catalog.pg_class t1
  JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
  JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     JOIN information_schema.columns t4 ON t1.relname = t4.table_name,
 sys.spt_datatype_info_table AS t5
WHERE (t4.data_type = t5.pg_type_name
 OR ((SELECT coalesce(t4.domain_name, '') != 'tinyint') AND (SELECT coalesce(t4.domain_name, '') != 'nchar') AND t5.pg_type_name = t4.udt_name)
 OR (t4.domain_schema = 'sys' AND t5.type_name = t4.domain_name));
GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597 for BABEL-1784
drop function if exists sys.sp_columns_100_internal(
 in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384),
    in_table_qualifier sys.nvarchar(384),
    in_column_name sys.nvarchar(384),
 in_NameScope int,
    in_ODBCVer int,
    in_fusepattern smallint);
create function sys.sp_columns_100_internal(
 in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384) = '',
    in_table_qualifier sys.nvarchar(384) = '',
    in_column_name sys.nvarchar(384) = '',
 in_NameScope int = 0,
    in_ODBCVer int = 2,
    in_fusepattern smallint = 1)
returns table (
 out_table_qualifier sys.sysname,
 out_table_owner sys.sysname,
 out_table_name sys.sysname,
 out_column_name sys.sysname,
 out_data_type smallint,
 out_type_name sys.sysname,
 out_precision int,
 out_length int,
 out_scale smallint,
 out_radix smallint,
 out_nullable smallint,
 out_remarks varchar(254),
 out_column_def sys.nvarchar(4000),
 out_sql_data_type smallint,
 out_sql_datetime_sub smallint,
 out_char_octet_length int,
 out_ordinal_position int,
 out_is_nullable varchar(254),
 out_ss_is_sparse smallint,
 out_ss_is_column_set smallint,
 out_ss_is_computed smallint,
 out_ss_is_identity smallint,
 out_ss_udt_catalog_name varchar(254),
 out_ss_udt_schema_name varchar(254),
 out_ss_udt_assembly_type_name varchar(254),
 out_ss_xml_schemacollection_catalog_name varchar(254),
 out_ss_xml_schemacollection_schema_name varchar(254),
 out_ss_xml_schemacollection_name varchar(254),
 out_ss_data_type sys.tinyint
)
as $$
begin
 IF in_fusepattern = 1 THEN
  return query
     select table_qualifier,
    table_owner,
    table_name,
    column_name,
    data_type,
    type_name,
    precision,
    length,
    scale,
    radix,
    nullable,
    remarks,
    column_def,
    sql_data_type,
    sql_datetime_sub,
    char_octet_length,
    ordinal_position,
    is_nullable,
    ss_is_sparse,
    ss_is_column_set,
    ss_is_computed,
    ss_is_identity,
    ss_udt_catalog_name,
    ss_udt_schema_name,
    ss_udt_assembly_type_name,
    ss_xml_schemacollection_catalog_name,
    ss_xml_schemacollection_schema_name,
    ss_xml_schemacollection_name,
    ss_data_type
  from sys.sp_columns_100_view
     where table_name like in_table_name
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name)
  order by table_qualifier, table_owner, table_name;
 ELSE
  return query
     select table_qualifier, precision from sys.sp_columns_100_view
       where in_table_name = table_name
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name)
  order by table_qualifier, table_owner, table_name;
 END IF;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_columns (
 "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '',
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
 "@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
 select out_table_qualifier as table_qualifier,
   out_table_owner as table_owner,
   out_table_name as table_name,
   out_column_name as column_name,
   out_data_type as data_type,
   out_type_name as type_name,
   out_precision as precision,
   out_length as length,
   out_scale as scale,
   out_radix as radix,
   out_nullable as nullable,
   out_remarks as remarks,
   out_column_def as column_def,
   out_sql_data_type as sql_data_type,
   out_sql_datetime_sub as sql_datetime_sub,
   out_char_octet_length as char_octet_length,
   out_ordinal_position as ordinal_position,
   out_is_nullable as is_nullable,
   out_ss_data_type as ss_data_type
 from sys.sp_columns_100_internal(@table_name, @table_owner,@table_qualifier, @column_name, @NameScope,@ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_columns_100 (
 "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '',
    "@table_qualifier" sys.nvarchar(384) = '',
    "@column_name" sys.nvarchar(384) = '',
 "@namescope" int = 0,
    "@odbcver" int = 2,
    "@fusepattern" smallint = 1)
AS $$
BEGIN
 select out_table_qualifier as table_qualifier,
   out_table_owner as table_owner,
   out_table_name as table_name,
   out_column_name as column_name,
   out_data_type as data_type,
   out_type_name as type_name,
   out_precision as precision,
   out_length as length,
   out_scale as scale,
   out_radix as radix,
   out_nullable as nullable,
   out_remarks as remarks,
   out_column_def as column_def,
   out_sql_data_type as sql_data_type,
   out_sql_datetime_sub as sql_datetime_sub,
   out_char_octet_length as char_octet_length,
   out_ordinal_position as ordinal_position,
   out_is_nullable as is_nullable,
   out_ss_is_sparse as ss_is_sparse,
   out_ss_is_column_set as ss_is_column_set,
   out_ss_is_computed as ss_is_computed,
   out_ss_is_identity as ss_is_identity,
   out_ss_udt_catalog_name as ss_udt_catalog_name,
   out_ss_udt_schema_name as ss_udt_schema_name,
   out_ss_udt_assembly_type_name as ss_udt_assembly_type_name,
   out_ss_xml_schemacollection_catalog_name as ss_xml_schemacollection_catalog_name,
   out_ss_xml_schemacollection_schema_name as ss_xml_schemacollection_schema_name,
   out_ss_xml_schemacollection_name as ss_xml_schemacollection_name,
   out_ss_data_type as ss_data_type
 from sys.sp_columns_100_internal(@table_name, @table_owner,@table_qualifier, @column_name, @NameScope,@ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

-- BABEL-1785: initial support of sp_describe_first_result_set
-- sys.sp_describe_first_result_set_internal: internal function
-- used to workaround BABEL-1597
create function sys.sp_describe_first_result_set_internal(
 tsqlquery varchar(384),
    params varchar(384) = NULL,
    browseMode sys.tinyint = 0
)
returns table (
 is_hidden sys.bit,
 column_ordinal int,
 name sys.sysname,
 is_nullable sys.bit,
 system_type_id int,
 system_type_name sys.nvarchar(256),
 max_length smallint,
 "precision" sys.tinyint,
 scale sys.tinyint,
 collation_name sys.sysname,
 user_type_id int,
 user_type_database sys.sysname,
 user_type_schema sys.sysname,
 user_type_name sys.sysname,
 assembly_qualified_type_name sys.nvarchar(4000),
 xml_collection_id int,
 xml_collection_database sys.sysname,
 xml_collection_schema sys.sysname,
 xml_collection_name sys.sysname,
 is_xml_document sys.bit,
 is_case_sensitive sys.bit,
 is_fixed_length_clr_type sys.bit,
 source_server sys.sysname,
 source_database sys.sysname,
 source_schema sys.sysname,
 source_table sys.sysname,
 source_column sys.sysname,
 is_identity_column sys.bit,
 is_part_of_unique_key sys.bit,
 is_updateable sys.bit,
 is_computed_column sys.bit,
 is_sparse_column_set sys.bit,
 ordinal_in_order_by_list smallint,
 order_by_list_length smallint,
 order_by_is_descending smallint,
 tds_type_id int,
 tds_length int,
 tds_collation_id int,
 ss_data_type sys.tinyint
)
as $$
 declare _args text[]; -- placeholder: parse @params and feed the tsqlquery
begin
 IF tsqlquery ILIKE 'select %' THEN
  DROP VIEW IF EXISTS sp_describe_first_result_set_view;
  EXECUTE 'create temp view sp_describe_first_result_set_view as ' || tsqlquery USING _args;
  RETURN query
  SELECT
   CAST(0 AS sys.bit) AS is_hidden,
   CAST(t1.dtd_identifier AS int) AS column_ordinal,
   CAST(t1.column_name AS sys.sysname) AS name,
   case
    when t1.is_nullable = 'Y' then CAST(1 AS sys.bit)
    else CAST(0 AS sys.bit)
   end as is_nullable,
   0 as system_type_id,
   CAST('' as sys.nvarchar(256)) as system_type_name,
   CAST(t2.length AS smallint) AS max_length,
   CAST(t1.numeric_precision AS sys.tinyint) AS precision,
   CAST(t1.numeric_scale AS sys.tinyint) AS scale,
   CAST((SELECT coalesce(t1.collation_name, '')) AS sys.sysname) as collation_name,
   CAST(NULL as int) as user_type_id,
   CAST('' as sys.sysname) as user_type_database,
   CAST('' as sys.sysname) as user_type_schema,
   CAST('' as sys.sysname) as user_type_name,
   CAST('' as sys.nvarchar(4000)) as assembly_qualified_type_name,
   CAST(NULL as int) as xml_collection_id,
   CAST('' as sys.sysname) as xml_collection_database,
   CAST('' as sys.sysname) as xml_collection_schema,
   CAST('' as sys.sysname) as xml_collection_name,
   case
    when t1.data_type = 'xml' then CAST(1 AS sys.bit)
    else CAST(0 AS sys.bit)
   end as is_xml_document,
   case
    when t1.udt_name = 'citext' then CAST(0 AS sys.bit)
    else CAST(1 AS sys.bit)
   end as is_case_sensitive,
   CAST(0 as sys.bit) as is_fixed_length_clr_type,
   CAST('' as sys.sysname) as source_server,
   CAST('' as sys.sysname) as source_database,
   CAST('' as sys.sysname) as source_schema,
   CAST('' as sys.sysname) as source_table,
   CAST('' as sys.sysname) as source_column,
   case
    when t1.is_identity = 'YES' then CAST(1 AS sys.bit)
    else CAST(0 AS sys.bit)
   end as is_identity_column,
   CAST(NULL as sys.bit) as is_part_of_unique_key,-- pg_constraint
   case
    when t1.is_updatable = 'YES' then CAST(1 AS sys.bit)
    else CAST(0 AS sys.bit)
   end as is_updateable,
   case
    when t1.is_generated = 'NEVER' then CAST(0 AS sys.bit)
    else CAST(1 AS sys.bit)
   end as is_computed_column,
   CAST(0 as sys.bit) as is_sparse_column_set,
   CAST(NULL as smallint) ordinal_in_order_by_list,
   CAST(NULL as smallint) order_by_list_length,
   CAST(NULL as smallint) order_by_is_descending,
   -- below are for internal usage
   CAST(NULL as int) as tds_type_id,
   CAST(NULL as int) as tds_length,
   CAST(NULL as int) as tds_collation_id,
   CAST(1 AS sys.tinyint) AS tds_collation_sort_id
  FROM information_schema.columns t1, sys.spt_datatype_info_table t2
  WHERE table_name = 'sp_describe_first_result_set_view'
   AND (t1.data_type = t2.pg_type_name
    OR ((SELECT coalesce(t1.domain_name, '') != 'tinyint')
     AND (SELECT coalesce(t1.domain_name, '') != 'nchar')
     AND t2.pg_type_name = t1.udt_name)
    OR (t1.domain_schema = 'sys' AND t2.type_name = t1.domain_name));
  DROP VIEW sp_describe_first_result_set_view;
 END IF;
end;
$$
LANGUAGE plpgsql;
GRANT ALL on FUNCTION sys.sp_describe_first_result_set_internal TO PUBLIC;

CREATE PROCEDURE sys.sp_describe_first_result_set (
 "@tsql" varchar(384),
    "@params" varchar(384) = NULL,
    "@browse_information_mode" sys.tinyint = 0)
AS $$
BEGIN
 select * from sys.sp_describe_first_result_set_internal(@tsql, @params, @browse_information_mode);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_first_result_set TO PUBLIC;

CREATE OR REPLACE VIEW sys.spt_tablecollations_view AS
    SELECT
        o.object_id AS object_id,
        o.schema_id AS schema_id,
        c.column_id AS colid,
        c.name AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id)
    WHERE
        c.is_sparse = 0;
GRANT SELECT ON sys.spt_tablecollations_view TO PUBLIC;

-- We are limited by what postgres procedures can return here, but IEW may not
-- need it for initial compatibility
CREATE OR REPLACE PROCEDURE sys.sp_tablecollations_100
(
    IN "@object" nvarchar(4000)
)
AS $$
BEGIN
    select
        s_tcv.colid AS colid,
        s_tcv.name AS name,
        s_tcv.tds_collation_100 AS tds_collation_100,
        s_tcv.collation_100 AS collation
    from
        sys.spt_tablecollations_view s_tcv
    where
        s_tcv.object_id = sys.object_id("@object") AND
        s_tcv.name NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid')
    order by colid;
END;
$$
LANGUAGE 'pltsql';

CREATE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id AS OBJECT_ID,
    isc.table_catalog AS TABLE_CATALOG,
    isc.table_schema AS TABLE_SCHEMA,
    o.name AS TABLE_NAME,
    c.name AS COLUMN_NAME,
    isc.ordinal_position AS ORDINAL_POSITION,
    isc.column_default AS COLUMN_DEFAULT,
    isc.is_nullable AS IS_NULLABLE,
    isc.data_type AS DATA_TYPE,
    isc.character_maximum_length AS CHARACTER_MAXIMUM_LENGTH,
    isc.character_octet_length AS CHARACTER_OCTET_LENGTH,
    isc.numeric_precision AS NUMERIC_PRECISION,
    isc.numeric_precision_radix AS NUMERIC_PRECISION_RADIX,
    isc.numeric_scale AS NUMERIC_SCALE,
    isc.datetime_precision AS DATETIME_PRECISION,
    isc.character_set_catalog AS CHARACTER_SET_CATALOG,
    isc.character_set_schema AS CHARACTER_SET_SCHEMA,
    isc.character_set_name AS CHARACTER_SET_NAME,
    isc.collation_catalog AS COLLATION_CATALOG,
    isc.collation_schema AS COLLATION_SCHEMA,
    c.collation_name AS COLLATION_NAME,
    isc.domain_catalog AS DOMAIN_CATALOG,
    isc.domain_schema AS DOMAIN_SCHEMA,
    isc.domain_name AS DOMAIN_NAME,
    c.is_sparse AS IS_SPARSE,
    c.is_column_set AS IS_COLUMN_SET,
    c.is_filestream AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V') -- limit columns to tables and views
        )
    LEFT JOIN information_schema.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc.table_schema and
            o.name = isc.table_name and
            c.name = isc.column_name
        )
    WHERE CAST(column_name AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');

CREATE FUNCTION sys.sp_columns_managed_internal(
    in_catalog sys.nvarchar(128),
    in_owner sys.nvarchar(128),
    in_table sys.nvarchar(128),
    in_column sys.nvarchar(128),
    in_schematype int)
RETURNS TABLE (
    out_table_catalog sys.nvarchar(128),
    out_table_schema sys.nvarchar(128),
    out_table_name sys.nvarchar(128),
    out_column_name sys.nvarchar(128),
    out_ordinal_position int,
    out_column_default sys.nvarchar(4000),
    out_is_nullable sys.nvarchar(3),
    out_data_type sys.nvarchar,
    out_character_maximum_length int,
    out_character_octet_length int,
    out_numeric_precision int,
    out_numeric_precision_radix int,
    out_numeric_scale int,
    out_datetime_precision int,
    out_character_set_catalog sys.nvarchar(128),
    out_character_set_schema sys.nvarchar(128),
    out_character_set_name sys.nvarchar(128),
    out_collation_catalog sys.nvarchar(128),
    out_is_sparse int,
    out_is_column_set int,
    out_is_filestream int
    )
AS
$$
BEGIN
    RETURN QUERY
        SELECT CAST(table_catalog AS sys.nvarchar(128)),
            CAST(table_schema AS sys.nvarchar(128)),
            CAST(table_name AS sys.nvarchar(128)),
            CAST(column_name AS sys.nvarchar(128)),
            CAST(ordinal_position AS int),
            CAST(column_default AS sys.nvarchar(4000)),
            CAST(is_nullable AS sys.nvarchar(3)),
            CAST(data_type AS sys.nvarchar),
            CAST(character_maximum_length AS int),
            CAST(character_octet_length AS int),
            CAST(numeric_precision AS int),
            CAST(numeric_precision_radix AS int),
            CAST(numeric_scale AS int),
            CAST(datetime_precision AS int),
            CAST(character_set_catalog AS sys.nvarchar(128)),
            CAST(character_set_schema AS sys.nvarchar(128)),
            CAST(character_set_name AS sys.nvarchar(128)),
            CAST(collation_catalog AS sys.nvarchar(128)),
            CAST(is_sparse AS int),
            CAST(is_column_set AS int),
            CAST(is_filestream AS int)
        FROM sys.spt_columns_view_managed s_cv
        WHERE
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE in_catalog) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE in_owner) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE in_table) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE in_column) AND
        (in_schematype = 0 AND (s_cv.IS_SPARSE = 0) OR in_schematype = 1 OR in_schematype = 2 AND (s_cv.IS_SPARSE = 1));
END;
$$
language plpgsql;

CREATE PROCEDURE sys.sp_columns_managed
(
    "@Catalog" nvarchar(128) = NULL,
    "@Owner" nvarchar(128) = NULL,
    "@Table" nvarchar(128) = NULL,
    "@Column" nvarchar(128) = NULL,
    "@SchemaType" nvarchar(128) = 0) -- 0 = 'select *' behavior (default), 1 = all columns, 2 = columnset columns
AS
$$
BEGIN
    SELECT
        out_TABLE_CATALOG AS TABLE_CATALOG,
        out_TABLE_SCHEMA AS TABLE_SCHEMA,
        out_TABLE_NAME AS TABLE_NAME,
        out_COLUMN_NAME AS COLUMN_NAME,
        out_ORDINAL_POSITION AS ORDINAL_POSITION,
        out_COLUMN_DEFAULT AS COLUMN_DEFAULT,
        out_IS_NULLABLE AS IS_NULLABLE,
        out_DATA_TYPE AS DATA_TYPE,
        out_CHARACTER_MAXIMUM_LENGTH AS CHARACTER_MAXIMUM_LENGTH,
        out_CHARACTER_OCTET_LENGTH AS CHARACTER_OCTET_LENGTH,
        out_NUMERIC_PRECISION AS NUMERIC_PRECISION,
        out_NUMERIC_PRECISION_RADIX AS NUMERIC_PRECISION_RADIX,
        out_NUMERIC_SCALE AS NUMERIC_SCALE,
        out_DATETIME_PRECISION AS DATETIME_PRECISION,
        out_CHARACTER_SET_CATALOG AS CHARACTER_SET_CATALOG,
        out_CHARACTER_SET_SCHEMA AS CHARACTER_SET_SCHEMA,
        out_CHARACTER_SET_NAME AS CHARACTER_SET_NAME,
        out_COLLATION_CATALOG AS COLLATION_CATALOG,
        out_IS_SPARSE AS IS_SPARSE,
        out_IS_COLUMN_SET AS IS_COLUMN_SET,
        out_IS_FILESTREAM AS IS_FILESTREAM
    FROM
        sys.sp_columns_managed_internal(@Catalog, @Owner, "@Table", "@Column", @SchemaType) s_cv
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, IS_NULLABLE;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_managed TO PUBLIC;

-- BABEL-1797: initial support of sp_describe_undeclared_parameters
-- sys.sp_describe_undeclared_parameters_internal: internal function
-- For the result rows, can we create a template table for it?
create function sys.sp_describe_undeclared_parameters_internal(
 tsqlquery varchar(384),
    params varchar(384) = NULL
)
returns table (
 parameter_ordinal int, -- NOT NULL
 name sys.sysname, -- NOT NULL
 suggested_system_type_id int, -- NOT NULL
 suggested_system_type_name sys.nvarchar(256),
 suggested_max_length smallint, -- NOT NULL
 suggested_precision sys.tinyint, -- NOT NULL
 suggested_scale sys.tinyint, -- NOT NULL
 suggested_user_type_id int, -- NOT NULL
 suggested_user_type_database sys.sysname,
 suggested_user_type_schema sys.sysname,
 suggested_user_type_name sys.sysname,
 suggested_assembly_qualified_type_name sys.nvarchar(4000),
 suggested_xml_collection_id int,
 suggested_xml_collection_database sys.sysname,
 suggested_xml_collection_schema sys.sysname,
 suggested_xml_collection_name sys.sysname,
 suggested_is_xml_document sys.bit, -- NOT NULL
 suggested_is_case_sensitive sys.bit, -- NOT NULL
 suggested_is_fixed_length_clr_type sys.bit, -- NOT NULL
 suggested_is_input sys.bit, -- NOT NULL
 suggested_is_output sys.bit, -- NOT NULL
 formal_parameter_name sys.sysname,
 suggested_tds_type_id int, -- NOT NULL
 suggested_tds_length int -- NOT NULL
)
AS 'babelfishpg_tsql', 'sp_describe_undeclared_parameters_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_undeclared_parameters_internal TO PUBLIC;

CREATE PROCEDURE sys.sp_describe_undeclared_parameters (
 "@tsql" varchar(384),
    "@params" varchar(384) = NULL)
AS $$
BEGIN
 select * from sys.sp_describe_undeclared_parameters_internal(@tsql, @params);
 return 1;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_undeclared_parameters TO PUBLIC;

-- BABEL-1782
CREATE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
t3.rolname AS TABLE_OWNER,
t1.relname AS TABLE_NAME,
case
  when t1.relkind = 'v' then 'VIEW'
  else 'TABLE'
end AS TABLE_TYPE,
CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, pg_catalog.pg_roles AS t3
WHERE t1.relowner = t3.oid AND t1.relnamespace = t2.oid;
GRANT SELECT on sys.sp_tables_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_tables (
 "@table_name" sys.nvarchar(384),
    "@table_owner" sys.nvarchar(384) = '',
    "@table_qualifier" sys.sysname = '',
    "@table_type" sys.nvarchar(100) = '',
    "@fusepattern" sys.bit = '1')
AS $$
BEGIN
 DECLARE @_opt_view varchar(16) = ''
 DECLARE @_opt_table varchar(16) = ''
 IF (select count(*) from STRING_SPLIT(@table_type, ',') where trim(value) = 'VIEW') = 1
   BEGIN
  SET @_opt_view = 'VIEW'
   END
 IF (select count(*) from STRING_SPLIT(@table_type, ',') where trim(value) = 'TABLE') = 1
   BEGIN
  SET @_opt_table = 'TABLE'
   END
 IF @fUsePattern = '1'
   BEGIN
        select * from sys.sp_tables_view where
  (@table_name = '' or table_name like @table_name)
  and (@table_owner = '' or table_owner like @table_owner)
  and (@table_qualifier = '' or table_qualifier like @table_qualifier)
  and (@table_type = '' or table_type = @_opt_table or table_type = @_opt_view);
   END
 ELSE
   BEGIN
        select * from sys.sp_tables_view where
  (@table_name = '' or table_name = @table_name)
  and (@table_owner = '' or table_owner = @table_owner)
  and (@table_qualifier = '' or table_qualifier = @table_qualifier)
  and (@table_type = '' or table_type = @_opt_table or table_type = @_opt_view);
   END
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_tables TO PUBLIC;

CREATE FUNCTION sys.fn_mapped_system_error_list ()
returns table (sql_error_code int)
AS 'babelfishpg_tsql', 'babel_list_mapped_error'
LANGUAGE C IMMUTABLE STRICT;
GRANT ALL on FUNCTION sys.fn_mapped_system_error_list TO PUBLIC;
-- 21 "sql/babelfishpg_tsql.in" 2






SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
RESET client_min_messages;
