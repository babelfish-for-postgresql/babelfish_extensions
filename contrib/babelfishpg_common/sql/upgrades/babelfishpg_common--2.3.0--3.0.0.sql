-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '3.0.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

/* This helper function would only be useful and strictly be used during 1.x->2.3 and 2.3->3.0 upgrade. */
CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

SELECT sys.babelfish_update_server_collation_name();

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- And reset babelfishpg_tsql.restored_server_collation_name GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
    end;
$$;

CREATE OR REPLACE FUNCTION sys.bigint_avg(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_avg(pg_catalog._int8)
RETURNS INT
AS 'babelfishpg_common', 'int4int2_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.avg(TINYINT)(
SFUNC = int2_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(SMALLINT)(
SFUNC = int2_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(INT)(
SFUNC = int4_avg_accum,
FINALFUNC = int4int2_avg,
STYPE = _int8,
COMBINEFUNC = int4_avg_combine,
PARALLEL = SAFE,
INITCOND='{0,0}'
);

CREATE OR REPLACE AGGREGATE sys.avg(BIGINT) (
SFUNC = int8_avg_accum,
FINALFUNC = bigint_avg,
STYPE = INTERNAL,
COMBINEFUNC = int8_avg_combine,
SERIALFUNC = int8_avg_serialize,
DESERIALFUNC = int8_avg_deserialize,
PARALLEL = SAFE
);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);