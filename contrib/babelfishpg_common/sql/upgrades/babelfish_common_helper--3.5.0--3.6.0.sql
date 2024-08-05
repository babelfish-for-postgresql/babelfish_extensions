------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "3.6.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

DO $$
DECLARE 
    schema_oid oid;
    cast_source oid;
    cast_target oid;
BEGIN
    select oid INTO schema_oid from pg_namespace where nspname='sys';
    select oid into cast_source from pg_type where typname='bbf_binary' and typnamespace=schema_oid;
    select oid into cast_target from pg_type where typname='varchar' and typnamespace=schema_oid;
    UPDATE pg_catalog.pg_cast SET castcontext='i' WHERE castsource=cast_source AND casttarget=cast_target;
END $$;

CREATE OR REPLACE FUNCTION sys.binary_lt(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
