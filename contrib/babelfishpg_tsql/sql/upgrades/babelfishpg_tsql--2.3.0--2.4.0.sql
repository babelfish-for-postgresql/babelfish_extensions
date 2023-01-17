-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.4.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(
	object_type varchar, schema_name varchar, object_name varchar
) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := format('drop %s %s.%s', object_type, schema_name, object_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view/function/procedure' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;


-- please add your SQL here
CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 INT)
RETURNS int AS 'babelfishpg_tsql','int_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 SMALLINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 TINYINT)
RETURNS int AS 'babelfishpg_tsql','smallint_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(TINYINT) TO PUBLIC;

CREATE OR REPLACE VIEW sys.partitions AS
SELECT
 (to_char( i.object_id, 'FM9999999999' ) || to_char( i.index_id, 'FM9999999999' ) || '1')::bigint AS partition_id
 , i.object_id
 , i.index_id
 , 1::integer AS partition_number
 , 0::bigint AS hobt_id
 , c.reltuples::bigint AS "rows"
 , 0::smallint AS filestream_filegroup_id
 , 0::sys.tinyint AS data_compression
 , 'NONE'::sys.nvarchar(60) AS data_compression_desc
FROM sys.indexes AS i
INNER JOIN pg_catalog.pg_class AS c ON i.object_id = c."oid";
GRANT SELECT ON sys.partitions TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.atn2(IN x SYS.FLOAT, IN y SYS.FLOAT) RETURNS SYS.FLOAT
AS
$$
DECLARE
    res SYS.FLOAT;
BEGIN
    IF x = 0 AND y = 0 THEN
        RAISE EXCEPTION 'An invalid floating point operation occurred.';
    ELSE
        res = PG_CATALOG.atan2(x, y);
        RETURN res;
    END IF;
END;
$$
LANGUAGE plpgsql PARALLEL SAFE IMMUTABLE RETURNS NULL ON NULL INPUT;


CREATE OR REPLACE FUNCTION sys.APP_NAME() RETURNS SYS.NVARCHAR(128)
AS
$$
    SELECT current_setting('application_name');
$$
LANGUAGE sql PARALLEL SAFE STABLE;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 INT)
RETURNS int  AS 'babelfishpg_tsql','int_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 BIGINT)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(BIGINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 SMALLINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 TINYINT)
RETURNS int  AS 'babelfishpg_tsql','smallint_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(TINYINT) TO PUBLIC;

CREATE OR REPLACE VIEW information_schema_tsql.SEQUENCES AS
    SELECT CAST(nc.dbname AS sys.nvarchar(128)) AS "SEQUENCE_CATALOG",
            CAST(extc.orig_name AS sys.nvarchar(128)) AS "SEQUENCE_SCHEMA",
            CAST(r.relname AS sys.nvarchar(128)) AS "SEQUENCE_NAME",
            CAST(CASE WHEN tsql_type_name = 'sysname' THEN sys.translate_pg_type_to_tsql(t.typbasetype) ELSE tsql_type_name END
                    AS sys.nvarchar(128))AS "DATA_TYPE",  -- numeric and decimal data types are converted into bigint which is due to Postgres inherent implementation
            CAST(information_schema_tsql._pgtsql_numeric_precision(tsql_type_name, t.oid, -1)
                        AS smallint) AS "NUMERIC_PRECISION",
            CAST(information_schema_tsql._pgtsql_numeric_precision_radix(tsql_type_name, case when t.typtype = 'd' THEN t.typbasetype ELSE t.oid END, -1)
                        AS smallint) AS "NUMERIC_PRECISION_RADIX",
            CAST(information_schema_tsql._pgtsql_numeric_scale(tsql_type_name, t.oid, -1)
                        AS int) AS "NUMERIC_SCALE",
            CAST(s.seqstart AS sys.sql_variant) AS "START_VALUE",
            CAST(s.seqmin AS sys.sql_variant) AS "MINIMUM_VALUE",
            CAST(s.seqmax AS sys.sql_variant) AS "MAXIMUM_VALUE",
            CAST(s.seqincrement AS sys.sql_variant) AS "INCREMENT",
            CAST( CASE WHEN s.seqcycle = 't' THEN 1 ELSE 0 END AS int) AS "CYCLE_OPTION",
            CAST(NULL AS sys.nvarchar(128)) AS "DECLARED_DATA_TYPE",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_PRECISION",
            CAST(NULL AS int) AS "DECLARED_NUMERIC_SCALE"
        FROM sys.pg_namespace_ext nc JOIN sys.babelfish_namespace_ext extc ON nc.nspname = extc.nspname,
            pg_sequence s join pg_class r on s.seqrelid = r.oid join pg_type t on s.seqtypid=t.oid,
            sys.translate_pg_type_to_tsql(s.seqtypid) AS tsql_type_name
        WHERE nc.oid = r.relnamespace
        AND extc.dbid = cast(sys.db_id() as oid)
            AND r.relkind = 'S'
            AND (NOT pg_is_other_temp_schema(nc.oid))
            AND (pg_has_role(r.relowner, 'USAGE')
                OR has_sequence_privilege(r.oid, 'SELECT, UPDATE, USAGE'));

