-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

ALTER FUNCTION sys.get_babel_server_collation_oid() RENAME TO get_babel_server_collation_oid_deprecated_in_2_3_0;

CREATE OR REPLACE FUNCTION sys.get_babel_server_collation_oid() RETURNS OID
LANGUAGE C
AS 'babelfishpg_common', 'get_server_collation_oid';

CREATE OR REPLACE PROCEDURE sys.init_server_collation_oid_common()
AS $$
DECLARE
    server_colloid OID;
BEGIN
    server_colloid = sys.get_babel_server_collation_oid();
    perform pg_catalog.set_config('babelfishpg_tsql.server_collation_oid', server_colloid::text, false);
    execute format('ALTER DATABASE %I SET babelfishpg_tsql.server_collation_oid FROM CURRENT', current_database());
END;
$$
LANGUAGE plpgsql;

CALL sys.init_server_collation_oid_common();

update pg_catalog.pg_type set typcollation = sys.get_babel_server_collation_oid()
where typname in ('varchar', 'bpchar', 'nvarchar', 'nchar', 'sql_variant', '_ci_sysname', 'sysname') and typnamespace = (select oid from pg_namespace where nspname = 'sys');

CREATE OR REPLACE FUNCTION sys.bigint_sum(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_sum(BIGINT)
RETURNS INT
AS 'babelfishpg_common' , 'int4int2_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.sum(BIGINT) (
SFUNC = int8_avg_accum,
FINALFUNC = bigint_sum,
STYPE = INTERNAL,
COMBINEFUNC = int8_avg_combine,
SERIALFUNC = int8_avg_serialize,
DESERIALFUNC = int8_avg_deserialize,
PARALLEL = SAFE
);


CREATE OR REPLACE AGGREGATE sys.sum(INT)(
SFUNC = int4_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.sum(SMALLINT)(
SFUNC = int2_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

CREATE OR REPLACE AGGREGATE sys.sum(TINYINT)(
SFUNC = int2_sum,
FINALFUNC = int4int2_sum,
STYPE = int8,
COMBINEFUNC = int8pl,
PARALLEL = SAFE
);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
