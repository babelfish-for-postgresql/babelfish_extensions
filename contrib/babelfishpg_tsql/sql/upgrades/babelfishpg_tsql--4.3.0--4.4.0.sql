-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.4.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE VIEW sys.configurations
AS
SELECT  configuration_id, 
        name, 
        value, 
        minimum, 
        maximum, 
        value_in_use, 
        description, 
        is_dynamic, 
        is_advanced 
FROM sys.babelfish_configurations
UNION ALL
SELECT 
CAST(103 as INT) AS configuration_id,
CAST('user connections' AS SYS.NVARCHAR(35)) AS name,
CAST(s.setting AS sys.sql_variant) AS value,
CAST(s.min_val AS sys.sql_variant) AS minimum,
CAST(s.max_val AS sys.sql_variant) AS maximum,
CAST(s.setting AS sys.sql_variant) AS value_in_use,
CAST(s.short_desc AS sys.nvarchar(255)) AS description,
CAST(0 AS sys.BIT) AS is_dynamic,
CAST(1 AS sys.BIT) AS is_advanced
FROM pg_catalog.pg_settings s where name = 'max_connections'
UNION ALL
SELECT 
CAST(505 as INT) AS configuration_id,
CAST('network packet size (B)' AS SYS.NVARCHAR(35)) AS name,
CAST(s.setting AS sys.sql_variant) AS value,
CAST(s.min_val AS sys.sql_variant) AS minimum,
CAST(s.max_val AS sys.sql_variant) AS maximum,
CAST(s.setting AS sys.sql_variant) AS value_in_use,
CAST(s.short_desc AS sys.nvarchar(255)) AS description,
CAST(1 AS sys.BIT) AS is_dynamic,
CAST(1 AS sys.BIT) AS is_advanced
FROM pg_catalog.pg_settings s where name = 'babelfishpg_tds.tds_default_packet_size'
ORDER BY configuration_id;
GRANT SELECT ON sys.configurations TO PUBLIC;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
