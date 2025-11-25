-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.9.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);


-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE FUNCTION sys.fn_varbintohexstr(expression sys.varbinary)
RETURNS sys.nvarchar AS 
$$ 
BEGIN 
    IF sys.len(expression) = 0 THEN
        RETURN NULL;
    END IF;
    RETURN pg_catalog.lower(expression::PG_CATALOG.TEXT);
END;
$$ 
LANGUAGE plpgsql IMMUTABLE STRICT;

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();
-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
