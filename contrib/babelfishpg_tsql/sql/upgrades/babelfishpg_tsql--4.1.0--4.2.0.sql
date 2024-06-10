-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.2.0'" to load this file. \quit

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
    when undefined_function then --if function does not exists
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- BABELFISH_SCHEMA_PERMISSIONS
CREATE TABLE IF NOT EXISTS sys.babelfish_schema_permissions (
  dbid smallint NOT NULL,
  schema_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_name sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  permission INT CHECK(permission > 0),
  grantee sys.NVARCHAR(128) NOT NULL COLLATE sys.database_default,
  object_type CHAR(1) NOT NULL COLLATE sys.database_default,
  function_args TEXT COLLATE "C",
  grantor sys.NVARCHAR(128) COLLATE sys.database_default,
  PRIMARY KEY(dbid, schema_name, object_name, grantee, object_type)
);

CREATE OR REPLACE FUNCTION sys.check_for_inconsistent_metadata()
RETURNS BOOLEAN AS $$
DECLARE
    has_inconsistent_metadata BOOLEAN;
    num_rows INT;
BEGIN
    has_inconsistent_metadata := FALSE;

    -- Count the number of inconsistent metadata rows from Babelfish catalogs
    SELECT COUNT(*) INTO num_rows
    FROM sys.babelfish_inconsistent_metadata();

    has_inconsistent_metadata := num_rows > 0;

    -- Additional checks can be added here to update has_inconsistent_metadata accordingly

    RETURN has_inconsistent_metadata;
END;
$$
LANGUAGE plpgsql STABLE;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_schema_permissions', '');

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
create or replace function sys.remove_accents_internal(IN TEXT) RETURNS sys.NVARCHAR
AS 'babelfishpg_tsql', 'remove_accents_internal'
LANGUAGE C
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS INTEGER
AS
$body$
BEGIN
    return sys.datediff_internal(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

-- datediff big
CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.date, IN enddate PG_CATALOG.date) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime, IN enddate sys.datetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetimeoffset, IN enddate sys.datetimeoffset) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.datetime2, IN enddate sys.datetime2) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate sys.smalldatetime, IN enddate sys.smalldatetime) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate::TIMESTAMP, enddate::TIMESTAMP);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.datediff_big(IN datepart PG_CATALOG.TEXT, IN startdate PG_CATALOG.time, IN enddate PG_CATALOG.time) RETURNS BIGINT
AS
$body$
BEGIN
    return sys.datediff_internal_big(datepart, startdate, enddate);
END
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

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
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate sys.bit) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate numeric) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;


CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate real) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate double precision) RETURNS DATETIME
AS
$body$
BEGIN
        return sys.dateadd_numeric_representation_helper(datepart, num, startdate);
END;
$body$
LANGUAGE plpgsql IMMUTABLE parallel safe;

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
LANGUAGE plpgsql IMMUTABLE parallel safe;

CREATE OR REPLACE FUNCTION sys.dateadd_numeric_representation_helper(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS DATETIME AS $$
DECLARE
    digit_to_startdate DATETIME;
BEGIN
    IF pg_typeof(startdate) IN ('bigint'::regtype, 'int'::regtype, 'smallint'::regtype,'sys.tinyint'::regtype,'sys.decimal'::regtype,
    'numeric'::regtype, 'float'::regtype,'double precision'::regtype, 'real'::regtype, 'sys.money'::regtype,'sys.smallmoney'::regtype,'sys.bit'::regtype) THEN
        digit_to_startdate := CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(startdate as sys.DATETIME);
    END IF;

    CASE datepart
	WHEN 'year' THEN
		RETURN digit_to_startdate + make_interval(years => num);
	WHEN 'quarter' THEN
		RETURN digit_to_startdate + make_interval(months => num * 3);
	WHEN 'month' THEN
		RETURN digit_to_startdate + make_interval(months => num);
	WHEN 'dayofyear', 'y' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'day' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'week' THEN
		RETURN digit_to_startdate + make_interval(weeks => num);
	WHEN 'weekday' THEN
		RETURN digit_to_startdate + make_interval(days => num);
	WHEN 'hour' THEN
		RETURN digit_to_startdate + make_interval(hours => num);
	WHEN 'minute' THEN
		RETURN digit_to_startdate + make_interval(mins => num);
	WHEN 'second' THEN
		RETURN digit_to_startdate + make_interval(secs => num);
	WHEN 'millisecond' THEN
		RETURN digit_to_startdate + make_interval(secs => (num::numeric) * 0.001);
	ELSE
		RAISE EXCEPTION 'The datepart % is not supported by date function dateadd for data type datetime.', datepart;
	END CASE;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE parallel safe;

/*
    This function is needed when input date is datetimeoffset type. When running the following query in postgres using tsql dialect, it faied.
        select dateadd(minute, -70, '2016-12-26 00:30:05.523456+8'::datetimeoffset);
    We tried to merge this function with sys.dateadd_internal by using '+' when adding interval to datetimeoffset, 
    but the error shows : operator does not exist: sys.datetimeoffset + interval. As the result, we should not use '+' directly
    but should keep using OPERATOR(sys.+) when input date is in datetimeoffset type.
*/
CREATE OR REPLACE FUNCTION sys.dateadd_internal_df(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate datetimeoffset)
RETURNS datetimeoffset AS
'babelfishpg_common', 'dateadd_datetimeoffset'
STRICT
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.dateadd_internal(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate ANYELEMENT) RETURNS ANYELEMENT AS $$
BEGIN
    IF pg_typeof(startdate) = 'time'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 0);
	END IF;
    IF pg_typeof(startdate) = 'date'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 1);
	END IF;
    IF pg_typeof(startdate) = 'sys.smalldatetime'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 2);
    END IF;
    IF (pg_typeof(startdate) = 'sys.datetime'::regtype or pg_typeof(startdate) = 'timestamp'::regtype) THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 3);
    END IF;
    IF pg_typeof(startdate) = 'sys.datetime2'::regtype THEN
        return sys.dateadd_internal_datetime(datepart, num, startdate, 4);
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql IMMUTABLE parallel safe;


CREATE OR REPLACE VIEW sys.index_columns
AS
WITH index_id_map AS MATERIALIZED (
  SELECT
    indexrelid,
    CASE
      WHEN indisclustered THEN 1
      ELSE 1+row_number() OVER(PARTITION BY indrelid ORDER BY indexrelid)
    END AS index_id
  FROM pg_index
)
SELECT
    CAST(i.indrelid AS INT) AS object_id,
    -- should match index_id of sys.indexes 
    CAST(imap.index_id AS INT) AS index_id,
    CAST(a.index_column_id AS INT) AS index_column_id,
    CAST(a.attnum AS INT) AS column_id,
    CAST(CASE
            WHEN a.index_column_id <= i.indnkeyatts THEN a.index_column_id
            ELSE 0
         END AS SYS.TINYINT) AS key_ordinal,
    CAST(0 AS SYS.TINYINT) AS partition_ordinal,
    CAST(CASE
            WHEN i.indoption[a.index_column_id-1] & 1 = 1 THEN 1
            ELSE 0 
         END AS SYS.BIT) AS is_descending_key,
    CAST(CASE
            WHEN a.index_column_id > i.indnkeyatts THEN 1
            ELSE 0
         END AS SYS.BIT) AS is_included_column
FROM
    pg_index i
    INNER JOIN index_id_map imap ON imap.indexrelid = i.indexrelid
    INNER JOIN pg_class c ON i.indrelid = c.oid
    INNER JOIN pg_namespace nsp ON nsp.oid = c.relnamespace
    LEFT JOIN sys.babelfish_namespace_ext ext ON (nsp.nspname = ext.nspname AND ext.dbid = sys.db_id())
    LEFT JOIN unnest(i.indkey) WITH ORDINALITY AS a(attnum, index_column_id) ON true
