-- 1 "sql/babelfishpg_common.in"
-- 1 "<built-in>"
-- 1 "<command-line>"
-- 1 "sql/babelfishpg_common.in"





CREATE SCHEMA sys;
GRANT USAGE ON SCHEMA sys TO PUBLIC;


SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- 1 "sql/money/fixeddecimal--1.1.0_base_parallel.sql" 1
------------------
-- FIXEDDECIMAL --
------------------

CREATE TYPE sys.FIXEDDECIMAL;

CREATE FUNCTION sys.fixeddecimalin(cstring, oid, int4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalout(fixeddecimal)
RETURNS cstring
AS 'babelfishpg_money', 'fixeddecimalout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalrecv(internal)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalsend(FIXEDDECIMAL)
RETURNS bytea
AS 'babelfishpg_money', 'fixeddecimalsend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaltypmodin(_cstring)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimaltypmodin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaltypmodout(INT4)
RETURNS cstring
AS 'babelfishpg_money', 'fixeddecimaltypmodout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE TYPE sys.FIXEDDECIMAL (
    INPUT = fixeddecimalin,
    OUTPUT = fixeddecimalout,
    RECEIVE = fixeddecimalrecv,
    SEND = fixeddecimalsend,
 TYPMOD_IN = fixeddecimaltypmodin,
 TYPMOD_OUT = fixeddecimaltypmodout,
    INTERNALLENGTH = 8,
 ALIGNMENT = 'double',
    STORAGE = plain,
    CATEGORY = 'N',
    PREFERRED = false,
    COLLATABLE = false,
 PASSEDBYVALUE -- But not always.. XXX fix that.
);

