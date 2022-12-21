-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '3.0.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

/* This helper function would only be useful and strictly be used during 1.x to 2.3 upgrade. */
CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

SELECT sys.babelfish_update_server_collation_name();

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- And reset babelfishpg_tsql.restored_server_collation_name and babelfishpg_tsql.restored_default_locale GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_default_locale', CURRENT_DATABASE());
        execute query;
    end;
$$;


-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);