WHERE
    has_schema_privilege(c.relnamespace, 'USAGE') AND
    has_table_privilege(c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER') AND
    (nsp.nspname = 'sys' OR ext.nspname is not null) AND
    i.indislive;
GRANT SELECT ON sys.index_columns TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE STRICT
AS $$
DECLARE
    extra_bytes CONSTANT INTEGER := 4;
    return_value INTEGER;
BEGIN
	return_value:=
        CASE LOWER(property_name)
            WHEN 'charmaxlen' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.atttypmod > 0 THEN a.atttypmod - extra_bytes
                    ELSE NULL
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'allowsnull' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attnotnull THEN 0
                    ELSE 1
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'iscomputed' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN a.attgenerated != '' THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            WHEN 'columnid' COLLATE sys.database_default THEN
                (SELECT a.attnum FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND (a.attname = property COLLATE sys.database_default))
            WHEN 'ordinal' COLLATE sys.database_default THEN
                (SELECT b.count FROM (SELECT attname, row_number() OVER () AS count FROM pg_catalog.pg_attribute a
                 WHERE a.attrelid = object_id AND attisdropped = false AND attnum > 0 ORDER BY a.attnum) AS b WHERE b.attname = property COLLATE sys.database_default)
            WHEN 'isidentity' COLLATE sys.database_default THEN (SELECT
                CASE
                    WHEN char_length(a.attidentity) > 0 THEN 1
                    ELSE 0
                END FROM pg_catalog.pg_attribute a WHERE a.attrelid = object_id and (a.attname = property COLLATE sys.database_default))
            ELSE
                NULL
        END;
    RETURN return_value::INTEGER;
EXCEPTION 
	WHEN others THEN
 		RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION sys.columnproperty(object_id OID, property NAME, property_name TEXT) TO PUBLIC;

create or replace view sys.indexes as
-- Get all indexes from all system and user tables
with index_id_map as MATERIALIZED(
  select
    indexrelid,
    case
      when indisclustered then 1
      else 1+row_number() over(partition by indrelid order by indexrelid)
    end as index_id
  from pg_index
)
select
  cast(X.indrelid as int) as object_id
  , cast(I.relname as sys.sysname) as name
  , cast(case when X.indisclustered then 1 else 2 end as sys.tinyint) as type
  , cast(case when X.indisclustered then 'CLUSTERED' else 'NONCLUSTERED' end as sys.nvarchar(60)) as type_desc
  , cast(case when X.indisunique then 1 else 0 end as sys.bit) as is_unique
  , cast(I.reltablespace as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(case when X.indisprimary then 1 else 0 end as sys.bit) as is_primary_key
  , cast(case when const.oid is null then 0 else 1 end as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(case when X.indpred is null then 0 else 1 end as sys.bit) as is_padded
  , cast(case when X.indisready then 0 else 1 end as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(imap.index_id as int) as index_id
from pg_index X 
inner join index_id_map imap on imap.indexrelid = X.indexrelid
inner join pg_class I on I.oid = X.indexrelid and I.relkind = 'i'
inner join pg_namespace nsp on nsp.oid = I.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
-- check if index is a unique constraint
left join pg_constraint const on const.conindid = I.oid and const.contype = 'u'
where has_schema_privilege(I.relnamespace, 'USAGE')
-- index is active
and X.indislive 
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)

union all 
-- Create HEAP entries for each system and user table
select
  cast(t.oid as int) as object_id
  , cast(null as sys.sysname) as name
  , cast(0 as sys.tinyint) as type
  , cast('HEAP' as sys.nvarchar(60)) as type_desc
  , cast(0 as sys.bit) as is_unique
  , cast(1 as int) as data_space_id
  , cast(0 as sys.bit) as ignore_dup_key
  , cast(0 as sys.bit) as is_primary_key
  , cast(0 as sys.bit) as is_unique_constraint
  , cast(0 as sys.tinyint) as fill_factor
  , cast(0 as sys.bit) as is_padded
  , cast(0 as sys.bit) as is_disabled
  , cast(0 as sys.bit) as is_hypothetical
  , cast(1 as sys.bit) as allow_row_locks
  , cast(1 as sys.bit) as allow_page_locks
  , cast(0 as sys.bit) as has_filter
  , cast(null as sys.nvarchar) as filter_definition
  , cast(0 as sys.bit) as auto_created
  , cast(0 as int) as index_id
from pg_class t
inner join pg_namespace nsp on nsp.oid = t.relnamespace
left join sys.babelfish_namespace_ext ext on (nsp.nspname = ext.nspname and ext.dbid = sys.db_id())
where t.relkind = 'r'
-- filter to get all the objects that belong to sys or babelfish schemas
and (nsp.nspname = 'sys' or ext.nspname is not null)
and has_schema_privilege(t.relnamespace, 'USAGE')
and has_table_privilege(t.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
order by object_id, type_desc;
GRANT SELECT ON sys.indexes TO PUBLIC;


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
		IF upper(cs_as_in_table_type) LIKE '%''TABLE''%' THEN
			opt_table = 'TABLE';
		END IF;
		IF upper(cs_as_in_table_type) LIKE '%''VIEW''%' THEN
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
			    OR table_type = opt_table
			    OR table_type = opt_view)
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
			    OR table_type = opt_table
			    OR table_type = opt_view)
			ORDER BY table_qualifier, table_owner, table_name;
		END IF;
	END;
$$
LANGUAGE plpgsql STABLE;


CREATE OR REPLACE PROCEDURE sys.sp_renamedb(
	IN "@objname" sys.SYSNAME,
	IN "@newname" sys.SYSNAME
)
AS 'babelfishpg_tsql', 'sp_renamedb_internal'
LANGUAGE C;

CREATE OR REPLACE PROCEDURE sys.sp_rename(
	IN "@objname" sys.nvarchar(776) = NULL,
	IN "@newname" sys.SYSNAME = NULL,
	IN "@objtype" sys.varchar(13) DEFAULT NULL
)
LANGUAGE 'pltsql'
AS $$
BEGIN
	SET @objtype = TRIM(@objtype);
	If @objtype IS NULL
		BEGIN
			THROW 33557097, N'Please provide @objtype that is supported in Babelfish', 1;
		END
	ELSE IF @objtype = 'INDEX'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Index', 1;
		END
	ELSE IF @objtype = 'STATISTICS'
		BEGIN
			THROW 33557097, N'Feature not supported: renaming object type Statistics', 1;
		END
	ELSE IF @objtype = 'DATABASE'
		BEGIN
			exec sys.sp_renamedb @objname, @newname;
		END
	ELSE
		BEGIN
			DECLARE @subname sys.nvarchar(776);
			DECLARE @schemaname sys.nvarchar(776);
			DECLARE @dbname sys.nvarchar(776);
			DECLARE @curr_relname sys.nvarchar(776);
			
			EXEC sys.babelfish_sp_rename_word_parse @objname, @objtype, @subname OUT, @curr_relname OUT, @schemaname OUT, @dbname OUT;
			DECLARE @currtype char(2);
			IF @objtype = 'COLUMN'
				BEGIN
					DECLARE @col_count INT;
					SELECT @col_count = COUNT(*)FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @curr_relname and COLUMN_NAME = @subname;
					IF @col_count < 0
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'CO';
				END
			ELSE IF @objtype = 'USERDATATYPE'
				BEGIN
					DECLARE @alias_count INT;
					SELECT @alias_count = COUNT(*) FROM sys.types t1 INNER JOIN sys.schemas s1 ON t1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND t1.name = @subname;
					IF @alias_count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @alias_count < 1
						BEGIN
							THROW 33557097, N'There is no object with the given @objname.', 1;
						END
					SET @currtype = 'AL';				
				END
			ELSE IF @objtype = 'OBJECT'
				BEGIN
					DECLARE @count INT;
					SELECT type INTO #tempTable FROM sys.objects o1 INNER JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id 
					WHERE s1.name = @schemaname AND o1.name = @subname;
					SELECT @count = COUNT(*) FROM #tempTable;
					IF @count > 1
						BEGIN
							THROW 33557097, N'There are multiple objects with the given @objname.', 1;
						END
					IF @count < 1
						BEGIN
							-- TABLE TYPE: check if there is a match in sys.table_types (if we cannot alter sys.objects table_type naming)
							SELECT @count = COUNT(*) FROM sys.table_types tt1 INNER JOIN sys.schemas s1 ON tt1.schema_id = s1.schema_id 
							WHERE s1.name = @schemaname AND tt1.name = @subname;
							IF @count > 1
								BEGIN
									THROW 33557097, N'There are multiple objects with the given @objname.', 1;
								END
							ELSE IF @count < 1
								BEGIN
									THROW 33557097, N'There is no object with the given @objname.', 1;
								END
							ELSE
								BEGIN
									SET @currtype = 'TT'
								END
						END
					IF @currtype IS NULL
						BEGIN
							SELECT @currtype = type from #tempTable;
						END
					IF @currtype = 'TR' OR @currtype = 'TA'
						BEGIN
							DECLARE @physical_schema_name sys.nvarchar(776) = '';
							SELECT @physical_schema_name = nspname FROM sys.babelfish_namespace_ext WHERE dbid = sys.db_id() AND orig_name = @schemaname;
							SELECT @curr_relname = relname FROM pg_catalog.pg_trigger tr LEFT JOIN pg_catalog.pg_class c ON tr.tgrelid = c.oid LEFT JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid 
							WHERE tr.tgname = @subname AND n.nspname = @physical_schema_name;
						END
				END
			ELSE
				BEGIN
					THROW 33557097, N'Provided @objtype is not currently supported in Babelfish', 1;
				END
			EXEC sys.babelfish_sp_rename_internal @subname, @newname, @schemaname, @currtype, @curr_relname;
			PRINT 'Caution: Changing any part of an object name could break scripts and stored procedures.';
		END
END;
$$;
GRANT EXECUTE on PROCEDURE sys.sp_rename(IN sys.nvarchar(776), IN sys.SYSNAME, IN sys.varchar(13)) TO PUBLIC;

-- login_token
CREATE OR REPLACE VIEW sys.login_token
AS SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
ELSE 'SQL LOGIN' END AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.orig_loginname = sys.suser_name()
AND Ext.type in ('S','U')
UNION ALL
SELECT
CAST(Base.oid As INT) AS principal_id,
CAST(CAST(Base.oid as INT) as sys.varbinary(85)) AS sid,
CAST(Ext.orig_loginname AS sys.nvarchar(128)) AS name,
CAST('SERVER ROLE' AS sys.nvarchar(128)) AS type,
CAST ('GRANT OR DENY' as sys.nvarchar(128)) as usage
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_login_ext AS Ext ON Base.rolname = Ext.rolname
WHERE Ext.type = 'R' AND
(pg_has_role(sys.suser_id(), 'sysadmin'::TEXT, 'MEMBER'));

GRANT SELECT ON sys.login_token TO PUBLIC;

-- user_token
CREATE OR REPLACE VIEW sys.user_token AS
SELECT
CAST(Base.oid AS INT) AS principal_id,
CAST(CAST(Base2.oid AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST(Ext.orig_username AS SYS.NVARCHAR(128)) AS NAME,
CAST(CASE
WHEN Ext.type = 'U' THEN 'WINDOWS LOGIN'
ELSE 'SQL USER' END
AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
FROM pg_catalog.pg_roles AS Base INNER JOIN sys.babelfish_authid_user_ext AS Ext
ON Base.rolname = Ext.rolname
LEFT OUTER JOIN pg_catalog.pg_roles Base2
ON Ext.login_name = Base2.rolname
WHERE Ext.database_name = sys.DB_NAME()
AND Ext.rolname = CURRENT_USER
AND Ext.type in ('S','U')
UNION ALL
SELECT
CAST(-1 AS INT) AS principal_id,
CAST(CAST(-1 AS INT) AS SYS.VARBINARY(85)) AS SID,
CAST('public' AS SYS.NVARCHAR(128)) AS NAME,
CAST('ROLE' AS SYS.NVARCHAR(128)) AS TYPE,
CAST('GRANT OR DENY' as SYS.NVARCHAR(128)) as USAGE
WHERE (SELECT orig_username FROM sys.babelfish_authid_user_ext WHERE rolname = CURRENT_USER) != 'dbo';

GRANT SELECT ON sys.user_token TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_babelfish_configure(IN "@option_name" varchar(128),  IN "@option_value" varchar(128), IN "@option_scope" varchar(128))
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
    IF LOWER(normalized_name) = 'babelfishpg_tsql.escape_hatch_unique_constraint' COLLATE C THEN
      CALl sys.printarg('Config option babelfishpg_tsql.escape_hatch_unique_constraint has been deprecated, babelfish now supports unique constraints on nullable columns');
    ELSE
      RAISE EXCEPTION 'unknown configuration: %', normalized_name;
    END IF;
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

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_time(TEXT, BOOL, NUMERIC) RENAME TO babelfish_conv_helper_to_time_with_arg_text_deprecated_in_4_2_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_time(ANYELEMENT, BOOL, NUMERIC) RENAME TO babelfish_conv_helper_to_time_with_arg_anyelement_deprecated_in_4_2_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

DO $$
DECLARE
    exception_message text;
BEGIN
    ALTER FUNCTION sys.babelfish_conv_helper_to_datetime(TEXT, BOOL, NUMERIC) RENAME TO babelfish_conv_helper_to_datetime_deprecated_in_4_2_0;
EXCEPTION
    WHEN undefined_function THEN
        GET STACKED DIAGNOSTICS
        exception_message = MESSAGE_TEXT;
        RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.babelfish_get_microsecs_from_fractsecs_v2(IN p_fractsecs TEXT,
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

    v_rnd_fractsecs := round(v_fractsecs::INTEGER, (v_pureplaces_len - (v_scale - v_decplaces)) * (-1));

    IF (char_length(v_rnd_fractsecs::TEXT) > v_fractsecs_len) THEN
        RETURN '-1';
    END IF;

    v_fractsecs := lpad(v_rnd_fractsecs::TEXT, v_fractsecs_len, '0');

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
IMMUTABLE
RETURNS NULL ON NULL INPUT;

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
    v_sign VARCHAR COLLATE "C";
    v_offhours VARCHAR COLLATE "C";
    v_offminutes VARCHAR COLLATE "C";
    v_daypart VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_offset VARCHAR COLLATE "C";
    v_timeunit VARCHAR COLLATE "C";
    v_err_message VARCHAR COLLATE "C";
    v_timeunit_mask VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*([AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,2})\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*(\d{1,9})';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('((\-|\+)', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '|Z)');
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

    v_daypart := substring(v_timepart, AMPM_REGEXP);
    v_offset := substring(v_timepart, TIME_OFFSET_REGEXP);
    v_timepart := trim(regexp_replace(v_timepart, AMPM_REGEXP, ''));
    v_timepart := trim(regexp_replace(v_timepart, TIME_OFFSET_REGEXP, ''));

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
    
    v_regmatch_groups := regexp_matches(v_offset, TIME_OFFSET_REGEXP, 'gi');

    v_sign := coalesce(v_regmatch_groups[2], '+');
    v_offhours := coalesce(v_regmatch_groups[3], '0');
    v_offminutes := coalesce(v_regmatch_groups[4], '0');

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
              WHEN 'OFFHOURS' THEN v_offhours
              WHEN 'OFFMINUTES' THEN v_offminutes
              WHEN 'OFFSIGN' THEN v_sign
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

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime2(IN p_datatype TEXT,
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
    v_sign VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offhours VARCHAR COLLATE "C" = NULL::VARCHAR;
    v_offminutes VARCHAR COLLATE "C" = NULL::VARCHAR;
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
    v_language VARCHAR COLLATE "C";
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
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATE|TIME|DATETIME2|DATETIMEOFFSET)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('\s*((\-|\+)\s*(', TIMEUNIT_REGEXP, ')\s*\:\s*(', TIMEUNIT_REGEXP, ')|Z)\s*');
    HHMMSSFSOFF_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    HHMMSSFSOFF_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFSOFF_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');    
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*($comp_month$)\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)', '\s*(', HHMMSSFSOFF_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', COMPYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', SHORTYEAR_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*\,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*', SHORTYEAR_REGEXP, '$');
    DEFMASK9_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '($comp_month$)\s*\,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', COMPYEAR_REGEXP, '$');
    SLASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', COMPYEAR_REGEXP, '$');
    DOT_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*(\s+', '(', HHMMSSFSOFF_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
    DASH_FULLYEAR_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*', FULLYEAR_REGEXP, '\s*-\s*', DAYMM_REGEXP, '$');
    SLASH_FULLYEAR_SLASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*', FULLYEAR_REGEXP, '\s*\/\s*', DAYMM_REGEXP, '$');
    DOT_FULLYEAR_DOT1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*', FULLYEAR_REGEXP, '\s*\.\s*', DAYMM_REGEXP, '$');
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{4}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{6}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', '\s*\d{8}', '(\s+(', HHMMSSFSOFF_PART_REGEXP, '))?$');
    W3C_XML_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, '(', '(\-|\+)', '(\d{2})', '\:', '(\d{2})', '|', 'Z', ')','$');                                                        
    W3C_XML_Z_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'Z','$');
    ISO_8601_DATETIMEOFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'T', '\d{2}', '\:', '\d{1,2}', '\:', '\d{1,2}', '(?:\.', '\d{1,9}', ')?', '((\-|\+)', '\d{2}', '\:', '\d{2}','|Z)?$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_res_datatype = 'DATE' AND v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (coalesce(v_scale, 0) NOT BETWEEN 0 AND 7)
    THEN
        RAISE interval_field_overflow;
    ELSIF (v_scale IS NULL) THEN
        -- currently datetime2, datetimeoffset and time only support factional seconds
        -- upto 6 digits hence set v_scale to 6 to get consistent behaviour in datetime2(7) and datetime2
        v_scale := 6;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    ELSIF (NOT ((v_style BETWEEN 0 AND 14) OR
             (v_style BETWEEN 20 AND 25) OR
             (v_style BETWEEN 100 AND 114) OR
             (v_style IN (120, 121, 126, 127, 130, 131))))
    THEN
        RAISE invalid_parameter_value;
    END IF;

    -- For W3C_XML_REGEXP, there is no need of maintaining v_timepart and v_datestring
    IF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_timepart := NULL;
        v_datestring := NULL;
    ELSE
        v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFSOFF_PART_REGEXP, ')')));
        v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFSOFF_PART_REGEXP, ')'), '', 'gi'));
    END IF;

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
    EXCEPTION
        WHEN OTHERS THEN
        RAISE invalid_escape_sequence;
    END;

    v_date_format := coalesce(nullif(DATE_FORMAT, ''), v_lang_metadata_json ->> 'date_format');

    v_compmonth_regexp := array_to_string(array_cat(ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_shortnames')),
                                                    ARRAY(SELECT jsonb_array_elements_text(v_lang_metadata_json -> 'months_names'))), '|');

    -- If datetime string has some part as 'AMZ' or 'PMZ' then its invalid datetime format
    IF (v_datetimestring ~* pg_catalog.concat(AMPM_REGEXP, 'Z'))
    THEN
        RAISE invalid_datetime_format;
    END IF;

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
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK8_2_REGEXP, '$comp_month$', v_compmonth_regexp))
            THEN
                RAISE invalid_datetime_format;      
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK8_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[1]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            IF (v_datetimestring ~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) OR
                    (v_datestring !~* pg_catalog.replace(DEFMASK9_2_REGEXP, '$comp_month$', v_compmonth_regexp) AND
                     v_datestring !~* pg_catalog.replace(DEFMASK9_3_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK9_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := '01';
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[2]);
        ELSE
            IF ((v_datestring !~* pg_catalog.replace(DEFMASK10_2_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_3_REGEXP, '$comp_month$', v_compmonth_regexp)) AND
                (v_datestring !~* pg_catalog.replace(DEFMASK10_4_REGEXP, '$comp_month$', v_compmonth_regexp)))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK10_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* SLASH_COMPYEAR1_1_REGEXP) AND
            (v_datestring !~* DOT_COMPYEAR1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF ((v_style IN (1, 10, 22)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                    RAISE character_not_in_repertoire;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (101, 110)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            ELSE
                RAISE invalid_datetime_format;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 22, 101, 103, 104, 105, 110, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        -- DATEFORMAT 'YDM' is not supported hence only applicable dateformat can be used here is YMD
        v_year := v_regmatch_groups[1];
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF ((v_datestring !~* DASH_FULLYEAR_DASH1_1_REGEXP) AND
            (v_datestring !~* SLASH_FULLYEAR_SLASH1_1_REGEXP) AND
            (v_datestring !~* DOT_FULLYEAR_DOT1_1_REGEXP))
        THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_style IN (6, 7, 8, 9, 12, 13, 14, 24, 100, 106, 107, 108, 109, 112, 113, 114, 130))
        THEN
            RAISE invalid_regular_expression;
        ELSIF (v_style IN (1, 2, 3, 4, 5, 10, 11, 20, 21, 22, 23, 25, 101, 102, 103, 104, 105, 110, 111, 120, 121, 126, 127, 131)) THEN
            RAISE invalid_datetime_format;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF ((v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP))
    THEN
        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
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
    ELSIF (v_datetimestring ~* HHMMSSFSOFF_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, W3C_XML_REGEXP, 'gi');
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];

        IF (v_datetimestring !~* W3C_XML_Z_REGEXP)
        THEN
            v_sign := v_regmatch_groups[5];
            v_offhours := v_regmatch_groups[6];
            v_offminutes := v_regmatch_groups[7];
            IF ((v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
                (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
                (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
            THEN
                RAISE invalid_datetime_format;
            END IF;
        ELSE
            v_sign := '+';
            v_offhours := '0';
            v_offminutes := '0';
        END IF;
    ELSIF (v_datetimestring ~* ISO_8601_DATETIMEOFFSET_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIMEOFFSET_REGEXP, 'gi');
        
        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    IF (v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');

        -- v_offhours and v_offminutes will be already set for W3C_XML datetime string format
        v_sign := coalesce(v_sign, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFSIGN'), '+');
        v_offhours := coalesce(v_offhours, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFHOURS'), '0');
        v_offminutes := coalesce(v_offminutes, sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFMINUTES'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;

    -- validate time and offset
    IF ((v_hours::SMALLINT NOT BETWEEN 0 AND 23) OR
        (v_minutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_seconds::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
        (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;
    
    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$') AND char_length(v_fseconds) > 3)
    THEN
        RAISE invalid_datetime_format;
    END IF;

    IF (v_timepart !~* PG_CATALOG.concat('^(', HHMMSSFSOFF_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a ':'
        v_fseconds := lpad(v_fseconds, 3, '0');
    END IF;

    IF (v_scale = 0) THEN
        v_seconds := concat_ws('.', v_seconds, v_fseconds);
        v_seconds := round(v_seconds::NUMERIC, 0)::TEXT;
    ELSE
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(v_fseconds, v_scale);
        
        -- Following condition will handle overflow of fractsecs
        IF (v_fseconds::INTEGER < 0) THEN
            v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
            v_seconds := (v_seconds::INTEGER + 1)::TEXT;
        END IF;

        v_seconds := concat_ws('.', v_seconds, v_fseconds);
    END IF;

    IF (v_res_datatype = 'DATE')
    THEN
        v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,0,0,0);
    ELSIF (v_res_datatype = 'TIME')
    THEN
        v_resdatetime := make_timestamp(9999, 12, 31, v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);        
    ELSE
        v_resdatetime := make_timestamp(v_year::SMALLINT, v_month::SMALLINT, v_day::SMALLINT,
                                            v_hours::SMALLINT, v_minutes::SMALLINT, v_seconds::NUMERIC);
    END IF;

    IF (v_resdatetime > make_timestamp(9999, 12, 31, 23, 59, 59.999999)) THEN
        -- if rounding of fractional seconds caused the date and time to go out of range 
        -- then max date and time that can be stored for p_datatype will be used
        v_resdatetime := make_timestamp(9999, 12, 31, 23, 59, concat_ws('.', '59', PG_CATALOG.repeat('9', LEAST(v_scale, 6)))::NUMERIC); 
    END IF;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of conv_string_to_datetime2 function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATE'', ''TIME''/''TIME(n)'', ''DATETIME2''/''DATETIME2(n)'', ''DATETIMEOFFSET''/''DATETIMEOFFSET(n)''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('CAST or CONVERT: invalid attributes specified for type ''%s''', v_res_datatype),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Conversion failed when converting date and/or time from character string.',
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE :=  pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

    WHEN character_not_in_repertoire THEN
        RAISE USING MESSAGE := 'This session''s YDM date format is not supported when converting from this character string format to date, time, datetime2 or datetimeoffset. Change the session''s date format or provide a style to the explicit conversion.',
                    DETAIL := 'Use of incorrect DATE_FORMAT constant value regarding string format parameter during conversion process.',
                    HINT := 'Change DATE_FORMAT constant to one of these values: MDY|DMY|DYM, recompile function and try again.';

    WHEN invalid_escape_sequence THEN
        RAISE USING MESSAGE := pg_catalog.format('Invalid CONVERSION_LANG constant value - ''%s''. Allowed values are: ''English'', ''Deutsch'', etc.',
                                      CONVERSION_LANG),
                    DETAIL := 'Compiled incorrect CONVERSION_LANG constant value in function''s body.',
                    HINT := 'Correct CONVERSION_LANG constant value in function''s body, recompile it and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetime_v2(IN p_datatype TEXT,
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
    v_language VARCHAR COLLATE "C";
    CONVERSION_LANG CONSTANT VARCHAR COLLATE "C" := '';
    DATE_FORMAT CONSTANT VARCHAR COLLATE "C" := '';
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    COMPYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2}|\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    MASKSEP_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:\.|-|/)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,3}\s*';
    DATATYPE_REGEXP CONSTANT VARCHAR COLLATE "C" := '^(DATETIME|SMALLDATETIME)\s*(?:\()?\s*((?:-)?\d+)?\s*(?:\))?$';
    HHMMSSFS_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_DOT_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat( TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\.', FRACTSECS_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                        TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.)', FRACTSECS_REGEXP, AMPM_REGEXP, '?');
    HHMMSSFS_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')$');
    DEFMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK1_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s+', COMPYEAR_REGEXP, '$');
    DEFMASK2_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK2_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK2_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)\s*,?\s*', COMPYEAR_REGEXP, '$');
    DEFMASK3_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK3_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '$');
    DEFMASK3_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '$');
    DEFMASK4_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*', '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK4_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '?\s*($comp_month$)$');
    DEFMASK4_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '\s*(?:,|', MASKSEP_REGEXP, ')', '\s*($comp_month$)$');
    DEFMASK5_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK5_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK5_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s+|\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK5_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '(?:\s*,\s*)', COMPYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK6_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK6_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK6_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', FULLYEAR_REGEXP, '\s+', DAYMM_REGEXP, '$');
    DEFMASK7_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK7_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK7_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,\s*', DAYMM_REGEXP, '\s*,\s*', COMPYEAR_REGEXP, '$');
    DEFMASK8_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)',
                                                 '\s*(', HHMMSSFS_PART_REGEXP, ')?$');
    DEFMASK8_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '?\s*($comp_month$)$');
    DEFMASK8_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)$');
    DEFMASK9_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', HHMMSSFS_PART_REGEXP, ')?\s*',
                                                 MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP,
                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK9_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '?\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK9_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', MASKSEP_REGEXP, '\s*($comp_month$)\s*,?\s*', FULLYEAR_REGEXP, '$');
    DEFMASK10_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                  DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP,
                                                  '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DEFMASK10_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*($comp_month$)\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_2_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*-\s*($comp_month$)\s*-\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_3_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\/\s*($comp_month$)\s*\/\s*', COMPYEAR_REGEXP, '$');
    DEFMASK10_4_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*\.\s*($comp_month$)\s*\.\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_COMPYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', COMPYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_COMPYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', COMPYEAR_REGEXP, '$');
    DOT_SLASH_DASH_SHORTYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', SHORTYEAR_REGEXP, '$');
    DOT_SLASH_DASH_FULLYEAR1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', DAYMM_REGEXP, '\s*(?:\.|/|-)\s*', FULLYEAR_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '$');
    
    FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');

    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*',
                                                                 DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP,
                                                                 '\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', DAYMM_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', FULLYEAR_REGEXP, '\s*', MASKSEP_REGEXP, '\s*', DAYMM_REGEXP, '$');
  
    FULLYEAR_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{4}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    SHORT_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{6}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    FULL_DIGITMASK1_0_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^(', '(', HHMMSSFS_PART_REGEXP, ')', '\s+)?\s*\d{8}\s*(\s+', '(', HHMMSSFS_PART_REGEXP, ')', ')?$');
    ISO_8601_DATETIME_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', '(\d{2})', '-', '(\d{2})', 'T', '\d{2}', '\:', '\d{2}', '\:', '\d{2}', '(?:\.', FRACTSECS_REGEXP, ')?','$');
