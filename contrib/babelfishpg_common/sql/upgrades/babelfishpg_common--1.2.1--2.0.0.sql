-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.0.0'" to load this file. \quit

-- CREATE OR REPLACE FUNCTION sys.babelfish_set_next_oid(OID)
-- RETURNS void
-- AS 'babelfishpg_common', 'BabelfishSetNextOid'
-- LANGUAGE C;

-- DO $$
-- DECLARE
--     maxOidFromAllObjects INT;
--     oidFromCheckpoint INT;
-- BEGIN
--         SELECT next_oid FROM pg_control_checkpoint() INTO oidFromCheckpoint;
--         SELECT max(object_id) FROM sys.all_objects INTO maxOidFromAllObjects;
--         perform sys.babelfish_set_next_oid(GREATEST(oidFromCheckpoint, maxOidFromAllObjects));
-- END$$;

-- DROP FUNCTION sys.babelfish_set_next_oid(OID);
