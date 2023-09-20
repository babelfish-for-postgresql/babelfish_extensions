-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.6.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- This is a temporary procedure which is called during upgrade to update guest schema
-- for the guest users in the already existing databases
CREATE OR REPLACE PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema()
LANGUAGE C
AS 'babelfishpg_tsql', 'update_user_catalog_for_guest_schema';

CALL sys.babelfish_update_user_catalog_for_guest_schema();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_update_user_catalog_for_guest_schema();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
