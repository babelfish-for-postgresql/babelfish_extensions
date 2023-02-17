-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.1.0'" to load this file. \quit

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

-- Removes a member object from the extension. The object is not dropped, only disassociated from the extension.
-- It is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
CREATE OR REPLACE PROCEDURE babelfish_remove_object_from_extension(obj_type varchar, qualified_obj_name varchar) AS
$$
DECLARE
    error_msg text;
    query text;
BEGIN
    query := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', obj_type, qualified_obj_name);
    execute query;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
END
$$
LANGUAGE plpgsql;

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- 3.1 changes table types to explicitly be stored as pass-by-value in pg_type. While MVU forces the catalog
-- to be regenerated, mVU (minor version upgrade) does not, so we need to manually fix it here.
UPDATE pg_catalog.pg_type AS t SET typbyval = 't' 
FROM sys.babelfish_namespace_ext AS b,
    pg_catalog.pg_namespace AS n
WHERE b.nspname = n.nspname AND t.typnamespace = n.oid -- only update types in babelfish namespaces
    AND typtype = 'c' -- only update composite types
    AND typacl IS NOT NULL; -- table types have non-NULL typacl, while normal tables have it as NULL

CREATE OR REPLACE FUNCTION sys.babelfish_get_scope_identity()
RETURNS INT8
AS 'babelfishpg_tsql', 'get_scope_identity'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.scope_identity()
RETURNS numeric(38,0) AS
$BODY$
 SELECT sys.babelfish_get_scope_identity()::numeric(38,0);
$BODY$
LANGUAGE SQL STABLE;

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
left outer join sys.babelfish_view_def vd on t.relname::sys.sysname = vd.object_name and sch.name = vd.schema_name and vd.dbid = sys.db_id() 
where t.relkind = 'v'
and has_schema_privilege(sch.schema_id, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER');
GRANT SELECT ON sys.views TO PUBLIC;

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

ALTER FUNCTION sys.num_days_in_date RENAME TO num_days_in_date_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'num_days_in_date_deprecated_in_3_1_0');
CREATE OR REPLACE FUNCTION sys.num_days_in_date(IN d1 BIGINT, IN m1 BIGINT, IN y1 BIGINT) RETURNS BIGINT AS $$
DECLARE
	i BIGINT;
	n1 BIGINT;
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
LANGUAGE plpgsql IMMUTABLE;

