-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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