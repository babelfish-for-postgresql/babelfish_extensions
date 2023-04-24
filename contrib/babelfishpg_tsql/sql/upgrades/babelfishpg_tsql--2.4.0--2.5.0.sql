-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.5.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

ALTER FUNCTION sys.nestlevel() RENAME TO nestlevel_deprecated_in_2_5_0;

CREATE OR REPLACE FUNCTION sys.nestlevel() RETURNS INTEGER AS
$$
DECLARE
    stack text;
    result integer;
BEGIN
    GET DIAGNOSTICS stack = PG_CONTEXT;
    result := array_length(string_to_array(stack, 'function'), 1) - 3; 
    IF result < -1 THEN
        RAISE EXCEPTION 'Invalid output, check stack trace %', stack;
    ELSE
        RETURN result;
    END IF;
END;
$$
LANGUAGE plpgsql STABLE;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'nestlevel_deprecated_in_2_5_0');

CREATE OR REPLACE VIEW sys.sp_databases_view AS
	SELECT CAST(database_name AS sys.SYSNAME),
	-- DATABASE_SIZE returns a NULL value for databases larger than 2.15 TB
	CASE WHEN (sum(table_size)::NUMERIC/1024.0) > 2.15 * 1024.0 * 1024.0 * 1024.0 THEN NULL
		ELSE CAST((sum(table_size)::NUMERIC/1024.0) AS int) END as database_size,
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
		LEFT JOIN pg_catalog.pg_class ON relnamespace = pg_catalog.pg_namespace.oid where pg_catalog.pg_class.relkind = 'r'
	) t
	GROUP BY database_name
	ORDER BY database_name;
GRANT SELECT on sys.sp_databases_view TO PUBLIC;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
