-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.0.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- Created to to fetch default collation Oid which is being used to set collation of system objects
CREATE OR REPLACE FUNCTION sys.babelfishpg_tsql_get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_tsql', 'get_server_collation_oid';

-- Set the collation of given schema_name.table_name.column_name column to default collation
CREATE OR REPLACE PROCEDURE sys.babelfish_update_collation_to_default(schema_name varchar, table_name varchar, column_name varchar) AS
$$
DECLARE
    sys_schema oid;
    table_oid oid;
    att_coll oid;
    default_coll_oid oid;
    c_coll_oid oid;
BEGIN
    select oid into default_coll_oid from pg_collation where collname = 'default';
    select oid into c_coll_oid from pg_collation where collname = 'C';
    select oid into sys_schema from pg_namespace where nspname = schema_name collate sys.database_default;
    select oid into table_oid from pg_class where relname = table_name collate sys.database_default and relnamespace = sys_schema;
    select attcollation into att_coll from pg_attribute where attname = column_name collate sys.database_default and attrelid = table_oid;
    if att_coll = default_coll_oid or att_coll = c_coll_oid then
        update pg_attribute set attcollation = sys.babelfishpg_tsql_get_babel_server_collation_oid() where attname = column_name collate sys.database_default and attrelid = table_oid;
    end if;
END
$$
LANGUAGE plpgsql;

-- please add your SQL here

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
EXCEPTION WHEN invalid_parameter_value or feature_not_supported THEN
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

CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_name'
LANGUAGE C STABLE;

CALL sys.babelfish_update_collation_to_default('sys', 'babelfish_authid_user_ext_login_db_idx', 'database_name');
-- we have to reindex babelfish_authid_user_ext_login_db_idx because given index includes database_name and we have to change its collation
REINDEX INDEX sys.babelfish_authid_user_ext_login_db_idx;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
DROP PROCEDURE sys.babelfish_update_collation_to_default(varchar, varchar, varchar);
DROP FUNCTION  sys.babelfishpg_tsql_get_babel_server_collation_oid();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);