GRANT SELECT ON information_schema_tsql.SEQUENCES TO PUBLIC;

CREATE or replace VIEW sys.check_constraints AS
SELECT CAST(c.conname as sys.sysname) as name
  , CAST(oid as integer) as object_id
  , CAST(NULL as integer) as principal_id 
  , CAST(c.connamespace as integer) as schema_id
  , CAST(conrelid as integer) as parent_object_id
  , CAST('C' as char(2)) as type
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
  , CAST(tsql_get_constraintdef(c.oid) as sys.nvarchar(4000)) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

/* set sys functions as STABLE */
ALTER FUNCTION sys.schema_id() STABLE;
ALTER FUNCTION sys.schema_name() STABLE;
ALTER FUNCTION sys.sp_columns_100_internal(
	in_table_name sys.nvarchar(384),
    in_table_owner sys.nvarchar(384), 
    in_table_qualifier sys.nvarchar(384),
    in_column_name sys.nvarchar(384),
	in_NameScope int,
    in_ODBCVer int,
    in_fusepattern smallint)
STABLE;
ALTER FUNCTION sys.sp_columns_managed_internal(
    in_catalog sys.nvarchar(128), 
    in_owner sys.nvarchar(128),
    in_table sys.nvarchar(128),
    in_column sys.nvarchar(128),
    in_schematype int)
STABLE;
ALTER FUNCTION sys.sp_pkeys_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384),
	in_table_qualifier sys.nvarchar(384)
)
STABLE;
ALTER FUNCTION sys.sp_statistics_internal(
    in_table_name sys.sysname,
    in_table_owner sys.sysname,
    in_table_qualifier sys.sysname,
    in_index_name sys.sysname,
	in_is_unique char,
	in_accuracy char
)
STABLE;
ALTER FUNCTION sys.sp_tables_internal(
	in_table_name sys.nvarchar(384),
	in_table_owner sys.nvarchar(384), 
	in_table_qualifier sys.sysname,
	in_table_type sys.varchar(100),
	in_fusepattern sys.bit)
