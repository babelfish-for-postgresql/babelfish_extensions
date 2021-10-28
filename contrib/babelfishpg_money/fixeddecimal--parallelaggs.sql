
-- Aggregate Support

CREATE FUNCTION fixeddecimalaggstatecombine(INTERNAL, INTERNAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimalaggstatecombine'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION fixeddecimalaggstateserialize(INTERNAL)
RETURNS BYTEA
AS 'babelfishpg_money', 'fixeddecimalaggstateserialize'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION fixeddecimalaggstatedeserialize(BYTEA, INTERNAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimalaggstatedeserialize'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION fixeddecimal_avg_accum(INTERNAL, FIXEDDECIMAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimal_avg_accum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION fixeddecimal_sum(INTERNAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimal_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION fixeddecimal_avg(INTERNAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimal_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE AGGREGATE min(FIXEDDECIMAL) (
    SFUNC = fixeddecimalsmaller,
    STYPE = FIXEDDECIMAL,
    SORTOP = <,
    COMBINEFUNC = fixeddecimalsmaller,
    PARALLEL = SAFE
);

CREATE AGGREGATE max(FIXEDDECIMAL) (
    SFUNC = fixeddecimallarger,
    STYPE = FIXEDDECIMAL,
    SORTOP = >,
    COMBINEFUNC = fixeddecimallarger,
    PARALLEL = SAFE
);

CREATE AGGREGATE sum(FIXEDDECIMAL) (
    SFUNC = fixeddecimal_avg_accum,
    FINALFUNC = fixeddecimal_sum,
    STYPE = INTERNAL,
    COMBINEFUNC = fixeddecimalaggstatecombine,
    SERIALFUNC = fixeddecimalaggstateserialize,
    DESERIALFUNC = fixeddecimalaggstatedeserialize,
    PARALLEL = SAFE
);

CREATE AGGREGATE avg(FIXEDDECIMAL) (
    SFUNC = fixeddecimal_avg_accum,
    FINALFUNC = fixeddecimal_avg,
    STYPE = INTERNAL,
    COMBINEFUNC = fixeddecimalaggstatecombine,
    SERIALFUNC = fixeddecimalaggstateserialize,
    DESERIALFUNC = fixeddecimalaggstatedeserialize,
    PARALLEL = SAFE
);