BEGIN
    v_datatype := trim(p_datatype);
    v_datetimestring := upper(trim(p_datetimestring));
    v_style := floor(p_style)::SMALLINT;

    v_datatype_groups := regexp_matches(v_datatype, DATATYPE_REGEXP, 'gi');

    v_res_datatype := upper(v_datatype_groups[1]);
    v_scale := v_datatype_groups[2]::SMALLINT;

    IF (v_res_datatype IS NULL) THEN
        RAISE datatype_mismatch;
    ELSIF (v_scale IS NOT NULL)
    THEN
        RAISE invalid_indicator_parameter_value;
    ELSIF (v_scale IS NULL) THEN
        v_scale := 7;
    END IF;

    IF (scale(p_style) > 0) THEN
        RAISE most_specific_type_mismatch;
    END IF;

    v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFS_PART_REGEXP, ')')));
    v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFS_PART_REGEXP, ')'), '', 'gi'));

    v_language := CASE
                    WHEN (v_style IN (130, 131)) THEN 'HIJRI'
                    ELSE CONVERSION_LANG
                  END;

    BEGIN
        v_lang_metadata_json := sys.babelfish_get_lang_metadata_json(v_language);
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
        IF (v_style = 127) THEN
            RAISE invalid_datetime_format;
        END IF;

        IF (v_datestring ~* pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK1_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[2];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[1], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);

        ELSIF (v_datestring ~* pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp))
        THEN
            v_regmatch_groups := regexp_matches(v_datestring, pg_catalog.replace(DEFMASK2_1_REGEXP, '$comp_month$', v_compmonth_regexp), 'gi');
            v_day := v_regmatch_groups[1];
            v_month := sys.babelfish_get_monthnum_by_name(v_regmatch_groups[2], v_lang_metadata_json);
            
            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
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

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[2]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
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

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
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

            -- For v_style 130 and 131, 1 or 2 digit year is out of range
            IF (v_style IN (130, 131) AND v_regmatch_groups[3]::SMALLINT <= 99)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
            v_year := sys.babelfish_get_full_year(v_regmatch_groups[3]);
        ELSE
            RAISE invalid_character_value_for_cast;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_COMPYEAR1_0_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_COMPYEAR1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_datestring ~* DOT_SLASH_DASH_SHORTYEAR_REGEXP)
        THEN
            IF (v_style NOT IN (0, 1, 2, 3, 4, 5, 10, 11))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            IF ((v_style IN (1, 10)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MDY'))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IN (2, 11)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YMD'))
            THEN
                v_day := v_rightpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_leftpart);

            ELSIF ((v_style IN (3, 4, 5)) OR
                   ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DMY'))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;
                v_year := sys.babelfish_get_full_year(v_rightpart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'DYM')
            THEN
                v_day = v_leftpart;
                v_month = v_rightpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'MYD')
            THEN
                v_day := v_rightpart;
                v_month := v_leftpart;
                v_year = sys.babelfish_get_full_year(v_middlepart);

            ELSIF ((v_style IS NULL OR v_style = 0) AND v_date_format = 'YDM')
            THEN
                v_day := v_middlepart;
                v_month := v_rightpart;
                v_year := sys.babelfish_get_full_year(v_leftpart);
            END IF;
        ELSIF (v_datestring ~* DOT_SLASH_DASH_FULLYEAR1_1_REGEXP)
        THEN
            IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
            THEN
                RAISE invalid_datetime_format;
            END IF;

            v_year := v_rightpart;
            IF ((v_style IN (103, 104, 105, 130, 131)) OR
                ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
            THEN
                v_day := v_leftpart;
                v_month := v_middlepart;

            ELSIF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
                    ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
            THEN
                v_day := v_middlepart;
                v_month := v_leftpart;
            END IF;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style NOT IN (0, 20, 21, 101, 102, 103, 104, 105, 110, 111, 120, 121, 130, 131))
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_year := v_regmatch_groups[1];
        v_middlepart := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF ((v_style IN (20, 21, 101, 102, 110, 111, 120, 121)) OR
            ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('MDY', 'MYD', 'YMD')))
        THEN
            v_day := v_rightpart;
            v_month := v_middlepart;

        ELSIF ((v_style IN (103, 104, 105, 130, 131)) OR
               ((v_style IS NULL OR v_style = 0) AND v_date_format IN ('DMY', 'DYM', 'YDM')))
        THEN
            v_day := v_middlepart;
            v_month := v_rightpart;
        END IF;
    ELSIF (v_datetimestring ~* DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_0_REGEXP)
    THEN
        IF (v_style IS NOT NULL AND v_style != 0)
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        v_regmatch_groups := regexp_matches(v_datestring, DOT_SLASH_DASH_FULLYEAR_DOT_SLASH_DASH1_1_REGEXP, 'gi');
        v_leftpart := v_regmatch_groups[1];
        v_year := v_regmatch_groups[2];
        v_rightpart := v_regmatch_groups[3];

        IF (v_date_format IN ('MYD', 'MDY', 'YMD'))
        THEN
            v_day := v_rightpart;
            v_month := v_leftpart;
        ELSIF (v_date_format IN ('DYM', 'DMY', 'YDM'))
        THEN
            v_day := v_leftpart;
            v_month := v_rightpart;
        ELSE
            RAISE invalid_datetime_format;
        END IF;
    ELSIF (v_datetimestring ~* FULLYEAR_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* SHORT_DIGITMASK1_0_REGEXP OR
           v_datetimestring ~* FULL_DIGITMASK1_0_REGEXP)
    THEN
        IF (v_style = 127 AND v_datestring !~* '^\d{4}$')
        THEN
            RAISE invalid_datetime_format;
        ELSIF (v_style IN (130, 131) AND v_res_datatype = 'SMALLDATETIME')
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        IF (v_datestring ~* '^\d{4}$')
        THEN
            v_day := '01';
            v_month := '01';
            v_year := substr(v_datestring, 1, 4);

        ELSIF (v_datestring ~* '^\d{6}$')
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
    ELSIF (v_datetimestring ~* HHMMSSFS_REGEXP OR length(v_datetimestring) = 0)
    THEN
        v_day := '01';
        v_month := '01';
        v_year := '1900';
    ELSIF (v_datetimestring ~* ISO_8601_DATETIME_REGEXP)
    THEN
        IF (v_style IN (130, 131))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;
        v_regmatch_groups := regexp_matches(v_datetimestring, ISO_8601_DATETIME_REGEXP, 'gi');

        v_day := v_regmatch_groups[3];
        v_month := v_regmatch_groups[2];
        v_year := v_regmatch_groups[1];
    ELSE
        RAISE invalid_datetime_format;
    END IF;

    -- DATETIME/SMALLDATETIME supports time part in either left or right side of date part, 
    -- but having time on both side of date part should throw error
    IF ((SELECT COUNT(*) FROM regexp_matches(v_datetimestring, HHMMSSFS_PART_REGEXP)) > 1)
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF ((v_datetimestring !~* HHMMSSFS_REGEXP AND
         length(v_datetimestring) != 0) AND
        v_style IN (130, 131))
    THEN
        -- validate date according to hijri date format
        IF ((v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
            (v_day::SMALLINT NOT BETWEEN 1 AND 30) OR
            ((MOD(v_month::SMALLINT, 2) = 0 AND v_month::SMALLINT != 12) AND v_day::SMALLINT = 30))
        THEN
            RAISE invalid_character_value_for_cast;
        END IF;

        -- for hijri leap year
        IF (v_month::SMALLINT = 12)
        THEN
            -- check for a leap year
            IF (MOD(v_year::SMALLINT, 30) IN (2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29))
            THEN
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 30)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            ELSE
                IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
                THEN
                    RAISE invalid_character_value_for_cast;
                END IF;
            END IF;
        END IF;

        v_hijridate := sys.babelfish_conv_hijri_to_greg(v_day, v_month, v_year) - 1;
        v_day = to_char(v_hijridate, 'DD');
        v_month = to_char(v_hijridate, 'MM');
        v_year = to_char(v_hijridate, 'YYYY');
    END IF;

    BEGIN
        v_hours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'HOURS'), '0');
        v_minutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'MINUTES'), '0');
        v_seconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'SECONDS'), '0');
        v_fseconds := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'FRACTSECONDS'), '0');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE invalid_character_value_for_cast;
    END;
    
    -- validate time
    IF ((v_hours::SMALLINT NOT BETWEEN 0 AND 23) OR
        (v_minutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_seconds::SMALLINT NOT BETWEEN 0 AND 59))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    -- validate date according to gregorian date format    
    IF ((v_year::SMALLINT NOT BETWEEN 1 AND 9999) OR
        (v_month::SMALLINT NOT BETWEEN 1 AND 12) OR
        ((v_month::SMALLINT IN (1,3,5,7,8,10,12)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 31)) OR
        ((v_month::SMALLINT IN (4,6,9,11)) AND (v_day::SMALLINT NOT BETWEEN 1 AND 30)) OR
        ((v_res_datatype = 'DATETIME') AND (v_year::SMALLINT NOT BETWEEN 1753 AND 9999)) OR
        ((v_res_datatype = 'SMALLDATETIME') AND 
            ((v_year::SMALLINT NOT BETWEEN 1900 AND 2079) OR
             (v_year::SMALLINT = 2079 AND 
                ((v_month::SMALLINT NOT BETWEEN 1 AND 6) OR (v_day::SMALLINT NOT BETWEEN 1 AND 6))))))
    THEN
        RAISE invalid_character_value_for_cast;
    ELSIF (v_month::SMALLINT = 2)
    THEN
        -- check for a leap year
        IF ((v_year::SMALLINT % 4 = 0) AND ((v_year::SMALLINT % 100 <> 0) or (v_year::SMALLINT % 400 = 0)))
        THEN
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 29)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        ELSE
            IF (v_day::SMALLINT NOT BETWEEN 1 AND 28)
            THEN
                RAISE invalid_character_value_for_cast;
            END IF;
        END IF;
    END IF;

    -- validate boundary condition for date and time
    IF ((v_res_datatype = 'SMALLDATETIME' AND 
         (v_year::SMALLINT = 2079 AND v_month::SMALLINT = 6 AND v_day::SMALLINT = 6 AND 
            v_hours::SMALLINT = 23 AND v_minutes::SMALLINT = 59 AND 
                (v_seconds::SMALLINT > 29 OR (v_seconds::SMALLINT = 29 AND v_fseconds::SMALLINT > 998)))) OR
        (v_res_datatype = 'DATETIME' AND 
         (v_year::SMALLINT = 9999 AND v_month::SMALLINT = 12 AND v_day::SMALLINT = 31 AND 
            v_hours::SMALLINT = 23 AND v_minutes::SMALLINT = 59 AND v_seconds::SMALLINT = 59 AND v_fseconds::SMALLINT > 998))
        )
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    IF (v_timepart ~* PG_CATALOG.concat('^(', HHMMSSFS_DOT_PART_REGEXP, ')$')) THEN
        -- if before fractional seconds there is a '.'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            rpad(v_fseconds, 3, '0'));
    ELSE
        -- if before fractional seconds there is a ':'
        v_resdatetime := sys.datetimefromparts(v_year, v_month, v_day,
                                                            v_hours, v_minutes, v_seconds,
                                                            lpad(v_fseconds, 3, '0'));
    END IF;

    IF (v_res_datatype = 'SMALLDATETIME' AND
        to_char(v_resdatetime, 'SS') <> '00')
    THEN
        IF (to_char(v_resdatetime, 'SS')::SMALLINT >= 30) THEN
            v_resdatetime := v_resdatetime + INTERVAL '1 minute';
        END IF;

        v_resdatetime := to_timestamp(to_char(v_resdatetime, 'DD.MM.YYYY.HH24.MI'), 'DD.MM.YYYY.HH24.MI');
    END IF;

    RETURN v_resdatetime;