ALTER FUNCTION sys.datediff_internal_df RENAME TO datediff_internal_df_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_df_deprecated_in_3_1_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal_df(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
	y1 BIGINT;
	m1 BIGINT;
	d1 BIGINT;
	y2 BIGINT;
	m2 BIGINT;
	d2 BIGINT;
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
		-- so we do not need to add second_diff again
		day_diff = sys.datepart('day', enddate OPERATOR(sys.-) startdate);
		hour_diff = sys.datepart('hour', enddate OPERATOR(sys.-) startdate);
		minute_diff = sys.datepart('minute', enddate OPERATOR(sys.-) startdate);
		second_diff = TRUNC(sys.datepart('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(sys.datepart('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
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

ALTER FUNCTION sys.datediff_internal_date RENAME TO datediff_internal_date_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_date_deprecated_in_3_1_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal_date(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
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
		-- so we do not need to add second_diff again
		day_diff = enddate - startdate;
		result = day_diff * 24 * 60 * 60 * 1000;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
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

ALTER FUNCTION sys.datediff_internal RENAME TO datediff_internal_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'datediff_internal_deprecated_in_3_1_0');
CREATE OR REPLACE FUNCTION sys.datediff_internal(IN datepart PG_CATALOG.TEXT, IN startdate anyelement, IN enddate anyelement) RETURNS BIGINT AS $$
DECLARE
	result BIGINT;
	year_diff BIGINT;
	month_diff BIGINT;
	day_diff BIGINT;
	hour_diff BIGINT;
	minute_diff BIGINT;
	second_diff BIGINT;
	millisecond_diff BIGINT;
	microsecond_diff BIGINT;
	y1 BIGINT;
	m1 BIGINT;
	d1 BIGINT;
	y2 BIGINT;
	m2 BIGINT;
	d2 BIGINT;
BEGIN
	CASE datepart
	WHEN 'year' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		result = year_diff;
	WHEN 'quarter' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = (year_diff * 12 + month_diff) / 3;
	WHEN 'month' THEN
		year_diff = date_part('year', enddate)::BIGINT - date_part('year', startdate)::BIGINT;
		month_diff = date_part('month', enddate)::BIGINT - date_part('month', startdate)::BIGINT;
		result = year_diff * 12 + month_diff;
	WHEN 'doy', 'y' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = day_diff;
	WHEN 'day' THEN
		y1 = date_part('year', enddate)::BIGINT;
		m1 = date_part('month', enddate)::BIGINT;
		d1 = date_part('day', enddate)::BIGINT;
		y2 = date_part('year', startdate)::BIGINT;
		m2 = date_part('month', startdate)::BIGINT;
		d2 = date_part('day', startdate)::BIGINT;
		result = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
	WHEN 'week' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = day_diff / 7;
	WHEN 'hour' THEN
		y1 = date_part('year', enddate)::BIGINT;
		m1 = date_part('month', enddate)::BIGINT;
		d1 = date_part('day', enddate)::BIGINT;
		y2 = date_part('year', startdate)::BIGINT;
		m2 = date_part('month', startdate)::BIGINT;
		d2 = date_part('day', startdate)::BIGINT;
		day_diff = sys.num_days_in_date(d1, m1, y1) - sys.num_days_in_date(d2, m2, y2);
		hour_diff = date_part('hour', enddate)::BIGINT - date_part('hour', startdate)::BIGINT;
		result = day_diff * 24 + hour_diff;
	WHEN 'minute' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		result = (day_diff * 24 + hour_diff) * 60 + minute_diff;
	WHEN 'second' THEN
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		result = ((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60 + second_diff;
	WHEN 'millisecond' THEN
		-- millisecond result from date_part by default contains second value,
		-- so we do not need to add second_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		result = (((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000 + millisecond_diff;
	WHEN 'microsecond' THEN
		-- microsecond result from date_part by default contains second and millisecond values,
		-- so we do not need to add second_diff and millisecond_diff again
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
		second_diff = TRUNC(date_part('second', enddate OPERATOR(sys.-) startdate));
		millisecond_diff = TRUNC(date_part('millisecond', enddate OPERATOR(sys.-) startdate));
		microsecond_diff = TRUNC(date_part('microsecond', enddate OPERATOR(sys.-) startdate));
		result = ((((day_diff * 24 + hour_diff) * 60 + minute_diff) * 60) * 1000) * 1000 + microsecond_diff;
	WHEN 'nanosecond' THEN
		-- Best we can do - Postgres does not support nanosecond precision
		day_diff = date_part('day', enddate OPERATOR(sys.-) startdate)::BIGINT;
		hour_diff = date_part('hour', enddate OPERATOR(sys.-) startdate)::BIGINT;
		minute_diff = date_part('minute', enddate OPERATOR(sys.-) startdate)::BIGINT;
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

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal_date(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal_df(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return CAST(sys.datediff_internal(datepart, startdate, enddate) AS INTEGER);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

-- datediff big
CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_date(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_df(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE;

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

  CASE WHEN t4."DATA_TYPE" = 'xml' THEN 0::INT
    WHEN t4."DATA_TYPE" = 'sql_variant' THEN 8000::INT
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
     LEFT OUTER JOIN sys.babelfish_namespace_ext ext on t2.nspname = ext.nspname
     JOIN information_schema_tsql.columns t4 ON (t1.relname::sys.nvarchar(128) = t4."TABLE_NAME" AND ext.orig_name = t4."TABLE_SCHEMA")
     LEFT JOIN pg_attribute a on a.attrelid = t1.oid AND a.attname::sys.nvarchar(128) = t4."COLUMN_NAME"
     LEFT JOIN pg_type t ON t.oid = a.atttypid
     LEFT JOIN sys.columns t6 ON
     (
      t1.oid = t6.object_id AND
      t4."ORDINAL_POSITION" = t6.column_id
     )
     , sys.translate_pg_type_to_tsql(a.atttypid) AS tsql_type_name
     , sys.spt_datatype_info_table AS t5
  WHERE (t4."DATA_TYPE" = CAST(t5.TYPE_NAME AS sys.nvarchar(128)))
    AND ext.dbid = cast(sys.db_id() as oid);
GRANT SELECT on sys.sp_columns_100_view TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.APP_NAME() RETURNS SYS.NVARCHAR(128)
AS
$$
    SELECT current_setting('application_name');
$$
LANGUAGE sql PARALLEL SAFE STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_get_expr(IN text_expr text DEFAULT NULL , IN function_id OID DEFAULT NULL)
RETURNS text AS 'babelfishpg_tsql', 'tsql_get_expr' LANGUAGE C IMMUTABLE PARALLEL SAFE;

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
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar(4000)) AS definition
  , 1::sys.bit AS uses_database_collation
  , 0::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_name = a.attname COLLATE sys.database_default AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
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
  , CAST(tsql_get_expr(d.adbin, d.adrelid) as sys.nvarchar(4000)) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

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
  , CAST(case when a.attidentity <> ''::"char" then 1 else 0 end AS sys.bit) as is_identity
  , CAST(case when a.attgenerated <> ''::"char" then 1 else 0 end AS sys.bit) as is_computed
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

CREATE OR REPLACE FUNCTION sys.STR(IN float_expression NUMERIC, IN length INTEGER DEFAULT 10, IN decimal_point INTEGER DEFAULT 0) RETURNS VARCHAR 
AS
'babelfishpg_tsql', 'float_str' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.STR(IN NUMERIC, IN INTEGER, IN INTEGER) TO PUBLIC;

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

CREATE OR REPLACE FUNCTION sys.power(IN arg1 BIGINT, IN arg2 NUMERIC)
RETURNS bigint  AS 'babelfishpg_tsql','bigint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(BIGINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 INT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','int_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(INT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 SMALLINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(SMALLINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.power(IN arg1 TINYINT, IN arg2 NUMERIC)
RETURNS int  AS 'babelfishpg_tsql','smallint_power' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.power(TINYINT,NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.degrees(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_degrees' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.degrees(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.radians(IN arg1 NUMERIC)
RETURNS numeric  AS 'babelfishpg_tsql','numeric_radians' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.radians(NUMERIC) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.rowcount_big()
RETURNS BIGINT AS 'babelfishpg_tsql' LANGUAGE C STABLE;

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

CREATE OR REPLACE PROCEDURE sys.sp_addlinkedserver( IN "@server" sys.sysname,
                                                    IN "@srvproduct" sys.nvarchar(128) DEFAULT NULL,
                                                    IN "@provider" sys.nvarchar(128) DEFAULT 'SQLNCLI',
                                                    IN "@datasrc" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@location" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@provstr" sys.nvarchar(4000) DEFAULT NULL,
                                                    IN "@catalog" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedserver_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_addlinkedserver(IN sys.sysname,
                                                  IN sys.nvarchar(128),
                                                  IN sys.nvarchar(128),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.nvarchar(4000),
                                                  IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_addlinkedserver( IN "@server" sys.sysname,
                                                  IN "@srvproduct" sys.nvarchar(128) DEFAULT NULL,
                                                  IN "@provider" sys.nvarchar(128) DEFAULT 'SQLNCLI',
                                                  IN "@datasrc" sys.nvarchar(4000) DEFAULT NULL,
                                                  IN "@location" sys.nvarchar(4000) DEFAULT NULL,
                                                  IN "@provstr" sys.nvarchar(4000) DEFAULT NULL,
                                                  IN "@catalog" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedserver_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_addlinkedserver OWNER TO sysadmin;

CREATE OR REPLACE VIEW sys.servers
AS
SELECT
  CAST(f.oid as int) AS server_id,
  CAST(f.srvname as sys.sysname) AS name,
  CAST('' as sys.sysname) AS product,
  CAST('tds_fdw' as sys.sysname) AS provider,
  CAST((select string_agg(
                  case
                  when option like 'servername=%%' then substring(option, 12)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.nvarchar(4000)) AS data_source,
  CAST(NULL as sys.nvarchar(4000)) AS location,
  CAST(NULL as sys.nvarchar(4000)) AS provider_string,
  CAST((select string_agg(
                  case
                  when option like 'database=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(f.srvoptions) as option) as sys.sysname) AS catalog,
  CAST(0 as int) AS connect_timeout,
  CAST(0 as int) AS query_timeout,
  CAST(1 as sys.bit) AS is_linked,
  CAST(0 as sys.bit) AS is_remote_login_enabled,
  CAST(0 as sys.bit) AS is_rpc_out_enabled,
  CAST(1 as sys.bit) AS is_data_access_enabled,
  CAST(0 as sys.bit) AS is_collation_compatible,
  CAST(1 as sys.bit) AS uses_remote_collation,
  CAST(NULL as sys.sysname) AS collation_name,
  CAST(0 as sys.bit) AS lazy_schema_validation,
  CAST(0 as sys.bit) AS is_system,
  CAST(0 as sys.bit) AS is_publisher,
  CAST(0 as sys.bit) AS is_subscriber,
  CAST(0 as sys.bit) AS is_distributor,
  CAST(0 as sys.bit) AS is_nonsql_subscriber,
  CAST(1 as sys.bit) AS is_remote_proc_transaction_promotion_enabled,
  CAST(NULL as sys.datetime) AS modify_date,
  CAST(0 as sys.bit) AS is_rda_server
FROM pg_foreign_server AS f
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

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

CREATE OR REPLACE VIEW information_schema_tsql.tables AS
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
		AND ext.dbid = cast(sys.db_id() as oid)
		AND (NOT c.relname = 'sysdatabases');

GRANT SELECT ON information_schema_tsql.tables TO PUBLIC;

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

  ANALYZE;

  CALL sys.printarg('Statistics for all tables have been updated. Refer logs for details.');
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE on PROCEDURE sys.sp_updatestats(IN "@resample" VARCHAR(8)) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.babelfish_has_any_privilege(
    userid oid,
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
        IF perm_target_type = 'table' COLLATE sys.database_default AND has_table_privilege(userid, qualified_name, permission)::integer = 1
            THEN RETURN 1;
        ELSIF perm_target_type COLLATE sys.database_default IN ('function', 'procedure') AND has_function_privilege(userid, function_signature, permission)::integer = 1
            THEN RETURN 1;
        END IF;
    END LOOP;
    RETURN 0;
END
$BODY$
LANGUAGE plpgsql;

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
    is_cross_db boolean := false;
    object_name text COLLATE sys.database_default;
    database_id smallint;
    namespace_id oid;
    userid oid;
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

    IF fully_supported = 'f' AND
		(SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) = 'dbo' THEN
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

	IF database_id <> sys.db_id() THEN
        is_cross_db = true;
	END IF;

	userid := (
        SELECT CASE
            WHEN is_cross_db THEN sys.suser_id()
            ELSE sys.user_id()
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
                    WHEN (SELECT count(a.attname)
                        FROM pg_attribute a
                        INNER JOIN pg_class c ON c.oid = a.attrelid
                        INNER JOIN pg_namespace s ON s.oid = c.relnamespace
                        WHERE
                        a.attname = cs_as_sub_securable COLLATE sys.database_default
                        AND c.relname = object_name COLLATE sys.database_default
                        AND s.nspname = pg_schema COLLATE sys.database_default
                        AND NOT a.attisdropped
                        AND (s.nspname IN (SELECT nspname FROM sys.babelfish_namespace_ext) OR s.nspname = 'sys')
                        -- r = ordinary table, i = index, S = sequence, t = TOAST table, v = view, m = materialized view, c = composite type, f = foreign table, p = partitioned table
                        AND c.relkind IN ('r', 'v', 'm', 'f', 'p')
                        AND a.attnum > 0) = 1
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
    
    -- Object was not found
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
            WHEN cs_as_permission = 'any' THEN babelfish_has_any_privilege(userid, object_type, pg_schema, object_name)

            WHEN object_type = 'column'
                THEN CASE
                    WHEN cs_as_permission IN('insert', 'delete', 'execute') THEN NULL
                    ELSE CAST(has_column_privilege(userid, qualified_name, cs_as_sub_securable, cs_as_permission) AS integer)
                END

            WHEN object_type = 'table'
                THEN CASE
                    WHEN cs_as_permission = 'execute' THEN 0
                    ELSE CAST(has_table_privilege(userid, qualified_name, cs_as_permission) AS integer)
                END

            WHEN object_type = 'function'
                THEN CASE
                    WHEN cs_as_permission IN('select', 'execute')
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
                    WHEN cs_as_permission IN('update', 'insert', 'delete', 'references')
                        THEN 0
                    ELSE NULL
                END

            WHEN object_type = 'procedure'
                THEN CASE
                    WHEN cs_as_permission = 'execute'
                        THEN CAST(has_function_privilege(userid, function_signature, 'execute') AS integer)
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

create or replace view sys.table_types_internal as
SELECT pt.typrelid
    FROM pg_catalog.pg_type pt
    INNER join sys.schemas sch on pt.typnamespace = sch.schema_id
    INNER JOIN pg_catalog.pg_depend dep ON pt.typrelid = dep.objid
    INNER JOIN pg_catalog.pg_class pc ON pc.oid = dep.objid
    WHERE pt.typtype = 'c' AND dep.deptype = 'i'  AND pc.relkind = 'r';

create or replace view sys.types As
with RECURSIVE type_code_list as
(
    select distinct  pg_typname as pg_type_name, tsql_typname as tsql_type_name
    from sys.babelfish_typecode_list()
),
tt_internal as MATERIALIZED
(
  Select * from sys.table_types_internal
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
    ELSE  c.collname
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
select cast(t.typname as text) as name
  , t.typbasetype as system_type_id
  , t.oid as user_type_id
  , t.typnamespace as schema_id
  , null::integer as principal_id
  , case when tt.typrelid is not null then -1::smallint else sys.tsql_type_max_length_helper(tsql_base_type_name, t.typlen, t.typtypmod) end as max_length
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_precision_helper(tsql_base_type_name, t.typtypmod) as int) end as precision
  , case when tt.typrelid is not null then 0::smallint else cast(sys.tsql_type_scale_helper(tsql_base_type_name, t.typtypmod, false) as int) end as scale
  , CASE c.collname
    WHEN 'default' THEN default_collation_name
    ELSE  c.collname 
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
left join type_code_list ti on t.typname = ti.pg_type_name
left join pg_collation c on c.oid = t.typcollation
left join tt_internal tt on t.typrelid = tt.typrelid
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

CREATE OR REPLACE PROCEDURE sys.sp_addlinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                      IN "@useself" sys.varchar(8) DEFAULT 'TRUE',
                                                      IN "@locallogin" sys.sysname DEFAULT NULL,
                                                      IN "@rmtuser" sys.sysname DEFAULT NULL,
                                                      IN "@rmtpassword" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedsrvlogin_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_addlinkedsrvlogin(IN sys.sysname,
                                                    IN sys.varchar(8),
                                                    IN sys.sysname,
                                                    IN sys.sysname,
                                                    IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_addlinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                      IN "@useself" sys.varchar(8) DEFAULT 'TRUE',
                                                      IN "@locallogin" sys.sysname DEFAULT NULL,
                                                      IN "@rmtuser" sys.sysname DEFAULT NULL,
                                                      IN "@rmtpassword" sys.sysname DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_addlinkedsrvlogin_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_addlinkedsrvlogin OWNER TO sysadmin;

CREATE OR REPLACE VIEW sys.linked_logins
AS
SELECT
  CAST(u.srvid as int) AS server_id,
  CAST(0 as int) AS local_principal_id,
  CAST(0 as sys.bit) AS uses_self_credential,
  CAST((select string_agg(
                  case
                  when option like 'username=%%' then substring(option, 10)
                  else NULL
                  end, ',')
          from unnest(u.umoptions) as option) as sys.sysname) AS remote_name,
  CAST(NULL as sys.datetime) AS modify_date
FROM pg_user_mappings AS U
LEFT JOIN pg_foreign_server AS f ON u.srvid = f.oid
LEFT JOIN pg_foreign_data_wrapper AS w ON f.srvfdw = w.oid
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.linked_logins TO PUBLIC;

/*
 * SCHEMATA view
 */
CREATE OR REPLACE FUNCTION sys.bbf_is_shared_schema(IN schemaname TEXT)
RETURNS BOOL
AS 'babelfishpg_tsql', 'is_shared_schema_wrapper'
LANGUAGE C STABLE STRICT;

CREATE OR REPLACE VIEW information_schema_tsql.schemata AS
	SELECT CAST(sys.db_name() AS sys.sysname) AS "CATALOG_NAME",
	CAST(CASE WHEN np.nspname LIKE CONCAT(sys.db_name(),'%') THEN RIGHT(np.nspname, LENGTH(np.nspname) - LENGTH(sys.db_name()) - 1)
	     ELSE np.nspname END AS sys.nvarchar(128)) AS "SCHEMA_NAME",
	-- For system-defined schemas, schema-owner name will be same as schema_name
	-- For user-defined schemas having default owner, schema-owner will be dbo
	-- For user-defined schemas with explicit owners, rolname contains dbname followed
	-- by owner name, so need to extract the owner name from rolname always.
	CAST(CASE WHEN sys.bbf_is_shared_schema(np.nspname) = TRUE THEN np.nspname
		  WHEN r.rolname LIKE CONCAT(sys.db_name(),'%') THEN
			CASE WHEN RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) = 'db_owner' THEN 'dbo'
			     ELSE RIGHT(r.rolname, LENGTH(r.rolname) - LENGTH(sys.db_name()) - 1) END ELSE 'dbo' END
			AS sys.nvarchar(128)) AS "SCHEMA_OWNER",
	CAST(null AS sys.varchar(6)) AS "DEFAULT_CHARACTER_SET_CATALOG",
	CAST(null AS sys.varchar(3)) AS "DEFAULT_CHARACTER_SET_SCHEMA",
	-- TODO: We need to first create mapping of collation name to char-set name;
	-- Until then return null for DEFAULT_CHARACTER_SET_NAME
	CAST(null AS sys.sysname) AS "DEFAULT_CHARACTER_SET_NAME"
	FROM ((pg_catalog.pg_namespace np LEFT JOIN sys.pg_namespace_ext nc on np.nspname = nc.nspname)
		LEFT JOIN pg_catalog.pg_roles r on r.oid = nc.nspowner) LEFT JOIN sys.babelfish_namespace_ext ext on nc.nspname = ext.nspname
	WHERE (ext.dbid = cast(sys.db_id() as oid) OR np.nspname in ('sys', 'information_schema_tsql')) AND
	      (pg_has_role(np.nspowner, 'USAGE') OR has_schema_privilege(np.oid, 'CREATE, USAGE'))
	ORDER BY nc.nspname, np.nspname;

GRANT SELECT ON information_schema_tsql.schemata TO PUBLIC;

CREATE TABLE sys.babelfish_domain_mapping (
  netbios_domain_name sys.VARCHAR(15) NOT NULL, -- Netbios domain name
  fq_domain_name sys.VARCHAR(128) NOT NULL, -- DNS domain name
  PRIMARY KEY (netbios_domain_name)
);

GRANT ALL ON TABLE sys.babelfish_domain_mapping TO sysadmin;
GRANT SELECT ON TABLE sys.babelfish_domain_mapping TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_domain_mapping', '');

CREATE OR REPLACE PROCEDURE sys.babelfish_add_domain_mapping_entry(IN sys.VARCHAR(15), IN sys.VARCHAR(128))
  AS 'babelfishpg_tsql', 'babelfish_add_domain_mapping_entry_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_add_domain_mapping_entry TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_remove_domain_mapping_entry(IN sys.VARCHAR(15))
  AS 'babelfishpg_tsql', 'babelfish_remove_domain_mapping_entry_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_remove_domain_mapping_entry TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_truncate_domain_mapping_table()
  AS 'babelfishpg_tsql', 'babelfish_truncate_domain_mapping_table_internal' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.babelfish_truncate_domain_mapping_table TO PUBLIC;

-- For all the views created on previous versions(except 2.4 and onwards), the definition in the catalog should be NULL.
UPDATE sys.babelfish_view_def AS bvd
SET definition = NULL
WHERE (SELECT get_bit(CAST(bvd.flag_validity AS bit(7)),4) = 0);

CREATE OR REPLACE PROCEDURE sys.sp_droplinkedsrvlogin(  IN "@rmtsrvname" sys.sysname,
                                                        IN "@locallogin" sys.sysname)
AS 'babelfishpg_tsql', 'sp_droplinkedsrvlogin_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_droplinkedsrvlogin( IN sys.sysname,
                                                      IN sys.sysname)
TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_droplinkedsrvlogin( IN "@rmtsrvname" sys.sysname,
                                                              IN "@locallogin" sys.sysname)
AS 'babelfishpg_tsql', 'sp_droplinkedsrvlogin_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_droplinkedsrvlogin OWNER TO sysadmin;

-- Add one column to store definition of the function in the table.
SET allow_system_table_mods = on;
ALTER TABLE sys.babelfish_function_ext add COLUMN IF NOT EXISTS definition sys.NTEXT DEFAULT NULL;
RESET allow_system_table_mods;

GRANT SELECT ON sys.babelfish_function_ext TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_function_ext', '');

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
	    /*
                 * TODO: We need to first create mapping of collation name to char-set name;
                 * Until then return null.
            */
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
            CAST(f.definition AS sys.nvarchar(4000)) AS "ROUTINE_DEFINITION",
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
	    inner join sys.all_objects ao on ao.object_id = CAST(p.oid AS INT)
		LEFT JOIN sys.babelfish_function_ext f ON p.proname = f.funcname AND sch.schema_id::regnamespace::name = f.nspname
			AND sys.babelfish_get_pltsql_function_signature(p.oid) = f.funcsignature COLLATE "C",
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

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF', 'TR') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar(4000)) AS definition  -- Object definition work in progress, will update definition with BABEL-3127 Jira.
  , CAST(1 as sys.bit)  AS uses_ansi_nulls
  , CAST(1 as sys.bit)  AS uses_quoted_identifier
  , CAST(0 as sys.bit)  AS is_schema_bound
  , CAST(0 as sys.bit)  AS uses_database_collation
  , CAST(0 as sys.bit)  AS is_recompiled
  , CAST(
      CASE WHEN ao.type IN ('P', 'FN', 'IN', 'TF', 'RF', 'IF') THEN
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
LEFT JOIN sys.babelfish_function_ext f ON ao.name = f.funcname COLLATE "C" AND ao.schema_id::regnamespace::name = f.nspname
AND sys.babelfish_get_pltsql_function_signature(ao.object_id) = f.funcsignature COLLATE "C"
WHERE ao.type in ('P', 'RF', 'V', 'TR', 'FN', 'IF', 'TF', 'R');
GRANT SELECT ON sys.all_sql_modules_internal TO PUBLIC;

-- deprecate old FOR XML/JSON functions if they exist - if this install came from an upgrade path that did
-- not contain v2.4+, then they WILL exist. Otherwise (v2.3->v3.0 OR v3.0->v3.1) they WILL NOT exist.
DO $$
BEGIN
ALTER FUNCTION sys.tsql_query_to_xml(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_deprecated_in_3_1_0');
EXCEPTION
    WHEN OTHERS THEN
        -- Do nothing
END $$;

DO $$
BEGIN
ALTER FUNCTION sys.tsql_query_to_xml_text(text, int, text, boolean, text) RENAME TO tsql_query_to_xml_text_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_xml_text_deprecated_in_3_1_0');
EXCEPTION
    WHEN OTHERS THEN
        -- Do nothing
END $$;

DO $$
BEGIN
ALTER FUNCTION sys.tsql_query_to_json_text(text, int, boolean, boolean, text) RENAME TO tsql_query_to_json_text_deprecated_in_3_1_0;
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'tsql_query_to_json_text_deprecated_in_3_1_0');
EXCEPTION
    WHEN OTHERS THEN
        -- Do nothing
END $$;

-- SELECT FOR XML
CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_xml_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_ffunc(
    state INTERNAL
)
RETURNS XML AS
'babelfishpg_tsql', 'tsql_query_to_xml_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_xml_text_ffunc(
    state INTERNAL
)
RETURNS NTEXT AS
'babelfishpg_tsql', 'tsql_query_to_xml_text_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_ffunc
);

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_xml_text_agg(
    rec ANYELEMENT,
    mode int,
    element_name text,
    binary_base64 boolean,
    root_name text)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_xml_sfunc,
    FINALFUNC = tsql_query_to_xml_text_ffunc
);

CREATE OR REPLACE FUNCTION sys.tsql_select_for_xml_result(res XML)
RETURNS setof XML AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.tsql_select_for_xml_text_result(res NTEXT)
RETURNS setof NTEXT AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql;

-- SELECT FOR JSON
CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_sfunc(
    state INTERNAL,
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT
) RETURNS INTERNAL
AS 'babelfishpg_tsql', 'tsql_query_to_json_sfunc'
LANGUAGE C STABLE;

CREATE OR REPLACE FUNCTION sys.tsql_query_to_json_ffunc(
    state INTERNAL
)
RETURNS sys.NVARCHAR AS
'babelfishpg_tsql', 'tsql_query_to_json_ffunc'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE AGGREGATE sys.tsql_select_for_json_agg(
    rec ANYELEMENT,
    mode INT,
    include_null_values BOOLEAN,
    without_array_wrapper BOOLEAN,
    root_name TEXT)
(
    STYPE = INTERNAL,
    SFUNC = tsql_query_to_json_sfunc,
    FINALFUNC = tsql_query_to_json_ffunc
);

CREATE OR REPLACE FUNCTION sys.tsql_select_for_json_result(res sys.NVARCHAR)
RETURNS setof sys.NVARCHAR AS
$$
BEGIN
IF res IS NOT NULL THEN
    return next res;
ELSE
    return;
END IF;
END;
$$
LANGUAGE plpgsql;

-- function sys.object_id(object_name, object_type) needs to change input type to sys.VARCHAR if not changed already
DO $$
BEGIN IF (SELECT count(*) FROM pg_proc as p where p.proname = 'object_id' AND (p.pronargs = 2 AND p.proargtypes[0] = 'sys.varchar'::regtype AND p.proargtypes[1] = 'sys.varchar'::regtype)) = 0 THEN
    ALTER FUNCTION sys.object_id RENAME TO object_id_deprecated_in_3_1_0;
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'object_id_deprecated_in_3_1_0');
END IF;
END $$;

CREATE OR REPLACE FUNCTION sys.object_id(IN object_name sys.VARCHAR, IN object_type sys.VARCHAR DEFAULT NULL)
RETURNS INTEGER AS
'babelfishpg_tsql', 'object_id'
LANGUAGE C STABLE;

CREATE OR REPLACE PROCEDURE sys.sp_helplinkedsrvlogin(
	IN "@rmtsrvname" sysname DEFAULT NULL,
	IN "@locallogin" sysname DEFAULT NULL
)
AS $$
DECLARE @server_id INT;
DECLARE @local_principal_id INT;
BEGIN
	IF @rmtsrvname IS NOT NULL
		BEGIN
			SELECT @server_id = server_id FROM sys.servers WHERE name = @rmtsrvname;

			IF @server_id IS NULL
				BEGIN
					RAISERROR('The server ''%s'' does not exist', 16, 1, @rmtsrvname);
        				RETURN 1;
				END
		END

	IF @locallogin IS NOT NULL
		BEGIN
			SELECT @local_principal_id = usesysid FROM pg_user WHERE CAST(usename as sys.sysname) = @locallogin;
		END
	
	SELECT
		s.name AS "Linked Server",
		CAST(u.usename as sys.sysname) AS "Local Login", 
		CAST(0 as smallint) AS "Is Self Mapping", 
		l.remote_name AS "Remote Login"
	FROM sys.linked_logins AS l 
	LEFT JOIN sys.servers AS s ON l.server_id = s.server_id
	LEFT JOIN pg_user AS u ON l.local_principal_id = u.usesysid
	WHERE (@server_id is NULL or @server_id = s.server_id) AND ((@local_principal_id is NULL AND @locallogin IS NULL) or @local_principal_id = l.local_principal_id);
END;
$$ LANGUAGE pltsql;
GRANT EXECUTE ON PROCEDURE sys.sp_helplinkedsrvlogin TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babelfish_sp_rename_internal(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@schemaname" sys.nvarchar(776),
	IN "@objtype" char(2) DEFAULT NULL
) AS 'babelfishpg_tsql', 'sp_rename_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.babelfish_sp_rename_internal TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776),
	IN "@newname" sys.SYSNAME,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	IF @objtype = 'COLUMN'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Column', 1;
		END
	IF @objtype = 'INDEX'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Index', 1;
		END
	IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
		END
	IF @objtype = 'USERDATATYPE'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type User-defined Data Type alias', 1;
		END
	IF @objtype IS NOT NULL AND (@objtype != 'OBJECT')
		BEGIN
			THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
		END
	DECLARE @name_count INT;
	DECLARE @subname sys.nvarchar(776) = '';
	DECLARE @schemaname sys.nvarchar(776) = '';
	DECLARE @dbname sys.nvarchar(776) = '';
	SELECT @name_count = COUNT(*) FROM STRING_SPLIT(@objname, '.');
	IF @name_count > 3
		BEGIN
			THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
		END
	IF @name_count = 3
		BEGIN
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @dbname = value FROM myTableWithRows WHERE row = 1;
			IF @dbname != sys.db_name()
				BEGIN
					THROW 33557097, N'No item by the given @objname could be found in the current database', 1;
				END
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @schemaname = value FROM myTableWithRows WHERE row = 2;
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @subname = value FROM myTableWithRows WHERE row = 3;
		END
	IF @name_count = 2
		BEGIN
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @schemaname = value FROM myTableWithRows WHERE row = 1;
			WITH myTableWithRows AS (
				SELECT (ROW_NUMBER() OVER (ORDER BY NULL)) as row,*
				FROM STRING_SPLIT(@objname, '.'))
			SELECT @subname = value FROM myTableWithRows WHERE row = 2;
		END
	IF @name_count = 1
		BEGIN
			SET @schemaname = sys.schema_name();
			SET @subname = @objname;
		END
	
	DECLARE @count INT;
	DECLARE @currtype char(2);
	SELECT @count = COUNT(*) FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
	WHERE s1.name = @schemaname AND o1.name = @subname;
	IF @count > 1
		BEGIN
			THROW 33557097, N'There are multiple objects with the given @objname.', 1;
		END
	IF @count < 1
		BEGIN
			THROW 33557097, N'There is no object with the given @objname.', 1;
		END
	SELECT @currtype = type FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
	WHERE s1.name = @schemaname AND o1.name = @subname;
	EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype;
	PRINT 'Caution: Changing any part of an object name could break scripts and stored procedures.';
END;
$$;
GRANT EXECUTE on PROCEDURE sys.sp_rename(IN sys.nvarchar(776), IN sys.SYSNAME, IN sys.varchar(13)) TO PUBLIC;

CREATE OR REPLACE VIEW sys.sp_fkeys_view AS
SELECT
CAST(nsp_ext2.dbname AS sys.sysname) AS PKTABLE_QUALIFIER,
CAST(bbf_nsp2.orig_name AS sys.sysname) AS PKTABLE_OWNER ,
CAST(c2.relname AS sys.sysname) AS PKTABLE_NAME,
CAST(COALESCE(split_part(a2.attoptions[1] COLLATE "C", '=', 2),a2.attname) AS sys.sysname) AS PKCOLUMN_NAME,
CAST(nsp_ext.dbname AS sys.sysname) AS FKTABLE_QUALIFIER,
CAST(bbf_nsp.orig_name AS sys.sysname) AS FKTABLE_OWNER ,
CAST(c.relname AS sys.sysname) AS FKTABLE_NAME,
CAST(COALESCE(split_part(a.attoptions[1] COLLATE "C", '=', 2),a.attname) AS sys.sysname) AS FKCOLUMN_NAME,
CAST(nr AS smallint) AS KEY_SEQ,
CASE
   WHEN const1.confupdtype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confupdtype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confupdtype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confupdtype = 'd' THEN CAST(3 AS smallint) -- set default
END AS UPDATE_RULE,

CASE
   WHEN const1.confdeltype = 'c' THEN CAST(0 AS smallint) -- cascade
   WHEN const1.confdeltype = 'a' THEN CAST(1 AS smallint) -- no action
   WHEN const1.confdeltype = 'n' THEN CAST(2 AS smallint) -- set null
   WHEN const1.confdeltype = 'd' THEN CAST(3 AS smallint) -- set default
   ELSE CAST(0 AS smallint)
END AS DELETE_RULE,
CAST(const1.conname AS sys.sysname) AS FK_NAME,
CAST(const2.conname AS sys.sysname) AS PK_NAME,
CASE
   WHEN const1.condeferrable = false THEN CAST(7 as smallint) -- not deferrable
   ELSE (CASE WHEN const1.condeferred = false THEN CAST(6 as smallint) --  not deferred by default
              ELSE CAST(5 as smallint) -- deferred by default
         END)
END AS DEFERRABILITY

FROM (pg_constraint const1
-- join with nsp_Ext to get constraints in current namespace
JOIN sys.pg_namespace_ext nsp_ext ON nsp_ext.oid = const1.connamespace
--get the table names corresponding to foreign keys
JOIN pg_class c ON const1.conrelid = c.oid AND const1.contype ='f'
-- join wiht bbf_nsp to get all constraint related to tsql endpoint and the owner of foreign key
JOIN sys.babelfish_namespace_ext bbf_nsp ON bbf_nsp.nspname = nsp_ext.nspname AND bbf_nsp.dbid = sys.db_id()
-- lateral join to use the conkey and confkey to join with pg_attribute to get column names
CROSS JOIN LATERAL unnest(const1.conkey,const1.confkey) WITH ORDINALITY AS ak(j, k, nr)
            LEFT JOIN pg_attribute a
                       ON (a.attrelid = const1.conrelid AND a.attnum = ak.j)
            LEFT JOIN pg_attribute a2
                       ON (a2.attrelid = const1.confrelid AND a2.attnum = ak.k)
)
-- get the index that foreign key depends on
LEFT JOIN pg_depend d1 ON d1.objid = const1.oid AND d1.classid = 'pg_constraint'::regclass
           AND d1.refclassid = 'pg_class'::regclass AND d1.refobjsubid = 0
-- get the pkey/ukey constraint for this index
LEFT JOIN pg_depend d2 ON d2.refclassid = 'pg_constraint'::regclass AND d2.classid = 'pg_class'::regclass AND d2.objid = d1.refobjid AND d2.objsubid = 0 AND d2.deptype = 'i'
-- get the constraint name from new pg_constraint
LEFT JOIN pg_constraint const2 ON const2.oid = d2.refobjid AND const2.contype IN ('p', 'u') AND const2.conrelid = const1.confrelid
-- get the namespace name for primary key
LEFT JOIN sys.pg_namespace_ext nsp_ext2 ON const2.connamespace = nsp_ext2.oid
-- get the owner name for primary key
LEFT JOIN sys.babelfish_namespace_ext bbf_nsp2 ON bbf_nsp2.nspname = nsp_ext2.nspname AND bbf_nsp2.dbid = sys.db_id()
-- get the table name for primary key
LEFT JOIN pg_class c2 ON const2.conrelid = c2.oid AND const2.contype IN ('p', 'u');

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
	PK_NAME,
	DEFERRABILITY
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

CREATE OR REPLACE PROCEDURE sys.sp_linkedservers()
AS $$
BEGIN
    SELECT 
		name AS "SRV_NAME", 
		CAST(provider AS sys.nvarchar(128)) AS "SRV_PROVIDERNAME", 
		CAST(product AS sys.nvarchar(128)) AS "SRV_PRODUCT", 
		data_source AS "SRV_DATASOURCE",
		provider_string AS "SRV_PROVIDERSTRING",
		location AS "SRV_LOCATION",
		catalog AS "SRV_CAT" 
	FROM sys.servers
	ORDER BY SRV_NAME
END;
$$ LANGUAGE 'pltsql';
GRANT EXECUTE ON PROCEDURE sys.sp_linkedservers TO PUBLIC;

ALTER TABLE sys.babelfish_authid_login_ext ADD COLUMN IF NOT EXISTS orig_loginname SYS.NVARCHAR(128);

UPDATE sys.babelfish_authid_login_ext SET orig_loginname = rolname WHERE orig_loginname IS NULL;

ALTER TABLE sys.babelfish_authid_login_ext ALTER COLUMN orig_loginname SET NOT NULL;

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'To use @@DBTS, set ''babelfishpg_tsql.escape_hatch_rowversion'' to ''ignore''';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE sys.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10) DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_dropserver_internal'
LANGUAGE C;

GRANT EXECUTE ON PROCEDURE sys.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10))
TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_dropserver( IN "@server" sys.sysname,
                                                    IN "@droplogins" sys.bpchar(10) DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_dropserver_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_dropserver OWNER TO sysadmin;


create or replace view sys.all_views as
SELECT
    CAST(c.relname AS sys.SYSNAME) as name
  , CAST(c.oid AS INT) as object_id
  , CAST(null AS INT) as principal_id
  , CAST(c.relnamespace as INT) as schema_id
  , CAST(0 as INT) as parent_object_id
  , CAST('V' as sys.bpchar(2)) as type
  , CAST('VIEW'as sys.nvarchar(60)) as type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
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
FROM pg_catalog.pg_namespace AS ns
INNER JOIN pg_class c ON ns.oid = c.relnamespace
INNER JOIN information_schema.views v ON c.relname = v.table_name AND ns.nspname = v.table_schema
WHERE c.relkind = 'v' AND ns.nspname in 
  (SELECT nspname from sys.babelfish_namespace_ext where dbid = sys.db_id() UNION ALL SELECT CAST('sys' AS NAME))
AND pg_is_other_temp_schema(ns.oid) = false
AND (pg_has_role(c.relowner, 'USAGE') = true
OR has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') = true
OR has_any_column_privilege(c.oid, 'SELECT, INSERT, UPDATE, REFERENCES') = true);
GRANT SELECT ON sys.all_views TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_set_session_context ("@key" sys.sysname, 
	"@value" sys.SQL_VARIANT, "@read_only" sys.bit = 0)
AS 'babelfishpg_tsql', 'sp_set_session_context'
LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_set_session_context TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.session_context ("@key" sys.sysname)
	RETURNS sys.SQL_VARIANT AS 'babelfishpg_tsql', 'session_context' LANGUAGE C;
GRANT EXECUTE ON FUNCTION sys.session_context TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_volatility(IN "@function_name" sys.varchar DEFAULT NULL, IN "@volatility" sys.varchar DEFAULT NULL)
AS 'babelfishpg_tsql', 'sp_babelfish_volatility' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_babelfish_volatility(IN sys.varchar, IN sys.varchar) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.babel_create_guest_schemas()
LANGUAGE C
AS 'babelfishpg_tsql', 'create_guest_schema_for_all_dbs';

CALL sys.babel_create_guest_schemas();

DROP PROCEDURE sys.babel_create_guest_schemas();

-- function sys.schema_id() should be changed from SQL to C-type function if not changed already
DO $$
BEGIN IF (SELECT count(*) FROM pg_proc as p where p.proname = 'schema_id' AND (p.pronargs = 0 AND (select l.lanname from pg_language as l where l.oid = p.prolang) = 'c'::name)) = 0 THEN
    ALTER FUNCTION sys.schema_id() RENAME TO sys_schema_id_deprecated_in_3_1_0;
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'sys_schema_id_deprecated_in_3_1_0');
END IF;
END $$;

-- function schema_id(varchar) needs to change input type to sys.SYSNAME if not changed already
DO $$
BEGIN IF (SELECT count(*) FROM pg_proc as p where p.proname = 'schema_id' AND (p.pronargs = 1 AND p.proargtypes[0] = 'sys.SYSNAME'::regtype)) = 0 THEN
    ALTER FUNCTION schema_id(schema_name VARCHAR) RENAME TO schema_id_deprecated_in_3_1_0;
    CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'schema_id_deprecated_in_3_1_0');
END IF;
END $$;

CREATE OR REPLACE FUNCTION schema_id()
RETURNS INT AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION schema_id(IN schema_name sys.SYSNAME)
RETURNS INT AS 'babelfishpg_tsql', 'schema_id' LANGUAGE C STABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION schema_id(schema_name sys.SYSNAME) TO PUBLIC;

/* set sys functions as STABLE */
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

CREATE OR REPLACE FUNCTION sys.OBJECT_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_name'
LANGUAGE C STABLE;

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
    X.indrelid as object_id
    , I.relname as name
    , case when X.indisclustered then 1 else 2 end as type
    , case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as type_desc
    , case when X.indisunique then 1 else 0 end as is_unique
    , I.reltablespace as data_space_id
    , 0 as ignore_dup_key
    , case when X.indisprimary then 1 else 0 end as is_primary_key
    , case when const.oid is null then 0 else 1 end as is_unique_constraint
    , 0 as fill_factor
    , case when X.indpred is null then 0 else 1 end as is_padded
    , case when X.indisready then 0 else 1 end as is_disabled
    , 0 as is_hypothetical
    , 1 as allow_row_locks
    , 1 as allow_page_locks
    , 0 as has_filter
    , null as filter_definition
    , 0 as auto_created
    , case when X.indisclustered then 1 else 1+row_number() over(partition by C.oid) end as index_id -- use rownumber to get index_id scoped on each objects
  from (pg_index X 
  -- get all the objects on which indexes can be created
  join pg_class C on C.oid=X.indrelid and C.relkind in ('r', 'm', 'p')
  -- get list of all indexes grouped by objects
  cross join pg_class I  
  )
  -- to get namespace information
  left join sys.schemas sch on I.relnamespace = sch.schema_id
  -- check if index is a unique constraint
  left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
  where has_schema_privilege(I.relnamespace, 'USAGE')
  and I.oid = X.indexrelid 
  and I.relkind = 'i' 
  -- index is active
  and X.indislive 
  -- filter to get all the objects that belong to sys or babelfish schemas
  and (sch.schema_id is not null or I.relnamespace::regnamespace::text = 'sys')

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
  left join sys.schemas sch on t.relnamespace = sch.schema_id
  where t.relkind = 'r'
  -- filter to get all the objects that belong to sys or babelfish schemas
  and (sch.schema_id is not null or t.relnamespace::regnamespace::text = 'sys')
  and has_schema_privilege(t.relnamespace, 'USAGE')
  and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')

) as indexes_select order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;

create or replace view  sys.sysindexes as
select
  i.object_id::integer as id
  , null::integer as status
  , null::binary(6) as first
  , i.index_id::smallint as indid
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

CREATE OR REPLACE VIEW sys.sp_special_columns_view AS
SELECT
CAST(1 AS SMALLINT) AS SCOPE,
CAST(coalesce (split_part(a.attoptions[1] COLLATE "C", '=', 2) ,a.attname) AS sys.sysname) AS COLUMN_NAME, -- get original column name if exists
CAST(t6.data_type AS SMALLINT) AS DATA_TYPE,

CASE -- cases for when they are of type identity. 
	WHEN  a.attidentity <> ''::"char" AND (t1.name = 'decimal' OR t1.name = 'numeric')
	THEN CAST(CONCAT(t1.name, '() identity') AS sys.sysname)
	WHEN  a.attidentity <> ''::"char" AND (t1.name != 'decimal' AND t1.name != 'numeric')
	THEN CAST(CONCAT(t1.name, ' identity') AS sys.sysname)
	ELSE CAST(t1.name AS sys.sysname)
END AS TYPE_NAME,

CAST(sys.sp_special_columns_precision_helper(COALESCE(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS PRECISION,
CAST(sys.sp_special_columns_length_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.precision, c1.max_length, t6."PRECISION") AS INT) AS LENGTH,
CAST(sys.sp_special_columns_scale_helper(coalesce(tsql_type_name, tsql_base_type_name), c1.scale) AS SMALLINT) AS SCALE,
CAST(1 AS smallint) AS PSEUDO_COLUMN,
CASE
	WHEN a.attnotnull
	THEN CAST(0 AS INT)
	ELSE CAST(1 AS INT) END
AS IS_NULLABLE,
CAST(nsp_ext.dbname AS sys.sysname) AS TABLE_QUALIFIER,
CAST(s1.name AS sys.sysname) AS TABLE_OWNER,
CAST(C.relname AS sys.sysname) AS TABLE_NAME,

CASE 
	WHEN X.indisprimary
	THEN CAST('p' AS sys.sysname)
	ELSE CAST('u' AS sys.sysname) -- if it is a unique index, then we should cast it as 'u' for filtering purposes
END AS CONSTRAINT_TYPE,
CAST(I.relname AS sys.sysname) CONSTRAINT_NAME,
CAST(X.indexrelid AS int) AS INDEX_ID

FROM( pg_index X
JOIN pg_class C ON X.indrelid = C.oid
JOIN pg_class I ON I.oid = X.indexrelid
CROSS JOIN LATERAL unnest(X.indkey) AS ak(k)
        LEFT JOIN pg_attribute a
                       ON (a.attrelid = X.indrelid AND a.attnum = ak.k)
)
LEFT JOIN sys.pg_namespace_ext nsp_ext ON C.relnamespace = nsp_ext.oid
LEFT JOIN sys.schemas s1 ON s1.schema_id = C.relnamespace
LEFT JOIN sys.columns c1 ON c1.object_id = X.indrelid AND cast(a.attname AS sys.sysname) = c1.name COLLATE sys.database_default
LEFT JOIN pg_catalog.pg_type AS T ON T.oid = c1.system_type_id
LEFT JOIN sys.types AS t1 ON a.atttypid = t1.user_type_id
LEFT JOIN sys.sp_datatype_info_helper(2::smallint, false) AS t6 ON T.typname = t6.pg_type_name OR T.typname = t6.type_name --need in order to get accurate DATA_TYPE value
, sys.translate_pg_type_to_tsql(t1.user_type_id) AS tsql_type_name
, sys.translate_pg_type_to_tsql(t1.system_type_id) AS tsql_base_type_name
WHERE has_schema_privilege(s1.schema_id, 'USAGE')
AND X.indislive ;

GRANT SELECT ON sys.sp_special_columns_view TO PUBLIC; 

CREATE OR REPLACE VIEW sys.server_principals
AS SELECT
CAST(Ext.orig_loginname AS sys.SYSNAME) AS name,
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE
    WHEN Ext.type = 'S' THEN 'SQL_LOGIN' 
    WHEN Ext.type = 'R' THEN 'SERVER_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_LOGIN'
    ELSE NULL 
  END
  AS NVARCHAR(60)) AS type_desc,
CAST(Ext.is_disabled AS INT) AS is_disabled,
CAST(Ext.create_date AS SYS.DATETIME) AS create_date,
CAST(Ext.modify_date AS SYS.DATETIME) AS modify_date,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.default_database_name END AS SYS.SYSNAME) AS default_database_name,
CAST(Ext.default_language_name AS SYS.SYSNAME) AS default_language_name,
CAST(CASE WHEN Ext.type = 'R' THEN NULL ELSE Ext.credential_id END AS INT) AS credential_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.owning_principal_id END AS INT) AS owning_principal_id,
CAST(CASE WHEN Ext.type = 'R' THEN 1 ELSE Ext.is_fixed_role END AS sys.BIT) AS is_fixed_role
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname;

CREATE OR REPLACE VIEW sys.database_principals AS SELECT
CAST(Ext.orig_username AS SYS.SYSNAME) AS name,
CAST(Base.oid AS INT) AS principal_id,
CAST(Ext.type AS CHAR(1)) as type,
CAST(
  CASE 
    WHEN Ext.type = 'S' THEN 'SQL_USER'
    WHEN Ext.type = 'R' THEN 'DATABASE_ROLE'
    WHEN Ext.type = 'U' THEN 'WINDOWS_USER'
    ELSE NULL 
  END 
  AS SYS.NVARCHAR(60)) AS type_desc,
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
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = DB_NAME();

CREATE OR REPLACE FUNCTION sys.original_login()
RETURNS sys.sysname
LANGUAGE plpgsql
STABLE STRICT
AS $$
declare return_value text;
begin
  RETURN (select orig_loginname from sys.babelfish_authid_login_ext where rolname = session_user)::sys.sysname;
EXCEPTION 
  WHEN others THEN
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION sys.systypes_precision_helper(IN type TEXT, IN max_length SMALLINT)
RETURNS SMALLINT
AS $$
DECLARE
	precision SMALLINT;
	v_type TEXT COLLATE sys.database_default := type;
BEGIN
	CASE
	WHEN v_type in ('text', 'ntext', 'image') THEN precision = CAST(NULL AS SMALLINT);
	WHEN v_type in ('nchar', 'nvarchar', 'sysname') THEN precision = max_length/2;
	WHEN v_type = 'sql_variant' THEN precision = 0;
	ELSE
		precision = max_length;
	END CASE;
	RETURN precision;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE VIEW sys.systypes AS
SELECT CAST(name as sys.sysname) as name
  , CAST(system_type_id as int) as xtype
  , CAST((case when is_nullable = 1 then 0 else 1 end) as sys.tinyint) as status
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as xusertype
  , max_length as length
  , CAST(precision as sys.tinyint) as xprec
  , CAST(scale as sys.tinyint) as xscale
  , CAST(default_object_id as int) as tdefault
  , CAST(rule_object_id as int) as domain
  , CAST((case when schema_id < 32767 then schema_id::int else null end) as smallint) as uid
  , CAST(0 as smallint) as reserved
  , CAST(sys.CollationProperty(collation_name, 'CollationId') as int) as collationid
  , CAST((case when user_type_id < 32767 then user_type_id::int else null end) as smallint) as usertype
  , CAST((case when (coalesce(sys.translate_pg_type_to_tsql(system_type_id), sys.translate_pg_type_to_tsql(user_type_id)) 
            in ('nvarchar', 'varchar', 'sysname', 'varbinary')) then 1 
          else 0 end) as sys.bit) as variable
  , CAST(is_nullable as sys.bit) as allownulls
  , CAST(system_type_id as int) as type
  , CAST(null as sys.varchar(255)) as printfmt
  , (case when precision <> 0::smallint then precision 
      else sys.systypes_precision_helper(sys.translate_pg_type_to_tsql(system_type_id), max_length) end) as prec
  , CAST(scale as sys.tinyint) as scale
  , CAST(collation_name as sys.sysname) as collation
FROM sys.types;
GRANT SELECT ON sys.systypes TO PUBLIC;

CREATE OR REPLACE FUNCTION OBJECT_DEFINITION(IN object_id INT)
RETURNS sys.NVARCHAR(4000)
AS $$
DECLARE
    definition sys.nvarchar(4000);
BEGIN

    definition = (SELECT cc.definition FROM sys.check_constraints cc WHERE cc.object_id = $1);
    IF (definition IS NULL)
    THEN
        definition = (SELECT dc.definition FROM sys.default_constraints dc WHERE dc.object_id = $1);
        IF (definition IS NULL)
        THEN
            definition = (SELECT asm.definition FROM sys.all_sql_modules asm WHERE asm.object_id = $1);
            IF (definition IS NULL)
            THEN
                RETURN NULL;
            END IF;
        END IF;
    END IF;

    RETURN definition;
END;
$$
LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys.openquery(
IN linked_server text,
IN query text)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql', 'openquery_internal'
LANGUAGE C VOLATILE;

CREATE OR REPLACE FUNCTION sys.OBJECT_SCHEMA_NAME(IN object_id INT, IN database_id INT DEFAULT NULL)
RETURNS sys.SYSNAME AS
'babelfishpg_tsql', 'object_schema_name'
LANGUAGE C STABLE;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('sp_addlinkedserver', 'master_dbo', 'P'),
    ('sp_addlinkedsrvlogin', 'master_dbo', 'P'),
    ('sp_dropserver', 'master_dbo', 'P'),
    ('sp_droplinkedsrvlogin', 'master_dbo', 'P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on t.schema_name = ns.nspname

union all

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name = b.orig_name
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

-- Disassociate procedures under master_dbo schema from the extension
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.sp_addlinkedserver(sys.sysname, sys.nvarchar, sys.nvarchar, sys.nvarchar, sys.nvarchar, sys.nvarchar, sys.sysname)');
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.sp_addlinkedsrvlogin(sys.sysname, sys.varchar, sys.sysname, sys.sysname, sys.sysname)');
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.sp_dropserver(sys.sysname, sys.bpchar)');
CALL sys.babelfish_remove_object_from_extension('procedure', 'master_dbo.sp_droplinkedsrvlogin(sys.sysname, sys.sysname)');

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
					ELSE LogExt.orig_loginname END
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
		AND Ext1.type != 'R'
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
					AND type != 'R')
	BEGIN
		SELECT CAST(Ext1.orig_username AS SYS.SYSNAME) AS 'UserName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN 'db_owner' 
					WHEN Ext2.orig_username IS NULL THEN 'public' 
					ELSE Ext2.orig_username END 
					AS SYS.SYSNAME) AS 'RoleName',
			   CAST(CASE WHEN Ext1.orig_username = 'dbo' THEN Base4.rolname
					ELSE LogExt.orig_loginname END
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
		AND Ext1.type != 'R'
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

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT -1)
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
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_varchar(IN typename TEXT,
                                                        IN arg ANYELEMENT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT -1)
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
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
														IN arg TEXT,
														IN p_style NUMERIC DEFAULT -1)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.VARCHAR);
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1)
RETURNS sys.VARCHAR
AS
$BODY$
DECLARE
	v_style SMALLINT;
BEGIN
	v_style := floor(p_style)::SMALLINT;

	CASE pg_typeof(arg)
	WHEN 'date'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_date_to_string(typename, arg, p_style);
		END IF;
	WHEN 'time'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg);
		ELSE
			RETURN sys.babelfish_try_conv_time_to_string(typename, 'TIME', arg, p_style);
		END IF;
	WHEN 'sys.datetime'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp);
		ELSE
			RETURN sys.babelfish_try_conv_datetime_to_string(typename, 'DATETIME', arg::timestamp, p_style);
		END IF;
	WHEN 'float'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg);
		ELSE
			RETURN sys.babelfish_try_conv_float_to_string(typename, arg, p_style);
		END IF;
	WHEN 'sys.money'::regtype THEN
		IF v_style = -1 THEN
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4)::pg_catalog.money);
		ELSE
			RETURN sys.babelfish_try_conv_money_to_string(typename, arg::numeric(19,4)::pg_catalog.money, p_style);
		END IF;
	ELSE
		RETURN CAST(arg AS sys.VARCHAR);
	END CASE;
END;
$BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT,
														IN arg TEXT,
														IN p_style NUMERIC DEFAULT -1)
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
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_varchar(IN typename TEXT,
														IN arg anyelement,
														IN p_style NUMERIC DEFAULT -1)
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
STABLE;

create or replace view sys.index_columns
as
select i.indrelid::integer as object_id
  , CAST(CASE WHEN i.indisclustered THEN 1 ELSE 1+row_number() OVER(PARTITION BY c.oid) END AS INTEGER) AS index_id
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

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);
DROP PROCEDURE sys.babelfish_remove_object_from_extension(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
