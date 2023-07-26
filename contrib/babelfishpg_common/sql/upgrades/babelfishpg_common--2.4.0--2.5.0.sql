-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.5.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE FUNCTION sys.int4varbinarydiv(leftarg int4 , rightarg sys.bbf_varbinary)
RETURNS int4
AS 'babelfishpg_common', 'int4varbinary_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR sys./ (
    LEFTARG = int4,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = int4varbinarydiv,
    COMMUTATOR = /
);

CREATE FUNCTION sys.varbinaryint4div(leftarg sys.bbf_varbinary , rightarg int4)
RETURNS int4
AS 'babelfishpg_common', 'varbinaryint4_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR sys./ (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = int4,
    FUNCTION = varbinaryint4div,
    COMMUTATOR = /
);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