EXCEPTION
    WHEN most_specific_type_mismatch THEN
        RAISE USING MESSAGE := 'Argument data type numeric is invalid for argument 3 of convert function.',
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('The style %s is not supported for conversions from varchar to %s.', v_style, PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect "style" parameter value during conversion process.',
                    HINT := 'Change "style" parameter to the proper value and try again.';

    WHEN invalid_regular_expression THEN
        RAISE USING MESSAGE := pg_catalog.format('The input character string does not follow style %s, either change the input character string or use a different style.', v_style),
                    DETAIL := 'Selected "style" param value isn''t valid for conversion of passed character string.',
                    HINT := 'Either change the input character string or use a different style.';

    WHEN datatype_mismatch THEN
        RAISE USING MESSAGE := 'Data type should be one of these values: ''DATETIME'', ''SMALLDATETIME''.',
                    DETAIL := 'Use of incorrect "datatype" parameter value during conversion process.',
                    HINT := 'Change "datatype" parameter to the proper value and try again.';

    WHEN invalid_indicator_parameter_value THEN
        RAISE USING MESSAGE := pg_catalog.format('CAST or CONVERT: invalid attributes specified for type ''%s''', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect scale value, which is not corresponding to specified data type.',
                    HINT := 'Change data type scale component or select different data type and try again.';

    WHEN interval_field_overflow THEN
        RAISE USING MESSAGE := pg_catalog.format('Specified scale %s is invalid.', v_scale),
                    DETAIL := 'Use of incorrect data type scale value during conversion process.',
                    HINT := 'Change scale component of data type parameter to be in range [0..7] and try again.';

    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := CASE v_res_datatype
                                  WHEN 'SMALLDATETIME' THEN 'Conversion failed when converting character string to smalldatetime data type.'
                                  ELSE 'Conversion failed when converting date and/or time from character string.'
                               END,
                    DETAIL := 'Incorrect using of pair of input parameters values during conversion process.',
                    HINT := 'Check the input parameters values, correct them if needed, and try again.';

    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := pg_catalog.format('The conversion of a varchar data type to a %s data type resulted in an out-of-range value.', PG_CATALOG.lower(v_res_datatype)),
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';

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
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_string_to_datetimeoffset(IN p_datatype TEXT,
                                                                     IN p_datetimestring TEXT,
                                                                     IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_sign VARCHAR COLLATE "C";
    v_offhours VARCHAR COLLATE "C";
    v_offminutes VARCHAR COLLATE "C";
    v_timepart VARCHAR COLLATE "C";
    v_datestring VARCHAR COLLATE "C";
    v_datetimestring VARCHAR COLLATE "C";
    v_regmatch_groups TEXT[];
    v_resdatetime TIMESTAMP(6) WITHOUT TIME ZONE;
    v_resdatetime_string VARCHAR COLLATE "C";
    DAYMM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{1,2})';
    FULLYEAR_REGEXP CONSTANT VARCHAR COLLATE "C" := '(\d{4})';
    AMPM_REGEXP CONSTANT VARCHAR COLLATE "C" := '(?:[AP]M)';
    TIMEUNIT_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,2}\s*';
    FRACTSECS_REGEXP CONSTANT VARCHAR COLLATE "C" := '\s*\d{1,9}\s*';
    TIME_OFFSET_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('\s*((\-|\+)\s*(', TIMEUNIT_REGEXP, ')\s*\:\s*(', TIMEUNIT_REGEXP, ')|Z)\s*');
    HHMMSSFSOFF_PART_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('(', TIMEUNIT_REGEXP, AMPM_REGEXP, '|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, AMPM_REGEXP, '?|',
                                                    TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '\:', TIMEUNIT_REGEXP, '(?:\.|\:)', FRACTSECS_REGEXP, AMPM_REGEXP, '?)(', TIME_OFFSET_REGEXP, ')?');
    W3C_XML_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, '(', '(\-|\+)', '\s*(\d{2})\s*', '\:', '\s*(\d{2})\s*', '|', 'Z', ')','$');
    W3C_XML_Z_REGEXP CONSTANT VARCHAR COLLATE "C" := concat('^', FULLYEAR_REGEXP, '-', DAYMM_REGEXP, '-', DAYMM_REGEXP, 'Z','$');