-- FIXEDDECIMAL, NUMERIC
CREATE FUNCTION sys.fixeddecimaleq(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimaleq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalne(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimallt(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimallt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalle(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalgt(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalgt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalge(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalum(FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalum'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalpl(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalmi(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalmul(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaldiv(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.abs(FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalabs'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimallarger(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimallarger'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalsmaller(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalsmaller'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_cmp(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_hash(FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_hash'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- Operators.
--

-- FIXEDDECIMAL op FIXEDDECIMAL
CREATE OPERATOR sys.= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = fixeddecimaleq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = fixeddecimalne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = fixeddecimallt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = fixeddecimalle,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = fixeddecimalge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = fixeddecimalgt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE = fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = fixeddecimalmi
);

CREATE OPERATOR sys.- (
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = fixeddecimalum
);

CREATE OPERATOR sys.* (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE = fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = fixeddecimaldiv
);

CREATE OPERATOR CLASS sys.fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 2 <= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 3 = (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 4 >= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 5 > (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_cmp(FIXEDDECIMAL, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

-- FIXEDDECIMAL, NUMERIC
CREATE FUNCTION sys.fixeddecimal_numeric_cmp(FIXEDDECIMAL, NUMERIC)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_cmp(NUMERIC, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'numeric_fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_eq(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_ne(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_lt(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_le(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_gt(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric_ge(FIXEDDECIMAL, NUMERIC)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_numeric_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = fixeddecimal_numeric_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = fixeddecimal_numeric_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = fixeddecimal_numeric_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = fixeddecimal_numeric_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = fixeddecimal_numeric_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = NUMERIC,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = fixeddecimal_numeric_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR CLASS sys.fixeddecimal_numeric_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (FIXEDDECIMAL, NUMERIC),
    OPERATOR 2 <= (FIXEDDECIMAL, NUMERIC),
    OPERATOR 3 = (FIXEDDECIMAL, NUMERIC),
    OPERATOR 4 >= (FIXEDDECIMAL, NUMERIC),
    OPERATOR 5 > (FIXEDDECIMAL, NUMERIC),
    FUNCTION 1 fixeddecimal_numeric_cmp(FIXEDDECIMAL, NUMERIC);

CREATE OPERATOR CLASS sys.fixeddecimal_numeric_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (FIXEDDECIMAL, NUMERIC),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

-- NUMERIC, FIXEDDECIMAL
CREATE FUNCTION sys.numeric_fixeddecimal_eq(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_ne(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_lt(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_le(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_gt(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal_ge(NUMERIC, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'numeric_fixeddecimal_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = numeric_fixeddecimal_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = numeric_fixeddecimal_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = numeric_fixeddecimal_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = numeric_fixeddecimal_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR >= (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = numeric_fixeddecimal_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = NUMERIC,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = numeric_fixeddecimal_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR CLASS sys.numeric_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR 2 <= (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR 3 = (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR 4 >= (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR 5 > (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    FUNCTION 1 numeric_fixeddecimal_cmp(NUMERIC, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.numeric_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (NUMERIC, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

--
-- Cross type operators with int8
--

-- FIXEDDECIMAL, INT8
CREATE FUNCTION sys.fixeddecimal_int8_cmp(FIXEDDECIMAL, INT8)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_int8_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_eq(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_ne(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_lt(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_le(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_gt(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int8_ge(FIXEDDECIMAL, INT8)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int8_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8pl(FIXEDDECIMAL, INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint8pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8mi(FIXEDDECIMAL, INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint8mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8mul(FIXEDDECIMAL, INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint8mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8div(FIXEDDECIMAL, INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint8div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = fixeddecimal_int8_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = fixeddecimal_int8_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = fixeddecimal_int8_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = fixeddecimal_int8_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = fixeddecimal_int8_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = fixeddecimal_int8_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    COMMUTATOR = +,
    PROCEDURE = fixeddecimalint8pl
);

CREATE OPERATOR sys.- (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    PROCEDURE = fixeddecimalint8mi
);

CREATE OPERATOR sys.* (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    COMMUTATOR = *,
    PROCEDURE = fixeddecimalint8mul
);

CREATE OPERATOR sys./ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT8,
    PROCEDURE = fixeddecimalint8div
);

CREATE OPERATOR CLASS sys.fixeddecimal_int8_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (FIXEDDECIMAL, INT8),
    OPERATOR 2 <= (FIXEDDECIMAL, INT8),
    OPERATOR 3 = (FIXEDDECIMAL, INT8),
    OPERATOR 4 >= (FIXEDDECIMAL, INT8),
    OPERATOR 5 > (FIXEDDECIMAL, INT8),
    FUNCTION 1 fixeddecimal_int8_cmp(FIXEDDECIMAL, INT8);

CREATE OPERATOR CLASS sys.fixeddecimal_int8_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (FIXEDDECIMAL, INT8),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

-- INT8, FIXEDDECIMAL
CREATE FUNCTION sys.int8_fixeddecimal_cmp(INT8, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'int8_fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_eq(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_ne(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_lt(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_le(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_gt(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_fixeddecimal_ge(INT8, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int8_fixeddecimal_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimalpl(INT8, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int8fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimalmi(INT8, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int8fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimalmul(INT8, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int8fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimaldiv(INT8, FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int8fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = int8_fixeddecimal_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = int8_fixeddecimal_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = int8_fixeddecimal_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = int8_fixeddecimal_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = int8_fixeddecimal_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = int8_fixeddecimal_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE = int8fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int8fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE = int8fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG = INT8,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int8fixeddecimaldiv
);

CREATE OPERATOR CLASS sys.int8_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (INT8, FIXEDDECIMAL),
    OPERATOR 2 <= (INT8, FIXEDDECIMAL),
    OPERATOR 3 = (INT8, FIXEDDECIMAL),
    OPERATOR 4 >= (INT8, FIXEDDECIMAL),
    OPERATOR 5 > (INT8, FIXEDDECIMAL),
    FUNCTION 1 int8_fixeddecimal_cmp(INT8, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.int8_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (INT8, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

--
-- Cross type operators with int4
--

-- FIXEDDECIMAL, INT4
CREATE FUNCTION sys.fixeddecimal_int4_cmp(FIXEDDECIMAL, INT4)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_int4_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_eq(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_ne(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_lt(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_le(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_gt(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int4_ge(FIXEDDECIMAL, INT4)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int4_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4pl(FIXEDDECIMAL, INT4)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint4pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4mi(FIXEDDECIMAL, INT4)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint4mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4mul(FIXEDDECIMAL, INT4)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint4mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4div(FIXEDDECIMAL, INT4)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint4div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = fixeddecimal_int4_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = fixeddecimal_int4_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = fixeddecimal_int4_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = fixeddecimal_int4_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = fixeddecimal_int4_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = fixeddecimal_int4_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    COMMUTATOR = +,
    PROCEDURE = fixeddecimalint4pl
);

CREATE OPERATOR sys.- (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    PROCEDURE = fixeddecimalint4mi
);

CREATE OPERATOR sys.* (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    COMMUTATOR = *,
    PROCEDURE = fixeddecimalint4mul
);

CREATE OPERATOR sys./ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT4,
    PROCEDURE = fixeddecimalint4div
);

CREATE OPERATOR CLASS sys.fixeddecimal_int4_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (FIXEDDECIMAL, INT4),
    OPERATOR 2 <= (FIXEDDECIMAL, INT4),
    OPERATOR 3 = (FIXEDDECIMAL, INT4),
    OPERATOR 4 >= (FIXEDDECIMAL, INT4),
    OPERATOR 5 > (FIXEDDECIMAL, INT4),
    FUNCTION 1 fixeddecimal_int4_cmp(FIXEDDECIMAL, INT4);

CREATE OPERATOR CLASS sys.fixeddecimal_int4_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (FIXEDDECIMAL, INT4),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

-- INT4, FIXEDDECIMAL
CREATE FUNCTION sys.int4_fixeddecimal_cmp(INT4, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'int4_fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_eq(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_ne(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_lt(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_le(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_gt(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_fixeddecimal_ge(INT4, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int4_fixeddecimal_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimalpl(INT4, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int4fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimalmi(INT4, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int4fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimalmul(INT4, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int4fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimaldiv(INT4, FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int4fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = int4_fixeddecimal_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = int4_fixeddecimal_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = int4_fixeddecimal_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = int4_fixeddecimal_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = int4_fixeddecimal_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = int4_fixeddecimal_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE = int4fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int4fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE = int4fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG = INT4,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int4fixeddecimaldiv
);

CREATE OPERATOR CLASS sys.int4_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (INT4, FIXEDDECIMAL),
    OPERATOR 2 <= (INT4, FIXEDDECIMAL),
    OPERATOR 3 = (INT4, FIXEDDECIMAL),
    OPERATOR 4 >= (INT4, FIXEDDECIMAL),
    OPERATOR 5 > (INT4, FIXEDDECIMAL),
    FUNCTION 1 int4_fixeddecimal_cmp(INT4, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.int4_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (INT4, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

--
-- Cross type operators with int2
--
-- FIXEDDECIMAL, INT2
CREATE FUNCTION sys.fixeddecimal_int2_cmp(FIXEDDECIMAL, INT2)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_int2_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_eq(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_ne(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_lt(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_le(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_gt(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_int2_ge(FIXEDDECIMAL, INT2)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimal_int2_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2pl(FIXEDDECIMAL, INT2)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint2pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2mi(FIXEDDECIMAL, INT2)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint2mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2mul(FIXEDDECIMAL, INT2)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint2mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2div(FIXEDDECIMAL, INT2)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'fixeddecimalint2div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = fixeddecimal_int2_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = fixeddecimal_int2_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = fixeddecimal_int2_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = fixeddecimal_int2_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = fixeddecimal_int2_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = fixeddecimal_int2_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    COMMUTATOR = +,
    PROCEDURE = fixeddecimalint2pl
);

CREATE OPERATOR sys.- (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    PROCEDURE = fixeddecimalint2mi
);

CREATE OPERATOR sys.* (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    COMMUTATOR = *,
    PROCEDURE = fixeddecimalint2mul
);

CREATE OPERATOR sys./ (
    LEFTARG = FIXEDDECIMAL,
    RIGHTARG = INT2,
    PROCEDURE = fixeddecimalint2div
);

CREATE OPERATOR CLASS sys.fixeddecimal_int2_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (FIXEDDECIMAL, INT2),
    OPERATOR 2 <= (FIXEDDECIMAL, INT2),
    OPERATOR 3 = (FIXEDDECIMAL, INT2),
    OPERATOR 4 >= (FIXEDDECIMAL, INT2),
    OPERATOR 5 > (FIXEDDECIMAL, INT2),
    FUNCTION 1 fixeddecimal_int2_cmp(FIXEDDECIMAL, INT2);

CREATE OPERATOR CLASS sys.fixeddecimal_int2_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (FIXEDDECIMAL, INT2),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

-- INT2, FIXEDDECIMAL
CREATE FUNCTION sys.int2_fixeddecimal_cmp(INT2, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'int2_fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_eq(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_ne(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_lt(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_le(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_gt(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_fixeddecimal_ge(INT2, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'int2_fixeddecimal_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimalpl(INT2, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int2fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimalmi(INT2, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int2fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimalmul(INT2, FIXEDDECIMAL)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int2fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimaldiv(INT2, FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int2fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = int2_fixeddecimal_eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = int2_fixeddecimal_ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = int2_fixeddecimal_lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = int2_fixeddecimal_le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = int2_fixeddecimal_ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = int2_fixeddecimal_gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE = int2fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int2fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE = int2fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG = INT2,
    RIGHTARG = FIXEDDECIMAL,
    PROCEDURE = int2fixeddecimaldiv
);

CREATE OPERATOR CLASS sys.int2_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR 1 < (INT2, FIXEDDECIMAL),
    OPERATOR 2 <= (INT2, FIXEDDECIMAL),
    OPERATOR 3 = (INT2, FIXEDDECIMAL),
    OPERATOR 4 >= (INT2, FIXEDDECIMAL),
    OPERATOR 5 > (INT2, FIXEDDECIMAL),
    FUNCTION 1 int2_fixeddecimal_cmp(INT2, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.int2_fixeddecimal_ops
FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR 1 = (INT2, FIXEDDECIMAL),
    FUNCTION 1 fixeddecimal_hash(FIXEDDECIMAL);

--
-- Casts
--

CREATE FUNCTION sys.fixeddecimal(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimal(INT8)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int8fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8(FIXEDDECIMAL)
RETURNS INT8
AS 'babelfishpg_money', 'fixeddecimalint8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimal(INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int4fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4(FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimalint4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimal(INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int2fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2(FIXEDDECIMAL)
RETURNS INT2
AS 'babelfishpg_money', 'fixeddecimalint2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaltod(FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'fixeddecimaltod'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.dtofixeddecimal(DOUBLE PRECISION)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'dtofixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaltof(FIXEDDECIMAL)
RETURNS REAL
AS 'babelfishpg_money', 'fixeddecimaltof'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.ftofixeddecimal(REAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'ftofixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimal_numeric(FIXEDDECIMAL)
RETURNS NUMERIC
AS 'babelfishpg_money', 'fixeddecimal_numeric'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_fixeddecimal(NUMERIC)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'numeric_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS FIXEDDECIMAL)
 WITH FUNCTION fixeddecimal (FIXEDDECIMAL, INT4) AS ASSIGNMENT;

CREATE CAST (INT8 AS FIXEDDECIMAL)
 WITH FUNCTION int8fixeddecimal (INT8) AS IMPLICIT;

CREATE CAST (FIXEDDECIMAL AS INT8)
 WITH FUNCTION fixeddecimalint8 (FIXEDDECIMAL) AS ASSIGNMENT;

CREATE CAST (INT4 AS FIXEDDECIMAL)
 WITH FUNCTION int4fixeddecimal (INT4) AS IMPLICIT;

CREATE CAST (FIXEDDECIMAL AS INT4)
 WITH FUNCTION fixeddecimalint4 (FIXEDDECIMAL) AS ASSIGNMENT;

CREATE CAST (INT2 AS FIXEDDECIMAL)
 WITH FUNCTION int2fixeddecimal (INT2) AS IMPLICIT;

CREATE CAST (FIXEDDECIMAL AS INT2)
 WITH FUNCTION fixeddecimalint2 (FIXEDDECIMAL) AS ASSIGNMENT;

CREATE CAST (FIXEDDECIMAL AS DOUBLE PRECISION)
 WITH FUNCTION fixeddecimaltod (FIXEDDECIMAL) AS IMPLICIT;

CREATE CAST (DOUBLE PRECISION AS FIXEDDECIMAL)
 WITH FUNCTION dtofixeddecimal (DOUBLE PRECISION) AS ASSIGNMENT; -- XXX? or Implicit?

CREATE CAST (FIXEDDECIMAL AS REAL)
 WITH FUNCTION fixeddecimaltof (FIXEDDECIMAL) AS IMPLICIT;

CREATE CAST (REAL AS FIXEDDECIMAL)
 WITH FUNCTION ftofixeddecimal (REAL) AS ASSIGNMENT; -- XXX or Implicit?

CREATE CAST (FIXEDDECIMAL AS NUMERIC)
 WITH FUNCTION fixeddecimal_numeric (FIXEDDECIMAL) AS IMPLICIT;

CREATE CAST (NUMERIC AS FIXEDDECIMAL)
 WITH FUNCTION numeric_fixeddecimal (NUMERIC) AS IMPLICIT;

CREATE DOMAIN sys.MONEY as sys.FIXEDDECIMAL CHECK (VALUE >= -922337203685477.5808 AND VALUE <= 922337203685477.5807);
CREATE DOMAIN sys.SMALLMONEY as sys.FIXEDDECIMAL CHECK (VALUE >= -214748.3648 AND VALUE <= 214748.3647);
-- 13 "sql/babelfishpg_common.in" 2
-- 1 "sql/money/fixeddecimal--parallelaggs.sql" 1

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
-- 14 "sql/babelfishpg_common.in" 2
-- 1 "sql/money/fixeddecimal--brin.sql" 1
CREATE OPERATOR CLASS sys.fixeddecimal_minmax_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING brin AS
    OPERATOR 1 < (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 2 <= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 3 = (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 4 >= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR 5 > (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION 1 brin_minmax_opcinfo(INTERNAL),
    FUNCTION 2 brin_minmax_add_value(INTERNAL, INTERNAL, INTERNAL, INTERNAL),
    FUNCTION 3 brin_minmax_consistent(INTERNAL, INTERNAL, INTERNAL),
    FUNCTION 4 brin_minmax_union(INTERNAL, INTERNAL, INTERNAL);
-- 15 "sql/babelfishpg_common.in" 2
-- 1 "sql/bpchar.sql" 1
CREATE TYPE sys.BPCHAR;

-- Basic functions
CREATE OR REPLACE FUNCTION sys.bpcharin(cstring)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpcharin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharout(sys.BPCHAR)
RETURNS cstring
AS 'bpcharout'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharrecv(internal)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpcharrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharsend(sys.BPCHAR)
RETURNS bytea
AS 'bpcharsend'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.BPCHAR (
    INPUT = sys.bpcharin,
    OUTPUT = sys.bpcharout,
    RECEIVE = sys.bpcharrecv,
    SEND = sys.bpcharsend,
    TYPMOD_IN = bpchartypmodin,
    TYPMOD_OUT = bpchartypmodout,
    CATEGORY = 'S',
    COLLATABLE = True,
    LIKE = pg_catalog.BPCHAR
);

-- Basic operator functions
CREATE FUNCTION sys.bpchareq(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharlt(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharlt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharle(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharle'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchargt(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpchargt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharge(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

-- Basic operators
-- Note that if those operators are not in pg_catalog, we will see different behaviors depending on sql_dialect
CREATE OPERATOR pg_catalog.= (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpchareq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES,
    HASHES
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpcharne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR pg_catalog.< (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.>=),
    COMMUTATOR = OPERATOR(pg_catalog.>),
    PROCEDURE = sys.bpcharlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR pg_catalog.<= (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.>),
    COMMUTATOR = OPERATOR(pg_catalog.>=),
    PROCEDURE = sys.bpcharle,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR pg_catalog.> (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.<=),
    COMMUTATOR = OPERATOR(pg_catalog.<),
    PROCEDURE = sys.bpchargt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR pg_catalog.>= (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.<),
    COMMUTATOR = OPERATOR(pg_catalog.<=),
    PROCEDURE = sys.bpcharge,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

-- Operator classes
CREATE FUNCTION sys.bpcharcmp(sys.BPCHAR, sys.BPCHAR)
RETURNS INT4
AS 'bpcharcmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.hashbpchar(sys.BPCHAR)
RETURNS INT4
AS 'hashbpchar'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS bpchar_ops
    DEFAULT FOR TYPE sys.BPCHAR USING btree AS
    OPERATOR 1 pg_catalog.< (sys.BPCHAR, sys.BPCHAR),
    OPERATOR 2 pg_catalog.<= (sys.BPCHAR, sys.BPCHAR),
    OPERATOR 3 pg_catalog.= (sys.BPCHAR, sys.BPCHAR),
    OPERATOR 4 pg_catalog.>= (sys.BPCHAR, sys.BPCHAR),
    OPERATOR 5 pg_catalog.> (sys.BPCHAR, sys.BPCHAR),
    FUNCTION 1 sys.bpcharcmp(sys.BPCHAR, sys.BPCHAR);

CREATE OPERATOR CLASS bpchar_ops
    DEFAULT FOR TYPE sys.BPCHAR USING hash AS
    OPERATOR 1 pg_catalog.= (sys.BPCHAR, sys.BPCHAR),
    FUNCTION 1 sys.hashbpchar(sys.BPCHAR);

CREATE OR REPLACE FUNCTION sys.bpchar(sys.BPCHAR, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- To sys.BPCHAR
CREATE CAST (sys.BPCHAR AS sys.BPCHAR)
WITH FUNCTION sys.BPCHAR (sys.BPCHAR, integer, boolean) AS IMPLICIT;

CREATE CAST (pg_catalog.VARCHAR as sys.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.TEXT as sys.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.BOOL as sys.BPCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

-- From sys.BPCHAR
CREATE CAST (sys.BPCHAR AS pg_catalog.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as pg_catalog.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as pg_catalog.TEXT)
WITHOUT FUNCTION AS IMPLICIT;

-- Operators between different types
CREATE FUNCTION sys.bpchareq(sys.BPCHAR, pg_catalog.TEXT)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchareq(pg_catalog.TEXT, sys.BPCHAR)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(sys.BPCHAR, pg_catalog.TEXT)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(pg_catalog.TEXT, sys.BPCHAR)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR pg_catalog.= (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = pg_catalog.TEXT,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpchareq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR pg_catalog.= (
    LEFTARG = pg_catalog.TEXT,
    RIGHTARG = sys.BPCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpchareq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG = sys.BPCHAR,
    RIGHTARG = pg_catalog.TEXT,
    NEGATOR = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpcharne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG = pg_catalog.TEXT,
    RIGHTARG = sys.BPCHAR,
    NEGATOR = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.bpcharne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.NCHAR AS sys.BPCHAR;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.nchar(sys.nchar, integer, boolean)
RETURNS sys.nchar
AS 'babelfishpg_common', 'bpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


SET client_min_messages = 'ERROR';
CREATE CAST (sys.nchar AS sys.nchar)
WITH FUNCTION sys.nchar (sys.nchar, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';
-- 16 "sql/babelfishpg_common.in" 2
-- 1 "sql/varchar.sql" 1
CREATE TYPE sys.VARCHAR;

-- Basic functions
CREATE OR REPLACE FUNCTION sys.varcharin(cstring)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varcharin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharout(sys.VARCHAR)
RETURNS cstring
AS 'varcharout'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharrecv(internal)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varcharrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharsend(sys.VARCHAR)
RETURNS bytea
AS 'varcharsend'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.VARCHAR (
    INPUT = sys.varcharin,
    OUTPUT = sys.varcharout,
    RECEIVE = sys.varcharrecv,
    SEND = sys.varcharsend,
    TYPMOD_IN = varchartypmodin,
    TYPMOD_OUT = varchartypmodout,
    CATEGORY = 'S',
    COLLATABLE = True,
    LIKE = pg_catalog.VARCHAR
);

-- Basic operator functions
CREATE FUNCTION sys.varchareq(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varchareq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharne(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharlt(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharle(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varchargt(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varchargt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharge(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Basic operators
-- Note that if those operators are not in pg_catalog, we will see different behaviors depending on sql_dialect
CREATE OPERATOR pg_catalog.= (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.varchareq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES,
    HASHES
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    NEGATOR = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE = sys.varcharne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR pg_catalog.< (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    NEGATOR = OPERATOR(pg_catalog.>=),
    COMMUTATOR = OPERATOR(pg_catalog.>),
    PROCEDURE = sys.varcharlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR pg_catalog.<= (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    NEGATOR = OPERATOR(pg_catalog.>),
    COMMUTATOR = OPERATOR(pg_catalog.>=),
    PROCEDURE = sys.varcharle,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR pg_catalog.> (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    NEGATOR = OPERATOR(pg_catalog.<=),
    COMMUTATOR = OPERATOR(pg_catalog.<),
    PROCEDURE = sys.varchargt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR pg_catalog.>= (
    LEFTARG = sys.VARCHAR,
    RIGHTARG = sys.VARCHAR,
    NEGATOR = OPERATOR(pg_catalog.<),
    COMMUTATOR = OPERATOR(pg_catalog.<=),
    PROCEDURE = sys.varcharge,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

-- Operator classes
CREATE FUNCTION sys.varcharcmp(sys.VARCHAR, sys.VARCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'varcharcmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.hashvarchar(sys.VARCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'hashvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS varchar_ops
    DEFAULT FOR TYPE sys.VARCHAR USING btree AS
    OPERATOR 1 pg_catalog.< (sys.VARCHAR, sys.VARCHAR),
    OPERATOR 2 pg_catalog.<= (sys.VARCHAR, sys.VARCHAR),
    OPERATOR 3 pg_catalog.= (sys.VARCHAR, sys.VARCHAR),
    OPERATOR 4 pg_catalog.>= (sys.VARCHAR, sys.VARCHAR),
    OPERATOR 5 pg_catalog.> (sys.VARCHAR, sys.VARCHAR),
    FUNCTION 1 sys.varcharcmp(sys.VARCHAR, sys.VARCHAR);

CREATE OPERATOR CLASS varchar_ops
    DEFAULT FOR TYPE sys.VARCHAR USING hash AS
    OPERATOR 1 pg_catalog.= (sys.VARCHAR, sys.VARCHAR),
    FUNCTION 1 sys.hashvarchar(sys.VARCHAR);

-- Typmode cast function
CREATE OR REPLACE FUNCTION sys.varchar(sys.VARCHAR, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- To sys.VARCHAR
CREATE CAST (sys.VARCHAR AS sys.VARCHAR)
WITH FUNCTION sys.VARCHAR (sys.VARCHAR, integer, boolean) AS IMPLICIT;

CREATE CAST (pg_catalog.VARCHAR as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.TEXT as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.BOOL as sys.VARCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

-- From sys.VARCHAR
CREATE CAST (sys.VARCHAR AS pg_catalog.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.VARCHAR as pg_catalog.TEXT)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.VARCHAR as pg_catalog.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.NVARCHAR AS sys.VARCHAR;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.nvarchar(sys.nvarchar, integer, boolean)
RETURNS sys.nvarchar
AS 'babelfishpg_common', 'varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

SET client_min_messages = 'ERROR';
CREATE CAST (sys.nvarchar AS sys.nvarchar)
WITH FUNCTION sys.nvarchar (sys.nvarchar, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';
-- 17 "sql/babelfishpg_common.in" 2
-- 1 "sql/numerics.sql" 1
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
LANGUAGE SQL;

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
LANGUAGE SQL;

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
LANGUAGE SQL;

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
LANGUAGE SQL;

CREATE OPERATOR sys.^ (
    LEFTARG = int8,
    RIGHTARG = int8,
    FUNCTION = sys.int8xor,
    COMMUTATOR = ^
);
-- 18 "sql/babelfishpg_common.in" 2
-- 1 "sql/strings.sql" 1
CREATE DOMAIN sys.NTEXT AS TEXT;
CREATE DOMAIN sys.SYSNAME AS sys.VARCHAR(128);
-- 19 "sql/babelfishpg_common.in" 2
-- 1 "sql/bit.sql" 1
CREATE TYPE sys.BIT;

CREATE OR REPLACE FUNCTION sys.bitin(cstring)
RETURNS sys.BIT
AS 'babelfishpg_common', 'bitin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bitout(sys.BIT)
RETURNS cstring
AS 'babelfishpg_common', 'bitout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bitrecv(internal)
RETURNS sys.BIT
AS 'babelfishpg_common', 'bitrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bitsend(sys.BIT)
RETURNS bytea
AS 'babelfishpg_common', 'bitsend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.BIT (
    INPUT = sys.bitin,
    OUTPUT = sys.bitout,
    RECEIVE = sys.bitrecv,
    SEND = sys.bitsend,
    INTERNALLENGTH = 1,
    PASSEDBYVALUE,
    ALIGNMENT = 'char',
    STORAGE = 'plain',
    CATEGORY = 'B',
    PREFERRED = true,
    COLLATABLE = false
  );

CREATE OR REPLACE FUNCTION sys.int2bit(INT2)
RETURNS sys.BIT
AS 'babelfishpg_common', 'int2bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT2 AS sys.BIT)
WITH FUNCTION sys.int2bit (INT2) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int4bit(INT4)
RETURNS sys.BIT
AS 'babelfishpg_common', 'int4bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT4 AS sys.BIT)
WITH FUNCTION sys.int4bit (INT4) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int8bit(INT8)
RETURNS sys.BIT
AS 'babelfishpg_common', 'int8bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT8 AS sys.BIT)
WITH FUNCTION sys.int8bit (INT8) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.ftobit(REAL)
RETURNS sys.BIT
AS 'babelfishpg_common', 'ftobit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (REAL AS sys.BIT)
WITH FUNCTION sys.ftobit (REAL) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.dtobit(DOUBLE PRECISION)
RETURNS sys.BIT
AS 'babelfishpg_common', 'dtobit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (DOUBLE PRECISION AS sys.BIT)
WITH FUNCTION sys.dtobit (DOUBLE PRECISION) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.numeric_bit(NUMERIC)
RETURNS sys.BIT
AS 'babelfishpg_common', 'numeric_bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.BIT)
WITH FUNCTION sys.numeric_bit (NUMERIC) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bit2int2(sys.BIT)
RETURNS INT2
AS 'babelfishpg_common', 'bit2int2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS INT2)
WITH FUNCTION sys.bit2int2 (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit2int4(sys.BIT)
RETURNS INT4
AS 'babelfishpg_common', 'bit2int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS INT4)
WITH FUNCTION sys.bit2int4 (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit2int8(sys.BIT)
RETURNS INT8
AS 'babelfishpg_common', 'bit2int8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS INT8)
WITH FUNCTION sys.bit2int8 (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit2numeric(sys.BIT)
RETURNS NUMERIC
AS 'babelfishpg_common', 'bit2numeric'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS NUMERIC)
WITH FUNCTION sys.bit2numeric (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit2fixeddec(sys.BIT)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_common', 'bit2fixeddec'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS FIXEDDECIMAL)
WITH FUNCTION sys.bit2fixeddec (sys.BIT) AS IMPLICIT;

CREATE FUNCTION sys.bitneg(sys.BIT)
RETURNS sys.BIT
AS 'babelfishpg_common', 'bitneg'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.biteq(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'biteq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitne(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'bitne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitlt(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'bitlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitle(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'bitle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitgt(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'bitgt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitge(sys.BIT, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'bitge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bit_cmp(sys.BIT, sys.BIT)
RETURNS int
AS 'babelfishpg_common', 'bit_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators for sys.BIT. TSQL doesn't support + - * / of bit
CREATE OPERATOR sys.- (
    RIGHTARG = sys.BIT,
    PROCEDURE = sys.bitneg
);

CREATE OPERATOR sys.= (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.biteq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.bitne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.bitlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.bitle,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.bitgt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.BIT,
    RIGHTARG = sys.BIT,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.bitge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR CLASS sys.bit_ops
DEFAULT FOR TYPE sys.bit USING btree AS
    OPERATOR 1 < (sys.bit, sys.bit),
    OPERATOR 2 <= (sys.bit, sys.bit),
    OPERATOR 3 = (sys.bit, sys.bit),
    OPERATOR 4 >= (sys.bit, sys.bit),
    OPERATOR 5 > (sys.bit, sys.bit),
    FUNCTION 1 sys.bit_cmp(sys.bit, sys.bit);


CREATE FUNCTION sys.int4biteq(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4biteq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4bitne(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4bitne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4bitlt(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4bitlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4bitle(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4bitle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4bitgt(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4bitgt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4bitge(INT4, sys.BIT)
RETURNS bool
AS 'babelfishpg_common', 'int4bitge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.int4biteq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.int4bitne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.int4bitlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.int4bitle,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.int4bitgt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = INT4,
    RIGHTARG = sys.BIT,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.int4bitge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);


CREATE FUNCTION sys.bitint4eq(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitint4ne(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitint4lt(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitint4le(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitint4gt(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bitint4ge(sys.BIT, INT4)
RETURNS bool
AS 'babelfishpg_common', 'bitint4ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.bitint4eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.bitint4ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.bitint4lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.bitint4le,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.bitint4gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.BIT,
    RIGHTARG = INT4,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.bitint4ge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OR REPLACE FUNCTION sys.bitxor(leftarg pg_catalog.bit, rightarg pg_catalog.bit)
RETURNS pg_catalog.bit
AS $$
SELECT (leftarg & ~rightarg) | (~leftarg & rightarg);
$$
LANGUAGE SQL;
-- 20 "sql/babelfishpg_common.in" 2
-- 1 "sql/varbinary.sql" 1
-- VARBINARY
CREATE TYPE sys.BBF_VARBINARY;

CREATE OR REPLACE FUNCTION sys.varbinaryin(cstring, oid, integer)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varbinaryin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinaryout(sys.BBF_VARBINARY)
RETURNS cstring
AS 'babelfishpg_common', 'varbinaryout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinaryrecv(internal, oid, integer)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varbinaryrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysend(sys.BBF_VARBINARY)
RETURNS bytea
AS 'babelfishpg_common', 'varbinarysend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarytypmodin(cstring[])
RETURNS integer
AS 'babelfishpg_common', 'varbinarytypmodin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarytypmodout(integer)
RETURNS cstring
AS 'babelfishpg_common', 'varbinarytypmodout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.BBF_VARBINARY (
    INPUT = sys.varbinaryin,
    OUTPUT = sys.varbinaryout,
    RECEIVE = sys.varbinaryrecv,
    SEND = sys.varbinarysend,
    TYPMOD_IN = sys.varbinarytypmodin,
    TYPMOD_OUT = sys.varbinarytypmodout,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT = 'int4',
    STORAGE = 'extended',
    CATEGORY = 'U',
    PREFERRED = false,
    COLLATABLE = false
);

CREATE OR REPLACE FUNCTION sys.varcharvarbinary(sys.VARCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.BBF_VARBINARY)
WITH FUNCTION sys.varcharvarbinary (sys.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varcharvarbinary(pg_catalog.VARCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS sys.BBF_VARBINARY)
WITH FUNCTION sys.varcharvarbinary (pg_catalog.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharvarbinary(pg_catalog.BPCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'bpcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BPCHAR AS sys.BBF_VARBINARY)
WITH FUNCTION sys.bpcharvarbinary (pg_catalog.BPCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharvarbinary(sys.BPCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'bpcharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.BBF_VARBINARY)
WITH FUNCTION sys.bpcharvarbinary (sys.BPCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinarysysvarchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.VARCHAR)
WITH FUNCTION sys.varbinarysysvarchar (sys.BBF_VARBINARY, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryvarchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS pg_catalog.VARCHAR)
WITH FUNCTION sys.varbinaryvarchar (sys.BBF_VARBINARY, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int2varbinary(INT2, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'int2varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT2 AS sys.BBF_VARBINARY)
WITH FUNCTION sys.int2varbinary (INT2, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int4varbinary(INT4, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'int4varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT4 AS sys.BBF_VARBINARY)
WITH FUNCTION sys.int4varbinary (INT4, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int8varbinary(INT8, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'int8varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT8 AS sys.BBF_VARBINARY)
WITH FUNCTION sys.int8varbinary (INT8, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.float4varbinary(REAL, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'float4varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (REAL AS sys.BBF_VARBINARY)
WITH FUNCTION sys.float4varbinary (REAL, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.float8varbinary(DOUBLE PRECISION, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'float8varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (DOUBLE PRECISION AS sys.BBF_VARBINARY)
WITH FUNCTION sys.float8varbinary (DOUBLE PRECISION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryint2(sys.BBF_VARBINARY)
RETURNS INT2
AS 'babelfishpg_common', 'varbinaryint2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY as INT2)
WITH FUNCTION sys.varbinaryint2 (sys.BBF_VARBINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryint4(sys.BBF_VARBINARY)
RETURNS INT4
AS 'babelfishpg_common', 'varbinaryint4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY as INT4)
WITH FUNCTION sys.varbinaryint4 (sys.BBF_VARBINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryint8(sys.BBF_VARBINARY)
RETURNS INT8
AS 'babelfishpg_common', 'varbinaryint8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY as INT8)
WITH FUNCTION sys.varbinaryint8 (sys.BBF_VARBINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryfloat4(sys.BBF_VARBINARY)
RETURNS REAL
AS 'babelfishpg_common', 'varbinaryfloat4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY as REAL)
WITH FUNCTION sys.varbinaryfloat4 (sys.BBF_VARBINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryfloat8(sys.BBF_VARBINARY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_common', 'varbinaryfloat8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY as DOUBLE PRECISION)
WITH FUNCTION sys.varbinaryfloat8 (sys.BBF_VARBINARY) AS ASSIGNMENT;

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.VARBINARY AS sys.BBF_VARBINARY;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.varbinary(sys.VARBINARY, integer, boolean)
RETURNS sys.VARBINARY
AS 'babelfishpg_common', 'varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

SET client_min_messages = 'ERROR';
CREATE CAST (sys.VARBINARY AS sys.VARBINARY)
WITH FUNCTION sys.varbinary (sys.VARBINARY, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';

-- Add support for varbinary and binary with operators
-- Support equals
CREATE FUNCTION sys.varbinary_eq(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_eq,
    COMMUTATOR = =
);

-- Support not equals
CREATE FUNCTION sys.varbinary_neq(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_neq,
    COMMUTATOR = <>
);

-- Support greater than
CREATE FUNCTION sys.varbinary_gt(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.> (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_gt,
    COMMUTATOR = <
);

-- Support greater than equals
CREATE FUNCTION sys.varbinary_geq(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_geq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.>= (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_geq,
    COMMUTATOR = <=
);

-- Support less than
CREATE FUNCTION sys.varbinary_lt(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.< (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_lt,
    COMMUTATOR = >
);

-- Support less than equals
CREATE FUNCTION sys.varbinary_leq(leftarg sys.bbf_varbinary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_leq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<= (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.varbinary_leq,
    COMMUTATOR = >=
);

CREATE FUNCTION sys.bbf_varbinary_cmp(sys.bbf_varbinary, sys.bbf_varbinary)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR CLASS sys.bbf_varbinary_ops
DEFAULT FOR TYPE sys.bbf_varbinary USING btree AS
    OPERATOR 1 < (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR 2 <= (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR 3 = (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR 4 >= (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR 5 > (sys.bbf_varbinary, sys.bbf_varbinary),
    FUNCTION 1 sys.bbf_varbinary_cmp(sys.bbf_varbinary, sys.bbf_varbinary);
-- 21 "sql/babelfishpg_common.in" 2
-- 1 "sql/binary.sql" 1
-- sys.BINARY
CREATE TYPE sys.BBF_BINARY;

CREATE OR REPLACE FUNCTION sys.binaryin(cstring, oid, integer)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'varbinaryin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binaryout(sys.BBF_BINARY)
RETURNS cstring
AS 'babelfishpg_common', 'varbinaryout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binaryrecv(internal, oid, integer)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'varbinaryrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarysend(sys.BBF_BINARY)
RETURNS bytea
AS 'babelfishpg_common', 'varbinarysend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarytypmodin(cstring[])
RETURNS integer
AS 'babelfishpg_common', 'varbinarytypmodin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarytypmodout(integer)
RETURNS cstring
AS 'babelfishpg_common', 'varbinarytypmodout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.BBF_BINARY (
    INPUT = sys.binaryin,
    OUTPUT = sys.binaryout,
    RECEIVE = sys.binaryrecv,
    SEND = sys.binarysend,
    TYPMOD_IN = sys.binarytypmodin,
    TYPMOD_OUT = sys.binarytypmodout,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT = 'int4',
    STORAGE = 'extended',
    CATEGORY = 'U',
    PREFERRED = false,
    COLLATABLE = false
);

-- casting functions for sys.BINARY
CREATE OR REPLACE FUNCTION sys.varcharbinary(sys.VARCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'varcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.BBF_BINARY)
WITH FUNCTION sys.varcharbinary (sys.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varcharbinary(pg_catalog.VARCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'varcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS sys.BBF_BINARY)
WITH FUNCTION sys.varcharbinary (pg_catalog.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharbinary(pg_catalog.BPCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'bpcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BPCHAR AS sys.BBF_BINARY)
WITH FUNCTION sys.bpcharbinary (pg_catalog.BPCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharbinary(sys.BPCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'bpcharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.BBF_BINARY)
WITH FUNCTION sys.bpcharbinary (sys.BPCHAR, integer, boolean) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.binarysysvarchar(sys.BBF_BINARY)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.VARCHAR)
WITH FUNCTION sys.binarysysvarchar (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryvarchar(sys.BBF_BINARY)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS pg_catalog.VARCHAR)
WITH FUNCTION sys.binaryvarchar (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int2binary(INT2, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'int2binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT2 AS sys.BBF_BINARY)
WITH FUNCTION sys.int2binary (INT2, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int4binary(INT4, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'int4binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT4 AS sys.BBF_BINARY)
WITH FUNCTION sys.int4binary (INT4, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int8binary(INT8, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'int8binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT8 AS sys.BBF_BINARY)
WITH FUNCTION sys.int8binary (INT8, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryint2(sys.BBF_BINARY)
RETURNS INT2
AS 'babelfishpg_common', 'binaryint2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY as INT2)
WITH FUNCTION sys.binaryint2 (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryint4(sys.BBF_BINARY)
RETURNS INT4
AS 'babelfishpg_common', 'binaryint4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY as INT4)
WITH FUNCTION sys.binaryint4 (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryint8(sys.BBF_BINARY)
RETURNS INT8
AS 'babelfishpg_common', 'binaryint8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY as INT8)
WITH FUNCTION sys.binaryint8 (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.float4binary(REAL, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'float4binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (REAL AS sys.BBF_BINARY)
WITH FUNCTION sys.float4binary (REAL, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.float8binary(DOUBLE PRECISION, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'float8binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (DOUBLE PRECISION AS sys.BBF_BINARY)
WITH FUNCTION sys.float8binary (DOUBLE PRECISION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryfloat4(sys.BBF_BINARY)
RETURNS REAL
AS 'babelfishpg_common', 'binaryfloat4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY as REAL)
WITH FUNCTION sys.binaryfloat4 (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.binaryfloat8(sys.BBF_BINARY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_common', 'binaryfloat8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY as DOUBLE PRECISION)
WITH FUNCTION sys.binaryfloat8 (sys.BBF_BINARY) AS ASSIGNMENT;

CREATE DOMAIN sys.IMAGE AS sys.BBF_VARBINARY;

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.BINARY AS sys.BBF_BINARY;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.binary(sys.BINARY, integer, boolean)
RETURNS sys.BINARY
AS 'babelfishpg_common', 'binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

SET client_min_messages = 'ERROR';
CREATE CAST (sys.BINARY AS sys.BINARY)
WITH FUNCTION sys.binary (sys.BINARY, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';

CREATE FUNCTION sys.binary_eq(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_eq,
    COMMUTATOR = =
);


CREATE FUNCTION sys.binary_neq(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_neq,
    COMMUTATOR = <>
);

CREATE FUNCTION sys.binary_gt(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.> (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_gt,
    COMMUTATOR = <
);

CREATE FUNCTION sys.binary_geq(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_geq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.>= (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_geq,
    COMMUTATOR = <=
);

CREATE FUNCTION sys.binary_lt(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.< (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_lt,
    COMMUTATOR = >
);

CREATE FUNCTION sys.binary_leq(leftarg sys.bbf_binary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_leq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<= (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.binary_leq,
    COMMUTATOR = >=
);

CREATE FUNCTION sys.bbf_binary_cmp(sys.bbf_binary, sys.bbf_binary)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.bbf_binary_ops
DEFAULT FOR TYPE sys.bbf_binary USING btree AS
    OPERATOR 1 < (sys.bbf_binary, sys.bbf_binary),
    OPERATOR 2 <= (sys.bbf_binary, sys.bbf_binary),
    OPERATOR 3 = (sys.bbf_binary, sys.bbf_binary),
    OPERATOR 4 >= (sys.bbf_binary, sys.bbf_binary),
    OPERATOR 5 > (sys.bbf_binary, sys.bbf_binary),
    FUNCTION 1 sys.bbf_binary_cmp(sys.bbf_binary, sys.bbf_binary);
-- 22 "sql/babelfishpg_common.in" 2
-- 1 "sql/uniqueidentifier.sql" 1
CREATE TYPE sys.UNIQUEIDENTIFIER;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierin(cstring)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'uniqueidentifier_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierout(sys.UNIQUEIDENTIFIER)
RETURNS cstring
AS 'babelfishpg_common', 'uniqueidentifier_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierrecv(internal)
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifiersend(sys.UNIQUEIDENTIFIER)
RETURNS bytea
AS 'uuid_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.UNIQUEIDENTIFIER (
 INPUT = sys.uniqueidentifierin,
 OUTPUT = sys.uniqueidentifierout,
 RECEIVE = sys.uniqueidentifierrecv,
 SEND = sys.uniqueidentifiersend,
 INTERNALLENGTH = 16,
 ALIGNMENT = 'int4',
 STORAGE = 'plain',
 CATEGORY = 'U',
 PREFERRED = false,
 COLLATABLE = false
);

CREATE OR REPLACE FUNCTION sys.newid()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4' -- uuid-ossp was added as dependency
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

-- in tsql, NEWSEQUENTIALID() produces a new unique value
-- greater than a sequence of previous values. Since PG doesn't 
-- have this capability, we will reuse the NEWID() functionality and be
-- aware of the functional shortcoming
CREATE OR REPLACE FUNCTION sys.NEWSEQUENTIALID()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifiereq(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierne(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierlt(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierle(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifiergt(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierge(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.uniqueidentifiereq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.uniqueidentifierne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.uniqueidentifierlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.uniqueidentifierle,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.uniqueidentifiergt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.UNIQUEIDENTIFIER,
    RIGHTARG = sys.UNIQUEIDENTIFIER,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.uniqueidentifierge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE FUNCTION uniqueidentifier_cmp(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS INT4
AS 'uuid_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION uniqueidentifier_hash(sys.UNIQUEIDENTIFIER)
RETURNS INT4
AS 'uuid_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.uniqueidentifier_ops
DEFAULT FOR TYPE sys.UNIQUEIDENTIFIER USING btree AS
    OPERATOR 1 < (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR 2 <= (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR 3 = (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR 4 >= (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR 5 > (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    FUNCTION 1 uniqueidentifier_cmp(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER);

CREATE OPERATOR CLASS sys.uniqueidentifier_ops
DEFAULT FOR TYPE sys.UNIQUEIDENTIFIER USING hash AS
    OPERATOR 1 = (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    FUNCTION 1 uniqueidentifier_hash(sys.UNIQUEIDENTIFIER);

CREATE FUNCTION sys.varchar2uniqueidentifier(pg_catalog.VARCHAR, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varchar2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varchar2uniqueidentifier(pg_catalog.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.varchar2uniqueidentifier(sys.VARCHAR, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varchar2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varchar2uniqueidentifier(sys.VARCHAR, integer, boolean) AS ASSIGNMENT;


CREATE FUNCTION sys.varbinary2uniqueidentifier(sys.bbf_varbinary, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varbinary2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.bbf_varbinary as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varbinary2uniqueidentifier(sys.bbf_varbinary, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.binary2uniqueidentifier(sys.bbf_binary, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varbinary2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.bbf_binary as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.binary2uniqueidentifier(sys.bbf_binary, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.uniqueidentifier2varbinary(sys.UNIQUEIDENTIFIER, integer, boolean)
RETURNS sys.bbf_varbinary
AS 'babelfishpg_common', 'uniqueidentifier2varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER as sys.bbf_varbinary)
WITH FUNCTION sys.uniqueidentifier2varbinary(sys.UNIQUEIDENTIFIER, integer, boolean) AS IMPLICIT;

CREATE FUNCTION sys.uniqueidentifier2binary(sys.UNIQUEIDENTIFIER, integer, boolean)
RETURNS sys.bbf_binary
AS 'babelfishpg_common', 'uniqueidentifier2binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER as sys.bbf_binary)
WITH FUNCTION sys.uniqueidentifier2binary(sys.UNIQUEIDENTIFIER, integer, boolean) AS IMPLICIT;
-- 23 "sql/babelfishpg_common.in" 2
-- 1 "sql/datetime.sql" 1
CREATE TYPE sys.DATETIME;

CREATE OR REPLACE FUNCTION sys.datetimein(cstring)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeout(sys.DATETIME)
RETURNS cstring
AS 'babelfishpg_common', 'datetime_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimerecv(internal)
RETURNS sys.DATETIME
AS 'timestamp_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimesend(sys.DATETIME)
RETURNS bytea
AS 'timestamp_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimetypmodin(cstring[])
RETURNS integer
AS 'timestamptypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimetypmodout(integer)
RETURNS cstring
AS 'timestamptypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATETIME (
 INPUT = sys.datetimein,
 OUTPUT = sys.datetimeout,
 RECEIVE = sys.datetimerecv,
 SEND = sys.datetimesend,
    TYPMOD_IN = sys.datetimetypmodin,
    TYPMOD_OUT = sys.datetimetypmodout,
 INTERNALLENGTH = 8,
 ALIGNMENT = 'double',
 STORAGE = 'plain',
 CATEGORY = 'D',
 PREFERRED = false,
 COLLATABLE = false,
    DEFAULT = '1900-01-01 00:00:00',
    PASSEDBYVALUE
);

CREATE FUNCTION sys.datetimeeq(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimene(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimelt(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimele(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimegt(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimege(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.datetimeeq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.datetimene,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.datetimelt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.datetimele,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.datetimegt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.DATETIME,
    RIGHTARG = sys.DATETIME,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.datetimege,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

-- datetime <-> int operators for datetime-int +/- arithmetic
CREATE FUNCTION sys.datetimeplint4(sys.DATETIME, INT4)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4pldatetime(INT4, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'int4_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimemiint4(sys.DATETIME, INT4)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4midatetime(INT4, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'int4_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = sys.DATETIME,
    RIGHTARG = INT4,
    PROCEDURE = sys.datetimeplint4
);

CREATE OPERATOR sys.+ (
    LEFTARG = INT4,
    RIGHTARG = sys.DATETIME,
    PROCEDURE = sys.int4pldatetime
);

CREATE OPERATOR sys.- (
    LEFTARG = sys.DATETIME,
    RIGHTARG = INT4,
    PROCEDURE = sys.datetimemiint4
);

CREATE OPERATOR sys.- (
    LEFTARG = INT4,
    RIGHTARG = sys.DATETIME,
    PROCEDURE = sys.int4midatetime
);



CREATE FUNCTION sys.datetimeplfloat8(sys.DATETIME, float8)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = sys.DATETIME,
    RIGHTARG = float8,
    PROCEDURE = sys.datetimeplfloat8
);

CREATE FUNCTION sys.datetimemifloat8(sys.DATETIME, float8)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG = sys.DATETIME,
    RIGHTARG = float8,
    PROCEDURE = sys.datetimemifloat8
);

CREATE FUNCTION sys.float8pldatetime(float8, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'float8_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = float8,
    RIGHTARG = sys.DATETIME,
    PROCEDURE = sys.float8pldatetime
);

CREATE FUNCTION sys.float8midatetime(float8, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'float8_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG = float8,
    RIGHTARG = sys.DATETIME,
    PROCEDURE = sys.float8midatetime
);




CREATE FUNCTION datetime_cmp(sys.DATETIME, sys.DATETIME)
RETURNS INT4
AS 'timestamp_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION datetime_hash(sys.DATETIME)
RETURNS INT4
AS 'timestamp_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.datetime_ops
DEFAULT FOR TYPE sys.DATETIME USING btree AS
    OPERATOR 1 < (sys.DATETIME, sys.DATETIME),
    OPERATOR 2 <= (sys.DATETIME, sys.DATETIME),
    OPERATOR 3 = (sys.DATETIME, sys.DATETIME),
    OPERATOR 4 >= (sys.DATETIME, sys.DATETIME),
    OPERATOR 5 > (sys.DATETIME, sys.DATETIME),
    FUNCTION 1 datetime_cmp(sys.DATETIME, sys.DATETIME);

CREATE OPERATOR CLASS sys.datetime_ops
DEFAULT FOR TYPE sys.DATETIME USING hash AS
    OPERATOR 1 = (sys.DATETIME, sys.DATETIME),
    FUNCTION 1 datetime_hash(sys.DATETIME);

-- cast TO datetime
CREATE OR REPLACE FUNCTION sys.timestamp2datetime(TIMESTAMP)
RETURNS DATETIME
AS 'babelfishpg_common', 'timestamp_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS DATETIME)
WITH FUNCTION sys.timestamp2datetime(TIMESTAMP) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.timestamptz2datetime(TIMESTAMPTZ)
RETURNS DATETIME
AS 'babelfishpg_common', 'timestamptz_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMPTZ AS DATETIME)
WITH FUNCTION sys.timestamptz2datetime (TIMESTAMPTZ) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.date2datetime(DATE)
RETURNS DATETIME
AS 'babelfishpg_common', 'date_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS DATETIME)
WITH FUNCTION sys.date2datetime (DATE) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.time2datetime(TIME)
RETURNS DATETIME
AS 'babelfishpg_common', 'time_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIME AS DATETIME)
WITH FUNCTION sys.time2datetime (TIME) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.varchar2datetime(sys.VARCHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'varchar_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS DATETIME)
WITH FUNCTION sys.varchar2datetime (sys.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varchar2datetime(pg_catalog.VARCHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'varchar_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS DATETIME)
WITH FUNCTION sys.varchar2datetime (pg_catalog.VARCHAR) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.char2datetime(CHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'char_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS DATETIME)
WITH FUNCTION sys.char2datetime (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2datetime(sys.BPCHAR)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'char_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.DATETIME)
WITH FUNCTION sys.bpchar2datetime (sys.BPCHAR) AS ASSIGNMENT;

-- cast FROM datetime
CREATE CAST (DATETIME AS TIMESTAMP)
WITHOUT FUNCTION AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime2timestamptz(DATETIME)
RETURNS TIMESTAMPTZ
AS 'timestamp_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS TIMESTAMPTZ)
WITH FUNCTION sys.datetime2timestamptz (DATETIME) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime2date(DATETIME)
RETURNS DATE
AS 'timestamp_date'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS DATE)
WITH FUNCTION sys.datetime2date (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2time(DATETIME)
RETURNS TIME
AS 'timestamp_time'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS TIME)
WITH FUNCTION sys.datetime2time (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2sysvarchar(DATETIME)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'datetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS sys.VARCHAR)
WITH FUNCTION sys.datetime2sysvarchar (DATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime2varchar(DATETIME)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'datetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS pg_catalog.VARCHAR)
WITH FUNCTION sys.datetime2varchar (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2char(DATETIME)
RETURNS CHAR
AS 'babelfishpg_common', 'datetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS CHAR)
WITH FUNCTION sys.datetime2char (DATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime2bpchar(sys.DATETIME)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'datetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME AS sys.BPCHAR)
WITH FUNCTION sys.datetime2bpchar (sys.DATETIME) AS ASSIGNMENT;
-- 24 "sql/babelfishpg_common.in" 2
-- 1 "sql/datetime2.sql" 1
CREATE TYPE sys.DATETIME2;

CREATE OR REPLACE FUNCTION sys.datetime2in(cstring)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'datetime2_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2out(sys.DATETIME2)
RETURNS cstring
AS 'timestamp_out'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2recv(internal)
RETURNS sys.DATETIME2
AS 'timestamp_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2send(sys.DATETIME2)
RETURNS bytea
AS 'timestamp_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2typmodin(cstring[])
RETURNS integer
AS 'timestamptypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2typmodout(integer)
RETURNS cstring
AS 'timestamptypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATETIME2 (
 INPUT = sys.datetime2in,
 OUTPUT = sys.datetime2out,
 RECEIVE = sys.datetime2recv,
 SEND = sys.datetime2send,
    TYPMOD_IN = sys.datetime2typmodin,
    TYPMOD_OUT = sys.datetime2typmodout,
 INTERNALLENGTH = 8,
 ALIGNMENT = 'double',
 STORAGE = 'plain',
 CATEGORY = 'D',
 PREFERRED = false,
 COLLATABLE = false,
    DEFAULT = '1900-01-01 00:00:00',
    PASSEDBYVALUE
);

CREATE FUNCTION sys.datetime2eq(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime2ne(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime2lt(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime2le(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime2gt(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime2ge(sys.DATETIME2, sys.DATETIME2)
RETURNS bool
AS 'timestamp_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.datetime2eq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.datetime2ne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.datetime2lt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.datetime2le,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.datetime2gt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.DATETIME2,
    RIGHTARG = sys.DATETIME2,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.datetime2ge,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE FUNCTION datetime2_cmp(sys.DATETIME2, sys.DATETIME2)
RETURNS INT4
AS 'timestamp_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION datetime2_hash(sys.DATETIME2)
RETURNS INT4
AS 'timestamp_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.datetime2_ops
DEFAULT FOR TYPE sys.DATETIME2 USING btree AS
    OPERATOR 1 < (sys.DATETIME2, sys.DATETIME2),
    OPERATOR 2 <= (sys.DATETIME2, sys.DATETIME2),
    OPERATOR 3 = (sys.DATETIME2, sys.DATETIME2),
    OPERATOR 4 >= (sys.DATETIME2, sys.DATETIME2),
    OPERATOR 5 > (sys.DATETIME2, sys.DATETIME2),
    FUNCTION 1 datetime2_cmp(sys.DATETIME2, sys.DATETIME2);

CREATE OPERATOR CLASS sys.datetime2_ops
DEFAULT FOR TYPE sys.DATETIME2 USING hash AS
    OPERATOR 1 = (sys.DATETIME2, sys.DATETIME2),
    FUNCTION 1 datetime2_hash(sys.DATETIME2);

-- cast TO datetime2
CREATE OR REPLACE FUNCTION sys.timestamp2datetime2(TIMESTAMP)
RETURNS DATETIME2
AS 'babelfishpg_common', 'timestamp_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS DATETIME2)
WITH FUNCTION sys.timestamp2datetime2(TIMESTAMP) AS ASSIGNMENT;
-- CREATE CAST (TIMESTAMP AS DATETIME2)
-- WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.timestamptz2datetime2(TIMESTAMPTZ)
RETURNS DATETIME2
AS 'babelfishpg_common', 'timestamptz_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMPTZ AS DATETIME2)
WITH FUNCTION sys.timestamptz2datetime2 (TIMESTAMPTZ) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.date2datetime2(DATE)
RETURNS DATETIME2
AS 'babelfishpg_common', 'date_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS DATETIME2)
WITH FUNCTION sys.date2datetime2 (DATE) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.time2datetime2(TIME)
RETURNS DATETIME2
AS 'babelfishpg_common', 'time_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIME AS DATETIME2)
WITH FUNCTION sys.time2datetime2 (TIME) AS IMPLICIT;


CREATE CAST (DATETIME AS DATETIME2)
WITHOUT FUNCTION AS IMPLICIT;


-- BABEL-1465 CAST from VARCHAR/NVARCHAR/CHAR/NCHAR to datetime2 is VOLATILE
CREATE OR REPLACE FUNCTION sys.varchar2datetime2(sys.VARCHAR)
RETURNS DATETIME2
AS 'babelfishpg_common', 'varchar_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS DATETIME2)
WITH FUNCTION sys.varchar2datetime2 (sys.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varchar2datetime2(pg_catalog.VARCHAR)
RETURNS DATETIME2
AS 'babelfishpg_common', 'varchar_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS DATETIME2)
WITH FUNCTION sys.varchar2datetime2 (pg_catalog.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.char2datetime2(CHAR)
RETURNS DATETIME2
AS 'babelfishpg_common', 'char_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS DATETIME2)
WITH FUNCTION sys.char2datetime2 (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2datetime2(sys.BPCHAR)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'char_datetime2'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.DATETIME2)
WITH FUNCTION sys.bpchar2datetime2 (sys.BPCHAR) AS ASSIGNMENT;

-- cast FROM datetime2
CREATE CAST (DATETIME2 AS TIMESTAMP)
WITHOUT FUNCTION AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime22datetime(DATETIME2)
RETURNS DATETIME
AS 'babelfishpg_common', 'timestamp_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS DATETIME)
WITH FUNCTION sys.datetime22datetime(DATETIME2) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime22timestamptz(DATETIME2)
RETURNS TIMESTAMPTZ
AS 'timestamp_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS TIMESTAMPTZ)
WITH FUNCTION sys.datetime22timestamptz (DATETIME2) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime22date(DATETIME2)
RETURNS DATE
AS 'timestamp_date'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS DATE)
WITH FUNCTION sys.datetime22date (DATETIME2) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime22time(DATETIME2)
RETURNS TIME
AS 'timestamp_time'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS TIME)
WITH FUNCTION sys.datetime22time (DATETIME2) AS ASSIGNMENT;


CREATE FUNCTION sys.datetime2scale(sys.DATETIME2, INT4)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'datetime2_scale'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME2 AS sys.DATETIME2)
WITH FUNCTION datetime2scale (sys.DATETIME2, INT4) AS ASSIGNMENT;


-- BABEL-1465 CAST from datetime2 to VARCHAR/NVARCHAR/CHAR/NCHAR is VOLATILE
CREATE OR REPLACE FUNCTION sys.datetime22sysvarchar(DATETIME2)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'datetime2_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS sys.VARCHAR)
WITH FUNCTION sys.datetime22sysvarchar (DATETIME2) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime22varchar(DATETIME2)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'datetime2_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS pg_catalog.VARCHAR)
WITH FUNCTION sys.datetime22varchar (DATETIME2) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime22char(DATETIME2)
RETURNS CHAR
AS 'babelfishpg_common', 'datetime2_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS CHAR)
WITH FUNCTION sys.datetime22char (DATETIME2) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime22bpchar(sys.DATETIME2)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'datetime2_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME2 AS sys.BPCHAR)
WITH FUNCTION sys.datetime22bpchar (sys.DATETIME2) AS ASSIGNMENT;
-- 25 "sql/babelfishpg_common.in" 2
-- 1 "sql/smalldatetime.sql" 1
CREATE TYPE sys.SMALLDATETIME;

CREATE OR REPLACE FUNCTION sys.smalldatetimein(cstring)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'smalldatetime_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimeout(sys.SMALLDATETIME)
RETURNS cstring
AS 'timestamp_out'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimerecv(internal)
RETURNS sys.SMALLDATETIME
AS 'timestamp_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimesend(sys.SMALLDATETIME)
RETURNS bytea
AS 'timestamp_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalltypmodin(cstring[])
RETURNS integer
AS 'timestamptypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalltypmodout(integer)
RETURNS cstring
AS 'timestamptypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.SMALLDATETIME (
 INPUT = sys.smalldatetimein,
 OUTPUT = sys.smalldatetimeout,
 RECEIVE = sys.smalldatetimerecv,
 SEND = sys.smalldatetimesend,
    TYPMOD_IN = sys.smalltypmodin,
    TYPMOD_OUT = sys.smalltypmodout,
 INTERNALLENGTH = 8,
 ALIGNMENT = 'double',
 STORAGE = 'plain',
 CATEGORY = 'D',
 PREFERRED = false,
 COLLATABLE = false,
    DEFAULT = '1900-01-01 00:00',
    PASSEDBYVALUE
);

CREATE FUNCTION sys.smalldatetimeeq(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimene(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimelt(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimele(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimegt(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimege(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.smalldatetimeeq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.smalldatetimene,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.smalldatetimelt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.smalldatetimele,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.smalldatetimegt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.smalldatetimege,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

-- smalldate vs pg_catalog.date
CREATE FUNCTION sys.smalldatetime_eq_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_eq_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_ne_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_ne_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_lt_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_lt_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_le_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_le_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_gt_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_gt_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_ge_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_ge_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = smalldatetime_eq_date,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = smalldatetime_ne_date,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = smalldatetime_lt_date,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = smalldatetime_le_date,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = smalldatetime_gt_date,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.SMALLDATETIME,
    RIGHTARG = pg_catalog.date,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = smalldatetime_ge_date,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

-- pg_catalog.date vs smalldate
CREATE FUNCTION sys.date_eq_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_eq_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_ne_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_ne_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_lt_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_lt_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_le_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_le_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_gt_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_gt_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_ge_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_ge_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = date_eq_smalldatetime,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = date_ne_smalldatetime,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = date_lt_smalldatetime,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = date_le_smalldatetime,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = date_gt_smalldatetime,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = pg_catalog.date,
    RIGHTARG = sys.SMALLDATETIME,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = date_ge_smalldatetime,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);


-- smalldatetime <-> int/float operators for smalldatetime-int +/- arithmetic
CREATE FUNCTION sys.smalldatetimeplint4(sys.smalldatetime, INT4)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_pl_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4plsmalldatetime(INT4, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'int4_pl_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimemiint4(sys.smalldatetime, INT4)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_mi_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4mismalldatetime(INT4, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'int4_mi_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = sys.smalldatetime,
    RIGHTARG = INT4,
    PROCEDURE = sys.smalldatetimeplint4
);

CREATE OPERATOR sys.+ (
    LEFTARG = INT4,
    RIGHTARG = sys.smalldatetime,
    PROCEDURE = sys.int4plsmalldatetime
);

CREATE OPERATOR sys.- (
    LEFTARG = sys.smalldatetime,
    RIGHTARG = INT4,
    PROCEDURE = sys.smalldatetimemiint4
);

CREATE OPERATOR sys.- (
    LEFTARG = INT4,
    RIGHTARG = sys.smalldatetime,
    PROCEDURE = sys.int4mismalldatetime
);



CREATE FUNCTION sys.smalldatetimeplfloat8(sys.smalldatetime, float8)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_pl_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = sys.smalldatetime,
    RIGHTARG = float8,
    PROCEDURE = sys.smalldatetimeplfloat8
);

CREATE FUNCTION sys.smalldatetimemifloat8(sys.smalldatetime, float8)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_mi_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG = sys.smalldatetime,
    RIGHTARG = float8,
    PROCEDURE = sys.smalldatetimemifloat8
);

CREATE FUNCTION sys.float8plsmalldatetime(float8, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'float8_pl_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG = float8,
    RIGHTARG = sys.smalldatetime,
    PROCEDURE = sys.float8plsmalldatetime
);

CREATE FUNCTION sys.float8mismalldatetime(float8, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'float8_mi_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG = float8,
    RIGHTARG = sys.smalldatetime,
    PROCEDURE = sys.float8mismalldatetime
);



CREATE FUNCTION smalldatetime_cmp(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS INT4
AS 'timestamp_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION smalldatetime_hash(sys.SMALLDATETIME)
RETURNS INT4
AS 'timestamp_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.smalldatetime_ops
DEFAULT FOR TYPE sys.SMALLDATETIME USING btree AS
    OPERATOR 1 < (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR 2 <= (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR 3 = (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR 4 >= (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR 5 > (sys.SMALLDATETIME, sys.SMALLDATETIME),
    FUNCTION 1 smalldatetime_cmp(sys.SMALLDATETIME, sys.SMALLDATETIME);

CREATE OPERATOR CLASS sys.smalldatetime_ops
DEFAULT FOR TYPE sys.SMALLDATETIME USING hash AS
    OPERATOR 1 = (sys.SMALLDATETIME, sys.SMALLDATETIME),
    FUNCTION 1 smalldatetime_hash(sys.SMALLDATETIME);

CREATE OR REPLACE FUNCTION sys.timestamp2smalldatetime(TIMESTAMP)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2smalldatetime(DATETIME)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime22smalldatetime(DATETIME2)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date2smalldatetime(DATE)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'date_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2date(SMALLDATETIME)
RETURNS DATE
AS 'timestamp_date'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.timestamptz2smalldatetime(TIMESTAMPTZ)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamptz_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2timestamptz(SMALLDATETIME)
RETURNS TIMESTAMPTZ
AS 'timestamp_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.time2smalldatetime(TIME)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'time_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2time(SMALLDATETIME)
RETURNS TIME
AS 'timestamp_time'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS SMALLDATETIME)
WITH FUNCTION sys.timestamp2smalldatetime(TIMESTAMP) AS ASSIGNMENT;

CREATE CAST (DATETIME AS SMALLDATETIME)
WITH FUNCTION sys.datetime2smalldatetime(DATETIME) AS ASSIGNMENT;

CREATE CAST (DATETIME2 AS SMALLDATETIME)
WITH FUNCTION sys.datetime22smalldatetime(DATETIME2) AS ASSIGNMENT;

CREATE CAST (SMALLDATETIME AS DATETIME)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS DATETIME2)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIMESTAMP)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (TIMESTAMPTZ AS SMALLDATETIME)
WITH FUNCTION sys.timestamptz2smalldatetime (TIMESTAMPTZ) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIMESTAMPTZ)
WITH FUNCTION sys.smalldatetime2timestamptz (SMALLDATETIME) AS ASSIGNMENT;

CREATE CAST (DATE AS SMALLDATETIME)
WITH FUNCTION sys.date2smalldatetime (DATE) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS DATE)
WITH FUNCTION sys.smalldatetime2date (SMALLDATETIME) AS ASSIGNMENT;

CREATE CAST (TIME AS SMALLDATETIME)
WITH FUNCTION sys.time2smalldatetime (TIME) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIME)
WITH FUNCTION sys.smalldatetime2time (SMALLDATETIME) AS ASSIGNMENT;

-- BABEL-1465 CAST from VARCHAR/NVARCHAR/CHAR/NCHAR to smalldatetime is VOLATILE
CREATE OR REPLACE FUNCTION sys.varchar2smalldatetime(sys.VARCHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'varchar_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS SMALLDATETIME)
WITH FUNCTION sys.varchar2smalldatetime (sys.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varchar2smalldatetime(pg_catalog.VARCHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'varchar_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS SMALLDATETIME)
WITH FUNCTION sys.varchar2smalldatetime (pg_catalog.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.char2smalldatetime(CHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'char_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS SMALLDATETIME)
WITH FUNCTION sys.char2smalldatetime (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2smalldatetime(sys.BPCHAR)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'char_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.SMALLDATETIME)
WITH FUNCTION sys.bpchar2smalldatetime (sys.BPCHAR) AS ASSIGNMENT;

-- BABEL-1465 CAST from smalldatetime to VARCHAR/NVARCHAR/CHAR/NCHAR is VOLATILE
CREATE OR REPLACE FUNCTION sys.smalldatetime2sysvarchar(SMALLDATETIME)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'smalldatetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS sys.VARCHAR)
WITH FUNCTION sys.smalldatetime2sysvarchar (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2varchar(SMALLDATETIME)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'smalldatetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS pg_catalog.VARCHAR)
WITH FUNCTION sys.smalldatetime2varchar (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2char(SMALLDATETIME)
RETURNS CHAR
AS 'babelfishpg_common', 'smalldatetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS CHAR)
WITH FUNCTION sys.smalldatetime2char (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2bpchar(sys.SMALLDATETIME)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'smalldatetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SMALLDATETIME AS sys.BPCHAR)
WITH FUNCTION sys.smalldatetime2bpchar (sys.SMALLDATETIME) AS ASSIGNMENT;
-- 26 "sql/babelfishpg_common.in" 2
-- 1 "sql/datetimeoffset.sql" 1
CREATE TYPE sys.DATETIMEOFFSET;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetin(cstring)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetout(sys.DATETIMEOFFSET)
RETURNS cstring
AS 'babelfishpg_common', 'datetimeoffset_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetrecv(internal)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_recv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetsend(sys.DATETIMEOFFSET)
RETURNS bytea
AS 'babelfishpg_common', 'datetimeoffset_send'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeofftypmodin(cstring[])
RETURNS integer
AS 'timestamptztypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeofftypmodout(integer)
RETURNS cstring
AS 'timestamptztypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATETIMEOFFSET (
 INPUT = sys.datetimeoffsetin,
 OUTPUT = sys.datetimeoffsetout,
 RECEIVE = sys.datetimeoffsetrecv,
 SEND = sys.datetimeoffsetsend,
    TYPMOD_IN = sys.datetimeofftypmodin,
    TYPMOD_OUT = sys.datetimeofftypmodout,
 INTERNALLENGTH = 10,
 ALIGNMENT = 'double',
 STORAGE = 'plain',
 CATEGORY = 'D',
 PREFERRED = false,
    DEFAULT = '1900-01-01 00:00+0'
);

CREATE FUNCTION sys.datetimeoffseteq(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetne(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetlt(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetle(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetgt(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetge(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetplinterval(sys.DATETIMEOFFSET, INTERVAL)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_pl_interval'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.intervalpldatetimeoffset(INTERVAL, sys.DATETIMEOFFSET)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'interval_pl_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetmiinterval(sys.DATETIMEOFFSET, INTERVAL)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_mi_interval'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetmi(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS INTERVAL
AS 'babelfishpg_common', 'datetimeoffset_mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.datetimeoffseteq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.datetimeoffsetne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.datetimeoffsetlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.datetimeoffsetle,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.datetimeoffsetgt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.datetimeoffsetge,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = interval,
    PROCEDURE = sys.datetimeoffsetplinterval
);

CREATE OPERATOR sys.+ (
    LEFTARG = interval,
    RIGHTARG = sys.DATETIMEOFFSET,
    PROCEDURE = sys.intervalpldatetimeoffset
);

CREATE OPERATOR sys.- (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = interval,
    PROCEDURE = sys.datetimeoffsetmiinterval
);

CREATE OPERATOR sys.- (
    LEFTARG = sys.DATETIMEOFFSET,
    RIGHTARG = sys.DATETIMEOFFSET,
    PROCEDURE = sys.datetimeoffsetmi
);

CREATE FUNCTION datetimeoffset_cmp(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS INT4
AS 'babelfishpg_common', 'datetimeoffset_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION datetimeoffset_hash(sys.DATETIMEOFFSET)
RETURNS INT4
AS 'babelfishpg_common', 'datetimeoffset_hash'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.datetimeoffset_ops
DEFAULT FOR TYPE sys.DATETIMEOFFSET USING btree AS
    OPERATOR 1 < (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR 2 <= (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR 3 = (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR 4 >= (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR 5 > (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    FUNCTION 1 datetimeoffset_cmp(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET);

CREATE OPERATOR CLASS sys.datetimeoffset_ops
DEFAULT FOR TYPE sys.DATETIMEOFFSET USING hash AS
    OPERATOR 1 = (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    FUNCTION 1 datetimeoffset_hash(sys.DATETIMEOFFSET);

-- Casts
CREATE FUNCTION sys.datetimeoffsetscale(sys.DATETIMEOFFSET, INT4)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_scale'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.timestamp2datetimeoffset(TIMESTAMP)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'timestamp_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2timestamp(sys.DATETIMEOFFSET)
RETURNS TIMESTAMP
AS 'babelfishpg_common', 'datetimeoffset_timestamp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date2datetimeoffset(DATE)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'date_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2date(sys.DATETIMEOFFSET)
RETURNS DATE
AS 'babelfishpg_common', 'datetimeoffset_date'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.time2datetimeoffset(TIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'time_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2time(sys.DATETIMEOFFSET)
RETURNS TIME
AS 'babelfishpg_common', 'datetimeoffset_time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2datetimeoffset(sys.SMALLDATETIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'smalldatetime_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2smalldatetime(sys.DATETIMEOFFSET)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'datetimeoffset_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2datetimeoffset(sys.DATETIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetime_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2datetime(sys.DATETIMEOFFSET)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetimeoffset_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime22datetimeoffset(sys.DATETIME2)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetime2_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2datetime2(sys.DATETIMEOFFSET)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'datetimeoffset_datetime2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIMEOFFSET)
WITH FUNCTION datetimeoffsetscale (sys.DATETIMEOFFSET, INT4) AS ASSIGNMENT;

CREATE CAST (TIMESTAMP AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.timestamp2datetimeoffset(TIMESTAMP) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS TIMESTAMP)
WITH FUNCTION sys.datetimeoffset2timestamp(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (DATE AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.date2datetimeoffset(DATE) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS DATE)
WITH FUNCTION sys.datetimeoffset2date(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (TIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.time2datetimeoffset(TIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS TIME)
WITH FUNCTION sys.datetimeoffset2time(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.SMALLDATETIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.smalldatetime2datetimeoffset(sys.SMALLDATETIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.SMALLDATETIME)
WITH FUNCTION sys.datetimeoffset2smalldatetime(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.DATETIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.datetime2datetimeoffset(sys.DATETIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIME)
WITH FUNCTION sys.datetimeoffset2datetime(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.DATETIME2 AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.datetime22datetimeoffset(sys.DATETIME2) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIME2)
WITH FUNCTION sys.datetimeoffset2datetime2(sys.DATETIMEOFFSET) AS ASSIGNMENT;
-- 27 "sql/babelfishpg_common.in" 2
-- 1 "sql/sqlvariant.sql" 1
CREATE TYPE sys.SQL_VARIANT;

CREATE OR REPLACE FUNCTION sys.sqlvariantin(cstring, oid, integer)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sqlvariantin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantout(sys.SQL_VARIANT)
RETURNS cstring
AS 'babelfishpg_common', 'sqlvariantout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantrecv(internal, oid, integer)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sqlvariantrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariantsend(sys.SQL_VARIANT)
RETURNS bytea
AS 'babelfishpg_common', 'sqlvariantsend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.SQL_VARIANT (
    INPUT = sys.sqlvariantin,
    OUTPUT = sys.sqlvariantout,
    RECEIVE = sys.sqlvariantrecv,
    SEND = sys.sqlvariantsend,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT = 'int4',
    STORAGE = 'extended',
    CATEGORY = 'U',
    PREFERRED = false,
    COLLATABLE = true
);

-- DATALENGTH function for SQL_VARIANT
CREATE OR REPLACE FUNCTION sys.datalength(sys.SQL_VARIANT)
RETURNS integer
AS 'babelfishpg_common', 'datalength_sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- CAST FUNCTIONS to SQL_VARIANT

-- cast functions from domain types are overloaded such that we support casts both in pg and tsql:
-- money/smallmoney, smallint/tinyint, varchar/nvarchar, char/nchar
-- in pg, we will have minimal support of casts since domains are not distinguished
-- in tsql, we will allow domain casts in coerce.sql such that exact type info are saved
-- this is required for sql_variant since we may call sql_variant_property() to retrieve base type

CREATE OR REPLACE FUNCTION sys.datetime_sqlvariant(sys.DATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetime2sqlvariant'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetime_sqlvariant (sys.DATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.datetime2_sqlvariant(sys.DATETIME2)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetime22sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME2 AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetime2_sqlvariant (sys.DATETIME2) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.datetimeoffset_sqlvariant(sys.DATETIMEOFFSET)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'datetimeoffset2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIMEOFFSET AS sys.SQL_VARIANT)
WITH FUNCTION sys.datetimeoffset_sqlvariant (sys.DATETIMEOFFSET) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smalldatetime_sqlvariant(sys.SMALLDATETIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smalldatetime2sqlvariant'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SMALLDATETIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.smalldatetime_sqlvariant (sys.SMALLDATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.date_sqlvariant(DATE)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'date2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS sys.SQL_VARIANT)
WITH FUNCTION sys.date_sqlvariant (DATE) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.time_sqlvariant(TIME)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'time2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (TIME AS sys.SQL_VARIANT)
WITH FUNCTION sys.time_sqlvariant (TIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.float_sqlvariant(FLOAT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'float2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT AS sys.SQL_VARIANT)
WITH FUNCTION sys.float_sqlvariant (FLOAT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.real_sqlvariant(REAL)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'real2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (REAL AS sys.SQL_VARIANT)
WITH FUNCTION sys.real_sqlvariant (REAL) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.numeric_sqlvariant(NUMERIC)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'numeric2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.SQL_VARIANT)
WITH FUNCTION sys.numeric_sqlvariant (NUMERIC) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.money_sqlvariant(FIXEDDECIMAL)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'money2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.money_sqlvariant(sys.money)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'money2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smallmoney_sqlvariant(sys.smallmoney)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallmoney2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS sys.SQL_VARIANT)
WITH FUNCTION sys.money_sqlvariant (FIXEDDECIMAL) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bigint_sqlvariant(BIGINT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bigint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (BIGINT AS sys.SQL_VARIANT)
WITH FUNCTION sys.bigint_sqlvariant (BIGINT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.int_sqlvariant(INT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'int2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT AS sys.SQL_VARIANT)
WITH FUNCTION sys.int_sqlvariant (INT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smallint_sqlvariant(SMALLINT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smallint_sqlvariant(smallint)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'smallint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tinyint_sqlvariant(sys.tinyint)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'tinyint2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (SMALLINT AS sys.SQL_VARIANT)
WITH FUNCTION sys.smallint_sqlvariant (SMALLINT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bit_sqlvariant(sys.BIT)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bit2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS sys.SQL_VARIANT)
WITH FUNCTION sys.bit_sqlvariant (sys.BIT) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar_sqlvariant(sys.varchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'varchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarchar_sqlvariant(sys.nvarchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'nvarchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.varchar_sqlvariant (sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar_sqlvariant(pg_catalog.varchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'varchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.varchar_sqlvariant (pg_catalog.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.char_sqlvariant(CHAR)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'char2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar_sqlvariant(sys.nchar)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'nchar2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.char_sqlvariant (CHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.char_sqlvariant(sys.BPCHAR)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'char2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.SQL_VARIANT)
WITH FUNCTION sys.char_sqlvariant (sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bbfvarbinary_sqlvariant(sys.BBF_VARBINARY)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bbfvarbinary2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.SQL_VARIANT)
WITH FUNCTION sys.bbfvarbinary_sqlvariant (sys.BBF_VARBINARY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bbfbinary_sqlvariant(sys.BBF_BINARY)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'bbfbinary2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.SQL_VARIANT)
WITH FUNCTION sys.bbfbinary_sqlvariant (sys.BBF_BINARY) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.uniqueidentifier_sqlvariant(sys.UNIQUEIDENTIFIER)
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'uniqueidentifier2sqlvariant'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER AS sys.SQL_VARIANT)
WITH FUNCTION sys.uniqueidentifier_sqlvariant (sys.UNIQUEIDENTIFIER) AS IMPLICIT;

-- CAST functions from SQL_VARIANT

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime(sys.SQL_VARIANT)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'sqlvariant2timestamp'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIME)
WITH FUNCTION sys.sqlvariant_datetime (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetime2(sys.SQL_VARIANT)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'sqlvariant2timestamp'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIME2)
WITH FUNCTION sys.sqlvariant_datetime2 (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_datetimeoffset(sys.SQL_VARIANT)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'sqlvariant2datetimeoffset'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.sqlvariant_datetimeoffset (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smalldatetime(sys.SQL_VARIANT)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'sqlvariant2timestamp'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.SMALLDATETIME)
WITH FUNCTION sys.sqlvariant_smalldatetime (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_date(sys.SQL_VARIANT)
RETURNS DATE
AS 'babelfishpg_common', 'sqlvariant2date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS DATE)
WITH FUNCTION sys.sqlvariant_date (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_time(sys.SQL_VARIANT)
RETURNS TIME
AS 'babelfishpg_common', 'sqlvariant2time'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS TIME)
WITH FUNCTION sys.sqlvariant_time (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_float(sys.SQL_VARIANT)
RETURNS FLOAT
AS 'babelfishpg_common', 'sqlvariant2float'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS FLOAT)
WITH FUNCTION sys.sqlvariant_float (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_real(sys.SQL_VARIANT)
RETURNS REAL
AS 'babelfishpg_common', 'sqlvariant2real'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS REAL)
WITH FUNCTION sys.sqlvariant_real (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_numeric(sys.SQL_VARIANT)
RETURNS NUMERIC
AS 'babelfishpg_common', 'sqlvariant2numeric'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS NUMERIC)
WITH FUNCTION sys.sqlvariant_numeric (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_money(sys.SQL_VARIANT)
RETURNS sys.MONEY
AS 'babelfishpg_common', 'sqlvariant2fixeddecimal'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smallmoney(sys.SQL_VARIANT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'sqlvariant2fixeddecimal'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS FIXEDDECIMAL)
WITH FUNCTION sys.sqlvariant_money (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bigint(sys.SQL_VARIANT)
RETURNS BIGINT
AS 'babelfishpg_common', 'sqlvariant2bigint'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS BIGINT)
WITH FUNCTION sys.sqlvariant_bigint (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_int(sys.SQL_VARIANT)
RETURNS INT
AS 'babelfishpg_common', 'sqlvariant2int'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS INT)
WITH FUNCTION sys.sqlvariant_int (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_smallint(sys.SQL_VARIANT)
RETURNS SMALLINT
AS 'babelfishpg_common', 'sqlvariant2smallint'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_tinyint(sys.SQL_VARIANT)
RETURNS sys.TINYINT
AS 'babelfishpg_common', 'sqlvariant2smallint'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS SMALLINT)
WITH FUNCTION sys.sqlvariant_smallint (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bit(sys.SQL_VARIANT)
RETURNS sys.BIT
AS 'babelfishpg_common', 'sqlvariant2bit'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BIT)
WITH FUNCTION sys.sqlvariant_bit (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_sysvarchar(sys.SQL_VARIANT)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.VARCHAR)
WITH FUNCTION sys.sqlvariant_sysvarchar (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_varchar(sys.SQL_VARIANT)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS pg_catalog.VARCHAR)
WITH FUNCTION sys.sqlvariant_varchar (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_nvarchar(sys.SQL_VARIANT)
RETURNS sys.NVARCHAR
AS 'babelfishpg_common', 'sqlvariant2varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_char(sys.SQL_VARIANT)
RETURNS CHAR
AS 'babelfishpg_common', 'sqlvariant2char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.sqlvariant_nchar(sys.SQL_VARIANT)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'sqlvariant2char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS CHAR)
WITH FUNCTION sys.sqlvariant_char (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bbfvarbinary(sys.SQL_VARIANT)
RETURNS sys.VARBINARY
AS 'babelfishpg_common', 'sqlvariant2bbfvarbinary'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BBF_VARBINARY)
WITH FUNCTION sys.sqlvariant_bbfvarbinary (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_bbfbinary(sys.SQL_VARIANT)
RETURNS sys.BINARY
AS 'babelfishpg_common', 'sqlvariant2bbfbinary'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.BBF_BINARY)
WITH FUNCTION sys.sqlvariant_bbfbinary (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.sqlvariant_uniqueidentifier(sys.SQL_VARIANT)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'sqlvariant2uniqueidentifier'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SQL_VARIANT AS sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.sqlvariant_uniqueidentifier (sys.SQL_VARIANT) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.SQL_VARIANT_PROPERTY(sys.SQL_VARIANT, sys.VARCHAR(20))
RETURNS sys.SQL_VARIANT
AS 'babelfishpg_common', 'sql_variant_property'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvarianteq(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvarianteq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantne(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantlt(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantle(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantgt(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantgt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.sqlvariantge(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS bool
AS 'babelfishpg_common', 'sqlvariantge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    COMMUTATOR = =,
    NEGATOR = <>,
    PROCEDURE = sys.sqlvarianteq,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    NEGATOR = =,
    COMMUTATOR = <>,
    PROCEDURE = sys.sqlvariantne,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    NEGATOR = >=,
    COMMUTATOR = >,
    PROCEDURE = sys.sqlvariantlt,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    NEGATOR = >,
    COMMUTATOR = >=,
    PROCEDURE = sys.sqlvariantle,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    NEGATOR = <=,
    COMMUTATOR = <,
    PROCEDURE = sys.sqlvariantgt,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = sys.SQL_VARIANT,
    RIGHTARG = sys.SQL_VARIANT,
    NEGATOR = <,
    COMMUTATOR = <=,
    PROCEDURE = sys.sqlvariantge,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE FUNCTION sqlvariant_cmp(sys.SQL_VARIANT, sys.SQL_VARIANT)
RETURNS INT4
AS 'babelfishpg_common', 'sqlvariant_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sqlvariant_hash(sys.SQL_VARIANT)
RETURNS INT4
AS 'babelfishpg_common', 'sqlvariant_hash'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.sqlvariant_ops
DEFAULT FOR TYPE sys.SQL_VARIANT USING btree AS
    OPERATOR 1 < (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR 2 <= (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR 3 = (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR 4 >= (sys.SQL_VARIANT, sys.SQL_VARIANT),
    OPERATOR 5 > (sys.SQL_VARIANT, sys.SQL_VARIANT),
    FUNCTION 1 sqlvariant_cmp(sys.SQL_VARIANT, sys.SQL_VARIANT);

CREATE OPERATOR CLASS sys.sqlvariant_ops
DEFAULT FOR TYPE sys.SQL_VARIANT USING hash AS
    OPERATOR 1 = (sys.SQL_VARIANT, sys.SQL_VARIANT),
    FUNCTION 1 sqlvariant_hash(sys.SQL_VARIANT);
-- 28 "sql/babelfishpg_common.in" 2
-- 1 "sql/string_operators.sql" 1
-- Wrap built-in CONCAT function to accept two text arguments.
-- This is necessary because CONCAT accepts arguments of type VARIADIC "any".
-- CONCAT also automatically handles NULL which || does not.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) RETURNS TEXT AS
$$
  SELECT
    CASE WHEN (current_setting('babelfishpg_tsql.concat_null_yields_null') = 'on') THEN
      CASE
        WHEN leftarg IS NULL OR rightarg IS NULL THEN NULL
        ELSE CONCAT(leftarg, rightarg)
      END
      ELSE
        CONCAT(leftarg, rightarg)
    END
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = sys.babelfish_concat_wrapper
);

create or replace function sys.CHAR(x in int)returns char
AS
$body$
BEGIN



    if x between 1 and 255 then
        return chr(x);
    else
        return null;
    end if;
END;
$body$
language plpgsql;

CREATE OR REPLACE FUNCTION sys.nchar(IN x INTEGER) RETURNS sys.nvarchar
AS
$body$
BEGIN
    --- 1114111 is 0x10FFFF - max value permitted as specified by documentation
    if x between 1 and 1114111 then
        return(select chr(x))::sys.nvarchar;
    else
        return null;
    end if;
END;
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar(IN x varbinary) RETURNS sys.nvarchar
AS
$body$
BEGIN
    --- 1114111 is 0x10FFFF - max value permitted as specified by documentation
    if x::integer between 1 and 1114111 then
        return(select chr(x::integer))::sys.nvarchar;
    else
        return null;
    end if;
END;
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
-- 29 "sql/babelfishpg_common.in" 2
-- 1 "sql/coerce.sql" 1
-- Add Missing casting functions
-- Casting functions used in catalog should use the exact type of castsource and casttarget.

-- double precision -> int8
CREATE OR REPLACE FUNCTION sys.dtrunci8(double precision)
RETURNS INT8
AS 'babelfishpg_common', 'dtrunci8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- double precision -> int4
CREATE OR REPLACE FUNCTION sys.dtrunci4(double precision)
RETURNS INT4
AS 'babelfishpg_common', 'dtrunci4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- double precision -> int2
CREATE OR REPLACE FUNCTION sys.dtrunci2(double precision)
RETURNS INT2
AS 'babelfishpg_common', 'dtrunci2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int8
CREATE OR REPLACE FUNCTION sys.ftrunci8(real)
RETURNS INT8
AS 'babelfishpg_common', 'ftrunci8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int4
CREATE OR REPLACE FUNCTION sys.ftrunci4(real)
RETURNS INT4
AS 'babelfishpg_common', 'ftrunci4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int2
CREATE OR REPLACE FUNCTION sys.ftrunci2(real)
RETURNS INT2
AS 'babelfishpg_common', 'ftrunci2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--- XXX: it is desriable to use SQL (or C) rather than plpgsql. But SQL function is not working
--- if tsql is enabled for some reasons. (BABEL-766)

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int8(In arg sys.fixeddecimal)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT8);
END;
$$ LANGUAGE plpgsql;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int4(In arg sys.fixeddecimal)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT4);
END;
$$ LANGUAGE plpgsql;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int2(In arg sys.fixeddecimal)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT2);
END;
$$ LANGUAGE plpgsql;

-- numeric -> int8
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int8(In arg numeric)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT8);
END;
$$ LANGUAGE plpgsql;

-- numeric -> int4
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int4(In arg numeric)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT4);
END;
$$ LANGUAGE plpgsql;

-- numeric -> int2
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int2(In arg numeric)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT2);
END;
$$ LANGUAGE plpgsql;

-- text -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(text)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- char -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(char)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.char_to_fixeddecimal(sys.bpchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- varchar -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(sys.varchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.char_to_fixeddecimal(pg_catalog.varchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- text -> name
CREATE FUNCTION sys.text_to_name(text)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- bpchar -> name
CREATE FUNCTION sys.bpchar_to_name(pg_catalog.bpchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_bpchar_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchar_to_name(sys.bpchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_bpchar_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- varchar -> name
CREATE FUNCTION sys.varchar_to_name(sys.varchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varchar_to_name(pg_catalog.varchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
-- 30 "sql/babelfishpg_common.in" 2

-- 1 "sql/utils.sql" 1
CREATE OR REPLACE PROCEDURE sys.babel_type_initializer()
LANGUAGE C
AS 'babelfishpg_common', 'init_tcode_trans_tab';
CALL sys.babel_type_initializer();
DROP PROCEDURE sys.babel_type_initializer();

CREATE OR REPLACE FUNCTION sys.babelfish_typecode_list()
RETURNS table (
  oid int,
  pg_namespace text,
  pg_typname text,
  tsql_typname text,
  type_family_priority smallint,
  priority smallint,
  sql_variant_hdr_size smallint
) AS 'babelfishpg_common', 'typecode_list' LANGUAGE C;
-- 32 "sql/babelfishpg_common.in" 2






SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
RESET client_min_messages;
