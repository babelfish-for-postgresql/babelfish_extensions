CREATE DOMAIN sys.TINYINT AS SMALLINT CHECK (VALUE >= 0 AND VALUE <= 255);
CREATE DOMAIN sys.INT AS INTEGER;
CREATE DOMAIN sys.BIGINT AS BIGINT;
CREATE DOMAIN sys.REAL AS REAL;
CREATE DOMAIN sys.FLOAT AS DOUBLE PRECISION;

-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.DECIMAL AS NUMERIC;
RESET enable_domain_typmod;

-- Domain Self Cast Functions to support Typmod Cast in Domain
CREATE OR REPLACE FUNCTION sys.decimal(sys.nchar, integer, boolean)
RETURNS sys.nchar
AS 'numeric'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.tinyintxor(leftarg sys.tinyint, rightarg sys.tinyint)
RETURNS sys.tinyint
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS sys.tinyint);
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = sys.tinyint,
    RIGHTARG = sys.tinyint,
    FUNCTION = sys.tinyintxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int2xor(leftarg int2, rightarg int2)
RETURNS int2
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS int2);
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int2,
    RIGHTARG = int2,
    FUNCTION = sys.int2xor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.intxor(leftarg int4, rightarg int4)
RETURNS int4
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(32)),
                    CAST(rightarg AS pg_catalog.bit(32))) AS int4)
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int4,
    RIGHTARG = int4,
    FUNCTION = sys.intxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int8xor(leftarg int8, rightarg int8)
RETURNS int8
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(64)),
                    CAST(rightarg AS pg_catalog.bit(64))) AS int8)
$$
LANGUAGE SQL STABLE;

CREATE OPERATOR sys.^ (
    LEFTARG = int8,
    RIGHTARG = int8,
    FUNCTION = sys.int8xor,
    COMMUTATOR = ^
);

-- tinyint operator definitions to force return type to tinyyint

CREATE OR REPLACE FUNCTION sys.tinyint_larger(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS 'int2larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tinyint_smaller(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS 'int2smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.TINYINT)
(
    sfunc = sys.tinyint_larger,
    stype = sys.tinyint,
    combinefunc = sys.tinyint_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.TINYINT)
(
    sfunc = sys.tinyint_smaller,
    stype = sys.tinyint,
    combinefunc = sys.tinyint_smaller,
    parallel = safe
);

CREATE FUNCTION sys.tinyintum(sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2um($1)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintpl(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2pl($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintmi(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2mi($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintmul(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2mul($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintdiv(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2div($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = +,
    PROCEDURE  = sys.tinyintpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintmi
);

CREATE OPERATOR sys.- (
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintum
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = *,
    PROCEDURE  = sys.tinyintmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintdiv
);


CREATE FUNCTION sys.smallmoneytinyintpl(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2pl($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintmi(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2mi($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintmul(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2mul($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintdiv(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2div($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = +,
    PROCEDURE  = sys.smallmoneytinyintpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.smallmoneytinyintmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = *,
    PROCEDURE  = sys.smallmoneytinyintmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.smallmoneytinyintdiv
);

CREATE FUNCTION sys.tinyintsmallmoneypl(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalpl($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneymi(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalmi($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneymul(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalmul($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneydiv(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimaldiv($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = sys.tinyintsmallmoneypl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = sys.tinyintsmallmoneymi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = sys.tinyintsmallmoneymul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = sys.tinyintsmallmoneydiv
);


-- function definition on REAL datatype to force return type to REAL

CREATE OR REPLACE FUNCTION sys.real_larger(sys.REAL, sys.REAL)
RETURNS sys.REAL
AS 'float4larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.real_smaller(sys.REAL, sys.REAL)
RETURNS sys.REAL
AS 'float4smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.REAL)
(
    sfunc = sys.real_larger,
    stype = sys.real,
    combinefunc = sys.real_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.REAL)
(
    sfunc = sys.real_smaller,
    stype = sys.real,
    combinefunc = sys.real_smaller,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.bigint_sum(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bigint_avg(INTERNAL)
RETURNS BIGINT
AS 'babelfishpg_common', 'bigint_avg'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_sum(BIGINT)
RETURNS INT
AS 'babelfishpg_common' , 'int4int2_sum'
LANGUAGE C IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4int2_avg(pg_catalog._int8)
RETURNS INT
AS 'babelfishpg_common', 'int4int2_avg'
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