BEGIN
    v_datetimestring := upper(trim(p_datetimestring));
    -- datetimestring validation and conversion will be done in babelfish_conv_string_to_datetime2 function and a timestamp will be returned 
    v_resdatetime := sys.babelfish_conv_string_to_datetime2(p_datatype, p_datetimestring, p_style);

    v_timepart := trim(substring(v_datetimestring, PG_CATALOG.concat('(', HHMMSSFSOFF_PART_REGEXP, ')')));
    v_datestring := trim(regexp_replace(v_datetimestring, PG_CATALOG.concat('T?', '(', HHMMSSFSOFF_PART_REGEXP, ')'), '', 'gi'));

    -- Get the time offset value
    IF (v_datetimestring ~* W3C_XML_REGEXP)
    THEN
        v_regmatch_groups := regexp_matches(v_datetimestring, W3C_XML_REGEXP, 'gi');

        IF (v_datetimestring !~* W3C_XML_Z_REGEXP)
        THEN
            v_sign := v_regmatch_groups[5];
            v_offhours := v_regmatch_groups[6];
            v_offminutes := v_regmatch_groups[7];
        ELSE
            v_sign := '+';
            v_offhours := '0';
            v_offminutes := '0';
        END IF; 
    ELSE
        BEGIN
            v_sign := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFSIGN'), '+');
            v_offhours := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFHOURS'), '0');
            v_offminutes := coalesce(sys.babelfish_get_timeunit_from_string(v_timepart, 'OFFMINUTES'), '0');
        EXCEPTION
            WHEN OTHERS THEN
                RAISE invalid_character_value_for_cast;
        END;
    END IF;

    -- validate offset
    IF ((v_offhours::SMALLINT NOT BETWEEN 0 AND 14) OR
        (v_offminutes::SMALLINT NOT BETWEEN 0 AND 59) OR
        (v_offhours::SMALLINT = 14 AND v_offminutes::SMALLINT != 0))
    THEN
        RAISE invalid_character_value_for_cast;
    END IF;

    v_resdatetime_string := PG_CATALOG.concat(v_resdatetime::PG_CATALOG.TEXT,v_sign,v_offhours,':',v_offminutes);

    RETURN CAST(v_resdatetime_string AS sys.datetimeoffset);
