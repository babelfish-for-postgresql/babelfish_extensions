 -- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '1.2.1'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);
-- enable DDL from pgendpoint
SELECT set_config('babelfishpg_tsql.enable_ddl_from_pgendpoint', 'true', false);

SELECT set_config('babelfishpg_tsql.enable_ddl_from_pgendpoint', 'false', false);
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);