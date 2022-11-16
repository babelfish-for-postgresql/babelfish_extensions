-- 1 "sql/babelfishpg_tsql.in"
-- 1 "<built-in>"
-- 1 "<command-line>"
-- 31 "<command-line>"
-- 1 "/usr/include/stdc-predef.h" 1 3 4
-- 32 "<command-line>" 2
-- 1 "sql/babelfishpg_tsql.in"




SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- 1 "sql/collation.sql" 1
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

-- 8 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/datatype.sql" 1
-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;

CREATE DOMAIN sys.CURSOR AS REFCURSOR;

RESET enable_domain_typmod;

-- At this point, the hooks are loaded, so sys.name will pick up the correct
-- collation.
CREATE DOMAIN sys._ci_sysname AS sys.sysname;
-- 9 "sql/babelfishpg_tsql.in" 2
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
DECLARE
    v_string VARCHAR COLLATE "C";
    v_separator VARCHAR COLLATE "C";
BEGIN
 if length(separator) != 1 then
  RAISE EXCEPTION 'Invalid separator: %', separator USING HINT =
  'Separator must be length 1';
        else
         v_string := string; -- use COLLATE "C"
  v_separator := separator; -- use COLLATE "C"
  RETURN QUERY(SELECT cast(unnest(string_to_array(v_string, v_separator)) as varchar));
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

CREATE OR REPLACE FUNCTION sys.format_datetime(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR, IN data_type VARCHAR DEFAULT '') RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_datetime' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_datetime(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.format_numeric(IN value anyelement, IN format_pattern NVARCHAR,IN culture VARCHAR, IN data_type VARCHAR DEFAULT '', IN e_position INT DEFAULT -1) RETURNS sys.nvarchar
AS 'babelfishpg_tsql', 'format_numeric' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.format_numeric(IN anyelement, IN NVARCHAR, IN VARCHAR, IN VARCHAR, IN INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.FORMAT(IN arg anyelement, IN p_format_pattern NVARCHAR, IN p_culture VARCHAR default 'en-us')
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    arg_type regtype;
    v_temp_integer INTEGER;
BEGIN
    arg_type := pg_typeof(arg);

    CASE
        WHEN arg_type IN ('time'::regtype ) THEN
            RETURN sys.format_datetime(arg, p_format_pattern, p_culture, 'time');

        WHEN arg_type IN ('date'::regtype, 'sys.datetime'::regtype, 'sys.smalldatetime'::regtype, 'sys.datetime2'::regtype ) THEN
            RETURN sys.format_datetime(arg::timestamp, p_format_pattern, p_culture);

        WHEN arg_type IN ('sys.tinyint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'tinyint');

        WHEN arg_type IN ('smallint'::regtype) THEN
            RETURN sys.format_numeric(arg::SMALLINT, p_format_pattern, p_culture, 'smallint');

        WHEN arg_type IN ('integer'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'integer');

         WHEN arg_type IN ('bigint'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'bigint');

        WHEN arg_type IN ('numeric'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('sys.decimal'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');

        WHEN arg_type IN ('real'::regtype) THEN
            IF(p_format_pattern LIKE 'R%') THEN
                v_temp_integer := length(nullif((regexp_matches(arg::real::text, '(?<=\d*\.).*(?=[eE].*)')::text[])[1], ''));
            ELSE v_temp_integer:= -1;
            END IF;

            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'real', v_temp_integer);

        WHEN arg_type IN ('float'::regtype) THEN
            RETURN sys.format_numeric(arg, p_format_pattern, p_culture, 'float');

        WHEN pg_typeof(arg) IN ('sys.smallmoney'::regtype, 'sys.money'::regtype) THEN
            RETURN sys.format_numeric(arg::numeric, p_format_pattern, p_culture, 'numeric');
        ELSE
            RAISE datatype_mismatch;
        END CASE;
EXCEPTION
 WHEN datatype_mismatch THEN
  RAISE USING MESSAGE := format('Argument data type % is invalid for argument 1 of format function.', pg_typeof(arg)),
     DETAIL := 'Invalid datatype.',
     HINT := 'Convert it to valid datatype and try again.';
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.FORMAT(IN anyelement, IN NVARCHAR, IN VARCHAR) TO PUBLIC;
-- 10 "sql/babelfishpg_tsql.in" 2
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
    AS $$select (clock_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;


CREATE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', clock_timestamp()::pg_catalog.timestamp)::sys.datetime;$$
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

CREATE TABLE sys.babelfish_syslanguages (
    lang_id SMALLINT,
    lang_name_pg VARCHAR(30),
    lang_alias_pg VARCHAR(30),
    lang_name_mssql VARCHAR(30),
    lang_alias_mssql VARCHAR(30),
    territory VARCHAR(50),
    spec_culture VARCHAR(10),
    lang_data_jsonb JSONB
) WITH (OIDS = FALSE);
GRANT SELECT ON sys.babelfish_syslanguages TO PUBLIC;

CREATE TABLE sys.babelfish_configurations (
    configuration_id INT,
    name sys.nvarchar(35),
    value sys.sql_variant,
    minimum sys.sql_variant,
    maximum sys.sql_variant,
    value_in_use sys.sql_variant,
    description sys.nvarchar(255),
    is_dynamic sys.BIT,
    is_advanced sys.BIT,
    comment_syscurconfigs sys.nvarchar(255),
    comment_sysconfigures sys.nvarchar(255)
) WITH (OIDS = FALSE);
-- 11 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_languages.sql" 1


-- 12 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_babelfish_configurations.sql" 1
-- The value and value_in_use is set to 1 because SSMS-Babelfish connectivity requires it.

-- 13 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_function_helpers.sql" 1



CREATE OR REPLACE FUNCTION sys.babelfish_get_last_identity()
RETURNS INT8
AS 'babelfishpg_tsql', 'get_last_identity'
LANGUAGE C STABLE;

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
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.user_name_sysname()
RETURNS sys.SYSNAME AS
$BODY$
 SELECT COALESCE(sys.user_name(), '');
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.system_user()
RETURNS sys.nvarchar(128) AS
$BODY$
 SELECT sys.suser_name();
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.session_user()
RETURNS sys.nvarchar(128) AS
$BODY$
 SELECT sys.user_name();
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
    v_day VARCHAR COLLATE "C";
    v_dateval DATE;
    v_style SMALLINT;
    v_month SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
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
 RAISE NOTICE 'v_language=[%]', v_language;
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
                    WHEN (v_style = 131) THEN pg_catalog.format('%s/MM/YYYY', lpad(v_day, 2, ' '))
                    WHEN (v_style IN (0, 9, 100, 109)) THEN pg_catalog.format('$mnme$ %s YYYY', lpad(v_day, 2, ' '))
                 END;

    v_resstring := to_char(v_dateval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
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
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from DATE to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type DATE to %s.', trim(p_datatype)),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
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
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT (or INTEGER) data type.',
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
    v_day VARCHAR COLLATE "C";
    v_hour VARCHAR COLLATE "C";
    v_month SMALLINT;
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_language VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_fractsep VARCHAR COLLATE "C";
    v_monthname VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_maxlength SMALLINT;
    v_res_length SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^(?:DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?$';
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
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
        v_resmask := pg_catalog.format('$mnme$ %s YYYY %s:MI%s',
                            lpad(v_day, 2, ' '),
                            lpad(v_hour, 2, ' '),
                            CASE
                               WHEN (v_style IN (-1, 0, 100)) THEN 'AM'
                               ELSE pg_catalog.format(':SS:%sAM', v_fseconds)
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
        v_resmask := pg_catalog.format('DD $mnme$ YYYY HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (14, 114)) THEN
        v_resmask := pg_catalog.format('HH24:MI:SS%s%s', v_fractsep, v_fseconds);
    ELSIF (v_style IN (20, 120)) THEN
        v_resmask := 'YYYY-MM-DD HH24:MI:SS';
    ELSIF ((v_style = -1 AND v_src_datatype = 'DATETIME2') OR
           v_style IN (21, 25, 121))
    THEN
        v_resmask := pg_catalog.format('YYYY-MM-DD HH24:MI:SS.%s', v_fseconds);
    ELSIF (v_style = 22) THEN
        v_resmask := pg_catalog.format('MM/DD/YY %s:MI:SS AM', lpad(v_hour, 2, ' '));
    ELSIF (v_style = 23) THEN
        v_resmask := 'YYYY-MM-DD';
    ELSIF (v_style IN (126, 127)) THEN
        v_resmask := CASE v_src_datatype
                        WHEN 'SMALLDATETIME' THEN 'YYYY-MM-DDT$rem$HH24:MI:SS'
                        ELSE pg_catalog.format('YYYY-MM-DDT$rem$HH24:MI:SS.%s', v_fseconds)
                     END;
    ELSIF (v_style IN (130, 131)) THEN
        v_resmask := concat(CASE p_style
                               WHEN 131 THEN pg_catalog.format('%s/MM/YYYY ', lpad(v_day, 2, ' '))
                               ELSE pg_catalog.format('%s $mnme$ YYYY ', lpad(v_day, 2, ' '))
                            END,
                            pg_catalog.format('%s:MI:SS%s%sAM', lpad(v_hour, 2, ' '), v_fractsep, v_fseconds));
    END IF;

    v_resstring := to_char(v_datetimeval, v_resmask);
    v_resstring := pg_catalog.replace(v_resstring, '$mnme$', v_monthname);
    v_resstring := pg_catalog.replace(v_resstring, '$rem$', '');

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
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_src_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from %s to a character string.',
                                      v_style, v_src_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                      v_lengthexpr, lower(v_res_datatype), v_maxlength),
                    DETAIL := 'Use of incorrect size value of data type parameter during conversion process.',
                    HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
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
    v_err_message VARCHAR COLLATE "C";
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
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

    RETURN to_timestamp(pg_catalog.format('%s %s', to_char(v_hijri_date, 'DD.MM.YYYY'),
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
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_style SMALLINT;
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_fractsecs VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP,
                                                    ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_DOTPART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|',
                                                       TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP,
                                                       ')\s*', AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', HHMMSSFS_PART_REGEXP, '$');
    HHMMSSFS_DOT_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', HHMMSSFS_DOTPART_REGEXP, '$');
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    v_defmask4_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', DAYMM_REGEXP, '\s*\,\s*', COMPYEAR_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*($comp_month$)\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    DOT_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', SHORTYEAR_REGEXP, '$');
    DOT_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '$');
    SLASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', SHORTYEAR_REGEXP, '$');
    SLASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', FULLYEAR_REGEXP, '$');
    DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', SHORTYEAR_REGEXP, '$');
    DASH_FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '$');
    DOT_SLASH_DASH_YEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP, '$');
    YEAR_DOTMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    YEAR_SLASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*/\s*', DAYMM_REGEXP, '\s*/\s*', DAYMM_REGEXP, '$');
    YEAR_DASHMASK_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    YEAR_DOT_SLASH_DASH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '$');
    DIGITMASK1_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{6}$';
    DIGITMASK2_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\d{8}$';
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
        v_datestring := trim(regexp_pg_catalog.replace(v_datestring, HHMMSSFS_PART_REGEXP, '', 'gi'));
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

    v_defmask1_regexp := pg_catalog.replace(v_defmask1_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask2_regexp := pg_catalog.replace(v_defmask2_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask3_regexp := pg_catalog.replace(v_defmask3_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask4_regexp := pg_catalog.replace(v_defmask4_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask5_regexp := pg_catalog.replace(v_defmask5_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask6_regexp := pg_catalog.replace(v_defmask6_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask7_regexp := pg_catalog.replace(v_defmask7_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask8_regexp := pg_catalog.replace(v_defmask8_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask9_regexp := pg_catalog.replace(v_defmask9_regexp, '$comp_month$', v_compmonth_regexp);
    v_defmask10_regexp := pg_catalog.replace(v_defmask10_regexp, '$comp_month$', v_compmonth_regexp);

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
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to DATE.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string doesn''t follow style %s.', v_style),
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
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_day VARCHAR COLLATE "C";
    v_year VARCHAR COLLATE "C";
    v_month VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_hours VARCHAR COLLATE "C";
    v_hijridate DATE;
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_leftpart VARCHAR COLLATE "C";
    v_middlepart VARCHAR COLLATE "C";
    v_rightpart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_res_datatype VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    v_lang_metadata_json JSONB;
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat(TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '*\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '*\s*($comp_month$)\s*', FULLYEAR_REGEXP,
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{6}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*\d{8}\s*(', HHMMSSFS_PART_REGEXP, ')?$');
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

    IF (v_datetimestring ~* pg_catalog.replace(DEFMASK1_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK2_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK3_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK4_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK5_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK6_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK7_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK8_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK9_0_REGEXP, '$comp_month$', v_compmonth_regexp) OR
        v_datetimestring ~* pg_catalog.replace(DEFMASK10_0_REGEXP, '$comp_month$', v_compmonth_regexp))
    THEN
        IF ((v_style IN (127, 130, 131) AND v_res_datatype IN ('DATETIME', 'SMALLDATETIME')) OR
            (v_style IN (130, 131) AND v_res_datatype = 'DATETIME2'))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF ((v_datestring ~* pg_catalog.replace(DEFMASK1_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK2_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK3_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK4_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK5_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK6_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK7_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
             v_datestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
            v_res_datatype = 'DATETIME2')
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK3_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK4_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK5_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[3], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK6_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[3];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK7_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := v_regmatch_groups[1];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := v_regmatch_groups[2];

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
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
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to %s.', v_style, v_res_datatype),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string doesn''t follow style %s.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
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
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_daypart VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_minutes SMALLINT;
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_datatype_groups TEXT[];
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
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
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from VARCHAR to TIME.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_hours VARCHAR COLLATE "C";
    v_style SMALLINT;
    v_scale SMALLINT;
    v_resmask VARCHAR COLLATE "C";
    v_fseconds VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_resstring VARCHAR COLLATE "C";
    v_lengthexpr VARCHAR COLLATE "C";
    v_res_length SMALLINT;
    v_res_datatype VARCHAR COLLATE "C";
    v_src_datatype VARCHAR COLLATE "C";
    v_res_maxlength SMALLINT;
    VARCHAR_MAX CONSTANT SMALLINT := 8000;
    NVARCHAR_MAX CONSTANT SMALLINT := 4000;
    -- We use the regex below to make sure input p_datatype is one of them
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*$';
    -- We use the regex below to get the length of the datatype, if specified
    -- For example, to get the '10' out of 'varchar(10)'
    DATATYPE_MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:CHAR|NCHAR|VARCHAR|NVARCHAR|CHARACTER VARYING)\s*\(\s*(\d+|MAX)\s*\)\s*$';
    SRCDATATYPE_MASK_REGEXP VARCHAR COLLATE "C" := '^\s*(?:TIME)\s*(?:\s*\(\s*(\d+)\s*\)\s*)?\s*$';
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
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', v_hours, v_fseconds)
                     END;
    ELSIF (v_style IN (13, 14, 21, 25, 113, 114, 121, 126, 127))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN 'HH24:MI:SS'
                        ELSE concat('HH24:MI:SS.', v_fseconds)
                     END;
    ELSIF (v_style = 22)
    THEN
        v_resmask := pg_catalog.format('%s:MI:SS AM', lpad(v_hours, 2, ' '));
    ELSIF (v_style IN (130, 131))
    THEN
        v_resmask := CASE
                        WHEN (char_length(v_fseconds) = 0) THEN concat(lpad(v_hours, 2, ' '), ':MI:SSAM')
                        ELSE pg_catalog.format('%s:MI:SS.%sAM', lpad(v_hours, 2, ' '), v_fseconds)
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
       RAISE USING MESSAGE := pg_catalog.format('The source data type scale (%s) given to the convert specification exceeds the maximum allowable value (7).',
                                     v_scale),
                   DETAIL := 'Use of incorrect scale value of source data type parameter during conversion process.',
                   HINT := 'Change scale component of source data type parameter to the allowable value and try again.';

   WHEN interval_field_overflow THEN
       RAISE USING MESSAGE := pg_catalog.format('The size (%s) given to the convert specification ''%s'' exceeds the maximum allowed for any data type (%s).',
                                     v_lengthexpr, lower(v_res_datatype), v_res_maxlength),
                   DETAIL := 'Use of incorrect size value of target data type parameter during conversion process.',
                   HINT := 'Change size component of data type parameter to the allowable value and try again.';

    WHEN escape_character_conflict THEN
        RAISE USING MESSAGE := 'Argument data type NUMERIC is invalid for argument 4 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from TIME to a character string.', v_style),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''CHAR(n|MAX)'', ''NCHAR(n|MAX)'', ''VARCHAR(n|MAX)'', ''NVARCHAR(n|MAX)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := pg_catalog.format('Error converting data type TIME to %s.',
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
                             WHEN (v_short_year::NUMERIC > p_year_cutoff) THEN v_full_year - 100
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_locale_parts TEXT[] COLLATE "C";
    v_lang_data_jsonb JSONB;
    v_lang_spec_culture VARCHAR COLLATE "C";
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
                  FROM sys.babelfish_syslanguages
                 WHERE spec_culture = v_lang_spec_culture;
            ELSE
                SELECT lang_data_jsonb
                  INTO STRICT v_lang_data_jsonb
                  FROM sys.babelfish_syslanguages
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
                      FROM sys.babelfish_syslanguages
                     WHERE spec_culture = v_lang_spec_culture;
                ELSE
                    v_locale_parts := string_to_array(v_lang_spec_culture, '-');

                    SELECT lang_data_jsonb
                      INTO STRICT v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
                     WHERE lang_name_pg = v_locale_parts[1]
                       AND territory = v_locale_parts[2];
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    v_lang_spec_culture := 'EN_US';

                    SELECT lang_data_jsonb
                      INTO v_lang_data_jsonb
                      FROM sys.babelfish_syslanguages
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
        RAISE USING MESSAGE := pg_catalog.format('The language metadata JSON value extracted from chache is not a valid JSON object.',
                                      p_lang_spec_culture),
                    HINT := 'Drop the current session, fix the appropriate record in "sys.babelfish_syslanguages" table, and try again after reconnection.';

    WHEN OTHERS THEN
        RAISE USING MESSAGE := pg_catalog.format('"%s" is not a valid special culture or language name parameter.',
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
    v_fractsecs VARCHAR COLLATE "C";
    v_pureplaces VARCHAR COLLATE "C";
    v_rnd_fractsecs INTEGER;
    v_fractsecs_len INTEGER;
    v_pureplaces_len INTEGER;
    v_err_message VARCHAR COLLATE "C";
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

    v_fractsecs := concat(pg_catalog.replace(rpad('', v_decplaces), ' ', '0'), v_rnd_fractsecs);

    RETURN substring(v_fractsecs, 1, CASE
                                        WHEN (v_scale >= 7) THEN 6
                                        ELSE v_scale
                                     END);
EXCEPTION
    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
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
        RAISE USING MESSAGE := pg_catalog.format('Can not convert value "%s" to a correct month number.',
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
    v_hours VARCHAR COLLATE "C";
    v_minutes VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C";
    v_fractsecs VARCHAR COLLATE "C";
    v_daypart VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_timeunit VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '\:', TIMEUNIT_REGEXP,
                                               '(?:\.|\:)', FRACTSECS_REGEXP, '$');
    HHMMSS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HHMMFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, '$');
    HHMM_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '$');
    HH_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', TIMEUNIT_REGEXP, '$');
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.', v_err_message),
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
        RAISE USING MESSAGE := pg_catalog.format('Can not convert value "%s" to a correct weekday number.',
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

-- Remove single pair of either square brackets or double-quotes from outer ends if present
-- If name begins with a delimiter but does not end with the matching delimiter return NULL
-- Otherwise, return the name unchanged
CREATE OR REPLACE FUNCTION babelfish_remove_delimiter_pair(IN name TEXT)
RETURNS TEXT AS
$BODY$
BEGIN
    IF name IN('[' COLLATE "C", ']' COLLATE "C", '"' COLLATE "C") THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '[' COLLATE "C" AND right(name, 1) = ']' COLLATE "C" THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '[' COLLATE "C" AND right(name, 1) != ']' COLLATE "C" THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '[' COLLATE "C" AND right(name, 1) = ']' COLLATE "C" THEN
        RETURN NULL;

    ELSIF length(name) >= 2 AND left(name, 1) = '"' COLLATE "C" AND right(name, 1) = '"' COLLATE "C" THEN
        IF length(name) = 2 THEN
            RETURN '';
        ELSE
            RETURN substring(name from 2 for length(name)-2);
        END IF;
    ELSIF length(name) >= 2 AND left(name, 1) = '"' COLLATE "C" AND right(name, 1) != '"' COLLATE "C" THEN
        RETURN NULL;
    ELSIF length(name) >= 2 AND left(name, 1) != '"' COLLATE "C" AND right(name, 1) = '"' COLLATE "C" THEN
        RETURN NULL;

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
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_seconds NUMERIC := 0;
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
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
        v_datestring := pg_catalog.replace(v_datestring, v_weekdaynames[1], ' ');
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
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
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

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
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

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
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
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type DATE using culture ''%s''.',
                                      p_datestring, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR COLLATE "C";
    v_error_message VARCHAR COLLATE "C";
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_datetimestring VARCHAR COLLATE "C";
    v_seconds VARCHAR COLLATE "C" := '0';
    v_fseconds VARCHAR COLLATE "C" := '0';
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_datetime TIMESTAMP(6) WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME|DATETIME2)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
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
        v_datetimestring := pg_catalog.replace(v_datetimestring, v_weekdaynames[1], ' ');
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
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
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

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
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

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');
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
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_datetimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME'', ''DATETIME2''/''DATETIME2(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
    v_day VARCHAR COLLATE "C";
    v_year SMALLINT;
    v_month VARCHAR COLLATE "C";
    v_res_date DATE;
    v_scale SMALLINT;
    v_hijridate DATE;
    v_culture VARCHAR COLLATE "C";
    v_dayparts TEXT[];
    v_resmask VARCHAR COLLATE "C";
    v_datatype VARCHAR COLLATE "C";
    v_raw_year VARCHAR COLLATE "C";
    v_left_part VARCHAR COLLATE "C";
    v_right_part VARCHAR COLLATE "C";
    v_resmask_fi VARCHAR COLLATE "C";
    v_timestring VARCHAR COLLATE "C";
    v_correctnum VARCHAR COLLATE "C";
    v_weekdaynum SMALLINT;
    v_err_message VARCHAR COLLATE "C";
    v_date_format VARCHAR COLLATE "C";
    v_weekdaynames TEXT[];
    v_hours SMALLINT := 0;
    v_srctimestring VARCHAR COLLATE "C";
    v_minutes SMALLINT := 0;
    v_res_datatype VARCHAR COLLATE "C";
    v_error_message VARCHAR COLLATE "C";
    v_found BOOLEAN := TRUE;
    v_compday_regexp VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_datatype_groups TEXT[];
    v_seconds VARCHAR COLLATE "C" := '0';
    v_fseconds VARCHAR COLLATE "C" := '0';
    v_compmonth_regexp VARCHAR COLLATE "C";
    v_lang_metadata_json JSONB;
    v_resmask_cnt SMALLINT := 10;
    v_res_time TIME WITHOUT TIME ZONE;
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{3,4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M|ص|م)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    MASKSEPONE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-)?';
    MASKSEPTWO_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|\.|,)';
    MASKSEPTWO_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:\s|/|-|,)';
    MASKSEPTHREE_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(?:/|-|\.|,)';
    TIME_MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|\.|,)*';
    TIME_MASKSEP_FI_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\s|,)*';
    WEEKDAYAMPM_START_REGEXP CONSTANT VARCHAR COLLATE "C" := '(^|[[:digit:][:space:]\.,])';
    WEEKDAYAMPM_END_REGEXP CONSTANT VARCHAR COLLATE "C" := '([[:digit:][:space:]\.,]|$)(?=[^/-]|$)';
    CORRECTNUM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:([+-]\d{1,4})(?:[[:space:]\.,]|[AP]M|ص|م|$))';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(TIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    ANNO_DOMINI_REGEXP VARCHAR COLLATE "C" := '(AD|A\.D\.)';
    ANNO_DOMINI_COMPREGEXP VARCHAR COLLATE "C" := concat(WEEKDAYAMPM_START_REGEXP, ANNO_DOMINI_REGEXP, WEEKDAYAMPM_END_REGEXP);
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    HHMMSSFS_PART_FI_REGEXP CONSTANT VARCHAR COLLATE "C" :=
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
    v_defmask1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP, '$');
    v_defmask1_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_REGEXP,
                                        AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_REGEXP, AMPM_REGEXP, TIME_MASKSEP_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                        CORRECTNUM_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP, '$');
    v_defmask2_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP,
                                           AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(?:(?:[\.|,]+', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, TIME_MASKSEP_FI_REGEXP, CORRECTNUM_REGEXP, '?)|',
                                           CORRECTNUM_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask3_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, ')|',
                                        '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', TIME_MASKSEP_REGEXP, AMPM_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask3_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '[\./]?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)',
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask4_0_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_1_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '(?:\s|,)+',
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask4_2_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP,
                                          '\s*[\.]+', TIME_MASKSEP_REGEXP,
                                          DAYMM_REGEXP, '\s*(', AMPM_REGEXP, ')',
                                          TIME_MASKSEP_REGEXP, '$');
    v_defmask5_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask5_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask6_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask6_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:\s*[\.])?',
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask7_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        FULLYEAR_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask7_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           FULLYEAR_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask8_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                        '(?:[\.|,]+', AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                        DAYMM_REGEXP,
                                        '(?:[\.|,]+', AMPM_REGEXP, ')?',
                                        TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask8_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_FI_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)|',
                                           '(?:[,]+', AMPM_REGEXP, '))', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '(?:(?:[\,]+|\s*/\s*)', AMPM_REGEXP, ')?',
                                           TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask9_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(',
                                        HHMMSSFS_PART_REGEXP,
                                        ')', TIME_MASKSEP_REGEXP, '$');
    v_defmask9_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '(',
                                           HHMMSSFS_PART_FI_REGEXP,
                                           ')', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask10_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask10_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)?', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask11_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask11_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                           '($comp_month$)',
                                           '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                           DAYMM_REGEXP,
                                           '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask12_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask12_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask13_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_REGEXP, '$');
    v_defmask13_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask14_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)'
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask14_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)'
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_FI_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_FI_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask15_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask15_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask16_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                         COMPYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask16_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)', TIME_MASKSEP_REGEXP,
                                            COMPYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask17_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask17_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask18_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                         '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP, '$');
    v_defmask18_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, '?', TIME_MASKSEP_REGEXP, '(?:', AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))?)|',
                                            '(?:(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '(?=(?:[[:space:]\.,])+))))', TIME_MASKSEP_REGEXP,
                                            '($comp_month$)',
                                            TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP, '$');
    v_defmask19_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_REGEXP, '(', HHMMSSFS_PART_REGEXP, ')?', TIME_MASKSEP_REGEXP,
                                         '($comp_month$)',
                                         '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                         FULLYEAR_REGEXP,
                                         '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                         '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                         DAYMM_REGEXP,
                                         '((?:(?:\s|\.|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_REGEXP, '))?', TIME_MASKSEP_REGEXP, '$');
    v_defmask19_fi_regexp VARCHAR COLLATE "C" := concat('^', TIME_MASKSEP_FI_REGEXP, '(', HHMMSSFS_PART_FI_REGEXP, ')?', TIME_MASKSEP_FI_REGEXP,
                                            '($comp_month$)',
                                            '(?:', MASKSEPTHREE_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)?', TIME_MASKSEP_REGEXP,
                                            FULLYEAR_REGEXP,
                                            '(?:(?:', MASKSEPTWO_REGEXP, TIME_MASKSEP_REGEXP, AMPM_REGEXP, '?)|',
                                            '(?:', TIME_MASKSEP_REGEXP, AMPM_REGEXP, '))', TIME_MASKSEP_REGEXP,
                                            DAYMM_REGEXP,
                                            '((?:(?:\s|,)+|', AMPM_REGEXP, ')(?:', HHMMSSFS_PART_FI_REGEXP, '))?', TIME_MASKSEP_FI_REGEXP, '$');
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
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
        v_srctimestring := pg_catalog.replace(v_srctimestring, v_weekdaynames[1], ' ');
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
        v_resmask := pg_catalog.replace(CASE v_resmask_cnt
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

        v_resmask_fi := pg_catalog.replace(CASE v_resmask_cnt
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

        v_timestring := pg_catalog.replace(regexp_replace(v_timestring, '\.?[AP]M|ص|م|\s|\,|\.\D|[\.|:]$', '', 'gi'), ':.', ':');

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
        RAISE USING MESSAGE := pg_catalog.format('Error converting string value ''%s'' into data type %s using culture ''%s''.',
                                      p_srctimestring, v_res_datatype, p_culture),
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Source data type should be ''TIME'' or ''TIME(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid attributes specified for data type %s.', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := CASE char_length(coalesce(CONVERSION_LANG, ''))
                                  WHEN 0 THEN pg_catalog.format('The culture parameter ''%s'' provided in the function call is not supported.',
                                                     p_culture)
                                  ELSE pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                              CONVERSION_LANG)
                               END,
                    DETAIL := 'Passed incorrect value for "p_culture" parameter or compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Check "p_culture" input parameter value, correct it if needed, and try again. Also check CONVERSION_LANG constant value.';

    WHEN invalid_text_representation THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := substring(lower(v_err_message), 'integer\:\s\"(.*)\"');

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to SMALLINT data type.',
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
        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', trim(p_fractseconds)),
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
    var_job_cmd := pg_catalog.format(proc_name_mask, par_job_id, '1');
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
-- 7280 "sql/sys_function_helpers.sql"
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


          WHEN var_freq_subday_type = 4 THEN pg_catalog.format('cron(*/%s * * * ? *)', var_freq_subday_interval::character varying)
          WHEN var_freq_subday_type = 8 THEN pg_catalog.format('cron(0 */%s * * ? *)', var_freq_subday_interval::character varying)
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
RETURNS sys.DATETIME
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


CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement)
RETURNS sys.DATETIME
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
 v_format VARCHAR COLLATE "C";
 v_moneyval NUMERIC(19,4) := p_moneyval::NUMERIC(19,4);
 v_moneysign NUMERIC(19,4) := sign(v_moneyval);
 v_moneyabs NUMERIC(19,4) := abs(v_moneyval);
 v_digits SMALLINT;
 v_integral_digits SMALLINT;
 v_decimal_digits SMALLINT;
 v_res_length SMALLINT;
 MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
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
  RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from MONEY to a character string.', v_style),
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
 v_format VARCHAR COLLATE "C";
 v_floatval NUMERIC := abs(p_floatval);
 v_digits SMALLINT;
 v_integral_digits SMALLINT;
 v_decimal_digits SMALLINT;
 v_sign SMALLINT := sign(p_floatval);
 v_result TEXT;
 v_res_length SMALLINT;
 MASK_REGEXP CONSTANT VARCHAR COLLATE "C" := '^\s*(?:character varying)\s*\(\s*(\d+|MAX)\s*\)\s*$';
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
  RAISE USING MESSAGE := pg_catalog.format('%s is not a valid style number when converting from FLOAT to a character string.', v_style),
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
-- 9989 "sql/sys_function_helpers.sql"
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

CREATE OR REPLACE FUNCTION babelfish_get_name_delimiter_pos(name TEXT)
RETURNS INTEGER
AS $$
DECLARE
    pos int;
BEGIN
    IF (length(name) <= 2 AND (position('"' IN name) != 0 OR position(']' IN name) != 0 OR position('[' IN name) != 0))
        -- invalid name
        THEN RETURN 0;
    ELSIF left(name, 1) = '[' THEN
        pos = position('].' IN name);
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 1;
        END IF;
    ELSIF left(name, 1) = '"' THEN
        -- search from position 1 in case name starts with ".
        pos = position('".' IN right(name, length(name) - 1));
        IF pos = 0 THEN
            -- invalid name
            RETURN 0;
        ELSE
            RETURN pos + 2;
        END IF;
    ELSE
        RETURN position('.' IN name);
    END IF;
END;
$$
LANGUAGE plpgsql;

-- valid names are db_name.schema_name.object_name or schema_name.object_name or object_name
CREATE OR REPLACE FUNCTION sys.babelfish_split_object_name(
    name TEXT,
    OUT db_name TEXT,
    OUT schema_name TEXT,
    OUT object_name TEXT)
AS $$
DECLARE
    lower_object_name text;
    names text[2];
    counter int;
    cur_pos int;
BEGIN
    lower_object_name = lower(rtrim(name));

    counter = 1;
    cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);

    -- Parse user input into names split by '.'
    WHILE cur_pos > 0 LOOP
        IF counter > 3 THEN
            -- Too many names provided
            RETURN;
        END IF;

        names[counter] = babelfish_remove_delimiter_pair(rtrim(left(lower_object_name, cur_pos - 1)));

        -- invalid name
        IF names[counter] IS NULL THEN
            RETURN;
        END IF;

        lower_object_name = substring(lower_object_name from cur_pos + 1);
        counter = counter + 1;
        cur_pos = babelfish_get_name_delimiter_pos(lower_object_name);
    END LOOP;

    CASE counter
        WHEN 1 THEN
            db_name = NULL;
            schema_name = NULL;
        WHEN 2 THEN
            db_name = NULL;
            schema_name = sys.babelfish_truncate_identifier(names[1]);
        WHEN 3 THEN
            db_name = sys.babelfish_truncate_identifier(names[1]);
            schema_name = sys.babelfish_truncate_identifier(names[2]);
        ELSE
            RETURN;
    END CASE;

    -- Assign each name accordingly
    object_name = sys.babelfish_truncate_identifier(babelfish_remove_delimiter_pair(rtrim(lower_object_name)));
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_has_any_privilege(
    perm_target_type text,
    schema_name text,
    object_name text)
RETURNS INTEGER
AS
$BODY$
DECLARE
    relevant_permissions text[];
    namespace_id oid;
    function_signature text;
    qualified_name text;
    permission text;
BEGIN
 IF perm_target_type IS NULL OR perm_target_type COLLATE sys.database_default NOT IN('table', 'function', 'procedure')
        THEN RETURN NULL;
    END IF;

    relevant_permissions := (
        SELECT CASE
            WHEN perm_target_type = 'table' COLLATE sys.database_default
                THEN '{"select", "insert", "update", "delete", "references"}'
            WHEN perm_target_type = 'column' COLLATE sys.database_default
                THEN '{"select", "update", "references"}'
            WHEN perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
                THEN '{"execute"}'
        END
    );

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = schema_name COLLATE sys.database_default;

    IF perm_target_type COLLATE sys.database_default IN ('function', 'procedure')
        THEN SELECT oid::regprocedure
                INTO function_signature
                FROM pg_catalog.pg_proc
                WHERE proname = object_name COLLATE sys.database_default
                    AND pronamespace = namespace_id;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', schema_name, '"."', object_name, '"');

    FOREACH permission IN ARRAY relevant_permissions
    LOOP
        IF perm_target_type = 'table' COLLATE sys.database_default AND has_table_privilege(qualified_name, permission)::integer = 1
            THEN RETURN 1;
        ELSIF perm_target_type COLLATE sys.database_default IN ('function', 'procedure') AND has_function_privilege(function_signature, permission)::integer = 1
            THEN RETURN 1;
        END IF;
    END LOOP;
    RETURN 0;
END
$BODY$
LANGUAGE plpgsql;

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







CREATE OR REPLACE FUNCTION sys.babelfish_get_pltsql_function_signature(IN funcoid OID)
RETURNS text
AS 'babelfishpg_tsql', 'get_pltsql_function_signature' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.num_days_in_date(IN d1 INTEGER, IN m1 INTEGER, IN y1 INTEGER) RETURNS INTEGER AS $$
DECLARE
 i INTEGER;
 n1 INTEGER;
BEGIN
 n1 = y1 * 365 + d1;
 FOR i in 0 .. m1-2 LOOP
  IF (i = 0 OR i = 2 OR i = 4 OR i = 6 OR i = 7 OR i = 9 OR i = 11) THEN
   n1 = n1 + 31;
  ELSIF (i = 3 OR i = 5 OR i = 8 OR i = 10) THEN
   n1 = n1 + 30;
  ELSIF (i = 1) THEN
   n1 = n1 + 28;
  END IF;
 END LOOP;
 IF m1 <= 2 THEN
  y1 = y1 - 1;
 END IF;
 n1 = n1 + (y1/4 - y1/100 + y1/400);

 return n1;
END
$$
LANGUAGE plpgsql;
-- 14 "sql/babelfishpg_tsql.in" 2
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

-- Helper function to support the FOR JSON clause
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_text(query text, mode int, include_null_value boolean,
           without_array_wrappers boolean, root_name text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_query_to_json_text'
LANGUAGE C IMMUTABLE COST 100;

-- User and Login Functions
CREATE OR REPLACE FUNCTION sys.user_name(IN id OID DEFAULT NULL)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'user_name'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_constraintdef(IN constraint_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_constraintdef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_functiondef(IN function_id OID DEFAULT NULL)
RETURNS text
AS 'babelfishpg_tsql', 'tsql_get_functiondef'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tsql_get_returnTypmodValue(IN function_id OID DEFAULT NULL)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_get_returnTypmodValue'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.user_id(IN user_name TEXT DEFAULT NULL)
RETURNS OID
AS 'babelfishpg_tsql', 'user_id'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.suser_name_internal(IN server_user_id OID)
RETURNS sys.NVARCHAR(128)
AS 'babelfishpg_tsql', 'suser_name'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name(IN server_user_id OID)
RETURNS sys.NVARCHAR(128) AS $$
    SELECT CASE
        WHEN server_user_id IS NULL THEN NULL
        ELSE sys.suser_name_internal(server_user_id)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_name()
RETURNS sys.NVARCHAR(128)
AS $$
    SELECT sys.suser_name_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_name but
-- with a different input data type
CREATE OR REPLACE FUNCTION sys.suser_sname(IN server_user_sid SYS.VARBINARY(85))
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name(CAST(server_user_sid AS INT));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sname()
RETURNS SYS.NVARCHAR(128)
AS $$
    SELECT sys.suser_name();
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id_internal(IN login TEXT)
RETURNS OID
AS 'babelfishpg_tsql', 'suser_id'
LANGUAGE C IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id(IN login TEXT)
RETURNS OID AS $$
    SELECT CASE
        WHEN login IS NULL THEN NULL
        ELSE sys.suser_id_internal(login)
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_id()
RETURNS OID
AS $$
    SELECT sys.suser_id_internal(NULL);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

-- Since SIDs are currently not supported in Babelfish, this essentially behaves the same as suser_id but
-- with different input/output data types. The second argument will be ignored as its functionality is not supported
CREATE OR REPLACE FUNCTION sys.suser_sid(IN login SYS.SYSNAME, IN Param2 INT DEFAULT NULL)
RETURNS SYS.VARBINARY(85) AS $$
    SELECT CASE
    WHEN login = ''
        THEN CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85))
    ELSE
        CAST(CAST(sys.suser_id(login) AS INT) AS SYS.VARBINARY(85))
    END;
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.suser_sid()
RETURNS SYS.VARBINARY(85)
AS $$
    SELECT CAST(CAST(sys.suser_id() AS INT) AS SYS.VARBINARY(85));
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

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
LANGUAGE SQL STABLE;

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

CREATE OR REPLACE FUNCTION sys.checksum(VARIADIC arr TEXT[])
RETURNS INTEGER
AS 'babelfishpg_tsql', 'checksum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

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

   v_calc_seconds := pg_catalog.format('%s.%s',
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
      RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                  DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                  HINT := 'Change "precision" parameter to the proper value and try again.';

   WHEN invalid_datetime_format THEN
      RAISE USING MESSAGE := 'Cannot construct data type DATETIME2, some of the arguments have values which are not valid.',
                  DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                  HINT := 'Check each input argument belongs to the valid range and try again.';

   WHEN numeric_value_out_of_range THEN
      GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
      v_err_message := upper(split_part(v_err_message, ' ', 1));

      RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                  DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                  HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
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

    v_calc_seconds := pg_catalog.format('%s.%s',
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                    HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
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
    IF ($1::VARCHAR COLLATE "C" ~ '^\s*$') THEN
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

    -- IF ($1::VARCHAR ~ '^\s*$') THEN
    IF (expr COLLATE "C" ~ '^\s*$') THEN
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
        db_name text collate "C";
        bbf_schema_name text collate "C";
        schema_name text collate "C";
        schema_oid oid;
        obj_name text collate "C";
        is_temp_object boolean;
        obj_type char(2) collate "C";
        cs_as_object_name text collate "C" := object_name;
BEGIN
        obj_type = object_type;
        id = null;
        schema_oid = NULL;

        SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, obj_name
        FROM babelfish_split_object_name(cs_as_object_name) s;

        -- Invalid object_name
        IF obj_name IS NULL OR obj_name = '' collate sys.database_default THEN
            RETURN NULL;
        END IF;

        IF bbf_schema_name IS NULL OR bbf_schema_name = '' collate sys.database_default THEN
            bbf_schema_name := sys.schema_name();
        END IF;

        schema_name := sys.bbf_get_current_physical_schema_name(bbf_schema_name);

        -- Check if looking for temp object.
        is_temp_object = left(obj_name, 1) = '#' collate sys.database_default;

        -- Can only search in current database. Allowing tempdb for temp objects.
        IF db_name IS NOT NULL AND db_name collate sys.database_default <> db_name() AND db_name collate sys.database_default <> 'tempdb' THEN
            RAISE EXCEPTION 'Can only do lookup in current database.';
        END IF;

        IF schema_name IS NULL OR schema_name = '' collate sys.database_default THEN
            RETURN NULL;
        END IF;

        -- Searching within a schema. Get schema oid.
        schema_oid = (SELECT oid FROM pg_namespace WHERE nspname = schema_name);
        IF schema_oid IS NULL THEN
            RETURN NULL;
        END IF;

        if obj_type <> '' then
            case
                -- Schema does not apply as much to temp objects.
                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and is_temp_object then
             id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);

                when upper(object_type) in ('S', 'U', 'V', 'IT', 'ET', 'SO') and not is_temp_object then
             id := (select oid from pg_class where lower(relname) collate sys.database_default = obj_name
                            and relnamespace = schema_oid limit 1);

                when upper(object_type) in ('C', 'D', 'F', 'PK', 'UQ') then
             id := (select oid from pg_constraint where lower(conname) collate sys.database_default = obj_name
                            and connamespace = schema_oid limit 1);

                when upper(object_type) in ('AF', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TF', 'RF', 'X') then
             id := (select oid from pg_proc where lower(proname) collate sys.database_default = obj_name
                            and pronamespace = schema_oid limit 1);

                when upper(object_type) in ('TR', 'TA') then
             id := (select oid from pg_trigger where lower(tgname) collate sys.database_default = obj_name limit 1);

                -- Throwing exception as a reminder to add support in the future.
                when upper(object_type) collate sys.database_default in ('R', 'EC', 'PG', 'SN', 'SQ', 'TT') then
                    RAISE EXCEPTION 'Object type currently unsupported.';

                -- unsupported obj_type
                else id := null;
            end case;
        else
            if not is_temp_object then
                id := (
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
                    limit 1
                );
            else
                -- temp object without "object_type" in-argument
                id := (select reloid from sys.babelfish_get_enr_list() where lower(relname) collate sys.database_default = obj_name limit 1);
            end if;
        end if;

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
  WHEN char_length($1) < char_length(pg_catalog.replace($1, '.', '')) + 4
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

    v_calc_seconds := pg_catalog.format('%s.%s',
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
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_precision),
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type time, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        GET STACKED DIAGNOSTICS v_err_message = MESSAGE_TEXT;
        v_err_message := upper(split_part(v_err_message, ' ', 1));

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to cast to %s data type.', v_err_message),
                    DETAIL := pg_catalog.format('Source value is out of %s data type range.', v_err_message),
                    HINT := pg_catalog.format('Correct the source value you are trying to cast to %s data type and try again.',
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

        RAISE USING MESSAGE := pg_catalog.format('Error while trying to convert "%s" value to NUMERIC data type.', v_err_message),
                    DETAIL := 'Supplied string value contains illegal characters.',
                    HINT := 'Correct supplied value, remove all illegal characters and try again.';
END;
$BODY$
LANGUAGE plpgsql
VOLATILE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.has_dbaccess(database_name SYSNAME) RETURNS INTEGER AS
'babelfishpg_tsql', 'has_dbaccess'
LANGUAGE C STRICT;

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

CREATE OR REPLACE FUNCTION sys.DATETIMEOFFSETFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER,
                                                               IN p_seconds INTEGER,
                                                               IN p_fractions INTEGER,
                                                               IN p_hour_offset INTEGER,
                                                               IN p_minute_offset INTEGER,
                                                               IN p_precision NUMERIC)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_err_message SYS.VARCHAR;
    v_fractions SYS.VARCHAR;
    v_precision SMALLINT;
    v_calc_seconds NUMERIC;
    v_resdatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    v_sign pg_catalog.text;
BEGIN
    v_fractions := p_fractions::SYS.VARCHAR;
    IF p_precision IS NULL THEN
        RAISE EXCEPTION 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions.';
    END IF;
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL OR p_seconds IS NULL OR p_fractions IS NULL
            OR p_hour_offset IS NULL OR p_minute_offset is NULL THEN
        RETURN NULL;
    END IF;
    v_precision := p_precision::SMALLINT;

    IF (scale(p_precision) > 0) THEN
        RAISE most_specific_type_mismatch;

    -- Check if arguments are out of range
    ELSIF ((p_year NOT BETWEEN 1753 AND 9999) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59) OR
        (p_seconds NOT BETWEEN 0 AND 59) OR
        (p_hour_offset NOT BETWEEN -14 AND 14) OR
        (p_minute_offset NOT BETWEEN -59 AND 59) OR
        (p_hour_offset * p_minute_offset < 0) OR
        (p_hour_offset = 14 AND p_minute_offset != 0) OR
        (p_hour_offset = -14 AND p_minute_offset != 0) OR
        (p_fractions != 0 AND char_length(v_fractions) > p_precision::SMALLINT))
    THEN
        RAISE invalid_datetime_format;
    ELSIF (v_precision NOT BETWEEN 0 AND 7) THEN
        RAISE numeric_value_out_of_range;
    END IF;
    v_calc_seconds := format('%s.%s',
                             p_seconds,
                             substring(rpad(lpad(v_fractions, v_precision, '0'), 7, '0'), 1, 6))::NUMERIC;

    v_resdatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    v_calc_seconds);
    v_sign := (
        SELECT CASE
            WHEN (p_hour_offset) > 0
                THEN '+'
            WHEN (p_hour_offset) = 0 AND (p_minute_offset) >= 0
                THEN '+'
            ELSE '-'
        END
    );
    v_string := CONCAT(v_resdatetime::pg_catalog.text,v_sign,abs(p_hour_offset)::SMALLINT::text,':',
                                                          abs(p_minute_offset)::SMALLINT::text);
    RETURN CAST(v_string AS sys.DATETIMEOFFSET);
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Scale argument is not valid. Valid expressions for data type datetimeoffset scale argument are integer constants and integer constant expressions',
                    DETAIL := 'Use of incorrect "precision" parameter value during conversion process.',
                    HINT := 'Change "precision" parameter to the proper value and try again.';
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type datetimeoffset, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';

    WHEN numeric_value_out_of_range THEN
        RAISE USING MESSAGE := format('Specified scale % is invalid.', p_fractions),
                    DETAIL := format('Source value is out of %s data type range.', v_err_message),
                    HINT := format('Correct the source value you are trying to cast to %s data type and try again.',
                                   v_err_message);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

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

-- Added for BABEL-1544
CREATE OR REPLACE FUNCTION sys.len(expr sys.BBF_VARBINARY) RETURNS INTEGER AS
'babelfishpg_common', 'varbinary_length'
STRICT
LANGUAGE c IMMUTABLE PARALLEL SAFE;

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
 EXECUTE pg_catalog.format(E'SELECT repeat(\' \', %s)::SYS.VARCHAR(%s)', number, number) INTO result;
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

CREATE OR REPLACE FUNCTION sys.is_collated_ci_as_internal(IN input_string TEXT) RETURNS BOOL
AS 'babelfishpg_tsql', 'is_collated_ci_as_internal'
LANGUAGE C VOLATILE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_collated_ci_as(IN input_string TEXT)
RETURNS BOOL AS
$$
 SELECT sys.is_collated_ci_as_internal(input_string);
$$
LANGUAGE SQL VOLATILE PARALLEL SAFE;

create or replace function sys.PATINDEX(in pattern varchar, in expression varchar) returns bigint as
$body$
declare
  v_find_result VARCHAR;
  v_pos bigint;
  v_regexp_pattern VARCHAR;
begin
  if pattern is null or expression is null then
    return null;
  end if;
  if left(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(pattern, '^%', '%#"', 'i');
  else
    v_regexp_pattern := '#"' || pattern;
  end if;

  if right(pattern, 1) = '%' collate sys.database_default then
    v_regexp_pattern := regexp_replace(v_regexp_pattern, '%$', '#"%', 'i');
  else
   v_regexp_pattern := v_regexp_pattern || '#"';
  end if;
  v_find_result := substring(expression, v_regexp_pattern, '#');
  if v_find_result <> '' collate sys.database_default then
    v_pos := strpos(expression, v_find_result);
  else
    v_pos := 0;
  end if;
  return v_pos;
end;
$body$
language plpgsql immutable returns null on null input;

create or replace function sys.RAND(x in int)returns double precision
AS 'babelfishpg_tsql', 'tsql_random'
LANGUAGE C IMMUTABLE STRICT COST 1 PARALLEL RESTRICTED;

create or replace function sys.square(in x double precision) returns double precision
AS
$BODY$
DECLARE
 res double precision;
BEGIN
 res = pow(x, 2::float);
 return res;
END;
$BODY$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;

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

-- Duplicate function with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datepart(IN datepart TEXT, IN arg TEXT) RETURNS INTEGER
AS
$body$
BEGIN
    IF pg_typeof(arg) = 'sys.DATETIMEOFFSET'::regtype THEN
        return sys.datepart_internal(datepart, arg::timestamp,
                     sys.babelfish_get_datetimeoffset_tzoffset(arg)::integer);
    ELSIF pg_typeof(arg) = 'pg_catalog.text'::regtype THEN
        return sys.datepart_internal(datepart, arg::sys.datetimeoffset::timestamp, sys.babelfish_get_datetimeoffset_tzoffset(arg::sys.datetimeoffset)::integer);
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
    return sys.datediff_internal_date(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
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
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
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

 -- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate TEXT) RETURNS DATETIME
AS
$body$
DECLARE
    is_date INT;
BEGIN
    is_date = sys.isdate(startdate);
    IF (is_date = 1) THEN
        RETURN sys.dateadd_internal(datepart,num,startdate::datetime);
    ELSEIF (startdate is NULL) THEN
        RETURN NULL;
    ELSE
        RAISE EXCEPTION 'Conversion failed when converting date and/or time from character string.';
    END IF;
END;
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
-- 1189 "sql/sys_functions.sql"
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
  RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.001);
 WHEN 'microsecond' THEN
  RETURN startdate OPERATOR(sys.+) make_interval(secs => (num::numeric) * 0.000001);
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  RETURN startdate OPERATOR(sys.+) make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
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
  RETURN startdate + make_interval(secs => (num::numeric) * 0.001);
 WHEN 'microsecond' THEN
        IF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => (num::numeric) * 0.000001);
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
 WHEN 'nanosecond' THEN
        IF pg_typeof(startdate) = 'time'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
            RETURN startdate + make_interval(secs => TRUNC((num::numeric)* 0.000000001, 6));
        ELSIF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type smalldatetime.', datepart;
        ELSE
            RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
        END IF;
 ELSE
  RAISE EXCEPTION '''%'' is not a recognized dateadd option.', datepart;
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
 y1 INTEGER;
 m1 INTEGER;
 d1 INTEGER;
 y2 INTEGER;
 m2 INTEGER;
 d2 INTEGER;
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
  y1 = sys.datepart('year', enddate);
  m1 = sys.datepart('month', enddate);
  d1 = sys.datepart('day', enddate);
  y2 = sys.datepart('year', startdate);
  m2 = sys.datepart('month', startdate);
  d2 = sys.datepart('day', startdate);
  result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
 WHEN 'week' THEN
  day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
  result = day_diff / 7;
 WHEN 'hour' THEN
  y1 = sys.datepart('year', enddate);
  m1 = sys.datepart('month', enddate);
  d1 = sys.datepart('day', enddate);
  y2 = sys.datepart('year', startdate);
  m2 = sys.datepart('month', startdate);
  d2 = sys.datepart('day', startdate);
  day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
  hour_diff = sys.datepart('hour', enddate) - sys.datepart('hour', startdate);
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

CREATE OR REPLACE FUNCTION sys.datediff_internal_date(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER AS $$
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
 -- for all intervals smaller than month, (DATE - DATE) already returns the integer number of days
 -- between the dates, so just use that directly as the day_diff. There is no finer resolution
 -- than days with the DATE type anyways.
 WHEN 'doy', 'y' THEN
  day_diff = enddate - startdate;
  result = day_diff;
 WHEN 'day' THEN
  day_diff = enddate - startdate;
  result = day_diff;
 WHEN 'week' THEN
  day_diff = enddate - startdate;
  result = day_diff / 7;
 WHEN 'hour' THEN
  day_diff = enddate - startdate;
  result = day_diff * 24;
 WHEN 'minute' THEN
  day_diff = enddate - startdate;
  result = day_diff * 24 * 60;
 WHEN 'second' THEN
  day_diff = enddate - startdate;
  result = day_diff * 24 * 60 * 60;
 WHEN 'millisecond' THEN
  -- millisecond result from date_part by default contains second value,
  -- so we don't need to add second_diff again
  day_diff = enddate - startdate;
  result = day_diff * 24 * 60 * 60 * 1000;
 WHEN 'microsecond' THEN
  -- microsecond result from date_part by default contains second and millisecond values,
  -- so we don't need to add second_diff and millisecond_diff again
  day_diff = enddate - startdate;
  result = day_diff * 24 * 60 * 60 * 1000 * 1000;
 WHEN 'nanosecond' THEN
  -- Best we can do - Postgres does not support nanosecond precision
  day_diff = enddate - startdate;
  result = day_diff * 24 * 60 * 60 * 1000 * 1000 * 1000;
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
 y1 INTEGER;
 m1 INTEGER;
 d1 INTEGER;
 y2 INTEGER;
 m2 INTEGER;
 d2 INTEGER;
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
  y1 = date_part('year', enddate)::INTEGER;
  m1 = date_part('month', enddate)::INTEGER;
  d1 = date_part('day', enddate)::INTEGER;
  y2 = date_part('year', startdate)::INTEGER;
  m2 = date_part('month', startdate)::INTEGER;
  d2 = date_part('day', startdate)::INTEGER;
  result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
 WHEN 'week' THEN
  day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::INTEGER;
  result = day_diff / 7;
 WHEN 'hour' THEN
  y1 = date_part('year', enddate)::INTEGER;
  m1 = date_part('month', enddate)::INTEGER;
  d1 = date_part('day', enddate)::INTEGER;
  y2 = date_part('year', startdate)::INTEGER;
  m2 = date_part('month', startdate)::INTEGER;
  d2 = date_part('day', startdate)::INTEGER;
  day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
  hour_diff = date_part('hour', enddate)::INTEGER - date_part('hour', startdate)::INTEGER;
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

-- Duplicate functions with arg TEXT since ANYELEMENT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.datename(IN dp PG_CATALOG.TEXT, IN arg TEXT) RETURNS TEXT AS
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
SELECT CAST(CURRENT_TIMESTAMP AT TIME ZONE 'UTC'::pg_catalog.text AS sys.DATETIME);
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

CREATE OR REPLACE FUNCTION sys.servicename()
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

CREATE OR REPLACE FUNCTION sys.get_current_full_xact_id()
    RETURNS XID8 AS 'babelfishpg_tsql' LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

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
 SELECT 201332885::INTEGER;
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
IF (((SELECT coalesce(property_name COLLATE sys.database_default, '')) = '') or
    ((SELECT UPPER(coalesce(property_name COLLATE sys.database_default, ''))) = 'COLUMN')) THEN
 IF (((SELECT LOWER(coalesce(level0_object_type COLLATE sys.database_default, ''))) = 'schema') and
     ((SELECT LOWER(coalesce(level1_object_type COLLATE sys.database_default, ''))) = 'table') and
     ((SELECT LOWER(coalesce(level2_object_type COLLATE sys.database_default, ''))) = 'column')) THEN
  RETURN query
  select CAST('COLUMN' AS sys.sysname) as objtype,
         CAST(t3.column_name AS sys.sysname) as objname,
         t1.name as name,
         t1.value as value
  from sys.extended_properties t1, pg_catalog.pg_class t2, information_schema.columns t3
  where t1.major_id = t2.oid and
     t2.relname = cast(t3.table_name as sys.sysname) COLLATE sys.database_default and
        t2.relname = (SELECT coalesce(level1_object_name COLLATE sys.database_default, '')) COLLATE sys.database_default and
     t3.column_name = (SELECT coalesce(level2_object_name COLLATE sys.database_default, '')) COLLATE sys.database_default;
 END IF;
END IF;
RETURN;
end;
$$
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty(
 varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128), varchar(128)
) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_tsql', 'tsql_exp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(DOUBLE PRECISION) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.exp(IN arg NUMERIC)
RETURNS DOUBLE PRECISION
AS
$BODY$
SELECT sys.exp(arg::DOUBLE PRECISION);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.exp(NUMERIC) TO PUBLIC;

-- For numeric/decimal and float/double precision there is already inbuilt functions,
-- Following sign functions are for remaining datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg INT) RETURNS INT AS
$BODY$
SELECT
 CASE
  WHEN arg > 0 THEN 1::INT
  WHEN arg < 0 THEN -1::INT
  ELSE 0::INT
 END;
$BODY$
STRICT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SMALLINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.TINYINT) RETURNS INT AS
$BODY$
SELECT sys.sign(arg::INT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.TINYINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg BIGINT) RETURNS BIGINT AS
$BODY$
SELECT
 CASE
  WHEN arg > 0::BIGINT THEN 1::BIGINT
  WHEN arg < 0::BIGINT THEN -1::BIGINT
  ELSE 0::BIGINT
 END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.MONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT
 CASE
  WHEN arg > 0::SYS.MONEY THEN 1::SYS.MONEY
  WHEN arg < 0::SYS.MONEY THEN -1::SYS.MONEY
  ELSE 0::SYS.MONEY
 END;
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.MONEY) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sign(IN arg SYS.SMALLMONEY) RETURNS SYS.MONEY AS
$BODY$
SELECT sys.sign(arg::SYS.MONEY);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(SYS.SMALLMONEY) TO PUBLIC;

-- To handle remaining input datatypes
CREATE OR REPLACE FUNCTION sys.sign(IN arg ANYELEMENT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
 sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(ANYELEMENT) TO PUBLIC;

-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.
CREATE OR REPLACE FUNCTION sys.sign(IN arg TEXT) RETURNS SYS.FLOAT AS
$BODY$
SELECT
 sign(arg::SYS.FLOAT);
$BODY$
LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.sign(TEXT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.lock_timeout()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.lock_timeout');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.lock_timeout() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.max_connections()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select s.setting FROM pg_catalog.pg_settings s where name = 'max_connections');
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.max_connections() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.trigger_nestlevel()
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$
declare return_value integer;
begin
    return_value := (select pg_trigger_depth());
    RETURN return_value;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.trigger_nestlevel() TO PUBLIC;

CREATE OR REPLACE VIEW babelfish_has_perms_by_name_permissions
AS
SELECT t.securable_type,t.permission_name,t.implied_dbo_permissions,t.fully_supported FROM
(
  VALUES
    ('application role', 'alter', 'f', 'f'),
    ('application role', 'any', 'f', 'f'),
    ('application role', 'control', 'f', 'f'),
    ('application role', 'view definition', 'f', 'f'),
    ('assembly', 'alter', 'f', 'f'),
    ('assembly', 'any', 'f', 'f'),
    ('assembly', 'control', 'f', 'f'),
    ('assembly', 'references', 'f', 'f'),
    ('assembly', 'take ownership', 'f', 'f'),
    ('assembly', 'view definition', 'f', 'f'),
    ('asymmetric key', 'alter', 'f', 'f'),
    ('asymmetric key', 'any', 'f', 'f'),
    ('asymmetric key', 'control', 'f', 'f'),
    ('asymmetric key', 'references', 'f', 'f'),
    ('asymmetric key', 'take ownership', 'f', 'f'),
    ('asymmetric key', 'view definition', 'f', 'f'),
    ('availability group', 'alter', 'f', 'f'),
    ('availability group', 'any', 'f', 'f'),
    ('availability group', 'control', 'f', 'f'),
    ('availability group', 'take ownership', 'f', 'f'),
    ('availability group', 'view definition', 'f', 'f'),
    ('certificate', 'alter', 'f', 'f'),
    ('certificate', 'any', 'f', 'f'),
    ('certificate', 'control', 'f', 'f'),
    ('certificate', 'references', 'f', 'f'),
    ('certificate', 'take ownership', 'f', 'f'),
    ('certificate', 'view definition', 'f', 'f'),
    ('contract', 'alter', 'f', 'f'),
    ('contract', 'any', 'f', 'f'),
    ('contract', 'control', 'f', 'f'),
    ('contract', 'references', 'f', 'f'),
    ('contract', 'take ownership', 'f', 'f'),
    ('contract', 'view definition', 'f', 'f'),
    ('database', 'administer database bulk operations', 'f', 'f'),
    ('database', 'alter', 't', 'f'),
    ('database', 'alter any application role', 'f', 'f'),
    ('database', 'alter any assembly', 'f', 'f'),
    ('database', 'alter any asymmetric key', 'f', 'f'),
    ('database', 'alter any certificate', 'f', 'f'),
    ('database', 'alter any column encryption key', 'f', 'f'),
    ('database', 'alter any column master key', 'f', 'f'),
    ('database', 'alter any contract', 'f', 'f'),
    ('database', 'alter any database audit', 'f', 'f'),
    ('database', 'alter any database ddl trigger', 'f', 'f'),
    ('database', 'alter any database event notification', 'f', 'f'),
    ('database', 'alter any database event session', 'f', 'f'),
    ('database', 'alter any database scoped configuration', 'f', 'f'),
    ('database', 'alter any dataspace', 'f', 'f'),
    ('database', 'alter any external data source', 'f', 'f'),
    ('database', 'alter any external file format', 'f', 'f'),
    ('database', 'alter any external language', 'f', 'f'),
    ('database', 'alter any external library', 'f', 'f'),
    ('database', 'alter any fulltext catalog', 'f', 'f'),
    ('database', 'alter any mask', 'f', 'f'),
    ('database', 'alter any message type', 'f', 'f'),
    ('database', 'alter any remote service binding', 'f', 'f'),
    ('database', 'alter any role', 'f', 'f'),
    ('database', 'alter any route', 'f', 'f'),
    ('database', 'alter any schema', 't', 'f'),
    ('database', 'alter any security policy', 'f', 'f'),
    ('database', 'alter any sensitivity classification', 'f', 'f'),
    ('database', 'alter any service', 'f', 'f'),
    ('database', 'alter any symmetric key', 'f', 'f'),
    ('database', 'alter any user', 't', 'f'),
    ('database', 'any', 't', 'f'),
    ('database', 'authenticate', 't', 'f'),
    ('database', 'backup database', 'f', 'f'),
    ('database', 'backup log', 'f', 'f'),
    ('database', 'checkpoint', 'f', 'f'),
    ('database', 'connect', 't', 'f'),
    ('database', 'connect replication', 'f', 'f'),
    ('database', 'control', 't', 'f'),
    ('database', 'create aggregate', 'f', 'f'),
    ('database', 'create assembly', 'f', 'f'),
    ('database', 'create asymmetric key', 'f', 'f'),
    ('database', 'create certificate', 'f', 'f'),
    ('database', 'create contract', 'f', 'f'),
    ('database', 'create database', 't', 'f'),
    ('database', 'create database ddl event notification', 'f', 'f'),
    ('database', 'create default', 'f', 'f'),
    ('database', 'create external language', 'f', 'f'),
    ('database', 'create external library', 'f', 'f'),
    ('database', 'create fulltext catalog', 'f', 'f'),
    ('database', 'create function', 't', 'f'),
    ('database', 'create message type', 'f', 'f'),
    ('database', 'create procedure', 't', 'f'),
    ('database', 'create queue', 'f', 'f'),
    ('database', 'create remote service binding', 'f', 'f'),
    ('database', 'create role', 'f', 'f'),
    ('database', 'create route', 'f', 'f'),
    ('database', 'create rule', 'f', 'f'),
    ('database', 'create schema', 't', 'f'),
    ('database', 'create service', 'f', 'f'),
    ('database', 'create symmetric key', 'f', 'f'),
    ('database', 'create synonym', 't', 'f'),
    ('database', 'create table', 't', 'f'),
    ('database', 'create type', 'f', 'f'),
    ('database', 'create view', 't', 'f'),
    ('database', 'create xml schema collection', 'f', 'f'),
    ('database', 'delete', 't', 'f'),
    ('database', 'execute', 't', 'f'),
    ('database', 'execute any external script', 'f', 'f'),
    ('database', 'insert', 't', 'f'),
    ('database', 'kill database connection', 'f', 'f'),
    ('database', 'references', 't', 'f'),
    ('database', 'select', 't', 'f'),
    ('database', 'showplan', 'f', 'f'),
    ('database', 'subscribe query notifications', 'f', 'f'),
    ('database', 'take ownership', 't', 'f'),
    ('database', 'unmask', 'f', 'f'),
    ('database', 'update', 't', 'f'),
    ('database', 'view any column encryption key definition', 'f', 'f'),
    ('database', 'view any column master key definition', 'f', 'f'),
    ('database', 'view any sensitivity classification', 'f', 'f'),
    ('database', 'view database state', 't', 'f'),
    ('database', 'view definition', 'f', 'f'),
    ('database scoped credential', 'alter', 'f', 'f'),
    ('database scoped credential', 'any', 'f', 'f'),
    ('database scoped credential', 'control', 'f', 'f'),
    ('database scoped credential', 'references', 'f', 'f'),
    ('database scoped credential', 'take ownership', 'f', 'f'),
    ('database scoped credential', 'view definition', 'f', 'f'),
    ('endpoint', 'alter', 'f', 'f'),
    ('endpoint', 'any', 'f', 'f'),
    ('endpoint', 'connect', 'f', 'f'),
    ('endpoint', 'control', 'f', 'f'),
    ('endpoint', 'take ownership', 'f', 'f'),
    ('endpoint', 'view definition', 'f', 'f'),
    ('external language', 'alter', 'f', 'f'),
    ('external language', 'any', 'f', 'f'),
    ('external language', 'control', 'f', 'f'),
    ('external language', 'execute external script', 'f', 'f'),
    ('external language', 'references', 'f', 'f'),
    ('external language', 'take ownership', 'f', 'f'),
    ('external language', 'view definition', 'f', 'f'),
    ('fulltext catalog', 'alter', 'f', 'f'),
    ('fulltext catalog', 'any', 'f', 'f'),
    ('fulltext catalog', 'control', 'f', 'f'),
    ('fulltext catalog', 'references', 'f', 'f'),
    ('fulltext catalog', 'take ownership', 'f', 'f'),
    ('fulltext catalog', 'view definition', 'f', 'f'),
    ('fulltext stoplist', 'alter', 'f', 'f'),
    ('fulltext stoplist', 'any', 'f', 'f'),
    ('fulltext stoplist', 'control', 'f', 'f'),
    ('fulltext stoplist', 'references', 'f', 'f'),
    ('fulltext stoplist', 'take ownership', 'f', 'f'),
    ('fulltext stoplist', 'view definition', 'f', 'f'),
    ('login', 'alter', 'f', 'f'),
    ('login', 'any', 'f', 'f'),
    ('login', 'control', 'f', 'f'),
    ('login', 'impersonate', 'f', 'f'),
    ('login', 'view definition', 'f', 'f'),
    ('message type', 'alter', 'f', 'f'),
    ('message type', 'any', 'f', 'f'),
    ('message type', 'control', 'f', 'f'),
    ('message type', 'references', 'f', 'f'),
    ('message type', 'take ownership', 'f', 'f'),
    ('message type', 'view definition', 'f', 'f'),
    ('object', 'alter', 't', 'f'),
    ('object', 'any', 't', 't'),
    ('object', 'control', 't', 'f'),
    ('object', 'delete', 't', 't'),
    ('object', 'execute', 't', 't'),
    ('object', 'insert', 't', 't'),
    ('object', 'receive', 'f', 'f'),
    ('object', 'references', 't', 't'),
    ('object', 'select', 't', 't'),
    ('object', 'take ownership', 'f', 'f'),
    ('object', 'update', 't', 't'),
    ('object', 'view change tracking', 'f', 'f'),
    ('object', 'view definition', 'f', 'f'),
    ('remote service binding', 'alter', 'f', 'f'),
    ('remote service binding', 'any', 'f', 'f'),
    ('remote service binding', 'control', 'f', 'f'),
    ('remote service binding', 'take ownership', 'f', 'f'),
    ('remote service binding', 'view definition', 'f', 'f'),
    ('role', 'alter', 'f', 'f'),
    ('role', 'any', 'f', 'f'),
    ('role', 'control', 'f', 'f'),
    ('role', 'take ownership', 'f', 'f'),
    ('role', 'view definition', 'f', 'f'),
    ('route', 'alter', 'f', 'f'),
    ('route', 'any', 'f', 'f'),
    ('route', 'control', 'f', 'f'),
    ('route', 'take ownership', 'f', 'f'),
    ('route', 'view definition', 'f', 'f'),
    ('schema', 'alter', 't', 'f'),
    ('schema', 'any', 't', 'f'),
    ('schema', 'control', 't', 'f'),
    ('schema', 'create sequence', 'f', 'f'),
    ('schema', 'delete', 't', 'f'),
    ('schema', 'execute', 't', 'f'),
    ('schema', 'insert', 't', 'f'),
    ('schema', 'references', 't', 'f'),
    ('schema', 'select', 't', 'f'),
    ('schema', 'take ownership', 't', 'f'),
    ('schema', 'update', 't', 'f'),
    ('schema', 'view change tracking', 'f', 'f'),
    ('schema', 'view definition', 'f', 'f'),
    ('search property list', 'alter', 'f', 'f'),
    ('search property list', 'any', 'f', 'f'),
    ('search property list', 'control', 'f', 'f'),
    ('search property list', 'references', 'f', 'f'),
    ('search property list', 'take ownership', 'f', 'f'),
    ('search property list', 'view definition', 'f', 'f'),
    ('server', 'administer bulk operations', 'f', 'f'),
    ('server', 'alter any availability group', 'f', 'f'),
    ('server', 'alter any connection', 'f', 'f'),
    ('server', 'alter any credential', 'f', 'f'),
    ('server', 'alter any database', 't', 'f'),
    ('server', 'alter any endpoint', 'f', 'f'),
    ('server', 'alter any event notification', 'f', 'f'),
    ('server', 'alter any event session', 'f', 'f'),
    ('server', 'alter any linked server', 'f', 'f'),
    ('server', 'alter any login', 'f', 'f'),
    ('server', 'alter any server audit', 'f', 'f'),
    ('server', 'alter any server role', 'f', 'f'),
    ('server', 'alter resources', 'f', 'f'),
    ('server', 'alter server state', 'f', 'f'),
    ('server', 'alter settings', 't', 'f'),
    ('server', 'alter trace', 'f', 'f'),
    ('server', 'any', 't', 'f'),
    ('server', 'authenticate server', 't', 'f'),
    ('server', 'connect any database', 't', 'f'),
    ('server', 'connect sql', 't', 'f'),
    ('server', 'control server', 't', 'f'),
    ('server', 'create any database', 't', 'f'),
    ('server', 'create availability group', 'f', 'f'),
    ('server', 'create ddl event notification', 'f', 'f'),
    ('server', 'create endpoint', 'f', 'f'),
    ('server', 'create server role', 'f', 'f'),
    ('server', 'create trace event notification', 'f', 'f'),
    ('server', 'external access assembly', 'f', 'f'),
    ('server', 'impersonate any login', 'f', 'f'),
    ('server', 'select all user securables', 't', 'f'),
    ('server', 'shutdown', 'f', 'f'),
    ('server', 'unsafe assembly', 'f', 'f'),
    ('server', 'view any database', 't', 'f'),
    ('server', 'view any definition', 'f', 'f'),
    ('server', 'view server state', 't', 'f'),
    ('server role', 'alter', 'f', 'f'),
    ('server role', 'any', 'f', 'f'),
    ('server role', 'control', 'f', 'f'),
    ('server role', 'take ownership', 'f', 'f'),
    ('server role', 'view definition', 'f', 'f'),
    ('service', 'alter', 'f', 'f'),
    ('service', 'any', 'f', 'f'),
    ('service', 'control', 'f', 'f'),
    ('service', 'send', 'f', 'f'),
    ('service', 'take ownership', 'f', 'f'),
    ('service', 'view definition', 'f', 'f'),
    ('symmetric key', 'alter', 'f', 'f'),
    ('symmetric key', 'any', 'f', 'f'),
    ('symmetric key', 'control', 'f', 'f'),
    ('symmetric key', 'references', 'f', 'f'),
    ('symmetric key', 'take ownership', 'f', 'f'),
    ('symmetric key', 'view definition', 'f', 'f'),
    ('type', 'any', 'f', 'f'),
    ('type', 'control', 'f', 'f'),
    ('type', 'execute', 'f', 'f'),
    ('type', 'references', 'f', 'f'),
    ('type', 'take ownership', 'f', 'f'),
    ('type', 'view definition', 'f', 'f'),
    ('user', 'alter', 'f', 'f'),
    ('user', 'any', 'f', 'f'),
    ('user', 'control', 'f', 'f'),
    ('user', 'impersonate', 'f', 'f'),
    ('user', 'view definition', 'f', 'f'),
    ('xml schema collection', 'alter', 'f', 'f'),
    ('xml schema collection', 'any', 'f', 'f'),
    ('xml schema collection', 'control', 'f', 'f'),
    ('xml schema collection', 'execute', 'f', 'f'),
    ('xml schema collection', 'references', 'f', 'f'),
    ('xml schema collection', 'take ownership', 'f', 'f'),
    ('xml schema collection', 'view definition', 'f', 'f')
) t(securable_type, permission_name, implied_dbo_permissions, fully_supported);
GRANT SELECT ON babelfish_has_perms_by_name_permissions TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME,
    securable_class SYS.NVARCHAR(60),
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME DEFAULT NULL,
    sub_securable_class SYS.NVARCHAR(60) DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    db_name text COLLATE sys.database_default;
    bbf_schema_name text;
    pg_schema text COLLATE sys.database_default;
    implied_dbo_permissions boolean;
    fully_supported boolean;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    object_type text;
    function_signature text;
    qualified_name text;
    return_value integer;
    cs_as_securable text COLLATE "C" := securable;
    cs_as_securable_class text COLLATE "C" := securable_class;
    cs_as_permission text COLLATE "C" := permission;
    cs_as_sub_securable text COLLATE "C" := sub_securable;
    cs_as_sub_securable_class text COLLATE "C" := sub_securable_class;
BEGIN
    return_value := NULL;

    -- Lower-case to avoid case issues, remove trailing whitespace to match SQL SERVER behavior
    -- Objects created in Babelfish are stored in lower-case in pg_class/pg_proc
    cs_as_securable = lower(rtrim(cs_as_securable));
    cs_as_securable_class = lower(rtrim(cs_as_securable_class));
    cs_as_permission = lower(rtrim(cs_as_permission));
    cs_as_sub_securable = lower(rtrim(cs_as_sub_securable));
    cs_as_sub_securable_class = lower(rtrim(cs_as_sub_securable_class));

    -- Assert that sub_securable and sub_securable_class are either both NULL or both defined
    IF cs_as_sub_securable IS NOT NULL AND cs_as_sub_securable_class IS NULL THEN
        RETURN NULL;
    ELSIF cs_as_sub_securable IS NULL AND cs_as_sub_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If they are both defined, user must be evaluating column privileges.
    -- Check that inputs are valid for column privileges: sub_securable_class must
    -- be column, securable_class must be object, and permission cannot be any.
    ELSIF cs_as_sub_securable_class IS NOT NULL
            AND (cs_as_sub_securable_class != 'column'
                    OR cs_as_securable_class IS NULL
                    OR cs_as_securable_class != 'object'
                    OR cs_as_permission = 'any') THEN
        RETURN NULL;

    -- If securable is null, securable_class must be null
    ELSIF cs_as_securable IS NULL AND cs_as_securable_class IS NOT NULL THEN
        RETURN NULL;
    -- If securable_class is null, securable must be null
    ELSIF cs_as_securable IS NOT NULL AND cs_as_securable_class IS NULL THEN
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'server' THEN
        -- SQL Server does not permit a securable_class value of 'server'.
        -- securable_class should be NULL to evaluate server permissions.
        RETURN NULL;
    ELSIF cs_as_securable_class IS NULL THEN
        -- NULL indicates a server permission. Set this variable so that we can
        -- search for the matching entry in babelfish_has_perms_by_name_permissions
        cs_as_securable_class = 'server';
    END IF;

    IF cs_as_sub_securable IS NOT NULL THEN
        cs_as_sub_securable := babelfish_remove_delimiter_pair(cs_as_sub_securable);
        IF cs_as_sub_securable IS NULL THEN
            RETURN NULL;
        END IF;
    END IF;

    SELECT p.implied_dbo_permissions,p.fully_supported
    INTO implied_dbo_permissions,fully_supported
    FROM babelfish_has_perms_by_name_permissions p
    WHERE p.securable_type = cs_as_securable_class AND p.permission_name = cs_as_permission;

    IF implied_dbo_permissions IS NULL OR fully_supported IS NULL THEN
        -- Securable class or permission is not valid, or permission is not valid for given securable
        RETURN NULL;
    END IF;

    IF cs_as_securable_class = 'database' AND cs_as_securable IS NOT NULL THEN
        db_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF db_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(name) FROM sys.databases WHERE name = db_name) != 1 THEN
            RETURN 0;
        END IF;
    ELSIF cs_as_securable_class = 'schema' THEN
        bbf_schema_name = babelfish_remove_delimiter_pair(cs_as_securable);
        IF bbf_schema_name IS NULL THEN
            RETURN NULL;
        ELSIF (SELECT COUNT(nspname) FROM sys.babelfish_namespace_ext ext
                WHERE ext.orig_name = bbf_schema_name
                    AND CAST(ext.dbid AS oid) = CAST(sys.db_id() AS oid)) != 1 THEN
            RETURN 0;
        END IF;
    END IF;

    IF fully_supported = 'f' AND CURRENT_USER IN('dbo', 'master_dbo', 'tempdb_dbo', 'msdb_dbo') THEN
        RETURN CAST(implied_dbo_permissions AS integer);
    ELSIF fully_supported = 'f' THEN
        RETURN 0;
    END IF;

    -- The only permissions that are fully supported belong to the OBJECT securable class.
    -- The block above has dealt with all permissions that are not fully supported, so
    -- if we reach this point we know the securable class is OBJECT.
    SELECT s.db_name, s.schema_name, s.object_name INTO db_name, bbf_schema_name, object_name
    FROM babelfish_split_object_name(cs_as_securable) s;

    -- Invalid securable name
    IF object_name IS NULL OR object_name = '' THEN
        RETURN NULL;
    END IF;

    -- If schema was not specified, use the default
    IF bbf_schema_name IS NULL OR bbf_schema_name = '' THEN
        bbf_schema_name := sys.schema_name();
    END IF;

    database_id := (
        SELECT CASE
            WHEN db_name IS NULL OR db_name = '' THEN (sys.db_id())
            ELSE (sys.db_id(db_name))
        END);

    -- Translate schema name from bbf to postgres, e.g. dbo -> master_dbo
    pg_schema := (SELECT nspname
                    FROM sys.babelfish_namespace_ext ext
                    WHERE ext.orig_name = bbf_schema_name
                        AND CAST(ext.dbid AS oid) = CAST(database_id AS oid));

    IF pg_schema IS NULL THEN
        -- Shared schemas like sys and pg_catalog do not exist in the table above.
        -- These schemas do not need to be translated from Babelfish to Postgres
        pg_schema := bbf_schema_name;
    END IF;

    -- Surround with double-quotes to handle names that contain periods/spaces
    qualified_name := concat('"', pg_schema, '"."', object_name, '"');

    SELECT oid INTO namespace_id FROM pg_catalog.pg_namespace WHERE nspname = pg_schema COLLATE sys.database_default;

    object_type := (
        SELECT CASE
            WHEN cs_as_sub_securable_class = 'column'
                THEN CASE
                    WHEN (SELECT count(name)
                        FROM sys.all_columns
                        WHERE name = cs_as_sub_securable COLLATE sys.database_default
                            -- Use V as the object type to specify that the securable is table-like.
                            -- We don't know that the securable is a view, but object_id behaves the 
                            -- same for differint table-like types, so V can be arbitrarily chosen.
                            AND object_id = sys.object_id(cs_as_securable, 'V')) = 1
                                THEN 'column'
                    ELSE NULL
                END

            WHEN (SELECT count(relname)
                    FROM pg_catalog.pg_class
                    WHERE relname = object_name COLLATE sys.database_default
                        AND relnamespace = namespace_id) = 1
                THEN 'table'

            WHEN (SELECT count(proname)
                    FROM pg_catalog.pg_proc
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'f') = 1
                THEN 'function'

            WHEN (SELECT count(proname)
                    FROM pg_catalog.pg_proc
                    WHERE proname = object_name COLLATE sys.database_default
                        AND pronamespace = namespace_id
                        AND prokind = 'p') = 1
                THEN 'procedure'
            ELSE NULL
        END
    );

    -- Object wasn't found
    IF object_type IS NULL THEN
        RETURN 0;
    END IF;

    -- Get signature for function-like objects
    IF object_type IN('function', 'procedure') THEN
        SELECT CAST(oid AS regprocedure)
            INTO function_signature
            FROM pg_catalog.pg_proc
            WHERE proname = object_name COLLATE sys.database_default
                AND pronamespace = namespace_id;
    END IF;

    return_value := (
        SELECT CASE
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('select', 'update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            ELSE NULL
        END
    );

    RETURN return_value;
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION sys.has_perms_by_name(
    securable sys.SYSNAME,
    securable_class sys.nvarchar(60),
    permission sys.SYSNAME,
    sub_securable sys.SYSNAME,
    sub_securable_class sys.nvarchar(60)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.schema_name()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $function$
begin
    RETURN (select orig_name from sys.babelfish_namespace_ext ext
                    where ext.nspname = (select current_schema()) and ext.dbid::oid = sys.db_id()::oid)::sys.sysname;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$function$
;
GRANT EXECUTE ON FUNCTION sys.schema_name() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.schema_id()
RETURNS INT
LANGUAGE plpgsql
STRICT
AS $$
BEGIN
  RETURN (select oid from sys.pg_namespace_ext where nspname = (select current_schema()))::INT;
EXCEPTION
    WHEN others THEN
        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.schema_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STRICT
AS $$
declare return_value text;
begin
 RETURN (select session_user)::sys.sysname;
EXCEPTION
 WHEN others THEN
   RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.original_login() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id oid, property name, property_name text)
RETURNS integer
LANGUAGE plpgsql
STRICT
AS $$

declare extra_bytes CONSTANT integer := 4;
declare return_value integer;
begin
 return_value := (
     select
      case LOWER(property_name)
       when 'charmaxlen' COLLATE sys.database_default then
        (select CASE WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes ELSE NULL END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
       when 'allowsnull' COLLATE sys.database_default then
        (select CASE WHEN a.attnotnull THEN 0 ELSE 1 END from pg_catalog.pg_attribute a where a.attrelid = object_id and a.attname = property)
       else
        null
      end
     );

  RETURN return_value::integer;
EXCEPTION
 WHEN others THEN
   RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id oid, property name, property_name text) TO PUBLIC;

COMMENT ON FUNCTION sys.columnproperty
IS 'This function returns column or parameter information. Currently only works with "charmaxlen", and "allowsnull" otherwise returns 0.';

-- substring --
CREATE OR REPLACE FUNCTION sys.substring(string TEXT, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.VARCHAR, i INTEGER, j INTEGER)
RETURNS sys.VARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NVARCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.substring(string sys.NCHAR, i INTEGER, j INTEGER)
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_varchar_substr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

-- For getting host os from PG_VERSION_STR
CREATE OR REPLACE FUNCTION sys.get_host_os()
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'host_os' LANGUAGE C IMMUTABLE PARALLEL SAFE;

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
  OUT database_id int2,
  OUT host_name varchar(128))
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_stat_get_activity'
LANGUAGE C VOLATILE STRICT;







CREATE OR REPLACE FUNCTION sys.is_table_type(object_id oid) RETURNS bool AS
$BODY$
SELECT
  EXISTS(
    SELECT 1
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid AND pt.oid = dep.refobjid
    join sys.schemas sch on pt.typnamespace = sch.schema_id
    JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i' AND pt.typrelid = object_id AND pc.relkind = 'r'
    AND dep.classid = 'pg_catalog.pg_class'::regclass AND dep.refclassid = 'pg_catalog.pg_type'::regclass);
$BODY$
LANGUAGE SQL VOLATILE STRICT;

-- JSON Functions
CREATE OR REPLACE FUNCTION sys.isjson(json_string text)
RETURNS INTEGER
AS 'babelfishpg_tsql', 'tsql_isjson' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_value(json_string text, path text)
RETURNS sys.NVARCHAR(4000)
AS 'babelfishpg_tsql', 'tsql_json_value' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.json_query(json_string text, path text default '$')
RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'tsql_json_query' LANGUAGE C IMMUTABLE PARALLEL SAFE;
-- 2784 "sql/sys_functions.sql"
CREATE OR REPLACE FUNCTION sys.json_modify(in expression sys.NVARCHAR,in path_json TEXT, in new_value TEXT)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    json_path TEXT;
    json_path_convert TEXT;
    new_jsonb_path TEXT[];
    key_value_type TEXT;
    path_split_array TEXT[];
    comparison_string TEXT COLLATE "C";
    len_array INTEGER;
    word_count INTEGER;
    create_if_missing BOOL = TRUE;
    append_modifier BOOL = FALSE;
    key_exists BOOL;
    key_value JSONB;
    json_expression JSONB = expression::JSONB;
    result_json sys.NVARCHAR;
BEGIN
    path_split_array = regexp_split_to_array(TRIM(path_json) COLLATE "C",'\s+');
    word_count = array_length(path_split_array,1);






    IF word_count = 1 THEN
        json_path = path_split_array[1];
        create_if_missing = TRUE;
        append_modifier = FALSE;
    ELSIF word_count = 2 THEN
        json_path = path_split_array[2];
        comparison_string = path_split_array[1]; -- append or lax/strict mode
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSIF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSIF word_count = 3 THEN
        json_path = path_split_array[3];
        comparison_string = path_split_array[1]; -- append mode
        IF comparison_string = 'append' THEN
            append_modifier = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
        comparison_string = path_split_array[2]; -- lax/strict mode
        IF comparison_string = 'strict' THEN
            create_if_missing = FALSE;
        ELSIF comparison_string = 'lax' THEN
            create_if_missing = TRUE;
        ELSE
            RAISE invalid_json_text;
        END IF;
    ELSE
        RAISE invalid_json_text;
    END IF;

    -- To convert input jsonpath to the required jsonb_path format
    json_path_convert = regexp_replace(json_path, '\$\.|]|\$\[' , '' , 'ig'); -- To remove "$." and "]" sign from the string
    json_path_convert = regexp_replace(json_path_convert, '\.|\[' , ',' , 'ig'); -- To replace "." and "[" with "," to change into required format
    new_jsonb_path = CONCAT('{',json_path_convert,'}'); -- Final required format of path by jsonb_set

    key_exists = jsonb_path_exists(json_expression,json_path::jsonpath); -- To check if key exist in the given path

    --This if else block is to call the jsonb_set function based on the create_if_missing and append_modifier flags
    IF append_modifier THEN
        IF key_exists THEN
            key_value = jsonb_path_query_first(json_expression,json_path::jsonpath); -- To get the value of the key
            key_value_type = jsonb_typeof(key_value);
            IF key_value_type = 'array' THEN
                len_array = jsonb_array_length(key_value);




                new_jsonb_path = FORMAT('%s,%s}',TRIM('}' FROM new_jsonb_path::TEXT),len_array);
                IF new_value IS NULL THEN
                    result_json = jsonb_insert(json_expression,new_jsonb_path,'null'); -- This needs to be done because "to_jsonb(coalesce(new_value, 'null'))" does not result in a JSON NULL
                ELSE
                    result_json = jsonb_insert(json_expression,new_jsonb_path,to_jsonb(new_value));
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_array_not_found;
                ELSE
                    result_json = json_expression;
                END IF;
            END IF;
        ELSE
            IF NOT create_if_missing THEN
                RAISE sql_json_object_not_found;
            ELSE
                result_json = jsonb_insert(json_expression,new_jsonb_path,to_jsonb(array_agg(new_value))); -- array_agg is used to convert the new_value text into array format as we append functionality is being used
            END IF;
        END IF;
    ELSE --When no append modifier is present
        IF new_value IS NOT NULL THEN
            IF key_exists OR create_if_missing THEN
                result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),create_if_missing);
            ELSE
                RAISE sql_json_object_not_found;
            END IF;
        ELSE
            IF key_exists THEN
                IF NOT create_if_missing THEN
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value));
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),create_if_missing,'delete_key');
                END IF;
            ELSE
                IF NOT create_if_missing THEN
                    RAISE sql_json_object_not_found;
                ELSE
                    result_json = jsonb_set_lax(json_expression,new_jsonb_path,to_jsonb(new_value),FALSE);
                END IF;
            END IF;
        END IF;
    END IF; -- If append_modifier block ends here
    RETURN result_json;
EXCEPTION
    WHEN invalid_json_text THEN
            RAISE USING MESSAGE = 'JSON path is not properly formatted',
                        DETAIL = FORMAT('Unexpected keyword "%s" is found.',comparison_string),
                        HINT = 'Change "modifier/mode" parameter to the proper value and try again.';
    WHEN sql_json_array_not_found THEN
            RAISE USING MESSAGE = 'array cannot be found in the specified JSON path',
                        HINT = 'Change JSON path to target array property and try again.';
    WHEN sql_json_object_not_found THEN
            RAISE USING MESSAGE = 'property cannot be found on the specified JSON path';
END;
$BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.openjson_object(json_string text)
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
SELECT key,
        CASE json_typeof(value) WHEN 'null' THEN NULL
                                ELSE TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null' THEN 0
                                WHEN 'string' THEN 1
                                WHEN 'number' THEN 2
                                WHEN 'boolean' THEN 3
                                WHEN 'array' THEN 4
                                WHEN 'object' THEN 5
        END
    FROM json_each(json_string::JSON)
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_array(json_string text)
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
SELECT (row_number() over ())-1,
        CASE json_typeof(value) WHEN 'null' THEN NULL
                                ELSE TRIM (BOTH '"' FROM value::TEXT)
        END,
        CASE json_typeof(value) WHEN 'null' THEN 0
                                WHEN 'string' THEN 1
                                WHEN 'number' THEN 2
                                WHEN 'boolean' THEN 3
                                WHEN 'array' THEN 4
                                WHEN 'object' THEN 5
        END
    FROM json_array_elements(json_string::JSON) AS value
$BODY$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION sys.openjson_simple(json_string text, path text default '$')
RETURNS TABLE
(
    key sys.NVARCHAR(4000),
    value sys.NVARCHAR,
    type INTEGER
)
AS
$BODY$
DECLARE
    sub_json text := sys.json_query(json_string, path);
BEGIN
    IF json_typeof(sub_json::JSON) = 'array' THEN
        RETURN QUERY SELECT * FROM sys.openjson_array(sub_json);
    ELSE
        RETURN QUERY SELECT * FROM sys.openjson_object(sub_json);
    END IF;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.openjson_with(json_string text, path text, VARIADIC column_paths text[])
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'tsql_openjson_with' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

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

-- Role member functions
CREATE OR REPLACE FUNCTION sys.is_rolemember_internal(
 IN role sys.SYSNAME,
 IN database_principal sys.SYSNAME
)
RETURNS INT AS 'babelfishpg_tsql', 'is_rolemember'
LANGUAGE C STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_member(IN role sys.SYSNAME)
RETURNS INT AS
$$
 SELECT sys.is_rolemember_internal(role, NULL);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(IN role sys.SYSNAME)
RETURNS INT AS
$$
 SELECT sys.is_rolemember_internal(role, NULL);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.is_rolemember(
 IN role sys.SYSNAME,
 IN database_principal sys.SYSNAME
)
RETURNS INT AS
$$
 SELECT sys.is_rolemember_internal(role, database_principal);
$$
LANGUAGE SQL STRICT STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.replace (in input_string text, in pattern text, in replacement text) returns TEXT as
$body$
begin
   if pattern is null or replacement is null then
       return null;
   elsif pattern = '' then
       return input_string;
   elsif sys.is_collated_ci_as(input_string) then
       return regexp_replace(input_string, '***=' || pattern, replacement, 'ig');
   else
       return regexp_replace(input_string, '***=' || pattern, replacement, 'g');
   end if;
end
$body$
LANGUAGE plpgsql STABLE PARALLEL SAFE STRICT;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT
AS $$
BEGIN

    IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
    THEN
        RETURN NULL;
    END IF;

    property := RTRIM(LOWER(COALESCE(property, '')));

    IF property = 'ownerid' -- OwnerId
    THEN
        RETURN (
                SELECT CAST(COALESCE(t1.principal_id, pn.nspowner) AS INT)
                FROM sys.all_objects t1
                INNER JOIN pg_catalog.pg_namespace pn ON pn.oid = t1.schema_id
                WHERE t1.object_id = id);

    ELSEIF property = 'isdefaultcnst' -- IsDefaultCnst
    THEN
        RETURN (SELECT count(distinct dc.object_id) FROM sys.default_constraints dc WHERE dc.object_id = id);

    ELSEIF property = 'execisquotedidenton' -- ExecIsQuotedIdentOn
    THEN
        RETURN (SELECT CAST(sm.uses_quoted_identifier as int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'tablefulltextpopulatestatus' -- TableFullTextPopulateStatus
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'tablehasvardecimalstorageformat' -- TableHasVarDecimalStorageFormat
    THEN
        IF NOT EXISTS (SELECT object_id FROM sys.tables t WHERE t.object_id = id) THEN
            RETURN NULL;
        END IF;
        RETURN 0;

    ELSEIF property = 'ismsshipped' -- IsMSShipped
    THEN
        RETURN (SELECT CAST(ao.is_ms_shipped AS int) FROM sys.all_objects ao WHERE ao.object_id = id);

    ELSEIF property = 'isschemabound' -- IsSchemaBound
    THEN
        RETURN (SELECT CAST(sm.is_schema_bound AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'execisansinullson' -- ExecIsAnsiNullsOn
    THEN
        RETURN (SELECT CAST(sm.uses_ansi_nulls AS int) FROM sys.all_sql_modules sm WHERE sm.object_id = id);

    ELSEIF property = 'isdeterministic' -- IsDeterministic
    THEN
        RETURN 0;

    ELSEIF property = 'isprocedure' -- IsProcedure
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'P');

    ELSEIF property = 'istable' -- IsTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IT', 'TT', 'U', 'S'));

    ELSEIF property = 'isview' -- IsView
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'V');

    ELSEIF property = 'isusertable' -- IsUserTable
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'U' and is_ms_shipped = 0);

    ELSEIF property = 'istablefunction' -- IsTableFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF', 'TF', 'FT'));

    ELSEIF property = 'isinlinefunction' -- IsInlineFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('IF'));

    ELSEIF property = 'isscalarfunction' -- IsScalarFunction
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('FN', 'FS'));

    ELSEIF property = 'isprimarykey' -- IsPrimaryKey
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type = 'PK');

    ELSEIF property = 'isindexed' -- IsIndexed
    THEN
        RETURN (SELECT count(distinct object_id) from sys.indexes WHERE object_id = id and index_id > 0);

    ELSEIF property = 'isdefault' -- IsDefault
    THEN
        RETURN 0;

    ELSEIF property = 'isrule' -- IsRule
    THEN
        RETURN 0;

    ELSEIF property = 'istrigger' -- IsTrigger
    THEN
        RETURN (SELECT count(distinct object_id) from sys.all_objects WHERE object_id = id and type in ('TA', 'TR'));
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION OBJECTPROPERTYEX(
    id INT,
    property SYS.VARCHAR
)
RETURNS SYS.SQL_VARIANT
AS $$
BEGIN
 property := RTRIM(LOWER(COALESCE(property, '')));

 IF NOT EXISTS(SELECT ao.object_id FROM sys.all_objects ao WHERE object_id = id)
 THEN
  RETURN NULL;
 END IF;

 IF property = 'basetype' -- BaseType
 THEN
  RETURN (SELECT CAST(ao.type AS SYS.SQL_VARIANT)
                FROM sys.all_objects ao
                WHERE ao.object_id = id
                LIMIT 1
                );
    END IF;

    RETURN CAST(OBJECTPROPERTY(id, property) AS SYS.SQL_VARIANT);
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.sid_binary(IN login sys.nvarchar)
RETURNS SYS.VARBINARY
AS $$
    SELECT CAST(NULL AS SYS.VARBINARY);
$$
LANGUAGE SQL IMMUTABLE PARALLEL RESTRICTED;

CREATE OR REPLACE FUNCTION sys.language()
RETURNS sys.NVARCHAR(128) AS 'babelfishpg_tsql' LANGUAGE C;

CREATE OR REPLACE FUNCTION sys.host_name()
RETURNS sys.NVARCHAR(128) AS 'babelfishpg_tsql' LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128))
RETURNS INT AS
$BODY$
DECLARE
ret_val INT;
BEGIN
 index_or_statistics_name = LOWER(TRIM(index_or_statistics_name));
 property = LOWER(TRIM(property));
    SELECT INTO ret_val
    CASE

        WHEN (SELECT CAST(type AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default) = 3 -- is XML index
        THEN CAST(NULL AS int)

        WHEN property = 'indexdepth'
        THEN CAST(0 AS int)

        WHEN property = 'indexfillfactor'
        THEN (SELECT CAST(fill_factor AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'indexid'
        THEN (SELECT CAST(index_id AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isautostatistics'
        THEN CAST(0 AS int)

        WHEN property = 'isclustered'
        THEN (SELECT CAST(CASE WHEN type = 1 THEN 1 ELSE 0 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isdisabled'
        THEN (SELECT CAST(is_disabled AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isfulltextkey'
        THEN CAST(0 AS int)

        WHEN property = 'ishypothetical'
        THEN (SELECT CAST(is_hypothetical AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'ispadindex'
        THEN (SELECT CAST(is_padded AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'ispagelockdisallowed'
        THEN (SELECT CAST(CASE WHEN allow_page_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isrowlockdisallowed'
        THEN (SELECT CAST(CASE WHEN allow_row_locks = 1 THEN 0 ELSE 1 END AS int) FROM sys.indexes i WHERE i.object_id=$1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'isstatistics'
        THEN CAST(0 AS int)

        WHEN property = 'isunique'
        THEN (SELECT CAST(is_unique AS int) FROM sys.indexes i WHERE i.object_id = $1 AND i.name = $2 COLLATE sys.database_default)

        WHEN property = 'iscolumnstore'
        THEN CAST(0 AS int)

        WHEN property = 'isoptimizedforsequentialkey'
        THEN CAST(0 AS int)
    ELSE
        CAST(NULL AS int)
    END;
RETURN ret_val;
END;
$BODY$
LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128)) TO PUBLIC;
-- 15 "sql/babelfishpg_tsql.in" 2
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

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg TEXT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
    RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg ANYELEMENT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
     RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg TEXT, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE pg_catalog.format('SELECT CAST(%L AS %s)', arg, format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;
-- 16 "sql/babelfishpg_tsql.in" 2
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
-- 17 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/object_definition_tsql.sql" 1
CREATE TABLE sys.babelfish_view_def (
 dbid SMALLINT NOT NULL,
 schema_name sys.SYSNAME NOT NULL,
 object_name sys.SYSNAME NOT NULL,
 definition sys.NTEXT,
 flag_validity BIGINT,
 flag_values BIGINT,
 create_date SYS.DATETIME,
 modify_date SYS.DATETIME,
 PRIMARY KEY(dbid, schema_name, object_name)
);
GRANT SELECT ON sys.babelfish_view_def TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_view_def', '');
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

-- BABELFISH_FUNCTION_EXT
CREATE TABLE sys.babelfish_function_ext (
 nspname NAME NOT NULL,
 funcname NAME NOT NULL,
 orig_name sys.NVARCHAR(128), -- users' original input name
 funcsignature TEXT NOT NULL COLLATE "C",
 default_positions TEXT COLLATE "C",
 flag_validity BIGINT,
 flag_values BIGINT,
 create_date SYS.DATETIME NOT NULL,
 modify_date SYS.DATETIME NOT NULL,
 PRIMARY KEY(nspname, funcsignature)
);
GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');

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
CAST(120 AS SYS.TINYINT) AS cmptlevel,
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

-- The items in initialize_babel_extras procedure need to be initialized or created
-- during babelfish initialization. They depend on the core babelfish to be initialized first.
CREATE OR REPLACE PROCEDURE initialize_babel_extras()
LANGUAGE plpgsql
AS $$
BEGIN
  CREATE OR REPLACE PROCEDURE sys.create_xp_qv_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_qv_in_master_dbo_internal';

  CREATE OR REPLACE PROCEDURE sys.create_xp_instance_regread_in_master_dbo()
  LANGUAGE C
  AS 'babelfishpg_tsql', 'create_xp_instance_regread_in_master_dbo_internal';

  CALL sys.create_xp_qv_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_qv OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_qv_in_master_dbo;

  CALL sys.create_xp_instance_regread_in_master_dbo();
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), int) OWNER TO sysadmin;
  ALTER PROCEDURE master_dbo.xp_instance_regread(sys.nvarchar(512), sys.sysname, sys.nvarchar(512), sys.nvarchar(512)) OWNER TO sysadmin;
  DROP PROCEDURE sys.create_xp_instance_regread_in_master_dbo;

  CREATE OR REPLACE VIEW msdb_dbo.syspolicy_system_health_state
  AS
    SELECT
      CAST(0 as BIGINT) AS health_state_id,
      CAST(0 as INT) AS policy_id,
      CAST(NULL AS sys.DATETIME) AS last_run_date,
      CAST('' AS sys.NVARCHAR(400)) AS target_query_expression_with_id,
      CAST('' AS sys.NVARCHAR) AS target_query_expression,
      CAST(1 as sys.BIT) AS result
    WHERE FALSE;
  GRANT SELECT ON msdb_dbo.syspolicy_system_health_state TO PUBLIC;
  ALTER VIEW msdb_dbo.syspolicy_system_health_state OWNER TO sysadmin;

  CREATE OR REPLACE FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled()
  RETURNS INTEGER
  AS
  $fn_body$
    SELECT 0;
  $fn_body$
  LANGUAGE SQL IMMUTABLE PARALLEL SAFE;
  ALTER FUNCTION msdb_dbo.fn_syspolicy_is_automation_enabled() OWNER TO sysadmin;

  CREATE OR REPLACE VIEW msdb_dbo.syspolicy_configuration
  AS
    SELECT CAST(t.name AS sys.sysname), CAST(t.current_value AS sys.sql_variant) FROM
    (
      VALUES
      ('Enabled', CAST(0 AS int)),
      ('HistoryRetentionInDays', CAST(0 AS int)),
      ('LogOnSuccess', CAST(0 AS int))
    )t (name, current_value);
  GRANT SELECT ON msdb_dbo.syspolicy_configuration TO PUBLIC;
  ALTER VIEW msdb_dbo.syspolicy_configuration OWNER TO sysadmin;

END
$$;

CREATE OR REPLACE PROCEDURE initialize_babelfish ( sa_name VARCHAR(128) )
LANGUAGE plpgsql
AS $$
DECLARE
 reserved_roles varchar[] := ARRAY['sysadmin', 'master_dbo', 'master_guest', 'master_db_owner', 'tempdb_dbo', 'tempdb_guest', 'tempdb_db_owner', 'msdb_dbo', 'msdb_guest', 'msdb_db_owner'];
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
 CALL sys.babel_initialize_logins('sysadmin');
 CALL sys.babel_create_builtin_dbs(sa_name);
 CALL sys.initialize_babel_extras();
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
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_configurations', '');

-- SERVER_PRINCIPALS
CREATE VIEW sys.server_principals
AS SELECT
CAST(Base.rolname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_LOGIN'
WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
ELSE NULL END AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

GRANT SELECT ON sys.server_principals TO PUBLIC;

-- USER extension
CREATE TABLE sys.babelfish_authid_user_ext (
rolname NAME NOT NULL,
login_name NAME NOT NULL,
type CHAR(1) NOT NULL DEFAULT 'S',
owning_principal_id INT,
is_fixed_role INT NOT NULL DEFAULT 0,
authentication_type INT,
default_language_lcid INT,
allow_encrypted_value_modifications INT NOT NULL DEFAULT 0,
create_date timestamptz NOT NULL,
modify_date timestamptz NOT NULL,
orig_username SYS.NVARCHAR(128) NOT NULL,
database_name SYS.NVARCHAR(128) NOT NULL,
default_schema_name SYS.NVARCHAR(128) NOT NULL,
default_language_name SYS.NVARCHAR(128),
authentication_type_desc SYS.NVARCHAR(60),
user_can_connect INT NOT NULL DEFAULT 1,
PRIMARY KEY (rolname));

CREATE INDEX babelfish_authid_user_ext_login_db_idx ON sys.babelfish_authid_user_ext (login_name, database_name);

GRANT SELECT ON sys.babelfish_authid_user_ext TO PUBLIC;

-- DATABASE_PRINCIPALS
CREATE VIEW sys.database_principals AS SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.OID AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(CASE WHEN Ext.type = 'S' THEN 'SQL_USER'
WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
ELSE NULL END AS SYS.NVARCHAR(60)) AS type_desc,
CAST(Ext.default_schema_name AS SYS.SYSNAME) AS default_schema_name,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(Ext.owning_principal_id AS INT) AS owning_principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.is_fixed_role AS SYS.BIT) AS is_fixed_role,
CAST(Ext.authentication_type AS INT) AS authentication_type,
CAST(Ext.authentication_type_desc AS SYS.NVARCHAR(60)) AS authentication_type_desc,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(Ext.default_language_lcid AS INT) AS default_language_lcid,
CAST(Ext.allow_encrypted_value_modifications AS SYS.BIT) AS allow_encrypted_value_modifications
FROM pg_catalog.pg_authid AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

GRANT SELECT ON sys.database_principals TO PUBLIC;

-- DATABASE_ROLE_MEMBERS
CREATE VIEW sys.database_role_members AS
SELECT
CAST(Auth1.oid AS INT) AS role_principal_id,
CAST(Auth2.oid AS INT) AS member_principal_id
FROM pg_catalog.pg_auth_members AS Authmbr
INNER JOIN pg_catalog.pg_authid AS Auth1 ON Auth1.oid = Authmbr.roleid
INNER JOIN pg_catalog.pg_authid AS Auth2 ON Auth2.oid = Authmbr.member
INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Auth1.rolname = Ext1.rolname
INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Auth2.rolname = Ext2.rolname
WHERE Ext1.database_name = DB_NAME()
AND Ext2.database_name = DB_NAME()
AND Ext1.type = 'R'
AND Ext2.orig_username != 'db_owner';

GRANT SELECT ON sys.database_role_members TO PUBLIC;

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
  CAST(d.name as SYS.SYSNAME) as name
  , CAST(sys.db_id(d.name) as INT) as database_id
  , CAST(NULL as INT) as source_database_id
  , cast(s.sid as SYS.VARBINARY(85)) as owner_sid
  , CAST(d.crdate AS SYS.DATETIME) as create_date
  , CAST(s.cmptlevel AS SYS.TINYINT) as compatibility_level
  , CAST(c.collname as SYS.SYSNAME) as collation_name
  , CAST(0 AS SYS.TINYINT) as user_access
  , CAST('MULTI_USER' AS SYS.NVARCHAR(60)) as user_access_desc
  , CAST(0 AS SYS.BIT) as is_read_only
  , CAST(0 AS SYS.BIT) as is_auto_close_on
  , CAST(0 AS SYS.BIT) as is_auto_shrink_on
  , CAST(0 AS SYS.TINYINT) as state
  , CAST('ONLINE' AS SYS.NVARCHAR(60)) as state_desc
  , CAST(
    CASE
   WHEN pg_is_in_recovery() is false THEN 0
   WHEN pg_is_in_recovery() is true THEN 1
  END
 AS SYS.BIT) as is_in_standby
  , CAST(0 AS SYS.BIT) as is_cleanly_shutdown
  , CAST(0 AS SYS.BIT) as is_supplemental_logging_enabled
  , CAST(1 AS SYS.TINYINT) as snapshot_isolation_state
  , CAST('ON' AS SYS.NVARCHAR(60)) as snapshot_isolation_state_desc
  , CAST(1 AS SYS.BIT) as is_read_committed_snapshot_on
  , CAST(1 AS SYS.TINYINT) as recovery_model
  , CAST('FULL' AS SYS.NVARCHAR(60)) as recovery_model_desc
  , CAST(0 AS SYS.TINYINT) as page_verify_option
  , CAST(NULL AS SYS.NVARCHAR(60)) as page_verify_option_desc
  , CAST(1 AS SYS.BIT) as is_auto_create_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_create_stats_incremental_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_on
  , CAST(0 AS SYS.BIT) as is_auto_update_stats_async_on
  , CAST(0 AS SYS.BIT) as is_ansi_null_default_on
  , CAST(0 AS SYS.BIT) as is_ansi_nulls_on
  , CAST(0 AS SYS.BIT) as is_ansi_padding_on
  , CAST(0 AS SYS.BIT) as is_ansi_warnings_on
  , CAST(0 AS SYS.BIT) as is_arithabort_on
  , CAST(0 AS SYS.BIT) as is_concat_null_yields_null_on
  , CAST(0 AS SYS.BIT) as is_numeric_roundabort_on
  , CAST(0 AS SYS.BIT) as is_quoted_identifier_on
  , CAST(0 AS SYS.BIT) as is_recursive_triggers_on
  , CAST(0 AS SYS.BIT) as is_cursor_close_on_commit_on
  , CAST(0 AS SYS.BIT) as is_local_cursor_default
  , CAST(0 AS SYS.BIT) as is_fulltext_enabled
  , CAST(0 AS SYS.BIT) as is_trustworthy_on
  , CAST(0 AS SYS.BIT) as is_db_chaining_on
  , CAST(0 AS SYS.BIT) as is_parameterization_forced
  , CAST(0 AS SYS.BIT) as is_master_key_encrypted_by_server
  , CAST(0 AS SYS.BIT) as is_query_store_on
  , CAST(0 AS SYS.BIT) as is_published
  , CAST(0 AS SYS.BIT) as is_subscribed
  , CAST(0 AS SYS.BIT) as is_merge_published
  , CAST(0 AS SYS.BIT) as is_distributor
  , CAST(0 AS SYS.BIT) as is_sync_with_backup
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as service_broker_guid
  , CAST(0 AS SYS.BIT) as is_broker_enabled
  , CAST(0 AS SYS.TINYINT) as log_reuse_wait
  , CAST('NOTHING' AS SYS.NVARCHAR(60)) as log_reuse_wait_desc
  , CAST(0 AS SYS.BIT) as is_date_correlation_on
  , CAST(0 AS SYS.BIT) as is_cdc_enabled
  , CAST(0 AS SYS.BIT) as is_encrypted
  , CAST(0 AS SYS.BIT) as is_honor_broker_priority_on
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as replica_id
  , CAST(NULL AS SYS.UNIQUEIDENTIFIER) as group_database_id
  , CAST(NULL AS INT) as resource_pool_id
  , CAST(NULL AS SMALLINT) as default_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_language_name
  , CAST(NULL AS INT) as default_fulltext_language_lcid
  , CAST(NULL AS SYS.NVARCHAR(128)) as default_fulltext_language_name
  , CAST(NULL AS SYS.BIT) as is_nested_triggers_on
  , CAST(NULL AS SYS.BIT) as is_transform_noise_words_on
  , CAST(NULL AS SMALLINT) as two_digit_year_cutoff
  , CAST(0 AS SYS.TINYINT) as containment
  , CAST('NONE' AS SYS.NVARCHAR(60)) as containment_desc
  , CAST(0 AS INT) as target_recovery_time_in_seconds
  , CAST(0 AS INT) as delayed_durability
  , CAST(NULL AS SYS.NVARCHAR(60)) as delayed_durability_desc
  , CAST(0 AS SYS.BIT) as is_memory_optimized_elevate_to_snapshot_on
  , CAST(0 AS SYS.BIT) as is_federation_member
  , CAST(0 AS SYS.BIT) as is_remote_data_archive_enabled
  , CAST(0 AS SYS.BIT) as is_mixed_page_allocation_on
  , CAST(0 AS SYS.BIT) as is_temporal_history_retention_enabled
  , CAST(0 AS INT) as catalog_collation_type
  , CAST('Not Applicable' AS SYS.NVARCHAR(60)) as catalog_collation_type_desc
  , CAST(NULL AS SYS.NVARCHAR(128)) as physical_database_name
  , CAST(0 AS SYS.BIT) as is_result_set_caching_on
  , CAST(0 AS SYS.BIT) as is_accelerated_database_recovery_on
  , CAST(0 AS SYS.BIT) as is_tempdb_spill_to_remote_store
  , CAST(0 AS SYS.BIT) as is_stale_page_detection_on
  , CAST(0 AS SYS.BIT) as is_memory_optimized_enabled
  , CAST(0 AS SYS.BIT) as is_ledger_on
 from sys.babelfish_sysdatabases d
 INNER JOIN sys.sysdatabases s on d.dbid = s.dbid
 LEFT OUTER JOIN pg_catalog.pg_collation c ON d.default_collation = c.collname;
GRANT SELECT ON sys.databases TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_inconsistent_metadata(return_consistency boolean default false)
RETURNS table (
  object_type varchar(32),
  schema_name varchar(128),
  object_name varchar(128),
  detail jsonb
) AS 'babelfishpg_tsql', 'babelfish_inconsistent_metadata' LANGUAGE C;


CREATE OR REPLACE FUNCTION sys.role_id(role_name SYS.SYSNAME)
RETURNS INT
AS 'babelfishpg_tsql', 'role_id'
LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.role_id TO PUBLIC;
-- 19 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/sys_views.sql" 1


-- The sys.table_types_internal view mimics the logic used in sys.is_table_type function
create or replace view sys.table_types_internal as
SELECT pt.typrelid
    FROM pg_catalog.pg_type pt
    INNER JOIN pg_catalog.pg_depend dep
    ON pt.typrelid = dep.objid
    INNER JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE
    pt.typnamespace in (select schema_id from sys.schemas)
    and (pt.typtype = 'c' AND dep.deptype = 'i' AND pc.relkind = 'r')
;

create or replace view sys.tables as
select
  CAST(t.relname as sys._ci_sysname) as name
  , CAST(t.oid as int) as object_id
  , CAST(NULL as int) as principal_id
  , CAST(t.relnamespace as int) as schema_id
  , 0 as parent_object_id
  , CAST('U' as CHAR(2)) as type
  , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as create_date
  , CAST((select string_agg(
                  case
                  when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                  else NULL
                  end, ',')
          from unnest(t.reloptions) as option)
        as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , case reltoastrelid when 0 then 0 else 1 end as lob_data_space_id
  , CAST(NULL as int) as filestream_data_space_id
  , CAST(relnatts as int) as max_column_id_used
  , CAST(0 as sys.bit) as lock_on_bulk_load
  , CAST(1 as sys.bit) as uses_ansi_nulls
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as has_replication_filter
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_sync_tran_subscribed
  , CAST(0 as sys.bit) as has_unchecked_assembly_data
  , 0 as text_in_row_limit
  , CAST(0 as sys.bit) as large_value_types_out_of_row
  , CAST(0 as sys.bit) as is_tracked_by_cdc
  , CAST(0 as sys.tinyint) as lock_escalation
  , CAST('TABLE' as sys.nvarchar(60)) as lock_escalation_desc
  , CAST(0 as sys.bit) as is_filetable
  , CAST(0 as sys.tinyint) as durability
  , CAST('SCHEMA_AND_DATA' as sys.nvarchar(60)) as durability_desc
  , CAST(0 as sys.bit) is_memory_optimized
  , case relpersistence when 't' then CAST(2 as sys.tinyint) else CAST(0 as sys.tinyint) end as temporal_type
  , case relpersistence when 't' then CAST('SYSTEM_VERSIONED_TEMPORAL_TABLE' as sys.nvarchar(60)) else CAST('NON_TEMPORAL_TABLE' as sys.nvarchar(60)) end as temporal_type_desc
  , CAST(null as integer) as history_table_id
  , CAST(0 as sys.bit) as is_remote_data_archive_enabled
  , CAST(0 as sys.bit) as is_external
from pg_class t
where t.relnamespace in (select schema_id from sys.schemas)
and t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and t.oid not in (select typrelid from sys.table_types_internal)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.tables TO PUBLIC;

create or replace view sys.views as
select
  t.relname as name
  , t.oid as object_id
  , null::integer as principal_id
  , sch.schema_id as schema_id
  , 0 as parent_object_id
  , 'V'::varchar(2) as type
  , 'VIEW'::varchar(60) as type_desc
  , vd.create_date::timestamp as create_date
  , vd.create_date::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
  , 0 as with_check_option
  , 0 as is_date_correlation_view
  , 0 as is_tracked_by_cdc
from pg_class t inner join sys.schemas sch on t.relnamespace = sch.schema_id
left outer join sys.babelfish_view_def vd on t.relname COLLATE sys.database_default = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id()
where t.relkind = 'v'
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.tsql_type_scale_helper(IN type TEXT, IN typemod INT, IN return_null_for_rest bool) RETURNS sys.TINYINT
AS $$
DECLARE
 scale INT;
BEGIN
 IF type IS NULL THEN
  RETURN -1;
 END IF;

 IF typemod = -1 THEN
  CASE type
  WHEN 'date' THEN scale = 0;
  WHEN 'datetime' THEN scale = 3;
  WHEN 'smalldatetime' THEN scale = 0;
  WHEN 'datetime2' THEN scale = 6;
  WHEN 'datetimeoffset' THEN scale = 6;
  WHEN 'decimal' THEN scale = 38;
  WHEN 'numeric' THEN scale = 38;
  WHEN 'money' THEN scale = 4;
  WHEN 'smallmoney' THEN scale = 4;
  WHEN 'time' THEN scale = 6;
  WHEN 'tinyint' THEN scale = 0;
  ELSE
   IF return_null_for_rest
    THEN scale = NULL;
   ELSE scale = 0;
   END IF;
  END CASE;
  RETURN scale;
 END IF;

 CASE type
 WHEN 'decimal' THEN scale = (typemod - 4) & 65535;
 WHEN 'numeric' THEN scale = (typemod - 4) & 65535;
 WHEN 'smalldatetime' THEN scale = 0;
 WHEN 'datetime2' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for datetime2 in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 WHEN 'datetimeoffset' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for datetimeoffset in Babelfish
  -- but adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 WHEN 'time' THEN
  CASE typemod
  WHEN 0 THEN scale = 0;
  WHEN 1 THEN scale = 1;
  WHEN 2 THEN scale = 2;
  WHEN 3 THEN scale = 3;
  WHEN 4 THEN scale = 4;
  WHEN 5 THEN scale = 5;
  WHEN 6 THEN scale = 6;
  -- typemod = 7 is not possible for time in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN scale = 7;
  END CASE;
 ELSE
  IF return_null_for_rest
   THEN scale = NULL;
  ELSE scale = 0;
  END IF;
 END CASE;
 RETURN scale;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_precision_helper(IN type TEXT, IN typemod INT) RETURNS sys.TINYINT
AS $$
DECLARE
 precision INT;
BEGIN
 IF type IS NULL THEN
  RETURN -1;
 END IF;

 IF typemod = -1 THEN
  CASE type
  WHEN 'bigint' THEN precision = 19;
  WHEN 'bit' THEN precision = 1;
  WHEN 'date' THEN precision = 10;
  WHEN 'datetime' THEN precision = 23;
  WHEN 'datetime2' THEN precision = 26;
  WHEN 'datetimeoffset' THEN precision = 33;
  WHEN 'decimal' THEN precision = 38;
  WHEN 'numeric' THEN precision = 38;
  WHEN 'float' THEN precision = 53;
  WHEN 'int' THEN precision = 10;
  WHEN 'money' THEN precision = 19;
  WHEN 'real' THEN precision = 24;
  WHEN 'smalldatetime' THEN precision = 16;
  WHEN 'smallint' THEN precision = 5;
  WHEN 'smallmoney' THEN precision = 10;
  WHEN 'time' THEN precision = 15;
  WHEN 'tinyint' THEN precision = 3;
  ELSE precision = 0;
  END CASE;
  RETURN precision;
 END IF;

 CASE type
 WHEN 'numeric' THEN precision = ((typemod - 4) >> 16) & 65535;
 WHEN 'decimal' THEN precision = ((typemod - 4) >> 16) & 65535;
 WHEN 'smalldatetime' THEN precision = 16;
 WHEN 'datetime2' THEN
  CASE typemod
  WHEN 0 THEN precision = 19;
  WHEN 1 THEN precision = 21;
  WHEN 2 THEN precision = 22;
  WHEN 3 THEN precision = 23;
  WHEN 4 THEN precision = 24;
  WHEN 5 THEN precision = 25;
  WHEN 6 THEN precision = 26;
  -- typemod = 7 is not possible for datetime2 in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN precision = 27;
  END CASE;
 WHEN 'datetimeoffset' THEN
  CASE typemod
  WHEN 0 THEN precision = 26;
  WHEN 1 THEN precision = 28;
  WHEN 2 THEN precision = 29;
  WHEN 3 THEN precision = 30;
  WHEN 4 THEN precision = 31;
  WHEN 5 THEN precision = 32;
  WHEN 6 THEN precision = 33;
  -- typemod = 7 is not possible for datetimeoffset in Babelfish
  -- but adding the case just in case we support it in future
  WHEN 7 THEN precision = 34;
  END CASE;
 WHEN 'time' THEN
  CASE typemod
  WHEN 0 THEN precision = 8;
  WHEN 1 THEN precision = 10;
  WHEN 2 THEN precision = 11;
  WHEN 3 THEN precision = 12;
  WHEN 4 THEN precision = 13;
  WHEN 5 THEN precision = 14;
  WHEN 6 THEN precision = 15;
  -- typemod = 7 is not possible for time in Babelfish but
  -- adding the case just in case we support it in future
  WHEN 7 THEN precision = 16;
  END CASE;
 ELSE precision = 0;
 END CASE;
 RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION sys.tsql_type_max_length_helper(IN type TEXT, IN typelen INT, IN typemod INT, IN for_sys_types boolean DEFAULT false, IN used_typmod_array boolean DEFAULT false)
RETURNS SMALLINT
AS $$
DECLARE
 max_length SMALLINT;
 precision INT;
 v_type TEXT COLLATE sys.database_default := type;
BEGIN
 -- unknown tsql type
 IF v_type IS NULL THEN
  RETURN CAST(typelen as SMALLINT);
 END IF;

 -- if using typmod_array from pg_proc.probin
 IF used_typmod_array THEN
  IF v_type = 'sysname' THEN
   RETURN 256;
  ELSIF (v_type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary', 'nchar', 'nvarchar'))
  THEN
   IF typemod < 0 THEN -- max value.
    RETURN -1;
   ELSIF v_type in ('nchar', 'nvarchar') THEN
    RETURN (2 * typemod);
   ELSE
    RETURN typemod;
   END IF;
  END IF;
 END IF;

 IF typelen != -1 THEN
  CASE v_type
  WHEN 'tinyint' THEN max_length = 1;
  WHEN 'date' THEN max_length = 3;
  WHEN 'smalldatetime' THEN max_length = 4;
  WHEN 'smallmoney' THEN max_length = 4;
  WHEN 'datetime2' THEN
   IF typemod = -1 THEN max_length = 8;
   ELSIF typemod <= 2 THEN max_length = 6;
   ELSIF typemod <= 4 THEN max_length = 7;
   ELSEIF typemod <= 7 THEN max_length = 8;
   -- typemod = 7 is not possible for datetime2 in Babel
   END IF;
  WHEN 'datetimeoffset' THEN
   IF typemod = -1 THEN max_length = 10;
   ELSIF typemod <= 2 THEN max_length = 8;
   ELSIF typemod <= 4 THEN max_length = 9;
   ELSIF typemod <= 7 THEN max_length = 10;
   -- typemod = 7 is not possible for datetimeoffset in Babel
   END IF;
  WHEN 'time' THEN
   IF typemod = -1 THEN max_length = 5;
   ELSIF typemod <= 2 THEN max_length = 3;
   ELSIF typemod <= 4 THEN max_length = 4;
   ELSIF typemod <= 7 THEN max_length = 5;
   END IF;
  WHEN 'timestamp' THEN max_length = 8;
  ELSE max_length = typelen;
  END CASE;
  RETURN max_length;
 END IF;

 IF typemod = -1 THEN
  CASE
  WHEN v_type collate sys.database_default in ('image', 'text', 'ntext') THEN max_length = 16;
  WHEN v_type collate sys.database_default = 'sql_variant' THEN max_length = 8016;
  WHEN v_type collate sys.database_default in ('varbinary', 'varchar', 'nvarchar') THEN
   IF for_sys_types THEN max_length = 8000;
   ELSE max_length = -1;
   END IF;
  WHEN v_type collate sys.database_default in ('binary', 'char', 'bpchar', 'nchar') THEN max_length = 8000;
  WHEN v_type collate sys.database_default in ('decimal', 'numeric') THEN max_length = 17;
  ELSE max_length = typemod;
  END CASE;
  RETURN max_length;
 END IF;

 CASE
 WHEN v_type collate sys.database_default in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN max_length = typemod - 4;
 WHEN v_type collate sys.database_default in ('nchar', 'nvarchar') THEN max_length = (typemod - 4) * 2;
 WHEN v_type collate sys.database_default = 'sysname' THEN max_length = (typemod - 4) * 2;
 WHEN v_type collate sys.database_default in ('numeric', 'decimal') THEN
  precision = ((typemod - 4) >> 16) & 65535;
  IF precision >= 1 and precision <= 9 THEN max_length = 5;
  ELSIF precision <= 19 THEN max_length = 9;
  ELSIF precision <= 28 THEN max_length = 13;
  ELSIF precision <= 38 THEN max_length = 17;
 ELSE max_length = typelen;
 END IF;
 ELSE
  max_length = typemod;
 END CASE;
 RETURN max_length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace view sys.all_columns as
select CAST(c.oid as int) as object_id
  , CAST(a.attname as sys.sysname) as name
  , CAST(a.attnum as int) as column_id
  , CAST(t.oid as int) as system_type_id
  , CAST(t.oid as int) as user_type_id
  , CAST(sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod) as smallint) as max_length
  , CAST(case
      when a.atttypmod != -1 then
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
      else
        sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
    end as sys.tinyint) as precision
  , CAST(case
      when a.atttypmod != -1 THEN
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
      else
        sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
    end as sys.tinyint) as scale
  , CAST(coll.collname as sys.sysname) as collation_name
  , case when a.attnotnull then CAST(0 as sys.bit) else CAST(1 as sys.bit) end as is_nullable
  , CAST(0 as sys.bit) as is_ansi_padded
  , CAST(0 as sys.bit) as is_rowguidcol
  , CAST(0 as sys.bit) as is_identity
  , CAST(0 as sys.bit) as is_computed
  , CAST(0 as sys.bit) as is_filestream
  , CAST(0 as sys.bit) as is_replicated
  , CAST(0 as sys.bit) as is_non_sql_subscribed
  , CAST(0 as sys.bit) as is_merge_published
  , CAST(0 as sys.bit) as is_dts_replicated
  , CAST(0 as sys.bit) as is_xml_document
  , CAST(0 as int) as xml_collection_id
  , CAST(coalesce(d.oid, 0) as int) as default_object_id
  , CAST(coalesce((select oid from pg_constraint where conrelid = t.oid and contype = 'c' and a.attnum = any(conkey) limit 1), 0) as int) as rule_object_id
  , CAST(0 as sys.bit) as is_sparse
  , CAST(0 as sys.bit) as is_column_set
  , CAST(0 as sys.tinyint) as generated_always_type
  , CAST('NOT_APPLICABLE' as sys.nvarchar(60)) as generated_always_type_desc
from pg_attribute a
inner join pg_class c on c.oid = a.attrelid
inner join pg_type t on t.oid = a.atttypid
inner join pg_namespace s on s.oid = c.relnamespace
left join pg_attrdef d on c.oid = d.adrelid and a.attnum = d.adnum
left join pg_collation coll on coll.oid = a.attcollation
, sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
where not a.attisdropped
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
-- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
and c.relkind in ('r', 'v', 'm', 'f', 'p')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(quote_ident(s.nspname) ||'.'||quote_ident(c.relname), a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
and a.attnum > 0;
GRANT SELECT ON sys.all_columns TO PUBLIC;

-- internal function in order to workaround BABEL-1597
CREATE OR REPLACE FUNCTION sys.columns_internal()
RETURNS TABLE (
    out_object_id int,
    out_name sys.sysname,
    out_column_id int,
    out_system_type_id int,
    out_user_type_id int,
    out_max_length smallint,
    out_precision sys.tinyint,
    out_scale sys.tinyint,
    out_collation_name sys.sysname,
    out_collation_id int,
    out_offset smallint,
    out_is_nullable sys.bit,
    out_is_ansi_padded sys.bit,
    out_is_rowguidcol sys.bit,
    out_is_identity sys.bit,
    out_is_computed sys.bit,
    out_is_filestream sys.bit,
    out_is_replicated sys.bit,
    out_is_non_sql_subscribed sys.bit,
    out_is_merge_published sys.bit,
    out_is_dts_replicated sys.bit,
    out_is_xml_document sys.bit,
    out_xml_collection_id int,
    out_default_object_id int,
    out_rule_object_id int,
    out_is_sparse sys.bit,
    out_is_column_set sys.bit,
    out_generated_always_type sys.tinyint,
    out_generated_always_type_desc sys.nvarchar(60),
    out_encryption_type int,
    out_encryption_type_desc sys.nvarchar(64),
    out_encryption_algorithm_name sys.sysname,
    out_column_encryption_key_id int,
    out_column_encryption_key_database_name sys.sysname,
    out_is_hidden sys.bit,
    out_is_masked sys.bit,
    out_graph_type int,
    out_graph_type_desc sys.nvarchar(60)
)
AS
$$
BEGIN
 RETURN QUERY
  SELECT CAST(c.oid AS int),
   CAST(a.attname AS sys.sysname),
   CAST(a.attnum AS int),
   CASE
   WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
    -- either tsql or PG base type
    CAST(a.atttypid AS int)
   ELSE
    CAST(t.typbasetype AS int)
   END,
   CAST(a.atttypid AS int),
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
   ELSE
    sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
   END,
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
   ELSE
    sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
   END,
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
   ELSE
    sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
   END,
   CAST(coll.collname AS sys.sysname),
   CAST(a.attcollation AS int),
   CAST(a.attnum AS smallint),
   CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
   CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit),
   CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS int),
   CAST(coalesce(d.oid, 0) AS int),
   CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
      and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.tinyint),
   CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
   CAST(null AS int),
   CAST(null AS sys.nvarchar(64)),
   CAST(null AS sys.sysname),
   CAST(null AS int),
   CAST(null AS sys.sysname),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(null AS int),
   CAST(null AS sys.nvarchar(60))
  FROM pg_attribute a
  INNER JOIN pg_class c ON c.oid = a.attrelid
  INNER JOIN pg_type t ON t.oid = a.atttypid
  INNER JOIN sys.schemas sch on c.relnamespace = sch.schema_id
  INNER JOIN sys.pg_namespace_ext ext on sch.schema_id = ext.oid
  LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
  LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
  , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
  , sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
  WHERE NOT a.attisdropped
  AND a.attnum > 0
  -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
  AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
  AND has_schema_privilege(sch.schema_id, 'USAGE')
  AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
  union all
  -- system tables information
  SELECT CAST(c.oid AS int),
   CAST(a.attname AS sys.sysname),
   CAST(a.attnum AS int),
   CASE
   WHEN tsql_type_name IS NOT NULL OR t.typbasetype = 0 THEN
    -- either tsql or PG base type
    CAST(a.atttypid AS int)
   ELSE
    CAST(t.typbasetype AS int)
   END,
   CAST(a.atttypid AS int),
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, a.atttypmod)
   ELSE
    sys.tsql_type_max_length_helper(coalesce(tsql_type_name, tsql_base_type_name), a.attlen, t.typtypmod)
   END,
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod)
   ELSE
    sys.tsql_type_precision_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod)
   END,
   CASE
   WHEN a.atttypmod != -1 THEN
    sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), a.atttypmod, false)
   ELSE
    sys.tsql_type_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), t.typtypmod, false)
   END,
   CAST(coll.collname AS sys.sysname),
   CAST(a.attcollation AS int),
   CAST(a.attnum AS smallint),
   CAST(case when a.attnotnull then 0 else 1 end AS sys.bit),
   CAST(case when t.typname in ('bpchar', 'nchar', 'binary') then 1 else 0 end AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit),
   CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS int),
   CAST(coalesce(d.oid, 0) AS int),
   CAST(coalesce((select oid from pg_constraint where conrelid = t.oid
      and contype = 'c' and a.attnum = any(conkey) limit 1), 0) AS int),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.tinyint),
   CAST('NOT_APPLICABLE' AS sys.nvarchar(60)),
   CAST(null AS int),
   CAST(null AS sys.nvarchar(64)),
   CAST(null AS sys.sysname),
   CAST(null AS int),
   CAST(null AS sys.sysname),
   CAST(0 AS sys.bit),
   CAST(0 AS sys.bit),
   CAST(null AS int),
   CAST(null AS sys.nvarchar(60))
  FROM pg_attribute a
  INNER JOIN pg_class c ON c.oid = a.attrelid
  INNER JOIN pg_type t ON t.oid = a.atttypid
  INNER JOIN pg_namespace nsp ON (nsp.oid = c.relnamespace and nsp.nspname = 'sys')
  LEFT JOIN pg_attrdef d ON c.oid = d.adrelid AND a.attnum = d.adnum
  LEFT JOIN pg_collation coll ON coll.oid = a.attcollation
  , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
  , sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
  WHERE NOT a.attisdropped
  AND a.attnum > 0
  AND c.relkind = 'r'
  AND has_schema_privilege(nsp.oid, 'USAGE')
  AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
END;
$$
language plpgsql;

create or replace view sys.columns AS
select out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
from sys.columns_internal();
GRANT SELECT ON sys.columns TO PUBLIC;

CREATE OR replace view sys.foreign_key_columns as
SELECT DISTINCT
  CAST(c.oid AS INT) AS constraint_object_id
  ,CAST((generate_series(1,ARRAY_LENGTH(c.conkey,1))) AS INT) AS constraint_column_id
  ,CAST(c.conrelid AS INT) AS parent_object_id
  ,CAST((UNNEST (c.conkey)) AS INT) AS parent_column_id
  ,CAST(c.confrelid AS INT) AS referenced_object_id
  ,CAST((UNNEST(c.confkey)) AS INT) AS referenced_column_id
FROM pg_constraint c
WHERE c.contype = 'f'
AND (c.connamespace IN (SELECT schema_id FROM sys.schemas))
AND has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.foreign_key_columns TO PUBLIC;

CREATE OR replace view sys.foreign_keys AS
SELECT
  CAST(c.conname AS sys.SYSNAME) AS name
, CAST(c.oid AS INT) AS object_id
, CAST(NULL AS INT) AS principal_id
, CAST(sch.schema_id AS INT) AS schema_id
, CAST(c.conrelid AS INT) AS parent_object_id
, CAST('F' AS CHAR(2)) AS type
, CAST('FOREIGN_KEY_CONSTRAINT' AS NVARCHAR(60)) AS type_desc
, CAST(NULL AS sys.DATETIME) AS create_date
, CAST(NULL AS sys.DATETIME) AS modify_date
, CAST(0 AS sys.BIT) AS is_ms_shipped
, CAST(0 AS sys.BIT) AS is_published
, CAST(0 AS sys.BIT) as is_schema_published
, CAST(c.confrelid AS INT) AS referenced_object_id
, CAST(c.conindid AS INT) AS key_index_id
, CAST(0 AS sys.BIT) AS is_disabled
, CAST(0 AS sys.BIT) AS is_not_for_replication
, CAST(0 AS sys.BIT) AS is_not_trusted
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS delete_referential_action
, CAST(
    (CASE c.confdeltype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) AS delete_referential_action_desc
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 0
    WHEN 'r' THEN 0
    WHEN 'c' THEN 1
    WHEN 'n' THEN 2
    WHEN 'd' THEN 3
    END)
    AS sys.TINYINT) AS update_referential_action
, CAST(
    (CASE c.confupdtype
    WHEN 'a' THEN 'NO_ACTION'
    WHEN 'r' THEN 'NO_ACTION'
    WHEN 'c' THEN 'CASCADE'
    WHEN 'n' THEN 'SET_NULL'
    WHEN 'd' THEN 'SET_DEFAULT'
    END)
    AS sys.NVARCHAR(60)) update_referential_action_desc
, CAST(1 AS sys.BIT) AS is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype = 'f';
GRANT SELECT ON sys.foreign_keys TO PUBLIC;

CREATE OR replace view sys.identity_columns AS
SELECT
  CAST(out_object_id AS INT) AS object_id
  , CAST(out_name AS SYSNAME) AS name
  , CAST(out_column_id AS INT) AS column_id
  , CAST(out_system_type_id AS TINYINT) AS system_type_id
  , CAST(out_user_type_id AS INT) AS user_type_id
  , CAST(out_max_length AS SMALLINT) AS max_length
  , CAST(out_precision AS TINYINT) AS precision
  , CAST(out_scale AS TINYINT) AS scale
  , CAST(out_collation_name AS SYSNAME) AS collation_name
  , CAST(out_is_nullable AS sys.BIT) AS is_nullable
  , CAST(out_is_ansi_padded AS sys.BIT) AS is_ansi_padded
  , CAST(out_is_rowguidcol AS sys.BIT) AS is_rowguidcol
  , CAST(out_is_identity AS sys.BIT) AS is_identity
  , CAST(out_is_computed AS sys.BIT) AS is_computed
  , CAST(out_is_filestream AS sys.BIT) AS is_filestream
  , CAST(out_is_replicated AS sys.BIT) AS is_replicated
  , CAST(out_is_non_sql_subscribed AS sys.BIT) AS is_non_sql_subscribed
  , CAST(out_is_merge_published AS sys.BIT) AS is_merge_published
  , CAST(out_is_dts_replicated AS sys.BIT) AS is_dts_replicated
  , CAST(out_is_xml_document AS sys.BIT) AS is_xml_document
  , CAST(out_xml_collection_id AS INT) AS xml_collection_id
  , CAST(out_default_object_id AS INT) AS default_object_id
  , CAST(out_rule_object_id AS INT) AS rule_object_id
  , CAST(out_is_sparse AS sys.BIT) AS is_sparse
  , CAST(out_is_column_set AS sys.BIT) AS is_column_set
  , CAST(out_generated_always_type AS TINYINT) AS generated_always_type
  , CAST(out_generated_always_type_desc AS NVARCHAR(60)) AS generated_always_type_desc
  , CAST(out_encryption_type AS INT) AS encryption_type
  , CAST(out_encryption_type_desc AS NVARCHAR(60)) AS encryption_type_desc
  , CAST(out_encryption_algorithm_name AS SYSNAME) AS encryption_algorithm_name
  , CAST(out_column_encryption_key_id AS INT) column_encryption_key_id
  , CAST(out_column_encryption_key_database_name AS SYSNAME) AS column_encryption_key_database_name
  , CAST(out_is_hidden AS sys.BIT) AS is_hidden
  , CAST(out_is_masked AS sys.BIT) AS is_masked
  , CAST(sys.ident_seed(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS seed_value
  , CAST(sys.ident_incr(OBJECT_NAME(sc.out_object_id)) AS SQL_VARIANT) AS increment_value
  , CAST(sys.babelfish_get_sequence_value(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname)) AS SQL_VARIANT) AS last_value
  , CAST(0 as sys.BIT) as is_not_for_replication
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = cast(a.attname as sys.sysname) COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_class c ON c.oid = a.attrelid
INNER JOIN sys.pg_namespace_ext ext ON ext.oid = c.relnamespace
WHERE NOT a.attisdropped
AND sc.out_is_identity::INTEGER = 1
AND pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname) IS NOT NULL
AND has_sequence_privilege(pg_get_serial_sequence(quote_ident(ext.nspname)||'.'||quote_ident(c.relname), a.attname), 'USAGE,SELECT,UPDATE');
GRANT SELECT ON sys.identity_columns TO PUBLIC;

create or replace view sys.indexes as
select
  CAST(object_id as int)
  , CAST(name as sys.sysname)
  , CAST(type as sys.tinyint)
  , CAST(type_desc as sys.nvarchar(60))
  , CAST(is_unique as sys.bit)
  , CAST(data_space_id as int)
  , CAST(ignore_dup_key as sys.bit)
  , CAST(is_primary_key as sys.bit)
  , CAST(is_unique_constraint as sys.bit)
  , CAST(fill_factor as sys.tinyint)
  , CAST(is_padded as sys.bit)
  , CAST(is_disabled as sys.bit)
  , CAST(is_hypothetical as sys.bit)
  , CAST(allow_row_locks as sys.bit)
  , CAST(allow_page_locks as sys.bit)
  , CAST(has_filter as sys.bit)
  , CAST(filter_definition as sys.nvarchar)
  , CAST(auto_created as sys.bit)
  , CAST(index_id as int)
from
(
  -- Get all indexes from all system and user tables
  select
    i.indrelid as object_id
    , c.relname as name
    , case when i.indisclustered then 1 else 2 end as type
    , case when i.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as type_desc
    , case when i.indisunique then 1 else 0 end as is_unique
    , c.reltablespace as data_space_id
    , 0 as ignore_dup_key
    , case when i.indisprimary then 1 else 0 end as is_primary_key
    , case when (SELECT count(constr.oid) FROM pg_constraint constr WHERE constr.conindid = c.oid and constr.contype = 'u') > 0 then 1 else 0 end as is_unique_constraint
    , 0 as fill_factor
    , case when i.indpred is null then 0 else 1 end as is_padded
    , case when i.indisready then 0 else 1 end as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , case when i.indisclustered then 1 else c.oid end as index_id
  from pg_class c
  inner join pg_index i on i.indexrelid = c.oid
  where c.relkind = 'i' and i.indislive
  and (c.relnamespace in (select schema_id from sys.schemas) or c.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(c.relnamespace, 'USAGE')

  union all

  -- Create HEAP entries for each system and user table
  select distinct on (t.oid)
    t.oid as object_id
    , null as name
    , 0 as type
    , 'HEAP' as type_desc
    , 0 as is_unique
    , 1 as data_space_id
    , 0 as ignore_dup_key
    , 0 as is_primary_key
    , 0 as is_unique_constraint
    , 0 as fill_factor
    , 0 as is_padded
    , 0 as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , 0 as index_id
  from pg_class t
  where t.relkind = 'r'
  and (t.relnamespace in (select schema_id from sys.schemas) or t.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(t.relnamespace, 'USAGE')
  and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

) as indexes_select order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

CREATE OR replace view sys.key_constraints AS
SELECT
    CAST(c.conname AS SYSNAME) AS name
  , CAST(c.oid AS INT) AS object_id
  , CAST(0 AS INT) AS principal_id
  , CAST(sch.schema_id AS INT) AS schema_id
  , CAST(c.conrelid AS INT) AS parent_object_id
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PK'
      WHEN 'u' THEN 'UQ'
    END)
    AS CHAR(2)) AS type
  , CAST(
    (CASE contype
      WHEN 'p' THEN 'PRIMARY_KEY_CONSTRAINT'
      WHEN 'u' THEN 'UNIQUE_CONSTRAINT'
    END)
    AS NVARCHAR(60)) AS type_desc
  , CAST(NULL AS DATETIME) AS create_date
  , CAST(NULL AS DATETIME) AS modify_date
  , CAST(c.conindid AS INT) AS unique_index_id
  , CAST(0 AS sys.BIT) AS is_ms_shipped
  , CAST(0 AS sys.BIT) AS is_published
  , CAST(0 AS sys.BIT) AS is_schema_published
  , CAST(1 as sys.BIT) as is_system_named
FROM pg_constraint c
INNER JOIN sys.schemas sch ON sch.schema_id = c.connamespace
WHERE has_schema_privilege(sch.schema_id, 'USAGE')
AND c.contype IN ('p', 'u');
GRANT SELECT ON sys.key_constraints TO PUBLIC;

create or replace view sys.procedures as
select
  cast(p.proname as sys.sysname) as name
  , cast(p.oid as int) as object_id
  , cast(null as int) as principal_id
  , cast(sch.schema_id as int) as schema_id
  , cast (0 as int) as parent_object_id
  , cast(case p.prokind
      when 'p' then 'P'
      when 'a' then 'AF'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'TR'
          else 'FN'
        end
    end as sys.bpchar(2)) COLLATE sys.database_default as type
  , cast(case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'
      when 'a' then 'AGGREGATE_FUNCTION'
      else
        case format_type(p.prorettype, null) when 'trigger'
          then 'SQL_TRIGGER'
          else 'SQL_SCALAR_FUNCTION'
        end
    end as sys.nvarchar(60)) as type_desc
  , cast(f.create_date as sys.datetime) as create_date
  , cast(f.create_date as sys.datetime) as modify_date
  , cast(0 as sys.bit) as is_ms_shipped
  , cast(0 as sys.bit) as is_published
  , cast(0 as sys.bit) as is_schema_published
  , cast(0 as sys.bit) as is_auto_executed
  , cast(0 as sys.bit) as is_execution_replicated
  , cast(0 as sys.bit) as is_repl_serializable_only
  , cast(0 as sys.bit) as skips_repl_constraints
from pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and format_type(p.prorettype, null) <> 'trigger'
and has_function_privilege(p.oid, 'EXECUTE');
GRANT SELECT ON sys.procedures TO PUBLIC;

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
inner join pg_attribute a_con on a_con.attrelid = c.conrelid and a_con.attnum = any(c.conkey)
inner join pg_attribute a_conf on a_conf.attrelid = c.confrelid and a_conf.attnum = any(c.confkey)
where c.contype = 'f'
and (c.connamespace in (select schema_id from sys.schemas))
and has_schema_privilege(c.connamespace, 'USAGE');
GRANT SELECT ON sys.sysforeignkeys TO PUBLIC;

create or replace view sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.type::smallint as indid
  , null::binary(6) as root
  , 0::smallint as minlen
  , 1::smallint as keycnt
  , null::smallint as groupid
  , 0 as dpages
  , 0 as reserved
  , 0 as used
  , 0::bigint as rowcnt
  , 0 as rowmodctr
  , 0 as reserved3
  , 0 as reserved4
  , 0::smallint as xmaxlen
  , null::smallint as maxirow
  , 90::sys.tinyint as "OrigFillFactor"
  , 0::sys.tinyint as "StatVersion"
  , 0 as reserved2
  , null::binary(6) as "FirstIAM"
  , 0::smallint as impid
  , 0::smallint as lockflags
  , 0 as pgmodctr
  , null::sys.varbinary(816) as keys
  , i.name::sys.sysname as name
  , null::sys.image as statblob
  , 0 as maxlen
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
  , CAST(t.host_name AS sys.nchar(128)) as hostname
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
 left join pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
 where a.datname = current_database();
GRANT SELECT ON sys.sysprocesses TO PUBLIC;

create or replace view sys.types As
with type_code_list as
(
    select distinct pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
)
-- For System types
select
  ti.tsql_type_name as name
  , t.oid as system_type_id
  , t.oid as user_type_id
  , s.oid as schema_id
  , cast(NULL as INT) as principal_id
  , sys.tsql_type_max_length_helper(ti.tsql_type_name, t.typlen, t.typtypmod, true) as max_length
  , cast(sys.tsql_type_precision_helper(ti.tsql_type_name, t.typtypmod) as int) as precision
  , cast(sys.tsql_type_scale_helper(ti.tsql_type_name, t.typtypmod, false) as int) as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE c.collname
    END as collation_name
  , case when typnotnull then 0 else 1 end as is_nullable
  , 0 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , 0 as is_table_type
from pg_type t
inner join pg_namespace s on s.oid = t.typnamespace
inner join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
,cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
where
ti.tsql_type_name IS NOT NULL
and pg_type_is_visible(t.oid)
and (s.nspname = 'pg_catalog' OR s.nspname = 'sys')
union all
-- For User Defined Types
select cast(t.typname as text) collate sys.database_default as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , t.typnamespace as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE c.collname
    END as collation_name
  , case when tt.typrelid is not null then 0
         else case when typnotnull then 0 else 1 end
    end
    as is_nullable
  -- CREATE TYPE ... FROM is implemented as CREATE DOMAIN in babel
  , 1 as is_user_defined
  , 0 as is_assembly_type
  , 0 as default_object_id
  , 0 as rule_object_id
  , case when tt.typrelid is not null then 1 else 0 end as is_table_type
from pg_type t
join sys.schemas sch on t.typnamespace = sch.schema_id
left join type_code_list ti on t.typname = ti.pg_type_name collate database_default
left join pg_collation c on c.oid = t.typcollation
left join sys.table_types_internal tt on t.typrelid = tt.typrelid
, sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_base_type_name
, cast(current_setting('babelfishpg_tsql.server_collation_name') as name) as default_collation_name
-- we want to show details of user defined datatypes created under babelfish database
where
 ti.tsql_type_name IS NULL
and
  (
    -- show all user defined datatypes created under babelfish database except table types
    t.typtype = 'd'
    or
    -- only for table types
    tt.typrelid is not null
  );
GRANT SELECT ON sys.types TO PUBLIC;

create or replace view sys.table_types as
select st.*
  , pt.typrelid::int as type_table_object_id
  , 0::sys.bit as is_memory_optimized -- return 0 until we support in-memory tables
from sys.types st
inner join pg_catalog.pg_type pt on st.user_type_id = pt.oid
where is_table_type = 1;
GRANT SELECT ON sys.table_types TO PUBLIC;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name collate "C" || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as char(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_expr returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(pg_get_expr(d.adbin, d.adrelid), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as sys.bpchar(2)) as type
  , CAST('CHECK_CONSTRAINT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(0 as sys.bit) as is_disabled
  , CAST(0 as sys.bit) as is_not_for_replication
  , CAST(0 as sys.bit) as is_not_trusted
  , CAST(c.conkey[1] as integer) AS parent_column_id
  -- use a simple regex to strip the datatype and collation that pg_get_constraintdef returns after a double-colon that is not expected in SQL Server
  , CAST(regexp_replace(substring(pg_get_constraintdef(c.oid) from 7), '::"?\w+"?| COLLATE "\w+"', '', 'g') as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on cast(t.schema_name as sys.sysname) = cast(ns.nspname as sys.sysname)

union all

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name=b.orig_name COLLATE sys.database_default
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname COLLATE sys.database_default;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

create or replace view sys.all_objects as
select
    cast (name as sys.sysname) collate sys.database_default
  , cast (object_id as integer)
  , cast ( principal_id as integer)
  , cast (schema_id as integer)
  , cast (parent_object_id as integer)
  , cast (type as char(2)) collate sys.database_default
  , cast (type_desc as sys.nvarchar(60))
  , cast (create_date as sys.datetime)
  , cast (modify_date as sys.datetime)
  , cast (case when (schema_id::regnamespace::text = 'sys' collate sys.database_default) then 1
          when name in (select name from sys.shipped_objects_not_in_sys nis
                        where nis.name = name collate sys.database_default and nis.schemaid = schema_id and nis.type = type collate sys.database_default) then 1
          else 0 end as sys.bit) as is_ms_shipped
  , cast (is_published as sys.bit)
  , cast (is_schema_published as sys.bit)
from
(
-- details of user defined and system tables
select
    t.relname collate sys.database_default as name
  , t.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , 0 as parent_object_id
  , 'U' as type
  , 'USER_TABLE' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relpersistence in ('p', 'u', 't')
and t.relkind = 'r'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and not sys.is_table_type(t.oid)
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system views
select
    t.relname collate sys.database_default as name
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
from pg_class t inner join pg_namespace s on s.oid = t.relnamespace
where t.relkind = 'v'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_table_privilege(quote_ident(s.nspname) ||'.'||quote_ident(t.relname), 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
union all
-- details of user defined and system foreign key constraints
select
    c.conname collate database_default as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'F' as type
  , 'FOREIGN_KEY_CONSTRAINT'
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'f'
union all
-- details of user defined and system primary key constraints
select
    c.conname collate sys.database_default as name
  , c.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , c.conrelid as parent_object_id
  , 'PK' as type
  , 'PRIMARY_KEY_CONSTRAINT' as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_constraint c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'p'
union all
-- details of user defined and system defined procedures
select
    p.proname collate sys.database_default as name
  , p.oid as object_id
  , null::integer as principal_id
  , s.oid as schema_id
  , cast (case when tr.tgrelid is not null
           then tr.tgrelid
           else 0 end as int)
    as parent_object_id
  , case p.prokind
      when 'p' then 'P'::varchar(2)
      when 'a' then 'AF'::varchar(2)
      else
        case
          when pg_catalog.format_type(p.prorettype, null) = 'trigger'
            then 'TR'::varchar(2)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'TF'::varchar(2)
              else 'IF'::varchar(2)
            end
          else 'FN'::varchar(2)
        end
    end as type
  , case p.prokind
      when 'p' then 'SQL_STORED_PROCEDURE'::varchar(60)
      when 'a' then 'AGGREGATE_FUNCTION'::varchar(60)
      else
        case
          when pg_catalog.format_type(p.prorettype, null) = 'trigger'
            then 'SQL_TRIGGER'::varchar(60)
          when p.proretset then
            case
              when t.typtype = 'c'
                then 'SQL_TABLE_VALUED_FUNCTION'::varchar(60)
              else 'SQL_INLINE_TABLE_VALUED_FUNCTION'::varchar(60)
            end
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
inner join pg_catalog.pg_type t on t.oid = p.prorettype
left join pg_trigger tr on tr.tgfoid = p.oid
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
union all
-- details of all default constraints
select
    ('DF_' || o.relname collate sys.database_default || '_' || d.oid)::name collate sys.database_default as name
  , d.oid as object_id
  , null::int as principal_id
  , o.relnamespace as schema_id
  , d.adrelid as parent_object_id
  , 'D'::char(2) as type
  , 'DEFAULT_CONSTRAINT'::sys.nvarchar(60) AS type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_attrdef d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join pg_class o on d.adrelid = o.oid
inner join pg_namespace s on s.oid = o.relnamespace
where a.atthasdef = 't' and a.attgenerated = ''
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES')
union all
-- details of all check constraints
select
    c.conname::name collate sys.database_default
  , c.oid::integer as object_id
  , NULL::integer as principal_id
  , c.connamespace::integer as schema_id
  , c.conrelid::integer as parent_object_id
  , 'C'::char(2) as type
  , 'CHECK_CONSTRAINT'::sys.nvarchar(60) as type_desc
  , null::sys.datetime as create_date
  , null::sys.datetime as modify_date
  , 0 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from pg_catalog.pg_constraint as c
inner join pg_namespace s on s.oid = c.connamespace
where (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
and c.contype = 'c' and c.conrelid != 0
union all
-- details of user defined and system defined sequence objects
select
  p.relname collate sys.database_default as name
  , p.oid as object_id
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
where p.relkind = 'S'
and (s.oid in (select schema_id from sys.schemas) or s.nspname = 'sys')
and has_schema_privilege(s.oid, 'USAGE')
union all
-- details of user defined table types
select
    ('TT_' || tt.name collate sys.database_default || '_' || tt.type_table_object_id)::name collate sys.database_default as name
  , tt.type_table_object_id as object_id
  , tt.principal_id as principal_id
  , tt.schema_id as schema_id
  , 0 as parent_object_id
  , 'TT'::varchar(2) as type
  , 'TABLE_TYPE'::varchar(60) as type_desc
  , null::timestamp as create_date
  , null::timestamp as modify_date
  , 1 as is_ms_shipped
  , 0 as is_published
  , 0 as is_schema_published
from sys.table_types tt
) ot;
GRANT SELECT ON sys.all_objects TO PUBLIC;

create or replace view sys.system_objects as
select * from sys.all_objects o
inner join pg_namespace s on s.oid = o.schema_id
where s.nspname = 'sys';
GRANT SELECT ON sys.system_objects TO PUBLIC;

create or replace view sys.all_views as
select
    CAST(t.name as sys.SYSNAME) COLLATE sys.database_default AS name
  , CAST(t.object_id as int) AS object_id
  , CAST(t.principal_id as int) AS principal_id
  , CAST(t.schema_id as int) AS schema_id
  , CAST(t.parent_object_id as int) AS parent_object_id
  , CAST(t.type as sys.bpchar(2)) AS type
  , CAST(t.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(t.create_date as sys.datetime) AS create_date
  , CAST(t.modify_date as sys.datetime) AS modify_date
  , CAST(t.is_ms_shipped as sys.BIT) AS is_ms_shipped
  , CAST(t.is_published as sys.BIT) AS is_published
  , CAST(t.is_schema_published as sys.BIT) AS is_schema_published
  , CAST(0 as sys.BIT) AS is_replicated
  , CAST(0 as sys.BIT) AS has_replication_filter
  , CAST(0 as sys.BIT) AS has_opaque_metadata
  , CAST(0 as sys.BIT) AS has_unchecked_assembly_data
  , CAST(
      CASE
        WHEN (v.check_option = 'NONE')
          THEN 0
        ELSE 1
      END
    AS sys.BIT) AS with_check_option
  , CAST(0 as sys.BIT) AS is_date_correlation_view
from sys.all_objects t
INNER JOIN pg_namespace ns ON t.schema_id = ns.oid
INNER JOIN information_schema.views v ON t.name = cast(v.table_name as sys.sysname) AND ns.nspname = v.table_schema
where t.type = 'V';
GRANT SELECT ON sys.all_views TO PUBLIC;

-- TODO: BABELFISH-506
CREATE OR REPLACE VIEW sys.triggers
AS
SELECT
  CAST(p.proname as sys.sysname) as name,
  CAST(p.oid as int) as object_id,
  CAST(1 as sys.tinyint) as parent_class,
  CAST('OBJECT_OR_COLUMN' as sys.nvarchar(60)) AS parent_class_desc,
  CAST(tr.tgrelid as int) AS parent_id,
  CAST('TR' as sys.bpchar(2)) AS type,
  CAST('SQL_TRIGGER' as sys.nvarchar(60)) AS type_desc,
  CAST(f.create_date as sys.datetime) AS create_date,
  CAST(f.create_date as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_ms_shipped,
  CAST(
      CASE WHEN tr.tgenabled = 'D'
      THEN 1
      ELSE 0
      END
      AS sys.bit
  ) AS is_disabled,
  CAST(0 as sys.bit) AS is_not_for_replication,
  CAST(get_bit(CAST(CAST(tr.tgtype as int) as bit(7)),0) as sys.bit) AS is_instead_of_trigger
FROM pg_proc p
inner join sys.schemas sch on sch.schema_id = p.pronamespace
left join pg_trigger tr on tr.tgfoid = p.oid
left join sys.babelfish_function_ext f on p.proname = f.funcname and sch.schema_id::regnamespace::name = f.nspname
and sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature collate "C"
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_function_privilege(p.oid, 'EXECUTE')
and p.prokind = 'f'
and format_type(p.prorettype, null) = 'trigger';
GRANT SELECT ON sys.triggers TO PUBLIC;

create or replace view sys.objects as
select
      CAST(t.name as sys.sysname) as name
    , CAST(t.object_id as int) as object_id
    , CAST(t.principal_id as int) as principal_id
    , CAST(t.schema_id as int) as schema_id
    , CAST(t.parent_object_id as int) as parent_object_id
    , CAST('U' as char(2)) as type
    , CAST('USER_TABLE' as sys.nvarchar(60)) as type_desc
    , CAST(t.create_date as sys.datetime) as create_date
    , CAST(t.modify_date as sys.datetime) as modify_date
    , CAST(t.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(t.is_published as sys.bit) as is_published
    , CAST(t.is_schema_published as sys.bit) as is_schema_published
from sys.tables t
union all
select
      CAST(v.name as sys.sysname) as name
    , CAST(v.object_id as int) as object_id
    , CAST(v.principal_id as int) as principal_id
    , CAST(v.schema_id as int) as schema_id
    , CAST(v.parent_object_id as int) as parent_object_id
    , CAST('V' as char(2)) as type
    , CAST('VIEW' as sys.nvarchar(60)) as type_desc
    , CAST(v.create_date as sys.datetime) as create_date
    , CAST(v.modify_date as sys.datetime) as modify_date
    , CAST(v.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(v.is_published as sys.bit) as is_published
    , CAST(v.is_schema_published as sys.bit) as is_schema_published
from sys.views v
union all
select
      CAST(f.name as sys.sysname) as name
    , CAST(f.object_id as int) as object_id
    , CAST(f.principal_id as int) as principal_id
    , CAST(f.schema_id as int) as schema_id
    , CAST(f.parent_object_id as int) as parent_object_id
    , CAST('F' as char(2)) as type
    , CAST('FOREIGN_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(f.create_date as sys.datetime) as create_date
    , CAST(f.modify_date as sys.datetime) as modify_date
    , CAST(f.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(f.is_published as sys.bit) as is_published
    , CAST(f.is_schema_published as sys.bit) as is_schema_published
 from sys.foreign_keys f
union all
select
      CAST(p.name as sys.sysname) as name
    , CAST(p.object_id as int) as object_id
    , CAST(p.principal_id as int) as principal_id
    , CAST(p.schema_id as int) as schema_id
    , CAST(p.parent_object_id as int) as parent_object_id
    , CAST('PK' as char(2)) as type
    , CAST('PRIMARY_KEY_CONSTRAINT' as sys.nvarchar(60)) as type_desc
    , CAST(p.create_date as sys.datetime) as create_date
    , CAST(p.modify_date as sys.datetime) as modify_date
    , CAST(p.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(p.is_published as sys.bit) as is_published
    , CAST(p.is_schema_published as sys.bit) as is_schema_published
from sys.key_constraints p
where p.type = 'PK'
union all
select
      CAST(pr.name as sys.sysname) as name
    , CAST(pr.object_id as int) as object_id
    , CAST(pr.principal_id as int) as principal_id
    , CAST(pr.schema_id as int) as schema_id
    , CAST(pr.parent_object_id as int) as parent_object_id
    , CAST(pr.type as char(2)) as type
    , CAST(pr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(pr.create_date as sys.datetime) as create_date
    , CAST(pr.modify_date as sys.datetime) as modify_date
    , CAST(pr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(pr.is_published as sys.bit) as is_published
    , CAST(pr.is_schema_published as sys.bit) as is_schema_published
 from sys.procedures pr
union all
select
      CAST(tr.name as sys.sysname) as name
    , CAST(tr.object_id as int) as object_id
    , CAST(NULL as int) as principal_id
    , CAST(p.pronamespace as int) as schema_id
    , CAST(tr.parent_id as int) as parent_object_id
    , CAST(tr.type as char(2)) as type
    , CAST(tr.type_desc as sys.nvarchar(60)) as type_desc
    , CAST(tr.create_date as sys.datetime) as create_date
    , CAST(tr.modify_date as sys.datetime) as modify_date
    , CAST(tr.is_ms_shipped as sys.bit) as is_ms_shipped
    , CAST(0 as sys.bit) as is_published
    , CAST(0 as sys.bit) as is_schema_published
  from sys.triggers tr
  inner join pg_proc p on p.oid = tr.object_id
union all
select
    CAST(def.name as sys.sysname) as name
  , CAST(def.object_id as int) as object_id
  , CAST(def.principal_id as int) as principal_id
  , CAST(def.schema_id as int) as schema_id
  , CAST(def.parent_object_id as int) as parent_object_id
  , CAST(def.type as char(2)) as type
  , CAST(def.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(def.create_date as sys.datetime) as create_date
  , CAST(def.modified_date as sys.datetime) as modify_date
  , CAST(def.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(def.is_published as sys.bit) as is_published
  , CAST(def.is_schema_published as sys.bit) as is_schema_published
  from sys.default_constraints def
union all
select
    CAST(chk.name as sys.sysname) as name
  , CAST(chk.object_id as int) as object_id
  , CAST(chk.principal_id as int) as principal_id
  , CAST(chk.schema_id as int) as schema_id
  , CAST(chk.parent_object_id as int) as parent_object_id
  , CAST(chk.type as char(2)) as type
  , CAST(chk.type_desc as sys.nvarchar(60)) as type_desc
  , CAST(chk.create_date as sys.datetime) as create_date
  , CAST(chk.modify_date as sys.datetime) as modify_date
  , CAST(chk.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(chk.is_published as sys.bit) as is_published
  , CAST(chk.is_schema_published as sys.bit) as is_schema_published
  from sys.check_constraints chk
union all
select
    CAST(p.relname as sys.sysname) as name
  , CAST(p.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(s.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('SO' as char(2)) as type
  , CAST('SEQUENCE_OBJECT' as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from pg_class p
inner join sys.schemas s on s.schema_id = p.relnamespace
and p.relkind = 'S'
and has_schema_privilege(s.schema_id, 'USAGE')
union all
select
    CAST(('TT_' || tt.name collate "C" || '_' || tt.type_table_object_id) as sys.sysname) as name
  , CAST(tt.type_table_object_id as int) as object_id
  , CAST(tt.principal_id as int) as principal_id
  , CAST(tt.schema_id as int) as schema_id
  , CAST(0 as int) as parent_object_id
  , CAST('TT' as char(2)) as type
  , CAST('TABLE_TYPE' as sys.nvarchar(60)) as type_desc
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as create_date
  , CAST((select string_agg(
                    case
                    when option like 'bbf_rel_create_date=%%' then substring(option, 21)
                    else NULL
                    end, ',')
          from unnest(c.reloptions) as option)
     as sys.datetime) as modify_date
  , CAST(1 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
from sys.table_types tt
inner join pg_class c on tt.type_table_object_id = c.oid;
GRANT SELECT ON sys.objects TO PUBLIC;

create or replace view sys.sysobjects as
select
  CAST(s.name as sys._ci_sysname)
  , CAST(s.object_id as int) as id
  , CAST(s.type as sys.bpchar(2)) as xtype

  -- 'uid' is specified as type INT here, and not SMALLINT per SQL Server documentation.
  -- This is because if you routinely drop and recreate databases, it is possible for the
  -- dbo schema which relies on pg_catalog oid values to exceed the size of a smallint.
  , CAST(s.schema_id as int) as uid
  , CAST(0 as smallint) as info
  , CAST(0 as int) as status
  , CAST(0 as int) as base_schema_ver
  , CAST(0 as int) as replinfo
  , CAST(s.parent_object_id as int) as parent_obj
  , CAST(s.create_date as sys.datetime) as crdate
  , CAST(0 as smallint) as ftcatid
  , CAST(0 as int) as schema_ver
  , CAST(0 as int) as stats_schema_ver
  , CAST(s.type as sys.bpchar(2)) as type
  , CAST(0 as smallint) as userstat
  , CAST(0 as smallint) as sysstat
  , CAST(0 as smallint) as indexdel
  , CAST(s.modify_date as sys.datetime) as refdate
  , CAST(0 as int) as version
  , CAST(0 as int) as deltrig
  , CAST(0 as int) as instrig
  , CAST(0 as int) as updtrig
  , CAST(0 as int) as seltrig
  , CAST(0 as int) as category
  , CAST(0 as smallint) as cache
from sys.objects s;
GRANT SELECT ON sys.sysobjects TO PUBLIC;

-- TODO: BABEL-3127
CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF') THEN COALESCE(tsql_get_functiondef(ao.object_id), pg_get_functiondef(ao.object_id))
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      WHEN ao.type = 'TR' THEN NULL
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit) AS uses_ansi_nulls
  , CAST(1 as sys.bit) AS uses_quoted_identifier
  , CAST(0 as sys.bit) AS is_schema_bound
  , CAST(0 as sys.bit) AS uses_database_collation
  , CAST(0 as sys.bit) AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF') THEN
        CASE WHEN p.proisstrict THEN 1
        ELSE 0
        END
      ELSE 0
      END
    AS sys.bit) as null_on_null_input
  , null::integer as execute_as_principal_id
  , CAST(0 as sys.bit) as uses_native_compilation
  , CAST(ao.is_ms_shipped as INT) as is_ms_shipped
FROM sys.all_objects ao
LEFT OUTER JOIN sys.pg_namespace_ext nmext on ao.schema_id = nmext.oid
LEFT OUTER JOIN sys.babelfish_namespace_ext ext ON nmext.nspname = ext.nspname
LEFT OUTER JOIN sys.babelfish_view_def bvd
 on (
      ext.orig_name = bvd.schema_name AND
      ext.dbid = bvd.dbid AND
      ao.name = bvd.object_name
   )
LEFT JOIN pg_proc p ON ao.object_id = CAST(p.oid AS INT)
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1;
GRANT SELECT ON sys.all_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.system_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 1;
GRANT SELECT ON sys.system_sql_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar(4000))
    ,CAST(t1.uses_ansi_nulls as sys.bit)
    ,CAST(t1.uses_quoted_identifier as sys.bit)
    ,CAST(t1.is_schema_bound as sys.bit)
    ,CAST(t1.uses_database_collation as sys.bit)
    ,CAST(t1.is_recompiled as sys.bit)
    ,CAST(t1.null_on_null_input as sys.bit)
    ,CAST(t1.execute_as_principal_id as int)
    ,CAST(t1.uses_native_compilation as sys.bit)
FROM sys.all_sql_modules_internal t1
WHERE t1.is_ms_shipped = 0;
GRANT SELECT ON sys.sql_modules TO PUBLIC;

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

CREATE OR REPLACE VIEW sys.computed_columns
AS
SELECT out_object_id as object_id
  , out_name as name
  , out_column_id as column_id
  , out_system_type_id as system_type_id
  , out_user_type_id as user_type_id
  , out_max_length as max_length
  , out_precision as precision
  , out_scale as scale
  , out_collation_name as collation_name
  , out_is_nullable as is_nullable
  , out_is_ansi_padded as is_ansi_padded
  , out_is_rowguidcol as is_rowguidcol
  , out_is_identity as is_identity
  , out_is_computed as is_computed
  , out_is_filestream as is_filestream
  , out_is_replicated as is_replicated
  , out_is_non_sql_subscribed as is_non_sql_subscribed
  , out_is_merge_published as is_merge_published
  , out_is_dts_replicated as is_dts_replicated
  , out_is_xml_document as is_xml_document
  , out_xml_collection_id as xml_collection_id
  , out_default_object_id as default_object_id
  , out_rule_object_id as rule_object_id
  , out_is_sparse as is_sparse
  , out_is_column_set as is_column_set
  , out_generated_always_type as generated_always_type
  , out_generated_always_type_desc as generated_always_type_desc
  , out_encryption_type as encryption_type
  , out_encryption_type_desc as encryption_type_desc
  , out_encryption_algorithm_name as encryption_algorithm_name
  , out_column_encryption_key_id as column_encryption_key_id
  , out_column_encryption_key_database_name as column_encryption_key_database_name
  , out_is_hidden as is_hidden
  , out_is_masked as is_masked
  , out_graph_type as graph_type
  , out_graph_type_desc as graph_type_desc
  , substring(pg_get_expr(d.adbin, d.adrelid), 1, 4000)::sys.nvarchar(4000) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.endpoints
AS
SELECT CAST('TSQL Default TCP' AS sys.sysname) AS name
 , CAST(4 AS int) AS endpoint_id
 , CAST(1 AS int) AS principal_id
 , CAST(2 AS sys.tinyint) AS protocol
 , CAST('TCP' AS sys.nvarchar(60)) AS protocol_desc
 , CAST(2 AS sys.tinyint) AS type
  , CAST('TSQL' AS sys.nvarchar(60)) AS type_desc
  , CAST(0 AS tinyint) AS state
  , CAST('STARTED' AS sys.nvarchar(60)) AS state_desc
  , CAST(0 AS sys.bit) AS is_admin_endpoint;
GRANT SELECT ON sys.endpoints TO PUBLIC;

create or replace view sys.index_columns
as
select i.indrelid::integer as object_id
  , i.indexrelid::integer as index_id
  , a.attrelid::integer as index_column_id
  , a.attnum::integer as column_id
  , a.attnum::sys.tinyint as key_ordinal
  , 0::sys.tinyint as partition_ordinal
  , 0::sys.bit as is_descending_key
  , 1::sys.bit as is_included_column
from pg_index as i
inner join pg_catalog.pg_attribute a on i.indexrelid = a.attrelid
inner join pg_class c on i.indrelid = c.oid
inner join sys.schemas sch on sch.schema_id = c.relnamespace
where has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.index_columns TO PUBLIC;

-- internal function that returns relevant info needed
-- by sys.syscolumns view for all procedure parameters.
-- This separate function was needed to workaround BABEL-1597
CREATE OR REPLACE FUNCTION sys.proc_param_helper()
RETURNS TABLE (
    name sys.sysname,
    id int,
    xtype int,
    colid smallint,
    collationid int,
    prec smallint,
    scale int,
    isoutparam int,
    collation sys.sysname
)
AS
$$
BEGIN
RETURN QUERY
select params.parameter_name::sys.sysname
  , pgproc.oid::int
  , CAST(case when pgproc.proallargtypes is null then split_part(pgproc.proargtypes::varchar, ' ', params.ordinal_position)
    else split_part(btrim(pgproc.proallargtypes::text,'{}'), ',', params.ordinal_position) end AS int)
  , params.ordinal_position::smallint
  , coll.oid::int
  , params.numeric_precision::smallint
  , params.numeric_scale::int
  , case params.parameter_mode when 'OUT' COLLATE sys.database_default then 1 when 'INOUT' COLLATE sys.database_default then 1 else 0 end
  , params.collation_name::sys.sysname
from information_schema.routines routine
left join information_schema.parameters params
  on routine.specific_schema = params.specific_schema
  and routine.specific_name = params.specific_name
left join pg_collation coll on coll.collname = params.collation_name

left join pg_proc pgproc on routine.specific_name = nameconcatoid(pgproc.proname, pgproc.oid)
left join sys.schemas sch on sch.schema_id = pgproc.pronamespace
where has_schema_privilege(sch.schema_id, 'USAGE');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW sys.syscolumns AS
SELECT out_name as name
  , out_object_id as id
  , out_system_type_id as xtype
  , 0::sys.tinyint as typestat
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as xusertype
  , out_max_length as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , out_column_id::smallint as colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , out_default_object_id::int as cdefault
  , out_rule_object_id::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , out_offset as offset
  , out_collation_id as collationid
  , (case out_is_nullable::int when 1 then 8 else 0 end +
     case out_is_identity::int when 1 then 128 else 0 end)::sys.tinyint as status
  , out_system_type_id as type
  , (case when out_user_type_id < 32767 then out_user_type_id else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , out_precision::smallint as prec
  , out_scale::int as scale
  , out_is_computed::int as iscomputed
  , 0::int as isoutparam
  , out_is_nullable::int as isnullable
  , out_collation_name::sys.sysname as collation
FROM sys.columns_internal()
union all
SELECT p.name
  , p.id
  , p.xtype
  , 0::sys.tinyint as typestat
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as xusertype
  , null as length
  , 0::sys.tinyint as xprec
  , 0::sys.tinyint as xscale
  , p.colid
  , 0::smallint as xoffset
  , 0::sys.tinyint as bitpos
  , 0::sys.tinyint as reserved
  , 0::smallint as colstat
  , null::int as cdefault
  , null::int as domain
  , 0::smallint as number
  , 0::smallint as colorder
  , null::sys.varbinary(8000) as autoval
  , 0::smallint as offset
  , collationid
  , (case p.isoutparam when 1 then 64 else 0 end)::sys.tinyint as status
  , p.xtype as type
  , (case when p.xtype < 32767 then p.xtype else null end)::smallint as usertype
  , null::varchar(255) as printfmt
  , p.prec
  , p.scale
  , 0::int as iscomputed
  , p.isoutparam
  , 1::int as isnullable
  , p.collation
FROM sys.proc_param_helper() as p;
GRANT SELECT ON sys.syscolumns TO PUBLIC;

create or replace view sys.dm_exec_sessions
  as
  select a.pid as session_id
    , a.backend_start::sys.datetime as login_time
    , d.host_name::sys.nvarchar(128) as host_name
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

CREATE OR REPLACE VIEW sys.configurations
AS
SELECT configuration_id,
        name,
        value,
        minimum,
        maximum,
        value_in_use,
        description,
        is_dynamic,
        is_advanced
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.configurations TO PUBLIC;

CREATE OR REPLACE VIEW sys.syscurconfigs
AS
SELECT value,
        configuration_id AS config,
        comment_syscurconfigs AS comment,
        CASE
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 0 THEN CAST(0 as smallint)
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 1 THEN CAST(1 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 0 THEN CAST(2 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 1 THEN CAST(3 as smallint)
        END AS status
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.syscurconfigs TO PUBLIC;

CREATE OR REPLACE VIEW sys.sysconfigures
AS
SELECT value_in_use AS value,
        configuration_id AS config,
        comment_sysconfigures AS comment,
        CASE
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 0 THEN CAST(0 as smallint)
         WHEN CAST(is_advanced as int) = 0 AND CAST(is_dynamic as int) = 1 THEN CAST(1 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 0 THEN CAST(2 as smallint)
         WHEN CAST(is_advanced as int) = 1 AND CAST(is_dynamic as int) = 1 THEN CAST(3 as smallint)
        END AS status
FROM sys.babelfish_configurations;
GRANT SELECT ON sys.sysconfigures TO PUBLIC;

CREATE OR REPLACE VIEW sys.syslanguages
AS
SELECT
    lang_id AS langid,
    CAST(lower(lang_data_jsonb ->> 'date_format') AS SYS.NCHAR(3)) AS dateformat,
    CAST(lang_data_jsonb -> 'date_first' AS SYS.TINYINT) AS datefirst,
    CAST(NULL AS INT) AS upgrade,
    CAST(coalesce(lang_name_mssql, lang_name_pg) AS SYS.SYSNAME) AS name,
    CAST(coalesce(lang_alias_mssql, lang_alias_pg) AS SYS.SYSNAME) AS alias,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_names')), ',') AS SYS.NVARCHAR(372)) AS months,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'months_shortnames')),',') AS SYS.NVARCHAR(132)) AS shortmonths,
    CAST(array_to_string(ARRAY(SELECT jsonb_array_elements_text(lang_data_jsonb -> 'days_shortnames')),',') AS SYS.NVARCHAR(217)) AS days,
    CAST(NULL AS INT) AS lcid,
    CAST(NULL AS SMALLINT) AS msglangid
FROM sys.babelfish_syslanguages;
GRANT SELECT ON sys.syslanguages TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_schema_collections
AS
SELECT
  CAST(NULL AS INT) as xml_collection_id,
  CAST(NULL AS INT) as schema_id,
  CAST(NULL AS INT) as principal_id,
  CAST('sys' AS sys.sysname) as name,
  CAST(NULL as sys.datetime) as create_date,
  CAST(NULL as sys.datetime) as modify_date
WHERE FALSE;
GRANT SELECT ON sys.xml_schema_collections TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_database_replica_states
AS
SELECT
   CAST(0 as INT) database_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as replica_id
  ,CAST(NULL as sys.UNIQUEIDENTIFIER) as group_database_id
  ,CAST(0 as sys.BIT) as is_local
  ,CAST(0 as sys.BIT) as is_primary_replica
  ,CAST(0 as sys.TINYINT) as synchronization_state
  ,CAST('' as sys.nvarchar(60)) as synchronization_state_desc
  ,CAST(0 as sys.BIT) as is_commit_participant
  ,CAST(0 as sys.TINYINT) as synchronization_health
  ,CAST('' as sys.nvarchar(60)) as synchronization_health_desc
  ,CAST(0 as sys.TINYINT) as database_state
  ,CAST('' as sys.nvarchar(60)) as database_state_desc
  ,CAST(0 as sys.BIT) as is_suspended
  ,CAST(0 as sys.TINYINT) as suspend_reason
  ,CAST('' as sys.nvarchar(60)) as suspend_reason_desc
  ,CAST(0.0 as numeric(25,0)) as truncation_lsn
  ,CAST(0.0 as numeric(25,0)) as recovery_lsn
  ,CAST(0.0 as numeric(25,0)) as last_sent_lsn
  ,CAST(NULL as sys.DATETIME) as last_sent_time
  ,CAST(0.0 as numeric(25,0)) as last_received_lsn
  ,CAST(NULL as sys.DATETIME) as last_received_time
  ,CAST(0.0 as numeric(25,0)) as last_hardened_lsn
  ,CAST(NULL as sys.DATETIME) as last_hardened_time
  ,CAST(0.0 as numeric(25,0)) as last_redone_lsn
  ,CAST(NULL as sys.DATETIME) as last_redone_time
  ,CAST(0 as sys.BIGINT) as log_send_queue_size
  ,CAST(0 as sys.BIGINT) as log_send_rate
  ,CAST(0 as sys.BIGINT) as redo_queue_size
  ,CAST(0 as sys.BIGINT) as redo_rate
  ,CAST(0 as sys.BIGINT) as filestream_send_rate
  ,CAST(0.0 as numeric(25,0)) as end_of_log_lsn
  ,CAST(0.0 as numeric(25,0)) as last_commit_lsn
  ,CAST(NULL as sys.DATETIME) as last_commit_time
  ,CAST(0 as sys.BIGINT) as low_water_mark_for_ghosts
  ,CAST(0 as sys.BIGINT) as secondary_lag_seconds
WHERE FALSE;
GRANT SELECT ON sys.dm_hadr_database_replica_states TO PUBLIC;

CREATE OR REPLACE VIEW sys.data_spaces
AS
SELECT
  CAST('PRIMARY' as SYSNAME) AS name,
  CAST(1 as INT) AS data_space_id,
  CAST('FG' as CHAR(2)) AS type,
  CAST('ROWS_FILEGROUP' as NVARCHAR(60)) AS type_desc,
  CAST(1 as sys.BIT) AS is_default,
  CAST(0 as sys.BIT) AS is_system;
GRANT SELECT ON sys.data_spaces TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_mirroring
AS
SELECT
  CAST(database_id AS int) AS database_id,
 CAST(NULL AS sys.uniqueidentifier) AS mirroring_guid,
 CAST(NULL AS sys.tinyint) AS mirroring_state,
 CAST(NULL AS sys.nvarchar(60)) AS mirroring_state_desc,
 CAST(NULL AS sys.tinyint) AS mirroring_role,
 CAST(NULL AS sys.nvarchar(60)) AS mirroring_role_desc,
 CAST(NULL AS int) AS mirroring_role_sequence,
 CAST(NULL AS sys.tinyint) as mirroring_safety_level,
 CAST(NULL AS sys.nvarchar(60)) AS mirroring_safety_level_desc,
 CAST(NULL AS int) as mirroring_safety_sequence,
 CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_name,
 CAST(NULL AS sys.nvarchar(128)) AS mirroring_partner_instance,
 CAST(NULL AS sys.nvarchar(128)) AS mirroring_witness_name,
 CAST(NULL AS sys.tinyint) AS mirroring_witness_state,
 CAST(NULL AS sys.nvarchar(60)) AS mirroring_witness_state_desc,
 CAST(NULL AS numeric(25,0)) AS mirroring_failover_lsn,
 CAST(NULL AS int) AS mirroring_connection_timeout,
 CAST(NULL AS int) AS mirroring_redo_queue,
 CAST(NULL AS sys.nvarchar(60)) AS mirroring_redo_queue_type,
 CAST(NULL AS numeric(25,0)) AS mirroring_end_of_log_lsn,
 CAST(NULL AS numeric(25,0)) AS mirroring_replication_lsn
FROM sys.databases;
GRANT SELECT ON sys.database_mirroring TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_files
AS
SELECT
    CAST(1 as INT) AS file_id,
    CAST(NULL as sys.uniqueidentifier) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as sys.NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as sys.SYSNAME) AS name,
    CAST('' as sys.NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as sys.NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as sys.uniqueidentifier) AS differential_base_guid,
    CAST(NULL as sys.datetime) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as sys.uniqueidentifier) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn
WHERE false;
GRANT SELECT ON sys.database_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.hash_indexes
AS
SELECT
  si.object_id,
  si.name,
  si.index_id,
  si.type,
  si.type_desc,
  si.is_unique,
  si.data_space_id,
  si.ignore_dup_key,
  si.is_primary_key,
  si.is_unique_constraint,
  si.fill_factor,
  si.is_padded,
  si.is_disabled,
  si.is_hypothetical,
  si.allow_row_locks,
  si.allow_page_locks,
  si.has_filter,
  si.filter_definition,
  CAST(0 as INT) AS bucket_count,
  si.auto_created
FROM sys.indexes si
WHERE FALSE;
GRANT SELECT ON sys.hash_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetable_system_defined_objects
AS
SELECT
  CAST(0 as INT) AS object_id,
  CAST(0 as INT) AS parent_object_id
  WHERE FALSE;
GRANT SELECT ON sys.filetable_system_defined_objects TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_filestream_options
AS
SELECT
  CAST(0 as INT) AS database_id,
  CAST('' as NVARCHAR(255)) AS directory_name,
  CAST(0 as TINYINT) AS non_transacted_access,
  CAST('' as NVARCHAR(60)) AS non_transacted_access_desc
WHERE FALSE;
GRANT SELECT ON sys.database_filestream_options TO PUBLIC;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT) AS index_id
  , CAST(idx.type AS sys.tinyint) AS type
  , CAST(idx.type_desc AS sys.nvarchar(60)) AS type_desc
  , CAST(idx.is_unique AS sys.bit) AS is_unique
  , CAST(idx.data_space_id AS int) AS data_space_id
  , CAST(idx.ignore_dup_key AS sys.bit) AS ignore_dup_key
  , CAST(idx.is_primary_key AS sys.bit) AS is_primary_key
  , CAST(idx.is_unique_constraint AS sys.bit) AS is_unique_constraint
  , CAST(idx.fill_factor AS sys.tinyint) AS fill_factor
  , CAST(idx.is_padded AS sys.bit) AS is_padded
  , CAST(idx.is_disabled AS sys.bit) AS is_disabled
  , CAST(idx.is_hypothetical AS sys.bit) AS is_hypothetical
  , CAST(idx.allow_row_locks AS sys.bit) AS allow_row_locks
  , CAST(idx.allow_page_locks AS sys.bit) AS allow_page_locks
  , CAST(idx.has_filter AS sys.bit) AS has_filter
  , CAST(idx.filter_definition AS sys.nvarchar(4000)) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS char(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_hadr_cluster
AS
SELECT
   CAST('' as sys.nvarchar(128)) as cluster_name
  ,CAST(0 as sys.tinyint) as quorum_type
  ,CAST('NODE_MAJORITY' as sys.nvarchar(50)) as quorum_type_desc
  ,CAST(0 as sys.tinyint) as quorum_state
  ,CAST('NORMAL_QUORUM' as sys.nvarchar(50)) as quorum_state_desc;
GRANT SELECT ON sys.dm_hadr_cluster TO PUBLIC;

CREATE OR REPLACE VIEW sys.assembly_modules
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS assembly_id,
   CAST('' AS SYSNAME) AS assembly_class,
   CAST('' AS SYSNAME) AS assembly_method,
   CAST(0 AS sys.BIT) AS null_on_null_input,
   CAST(0 as INT) AS execute_as_principal_id
   WHERE FALSE;
GRANT SELECT ON sys.assembly_modules TO PUBLIC;

CREATE OR REPLACE VIEW sys.change_tracking_databases
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(0 as sys.BIT) AS is_auto_cleanup_on,
   CAST(0 as INT) AS retention_period,
   CAST('' as NVARCHAR(60)) AS retention_period_units_desc,
   CAST(0 as TINYINT) AS retention_period_units
WHERE FALSE;
GRANT SELECT ON sys.change_tracking_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.database_recovery_status
AS
SELECT
   CAST(0 as INT) AS database_id,
   CAST(NULL as UNIQUEIDENTIFIER) AS database_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS family_guid,
   CAST(0 as NUMERIC(25,0)) AS last_log_backup_lsn,
   CAST(NULL as UNIQUEIDENTIFIER) AS recovery_fork_guid,
   CAST(NULL as UNIQUEIDENTIFIER) AS first_recovery_fork_guid,
   CAST(0 as NUMERIC(25,0)) AS fork_point_lsn
WHERE FALSE;
GRANT SELECT ON sys.database_recovery_status TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_languages
AS
SELECT
   CAST(0 as INT) AS lcid,
   CAST('' as SYSNAME) AS name
WHERE FALSE;
GRANT SELECT ON sys.fulltext_languages TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_index_columns
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS column_id,
   CAST(0 as INT) AS type_column_id,
   CAST(0 as INT) AS language_id,
   CAST(0 as INT) AS statistical_semantics
WHERE FALSE;
GRANT SELECT ON sys.fulltext_index_columns TO PUBLIC;

CREATE OR REPLACE VIEW sys.selective_xml_index_paths
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS index_id,
   CAST(0 as INT) AS path_id,
   CAST('' as NVARCHAR(4000)) AS path,
   CAST('' as SYSNAME) AS name,
   CAST(0 as TINYINT) AS path_type,
   CAST(0 as SYSNAME) AS path_type_desc,
   CAST(0 as INT) AS xml_component_id,
   CAST('' as NVARCHAR(4000)) AS xquery_type_description,
   CAST(0 as sys.BIT) AS is_xquery_type_inferred,
   CAST(0 as SMALLINT) AS xquery_max_length,
   CAST(0 as sys.BIT) AS is_xquery_max_length_inferred,
   CAST(0 as sys.BIT) AS is_node,
   CAST(0 as TINYINT) AS system_type_id,
   CAST(0 as TINYINT) AS user_type_id,
   CAST(0 as SMALLINT) AS max_length,
   CAST(0 as TINYINT) AS precision,
   CAST(0 as TINYINT) AS scale,
   CAST('' as SYSNAME) AS collation_name,
   CAST(0 as sys.BIT) AS is_singleton
WHERE FALSE;
GRANT SELECT ON sys.selective_xml_index_paths TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_indexes
AS
SELECT
   object_id,
   name,
   index_id,
   type,
   type_desc,
   is_unique,
   data_space_id,
   ignore_dup_key,
   is_primary_key,
   is_unique_constraint,
   fill_factor,
   is_padded,
   is_disabled,
   is_hypothetical,
   allow_row_locks,
   allow_page_locks,
   CAST(1 as TINYINT) AS spatial_index_type,
   CAST('' as NVARCHAR(60)) AS spatial_index_type_desc,
   CAST('' as SYSNAME) AS tessellation_scheme,
   has_filter,
   filter_definition,
   auto_created
FROM sys.indexes WHERE FALSE;
GRANT SELECT ON sys.spatial_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.filetables
AS
SELECT
   CAST(0 AS INT) AS object_id,
   CAST(0 AS sys.BIT) AS is_enabled,
   CAST('' AS sys.VARCHAR(255)) AS directory_name,
   CAST(0 AS INT) AS filename_collation_id,
   CAST('' AS sys.VARCHAR) AS filename_collation_name
   WHERE FALSE;
GRANT SELECT ON sys.filetables TO PUBLIC;

CREATE OR REPLACE VIEW sys.registered_search_property_lists
AS
SELECT
   CAST(0 AS INT) AS property_list_id,
   CAST('' AS SYSNAME) AS name,
   CAST(NULL AS DATETIME) AS create_date,
   CAST(NULL AS DATETIME) AS modify_date,
   CAST(0 AS INT) AS principal_id
WHERE FALSE;
GRANT SELECT ON sys.registered_search_property_lists TO PUBLIC;

CREATE OR REPLACE VIEW sys.filegroups
AS
SELECT
   CAST(ds.name AS sys.SYSNAME),
   CAST(ds.data_space_id AS INT),
   CAST(ds.type AS sys.BPCHAR(2)) COLLATE sys.database_default,
   CAST(ds.type_desc AS sys.NVARCHAR(60)),
   CAST(ds.is_default AS sys.BIT),
   CAST(ds.is_system AS sys.BIT),
   CAST(NULL as sys.UNIQUEIDENTIFIER) AS filegroup_guid,
   CAST(0 as INT) AS log_filegroup_id,
   CAST(0 as sys.BIT) AS is_read_only,
   CAST(0 as sys.BIT) AS is_autogrow_all_files
FROM sys.data_spaces ds WHERE type = 'FG';
GRANT SELECT ON sys.filegroups TO PUBLIC;

CREATE OR REPLACE VIEW sys.master_files
AS
SELECT
    CAST(0 as INT) AS database_id,
    CAST(0 as INT) AS file_id,
    CAST(NULL as UNIQUEIDENTIFIER) AS file_guid,
    CAST(0 as sys.TINYINT) AS type,
    CAST('' as NVARCHAR(60)) AS type_desc,
    CAST(0 as INT) AS data_space_id,
    CAST('' as SYSNAME) AS name,
    CAST('' as NVARCHAR(260)) AS physical_name,
    CAST(0 as sys.TINYINT) AS state,
    CAST('' as NVARCHAR(60)) AS state_desc,
    CAST(0 as INT) AS size,
    CAST(0 as INT) AS max_size,
    CAST(0 as INT) AS growth,
    CAST(0 as sys.BIT) AS is_media_read_only,
    CAST(0 as sys.BIT) AS is_read_only,
    CAST(0 as sys.BIT) AS is_sparse,
    CAST(0 as sys.BIT) AS is_percent_growth,
    CAST(0 as sys.BIT) AS is_name_reserved,
    CAST(0 as NUMERIC(25,0)) AS create_lsn,
    CAST(0 as NUMERIC(25,0)) AS drop_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_only_lsn,
    CAST(0 as NUMERIC(25,0)) AS read_write_lsn,
    CAST(0 as NUMERIC(25,0)) AS differential_base_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS differential_base_guid,
    CAST(NULL as DATETIME) AS differential_base_time,
    CAST(0 as NUMERIC(25,0)) AS redo_start_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_start_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS redo_target_lsn,
    CAST(NULL as UNIQUEIDENTIFIER) AS redo_target_fork_guid,
    CAST(0 as NUMERIC(25,0)) AS backup_lsn,
    CAST(0 as INT) AS credential_id
WHERE FALSE;
GRANT SELECT ON sys.master_files TO PUBLIC;

CREATE OR REPLACE VIEW sys.stats
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST('' as SYSNAME) AS name,
   CAST(0 as INT) AS stats_id,
   CAST(0 as sys.BIT) AS auto_created,
   CAST(0 as sys.BIT) AS user_created,
   CAST(0 as sys.BIT) AS no_recompute,
   CAST(0 as sys.BIT) AS has_filter,
   CAST('' as sys.NVARCHAR(4000)) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;
GRANT SELECT ON sys.stats TO PUBLIC;


CREATE OR REPLACE VIEW sys.change_tracking_tables
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as sys.BIT) AS is_track_columns_updated_on,
   CAST(0 AS sys.BIGINT) AS begin_version,
   CAST(0 AS sys.BIGINT) AS cleanup_version,
   CAST(0 AS sys.BIGINT) AS min_valid_version
   WHERE FALSE;
GRANT SELECT ON sys.change_tracking_tables TO PUBLIC;


CREATE OR REPLACE VIEW sys.fulltext_catalogs
AS
SELECT
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST('' as SYSNAME) AS name,
   CAST('' as NVARCHAR(260)) AS path,
   CAST(0 as sys.BIT) AS is_default,
   CAST(0 as sys.BIT) AS is_accent_sensitivity_on,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS file_id,
   CAST(0 as INT) AS principal_id,
   CAST(2 as sys.BIT) AS is_importing
WHERE FALSE;
GRANT SELECT ON sys.fulltext_catalogs TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_stoplists
AS
SELECT
   CAST(0 as INT) AS stoplist_id,
   CAST('' as SYSNAME) AS name,
   CAST(NULL as DATETIME) AS create_date,
   CAST(NULL as DATETIME) AS modify_date,
   CAST(0 as INT) AS Principal_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_stoplists TO PUBLIC;

CREATE OR REPLACE VIEW sys.fulltext_indexes
AS
SELECT
   CAST(0 as INT) AS object_id,
   CAST(0 as INT) AS unique_index_id,
   CAST(0 as INT) AS fulltext_catalog_id,
   CAST(0 as sys.BIT) AS is_enabled,
   CAST('O' as sys.BPCHAR(1)) AS change_tracking_state,
   CAST('' as sys.NVARCHAR(60)) AS change_tracking_state_desc,
   CAST(0 as sys.BIT) AS has_crawl_completed,
   CAST('' as sys.BPCHAR(1)) AS crawl_type,
   CAST('' as sys.NVARCHAR(60)) AS crawl_type_desc,
   CAST(NULL as sys.DATETIME) AS crawl_start_date,
   CAST(NULL as sys.DATETIME) AS crawl_end_date,
   CAST(NULL as BINARY(8)) AS incremental_timestamp,
   CAST(0 as INT) AS stoplist_id,
   CAST(0 as INT) AS data_space_id,
   CAST(0 as INT) AS property_list_id
WHERE FALSE;
GRANT SELECT ON sys.fulltext_indexes TO PUBLIC;

CREATE OR REPLACE VIEW sys.synonyms
AS
SELECT
    CAST(obj.name as sys.sysname) AS name
  , CAST(obj.object_id as int) AS object_id
  , CAST(obj.principal_id as int) AS principal_id
  , CAST(obj.schema_id as int) AS schema_id
  , CAST(obj.parent_object_id as int) AS parent_object_id
  , CAST(obj.type as sys.bpchar(2)) AS type
  , CAST(obj.type_desc as sys.nvarchar(60)) AS type_desc
  , CAST(obj.create_date as sys.datetime) as create_date
  , CAST(obj.modify_date as sys.datetime) as modify_date
  , CAST(obj.is_ms_shipped as sys.bit) as is_ms_shipped
  , CAST(obj.is_published as sys.bit) as is_published
  , CAST(obj.is_schema_published as sys.bit) as is_schema_published
  , CAST('' as sys.nvarchar(1035)) AS base_object_name
FROM sys.objects obj
WHERE type='SN';
GRANT SELECT ON sys.synonyms TO PUBLIC;

CREATE OR REPLACE VIEW sys.plan_guides
AS
SELECT
    CAST(0 as int) AS plan_guide_id
  , CAST('' as sys.sysname) AS name
  , CAST(NULL as sys.datetime) as create_date
  , CAST(NULL as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_disabled
  , CAST('' as sys.nvarchar(4000)) AS query_text
  , CAST(0 as sys.tinyint) AS scope_type
  , CAST('' as sys.nvarchar(60)) AS scope_type_desc
  , CAST(0 as int) AS scope_type_id
  , CAST('' as sys.nvarchar(4000)) AS scope_batch
  , CAST('' as sys.nvarchar(4000)) AS parameters
  , CAST('' as sys.nvarchar(4000)) AS hints
WHERE FALSE;
GRANT SELECT ON sys.plan_guides TO PUBLIC;

CREATE OR REPLACE VIEW sys.spatial_index_tessellations
AS
SELECT
    CAST(0 as int) AS object_id
  , CAST(0 as int) AS index_id
  , CAST('' as sys.sysname) AS tessellation_scheme
  , CAST(0 as float(53)) AS bounding_box_xmin
  , CAST(0 as float(53)) AS bounding_box_ymin
  , CAST(0 as float(53)) AS bounding_box_xmax
  , CAST(0 as float(53)) AS bounding_box_ymax
  , CAST(0 as smallint) as level_1_grid
  , CAST('' as sys.nvarchar(60)) AS level_1_grid_desc
  , CAST(0 as smallint) as level_2_grid
  , CAST('' as sys.nvarchar(60)) AS level_2_grid_desc
  , CAST(0 as smallint) as level_3_grid
  , CAST('' as sys.nvarchar(60)) AS level_3_grid_desc
  , CAST(0 as smallint) as level_4_grid
  , CAST('' as sys.nvarchar(60)) AS level_4_grid_desc
  , CAST(0 as int) as cells_per_object
WHERE FALSE;
GRANT SELECT ON sys.spatial_index_tessellations TO PUBLIC;

CREATE OR REPLACE VIEW sys.all_parameters
AS
SELECT
    CAST(ss.p_oid AS INT) AS object_id
  , CAST(COALESCE(ss.proargnames[(ss.x).n], '') AS sys.SYSNAME) AS name
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 0 -- param_id = 0 for output of scalar function
        ELSE (ss.x).n
      END
    AS INT) AS parameter_id
  -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
  -- This is because the IDs of system type values generated by
  -- Babelfish installation will exceed the size of TINYINT
  , CAST(st.system_type_id AS INT) AS system_type_id
  , CAST(st.user_type_id AS INT) AS user_type_id
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN -1 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.max_length -- UDT case
        ELSE sys.tsql_type_max_length_helper(st.name, t.typlen, typmod, true, true)
      END
    AS smallint) AS max_length
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.precision -- UDT case
        ELSE sys.tsql_type_precision_helper(st.name, typmod)
      END
    AS sys.tinyint) AS precision
  , CAST(
      CASE
        WHEN st.is_table_type = 1 THEN 0 -- TVP case
        WHEN st.is_user_defined = 1 THEN st.scale
        ELSE sys.tsql_type_scale_helper(st.name, typmod,false)
      END
    AS sys.tinyint) AS scale
  , CAST(
      CASE
        WHEN is_out_scalar = 1 THEN 1 -- Output of a scalar function
        WHEN ss.proargmodes[(ss.x).n] in ('o', 'b', 't') THEN 1
        ELSE 0
      END
    AS sys.bit) AS is_output
  , CAST(0 AS sys.bit) AS is_cursor_ref
  , CAST(0 AS sys.bit) AS has_default_value
  , CAST(0 AS sys.bit) AS is_xml_document
  , CAST(NULL AS sys.sql_variant) AS default_value
  , CAST(0 AS int) AS xml_collection_id
  , CAST(0 AS sys.bit) AS is_readonly
  , CAST(1 AS sys.bit) AS is_nullable
  , CAST(NULL AS int) AS encryption_type
  , CAST(NULL AS sys.nvarchar(64)) AS encryption_type_desc
  , CAST(NULL AS sys.sysname) AS encryption_algorithm_name
  , CAST(NULL AS int) AS column_encryption_key_id
  , CAST(NULL AS sys.sysname) AS column_encryption_key_database_name
FROM pg_type t
  INNER JOIN sys.types st ON st.user_type_id = t.oid
  INNER JOIN
  (
    SELECT
      p.oid AS p_oid,
      p.proargnames,
      p.proargmodes,
      p.prokind,
      json_extract_path(CAST(p.probin as json), 'typmod_array') AS typmod_array,
      information_schema._pg_expandarray(
      COALESCE(p.proallargtypes,
        CASE
          WHEN p.prokind = 'f' THEN (CAST( p.proargtypes AS oid[]) || p.prorettype) -- Adds return type if not present on proallargtypes
          ELSE CAST(p.proargtypes AS oid[])
        END
      )) AS x
    FROM pg_proc p
    WHERE (
      p.pronamespace in (select schema_id from sys.schemas union all select oid from pg_namespace where nspname = 'sys')
      AND (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND p.probin like '{%typmod_array%}') -- Needs to have a typmod array in JSON format
  ) ss ON t.oid = (ss.x).x,
  COALESCE(pg_get_function_result(ss.p_oid), '') AS return_type,
  CAST(ss.typmod_array->>(ss.x).n-1 AS INT) AS typmod,
  CAST(
    CASE
      WHEN ss.prokind = 'f' AND ss.proargnames[(ss.x).n] IS NULL THEN 1 -- checks if param is output of scalar function
      ELSE 0
    END
  AS INT) AS is_out_scalar
WHERE ( -- If it's a Table function, we only want the inputs
      return_type NOT LIKE 'TABLE(%' OR
      (return_type LIKE 'TABLE(%' AND ss.proargmodes[(ss.x).n] = 'i'));
GRANT SELECT ON sys.all_parameters TO PUBLIC;

CREATE OR REPLACE VIEW sys.numbered_procedures
AS
SELECT
    CAST(0 as int) AS object_id
  , CAST(0 as smallint) AS procedure_number
  , CAST('' as sys.nvarchar(4000)) AS definition
WHERE FALSE; -- This condition will ensure that the view is empty
GRANT SELECT ON sys.numbered_procedures TO PUBLIC;

-- BABEL-3325: Revisit once DDL and/or CREATE EVENT NOTIFICATION is supported
CREATE OR REPLACE VIEW sys.events
AS
SELECT
  CAST(pt.tgfoid as int) AS object_id
  , CAST(
      CASE
        WHEN tr.event_manipulation='INSERT' COLLATE sys.database_default THEN 1
        WHEN tr.event_manipulation='UPDATE' COLLATE sys.database_default THEN 2
        WHEN tr.event_manipulation='DELETE' COLLATE sys.database_default THEN 3
        ELSE 1
      END as int
  ) AS type
  , CAST(tr.event_manipulation as sys.nvarchar(60)) AS type_desc
  , CAST(1 as sys.bit) AS is_trigger_event
  , CAST(null as int) AS event_group_type
  , CAST(null as sys.nvarchar(60)) AS event_group_type_desc
FROM information_schema.triggers tr
JOIN pg_catalog.pg_namespace np ON tr.event_object_schema = np.nspname COLLATE sys.database_default
JOIN pg_class pc ON pc.relname = tr.event_object_table COLLATE sys.database_default AND pc.relnamespace = np.oid
JOIN pg_trigger pt ON pt.tgrelid = pc.oid AND tr.trigger_name = pt.tgname COLLATE sys.database_default
AND has_schema_privilege(pc.relnamespace, 'USAGE')
AND has_table_privilege(pc.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.events TO PUBLIC;

CREATE OR REPLACE VIEW sys.trigger_events
AS
SELECT
  CAST(e.object_id as int) AS object_id,
  CAST(e.type as int) AS type,
  CAST(e.type_desc as sys.nvarchar(60)) AS type_desc,
  CAST(0 as sys.bit) AS is_first,
  CAST(0 as sys.bit) AS is_last,
  CAST(null as int) AS event_group_type,
  CAST(null as sys.nvarchar(60)) AS event_group_type_desc,
  CAST(e.is_trigger_event as sys.bit) AS is_trigger_event
FROM sys.events e
WHERE e.is_trigger_event = 1;
GRANT SELECT ON sys.trigger_events TO PUBLIC;
-- 20 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/information_schema_tsql.sql" 1
-- 15 "sql/information_schema_tsql.sql"
CREATE SCHEMA information_schema_tsql;
GRANT USAGE ON SCHEMA information_schema_tsql TO PUBLIC;
SET search_path TO information_schema_tsql;






CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypid(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS oid
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypid ELSE tp.typbasetype END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_truetypmod(nt pg_namespace, at pg_attribute, tp pg_type) RETURNS int4
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT CASE WHEN nt.nspname = 'pg_catalog' OR nt.nspname = 'sys' THEN at.atttypmod ELSE tp.typtypmod END$$;

-- these functions encapsulate knowledge about the encoding of typmod:

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length(type text, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT
 CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
  THEN CASE WHEN typmod = -1
   THEN -1
   ELSE typmod - 4
   END
  WHEN type IN ('text', 'image')
  THEN 2147483647
  WHEN type = 'ntext'
  THEN 1073741823
  WHEN type = 'sysname'
  THEN 128
  WHEN type = 'xml'
  THEN -1
  WHEN type = 'sql_variant'
  THEN 0
  ELSE null
 END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length(type text, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT
 CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
  THEN CASE WHEN typmod = -1
   THEN -1
   ELSE typmod - 4
   END
  WHEN type IN ('nchar', 'nvarchar')
  THEN CASE WHEN typmod = -1
   THEN -1
   ELSE (typmod - 4) * 2
   END
  WHEN type IN ('text', 'image')
  THEN 2147483647
  WHEN type = 'ntext'
  THEN 2147483646
  WHEN type = 'sysname'
  THEN 256
  WHEN type = 'sql_variant'
  THEN 0
  WHEN type = 'xml'
  THEN -1
    ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_max_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'nchar', 'varchar', 'nvarchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647
                WHEN type = 'ntext'
                THEN 1073741823
                WHEN type = 'sysname'
                THEN 128
                WHEN type = 'xml'
                THEN -1
                WHEN type = 'sql_variant'
                THEN 0
                ELSE null
        END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_char_octet_length_for_routines(type text, typmod int4) RETURNS integer
        LANGUAGE sql
        IMMUTABLE
        PARALLEL SAFE
        RETURNS NULL ON NULL INPUT
        AS
$$SELECT
        CASE WHEN type IN ('char', 'varchar', 'binary', 'varbinary')
                THEN CASE WHEN typmod = -1
                        THEN 1
                        ELSE typmod - 4
                        END
                WHEN type IN ('nchar', 'nvarchar')
                THEN CASE WHEN typmod = -1
                        THEN 2
                        ELSE (typmod - 4) * 2
                        END
                WHEN type IN ('text', 'image')
                THEN 2147483647
                WHEN type = 'ntext'
                THEN 2147483646
                WHEN type = 'sysname'
                THEN 256
                WHEN type = 'sql_variant'
                THEN 0
                WHEN type = 'xml'
                THEN -1
           ELSE null
  END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision(type text, typid oid, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$
 SELECT
 CASE typid
  WHEN 21 THEN 5
  WHEN 23 THEN 10
  WHEN 20 THEN 19
  WHEN 1700 THEN
   CASE WHEN typmod = -1 THEN null
    ELSE ((typmod - 4) >> 16) & 65535
   END
  WHEN 700 THEN 24
  WHEN 701 THEN 53
  ELSE
   CASE WHEN type = 'tinyint' THEN 3
    WHEN type = 'money' THEN 19
    WHEN type = 'smallmoney' THEN 10
    WHEN type = 'decimal' THEN
     CASE WHEN typmod = -1 THEN null
      ELSE ((typmod - 4) >> 16) & 65535
     END
    ELSE null
   END
 END
$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_precision_radix(type text, typid oid, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT
 CASE WHEN typid IN (700, 701) THEN 2
  WHEN typid IN (20, 21, 23, 1700) THEN 10
  WHEN type IN ('tinyint', 'money', 'smallmoney') THEN 10
  ELSE null
 END$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_numeric_scale(type text, typid oid, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$
 SELECT
 CASE WHEN typid IN (21, 23, 20) THEN 0
  WHEN typid IN (1700) THEN
   CASE WHEN typmod = -1 THEN null
    ELSE (typmod - 4) & 65535
   END
  WHEN type = 'tinyint' THEN 0
  WHEN type IN ('money', 'smallmoney') THEN 4
  WHEN type = 'decimal' THEN
   CASE WHEN typmod = -1 THEN NULL
    ELSE (typmod - 4) & 65535
   END
  ELSE null
 END
$$;

CREATE OR REPLACE FUNCTION information_schema_tsql._pgtsql_datetime_precision(type text, typmod int4) RETURNS integer
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
 RETURNS NULL ON NULL INPUT
 AS
$$SELECT
  CASE WHEN type = 'date'
     THEN 0
  WHEN type = 'datetime'
  THEN 3
   WHEN type IN ('time', 'datetime2', 'smalldatetime', 'datetimeoffset')
   THEN CASE WHEN typmod < 0 THEN 6 ELSE typmod END
   ELSE null
  END$$;






CREATE OR REPLACE VIEW information_schema_tsql.columns AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
   CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
   CAST(a.attname AS sys.nvarchar(128)) AS "COLUMN_NAME",
   CAST(a.attnum AS int) AS "ORDINAL_POSITION",
   CAST(CASE WHEN a.attgenerated = '' THEN pg_get_expr(ad.adbin, ad.adrelid) END AS sys.nvarchar(4000)) AS "COLUMN_DEFAULT",
   CAST(CASE WHEN a.attnotnull OR (t.typtype = 'd' AND t.typnotnull) THEN 'NO' ELSE 'YES' END
    AS varchar(3))
    AS "IS_NULLABLE",

   CAST(
    CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype)
    ELSE tsql_type_name END
    AS sys.nvarchar(128))
    AS "DATA_TYPE",

   CAST(
    information_schema_tsql._pgtsql_char_max_length(tsql_type_name, true_typmod)
    AS int)
    AS "CHARACTER_MAXIMUM_LENGTH",

   CAST(
    information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, true_typmod)
    AS int)
    AS "CHARACTER_OCTET_LENGTH",

   CAST(

    information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, true_typid, true_typmod)
    AS sys.tinyint)
    AS "NUMERIC_PRECISION",

   CAST(
    information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, true_typid, true_typmod)
    AS smallint)
    AS "NUMERIC_PRECISION_RADIX",

   CAST(
    information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, true_typid, true_typmod)
    AS int)
    AS "NUMERIC_SCALE",

   CAST(
    information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
    AS smallint)
    AS "DATETIME_PRECISION",

   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",




   CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

   CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
   CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",


   CAST(co.collname AS sys.nvarchar(128)) AS "COLLATION_NAME",

   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN nc.dbname ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN ext.orig_name ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
   CAST(CASE WHEN t.typtype = 'd' AND nt.nspname <> 'pg_catalog' AND nt.nspname <> 'sys'
    THEN t.typname ELSE null END
    AS sys.nvarchar(128)) AS "DOMAIN_NAME"

 FROM (pg_attribute a LEFT JOIN pg_attrdef ad ON attrelid = adrelid AND attnum = adnum)
  JOIN (pg_class c JOIN sys.pg_namespace_ext nc ON (c.relnamespace = nc.oid)) ON a.attrelid = c.oid
  JOIN (pg_type t JOIN pg_namespace nt ON (t.typnamespace = nt.oid)) ON a.atttypid = t.oid
  LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON (bt.typnamespace = nbt.oid))
   ON (t.typtype = 'd' AND t.typbasetype = bt.oid)
  LEFT JOIN pg_collation co on co.oid = a.attcollation
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
  information_schema_tsql._pgtsql_truetypid(nt, a, t) AS true_typid,
  information_schema_tsql._pgtsql_truetypmod(nt, a, t) AS true_typmod,
  sys.translate_pg_type_to_tsql(true_typid) AS tsql_type_name

 WHERE (NOT pg_is_other_temp_schema(nc.oid))
  AND a.attnum > 0 AND NOT a.attisdropped
  AND c.relkind IN ('r', 'v', 'p')
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_column_privilege(c.oid, a.attnum,
         'SELECT, INSERT, UPDATE, REFERENCES'))
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.columns TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.domains AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "DOMAIN_CATALOG",
  CAST(ext.orig_name AS sys.nvarchar(128)) AS "DOMAIN_SCHEMA",
  CAST(t.typname AS sys.sysname) AS "DOMAIN_NAME",
  CAST(case when is_tbl_type THEN 'table type' ELSE tsql_type_name END AS sys.sysname) AS "DATA_TYPE",

  CAST(information_schema_tsql._pgtsql_char_max_length(tsql_type_name, t.typtypmod)
   AS int)
  AS "CHARACTER_MAXIMUM_LENGTH",

  CAST(information_schema_tsql._pgtsql_char_octet_length(tsql_type_name, t.typtypmod)
   AS int)
  AS "CHARACTER_OCTET_LENGTH",

  CAST(NULL as sys.nvarchar(128)) AS "COLLATION_CATALOG",
  CAST(NULL as sys.nvarchar(128)) AS "COLLATION_SCHEMA",


  CAST(
   CASE co.collname
    WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
    ELSE co.collname
   END
  AS sys.nvarchar(128)) AS "COLLATION_NAME",

  CAST(null AS sys.varchar(6)) AS "CHARACTER_SET_CATALOG",
  CAST(null AS sys.varchar(3)) AS "CHARACTER_SET_SCHEMA",




  CAST(null AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",

  CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.typbasetype, t.typtypmod)
   AS sys.tinyint)
  AS "NUMERIC_PRECISION",

  CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, t.typbasetype, t.typtypmod)
   AS smallint)
  AS "NUMERIC_PRECISION_RADIX",

  CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.typbasetype, t.typtypmod)
   AS int)
  AS "NUMERIC_SCALE",

  CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, t.typtypmod)
   AS smallint)
  AS "DATETIME_PRECISION",

  CAST(case when is_tbl_type THEN NULL ELSE t.typdefault END AS sys.nvarchar(4000)) AS "DOMAIN_DEFAULT"

  FROM (pg_type t JOIN sys.pg_namespace_ext nc ON t.typnamespace = nc.oid)
  LEFT JOIN pg_collation co ON t.typcollation = co.oid
  LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname,
  sys.translate_pg_type_to_tsql(t.typbasetype) AS tsql_type_name,
  sys.is_table_type(t.typrelid) as is_tbl_type

  WHERE (pg_has_role(t.typowner, 'USAGE')
   OR has_type_privilege(t.oid, 'USAGE'))
  AND (t.typtype = 'd' OR is_tbl_type)
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.domains TO PUBLIC;





CREATE VIEW information_schema_tsql.tables AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
     CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
     CAST(
    CASE WHEN c.reloptions[1] LIKE 'bbf_original_rel_name%' THEN substring(c.reloptions[1], 23)
                  ELSE c.relname END
    AS sys._ci_sysname) AS "TABLE_NAME",

     CAST(
    CASE WHEN c.relkind IN ('r', 'p') THEN 'BASE TABLE'
      WHEN c.relkind = 'v' THEN 'VIEW'
      ELSE null END
    AS varchar(10)) AS "TABLE_TYPE"

 FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname

 WHERE c.relkind IN ('r', 'v', 'p')
  AND (NOT pg_is_other_temp_schema(nc.oid))
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
   OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;





CREATE VIEW information_schema_tsql.table_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
           CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
           CAST(nr.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
           CAST(extr.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
           CAST(r.relname AS sys.sysname) AS "TABLE_NAME",
           CAST(
             CASE c.contype WHEN 'c' THEN 'CHECK'
                            WHEN 'f' THEN 'FOREIGN KEY'
                            WHEN 'p' THEN 'PRIMARY KEY'
                            WHEN 'u' THEN 'UNIQUE' END
             AS sys.varchar(11)) COLLATE sys.database_default AS "CONSTRAINT_TYPE",
           CAST('NO' AS sys.varchar(2)) AS "IS_DEFERRABLE",
           CAST('NO' AS sys.varchar(2)) AS "INITIALLY_DEFERRED"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nr.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype NOT IN ('t', 'x')
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nr.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
    AND extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.table_constraints TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.views AS
 SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "TABLE_CATALOG",
   CAST(ext.orig_name AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
   CAST(c.relname AS sys.nvarchar(128)) AS "TABLE_NAME",
   CAST(vd.definition AS sys.nvarchar(4000)) AS "VIEW_DEFINITION",

   CAST(
    CASE WHEN 'check_option=cascaded' = ANY (c.reloptions)
     THEN 'CASCADE'
     ELSE 'NONE' END
    AS sys.varchar(7)) COLLATE sys.database_default AS "CHECK_OPTION",

   CAST('NO' AS sys.varchar(2)) AS "IS_UPDATABLE"

 FROM sys.pg_namespace_ext nc JOIN pg_class c ON (nc.oid = c.relnamespace)
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext
   ON (nc.nspname = ext.nspname COLLATE sys.database_default)
  LEFT OUTER JOIN sys.babelfish_view_def vd
   ON ext.dbid = vd.dbid
    AND (ext.orig_name = vd.schema_name COLLATE sys.database_default)
    AND (CAST(c.relname AS sys.nvarchar(128)) = vd.object_name COLLATE sys.database_default)

 WHERE c.relkind = 'v'
  AND (NOT pg_is_other_temp_schema(nc.oid))
  AND (pg_has_role(c.relowner, 'USAGE')
   OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
   OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') )
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.views TO PUBLIC;





CREATE VIEW information_schema_tsql.check_constraints AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
     CAST(extc.orig_name AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
           CAST(c.conname AS sys.sysname) AS "CONSTRAINT_NAME",
     CAST(sys.tsql_get_constraintdef(c.oid) AS sys.nvarchar(4000)) AS "CHECK_CLAUSE"

    FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
         pg_constraint c,
         pg_class r

    WHERE nc.oid = c.connamespace AND nc.oid = r.relnamespace
          AND c.conrelid = r.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND (NOT pg_is_other_temp_schema(nc.oid))
          AND (pg_has_role(r.relowner, 'USAGE')
               OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
               OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))
    AND extc.dbid = cast(sys.db_id() as oid);

GRANT SELECT ON information_schema_tsql.check_constraints TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.CONSTRAINT_COLUMN_USAGE AS
SELECT CAST(tblcat AS sys.nvarchar(128)) AS "TABLE_CATALOG",
          CAST(tblschema AS sys.nvarchar(128)) AS "TABLE_SCHEMA",
          CAST(tblname AS sys.nvarchar(128)) AS "TABLE_NAME" ,
          CAST(colname AS sys.nvarchar(128)) AS "COLUMN_NAME",
          CAST(cstrcat AS sys.nvarchar(128)) AS "CONSTRAINT_CATALOG",
          CAST(cstrschema AS sys.nvarchar(128)) AS "CONSTRAINT_SCHEMA",
          CAST(cstrname AS sys.nvarchar(128)) AS "CONSTRAINT_NAME"

FROM (

   SELECT DISTINCT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r, pg_depend d

     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND d.refclassid = 'pg_catalog.pg_class'::regclass
          AND d.refobjid = r.oid
          AND d.refobjsubid = a.attnum
          AND d.classid = 'pg_catalog.pg_constraint'::regclass
          AND d.objid = c.oid
          AND c.connamespace = nc.oid
          AND c.contype = 'c'
          AND r.relkind IN ('r', 'p')
          AND NOT a.attisdropped
   AND (pg_has_role(r.relowner, 'USAGE')
  OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
  OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

       UNION ALL


   SELECT extr.orig_name, r.relname, r.relowner, a.attname, extc.orig_name, c.conname, nr.dbname, nc.dbname
     FROM sys.pg_namespace_ext nc LEFT OUTER JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
          sys.pg_namespace_ext nr LEFT OUTER JOIN sys.babelfish_namespace_ext extr ON nr.nspname = extr.nspname,
          pg_attribute a,
          pg_constraint c,
          pg_class r
     WHERE nr.oid = r.relnamespace
          AND r.oid = a.attrelid
          AND nc.oid = c.connamespace
          AND r.oid = c.conrelid
          AND a.attnum = ANY (c.conkey)
          AND NOT a.attisdropped
          AND c.contype IN ('p', 'u', 'f')
          AND r.relkind IN ('r', 'p')
   AND (pg_has_role(r.relowner, 'USAGE')
  OR has_table_privilege(r.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER')
  OR has_any_column_privilege(r.oid, 'SELECT, INSERT, UPDATE, REFERENCES'))

      ) AS x (tblschema, tblname, tblowner, colname, cstrschema, cstrname, tblcat, cstrcat);

GRANT SELECT ON information_schema_tsql.CONSTRAINT_COLUMN_USAGE TO PUBLIC;





CREATE OR REPLACE VIEW information_schema_tsql.COLUMN_DOMAIN_USAGE AS
    SELECT isc_col."DOMAIN_CATALOG",
           isc_col."DOMAIN_SCHEMA" ,
           CAST(isc_col."DOMAIN_NAME" AS sys.sysname),
           isc_col."TABLE_CATALOG",
           isc_col."TABLE_SCHEMA",
           CAST(isc_col."TABLE_NAME" AS sys.sysname),
           CAST(isc_col."COLUMN_NAME" AS sys.sysname)

    FROM information_schema_tsql.columns AS isc_col
    WHERE isc_col."DOMAIN_NAME" IS NOT NULL;

GRANT SELECT ON information_schema_tsql.COLUMN_DOMAIN_USAGE TO PUBLIC;




CREATE OR REPLACE VIEW information_schema_tsql.routines AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SPECIFIC_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "SPECIFIC_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "SPECIFIC_NAME",
           CAST(nc.dbname AS sys.nvarchar(128)) AS "ROUTINE_CATALOG",
           CAST(ext.orig_name AS sys.nvarchar(128)) AS "ROUTINE_SCHEMA",
           CAST(p.proname AS sys.nvarchar(128)) AS "ROUTINE_NAME",
           CAST(CASE p.prokind WHEN 'f' THEN 'FUNCTION' WHEN 'p' THEN 'PROCEDURE' END
             AS sys.nvarchar(20)) AS "ROUTINE_TYPE",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "MODULE_NAME",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_SCHEMA",
           CAST(NULL AS sys.nvarchar(128)) AS "UDT_NAME",
    CAST(case when is_tbl_type THEN 'table' when p.prokind = 'p' THEN NULL ELSE tsql_type_name END AS sys.nvarchar(128)) AS "DATA_TYPE",
           CAST(information_schema_tsql._pgtsql_char_max_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_MAXIMUM_LENGTH",
           CAST(information_schema_tsql._pgtsql_char_octet_length_for_routines(tsql_type_name, true_typmod)
                 AS int)
           AS "CHARACTER_OCTET_LENGTH",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_CATALOG",
           CAST(NULL AS sys.nvarchar(128)) AS "COLLATION_SCHEMA",
           CAST(
                 CASE co.collname
                       WHEN 'default' THEN current_setting('babelfishpg_tsql.server_collation_name')
                       ELSE co.collname
                 END
            AS sys.nvarchar(128)) AS "COLLATION_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "CHARACTER_SET_SCHEMA",




     CAST(case when tsql_type_name IN ('nchar','nvarchar') THEN 'UNICODE' when tsql_type_name IN ('char','varchar') THEN 'iso_1' ELSE NULL END AS sys.nvarchar(128)) AS "CHARACTER_SET_NAME",
     CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION",
     CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, true_typmod)
                        AS smallint)
            AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, true_typmod)
                        AS smallint)
            AS "NUMERIC_SCALE",
            CAST(information_schema_tsql._pgtsql_datetime_precision(tsql_type_name, true_typmod)
                        AS smallint)
            AS "DATETIME_PRECISION",
     CAST(NULL AS sys.nvarchar(30)) AS "INTERVAL_TYPE",
            CAST(NULL AS smallint) AS "INTERVAL_PRECISION",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "TYPE_UDT_NAME",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_CATALOG",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_SCHEMA",
            CAST(NULL AS sys.nvarchar(128)) AS "SCOPE_NAME",
            CAST(NULL AS bigint) AS "MAXIMUM_CARDINALITY",
            CAST(NULL AS sys.nvarchar(128)) AS "DTD_IDENTIFIER",
            CAST(CASE WHEN l.lanname = 'sql' THEN 'SQL' WHEN l.lanname = 'pltsql' THEN 'SQL' ELSE 'EXTERNAL' END AS sys.nvarchar(30)) AS "ROUTINE_BODY",
            CAST(sys.tsql_get_functiondef(p.oid) AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
            CAST(NULL AS sys.nvarchar(128)) AS "EXTERNAL_NAME",
            CAST(NULL AS sys.nvarchar(30)) AS "EXTERNAL_LANGUAGE",
            CAST(NULL AS sys.nvarchar(30)) AS "PARAMETER_STYLE",
            CAST(CASE WHEN p.provolatile = 'i' THEN 'YES' ELSE 'NO' END AS sys.nvarchar(10)) AS "IS_DETERMINISTIC",
     CAST(CASE p.prokind WHEN 'p' THEN 'MODIFIES' ELSE 'READS' END AS sys.nvarchar(30)) AS "SQL_DATA_ACCESS",
            CAST(CASE WHEN p.prokind <> 'p' THEN
              CASE WHEN p.proisstrict THEN 'YES' ELSE 'NO' END END AS sys.nvarchar(10)) AS "IS_NULL_CALL",
            CAST(NULL AS sys.nvarchar(128)) AS "SQL_PATH",
            CAST('YES' AS sys.nvarchar(10)) AS "SCHEMA_LEVEL_ROUTINE",
            CAST(CASE p.prokind WHEN 'f' THEN 0 WHEN 'p' THEN -1 END AS smallint) AS "MAX_DYNAMIC_RESULT_SETS",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_USER_DEFINED_CAST",
            CAST('NO' AS sys.nvarchar(10)) AS "IS_IMPLICITLY_INVOCABLE",
            CAST(NULL AS sys.datetime) AS "CREATED",
            CAST(NULL AS sys.datetime) AS "LAST_ALTERED"

       FROM sys.pg_namespace_ext nc LEFT JOIN sys.babelfish_namespace_ext ext ON nc.nspname = ext.nspname,
            pg_proc p inner join sys.schemas sch on sch.schema_id = p.pronamespace
     inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT),
            pg_language l,
            pg_type t LEFT JOIN pg_collation co ON t.typcollation = co.oid,
            sys.translate_pg_type_to_tsql(t.oid) AS tsql_type_name,
            sys.tsql_get_returnTypmodValue(p.oid) AS true_typmod,
     sys.is_table_type(t.typrelid) as is_tbl_type

       WHERE
            (case p.prokind
        when 'p' then true
        when 'a' then false
               else
                (case format_type(p.prorettype, null)
           when 'trigger' then false
           else true
         end)
            end)
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND has_function_privilege(p.oid, 'EXECUTE')
            AND (pg_has_role(t.typowner, 'USAGE')
            OR has_type_privilege(t.oid, 'USAGE'))
            AND ext.dbid = cast(sys.db_id() as oid)
     AND p.prolang = l.oid
            AND p.prorettype = t.oid
            AND p.pronamespace = nc.oid
     AND CAST(ao.is_ms_shipped as INT) = 0;

GRANT SELECT ON information_schema_tsql.routines TO PUBLIC;

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);
-- 21 "sql/babelfishpg_tsql.in" 2
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

CREATE VIEW sys.babelfish_configurations_view as
    SELECT *
    FROM pg_catalog.pg_settings
    WHERE name collate "C" like 'babelfishpg_tsql.explain_%' OR
          name collate "C" like 'babelfishpg_tsql.escape_hatch_%' OR
          name collate "C" = 'babelfishpg_tsql.enable_pg_hint';
GRANT SELECT on sys.babelfish_configurations_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128), IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
AS $$
DECLARE
  normalized_name varchar(256);
  default_value text;
  value_type text;
  enum_value text[];
  cnt int;
  cur refcursor;
  guc_name varchar(256);
  server boolean := false;
  prev_user text;
BEGIN
  IF lower("@option_name") like 'babelfishpg_tsql.%' collate "C" THEN
    SELECT "@option_name" INTO normalized_name;
  ELSE
    SELECT concat('babelfishpg_tsql.',"@option_name") INTO normalized_name;
  END IF;

  IF lower("@option_scope") = 'server' THEN
    server := true;
  ELSIF btrim("@option_scope") != '' THEN
    RAISE EXCEPTION 'invalid option: %', "@option_scope";
  END IF;

  SELECT COUNT(*) INTO cnt FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  IF cnt = 0 THEN
    RAISE EXCEPTION 'unknown configuration: %', normalized_name;
  ELSIF cnt > 1 AND (lower("@option_value") != 'ignore' AND lower("@option_value") != 'strict'
                AND lower("@option_value") != 'default') THEN
    RAISE EXCEPTION 'unvalid option: %', lower("@option_value");
  END IF;

  OPEN cur FOR SELECT name FROM sys.babelfish_configurations_view where name collate "C" like normalized_name;
  LOOP
    FETCH NEXT FROM cur into guc_name;
    exit when not found;

    SELECT boot_val, vartype, enumvals INTO default_value, value_type, enum_value FROM pg_catalog.pg_settings WHERE name = guc_name;
    IF lower("@option_value") = 'default' THEN
        PERFORM pg_catalog.set_config(guc_name, default_value, 'false');
    ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
      IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
      ELSE
        CONTINUE;
      END IF;
    ELSE
        PERFORM pg_catalog.set_config(guc_name, "@option_value", 'false');
    END IF;
    IF server THEN
      SELECT current_user INTO prev_user;
      PERFORM sys.babelfish_set_role(session_user);
      IF lower("@option_value") = 'default' THEN
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, default_value);
      ELSIF lower("@option_value") = 'ignore' or lower("@option_value") = 'strict' THEN
        IF value_type = 'enum' AND enum_value = '{"strict", "ignore"}' THEN
          EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
        ELSE
          CONTINUE;
        END IF;
      ELSE
        -- store the setting in PG master database so that it can be applied to all bbf databases
        EXECUTE format('ALTER DATABASE %s SET %s = %s', CURRENT_DATABASE(), guc_name, "@option_value");
      END IF;
      PERFORM sys.babelfish_set_role(prev_user);
    END IF;
  END LOOP;

  CLOSE cur;

END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.sp_babelfish_configure(
 IN varchar(128), IN varchar(128), IN varchar(128)
) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addrole(IN "@rolename" sys.SYSNAME, IN "@ownername" sys.SYSNAME DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addrole' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_addrole(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_droprole(IN "@rolename" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_droprole' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_droprole(IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_addrolemember(IN "@rolename" sys.SYSNAME, IN "@membername" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_addrolemember' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_addrolemember(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_droprolemember(IN "@rolename" sys.SYSNAME, IN "@membername" sys.SYSNAME)
AS 'babelfishpg_tsql', 'sp_droprolemember' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_droprolemember(IN sys.SYSNAME, IN sys.SYSNAME) TO PUBLIC;
-- 22 "sql/babelfishpg_tsql.in" 2
-- 1 "sql/import_export_compatibility.sql" 1
-- sys.assemblies should be a view, but the underlying system catalogs haven't
-- been implemented in Babelfish yet (sys.sysclsobjs, etc)
CREATE TABLE sys.assemblies(
        name sys.sysname,
        principal_id int,
        assembly_id int,
  clr_name nvarchar(4000),
        permission_set tinyint,
        permission_set_desc nvarchar(60),
        is_visible bit,
        create_date datetime,
        modify_date datetime,
        is_user_defined bit
);
GRANT SELECT ON sys.assemblies TO PUBLIC;

CREATE OR REPLACE VIEW sys.assembly_types
AS
SELECT
   CAST(t.name as sys.sysname) AS name,
   -- 'system_type_id' is specified as type INT here, and not TINYINT per SQL Server documentation.
   -- This is because the IDs of generated SQL Server system type values generated by B
   -- Babelfish installation will exceed the size of TINYINT.
   CAST(t.system_type_id as int) AS system_type_id,
   CAST(t.user_type_id as int) AS user_type_id,
   CAST(t.schema_id as int) AS schema_id,
   CAST(t.principal_id as int) AS principal_id,
   CAST(t.max_length as smallint) AS max_length,
   CAST(t.precision as sys.tinyint) AS precision,
   CAST(t.scale as sys.tinyint) AS scale,
   CAST(t.collation_name as sys.sysname) AS collation_name,
   CAST(t.is_nullable as sys.bit) AS is_nullable,
   CAST(t.is_user_defined as sys.bit) AS is_user_defined,
   CAST(t.is_assembly_type as sys.bit) AS is_assembly_type,
   CAST(t.default_object_id as int) AS default_object_id,
   CAST(t.rule_object_id as int) AS rule_object_id,
   CAST(NULL as int) AS assembly_id,
   CAST(NULL as sys.sysname) AS assembly_class,
   CAST(NULL as sys.bit) AS is_binary_ordered,
   CAST(NULL as sys.bit) AS is_fixed_length,
   CAST(NULL as sys.nvarchar(40)) AS prog_id,
   CAST(NULL as sys.nvarchar(4000)) AS assembly_qualified_name,
   CAST(t.is_table_type as sys.bit) AS is_table_type
FROM sys.types t
WHERE t.is_assembly_type = 1;
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
-- 23 "sql/babelfishpg_tsql.in" 2
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

CREATE FUNCTION fulltextserviceproperty (TEXT)
 RETURNS sys.int AS 'babelfishpg_tsql', 'fulltextserviceproperty' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION COLUMNS_UPDATED ()
    RETURNS sys.VARBINARY AS 'babelfishpg_tsql', 'columnsupdated' LANGUAGE C;

CREATE OR REPLACE FUNCTION UPDATE (TEXT)
    RETURNS BOOLEAN AS 'babelfishpg_tsql', 'updated' LANGUAGE C;

CREATE OR REPLACE PROCEDURE xp_qv(IN nvarchar(256), IN nvarchar(256))
    AS 'babelfishpg_tsql', 'xp_qv_internal' LANGUAGE C;

CREATE PROCEDURE xp_instance_regread(IN p1 sys.nvarchar(512),
 IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param int)
AS 'babelfishpg_tsql', 'xp_instance_regread_internal'
LANGUAGE C;

CREATE PROCEDURE xp_instance_regread(IN p1 sys.nvarchar(512),
 IN p2 sys.sysname, IN p3 sys.nvarchar(512), INOUT out_param sys.nvarchar(512))
AS 'babelfishpg_tsql', 'xp_instance_regread_internal'
LANGUAGE C;

--
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
  FROM sys.babelfish_helpdb(@dbname);

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

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info (
 "@data_type" int = 0,
 "@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, false) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE PROCEDURE sys.sp_datatype_info_100 (
 "@data_type" int = 0,
 "@odbcver" smallint = 2)
AS $$
BEGIN
        select TYPE_NAME, DATA_TYPE, PRECISION, LITERAL_PREFIX, LITERAL_SUFFIX,
              CREATE_PARAMS::CHAR(20), NULLABLE, CASE_SENSITIVE, SEARCHABLE,
              UNSIGNED_ATTRIBUTE, MONEY, AUTO_INCREMENT, LOCAL_TYPE_NAME,
              MINIMUM_SCALE, MAXIMUM_SCALE, SQL_DATA_TYPE, SQL_DATETIME_SUB,
              NUM_PREC_RADIX, INTERVAL_PRECISION, USERTYPE
        from sys.sp_datatype_info_helper(@odbcver, true) where @data_type = 0 or data_type = @data_type
        order by DATA_TYPE, AUTO_INCREMENT, MONEY, USERTYPE;
END;
$$
LANGUAGE 'pltsql';

CREATE OR REPLACE FUNCTION sys.tsql_type_radix_for_sp_columns_helper(IN type TEXT)
RETURNS SMALLINT
AS $$
DECLARE
  radix SMALLINT;
BEGIN
  CASE type
    WHEN 'tinyint' THEN radix = 10;
    WHEN 'money' THEN radix = 10;
    WHEN 'smallmoney' THEN radix = 10;
    WHEN 'sql_variant' THEN radix = 10;
  ELSE
    radix = NULL;
  END CASE;
  RETURN radix;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_type_length_for_sp_columns_helper(IN type TEXT, IN typelen INT, IN typemod INT)
RETURNS INT
AS $$
DECLARE
  length INT;
  precision INT;
BEGIN
  -- unknown tsql type
  IF type IS NULL THEN
    RETURN typelen::INT;
  END IF;

  IF typemod = -1 AND (type = 'varchar' OR type = 'nvarchar' OR type = 'varbinary') THEN
    length = 0;
    RETURN length;
  END IF;

  IF typelen != -1 THEN
    CASE type
    WHEN 'tinyint' THEN length = 1;
    WHEN 'date' THEN length = 6;
    WHEN 'smalldatetime' THEN length = 16;
    WHEN 'smallmoney' THEN length = 12;
    WHEN 'money' THEN length = 21;
    WHEN 'datetime' THEN length = 16;
    WHEN 'datetime2' THEN length = 16;
    WHEN 'datetimeoffset' THEN length = 20;
    WHEN 'time' THEN length = 12;
    WHEN 'timestamp' THEN length = 8;
    ELSE length = typelen;
    END CASE;
    RETURN length;
  END IF;

  CASE
  WHEN type in ('char', 'bpchar', 'varchar', 'binary', 'varbinary') THEN length = typemod - 4;
  WHEN type in ('nchar', 'nvarchar') THEN length = (typemod - 4) * 2;
  WHEN type in ('text', 'image') THEN length = 2147483647;
  WHEN type = 'ntext' THEN length = 2147483646;
  WHEN type = 'xml' THEN length = 0;
  WHEN type = 'sql_variant' THEN length = 8000;
  WHEN type = 'money' THEN length = 21;
  WHEN type = 'sysname' THEN length = (typemod - 4) * 2;
  WHEN type in ('numeric', 'decimal') THEN
    precision = ((typemod - 4) >> 16) & 65535;
    length = precision + 2;
  ELSE
    length = typemod;
  END CASE;
  RETURN length;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- BABEL-1784: support for sp_columns/sp_columns_100
CREATE OR REPLACE VIEW sys.sp_columns_100_view AS
  SELECT
  CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
  CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
  CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
  CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
  CAST(t5.data_type AS smallint) AS DATA_TYPE,
  CAST(coalesce(tsql_type_name, t.typname) AS sys.sysname) AS TYPE_NAME,

  CASE WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", a.atttypmod)) AS INT)
    WHEN tsql_type_name = 'timestamp'
    THEN 8
    ELSE
    CAST(coalesce(t4."NUMERIC_PRECISION", t4."CHARACTER_MAXIMUM_LENGTH", sys.tsql_type_precision_helper(t4."DATA_TYPE", t.typtypmod)) AS INT)
  END AS PRECISION,

  CASE WHEN a.atttypmod != -1
    THEN
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, a.atttypmod) AS int)
    ELSE
    CAST(sys.tsql_type_length_for_sp_columns_helper(t4."DATA_TYPE", a.attlen, t.typtypmod) AS int)
  END AS LENGTH,


  CASE WHEN a.atttypmod != -1
    THEN
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", a.atttypmod, true)) AS smallint)
    ELSE
    CAST(coalesce(t4."NUMERIC_SCALE", sys.tsql_type_scale_helper(t4."DATA_TYPE", t.typtypmod, true)) AS smallint)
  END AS SCALE,


  CAST(coalesce(t4."NUMERIC_PRECISION_RADIX", sys.tsql_type_radix_for_sp_columns_helper(t4."DATA_TYPE")) AS smallint) AS RADIX,
  case
    when t4."IS_NULLABLE" = 'YES' then CAST(1 AS smallint)
    else CAST(0 AS smallint)
  end AS NULLABLE,

  CAST(NULL AS varchar(254)) AS remarks,
  CAST(t4."COLUMN_DEFAULT" AS sys.nvarchar(4000)) AS COLUMN_DEF,
  CAST(t5.sql_data_type AS smallint) AS SQL_DATA_TYPE,
  CAST(t5.SQL_DATETIME_SUB AS smallint) AS SQL_DATETIME_SUB,

  CASE WHEN t4."DATA_TYPE" = 'xml' COLLATE sys.database_default THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' COLLATE sys.database_default THEN 8000::INT
    WHEN t4."CHARACTER_MAXIMUM_LENGTH" = -1 THEN 0::INT
    ELSE CAST(t4."CHARACTER_OCTET_LENGTH" AS int)
  END AS CHAR_OCTET_LENGTH,

  CAST(t4."ORDINAL_POSITION" AS int) AS ORDINAL_POSITION,
  CAST(t4."IS_NULLABLE" AS varchar(254)) AS IS_NULLABLE,
  CAST(t5.ss_data_type AS sys.tinyint) AS SS_DATA_TYPE,
  CAST(0 AS smallint) AS SS_IS_SPARSE,
  CAST(0 AS smallint) AS SS_IS_COLUMN_SET,
  CAST(t6.is_computed as smallint) AS SS_IS_COMPUTED,
  CAST(t6.is_identity as smallint) AS SS_IS_IDENTITY,
  CAST(NULL AS varchar(254)) SS_UDT_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_UDT_ASSEMBLY_TYPE_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
  CAST(NULL AS varchar(254)) SS_XML_SCHEMACOLLECTION_NAME

  FROM pg_catalog.pg_class t1
     JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
     JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname COLLATE sys.database_default
     JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND ext.orig_name = t4."TABLE_SCHEMA" COLLATE sys.database_default)
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname = t4."COLUMN_NAME" COLLATE sys.database_default
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = t5.TYPE_NAME COLLATE sys.database_default)
    AND ext.dbid = cast(sys.db_id() as oid);

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
     where lower(table_name) similar to lower(in_table_name) COLLATE "C" -- TBD - this should be changed to ci_as
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner like in_table_owner collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier like in_table_qualifier collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name like in_column_name collate sys.bbf_unicode_general_ci_as)
  order by table_qualifier,
           table_owner,
    table_name,
    ordinal_position;
 ELSE
  return query
     select table_qualifier, precision from sys.sp_columns_100_view
       where in_table_name = table_name collate sys.bbf_unicode_general_ci_as
       and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier collate sys.bbf_unicode_general_ci_as)
       and ((SELECT coalesce(in_column_name,'')) = '' or column_name = in_column_name collate sys.bbf_unicode_general_ci_as)
  order by table_qualifier,
           table_owner,
    table_name,
    ordinal_position;
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
 select out_table_qualifier as TABLE_QUALIFIER,
   out_table_owner as TABLE_OWNER,
   out_table_name as TABLE_NAME,
   out_column_name as COLUMN_NAME,
   out_data_type as DATA_TYPE,
   out_type_name as TYPE_NAME,
   out_precision as PRECISION,
   out_length as LENGTH,
   out_scale as SCALE,
   out_radix as RADIX,
   out_nullable as NULLABLE,
   out_remarks as REMARKS,
   out_column_def as COLUMN_DEF,
   out_sql_data_type as SQL_DATA_TYPE,
   out_sql_datetime_sub as SQL_DATETIME_SUB,
   out_char_octet_length as CHAR_OCTET_LENGTH,
   out_ordinal_position as ORDINAL_POSITION,
   out_is_nullable as IS_NULLABLE,
   (
   CASE
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = -6 THEN 48 -- Tinyint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 5 THEN 52 -- Smallint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 4 THEN 56 -- Int Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = -5 THEN 63 -- Bigint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 3 THEN 55 -- Decimal Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 2 THEN 63 -- Numeric Identity
    ELSE out_ss_data_type
   END
   ) as SS_DATA_TYPE
 from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
  sys.babelfish_truncate_identifier(@table_owner),
  sys.babelfish_truncate_identifier(@table_qualifier),
  sys.babelfish_truncate_identifier(@column_name), @NameScope, @ODBCVer, @fusepattern);
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
 select out_table_qualifier as TABLE_QUALIFIER,
   out_table_owner as TABLE_OWNER,
   out_table_name as TABLE_NAME,
   out_column_name as COLUMN_NAME,
   out_data_type as DATA_TYPE,
   out_type_name as TYPE_NAME,
   out_precision as PRECISION,
   out_length as LENGTH,
   out_scale as SCALE,
   out_radix as RADIX,
   out_nullable as NULLABLE,
   out_remarks as REMARKS,
   out_column_def as COLUMN_DEF,
   out_sql_data_type as SQL_DATA_TYPE,
   out_sql_datetime_sub as SQL_DATETIME_SUB,
   out_char_octet_length as CHAR_OCTET_LENGTH,
   out_ordinal_position as ORDINAL_POSITION,
   out_is_nullable as IS_NULLABLE,
   out_ss_is_sparse as SS_IS_SPARSE,
   out_ss_is_column_set as SS_IS_COLUMN_SET,
   out_ss_is_computed as SS_IS_COMPUTED,
   out_ss_is_identity as SS_IS_IDENTITY,
   out_ss_udt_catalog_name as SS_UDT_CATALOG_NAME,
   out_ss_udt_schema_name as SS_UDT_SCHEMA_NAME,
   out_ss_udt_assembly_type_name as SS_UDT_ASSEMBLY_TYPE_NAME,
   out_ss_xml_schemacollection_catalog_name as SS_XML_SCHEMACOLLECTION_CATALOG_NAME,
   out_ss_xml_schemacollection_schema_name as SS_XML_SCHEMACOLLECTION_SCHEMA_NAME,
   out_ss_xml_schemacollection_name as SS_XML_SCHEMACOLLECTION_NAME,
   (
   CASE
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = -6 THEN 48 -- Tinyint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 5 THEN 52 -- Smallint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 4 THEN 56 -- Int Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = -5 THEN 63 -- Bigint Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 3 THEN 55 -- Decimal Identity
    WHEN out_ss_is_identity = 1 AND out_sql_data_type = 2 THEN 63 -- Numeric Identity
    ELSE out_ss_data_type
   END
   ) as SS_DATA_TYPE
 from sys.sp_columns_100_internal(sys.babelfish_truncate_identifier(@table_name),
  sys.babelfish_truncate_identifier(@table_owner),
  sys.babelfish_truncate_identifier(@table_qualifier),
  sys.babelfish_truncate_identifier(@column_name), @NameScope, @ODBCVer, @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_100 TO PUBLIC;

create or replace function sys.get_tds_id(
 datatype sys.varchar(50)
)
returns INT
AS $$
DECLARE
 tds_id INT;
BEGIN
 IF datatype IS NULL THEN
  RETURN 0;
 END IF;
 CASE datatype
  WHEN 'text' THEN tds_id = 35;
  WHEN 'uniqueidentifier' THEN tds_id = 36;
  WHEN 'tinyint' THEN tds_id = 38;
  WHEN 'smallint' THEN tds_id = 38;
  WHEN 'int' THEN tds_id = 38;
  WHEN 'bigint' THEN tds_id = 38;
  WHEN 'ntext' THEN tds_id = 99;
  WHEN 'bit' THEN tds_id = 104;
  WHEN 'float' THEN tds_id = 109;
  WHEN 'real' THEN tds_id = 109;
  WHEN 'varchar' THEN tds_id = 167;
  WHEN 'nvarchar' THEN tds_id = 231;
  WHEN 'nchar' THEN tds_id = 239;
  WHEN 'money' THEN tds_id = 110;
  WHEN 'smallmoney' THEN tds_id = 110;
  WHEN 'char' THEN tds_id = 175;
  WHEN 'date' THEN tds_id = 40;
  WHEN 'datetime' THEN tds_id = 111;
  WHEN 'smalldatetime' THEN tds_id = 111;
  WHEN 'numeric' THEN tds_id = 108;
  WHEN 'xml' THEN tds_id = 241;
  WHEN 'decimal' THEN tds_id = 106;
  WHEN 'varbinary' THEN tds_id = 165;
  WHEN 'binary' THEN tds_id = 173;
  WHEN 'image' THEN tds_id = 34;
  WHEN 'time' THEN tds_id = 41;
  WHEN 'datetime2' THEN tds_id = 42;
  WHEN 'sql_variant' THEN tds_id = 98;
  WHEN 'datetimeoffset' THEN tds_id = 43;
  WHEN 'timestamp' THEN tds_id = 173;
  ELSE tds_id = 0;
 END CASE;
 RETURN tds_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

create or replace function sys.sp_describe_first_result_set_internal(
 tsqlquery sys.nvarchar(8000),
    params sys.nvarchar(8000) = NULL,
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
AS 'babelfishpg_tsql', 'sp_describe_first_result_set_internal'
LANGUAGE C;
GRANT ALL on FUNCTION sys.sp_describe_first_result_set_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_describe_first_result_set (
 "@tsql" sys.nvarchar(8000),
    "@params" sys.nvarchar(8000) = NULL,
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
        CASE WHEN p.attoptions[1] collate "C" LIKE 'bbf_original_name=%' THEN split_part(p.attoptions[1] collate "C", '=', 2)
  ELSE c.name END AS name,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_28,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_90,
        CAST(CollationProperty(c.collation_name,'tdscollation') AS binary(5)) AS tds_collation_100,
        CAST(c.collation_name AS nvarchar(128)) AS collation_28,
        CAST(c.collation_name AS nvarchar(128)) AS collation_90,
        CAST(c.collation_name AS nvarchar(128)) AS collation_100
    FROM
        sys.all_columns c INNER JOIN
        sys.all_objects o ON (c.object_id = o.object_id) JOIN
        pg_attribute p ON (c.name = p.attname COLLATE sys.database_default AND c.object_id = p.attrelid)
    WHERE
        c.is_sparse = 0 AND p.attnum >= 0;
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
        s_tcv.tds_collation_100 AS tds_collation,
        s_tcv.collation_100 AS collation
    from
        sys.spt_tablecollations_view s_tcv
    where
        s_tcv.object_id = (SELECT sys.object_id(@object))
    order by colid;
END;
$$
LANGUAGE 'pltsql';

-- TODO: Remove information_schema references
CREATE OR REPLACE VIEW sys.spt_columns_view_managed AS
SELECT
    o.object_id AS OBJECT_ID,
    isc."TABLE_CATALOG"::information_schema.sql_identifier AS TABLE_CATALOG,
    isc."TABLE_SCHEMA"::information_schema.sql_identifier AS TABLE_SCHEMA,
    o.name AS TABLE_NAME,
    c.name AS COLUMN_NAME,
    isc."ORDINAL_POSITION"::information_schema.cardinal_number AS ORDINAL_POSITION,
    isc."COLUMN_DEFAULT"::information_schema.character_data AS COLUMN_DEFAULT,
    isc."IS_NULLABLE"::information_schema.yes_or_no AS IS_NULLABLE,
    isc."DATA_TYPE"::information_schema.character_data AS DATA_TYPE,

    CAST (CASE WHEN isc."CHARACTER_MAXIMUM_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_MAXIMUM_LENGTH" END
  AS information_schema.cardinal_number) AS CHARACTER_MAXIMUM_LENGTH,

    CAST (CASE WHEN isc."CHARACTER_OCTET_LENGTH" < 0 THEN 0 ELSE isc."CHARACTER_OCTET_LENGTH" END
  AS information_schema.cardinal_number) AS CHARACTER_OCTET_LENGTH,

    CAST (CASE WHEN isc."NUMERIC_PRECISION" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION" END
  AS information_schema.cardinal_number) AS NUMERIC_PRECISION,

    CAST (CASE WHEN isc."NUMERIC_PRECISION_RADIX" < 0 THEN 0 ELSE isc."NUMERIC_PRECISION_RADIX" END
  AS information_schema.cardinal_number) AS NUMERIC_PRECISION_RADIX,

    CAST (CASE WHEN isc."NUMERIC_SCALE" < 0 THEN 0 ELSE isc."NUMERIC_SCALE" END
  AS information_schema.cardinal_number) AS NUMERIC_SCALE,

    CAST (CASE WHEN isc."DATETIME_PRECISION" < 0 THEN 0 ELSE isc."DATETIME_PRECISION" END
  AS information_schema.cardinal_number) AS DATETIME_PRECISION,

    isc."CHARACTER_SET_CATALOG"::information_schema.sql_identifier AS CHARACTER_SET_CATALOG,
    isc."CHARACTER_SET_SCHEMA"::information_schema.sql_identifier AS CHARACTER_SET_SCHEMA,
    isc."CHARACTER_SET_NAME"::information_schema.sql_identifier AS CHARACTER_SET_NAME,
    isc."COLLATION_CATALOG"::information_schema.sql_identifier AS COLLATION_CATALOG,
    isc."COLLATION_SCHEMA"::information_schema.sql_identifier AS COLLATION_SCHEMA,
    c.collation_name AS COLLATION_NAME,
    isc."DOMAIN_CATALOG"::information_schema.sql_identifier AS DOMAIN_CATALOG,
    isc."DOMAIN_SCHEMA"::information_schema.sql_identifier AS DOMAIN_SCHEMA,
    isc."DOMAIN_NAME"::information_schema.sql_identifier AS DOMAIN_NAME,
    c.is_sparse AS IS_SPARSE,
    c.is_column_set AS IS_COLUMN_SET,
    c.is_filestream AS IS_FILESTREAM
FROM
    sys.objects o JOIN sys.columns c ON
        (
            c.object_id = o.object_id and
            o.type in ('U', 'V') -- limit columns to tables and views
        )
    LEFT JOIN information_schema_tsql.columns isc ON
        (
            sys.schema_name(o.schema_id) = isc."TABLE_SCHEMA" and
            o.name = isc."TABLE_NAME" and
            c.name = isc."COLUMN_NAME"
        )
    WHERE CAST("COLUMN_NAME" AS sys.nvarchar(128)) NOT IN ('cmin', 'cmax', 'xmin', 'xmax', 'ctid', 'tableoid');
GRANT SELECT ON sys.spt_columns_view_managed TO PUBLIC;

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
        (in_catalog IS NULL OR s_cv.TABLE_CATALOG LIKE LOWER(in_catalog)) AND
        (in_owner IS NULL OR s_cv.TABLE_SCHEMA LIKE LOWER(in_owner)) AND
        (in_table IS NULL OR s_cv.TABLE_NAME LIKE LOWER(in_table)) AND
        (in_column IS NULL OR s_cv.COLUMN_NAME LIKE LOWER(in_column)) AND
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
        sys.sp_columns_managed_internal(@Catalog, @Owner, @Table, @Column, @SchemaType) s_cv
    ORDER BY TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, IS_NULLABLE;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_columns_managed TO PUBLIC;

-- BABEL-1797: initial support of sp_describe_undeclared_parameters
-- sys.sp_describe_undeclared_parameters_internal: internal function
-- For the result rows, can we create a template table for it?
create function sys.sp_describe_undeclared_parameters_internal(
 tsqlquery sys.nvarchar(4000),
    params sys.nvarchar(4000) = NULL
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
 "@tsql" sys.nvarchar(4000),
    "@params" sys.nvarchar(4000) = NULL)
AS $$
BEGIN
 select * from sys.sp_describe_undeclared_parameters_internal(@tsql, @params);
 return 1;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_describe_undeclared_parameters TO PUBLIC;

-- BABEL-1782
CREATE OR REPLACE VIEW sys.sp_tables_view AS
SELECT
t2.dbname AS TABLE_QUALIFIER,
CAST(t3.name AS name) AS TABLE_OWNER,
t1.relname AS TABLE_NAME,

CASE
WHEN t1.relkind = 'v'
 THEN 'VIEW'
ELSE 'TABLE'
END AS TABLE_TYPE,

CAST(NULL AS varchar(254)) AS remarks
FROM pg_catalog.pg_class AS t1, sys.pg_namespace_ext AS t2, sys.schemas AS t3
WHERE t1.relnamespace = t3.schema_id AND t1.relnamespace = t2.oid AND t1.relkind IN ('r','v','m')
AND has_schema_privilege(t1.relnamespace, 'USAGE')
AND has_table_privilege(t1.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.sp_tables_view TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_tables_internal(
 in_table_name sys.nvarchar(384) = '',
 in_table_owner sys.nvarchar(384) = '',
 in_table_qualifier sys.sysname = '',
 in_table_type sys.varchar(100) = '',
 in_fusepattern sys.bit = '1')
 RETURNS TABLE (
  out_table_qualifier sys.sysname,
  out_table_owner sys.sysname,
  out_table_name sys.sysname,
  out_table_type sys.varchar(32),
  out_remarks sys.varchar(254)
 )
 AS $$
  DECLARE opt_table sys.varchar(16) = '';
  DECLARE opt_view sys.varchar(16) = '';
  DECLARE cs_as_in_table_type varchar COLLATE "C" = in_table_type;
 BEGIN
  IF (SELECT count(*) FROM unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = '''TABLE''' OR upper(trim(unnest)) = '''''''TABLE''''''') >= 1 THEN
   opt_table = 'TABLE';
  END IF;
  IF (SELECT count(*) from unnest(string_to_array(cs_as_in_table_type, ',')) WHERE upper(trim(unnest)) = '''VIEW''' OR upper(trim(unnest)) = '''''''VIEW''''''') >= 1 THEN
   opt_view = 'VIEW';
  END IF;
  IF in_fusepattern = 1 THEN
   RETURN query
   SELECT
   CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
   CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
   CAST(table_name AS sys.sysname) AS TABLE_NAME,
   CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
   CAST(remarks AS sys.varchar(254)) AS REMARKS
   FROM sys.sp_tables_view
   WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name LIKE in_table_name collate sys.database_default)
   AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner LIKE in_table_owner collate sys.database_default)
   AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier LIKE in_table_qualifier collate sys.database_default)
   AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
       OR table_type collate sys.database_default = opt_table
       OR table_type collate sys.database_default = opt_view)
   ORDER BY table_qualifier, table_owner, table_name;
  ELSE
   RETURN query
   SELECT
   CAST(table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
   CAST(table_owner AS sys.sysname) AS TABLE_OWNER,
   CAST(table_name AS sys.sysname) AS TABLE_NAME,
   CAST(table_type AS sys.varchar(32)) AS TABLE_TYPE,
   CAST(remarks AS sys.varchar(254)) AS REMARKS
   FROM sys.sp_tables_view
   WHERE ((SELECT coalesce(in_table_name,'')) = '' OR table_name = in_table_name collate sys.database_default)
   AND ((SELECT coalesce(in_table_owner,'')) = '' OR table_owner = in_table_owner collate sys.database_default)
   AND ((SELECT coalesce(in_table_qualifier,'')) = '' OR table_qualifier = in_table_qualifier collate sys.database_default)
   AND ((SELECT coalesce(cs_as_in_table_type,'')) = ''
       OR table_type collate sys.database_default = opt_table
       OR table_type collate sys.database_default = opt_view)
   ORDER BY table_qualifier, table_owner, table_name;
  END IF;
 END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE sys.sp_tables (
    "@table_name" sys.nvarchar(384) = '',
    "@table_owner" sys.nvarchar(384) = '',
    "@table_qualifier" sys.sysname = '',
    "@table_type" sys.nvarchar(100) = '',
    "@fusepattern" sys.bit = '1')
AS $$
 DECLARE @opt_table sys.varchar(16) = '';
 DECLARE @opt_view sys.varchar(16) = '';
BEGIN
 IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 SELECT
 CAST(out_table_qualifier AS sys.sysname) AS TABLE_QUALIFIER,
 CAST(out_table_owner AS sys.sysname) AS TABLE_OWNER,
 CAST(out_table_name AS sys.sysname) AS TABLE_NAME,
 CAST(out_table_type AS sys.varchar(32)) AS TABLE_TYPE,
 CAST(out_remarks AS sys.varchar(254)) AS REMARKS
 FROM sys.sp_tables_internal(@table_name, @table_owner, @table_qualifier, CAST(@table_type AS varchar(100)), @fusepattern);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_tables TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.fn_mapped_system_error_list ()
returns table (pg_sql_state sys.nvarchar(5), error_message sys.nvarchar(4000), error_msg_parameters sys.nvarchar(4000), sql_error_code int)
AS 'babelfishpg_tsql', 'babel_list_mapped_error'
LANGUAGE C IMMUTABLE STRICT;
GRANT ALL on FUNCTION sys.fn_mapped_system_error_list TO PUBLIC;

-- BABEL-2259: Support sp_databases System Stored Procedure
-- Lists databases that either reside in an instance of the SQL Server or
-- are accessible through a database gateway
DROP VIEW IF EXISTS sys.sp_databases_view CASCADE;

CREATE OR REPLACE VIEW sys.sp_databases_view AS
 SELECT CAST(database_name AS sys.SYSNAME),
 -- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
 CASE WHEN (sum(table_size)/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
  ELSE CAST((sum(table_size)/1024.0) AS int) END as database_size,
 CAST(NULL AS sys.VARCHAR(254)) as remarks
 FROM (
  SELECT pg_catalog.pg_namespace.oid as schema_oid,
  pg_catalog.pg_namespace.nspname as schema_name,
  INT.name AS database_name,
  coalesce(pg_relation_size(pg_catalog.pg_class.oid), 0) as table_size
  FROM
  sys.babelfish_namespace_ext EXT
  JOIN sys.babelfish_sysdatabases INT ON EXT.dbid = INT.dbid
  JOIN pg_catalog.pg_namespace ON pg_catalog.pg_namespace.nspname = EXT.nspname
  LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid
 ) t
 GROUP BY database_name
 ORDER BY database_name;
GRANT SELECT on sys.sp_databases_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_databases ()
AS $$
BEGIN
 SELECT database_name as "DATABASE_NAME",
  database_size as "DATABASE_SIZE",
  remarks as "REMARKS" from sys.sp_databases_view;
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_databases TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_pkeys_view AS
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST(seq AS smallint) AS KEY_SEQ,
CAST(t5.conname AS sys.sysname) AS PK_NAME
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
  LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
 JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND ext.orig_name = t4."TABLE_SCHEMA" COLLATE sys.database_default)
 JOIN pg_constraint t5 ON t1.oid = t5.conrelid
 , generate_series(1,16) seq -- SQL server has max 16 columns per primary key
WHERE t5.contype = 'p'
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.conkey)
 AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.conkey[seq]
  AND ext.dbid = cast(sys.db_id() as oid);

GRANT SELECT on sys.sp_pkeys_view TO PUBLIC;

-- internal function in order to workaround BABEL-1597
create or replace function sys.sp_pkeys_internal(
 in_table_name sys.nvarchar(384),
 in_table_owner sys.nvarchar(384) = '',
 in_table_qualifier sys.nvarchar(384) = ''
)
returns table(
 out_table_qualifier sys.sysname,
 out_table_owner sys.sysname,
 out_table_name sys.sysname,
 out_column_name sys.sysname,
 out_key_seq smallint,
 out_pk_name sys.sysname
)
as $$
begin
 return query
 select * from sys.sp_pkeys_view
 where table_name = in_table_name collate sys.database_default
  and table_owner = coalesce(in_table_owner,'dbo') collate sys.database_default
  and ((SELECT
           coalesce(in_table_qualifier,'')) = '' or
           table_qualifier = in_table_qualifier collate sys.database_default)
 order by table_qualifier,
          table_owner,
   table_name,
   key_seq;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_pkeys(
 "@table_name" sys.nvarchar(384),
 "@table_owner" sys.nvarchar(384) = 'dbo',
 "@table_qualifier" sys.nvarchar(384) = ''
)
AS $$
BEGIN
 select out_table_qualifier as TABLE_QUALIFIER,
   out_table_owner as TABLE_OWNER,
   out_table_name as TABLE_NAME,
   out_column_name as COLUMN_NAME,
   out_key_seq as KEY_SEQ,
   out_pk_name as PK_NAME
 from sys.sp_pkeys_internal(@table_name, @table_owner, @table_qualifier);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_pkeys TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_statistics_view AS
SELECT
CAST(t3."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t3."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t3."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CAST(NULL AS smallint) AS NON_UNIQUE,
CAST(NULL AS sys.sysname) AS INDEX_QUALIFIER,
CAST(NULL AS sys.sysname) AS INDEX_NAME,
CAST(0 AS smallint) AS TYPE,
CAST(NULL AS smallint) AS SEQ_IN_INDEX,
CAST(NULL AS sys.sysname) AS COLUMN_NAME,
CAST(NULL AS sys.varchar(1)) AS COLLATION,
CAST(t1.reltuples AS int) AS CARDINALITY,
CAST(t1.relpages AS int) AS PAGES,
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN information_schema_tsql.columns t3 ON (t1.relname = t3."TABLE_NAME" COLLATE sys.database_default AND s1.name = t3."TABLE_SCHEMA")
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
UNION
SELECT
CAST(t4."TABLE_CATALOG" AS sys.sysname) AS TABLE_QUALIFIER,
CAST(t4."TABLE_SCHEMA" AS sys.sysname) AS TABLE_OWNER,
CAST(t4."TABLE_NAME" AS sys.sysname) AS TABLE_NAME,
CASE
WHEN t5.indisunique = 't' THEN CAST(0 AS smallint)
ELSE CAST(1 AS smallint)
END AS NON_UNIQUE,
CAST(t1.relname AS sys.sysname) AS INDEX_QUALIFIER,
-- the index name created by CREATE INDEX is re-mapped, find it (by checking
-- the ones not in pg_constraint) and restoring it back before display
CASE
WHEN t8.oid > 0 THEN CAST(t6.relname AS sys.sysname)
ELSE CAST(SUBSTRING(t6.relname,1,LENGTH(t6.relname)-32-LENGTH(t1.relname)) AS sys.sysname)
END AS INDEX_NAME,
CASE
WHEN t7.starelid > 0 THEN CAST(0 AS smallint)
ELSE
 CASE
 WHEN t5.indisclustered = 't' THEN CAST(1 AS smallint)
 ELSE CAST(3 AS smallint)
 END
END AS TYPE,
CAST(seq + 1 AS smallint) AS SEQ_IN_INDEX,
CAST(t4."COLUMN_NAME" AS sys.sysname) AS COLUMN_NAME,
CAST('A' AS sys.varchar(1)) AS COLLATION,
CAST(t7.stadistinct AS int) AS CARDINALITY,
CAST(0 AS int) AS PAGES, --not supported
CAST(NULL AS sys.varchar(128)) AS FILTER_CONDITION
FROM pg_catalog.pg_class t1
    JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
    JOIN pg_catalog.pg_roles t3 ON t1.relowner = t3.oid
    JOIN information_schema_tsql.columns t4 ON (t1.relname = t4."TABLE_NAME" COLLATE sys.database_default AND s1.name = t4."TABLE_SCHEMA")
 JOIN (pg_catalog.pg_index t5 JOIN
  pg_catalog.pg_class t6 ON t5.indexrelid = t6.oid) ON t1.oid = t5.indrelid
 LEFT JOIN pg_catalog.pg_statistic t7 ON t1.oid = t7.starelid
 LEFT JOIN pg_catalog.pg_constraint t8 ON t5.indexrelid = t8.conindid
    , generate_series(0,31) seq -- SQL server has max 32 columns per index
WHERE CAST(t4."ORDINAL_POSITION" AS smallint) = ANY (t5.indkey)
    AND CAST(t4."ORDINAL_POSITION" AS smallint) = t5.indkey[seq];
GRANT SELECT on sys.sp_statistics_view TO PUBLIC;

create function sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname = '',
    in_table_qualifier sys.sysname = '',
    in_index_name sys.sysname = '',
 in_is_unique char = 'N',
 in_accuracy char = 'Q'
)
returns table(
    out_table_qualifier sys.sysname,
    out_table_owner sys.sysname,
    out_table_name sys.sysname,
 out_non_unique smallint,
 out_index_qualifier sys.sysname,
 out_index_name sys.sysname,
 out_type smallint,
 out_seq_in_index smallint,
 out_column_name sys.sysname,
 out_collation sys.varchar(1),
 out_cardinality int,
 out_pages int,
 out_filter_condition sys.varchar(128)
)
as $$
begin
    return query
    select * from sys.sp_statistics_view
    where in_table_name = table_name COLLATE sys.database_default
        and ((SELECT coalesce(in_table_owner,'')) = '' or table_owner = in_table_owner COLLATE sys.database_default)
        and ((SELECT coalesce(in_table_qualifier,'')) = '' or table_qualifier = in_table_qualifier COLLATE sys.database_default)
        and ((SELECT coalesce(in_index_name,'')) = '' or index_name like in_index_name COLLATE sys.database_default)
        and ((UPPER(in_is_unique) = 'Y' and (non_unique IS NULL or non_unique = 0)) or (UPPER(in_is_unique) = 'N'))
    order by non_unique, type, index_name, seq_in_index;
end;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_statistics(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
 "@index_name" sys.sysname = '',
 "@is_unique" char = 'N',
 "@accuracy" char = 'Q'
)
AS $$
BEGIN
    IF @index_name = '%'
 BEGIN
     SELECT @index_name = ''
 END
    select out_table_qualifier as table_qualifier,
            out_table_owner as table_owner,
            out_table_name as table_name,
   out_non_unique as non_unique,
   out_index_qualifier as index_qualifier,
   out_index_name as index_name,
   out_type as type,
   out_seq_in_index as seq_in_index,
   out_column_name as column_name,
   out_collation as collation,
   out_cardinality as cardinality,
   out_pages as pages,
   out_filter_condition as filter_condition
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics TO PUBLIC;

-- same as sp_statistics
CREATE OR REPLACE PROCEDURE sys.sp_statistics_100(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
 "@index_name" sys.sysname = '',
 "@is_unique" char = 'N',
 "@accuracy" char = 'Q'
)
AS $$
BEGIN
    IF @index_name = '%'
 BEGIN
     SELECT @index_name = ''
 END
    select out_table_qualifier as TABLE_QUALIFIER,
            out_table_owner as TABLE_OWNER,
            out_table_name as TABLE_NAME,
   out_non_unique as NON_UNIQUE,
   out_index_qualifier as INDEX_QUALIFIER,
   out_index_name as INDEX_NAME,
   out_type as TYPE,
   out_seq_in_index as SEQ_IN_INDEX,
   out_column_name as COLUMN_NAME,
   out_collation as COLLATION,
   out_cardinality as CARDINALITY,
   out_pages as PAGES,
   out_filter_condition as FILTER_CONDITION
    from sys.sp_statistics_internal(@table_name, @table_owner, @table_qualifier, @index_name, @is_unique, @accuracy);
END;
$$
LANGUAGE 'pltsql';
GRANT ALL on PROCEDURE sys.sp_statistics_100 TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.printarg(IN "@message" TEXT)
AS $$
BEGIN
  PRINT @message;
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.printarg(IN "@message" TEXT) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8) DEFAULT 'NO')
AS $$
BEGIN
  IF sys.user_name() != 'dbo' THEN
    RAISE EXCEPTION 'user does not have permission';
  END IF;

  IF lower("@resample") = 'resample' THEN
    RAISE NOTICE 'ignoring resample option';
  ELSIF lower("@resample") != 'no' THEN
    RAISE EXCEPTION 'Invalid option name %', "@resample";
  END IF;

  ANALYZE VERBOSE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

CREATE OR REPLACE VIEW sys.dm_os_host_info AS
SELECT
  -- get_host_os() depends on a Postgres function created separately.
  cast( sys.get_host_os() as sys.nvarchar(256) ) as host_platform
  -- Hardcoded at the moment. Should likely be GUC with default '' (empty string).
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_distribution') as sys.nvarchar(256) ) as host_distribution
  -- documentation on one hand states this is empty string on 1, but otoh shows an example with "ubuntu 16.04"
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_release') as sys.nvarchar(256) ) as host_release
  -- empty string on 1 .
  , cast( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.host_service_pack_level') as sys.nvarchar(256) )
    as host_service_pack_level
  -- windows stock keeping unit. null on 1 .
  , cast( null as int ) as host_sku
  -- lcid
  , cast( sys.collationproperty( (select setting FROM pg_settings WHERE name = 'babelfishpg_tsql.server_collation_name') , 'lcid') as int )
    as "os_language_version";
GRANT SELECT ON sys.dm_os_host_info TO PUBLIC;

-- For some cases, T-SQL throws an error in DML-time even though it can be detected in DDL-time.
-- This function can be used in DDL-time to postpone errors without impacting general DML performance.
CREATE OR REPLACE FUNCTION sys.babelfish_runtime_error(msg ANYCOMPATIBLE)
RETURNS ANYCOMPATIBLE AS
$$
BEGIN
 RAISE EXCEPTION '%', msg;
END;
$$
LANGUAGE PLPGSQL;
GRANT ALL on FUNCTION sys.babelfish_runtime_error TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_column_privileges_view AS
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) AS TABLE_NAME,
CAST(COALESCE(SPLIT_PART(t6.attoptions[1] collate "C", '=', 2), t5.column_name collate "C") AS sys.sysname) AS COLUMN_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantor::name) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t5.grantee::name) AS sys.sysname) AS GRANTEE,
CAST(t5.privilege_type AS sys.varchar(32)) COLLATE sys.database_default AS PRIVILEGE,
CAST(t5.is_grantable AS sys.varchar(3)) COLLATE sys.database_default AS IS_GRANTABLE
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
 JOIN information_schema.column_privileges t5 ON t1.relname = t5.table_name AND t2.nspname = t5.table_schema
 JOIN pg_attribute t6 ON t6.attrelid = t1.oid AND t6.attname = t5.column_name;
GRANT SELECT ON sys.sp_column_privileges_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_column_privileges(
    "@table_name" sys.sysname,
    "@table_owner" sys.sysname = '',
    "@table_qualifier" sys.sysname = '',
    "@column_name" sys.nvarchar(384) = ''
)
AS $$
BEGIN
    IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 IF (COALESCE(@table_owner, '') = '')
 BEGIN

  IF EXISTS (
   SELECT * FROM sys.sp_column_privileges_view
   WHERE LOWER(@table_name) = LOWER(table_name) and LOWER(SCHEMA_NAME()) = LOWER(table_qualifier)
   )
  BEGIN
   SELECT
   TABLE_QUALIFIER,
   TABLE_OWNER,
   TABLE_NAME,
   COLUMN_NAME,
   GRANTOR,
   GRANTEE,
   PRIVILEGE,
   IS_GRANTABLE
   FROM sys.sp_column_privileges_view
   WHERE LOWER(@table_name) = LOWER(table_name)
    AND (LOWER(SCHEMA_NAME()) = LOWER(table_owner))
    AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
    AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
   ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
  END
  ELSE
  BEGIN
   SELECT
   TABLE_QUALIFIER,
   TABLE_OWNER,
   TABLE_NAME,
   COLUMN_NAME,
   GRANTOR,
   GRANTEE,
   PRIVILEGE,
   IS_GRANTABLE
   FROM sys.sp_column_privileges_view
   WHERE LOWER(@table_name) = LOWER(table_name)
    AND (LOWER('dbo')= LOWER(table_owner))
    AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
    AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
   ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
  END
 END
 ELSE
 BEGIN
  SELECT
  TABLE_QUALIFIER,
  TABLE_OWNER,
  TABLE_NAME,
  COLUMN_NAME,
  GRANTOR,
  GRANTEE,
  PRIVILEGE,
  IS_GRANTABLE
  FROM sys.sp_column_privileges_view
  WHERE LOWER(@table_name) = LOWER(table_name)
   AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
   AND ((SELECT COALESCE(@table_qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@table_qualifier))
   AND ((SELECT COALESCE(@column_name,'')) = '' OR LOWER(column_name) LIKE LOWER(@column_name))
  ORDER BY table_qualifier, table_owner, table_name, column_name, privilege, grantee;
 END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_column_privileges TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_table_privileges_view AS
-- Will use sp_column_priivleges_view to get information from SELECT, INSERT and REFERENCES (only need permission from 1 column in table)
SELECT DISTINCT
CAST(TABLE_QUALIFIER AS sys.sysname) AS TABLE_QUALIFIER,
CAST(TABLE_OWNER AS sys.sysname) AS TABLE_OWNER,
CAST(TABLE_NAME AS sys.sysname) AS TABLE_NAME,
CAST(GRANTOR AS sys.sysname) AS GRANTOR,
CAST(GRANTEE AS sys.sysname) AS GRANTEE,
CAST(PRIVILEGE AS sys.sysname) AS PRIVILEGE,
CAST(IS_GRANTABLE AS sys.sysname) AS IS_GRANTABLE
FROM sys.sp_column_privileges_view

UNION
-- We need these set of joins only for the DELETE privilege
SELECT
CAST(t2.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(t1.relname AS sys.sysname) COLLATE sys.database_default AS TABLE_NAME,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantor) AS sys.sysname) AS GRANTOR,
CAST((select orig_username from sys.babelfish_authid_user_ext where rolname = t4.grantee) AS sys.sysname) AS GRANTEE,
CAST(t4.privilege_type AS sys.sysname) AS PRIVILEGE,
CAST(t4.is_grantable AS sys.sysname) AS IS_GRANTABLE
FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
 JOIN information_schema.table_privileges t4 ON t1.relname = t4.table_name
WHERE t4.privilege_type = 'DELETE';
GRANT SELECT on sys.sp_table_privileges_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_table_privileges(
 "@table_name" sys.nvarchar(384),
 "@table_owner" sys.nvarchar(384) = '',
 "@table_qualifier" sys.sysname = '',
 "@fusepattern" sys.bit = 1
)
AS $$
BEGIN

 IF (@table_qualifier != '') AND (LOWER(@table_qualifier) != LOWER(sys.db_name()))
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 IF @fusepattern = 1
 BEGIN
  SELECT
  TABLE_QUALIFIER,
  TABLE_OWNER,
  TABLE_NAME,
  GRANTOR,
  GRANTEE,
  PRIVILEGE,
  IS_GRANTABLE FROM sys.sp_table_privileges_view
  WHERE LOWER(TABLE_NAME) LIKE LOWER(@table_name)
   AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) LIKE LOWER(@table_owner))
  ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
 END
 ELSE
 BEGIN
  SELECT
  TABLE_QUALIFIER,
  TABLE_OWNER,
  TABLE_NAME,
  GRANTOR,
  GRANTEE,
  PRIVILEGE,
  IS_GRANTABLE FROM sys.sp_table_privileges_view
  WHERE LOWER(TABLE_NAME) = LOWER(@table_name)
   AND ((SELECT COALESCE(@table_owner,'')) = '' OR LOWER(TABLE_OWNER) = LOWER(@table_owner))
  ORDER BY table_qualifier, table_owner, table_name, privilege, grantee;
 END

END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_table_privileges TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_precision_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('real','float') THEN sp_columns_max_length * 2 - 1
  WHEN type COLLATE sys.database_default in ('char','varchar','binary','varbinary') THEN sp_columns_max_length
  WHEN type COLLATE sys.database_default in ('nchar','nvarchar') THEN sp_columns_max_length / 2
  WHEN type COLLATE sys.database_default in ('sysname','uniqueidentifier') THEN sp_datatype_info_precision
  ELSE sp_columns_precision
 END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_length_helper(IN type TEXT, IN sp_columns_precision INT, IN sp_columns_max_length SMALLINT, IN sp_datatype_info_precision BIGINT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('decimal','numeric','money','smallmoney') THEN sp_columns_precision + 2
  WHEN type COLLATE sys.database_default in ('time','date','datetime2','datetimeoffset') THEN sp_columns_precision * 2
  WHEN type COLLATE sys.database_default in ('smalldatetime') THEN sp_columns_precision
  WHEN type COLLATE sys.database_default in ('datetime') THEN sp_columns_max_length * 2
  WHEN type COLLATE sys.database_default in ('sql_variant') THEN sp_datatype_info_precision
  ELSE sp_columns_max_length
 END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.sp_special_columns_scale_helper(IN type TEXT, IN sp_columns_scale INT) RETURNS INT
AS $$
SELECT
 CASE
  WHEN type COLLATE sys.database_default in ('bit','real','float','char','varchar','nchar','nvarchar','time','date','datetime2','datetimeoffset','varbinary','binary','sql_variant','sysname','uniqueidentifier') THEN NULL
  ELSE sp_columns_scale
 END;
$$ LANGUAGE SQL IMMUTABLE;

-- TODO: BABEL-2838
CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT DISTINCT
CAST(1 as smallint) AS SCOPE,
CAST(coalesce (split_part(pa.attoptions[1] collate "C", '=', 2) ,c1.name) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS smallint) AS DATA_TYPE,

CASE -- cases for when they are of type identity.
 WHEN c1.is_identity = 1 AND (t8.name COLLATE sys.database_default = 'decimal' or t8.name COLLATE sys.database_default = 'numeric')
 THEN CAST(CONCAT(t8.name, '() identity') AS sys.sysname)
 WHEN c1.is_identity = 1 AND (t8.name COLLATE sys.database_default != 'decimal' AND t8.name COLLATE sys.database_default != 'numeric')
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
 WHEN idx.is_primary_key != 1
 THEN CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
 ELSE CAST('p' AS sys.sysname)
END AS CONSTRAINT_TYPE,
CAST(idx.name AS sys.sysname) AS CONSTRAINT_NAME,
CAST(idx.index_id AS int) AS INDEX_ID

FROM pg_catalog.pg_class t1
 JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
 JOIN sys.schemas s1 ON s1.schema_id = t1.relnamespace
 LEFT JOIN sys.indexes idx ON idx.object_id = t1.oid
 INNER JOIN pg_catalog.pg_attribute i2 ON idx.index_id = i2.attrelid
 INNER JOIN sys.columns c1 ON c1.object_id = idx.object_id AND cast(i2.attname as sys.sysname) = c1.name collate sys.database_default

 JOIN pg_catalog.pg_type AS t7 ON t7.oid = c1.system_type_id
 JOIN sys.types AS t8 ON c1.user_type_id = t8.user_type_id
 LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON t7.typname = t6.pg_type_name collate sys.database_default OR t7.typname = t6.type_name collate sys.database_default --need in order to get accurate DATA_TYPE value
 LEFT JOIN pg_catalog.pg_attribute AS pa ON t1.oid = pa.attrelid AND c1.name = pa.attname collate sys.database_default
 , sys.translate_pg_type_to_tsql(t8.user_type_id) AS tsql_type_name
 , sys.translate_pg_type_to_tsql(t8.system_type_id) AS tsql_base_type_name
 WHERE has_schema_privilege(s1.schema_id, 'USAGE');

GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_special_columns(
 "@table_name" sys.sysname,
 "@table_owner" sys.sysname = '',
 "@qualifier" sys.sysname = '',
 "@col_type" char(1) = 'R',
 "@scope" char(1) = 'T',
 "@nullable" char(1) = 'U',
 "@odbcver" int = 2
)
AS $$
DECLARE @special_col_type sys.sysname;
DECLARE @constraint_name sys.sysname;
BEGIN
 IF (@qualifier != '') AND (LOWER(@qualifier) != LOWER(sys.db_name()))
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;

 END

 IF (LOWER(@col_type) = LOWER('V'))
 BEGIN
  THROW 33557097, N'TIMESTAMP datatype is not currently supported in Babelfish', 1;
 END

 IF (LOWER(@nullable) = LOWER('O'))
 BEGIN
  SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
  WHERE LOWER(@table_name) = LOWER(table_name)
   AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
   AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0)
  ORDER BY constraint_type, index_id;

  IF @special_col_type='u'
  BEGIN
   IF @scope='C'
   BEGIN
    SELECT
    CAST(0 AS smallint) AS SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND @constraint_name = constraint_name
    ORDER BY scope, column_name;

   END
   ELSE
   BEGIN
    SELECT
    SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND @constraint_name = constraint_name
    ORDER BY scope, column_name;
   END

  END

  ELSE
  BEGIN
   IF @scope='C'
   BEGIN
    SELECT
    CAST(0 AS smallint) AS SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND CONSTRAINT_TYPE = 'p'
    ORDER BY scope, column_name;
   END
   ELSE
   BEGIN
    SELECT SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND (is_nullable = 0) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND CONSTRAINT_TYPE = 'p'
    ORDER BY scope, column_name;
   END
  END
 END

 ELSE
 BEGIN
  SELECT TOP 1 @special_col_type = constraint_type, @constraint_name = constraint_name FROM sys.sp_special_columns_view
  WHERE LOWER(@table_name) = LOWER(table_name)
   AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
   AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier))
  ORDER BY constraint_type, index_id;

  IF @special_col_type='u'
  BEGIN
   IF @scope='C'
   BEGIN
    SELECT
    CAST(0 AS smallint) AS SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND @constraint_name = constraint_name
    ORDER BY scope, column_name;
   END

   ELSE
   BEGIN
    SELECT SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND @constraint_name = constraint_name
    ORDER BY scope, column_name;
   END

  END
  ELSE
  BEGIN
   IF @scope='C'
   BEGIN
    SELECT
    CAST(0 AS smallint) AS SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND CONSTRAINT_TYPE = 'p'
    ORDER BY scope, column_name;
   END

   ELSE
   BEGIN
    SELECT SCOPE,
    COLUMN_NAME,
    DATA_TYPE,
    TYPE_NAME,
    PRECISION,
    LENGTH,
    SCALE,
    PSEUDO_COLUMN FROM sys.sp_special_columns_view
    WHERE LOWER(@table_name) = LOWER(table_name)
    AND ((SELECT coalesce(@table_owner,'')) = '' OR LOWER(table_owner) = LOWER(@table_owner))
    AND ((SELECT coalesce(@qualifier,'')) = '' OR LOWER(table_qualifier) = LOWER(@qualifier)) AND LOWER(constraint_type) = LOWER(@special_col_type)
    AND CONSTRAINT_TYPE = 'p'
    ORDER BY scope, column_name;
   END

  END
 END

END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_special_columns_100(
 "@table_name" sys.sysname,
 "@table_owner" sys.sysname = '',
 "@qualifier" sys.sysname = '',
 "@col_type" char(1) = 'R',
 "@scope" char(1) = 'T',
 "@nullable" char(1) = 'U',
 "@odbcver" int = 2
)
AS $$
BEGIN
 EXEC sp_special_columns @table_name, @table_owner, @qualifier, @col_type, @scope, @nullable, @odbcver
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_special_columns_100 TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
-- primary key info
CAST(t2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname COLLATE sys.database_default = ref.table_schema) AS sys.sysname) AS PKTABLE_OWNER,
CAST(ref.table_name AS sys.sysname) AS PKTABLE_NAME,
CAST(coalesce(split_part(pkname_table.attoptions[1] COLLATE "C", '=', 2), ref.column_name) AS sys.sysname) AS PKCOLUMN_NAME,

-- foreign key info
CAST(t2.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST((select orig_name from sys.babelfish_namespace_ext where dbid = sys.db_id() and nspname COLLATE sys.database_default = fk.table_schema) AS sys.sysname) AS FKTABLE_OWNER,
CAST(fk.table_name AS sys.sysname) AS FKTABLE_NAME,
CAST(coalesce(split_part(fkname_table.attoptions[1] COLLATE "C", '=', 2), fk.column_name) AS sys.sysname) AS FKCOLUMN_NAME,

CAST(seq AS smallint) AS KEY_SEQ,
CASE
    WHEN map.update_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.update_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.update_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS UPDATE_RULE,

CASE
    WHEN map.delete_rule = 'NO ACTION' THEN CAST(1 AS smallint)
    WHEN map.delete_rule = 'SET NULL' THEN CAST(2 AS smallint)
    WHEN map.delete_rule = 'SET DEFAULT' THEN CAST(3 AS smallint)
    ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(fk.constraint_name AS sys.sysname) AS FK_NAME,
CAST(ref.constraint_name AS sys.sysname) AS PK_NAME

FROM information_schema.referential_constraints AS map

-- join unique constraints (e.g. PKs constraints) to ref columns info
INNER JOIN information_schema.key_column_usage AS ref
 JOIN pg_catalog.pg_class p1 -- Need to join this in order to get oid for pkey's original bbf name
    JOIN sys.pg_namespace_ext p2 ON p1.relnamespace = p2.oid
    JOIN information_schema.columns p4 ON p1.relname = p4.table_name AND p1.relnamespace::regnamespace::text = p4.table_schema
    JOIN pg_constraint p5 ON p1.oid = p5.conrelid
    ON (p1.relname=ref.table_name AND p4.column_name=ref.column_name AND ref.table_schema = p2.nspname AND ref.table_schema = p4.table_schema)

    ON ref.constraint_catalog = map.unique_constraint_catalog
    AND ref.constraint_schema = map.unique_constraint_schema
    AND ref.constraint_name = map.unique_constraint_name

-- join fk columns to the correct ref columns using ordinal positions
INNER JOIN information_schema.key_column_usage AS fk
    ON fk.constraint_catalog = map.constraint_catalog
    AND fk.constraint_schema = map.constraint_schema
    AND fk.constraint_name = map.constraint_name
    AND fk.position_in_unique_constraint = ref.ordinal_position

INNER JOIN pg_catalog.pg_class t1
    JOIN sys.pg_namespace_ext t2 ON t1.relnamespace = t2.oid
    JOIN information_schema.columns t4 ON t1.relname = t4.table_name AND t1.relnamespace::regnamespace::text = t4.table_schema
    JOIN pg_constraint t5 ON t1.oid = t5.conrelid
    ON (t1.relname=fk.table_name AND t4.column_name=fk.column_name AND fk.table_schema = t2.nspname AND fk.table_schema = t4.table_schema)

-- get foreign key's original bbf name
JOIN pg_catalog.pg_attribute fkname_table
 ON (t1.oid = fkname_table.attrelid) AND (fk.column_name = fkname_table.attname)

-- get primary key's original bbf name
JOIN pg_catalog.pg_attribute pkname_table
 ON (p1.oid = pkname_table.attrelid) AND (ref.column_name = pkname_table.attname)

 , generate_series(1,16) seq -- BBF has max 16 columns per primary key
WHERE t5.contype = 'f'
AND CAST(t4.dtd_identifier AS smallint) = ANY (t5.conkey)
AND CAST(t4.dtd_identifier AS smallint) = t5.conkey[seq];

GRANT SELECT ON sys.sp_fkeys_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_fkeys(
 "@pktable_name" sys.sysname = '',
 "@pktable_owner" sys.sysname = '',
 "@pktable_qualifier" sys.sysname = '',
 "@fktable_name" sys.sysname = '',
 "@fktable_owner" sys.sysname = '',
 "@fktable_qualifier" sys.sysname = ''
)
AS $$
BEGIN

 IF coalesce(@pktable_name,'') = '' AND coalesce(@fktable_name,'') = ''
 BEGIN
  THROW 33557097, N'Primary or foreign key table name must be given.', 1;
 END

 IF (@pktable_qualifier != '' AND (SELECT sys.db_name()) != @pktable_qualifier) OR
  (@fktable_qualifier != '' AND (SELECT sys.db_name()) != @fktable_qualifier)
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
   END

   SELECT
 PKTABLE_QUALIFIER,
 PKTABLE_OWNER,
 PKTABLE_NAME,
 PKCOLUMN_NAME,
 FKTABLE_QUALIFIER,
 FKTABLE_OWNER,
 FKTABLE_NAME,
 FKCOLUMN_NAME,
 KEY_SEQ,
 UPDATE_RULE,
 DELETE_RULE,
 FK_NAME,
 PK_NAME
 FROM sys.sp_fkeys_view
 WHERE ((SELECT coalesce(@pktable_name,'')) = '' OR LOWER(pktable_name) = LOWER(@pktable_name))
  AND ((SELECT coalesce(@fktable_name,'')) = '' OR LOWER(fktable_name) = LOWER(@fktable_name))
  AND ((SELECT coalesce(@pktable_owner,'')) = '' OR LOWER(pktable_owner) = LOWER(@pktable_owner))
  AND ((SELECT coalesce(@pktable_qualifier,'')) = '' OR LOWER(pktable_qualifier) = LOWER(@pktable_qualifier))
  AND ((SELECT coalesce(@fktable_owner,'')) = '' OR LOWER(fktable_owner) = LOWER(@fktable_owner))
  AND ((SELECT coalesce(@fktable_qualifier,'')) = '' OR LOWER(fktable_qualifier) = LOWER(@fktable_qualifier))
 ORDER BY fktable_qualifier, fktable_owner, fktable_name, key_seq;

END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_fkeys TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_stored_procedures_view AS
SELECT
CAST(d.name AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS PROCEDURE_OWNER,

CASE
 WHEN p.prokind = 'p' THEN CAST(concat(p.proname, ';1') AS sys.nvarchar(134))
 ELSE CAST(concat(p.proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_proc p

INNER JOIN sys.schemas s1 ON p.pronamespace = s1.schema_id
INNER JOIN sys.databases d ON d.database_id = sys.db_id()
WHERE has_schema_privilege(s1.schema_id, 'USAGE')

UNION

SELECT CAST((SELECT sys.db_name()) AS sys.sysname) COLLATE sys.database_default AS PROCEDURE_QUALIFIER,
CAST(nspname AS sys.sysname) AS PROCEDURE_OWNER,

CASE
 WHEN prokind = 'p' THEN cast(concat(proname, ';1') AS sys.nvarchar(134))
 ELSE cast(concat(proname, ';0') AS sys.nvarchar(134))
END AS PROCEDURE_NAME,

-1 AS NUM_INPUT_PARAMS,
-1 AS NUM_OUTPUT_PARAMS,
-1 AS NUM_RESULT_SETS,
CAST(NULL AS varchar(254)) COLLATE sys.database_default AS REMARKS,
cast(2 AS smallint) AS PROCEDURE_TYPE

FROM pg_catalog.pg_namespace n
JOIN pg_catalog.pg_proc p
ON pronamespace = n.oid
WHERE nspname = 'sys' AND (proname LIKE 'sp\_%' OR proname LIKE 'xp\_%' OR proname LIKE 'dm\_%' OR proname LIKE 'fn\_%');

GRANT SELECT ON sys.sp_stored_procedures_view TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_stored_procedures(
    "@sp_name" sys.nvarchar(390) = '',
    "@sp_owner" sys.nvarchar(384) = '',
    "@sp_qualifier" sys.sysname = '',
    "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
 IF (@sp_qualifier != '') AND LOWER(sys.db_name()) != LOWER(@sp_qualifier)
 BEGIN
  THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
 END

 -- If @sp_name or @sp_owner = '%', it gets converted to NULL or '' regardless of @fusepattern
 IF @sp_name = '%'
 BEGIN
  SELECT @sp_name = ''
 END

 IF @sp_owner = '%'
 BEGIN
  SELECT @sp_owner = ''
 END

 -- Changes fusepattern to 0 if no wildcards are used. NOTE: Need to add [] wildcard pattern when it is implemented. Wait for BABEL-2452
 IF @fusepattern = 1
 BEGIN
  IF (CHARINDEX('%', @sp_name) != 0 AND CHARINDEX('_', @sp_name) != 0 AND CHARINDEX('%', @sp_owner) != 0 AND CHARINDEX('_', @sp_owner) != 0 )
  BEGIN
   SELECT @fusepattern = 0;
  END
 END

 -- Condition for when sp_name argument is not given or is null, or is just a wildcard (same order)
 IF COALESCE(@sp_name, '') = ''
 BEGIN
  IF @fusepattern=1
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
  ELSE
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
 END
 -- When @sp_name is not null
 ELSE
 BEGIN
  -- When sp_owner is null and fusepattern = 0
  IF (@fusepattern = 0 AND COALESCE(@sp_owner,'') = '')
  BEGIN
   IF EXISTS ( -- Search in the sys schema
     SELECT * FROM sys.sp_stored_procedures_view
     WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
      AND (LOWER(procedure_owner) = 'sys'))
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = 'sys')
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END
   ELSE IF EXISTS (
    SELECT * FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
     )
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = LOWER(SCHEMA_NAME()))
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END
   ELSE -- Search in the dbo schema (if nothing exists it should just return nothing).
   BEGIN
    SELECT PROCEDURE_QUALIFIER,
    PROCEDURE_OWNER,
    PROCEDURE_NAME,
    NUM_INPUT_PARAMS,
    NUM_OUTPUT_PARAMS,
    NUM_RESULT_SETS,
    REMARKS,
    PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
    WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
     AND (LOWER(procedure_owner) = 'dbo')
    ORDER BY procedure_qualifier, procedure_owner, procedure_name;
   END

  END
  ELSE IF (@fusepattern = 0 AND COALESCE(@sp_owner,'') != '')
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE (LOWER(LEFT(procedure_name, -2)) = LOWER(@sp_name))
    AND (LOWER(procedure_owner) = LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
  ELSE -- fusepattern = 1
  BEGIN
   SELECT
   PROCEDURE_QUALIFIER,
   PROCEDURE_OWNER,
   PROCEDURE_NAME,
   NUM_INPUT_PARAMS,
   NUM_OUTPUT_PARAMS,
   NUM_RESULT_SETS,
   REMARKS,
   PROCEDURE_TYPE FROM sys.sp_stored_procedures_view
   WHERE ((SELECT COALESCE(@sp_name,'')) = '' OR LOWER(LEFT(procedure_name, -2)) LIKE LOWER(@sp_name))
    AND ((SELECT COALESCE(@sp_owner,'')) = '' OR LOWER(procedure_owner) LIKE LOWER(@sp_owner))
   ORDER BY procedure_qualifier, procedure_owner, procedure_name;
  END
 END
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_stored_procedures TO PUBLIC;

CREATE OR REPLACE FUNCTION is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME DEFAULT suser_name())
RETURNS INTEGER AS
$$
DECLARE has_role BOOLEAN;
DECLARE login_valid BOOLEAN;
BEGIN
 role := TRIM(trailing from LOWER(role));
 login := TRIM(trailing from LOWER(login));

 login_valid = (login = suser_name()) OR
  (EXISTS (SELECT name
     FROM sys.server_principals
      WHERE
    LOWER(name) = login
    AND type = 'S'));

  IF NOT login_valid THEN
   RETURN NULL;

    ELSIF role = 'public' THEN
     RETURN 1;

  ELSIF role = 'sysadmin' THEN
    has_role = pg_has_role(login::TEXT, role::TEXT, 'MEMBER');
     IF has_role THEN
   RETURN 1;
  ELSE
   RETURN 0;
  END IF;

    ELSIF role IN (
            'serveradmin',
            'securityadmin',
            'setupadmin',
            'securityadmin',
            'processadmin',
            'dbcreator',
            'diskadmin',
            'bulkadmin') THEN
     RETURN 0;

    ELSE
     RETURN NULL;
  END IF;

  EXCEPTION WHEN OTHERS THEN
     RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_helpuser("@name_in_db" sys.SYSNAME = NULL) AS
$$
BEGIN
 -- If security account is not specified, return info about all users
 IF @name_in_db IS NULL
 BEGIN
  SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner'
     WHEN Ext2.orig_username IS NULL THEN 'public'
     ELSE Ext2.orig_username END
     AS SYS.SYSNAME) AS 'RoleName',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
     ELSE Base3.rolname END
     AS SYS.SYSNAME) AS 'LoginName',
      CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
      CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
      CAST(Base1.oid AS INT) AS 'UserID',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
     WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
     ELSE CAST(Base3.oid AS INT) END
     AS SYS.VARBINARY(85)) AS 'SID'
  FROM sys.babelfish_authid_user_ext AS Ext1
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
  LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
  LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
  LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
  WHERE Ext1.database_name = DB_NAME()
  AND Ext1.type = 'S'
  AND Ext1.orig_username != 'db_owner'
  ORDER BY UserName, RoleName;
 END
 -- If the security account is the db fixed role - db_owner
    ELSE IF @name_in_db = 'db_owner'
 BEGIN
  -- TODO: Need to change after we can add/drop members to/from db_owner
  SELECT CAST('db_owner' AS SYS.SYSNAME) AS 'Role_name',
      ROLE_ID('db_owner') AS 'Role_id',
      CAST('dbo' AS SYS.SYSNAME) AS 'Users_in_role',
      USER_ID('dbo') AS 'Userid';
 END
 -- If the security account is a db role
 ELSE IF EXISTS (SELECT 1
     FROM sys.babelfish_authid_user_ext
     WHERE (orig_username = @name_in_db
     OR lower(orig_username) = lower(@name_in_db))
     AND database_name = DB_NAME()
     AND type = 'R')
 BEGIN
  SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'Role_name',
      CAST(Base1.oid AS INT) AS 'Role_id',
      CAST(Ext2.orig_username AS SYS.SYSNAME) AS 'Users_in_role',
      CAST(Base2.oid AS INT) AS 'Userid'
  FROM sys.babelfish_authid_user_ext AS Ext2
  INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.rolname = Ext2.rolname
  INNER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base2.oid = Authmbr.member
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
  LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
  WHERE Ext1.database_name = DB_NAME()
  AND Ext2.database_name = DB_NAME()
  AND Ext1.type = 'R'
  AND Ext2.orig_username != 'db_owner'
  AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
  ORDER BY Role_name, Users_in_role;
 END
 -- If the security account is a user
 ELSE IF EXISTS (SELECT 1
     FROM sys.babelfish_authid_user_ext
     WHERE (orig_username = @name_in_db
     OR lower(orig_username) = lower(@name_in_db))
     AND database_name = DB_NAME()
     AND type = 'S')
 BEGIN
  SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner'
     WHEN Ext2.orig_username IS NULL THEN 'public'
     ELSE Ext2.orig_username END
     AS SYS.SYSNAME) AS 'RoleName',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
     ELSE Base3.rolname END
     AS SYS.SYSNAME) AS 'LoginName',
      CAST(LogExt.default_database_name AS SYS.SYSNAME) AS 'DefDBName',
      CAST(Ext1.default_schema_name AS SYS.SYSNAME) AS 'DefSchemaName',
      CAST(Base1.oid AS INT) AS 'UserID',
      CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN CAST(Base4.oid AS INT)
     WHEN Ext1.orig_username = 'guest' THEN CAST(0 AS INT)
     ELSE CAST(Base3.oid AS INT) END
     AS SYS.VARBINARY(85)) AS 'SID'
  FROM sys.babelfish_authid_user_ext AS Ext1
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.rolname = Ext1.rolname
  LEFT OUTER JOIN pg_catalog.pg_auth_members AS Authmbr ON Base1.oid = Authmbr.member
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.roleid
  LEFT OUTER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  LEFT OUTER JOIN sys.babelfish_authid_login_ext As LogExt ON LogExt.rolname = Ext1.login_name
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base3 ON Base3.rolname = LogExt.rolname
  LEFT OUTER JOIN sys.babelfish_sysdatabases AS Bsdb ON Bsdb.name = DB_NAME()
  LEFT OUTER JOIN pg_catalog.pg_roles AS Base4 ON Base4.rolname = Bsdb.owner
  WHERE Ext1.database_name = DB_NAME()
  AND Ext1.type = 'S'
  AND Ext1.orig_username != 'db_owner'
  AND (Ext1.orig_username = @name_in_db OR lower(Ext1.orig_username) = lower(@name_in_db))
  ORDER BY UserName, RoleName;
 END
 -- If the security account is not valid
 ELSE
  RAISERROR ( 'The name supplied (%s) is not a user, role, or aliased login.', 16, 1, @name_in_db);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE on PROCEDURE sys.sp_helpuser TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helprole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
 -- If role is not specified, return info for all roles in the current db
 IF @rolename IS NULL
 BEGIN
  SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
      CAST(Base.oid AS INT) AS 'RoleId',
      0 AS 'IsAppRole'
  FROM pg_catalog.pg_roles AS Base
  INNER JOIN sys.babelfish_authid_user_ext AS Ext
  ON Base.rolname = Ext.rolname
  WHERE Ext.database_name = DB_NAME()
  AND Ext.type = 'R'
  ORDER BY RoleName;
 END
 -- If a valid role is specified, return its info
 ELSE IF EXISTS (SELECT 1
     FROM sys.babelfish_authid_user_ext
     WHERE (orig_username = @rolename
     OR lower(orig_username) = lower(@rolename))
     AND database_name = DB_NAME()
     AND type = 'R')
 BEGIN
  SELECT CAST(Ext.orig_username AS sys.SYSNAME) AS 'RoleName',
      CAST(Base.oid AS INT) AS 'RoleId',
      0 AS 'IsAppRole'
  FROM pg_catalog.pg_roles AS Base
  INNER JOIN sys.babelfish_authid_user_ext AS Ext
  ON Base.rolname = Ext.rolname
  WHERE Ext.database_name = DB_NAME()
  AND Ext.type = 'R'
  AND (Ext.orig_username = @rolename OR lower(Ext.orig_username) = lower(@rolename))
  ORDER BY RoleName;
 END
 -- If the specified role is not valid
 ELSE
  RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprole TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helprolemember("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
 -- If role is not specified, return info for all roles that have at least
 -- one member in the current db
 IF @rolename IS NULL
 BEGIN
  SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
      CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
      CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
  FROM pg_catalog.pg_auth_members AS Authmbr
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
  INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
  INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
  INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  WHERE Ext1.database_name = DB_NAME()
  AND Ext2.database_name = DB_NAME()
  AND Ext1.type = 'R'
  AND Ext2.orig_username != 'db_owner'
  ORDER BY RoleName, MemberName;
 END
 -- If a valid role is specified, return its member info
 ELSE IF EXISTS (SELECT 1
     FROM sys.babelfish_authid_user_ext
     WHERE (orig_username = @rolename
     OR lower(orig_username) = lower(@rolename))
     AND database_name = DB_NAME()
     AND type = 'R')
 BEGIN
  SELECT CAST(Ext1.orig_username AS sys.SYSNAME) AS 'RoleName',
      CAST(Ext2.orig_username AS sys.SYSNAME) AS 'MemberName',
      CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
  FROM pg_catalog.pg_auth_members AS Authmbr
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
  INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
  INNER JOIN sys.babelfish_authid_user_ext AS Ext1 ON Base1.rolname = Ext1.rolname
  INNER JOIN sys.babelfish_authid_user_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  WHERE Ext1.database_name = DB_NAME()
  AND Ext2.database_name = DB_NAME()
  AND Ext1.type = 'R'
  AND Ext2.orig_username != 'db_owner'
  AND (Ext1.orig_username = @rolename OR lower(Ext1.orig_username) = lower(@rolename))
  ORDER BY RoleName, MemberName;
 END
 -- If the specified role is not valid
 ELSE
  RAISERROR('%s is not a role.', 16, 1, @rolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helprolemember TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpsrvrolemember("@srvrolename" sys.SYSNAME = NULL) AS
$$
BEGIN
 -- If server role is not specified, return info for all server roles
 IF @srvrolename IS NULL
 BEGIN
  SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
      CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
      CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
  FROM pg_catalog.pg_auth_members AS Authmbr
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
  INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
  INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
  INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  WHERE Ext1.type = 'R'
  ORDER BY ServerRole, MemberName;
 END
 -- If a valid server role is specified, return its member info
 -- If the role is a SQL server predefined role (i.e. serveradmin),
 -- do not raise an error even if it does not exist
 ELSE IF EXISTS (SELECT 1
     FROM sys.babelfish_authid_login_ext
     WHERE (rolname = RTRIM(@srvrolename)
     OR lower(rolname) = lower(RTRIM(@srvrolename)))
     AND type = 'R')
     OR lower(RTRIM(@srvrolename)) IN (
     'serveradmin', 'setupadmin', 'securityadmin', 'processadmin',
     'dbcreator', 'diskadmin', 'bulkadmin')
 BEGIN
  SELECT CAST(Ext1.rolname AS sys.SYSNAME) AS 'ServerRole',
      CAST(Ext2.rolname AS sys.SYSNAME) AS 'MemberName',
      CAST(CAST(Base2.oid AS INT) AS sys.VARBINARY(85)) AS 'MemberSID'
  FROM pg_catalog.pg_auth_members AS Authmbr
  INNER JOIN pg_catalog.pg_roles AS Base1 ON Base1.oid = Authmbr.roleid
  INNER JOIN pg_catalog.pg_roles AS Base2 ON Base2.oid = Authmbr.member
  INNER JOIN sys.babelfish_authid_login_ext AS Ext1 ON Base1.rolname = Ext1.rolname
  INNER JOIN sys.babelfish_authid_login_ext AS Ext2 ON Base2.rolname = Ext2.rolname
  WHERE Ext1.type = 'R'
  AND (Ext1.rolname = RTRIM(@srvrolename) OR lower(Ext1.rolname) = lower(RTRIM(@srvrolename)))
  ORDER BY ServerRole, MemberName;
 END
 -- If the specified server role is not valid
 ELSE
  RAISERROR('%s is not a known fixed role.', 16, 1, @srvrolename);
END;
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpsrvrolemember TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_helpdbfixedrole("@rolename" sys.SYSNAME = NULL) AS
$$
BEGIN
 -- Returns a list of the fixed database roles.
 -- Only fixed role present in babelfish is db_owner.
 IF LOWER(RTRIM(@rolename)) IS NULL OR LOWER(RTRIM(@rolename)) = 'db_owner'
 BEGIN
  SELECT CAST('db_owner' AS sys.SYSNAME) AS DbFixedRole, CAST('DB Owners' AS sys.nvarchar(70)) AS Description;
 END
 ELSE IF LOWER(RTRIM(@rolename)) IN (
   'db_accessadmin','db_securityadmin','db_ddladmin', 'db_backupoperator',
   'db_datareader', 'db_datawriter', 'db_denydatareader', 'db_denydatawriter')
 BEGIN
  -- Return an empty result set instead of raising an error
  SELECT CAST(NULL AS sys.SYSNAME) AS DbFixedRole, CAST(NULL AS sys.nvarchar(70)) AS Description
  WHERE 1=0;
 END
 ELSE
  RAISERROR('''%s'' is not a known fixed role.', 16, 1, @rolename);
END
$$
LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_helpdbfixedrole TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_sproc_columns_view
AS
SELECT
CAST(sys.db_name() AS sys.sysname) AS PROCEDURE_QUALIFIER -- This will always be objects in current database
, CAST(ss.schema_name AS sys.sysname) AS PROCEDURE_OWNER
, CAST(
CASE
  WHEN ss.prokind = 'p' THEN CONCAT(ss.proname, ';1')
  ELSE CONCAT(ss.proname, ';0')
END
AS sys.nvarchar(134)) AS PROCEDURE_NAME
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN '@TABLE_RETURN_VALUE'
    ELSE '@RETURN_VALUE'
  END
ELSE COALESCE(ss.proargnames[n], '')
END
AS sys.SYSNAME) AS COLUMN_NAME
, CAST(
CASE
WHEN ss.n IS NULL THEN
  CASE
    WHEN ss.proretset THEN 3
    ELSE 5
  END
WHEN ss.proargmodes[n] in ('o', 'b') THEN 2
ELSE 1
END
AS smallint) AS COLUMN_TYPE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.prokind = 'p' THEN (SELECT data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int')
    WHEN ss.proretset THEN NULL
    ELSE sdit.data_type
    END
  WHEN st.is_table_type = 1 THEN -153
  ELSE sdit.data_type
END
AS smallint) AS DATA_TYPE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 'table'
      WHEN ss.prokind = 'p' THEN 'int'
      ELSE st.name
    END
  ELSE st.name
END
AS sys.sysname) AS TYPE_NAME
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
    WHEN ss.prokind = 'p' THEN (SELECT precision FROM sys.types WHERE name = 'int')
    ELSE st.precision
  END
  WHEN st.is_table_type = 1 THEN 0
  ELSE st.precision
END
AS sys.int) AS PRECISION
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
    WHEN ss.prokind = 'p' THEN (SELECT max_length FROM sys.types WHERE name = 'int')
    ELSE st.max_length
  END
  WHEN st.is_table_type = 1 THEN 2147483647
  ELSE st.max_length
END
AS sys.int) AS LENGTH
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
      WHEN ss.prokind = 'p' THEN (SELECT scale FROM sys.types WHERE name = 'int')
      ELSE st.scale
    END
  WHEN st.is_table_type = 1 THEN NULL
  ELSE st.scale
END
AS smallint) AS SCALE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
    WHEN ss.prokind = 'p' THEN (SELECT num_prec_radix FROM sys.spt_datatype_info_table WHERE type_name = 'int')
    ELSE sdit.num_prec_radix
  END
  WHEN st.is_table_type = 1 THEN NULL
  ELSE sdit.num_prec_radix
END
AS smallint) AS RADIX
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset OR ss.prokind = 'p' THEN 0
      ELSE sdit.nullable
    END
  WHEN st.is_table_type = 1 THEN 1
  ELSE sdit.nullable
END
AS smallint) AS NULLABLE
, CAST(
CASE
  WHEN ss.n IS NULL AND ss.proretset THEN 'Result table returned by table valued function'
  ELSE NULL
END
AS sys.varchar(254)) COLLATE sys.database_default AS REMARKS
, CAST(NULL AS sys.nvarchar(4000)) AS COLUMN_DEF
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN NULL
      WHEN ss.prokind = 'p' THEN (SELECT sql_data_type FROM sys.spt_datatype_info_table WHERE type_name = 'int')
      ELSE sdit.sql_data_type
    END
  WHEN st.is_table_type = 1 THEN -153
  ELSE sdit.sql_data_type
END
AS smallint) AS SQL_DATA_TYPE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
      WHEN ss.prokind = 'p' THEN (SELECT sql_datetime_sub FROM sys.spt_datatype_info_table WHERE type_name = 'int')
      ELSE sdit.sql_datetime_sub
    END
  ELSE sdit.sql_datetime_sub
END
AS smallint) AS SQL_DATETIME_SUB
, CAST(
CASE
  WHEN ss.n IS NOT NULL AND st.is_table_type = 1 THEN 2147483647
  ELSE NULL
END
AS sys.int) AS CHAR_OCTET_LENGTH
, CAST(
CASE
  WHEN ss.n IS NULL THEN 0
  ELSE n
END
AS sys.int) AS ORDINAL_POSITION
, CAST(
CASE
  WHEN ss.n IS NULL AND ss.proretset THEN 'NO'
  WHEN st.is_table_type = 1 THEN 'YES'
  WHEN sdit.nullable = 1 THEN 'YES'
  ELSE 'NO'
END
AS sys.varchar(254)) COLLATE sys.database_default AS IS_NULLABLE
, CAST(
CASE
  WHEN ss.n IS NULL THEN
    CASE
      WHEN ss.proretset THEN 0
      WHEN ss.prokind = 'p' THEN 56
      ELSE sdit.ss_data_type
    END
  WHEN st.is_table_type = 1 THEN 0
  ELSE sdit.ss_data_type
END
AS sys.tinyint) AS SS_DATA_TYPE
, CAST(ss.proname AS sys.sysname) AS original_procedure_name
FROM
(
  -- CTE to query procedures related to bbf
  WITH bbf_proc AS (
    SELECT
      p.proname as proname,
      p.proargnames as proargnames,
      p.proargmodes as proargmodes,
      p.prokind as prokind,
      p.proretset as proretset,
      p.prorettype as prorettype,
      p.proallargtypes as proallargtypes,
      p.proargtypes as proargtypes,
      s.name as schema_name
    FROM
      pg_proc p
    INNER JOIN (
      SELECT name as name, schema_id as id FROM sys.schemas
      UNION ALL
      SELECT CAST(nspname as sys.sysname) as name, CAST(oid as int) as id
        from pg_namespace WHERE nspname in ('sys', 'information_schema')
    ) as s ON p.pronamespace = s.id
    WHERE (
      (pg_has_role(p.proowner, 'USAGE') OR has_function_privilege(p.oid, 'EXECUTE'))
      AND (s.name != 'sys'
        OR p.proname like 'sp\_%' -- filter out internal babelfish-specific procs in sys schema
        OR p.proname like 'xp\_%'
        OR p.proname like 'dm\_%'
        OR p.proname like 'fn\_%'))
  )

  SELECT *
  FROM (
    SELECT -- Selects all parameters (input and output), but NOT return values
    p.proname as proname,
    p.proargnames as proargnames,
    p.proargmodes as proargmodes,
    p.prokind as prokind,
    p.proretset as proretset,
    p.prorettype as prorettype,
    p.schema_name as schema_name,
    (information_schema._pg_expandarray(
    COALESCE(p.proallargtypes,
      CASE
        WHEN p.prokind = 'f' THEN (CAST(p.proargtypes AS oid[]))
        ELSE CAST(p.proargtypes AS oid[])
      END
    ))).x AS x,
    (information_schema._pg_expandarray(
    COALESCE(p.proallargtypes,
      CASE
        WHEN p.prokind = 'f' THEN (CAST(p.proargtypes AS oid[]))
        ELSE CAST(p.proargtypes AS oid[])
      END
    ))).n AS n
    FROM bbf_proc p) AS t
  WHERE (t.proargmodes[t.n] in ('i', 'o', 'b') OR t.proargmodes is NULL)

  UNION ALL

  SELECT -- Selects all return values (this is because inline-table functions could cause duplicate outputs)
  p.proname as proname,
  p.proargnames as proargnames,
  p.proargmodes as proargmodes,
  p.prokind as prokind,
  p.proretset as proretset,
  p.prorettype as prorettype,
  p.schema_name as schema_name,
  p.prorettype AS x,
  NULL AS n -- null value indicates that we are retrieving the return values of the proc/func
  FROM bbf_proc p
) ss
LEFT JOIN sys.types st ON ss.x = st.user_type_id -- left join'd because return type of table-valued functions may not have an entry in sys.types
-- Because spt_datatype_info_table does contain user-defind types and their names,
-- the join below allows us to retrieve the name of the base type of the user-defined type
LEFT JOIN sys.spt_datatype_info_table sdit ON sdit.type_name = sys.translate_pg_type_to_tsql(st.system_type_id);
GRANT SELECT ON sys.sp_sproc_columns_view TO PUBLIC;


CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns(
 "@procedure_name" sys.nvarchar(390) = '%',
 "@procedure_owner" sys.nvarchar(384) = NULL,
 "@procedure_qualifier" sys.sysname = NULL,
 "@column_name" sys.nvarchar(384) = NULL,
 "@odbcver" int = 2,
 "@fusepattern" sys.bit = '1'
)
AS $$
 SELECT @procedure_name = LOWER(COALESCE(@procedure_name, ''))
 SELECT @procedure_owner = LOWER(COALESCE(@procedure_owner, ''))
 SELECT @procedure_qualifier = LOWER(COALESCE(@procedure_qualifier, ''))
 SELECT @column_name = LOWER(COALESCE(@column_name, ''))
BEGIN
 IF (@procedure_qualifier != '' AND (SELECT LOWER(sys.db_name())) != @procedure_qualifier)
  BEGIN
   THROW 33557097, N'The database name component of the object qualifier must be the name of the current database.', 1;
      END
 IF @fusepattern = '1'
  BEGIN
   SELECT PROCEDURE_QUALIFIER,
     PROCEDURE_OWNER,
     PROCEDURE_NAME,
     COLUMN_NAME,
     COLUMN_TYPE,
     DATA_TYPE,
     TYPE_NAME,
     PRECISION,
     LENGTH,
     SCALE,
     RADIX,
     NULLABLE,
     REMARKS,
     COLUMN_DEF,
     SQL_DATA_TYPE,
     SQL_DATETIME_SUB,
     CHAR_OCTET_LENGTH,
     ORDINAL_POSITION,
     IS_NULLABLE,
     SS_DATA_TYPE
   FROM sys.sp_sproc_columns_view
   WHERE (@procedure_name = '' OR original_procedure_name LIKE @procedure_name)
    AND (@procedure_owner = '' OR procedure_owner LIKE @procedure_owner)
    AND (@column_name = '' OR column_name LIKE @column_name)
    AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
   ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
  END
 ELSE
  BEGIN
   SELECT PROCEDURE_QUALIFIER,
     PROCEDURE_OWNER,
     PROCEDURE_NAME,
     COLUMN_NAME,
     COLUMN_TYPE,
     DATA_TYPE,
     TYPE_NAME,
     PRECISION,
     LENGTH,
     SCALE,
     RADIX,
     NULLABLE,
     REMARKS,
     COLUMN_DEF,
     SQL_DATA_TYPE,
     SQL_DATETIME_SUB,
     CHAR_OCTET_LENGTH,
     ORDINAL_POSITION,
     IS_NULLABLE,
     SS_DATA_TYPE
   FROM sys.sp_sproc_columns_view
   WHERE (@procedure_name = '' OR original_procedure_name = @procedure_name)
    AND (@procedure_owner = '' OR procedure_owner = @procedure_owner)
    AND (@column_name = '' OR column_name = @column_name)
    AND (@procedure_qualifier = '' OR procedure_qualifier = @procedure_qualifier)
   ORDER BY procedure_qualifier, procedure_owner, procedure_name, ordinal_position;
  END
END;
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_sproc_columns_100(
 "@procedure_name" sys.nvarchar(390) = '%',
 "@procedure_owner" sys.nvarchar(384) = NULL,
 "@procedure_qualifier" sys.sysname = NULL,
 "@column_name" sys.nvarchar(384) = NULL,
 "@odbcver" int = 2,
 "@fusepattern" sys.bit = '1'
)
AS $$
BEGIN
    exec sys.sp_sproc_columns @procedure_name, @procedure_owner, @procedure_qualifier, @column_name, @odbcver, @fusepattern;
END;
$$
LANGUAGE 'pltsql';
GRANT ALL ON PROCEDURE sys.sp_sproc_columns_100 TO PUBLIC;
-- 24 "sql/babelfishpg_tsql.in" 2






SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
RESET client_min_messages;