EXCEPTION
    WHEN invalid_character_value_for_cast THEN
        RAISE USING MESSAGE := 'The conversion of a varchar data type to a datetimeoffset data type resulted in an out-of-range value.',
                    DETAIL := 'Use of incorrect pair of input parameter values during conversion process.',
                    HINT := 'Check input parameter values, correct them if needed, and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetime2(IN p_datatype TEXT,
                                                                    IN p_datetimestring TEXT,
                                                                    IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetime2(p_datatype,
                                                    p_datetimestring,
                                                    p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetime_v2(IN p_datatype TEXT,
                                                                         IN p_datetimestring TEXT,
                                                                         IN p_style NUMERIC DEFAULT 0)
RETURNS TIMESTAMP WITHOUT TIME ZONE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetime_v2(p_datatype,
                                                     p_datetimestring ,
                                                     p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_string_to_datetimeoffset(IN p_datatype TEXT,
                                                                         IN p_datetimestring TEXT,
                                                                         IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_string_to_datetimeoffset(p_datatype,
                                                        p_datetimestring ,
                                                        p_style);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg TEXT,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    IF try THEN
        RETURN sys.babelfish_try_conv_string_to_datetime2('DATE', arg, p_style);
    ELSE
	    RETURN sys.babelfish_conv_string_to_datetime2('DATE', arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.VARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.NVARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.BPCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg sys.NCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_date(arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_date(IN arg anyelement)
RETURNS DATE
AS
$BODY$
BEGIN
    RETURN CAST(arg AS DATE);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to date is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_date(IN arg anyelement,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS DATE
AS
$BODY$
DECLARE
    resdate DATE;
BEGIN
    IF try THEN
        resdate := sys.babelfish_try_conv_to_date(arg); 
    ELSE
        BEGIN
            resdate := CAST(arg AS DATE);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to date is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type date.';
        END;
    END IF;

    RETURN resdate;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg TEXT,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
DECLARE
    v_res_datatype TEXT COLLATE C;
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'TIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('TIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    ELSE
	    RETURN sys.babelfish_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.VARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.NVARCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.BPCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg sys.NCHAR,
                                                        IN try BOOL,
                                                        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_time(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_time(IN arg anyelement)
RETURNS TIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS TIME);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to time is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_time(IN typmod INTEGER,
                                                        IN arg anyelement,
                                                        IN try BOOL,
												        IN p_style NUMERIC DEFAULT 0)
RETURNS TIME
AS
$BODY$
DECLARE
    restime TIME;
BEGIN
    IF try THEN
        restime := sys.babelfish_try_conv_to_time(arg);
    ELSE
        BEGIN
            restime := CAST(arg AS TIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to time is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type time.';
        END;
    END IF;

    RETURN restime;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
DECLARE
    v_res_datatype TEXT COLLATE C;
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime_v2(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime_v2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.BPCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg sys.NCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime(IN arg anyelement)
RETURNS sys.DATETIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIME);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME
AS
$BODY$
DECLARE
    resdatetime sys.DATETIME;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_datetime(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.DATETIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetime.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    v_res_datatype TEXT COLLATE C;
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIME2';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIME2(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.BPCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg sys.NCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetime2(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetime2(IN arg anyelement)
RETURNS sys.DATETIME2
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIME2);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime2 is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetime2(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIME2
AS
$BODY$
DECLARE
    resdatetime sys.DATETIME2;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_datetime2(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.DATETIME2);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetime2 is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetime2.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    v_res_datatype TEXT COLLATE C;
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'DATETIMEOFFSET';
    ELSE
        v_res_datatype := PG_CATALOG.format('DATETIMEOFFSET(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetimeoffset(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetimeoffset(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.BPCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg sys.NCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_datetimeoffset(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_datetimeoffset(IN arg anyelement)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.DATETIMEOFFSET);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetimeoffset is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_datetimeoffset(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                        IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.DATETIMEOFFSET
AS
$BODY$
DECLARE
    resdatetimeoffset sys.DATETIMEOFFSET;
BEGIN
    IF try THEN
        resdatetimeoffset := sys.babelfish_try_conv_to_datetimeoffset(arg);
    ELSE
        BEGIN
            resdatetimeoffset := CAST(arg AS sys.DATETIMEOFFSET);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to datetimeoffset is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type datetimeoffset.';
        END;
    END IF;

    RETURN resdatetimeoffset;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg TEXT,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
DECLARE
    v_res_datatype TEXT COLLATE C;
BEGIN
    IF (typmod = -1) THEN
        v_res_datatype := 'SMALLDATETIME';
    ELSE
        v_res_datatype := PG_CATALOG.format('SMALLDATETIME(%s)', typmod);
    END IF;

    IF try THEN
	    RETURN sys.babelfish_try_conv_string_to_datetime_v2(v_res_datatype, arg, p_style);
    ELSE
        RETURN sys.babelfish_conv_string_to_datetime_v2(v_res_datatype, arg, p_style);
    END IF;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.VARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.NVARCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.BPCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg sys.NCHAR,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN sys.babelfish_conv_helper_to_smalldatetime(typmod, arg::TEXT, try, p_style);
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_conv_to_smalldatetime(IN arg anyelement)
RETURNS sys.SMALLDATETIME
AS
$BODY$
BEGIN
    RETURN CAST(arg AS sys.SMALLDATETIME);
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to smalldatetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
        WHEN OTHERS THEN
            RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_conv_helper_to_smalldatetime(IN typmod INTEGER,
                                                            IN arg anyelement,
                                                            IN try BOOL,
													        IN p_style NUMERIC DEFAULT 0)
RETURNS sys.SMALLDATETIME
AS
$BODY$
DECLARE
    resdatetime sys.SMALLDATETIME;
BEGIN
    IF try THEN
        resdatetime := sys.babelfish_try_conv_to_smalldatetime(arg);
    ELSE
        BEGIN
            resdatetime := CAST(arg AS sys.SMALLDATETIME);
        EXCEPTION
            WHEN cannot_coerce THEN
                RAISE USING MESSAGE := pg_catalog.format('Explicit conversion from data type %s to smalldatetime is not allowed.', format_type(pg_typeof(arg)::oid, NULL));
            WHEN datetime_field_overflow THEN
                RAISE USING MESSAGE := 'Arithmetic overflow error converting expression to data type smalldatetime.';
        END;
    END IF;

    RETURN resdatetime;
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

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
        v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(to_char(v_datetimeval, 'US'), v_scale);

        -- Following condition will handle overflow of fractsecs
        IF (v_fseconds::INTEGER < 0) THEN
            v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
            v_datetimeval := v_datetimeval + INTERVAL '1 second';
        END IF;

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
STABLE
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
    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(to_char(p_timeval, 'US'), v_scale);

    -- Following condition will handle overflow of fractsecs
    IF (v_fseconds::INTEGER < 0) THEN
        v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
        p_timeval := p_timeval + INTERVAL '1 second';
    END IF;

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
STABLE
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
            v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(rpad(v_fseconds, 9, '0'), v_scale);

            -- Following condition will handle overflow of fractsecs
            IF (v_fseconds::INTEGER < 0) THEN
                v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
                v_seconds := (v_seconds::INTEGER + 1)::TEXT;
            END IF;

            v_seconds := concat_ws('.', v_seconds, v_fseconds);

            v_res_datetime := make_timestamp(v_year, v_month::SMALLINT, v_day::SMALLINT,
                                             v_hours, v_minutes, v_seconds::NUMERIC);

            IF (v_res_datetime > make_timestamp(9999, 12, 31, 23, 59, 59.999999)) THEN
                -- if rounding of fractional seconds caused the date and time to go out of range 
                -- then max date and time that can be stored for p_datatype will be used
                v_res_datetime := make_timestamp(9999, 12, 31, 23, 59, concat_ws('.', '59', PG_CATALOG.repeat('9', LEAST(v_scale, 6)))::NUMERIC); 
            END IF;
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
STABLE
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

    v_fseconds := sys.babelfish_get_microsecs_from_fractsecs_v2(rpad(v_fseconds, 9, '0'), v_scale);
    -- Following condition will handle overflow of fractsecs
    IF (v_fseconds::INTEGER < 0) THEN
        v_fseconds := PG_CATALOG.repeat('0', LEAST(v_scale, 6));
        v_seconds := (v_seconds::INTEGER + 1)::TEXT;
    END IF;

    v_seconds := concat_ws('.', v_seconds, v_fseconds);

    v_res_time := make_time(v_hours, v_minutes, v_seconds::NUMERIC);

    IF (v_res_time > make_time(23, 59, 59.999999)) THEN
        -- if rounding of fractional seconds caused the time to go out of range 
        -- then max time that can be stored for time will be used
        v_res_time := make_time(23, 59, concat_ws('.', '59', PG_CATALOG.repeat('9', LEAST(v_scale, 6)))::NUMERIC); 
    END IF;

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
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.date_bucket(IN datepart PG_CATALOG.TEXT, IN number INTEGER, IN date ANYELEMENT, IN origin ANYELEMENT default NULL) RETURNS ANYELEMENT 
AS 
$body$
DECLARE
    required_bucket INT;
    years_diff INT;
    quarters_diff INT;
    months_diff INT;
    hours_diff INT;
    minutes_diff INT;
    seconds_diff INT;
    milliseconds_diff INT;
    timezone INT;
    result_time time;
    result_date timestamp;
    offset_string PG_CATALOG.text;
    date_difference_interval INTERVAL;
    millisec_trunc_diff_interval INTERVAL;
    date_arg_datatype regtype;
    is_valid boolean;
BEGIN
    BEGIN
        date_arg_datatype := pg_typeof(date);
        is_valid := sys.date_bucket_internal_helper(datepart, number, true, true, date);

        -- If optional argument origin's value is not provided by user then set it's default value of valid datatype.
        IF origin IS NULL THEN
                IF date_arg_datatype = 'sys.datetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime);
                ELSIF date_arg_datatype = 'sys.datetime2'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetime2);
                ELSIF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.datetimeoffset);
                ELSIF date_arg_datatype = 'sys.smalldatetime'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS sys.smalldatetime);
                ELSIF date_arg_datatype = 'date'::regtype THEN
                    origin := CAST('1900-01-01 00:00:00.000' AS pg_catalog.date);
                ELSIF date_arg_datatype = 'time'::regtype THEN
                    origin := CAST('00:00:00.000' AS pg_catalog.time);
                END IF;
        END IF;
    END;

    /* support of date_bucket() for different kinds of date datatype starts here */
    -- support of date_bucket() when date is of 'time' datatype
    IF date_arg_datatype = 'time'::regtype THEN
        -- Find interval between date and origin and extract hour, minute, second, millisecond from the interval
        date_difference_interval := date_trunc('millisecond', date) - date_trunc('millisecond', origin);
        hours_diff := EXTRACT('hour' from date_difference_interval)::INT;
        minutes_diff := EXTRACT('minute' from date_difference_interval)::INT;
        seconds_diff := FLOOR(EXTRACT('second' from date_difference_interval))::INT;
        milliseconds_diff := FLOOR(EXTRACT('millisecond' from date_difference_interval))::INT;
        CASE datepart
            WHEN 'hour' THEN
                -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                -- For Ex. 'date_bucket(hour, 2, '01:00:00', '08:00:00')' hence check if the result_time is greater then date
                -- For comparision we are trunceting the result_time to milliseconds
                required_bucket := hours_diff/number;
                result_time := origin + make_interval(hours => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(hours => number);
                END IF;
                RETURN result_time;

            WHEN 'minute' THEN
                required_bucket := (hours_diff * 60 + minutes_diff)/number;
                result_time := origin + make_interval(mins => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(mins => number);
                END IF;
                RETURN result_time;

            WHEN 'second' THEN
                required_bucket := ((hours_diff * 60 + minutes_diff) * 60 + seconds_diff)/number;
                result_time := origin + make_interval(secs => required_bucket * number);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => number);
                END IF;
                RETURN result_time;

            WHEN 'millisecond' THEN
                required_bucket := (((hours_diff * 60 + minutes_diff) * 60) * 1000 + milliseconds_diff)/number;
                result_time := origin + make_interval(secs => ((required_bucket * number)::numeric) * 0.001);
                IF date_trunc('millisecond', result_time) > date THEN
                    RETURN result_time - make_interval(secs => (number::numeric) * 0.001);
                END IF;
                RETURN result_time;
        END CASE;

    -- support of date_bucket() when date is of {'datetime2', 'datetimeoffset'} datatype
    -- handling separately because both the datatypes have precision in milliseconds
    ELSIF date_arg_datatype IN ('sys.datetime2'::regtype, 'sys.datetimeoffset'::regtype) THEN
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Ex. date_bucket(year, 2, '2010-01-01', '2019-01-01')) hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number*3);
                    END IF;
            END CASE;  
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function. 
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            millisec_trunc_diff_interval := (origin::timestamp - date_trunc('millisecond', origin::timestamp))::interval;
            result_date = date_bin(date_difference_interval, date::timestamp, date_trunc('millisecond', origin::timestamp)) + millisec_trunc_diff_interval;

            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result.
            IF result_date + date_difference_interval <= date::timestamp THEN
                result_date = result_date + date_difference_interval;
            END IF;
        END IF;

        -- All the above operations are performed by converting every date datatype into TIMESTAMPS. 
        -- datetimeoffset is typecasted into TIMESTAMPS that changes the value. 
        -- Ex. '2023-02-23 09:19:21.23 +10:12'::sys.datetimeoffset::timestamp => '2023-02-22 23:07:21.23'
        -- The output of date_bucket() for datetimeoffset datatype will always be in the same time-zone as of provided date argument. 
        -- Here, converting TIMESTAMP into datetimeoffset datatype with the same timezone as of date argument.
        IF date_arg_datatype = 'sys.datetimeoffset'::regtype THEN
            timezone = sys.babelfish_get_datetimeoffset_tzoffset(date)::INTEGER;
            offset_string = right(date::PG_CATALOG.TEXT, 6);
            result_date = result_date + make_interval(mins => timezone);
            RETURN concat(result_date, ' ', offset_string)::sys.datetimeoffset;
        ELSE
            RETURN result_date;
        END IF;

    -- support of date_bucket() when date is of {'date', 'datetime', 'smalldatetime'} datatype
    ELSE
        -- Round datetime to fixed bins (e.g. .000, .003, .007)
        IF date_arg_datatype = 'sys.datetime'::regtype THEN
            date := sys.babelfish_conv_string_to_datetime_v2('DATETIME', date::TEXT)::sys.datetime;
            origin := sys.babelfish_conv_string_to_datetime_v2('DATETIME', origin::TEXT)::sys.datetime;
        END IF;
        -- when datepart is {year, quarter, month} make use of AGE() function to find number of buckets
        IF datepart IN ('year', 'quarter', 'month') THEN
            date_difference_interval := AGE(date_trunc('day', date::timestamp), date_trunc('day', origin::timestamp));
            years_diff := EXTRACT('Year' from date_difference_interval)::INT;
            months_diff := EXTRACT('Month' from date_difference_interval)::INT;
            CASE datepart
                WHEN 'year' THEN
                    -- Here we are finding how many buckets we have to add in the origin so that we can reach to a bucket in which date belongs.
                    -- For cases where origin > date, we might end up in a bucket which exceeds date by 1 bucket. 
                    -- For Example. date_bucket(year, 2, '2010-01-01', '2019-01-01') hence check if the result_time is greater then date.
                    -- For comparision we are trunceting the result_time to milliseconds
                    required_bucket := years_diff/number;
                    result_date := origin::timestamp + make_interval(years => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(years => number);
                    END IF;

                WHEN 'month' THEN
                    required_bucket := (12 * years_diff + months_diff)/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number);
                    END IF;

                WHEN 'quarter' THEN
                    quarters_diff := (12 * years_diff + months_diff)/3;
                    required_bucket := quarters_diff/number;
                    result_date := origin::timestamp + make_interval(months => required_bucket * number * 3);
                    IF result_date > date::timestamp THEN
                        result_date = result_date - make_interval(months => number * 3);
                    END IF;
            END CASE;
            RETURN result_date;
        
        -- when datepart is {week, day, hour, minute, second, millisecond} make use of built-in date_bin() postgresql function.
        ELSE
            -- trunceting origin to millisecond before passing it to date_bin() function. 
            -- store the difference between origin and trunceted origin to add it in the result of date_bin() function
            date_difference_interval := concat(number, ' ', datepart)::INTERVAL;
            result_date = date_bin(date_difference_interval, date::TIMESTAMP, origin::TIMESTAMP);
            -- Filetering cases where the required bucket ends at date then date_bin() gives start point of this bucket as result. 
            IF result_date + date_difference_interval <= date::TIMESTAMP THEN
                result_date = result_date + date_difference_interval;
            END IF;
            RETURN result_date;
        END IF;
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;

ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_dateval DATE) IMMUTABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day NUMERIC, IN p_month NUMERIC, IN p_year NUMERIC) IMMUTABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_day TEXT, IN p_month TEXT, IN p_year TEXT) IMMUTABLE;
ALTER FUNCTION sys.babelfish_conv_hijri_to_greg(IN p_datetimeval TIMESTAMP WITHOUT TIME ZONE) IMMUTABLE;
ALTER FUNCTION sys.babelfish_get_full_year(IN p_short_year TEXT, IN p_base_century TEXT, IN p_year_cutoff NUMERIC) IMMUTABLE;
ALTER FUNCTION sys.babelfish_get_int_part(IN p_srcnumber DOUBLE PRECISION) IMMUTABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_date');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_date');

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_time_with_arg_text_deprecated_in_4_2_0');
CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_time_with_arg_anyelement_deprecated_in_4_2_0');
DO $$
BEGIN
    IF (NOT EXISTS(SELECT * FROM pg_proc
                            WHERE proname = 'babelfish_conv_helper_to_time_with_arg_text_deprecated_in_3_6_0' AND
                            pronamespace = 'sys'::regnamespace::oid) AND
        NOT EXISTS(SELECT * FROM pg_proc
                            WHERE proname = 'babelfish_conv_helper_to_time_with_arg_text_deprecated_in_4_2_0' AND
                            pronamespace = 'sys'::regnamespace::oid))
    THEN
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_time');
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_time');
    END IF;
END;
$$;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_helper_to_datetime_deprecated_in_4_2_0');
DO $$
BEGIN
    IF (NOT EXISTS (SELECT * FROM pg_proc
                            WHERE proname = 'babelfish_conv_helper_to_datetime_deprecated_in_2_3_0_1' AND
                            pronamespace = 'sys'::regnamespace::oid) AND
        NOT EXISTS (SELECT * FROM pg_proc
                            WHERE proname like 'babelfish_conv_helper_to_datetime_deprecated_in_3_6_0' AND
                            pronamespace = 'sys'::regnamespace::oid) AND
        NOT EXISTS (SELECT * FROM pg_proc
                            WHERE proname like 'babelfish_conv_helper_to_datetime_deprecated_in_4_2_0' AND
                            pronamespace = 'sys'::regnamespace::oid))
    THEN
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_try_conv_string_to_datetime');
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_conv_string_to_datetime');
    END IF;
END;
$$;

DO $$
BEGIN
    IF (NOT EXISTS(SELECT * FROM pg_proc
                            WHERE proname = 'babelfish_conv_string_to_datetime' AND
                            pronamespace = 'sys'::regnamespace::oid) AND
        NOT EXISTS(SELECT * FROM pg_proc
                            WHERE proname = 'babelfish_conv_string_to_time' AND
                            pronamespace = 'sys'::regnamespace::oid))
    THEN
        CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'babelfish_get_microsecs_from_fractsecs');
    END IF;
