-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.3.0'" to load this file. \quit

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

CREATE OR REPLACE PROCEDURE sys.sp_execute_postgresql(IN "@postgresStmt" sys.nvarchar)
AS 'babelfishpg_tsql', 'sp_execute_postgresql' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_execute_postgresql(IN sys.nvarchar) TO PUBLIC;

ALTER FUNCTION sys.parsename(VARCHAR,INT) RENAME TO parsename_deprecated_in_3_3_0;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.VARCHAR, object_piece int)
RETURNS sys.SYSNAME
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.identity_into_int(IN typename INT, IN seed INT, IN increment INT)
RETURNS int AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.identity_into_int(INT, INT, INT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.identity_into_smallint(IN typename INT, IN seed SMALLINT, IN increment SMALLINT)
RETURNS smallint AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.identity_into_smallint(INT, SMALLINT, SMALLINT) TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.identity_into_bigint(IN typename INT, IN seed BIGINT, IN increment BIGINT)
RETURNS bigint AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.identity_into_bigint(INT, BIGINT, BIGINT) TO PUBLIC;

CREATE OR REPLACE VIEW sys.sql_expression_dependencies
AS
SELECT
    CAST(0 as INT) AS referencing_id,
    CAST(0 as INT) AS referencing_minor_id,
    CAST(0 as sys.TINYINT) AS referencing_class,
    CAST('' as NVARCHAR(60)) AS referencing_class_desc,
    CAST(0 as sys.BIT) AS is_schema_bound_reference,
    CAST(0 as sys.TINYINT) AS referenced_class,
    CAST('' as NVARCHAR(60)) AS referenced_class_desc,
    CAST('' as SYSNAME) AS referenced_server_name,
    CAST('' as SYSNAME) AS referenced_database_name,
    CAST('' as SYSNAME) AS referenced_schema_name,
    CAST('' as SYSNAME) AS referenced_entity_name,
    CAST(0 as INT) AS referenced_id,
    CAST(0 as INT) AS referenced_minor_id,
    CAST(0 as sys.BIT) AS is_caller_dependent,
    CAST(0 as sys.BIT) AS is_ambiguous
WHERE FALSE;
GRANT SELECT ON sys.sql_expression_dependencies TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_3_0');

CREATE OR REPLACE FUNCTION sys.EOMONTH(date,int DEFAULT 0)
RETURNS date
AS 'babelfishpg_tsql', 'EOMONTH'
LANGUAGE C STABLE PARALLEL SAFE;

ALTER TABLE sys.babelfish_server_options ADD COLUMN IF NOT EXISTS connect_timeout INT;

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
  CAST(s.connect_timeout as int) AS connect_timeout,
  CAST(s.query_timeout as int) AS query_timeout,
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
LEFT JOIN sys.babelfish_server_options AS s on f.srvname = s.servername
WHERE w.fdwname = 'tds_fdw';
GRANT SELECT ON sys.servers TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_testlinkedserver(IN "@servername" sys.sysname)
AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_testlinkedserver(IN sys.sysname) TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_testlinkedserver( IN "@servername" sys.sysname)
AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_testlinkedserver OWNER TO sysadmin;

CREATE OR REPLACE PROCEDURE sys.sp_enum_oledb_providers()
AS 'babelfishpg_tsql', 'sp_enum_oledb_providers_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_enum_oledb_providers() TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_enum_oledb_providers()
AS 'babelfishpg_tsql', 'sp_enum_oledb_providers_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_enum_oledb_providers OWNER TO sysadmin;

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
    ('sp_testlinkedserver', 'master_dbo', 'P'),
    ('sp_enum_oledb_providers','master_dbo','P'),
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

-- It is assumed that there is no data stored in the sys.extended_properties table.
ALTER TABLE sys.extended_properties RENAME TO extended_properties_deprecated_in_3_3_0;
CREATE TABLE sys.babelfish_extended_properties (
  dbid smallint NOT NULL,
  schema_name name NOT NULL,
  major_name name NOT NULL,
  minor_name name NOT NULL,
  type sys.varchar(50) NOT NULL,
  name sys.sysname NOT NULL,
  orig_name sys.sysname NOT NULL,
  value sys.sql_variant,
  PRIMARY KEY (dbid, type, schema_name, major_name, minor_name, name)
);
GRANT SELECT on sys.babelfish_extended_properties TO PUBLIC;
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_extended_properties', '');

CREATE OR REPLACE VIEW sys.extended_properties
AS
SELECT
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 3
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 1
		WHEN ep.type = 'TYPE' THEN 6
		END) AS sys.tinyint) AS class,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 'DATABASE'
		WHEN ep.type = 'SCHEMA' THEN 'SCHEMA'
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION') THEN 'OBJECT_OR_COLUMN'
		WHEN ep.type = 'TYPE' THEN 'TYPE'
	END) AS sys.nvarchar(60)) AS class_desc,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN n.oid
		WHEN ep.type IN ('TABLE', 'TABLE COLUMN', 'VIEW', 'SEQUENCE') THEN c.oid
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN p.oid
		WHEN ep.type = 'TYPE' THEN t.oid
	END) AS int) AS major_id,
	CAST((CASE
		WHEN ep.type = 'DATABASE' THEN 0
		WHEN ep.type = 'SCHEMA' THEN 0
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE', 'PROCEDURE', 'FUNCTION', 'TYPE') THEN 0
		WHEN ep.type = 'TABLE COLUMN' THEN a.attnum
	END) AS int) AS minor_id,
	ep.orig_name AS name, ep.value AS value
	FROM sys.babelfish_extended_properties ep
		LEFT JOIN pg_catalog.pg_namespace n ON n.nspname = ep.schema_name
		LEFT JOIN pg_catalog.pg_class c ON c.relname = ep.major_name AND c.relnamespace = n.oid
		LEFT JOIN pg_catalog.pg_proc p ON p.proname = ep.major_name AND p.pronamespace = n.oid
		LEFT JOIN pg_catalog.pg_type t ON t.typname = ep.major_name AND t.typnamespace = n.oid
		LEFT JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid AND a.attname = ep.minor_name
	WHERE ep.dbid = sys.db_id() AND
	(CASE
		WHEN ep.type = 'DATABASE' THEN true
		WHEN ep.type = 'SCHEMA' THEN has_schema_privilege(n.oid, 'USAGE, CREATE')
		WHEN ep.type IN ('TABLE', 'VIEW', 'SEQUENCE') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'))
		WHEN ep.type IN ('TABLE COLUMN') THEN (has_table_privilege(c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') OR has_column_privilege(a.attrelid, a.attname, 'SELECT, INSERT, UPDATE, REFERENCES'))
		WHEN ep.type IN ('PROCEDURE', 'FUNCTION') THEN has_function_privilege(p.oid, 'EXECUTE')
		WHEN ep.type = 'TYPE' THEN has_type_privilege(t.oid, 'USAGE')
	END)
	ORDER BY class, class_desc, major_id, minor_id, ep.orig_name;
GRANT SELECT ON sys.extended_properties TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('table', 'sys', 'extended_properties_deprecated_in_3_3_0');

ALTER FUNCTION sys.fn_listextendedproperty RENAME TO fn_listextendedproperty_deprecated_in_3_3_0;
CREATE OR REPLACE FUNCTION sys.fn_listextendedproperty
(
    IN "@name" sys.sysname DEFAULT NULL,
    IN "@level0type" VARCHAR(128) DEFAULT NULL,
    IN "@level0name" sys.sysname DEFAULT NULL,
    IN "@level1type" VARCHAR(128) DEFAULT NULL,
    IN "@level1name" sys.sysname DEFAULT NULL,
    IN "@level2type" VARCHAR(128) DEFAULT NULL,
    IN "@level2name" sys.sysname DEFAULT NULL,
    OUT objtype sys.sysname,
    OUT objname sys.sysname,
    OUT name sys.sysname,
    OUT value sys.sql_variant
)
RETURNS SETOF RECORD
AS 'babelfishpg_tsql' LANGUAGE C STABLE;
GRANT EXECUTE ON FUNCTION sys.fn_listextendedproperty TO PUBLIC;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'fn_listextendedproperty_deprecated_in_3_3_0');

CREATE OR REPLACE PROCEDURE sys.sp_addextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_addextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_updateextendedproperty
(
  "@name" sys.sysname,
  "@value" sys.sql_variant = NULL,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_updateextendedproperty TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.sp_dropextendedproperty
(
  "@name" sys.sysname,
  "@level0type" VARCHAR(128) = NULL,
  "@level0name" sys.sysname = NULL,
  "@level1type" VARCHAR(128) = NULL,
  "@level1name" sys.sysname = NULL,
  "@level2type" VARCHAR(128) = NULL,
  "@level2name" sys.sysname = NULL
)
AS 'babelfishpg_tsql' LANGUAGE C;
GRANT EXECUTE ON PROCEDURE sys.sp_dropextendedproperty TO PUBLIC;

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
  , t.client_pid::varchar(10) as hostprocess
  , a.query as cmd
  , null::varchar(128) as nt_domain
  , null::varchar(128) as nt_username
  , null::varchar(12) as net_address
  , null::varchar(12) as net_library
  , a.usename as loginname
  , t.context_info::bytea as context_info
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

CREATE OR REPLACE FUNCTION sys.host_id()
RETURNS sys.VARCHAR(10)  AS 'babelfishpg_tsql' LANGUAGE C IMMUTABLE PARALLEL SAFE;
GRANT EXECUTE ON FUNCTION sys.host_id() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sysdatetime() RETURNS datetime2
    AS $$select statement_timestamp()::datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetime() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sysdatetimeoffset() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(statement_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp()::pg_catalog.timestamp)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.bbf_sleep_for(IN sleep_time DATETIME)
AS $$
DECLARE
  v TIME;
BEGIN
  v = CAST(sleep_time as TIME);
  PERFORM pg_sleep(extract(epoch from clock_timestamp() + v) -
                extract(epoch from clock_timestamp()));
END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.bbf_sleep_for(IN sleep_time DATETIME) TO PUBLIC;

CREATE OR REPLACE PROCEDURE sys.bbf_sleep_until(IN sleep_time DATETIME)
AS $$
DECLARE
  t TIME;
  target_timestamp TIMESTAMPTZ;
BEGIN
  t = CAST(sleep_time as TIME);
  target_timestamp = current_date + t;
  IF target_timestamp < current_timestamp THEN
    target_timestamp = target_timestamp + '1 day';
  END IF;
  PERFORM pg_sleep(extract(epoch from target_timestamp) -
                extract(epoch from clock_timestamp()));
END
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON PROCEDURE sys.bbf_sleep_until(IN sleep_time DATETIME) TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);

-- tsql full-text search configurations for Babelfish
-- Since currently we only support one language - American English, 
-- this configuration is for American English only
CREATE TEXT SEARCH DICTIONARY fts_contains_dict (
    TEMPLATE = simple,
    STOPWORDS = tsql_contains
);

COMMENT ON TEXT SEARCH DICTIONARY fts_contains_dict IS 'Babelfish T-SQL full text search CONTAINS dictionary (currently we only support American English)';

CREATE TEXT SEARCH CONFIGURATION fts_contains ( COPY = simple );

COMMENT ON TEXT SEARCH CONFIGURATION fts_contains IS 'Babelfish T-SQL full text search CONTAINS configuration (currently we only support American English)';

ALTER TEXT SEARCH CONFIGURATION fts_contains
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH fts_contains_dict;

-- This function performs string rewriting for the full text search CONTAINS predicate
-- in Babelfish
-- For example, a T-SQL query 
-- SELECT * FROM t WHERE CONTAINS(txt, '"good old days"')
-- is rewritten into a Postgres query 
-- SELECT * FROM t WHERE to_tsvector('fts_contains', txt) @@ to_tsquery('fts_contains', 'good <-> old <-> days')
-- In particular, the string constant '"good old days"' gets rewritten into 'good <-> old <-> days'
-- This function performs the string rewriting from '"good old days"' to 'good <-> old <-> days'
-- For prefix terms, '"word1*"' is rewritten into 'word1:*', and '"word1 word2 word3*"' is rewritten into 'word1<->word2<->word3:*'
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_rewrite(IN phrase text)
  RETURNS TEXT AS
$$
DECLARE
  orig_phrase text;
  joined_text text;
  word text;
BEGIN
  orig_phrase = phrase;

  -- generation term not supported
  IF (phrase COLLATE C) SIMILAR TO ('[ ]*FORMSOF[ ]*\(%\)%' COLLATE C) THEN
    RAISE EXCEPTION 'Generation term not supported';
  END IF;

  -- boolean operators not supported
  IF position(('&' COLLATE C) IN (phrase COLLATE "C")) <> 0 OR position(('|' COLLATE C) IN (phrase COLLATE "C")) <> 0 OR position(('&!' COLLATE C) IN (phrase COLLATE "C")) <> 0 THEN
    RAISE EXCEPTION 'Boolean operators not supported';
  END IF;

  IF position((' AND ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 OR position((' OR ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 OR position((' AND NOT ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 THEN
    RAISE EXCEPTION 'Boolean operators not supported';
  END IF;

  -- Initialize the joined_text variable
  joined_text := '';

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- no rewriting is needed if the query is a single word
  IF position((' ' COLLATE C) IN (phrase COLLATE "C")) = 0 AND position(('"' COLLATE C) IN UPPER(phrase COLLATE "C")) = 0 THEN
    RETURN phrase;
  END IF;

  -- rewrite phrase queries 
  -- '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'

  -- Check if the phrase is surrounded by double quotes
  IF position(('"' COLLATE "C") IN (phrase COLLATE "C") ) <> 1 OR position(('"' COLLATE "C") IN (reverse(phrase) COLLATE "C")) <> 1 THEN
    RAISE EXCEPTION 'Phrase must be surrounded by double quotes';
  END IF;

  -- Strip the double quotes from the phrase
  phrase := substring(phrase COLLATE "C", 2, length(phrase) - 2) COLLATE "C";

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- Split the phrase into an array of words
  FOREACH word IN ARRAY regexp_split_to_array(phrase COLLATE "C", '\s+' COLLATE "C") COLLATE "C" LOOP
    -- Append the word to the joined_text variable
    joined_text := joined_text || word || '<->';
  END LOOP;

  -- Remove the trailing "<->" from the joined_text
  joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 3) COLLATE "C";

  -- Prefix term (Examples: '"word1*"', '"word1 word2*"') if 
  -- (1) search term is surrounded by double quotes (Counter example: 'word1*', as it doesn't have double quotes)
  -- (2) last word in the search term ends with a star (Counter example: '"word1* word2"', as last word doesn't end with star)
  -- (3) last word is NOT a single star (Counter example: '"*"', '"word1 word2 *"', as last word is a single star)
  -- We need to rewrite the last word into 'lastword:*'
  IF (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"%\*"[ ]*' COLLATE C) AND (NOT (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"% \*"[ ]*' COLLATE C)) AND (NOT (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"\*"[ ]*' COLLATE C)) THEN
    joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 1) || ':*';
  END IF;

  -- Return the joined_text
  RETURN joined_text;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 
-- Removing IMMUTABLE PARALLEL SAFE will disallow parallel mode for full text search

-- Given the query string, determine the Postgres full text configuration to use
-- Currently we only support simple terms and prefix terms
-- For simple terms, we use the 'fts_contains' configuration
-- For prefix terms, we use the 'simple' configuration
-- They are the configurations that provide closest matching according to our experiments
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_pgconfig(IN phrase text)
  RETURNS regconfig AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  -- Prefix term (Examples: '"word1*"', '"word1 word2*"') if 
  -- (1) search term is surrounded by double quotes (Counter example: 'word1*', as it doesn't have double quotes)
  -- (2) last word in the search term ends with a star (Counter example: '"word1* word2"', as last word doesn't end with star)
  -- (3) last word is NOT a single star (Counter example: '"*"', '"word1 word2 *"', as last word is a single star)
  IF (phrase COLLATE C) SIMILAR TO ('[ ]*"%\*"[ ]*' COLLATE C) AND (NOT (phrase COLLATE C) SIMILAR TO ('[ ]*"% \*"[ ]*' COLLATE C)) AND (NOT (phrase COLLATE C) SIMILAR TO ('[ ]*"\*"[ ]*' COLLATE C)) THEN
    RETURN 'simple'::regconfig;
  END IF;
  -- Simple term
  RETURN 'fts_contains'::regconfig;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.SMALLDATETIMEFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER
                                                               )
RETURNS sys.smalldatetime
AS
$BODY$
DECLARE
    v_ressmalldatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    p_seconds INTEGER;
BEGIN
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if arguments are out of range
    IF ((p_year NOT BETWEEN 1900 AND 2079) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59)) OR (p_year = 2079 AND (p_month > 6 or p_day > 6))
    THEN
        RAISE invalid_datetime_format;
    END IF;
    p_seconds := 0;
    v_ressmalldatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    p_seconds);

    v_string := v_ressmalldatetime::pg_catalog.text;
    RETURN CAST(v_string AS sys.SMALLDATETIME);
EXCEPTION   
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type smalldatetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

ALTER FUNCTION sys.power (IN arg1 INT, IN arg2 NUMERIC) STRICT;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
