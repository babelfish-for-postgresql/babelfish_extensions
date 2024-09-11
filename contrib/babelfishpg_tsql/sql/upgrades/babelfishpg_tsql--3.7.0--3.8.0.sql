-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.6.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

-- Assigning dbo role to the db_owner login
DO $$
DECLARE
    owner_name NAME;
    db_name TEXT;
    role_name NAME;
    owner_cursor CURSOR FOR SELECT DISTINCT owner, name FROM sys.babelfish_sysdatabases;
BEGIN
    OPEN owner_cursor;
    FETCH NEXT FROM owner_cursor INTO owner_name, db_name;

    WHILE FOUND
    LOOP
        SELECT rolname FROM sys.babelfish_authid_user_ext WHERE database_name = db_name INTO role_name;

        IF db_name = 'master' OR db_name = 'tempdb' OR db_name = 'msdb'
        THEN
            FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
            CONTINUE;
        END IF;

        EXECUTE FORMAT('GRANT %I TO %I', role_name, owner_name);

        FETCH NEXT FROM owner_cursor INTO owner_name, db_name;
    END LOOP;

    CLOSE owner_cursor;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_varchar(INTERNAL)
RETURNS sys.VARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE FUNCTION bbf_string_agg_finalfn_nvarchar(INTERNAL)
RETURNS sys.NVARCHAR
AS 'string_agg_finalfn' LANGUAGE INTERNAL;

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.VARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_varchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.string_agg(sys.NVARCHAR, sys.VARCHAR) (
    SFUNC = string_agg_transfn,
    FINALFUNC = bbf_string_agg_finalfn_nvarchar,
    STYPE = INTERNAL,
    PARALLEL = SAFE
);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