END;
$$;

ALTER VIEW sys.all_sql_modules_internal RENAME TO all_sql_modules_internal_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.all_sql_modules_internal AS
SELECT
  ao.object_id AS object_id
  , CAST(
      CASE WHEN ao.type in ('P', 'FN', 'IN', 'TF', 'RF', 'IF', 'TR') THEN COALESCE(f.definition, '')
      WHEN ao.type = 'V' THEN COALESCE(bvd.definition, '')
      ELSE NULL
      END
    AS sys.nvarchar) AS definition
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

ALTER VIEW sys.all_sql_modules RENAME TO all_sql_modules_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.all_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
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

ALTER VIEW sys.system_sql_modules RENAME TO system_sql_modules_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.system_sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
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

ALTER VIEW sys.sql_modules RENAME TO sql_modules_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.sql_modules AS
SELECT
     CAST(t1.object_id as int)
    ,CAST(t1.definition as sys.nvarchar)
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

ALTER VIEW sys.default_constraints RENAME TO default_constraints_deprecated_4_2_0;

create or replace view sys.default_constraints
AS
select CAST(('DF_' || tab.name || '_' || d.oid) as sys.sysname) as name
  , CAST(d.oid as int) as object_id
  , CAST(null as int) as principal_id
  , CAST(tab.schema_id as int) as schema_id
  , CAST(d.adrelid as int) as parent_object_id
  , CAST('D' as sys.bpchar(2)) as type
  , CAST('DEFAULT_CONSTRAINT' as sys.nvarchar(60)) AS type_desc
  , CAST(null as sys.datetime) as create_date
  , CAST(null as sys.datetime) as modified_date
  , CAST(0 as sys.bit) as is_ms_shipped
  , CAST(0 as sys.bit) as is_published
  , CAST(0 as sys.bit) as is_schema_published
  , CAST(d.adnum as int) as parent_column_id
  , CAST(tsql_get_expr(d.adbin, d.adrelid) as sys.nvarchar) as definition
  , CAST(1 as sys.bit) as is_system_named
