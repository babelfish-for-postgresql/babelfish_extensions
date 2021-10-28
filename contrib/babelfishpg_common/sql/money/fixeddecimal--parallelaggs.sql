
-- Aggregate Support

CREATE FUNCTION sys.fixeddecimalaggstatecombine(INTERNAL, INTERNAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimalaggstatecombine'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalaggstateserialize(INTERNAL)
RETURNS BYTEA
AS 'babelfishpg_money', 'fixeddecimalaggstateserialize'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalaggstatedeserialize(BYTEA, INTERNAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimalaggstatedeserialize'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_avg_accum(INTERNAL, FIXEDDECIMAL)
RETURNS INTERNAL
AS 'babelfishpg_money', 'fixeddecimal_avg_accum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_sum(INTERNAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimal_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_avg(INTERNAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimal_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE AGGREGATE sys.min(FIXEDDECIMAL) (
    SFUNC = fixeddecimalsmaller,
    STYPE = FIXEDDECIMAL,
    SORTOP = <,
    COMBINEFUNC = fixeddecimalsmaller,
    PARALLEL = SAFE
);

CREATE AGGREGATE sys.max(FIXEDDECIMAL) (
    SFUNC = fixeddecimallarger,
    STYPE = FIXEDDECIMAL,
    SORTOP = >,
    COMBINEFUNC = fixeddecimallarger,
    PARALLEL = SAFE
);

CREATE AGGREGATE sys.sum(FIXEDDECIMAL) (
    SFUNC = fixeddecimal_avg_accum,
    FINALFUNC = fixeddecimal_sum,
    STYPE = INTERNAL,
    COMBINEFUNC = fixeddecimalaggstatecombine,
    SERIALFUNC = fixeddecimalaggstateserialize,
    DESERIALFUNC = fixeddecimalaggstatedeserialize,
    PARALLEL = SAFE
);

CREATE AGGREGATE sys.avg(FIXEDDECIMAL) (
    SFUNC = fixeddecimal_avg_accum,
    FINALFUNC = fixeddecimal_avg,
    STYPE = INTERNAL,
    COMBINEFUNC = fixeddecimalaggstatecombine,
    SERIALFUNC = fixeddecimalaggstateserialize,
    DESERIALFUNC = fixeddecimalaggstatedeserialize,
    PARALLEL = SAFE
);


