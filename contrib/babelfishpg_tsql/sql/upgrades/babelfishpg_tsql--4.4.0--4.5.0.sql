-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '4.5.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Please add your SQLs here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */
-- Update all grants to babelfish users to make bbf_role_admin as grantor.
DO
LANGUAGE plpgsql
$$
DECLARE
    temprow RECORD;
    query TEXT;
    init_user NAME;
BEGIN
    SELECT r.rolname
    INTO init_user
    FROM pg_roles r
    INNER JOIN pg_database d
    ON r.oid = d.datdba
    WHERE d.datname = current_database();

    FOR temprow IN
        WITH bbf_catalog AS (
            SELECT rolname::regrole AS roleid
            FROM sys.babelfish_authid_login_ext
            WHERE rolname != init_user
            UNION
            SELECT rolname::regrole AS roleid
            FROM sys.babelfish_authid_user_ext
        )
        SELECT am.roleid::regrole, am.member::regrole, am.grantor::regrole
        FROM pg_auth_members am
        INNER JOIN bbf_catalog cat ON am.roleid = cat.roleid
        INNER JOIN bbf_catalog cat2 ON am.member = cat2.roleid
        WHERE am.admin_option = 'f'
        AND am.grantor != 'bbf_role_admin'::regrole
    LOOP
        -- First revoke the existing grant
        query := pg_catalog.format('REVOKE %I FROM %I GRANTED BY %I;', temprow.roleid, temprow.member, temprow.grantor);
        EXECUTE query;
        -- Now create the grant with bbf_role_admin as grantor
        query := pg_catalog.format('GRANT %I TO %I GRANTED BY bbf_role_admin;', temprow.roleid, temprow.member);
        EXECUTE query;
    END LOOP;
END;
$$;

-- This is a temporary procedure which is only meant to be called during upgrade
CREATE OR REPLACE PROCEDURE sys.babelfish_revoke_guest_from_mapped_logins()
LANGUAGE C
AS 'babelfishpg_tsql', 'revoke_guest_from_mapped_logins';

CALL sys.babelfish_revoke_guest_from_mapped_logins();

-- Drop this procedure after it gets executed once.
DROP PROCEDURE sys.babelfish_revoke_guest_from_mapped_logins();

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