from pg_catalog.pg_attrdef as d
inner join pg_attribute a on a.attrelid = d.adrelid and d.adnum = a.attnum
inner join sys.tables tab on d.adrelid = tab.object_id
WHERE a.atthasdef = 't' and a.attgenerated = ''
AND has_schema_privilege(tab.schema_id, 'USAGE')
AND has_column_privilege(a.attrelid, a.attname, 'SELECT,INSERT,UPDATE,REFERENCES');
GRANT SELECT ON sys.default_constraints TO PUBLIC;

ALTER VIEW sys.check_constraints RENAME TO check_constraints_deprecated_4_2_0;

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
  , CAST(tsql_get_constraintdef(c.oid) as sys.nvarchar) AS definition
  , CAST(1 as sys.bit) as uses_database_collation
  , CAST(0 as sys.bit) as is_system_named
FROM pg_catalog.pg_constraint as c
INNER JOIN sys.schemas s on c.connamespace = s.schema_id
WHERE has_schema_privilege(s.schema_id, 'USAGE')
AND c.contype = 'c' and c.conrelid != 0;
GRANT SELECT ON sys.check_constraints TO PUBLIC;

ALTER VIEW sys.computed_columns RENAME TO computed_columns_deprecated_4_2_0;

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
  , cast(tsql_get_expr(d.adbin, d.adrelid) AS sys.nvarchar) AS definition
  , 1::sys.bit AS uses_database_collation
  , 1::sys.bit AS is_persisted
FROM sys.columns_internal() sc
INNER JOIN pg_attribute a ON sc.out_object_id = a.attrelid AND sc.out_column_id = a.attnum
INNER JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
WHERE a.attgenerated = 's' AND sc.out_is_computed::integer = 1;
GRANT SELECT ON sys.computed_columns TO PUBLIC;

ALTER VIEW sys.xml_indexes RENAME TO xml_indexes_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.xml_indexes
AS
SELECT
    CAST(idx.object_id AS INT) AS object_id
  , CAST(idx.name AS sys.sysname) AS name
  , CAST(idx.index_id AS INT)  AS index_id
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
  , CAST(idx.filter_definition AS sys.nvarchar) AS filter_definition
  , CAST(idx.auto_created AS sys.bit) AS auto_created
  , CAST(NULL AS INT) AS using_xml_index_id
  , CAST(NULL AS sys.bpchar(1)) AS secondary_type
  , CAST(NULL AS sys.nvarchar(60)) AS secondary_type_desc
  , CAST(0 AS sys.tinyint) AS xml_index_type
  , CAST(NULL AS sys.nvarchar(60)) AS xml_index_type_description
  , CAST(NULL AS INT) AS path_id
FROM  sys.indexes idx
WHERE idx.type = 3; -- 3 is of type XML
GRANT SELECT ON sys.xml_indexes TO PUBLIC;

ALTER VIEW sys.stats RENAME TO stats_deprecated_4_2_0;

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
   CAST('' as sys.NVARCHAR) AS filter_definition,
   CAST(0 as sys.BIT) AS is_temporary,
   CAST(0 as sys.BIT) AS is_incremental,
   CAST(0 as sys.BIT) AS has_persisted_sample,
   CAST(0 as INT) AS stats_generation_method,
   CAST('' as sys.VARCHAR(255)) AS stats_generation_method_desc
WHERE FALSE;
GRANT SELECT ON sys.stats TO PUBLIC;

ALTER VIEW sys.plan_guides RENAME TO plan_guides_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.plan_guides
AS
SELECT 
    CAST(0 as int) AS plan_guide_id
  , CAST('' as sys.sysname) AS name
  , CAST(NULL as sys.datetime) as create_date
  , CAST(NULL as sys.datetime) as modify_date
  , CAST(0 as sys.bit) as is_disabled
  , CAST('' as sys.nvarchar) AS query_text
  , CAST(0 as sys.tinyint) AS scope_type
  , CAST('' as sys.nvarchar(60)) AS scope_type_desc
  , CAST(0 as int) AS scope_type_id
  , CAST('' as sys.nvarchar) AS scope_batch
  , CAST('' as sys.nvarchar) AS parameters
  , CAST('' as sys.nvarchar) AS hints
WHERE FALSE;
GRANT SELECT ON sys.plan_guides TO PUBLIC;

ALTER VIEW sys.numbered_procedures RENAME TO numbered_procedures_deprecated_4_2_0;

CREATE OR REPLACE VIEW sys.numbered_procedures
AS
SELECT 
    CAST(0 as int) AS object_id
  , CAST(0 as smallint) AS procedure_number
  , CAST('' as sys.nvarchar) AS definition
WHERE FALSE; -- This condition will ensure that the view is empty
GRANT SELECT ON sys.numbered_procedures TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'default_constraints_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'check_constraints_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'computed_columns_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'xml_indexes_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'stats_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'plan_guides_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'numbered_procedures_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'all_sql_modules_internal_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'all_sql_modules_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'system_sql_modules_deprecated_4_2_0');
CALL sys.babelfish_drop_deprecated_object('view', 'sys', 'sql_modules_deprecated_4_2_0');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