STABLE;
ALTER FUNCTION sys.trigger_nestlevel() STABLE;
ALTER FUNCTION sys.proc_param_helper() STABLE;
ALTER FUNCTION sys.original_login() STABLE; 
ALTER FUNCTION sys.objectproperty(id INT, property SYS.VARCHAR) STABLE;
ALTER FUNCTION sys.OBJECTPROPERTYEX(id INT, property SYS.VARCHAR) STABLE;
ALTER FUNCTION sys.num_days_in_date(IN d1 INTEGER, IN m1 INTEGER, IN y1 INTEGER) STABLE;
ALTER FUNCTION sys.nestlevel() STABLE;
ALTER FUNCTION sys.max_connections() STABLE;
ALTER FUNCTION sys.lock_timeout() STABLE;
ALTER FUNCTION sys.json_modify(in expression sys.NVARCHAR,in path_json TEXT, in new_value TEXT) STABLE;
ALTER FUNCTION sys.isnumeric(IN expr ANYELEMENT) STABLE;
ALTER FUNCTION sys.isnumeric(IN expr TEXT) STABLE;
ALTER FUNCTION sys.isdate(v text) STABLE;
ALTER FUNCTION sys.is_srvrolemember(role sys.SYSNAME, login sys.SYSNAME) STABLE;
ALTER FUNCTION sys.INDEXPROPERTY(IN object_id INT, IN index_or_statistics_name sys.nvarchar(128), IN property sys.varchar(128)) STABLE;
ALTER FUNCTION sys.has_perms_by_name(
    securable SYS.SYSNAME, 
    securable_class SYS.NVARCHAR(60), 
    permission SYS.SYSNAME,
    sub_securable SYS.SYSNAME,
    sub_securable_class SYS.NVARCHAR(60)
)
STABLE;
ALTER FUNCTION sys.fn_listextendedproperty (
property_name varchar(128),
level0_object_type varchar(128),
level0_object_name varchar(128),
level1_object_type varchar(128),
level1_object_name varchar(128),
level2_object_type varchar(128),
level2_object_name varchar(128)
)
STABLE;
ALTER FUNCTION sys.fn_helpcollations() STABLE;
ALTER FUNCTION sys.DBTS() STABLE;
ALTER FUNCTION sys.columns_internal() STABLE;
ALTER FUNCTION sys.columnproperty(object_id oid, property name, property_name text) STABLE;
ALTER FUNCTION sys.babelfish_get_id_by_name(object_name text) STABLE;
ALTER FUNCTION sys.babelfish_get_sequence_value(in sequence_name character varying) STABLE;
ALTER FUNCTION sys.babelfish_conv_date_to_string(IN p_datatype TEXT, IN p_dateval DATE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_datetime_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_datetimeval TIMESTAMP(6) WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_dateval DATE) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day NUMERIC, IN p_month NUMERIC, IN p_year NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_day TEXT, IN p_month TEXT, IN p_year TEXT) STABLE;
ALTER FUNCTION sys.babelfish_conv_greg_to_hijri(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_dateval DATE) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day NUMERIC, IN p_month NUMERIC, IN p_year NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day TEXT, IN p_month TEXT, IN p_year TEXT) STABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_date(IN p_datestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_string_to_time(IN p_datatype TEXT, IN p_timestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_time_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_timeval TIME(6) WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_dbts() STABLE;
ALTER FUNCTION sys.babelfish_get_jobs() STABLE;
ALTER FUNCTION sys.babelfish_get_lang_metadata_json(IN p_lang_spec_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_service_setting ( IN p_service sys.service_settings.service%TYPE , IN p_setting sys.service_settings.setting%TYPE ) STABLE;
ALTER FUNCTION sys.babelfish_get_version(pComponentName VARCHAR(256)) STABLE;
ALTER FUNCTION sys.babelfish_is_ossp_present() STABLE;
ALTER FUNCTION sys.babelfish_is_spatial_present() STABLE;
ALTER FUNCTION sys.babelfish_istime(v text) STABLE;
ALTER FUNCTION babelfish_remove_delimiter_pair(IN name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_openxml(IN DocHandle BIGINT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_date(IN p_datestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_to_time(IN p_datatype TEXT, IN p_srctimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_ROUND3(x in numeric, y in int, z in int) STABLE;
ALTER FUNCTION sys.babelfish_sp_aws_add_jobschedule (par_job_id integer, par_schedule_id integer, out returncode integer) STABLE;
ALTER FUNCTION sys.babelfish_sp_aws_del_jobschedule (par_job_id integer, par_schedule_id integer, out returncode integer )STABLE;
ALTER FUNCTION sys.babelfish_sp_schedule_to_cron (par_job_id integer, par_schedule_id integer, out cron_expression varchar )STABLE;
ALTER FUNCTION sys.babelfish_sp_sequence_get_range(
  in par_sequence_name text,
  in par_range_size bigint,
  out par_range_first_value bigint,
  out par_range_last_value bigint,
  out par_range_cycle_count bigint,
  out par_sequence_increment bigint,
  out par_sequence_min_value bigint,
  out par_sequence_max_value bigint
)  
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job (
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
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_date (par_date integer, par_date_name varchar, out returncode integer) STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_job_name varchar,
  inout par_job_id integer,
  par_sqlagent_starting_test varchar,
  inout par_owner_sid char,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_job_time (
  par_time integer,
  par_time_name varchar,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_jobstep (
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
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_schedule (
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
STABLE;
ALTER FUNCTION sys.babelfish_sp_verify_schedule_identifiers (
  par_name_of_name_parameter varchar,
  par_name_of_id_parameter varchar,
  inout par_schedule_name varchar,
  inout par_schedule_id integer,
  inout par_owner_sid char,
  inout par_orig_server_id integer,
  par_job_id_filter integer,
  out returncode integer
)
STABLE;
ALTER FUNCTION sys.babelfish_STRPOS3(p_str text, p_substr text, p_loc int) STABLE;
ALTER FUNCTION sys.babelfish_tomsbit(in_str NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_tomsbit(in_str VARCHAR) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_date_to_string(IN p_datatype TEXT, IN p_dateval DATE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_datetime_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_date(IN p_datestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_string_to_time(IN p_datatype TEXT, IN p_timestring TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_time_to_string(IN p_datatype TEXT, IN p_src_datatype TEXT, IN p_timeval TIME WITHOUT TIME ZONE, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_date(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_date(IN arg anyelement, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_date(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_time(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_time(IN arg anyelement, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_time(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg TEXT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT, IN arg ANYELEMENT, IN try BOOL, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT, IN arg TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT, IN arg TEXT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT, IN arg anyelement, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_date(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_time(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_parse_helper_to_datetime(IN arg TEXT, IN try BOOL, IN culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_money_to_string(IN p_datatype TEXT, IN p_moneyval PG_CATALOG.MONEY, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_conv_float_to_string(IN p_datatype TEXT, IN p_floatval FLOAT, IN p_style NUMERIC) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_date(IN p_datestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_datetime(IN p_datatype TEXT, IN p_datetimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION sys.babelfish_try_parse_to_time(IN p_datatype TEXT, IN p_srctimestring TEXT, IN p_culture TEXT) STABLE;
ALTER FUNCTION babelfish_get_name_delimiter_pos(name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_split_object_name(name TEXT, OUT db_name TEXT, OUT schema_name TEXT, OUT object_name TEXT) STABLE;
ALTER FUNCTION sys.babelfish_has_any_privilege(userid oid, perm_target_type text, schema_name text, object_name text) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_smallint(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_int(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_bigint(IN arg TEXT) STABLE;
ALTER FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT) STABLE;
ALTER FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg TEXT, IN typmod INTEGER) STABLE;
ALTER FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg ANYELEMENT, IN typmod INTEGER) STABLE;
ALTER FUNCTION sys.sysdatetimeoffset() STABLE;
ALTER FUNCTION sys.sysutcdatetime() STABLE;
ALTER FUNCTION sys.getdate() STABLE;
ALTER FUNCTION sys.GETUTCDATE() STABLE;
ALTER FUNCTION sys.isnull(text,text) STABLE;
ALTER FUNCTION sys.isnull(boolean,boolean) STABLE;
ALTER FUNCTION sys.isnull(smallint,smallint) STABLE;
ALTER FUNCTION sys.isnull(integer,integer) STABLE;
ALTER FUNCTION sys.isnull(bigint,bigint) STABLE;
ALTER FUNCTION sys.isnull(real,real) STABLE;
ALTER FUNCTION sys.isnull(double precision, double precision) STABLE;
ALTER FUNCTION sys.isnull(numeric,numeric) STABLE;
ALTER FUNCTION sys.isnull(date, date) STABLE;
ALTER FUNCTION sys.isnull(timestamp,timestamp) STABLE;
ALTER FUNCTION sys.isnull(timestamp with time zone,timestamp with time zone) STABLE;
ALTER FUNCTION sys.is_table_type(object_id oid) STABLE;
ALTER FUNCTION sys.rand() STABLE;
ALTER FUNCTION sys.spid() STABLE;
ALTER FUNCTION sys.APPLOCK_MODE(IN "@dbprincipal" varchar(32), IN "@resource" varchar(255), IN "@lockowner" varchar(32)) STABLE;
ALTER FUNCTION sys.APPLOCK_TEST(IN "@dbprincipal" varchar(32), IN "@resource" varchar(255), IN "@lockmode" varchar(32), IN "@lockowner" varchar(32)) STABLE;
ALTER FUNCTION sys.has_dbaccess(database_name SYSNAME) STABLE;
ALTER FUNCTION sys.language() STABLE;
ALTER FUNCTION sys.rowcount() STABLE;
ALTER FUNCTION sys.error() STABLE;
ALTER FUNCTION sys.pgerror() STABLE;
ALTER FUNCTION sys.trancount() STABLE;
ALTER FUNCTION sys.datefirst() STABLE;
ALTER FUNCTION sys.options() STABLE;
ALTER FUNCTION sys.version() STABLE;
ALTER FUNCTION sys.servername() STABLE;
ALTER FUNCTION sys.servicename() STABLE;
ALTER FUNCTION sys.fetch_status() STABLE;
ALTER FUNCTION sys.cursor_rows() STABLE;
ALTER FUNCTION sys.cursor_status(text, text) STABLE;
ALTER FUNCTION sys.xact_state() STABLE;
ALTER FUNCTION sys.error_line() STABLE;
ALTER FUNCTION sys.error_message() STABLE;
ALTER FUNCTION sys.error_number() STABLE;
ALTER FUNCTION sys.error_procedure() STABLE;
ALTER FUNCTION sys.error_severity() STABLE;
ALTER FUNCTION sys.error_state() STABLE;
ALTER FUNCTION sys.babelfish_get_identity_param(IN tablename TEXT, IN optionname TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_identity_current(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.babelfish_get_login_default_db(IN login_name TEXT) STABLE;
-- internal table function for querying the registered ENRs
ALTER FUNCTION sys.babelfish_get_enr_list() STABLE;
-- internal table function for collation_list
ALTER FUNCTION sys.babelfish_collation_list() STABLE;
-- internal table function for sp_cursor_list and sp_decribe_cursor
ALTER FUNCTION sys.babelfish_cursor_list(cursor_source integer) STABLE;
-- internal table function for sp_helpdb with no arguments
ALTER FUNCTION sys.babelfish_helpdb() STABLE;
-- internal table function for helpdb with dbname as input
ALTER FUNCTION sys.babelfish_helpdb(varchar) STABLE;

ALTER FUNCTION sys.babelfish_inconsistent_metadata(return_consistency boolean) STABLE;
ALTER FUNCTION COLUMNS_UPDATED () STABLE;
ALTER FUNCTION sys.ident_seed(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.ident_incr(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.ident_current(IN tablename TEXT) STABLE;
ALTER FUNCTION sys.babelfish_waitfor_delay(time_to_pass TEXT) STABLE;
ALTER FUNCTION sys.babelfish_waitfor_delay(time_to_pass TIMESTAMP WITHOUT TIME ZONE) STABLE;
ALTER FUNCTION sys.user_name_sysname() STABLE;
ALTER FUNCTION sys.system_user() STABLE;
ALTER FUNCTION sys.session_user() STABLE;
ALTER FUNCTION UPDATE (TEXT) STABLE;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
