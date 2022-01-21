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
    INPUT          = fixeddecimalin,
    OUTPUT         = fixeddecimalout,
    RECEIVE        = fixeddecimalrecv,
    SEND           = fixeddecimalsend,
	TYPMOD_IN      = fixeddecimaltypmodin,
	TYPMOD_OUT     = fixeddecimaltypmodout,
    INTERNALLENGTH = 8,
	ALIGNMENT      = 'double',
    STORAGE        = plain,
    CATEGORY       = 'N',
    PREFERRED      = false,
    COLLATABLE     = false,
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

CREATE OPERATOR FAMILY fixeddecimal_ops USING btree;
CREATE OPERATOR FAMILY fixeddecimal_ops USING hash;

-- FIXEDDECIMAL op FIXEDDECIMAL
CREATE OPERATOR sys.= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimaleq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimalne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimallt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimalle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimalge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimalgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimalmi
);

CREATE OPERATOR sys.- (
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimalum
);

CREATE OPERATOR sys.* (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimaldiv
);

CREATE OPERATOR CLASS sys.fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING btree FAMILY fixeddecimal_ops AS
    OPERATOR    1   <  (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    2   <= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    3   =  (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    4   >= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    5   >  (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION    1   fixeddecimal_cmp(FIXEDDECIMAL, FIXEDDECIMAL);

CREATE OPERATOR CLASS sys.fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING hash FAMILY fixeddecimal_ops AS
    OPERATOR    1   =  (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION    1   fixeddecimal_hash(FIXEDDECIMAL);

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
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimal_numeric_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimal_numeric_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimal_numeric_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimal_numeric_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimal_numeric_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = NUMERIC,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimal_numeric_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (FIXEDDECIMAL, NUMERIC),
    OPERATOR    2   <= (FIXEDDECIMAL, NUMERIC),
    OPERATOR    3   =  (FIXEDDECIMAL, NUMERIC),
    OPERATOR    4   >= (FIXEDDECIMAL, NUMERIC),
    OPERATOR    5   >  (FIXEDDECIMAL, NUMERIC),
    FUNCTION    1   fixeddecimal_numeric_cmp(FIXEDDECIMAL, NUMERIC);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (FIXEDDECIMAL, NUMERIC);

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
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = numeric_fixeddecimal_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = numeric_fixeddecimal_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = numeric_fixeddecimal_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = numeric_fixeddecimal_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR >= (
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = numeric_fixeddecimal_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = NUMERIC,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = numeric_fixeddecimal_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR    2   <= (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR    3   =  (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR    4   >= (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    OPERATOR    5   >  (NUMERIC, FIXEDDECIMAL) FOR SEARCH,
    FUNCTION    1   numeric_fixeddecimal_cmp(NUMERIC, FIXEDDECIMAL);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (NUMERIC, FIXEDDECIMAL);

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
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimal_int8_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimal_int8_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimal_int8_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimal_int8_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimal_int8_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimal_int8_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint8pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    PROCEDURE  = fixeddecimalint8mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint8mul
);

CREATE OPERATOR sys./ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT8,
    PROCEDURE  = fixeddecimalint8div
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (FIXEDDECIMAL, INT8),
    OPERATOR    2   <= (FIXEDDECIMAL, INT8),
    OPERATOR    3   =  (FIXEDDECIMAL, INT8),
    OPERATOR    4   >= (FIXEDDECIMAL, INT8),
    OPERATOR    5   >  (FIXEDDECIMAL, INT8),
    FUNCTION    1   fixeddecimal_int8_cmp(FIXEDDECIMAL, INT8);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
   OPERATOR    1   =  (FIXEDDECIMAL, INT8);

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
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = int8_fixeddecimal_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = int8_fixeddecimal_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = int8_fixeddecimal_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = int8_fixeddecimal_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = int8_fixeddecimal_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = int8_fixeddecimal_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = int8fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int8fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = int8fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int8fixeddecimaldiv
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (INT8, FIXEDDECIMAL),
    OPERATOR    2   <= (INT8, FIXEDDECIMAL),
    OPERATOR    3   =  (INT8, FIXEDDECIMAL),
    OPERATOR    4   >= (INT8, FIXEDDECIMAL),
    OPERATOR    5   >  (INT8, FIXEDDECIMAL),
    FUNCTION    1   int8_fixeddecimal_cmp(INT8, FIXEDDECIMAL);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
   OPERATOR    1   =  (INT8, FIXEDDECIMAL);

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
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimal_int4_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimal_int4_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimal_int4_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimal_int4_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimal_int4_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimal_int4_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint4pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint4mul
);

CREATE OPERATOR sys./ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4div
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (FIXEDDECIMAL, INT4),
    OPERATOR    2   <= (FIXEDDECIMAL, INT4),
    OPERATOR    3   =  (FIXEDDECIMAL, INT4),
    OPERATOR    4   >= (FIXEDDECIMAL, INT4),
    OPERATOR    5   >  (FIXEDDECIMAL, INT4),
    FUNCTION    1   fixeddecimal_int4_cmp(FIXEDDECIMAL, INT4);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (FIXEDDECIMAL, INT4);

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
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = int4_fixeddecimal_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = int4_fixeddecimal_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = int4_fixeddecimal_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = int4_fixeddecimal_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = int4_fixeddecimal_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = int4_fixeddecimal_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = int4fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int4fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = int4fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int4fixeddecimaldiv
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (INT4, FIXEDDECIMAL),
    OPERATOR    2   <= (INT4, FIXEDDECIMAL),
    OPERATOR    3   =  (INT4, FIXEDDECIMAL),
    OPERATOR    4   >= (INT4, FIXEDDECIMAL),
    OPERATOR    5   >  (INT4, FIXEDDECIMAL),
    FUNCTION    1   int4_fixeddecimal_cmp(INT4, FIXEDDECIMAL);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (INT4, FIXEDDECIMAL);

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
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimal_int2_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimal_int2_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimal_int2_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimal_int2_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimal_int2_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimal_int2_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint2pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint2mul
);

CREATE OPERATOR sys./ (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2div
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (FIXEDDECIMAL, INT2),
    OPERATOR    2   <= (FIXEDDECIMAL, INT2),
    OPERATOR    3   =  (FIXEDDECIMAL, INT2),
    OPERATOR    4   >= (FIXEDDECIMAL, INT2),
    OPERATOR    5   >  (FIXEDDECIMAL, INT2),
    FUNCTION    1   fixeddecimal_int2_cmp(FIXEDDECIMAL, INT2);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (FIXEDDECIMAL, INT2);

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
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = int2_fixeddecimal_eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = int2_fixeddecimal_ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = int2_fixeddecimal_lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = int2_fixeddecimal_le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = int2_fixeddecimal_ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = int2_fixeddecimal_gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = int2fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int2fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = int2fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int2fixeddecimaldiv
);

ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    OPERATOR    1   <  (INT2, FIXEDDECIMAL),
    OPERATOR    2   <= (INT2, FIXEDDECIMAL),
    OPERATOR    3   =  (INT2, FIXEDDECIMAL),
    OPERATOR    4   >= (INT2, FIXEDDECIMAL),
    OPERATOR    5   >  (INT2, FIXEDDECIMAL),
    FUNCTION    1   int2_fixeddecimal_cmp(INT2, FIXEDDECIMAL);

ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (INT2, FIXEDDECIMAL);

-- add combination of (int8/int4/int2) to fixeddecimal_ops to make it complete
ALTER OPERATOR FAMILY fixeddecimal_ops USING btree ADD
    -- INT8
    OPERATOR    1   <  (INT8, INT8),
    OPERATOR    2   <= (INT8, INT8),
    OPERATOR    3   =  (INT8, INT8),
    OPERATOR    4   >= (INT8, INT8),
    OPERATOR    5   >  (INT8, INT8),
    FUNCTION    1   btint8cmp(INT8, INT8),

    OPERATOR    1   <  (INT8, INT4),
    OPERATOR    2   <= (INT8, INT4),
    OPERATOR    3   =  (INT8, INT4),
    OPERATOR    4   >= (INT8, INT4),
    OPERATOR    5   >  (INT8, INT4),
    FUNCTION    1   btint84cmp(INT8, INT4),

    OPERATOR    1   <  (INT8, INT2),
    OPERATOR    2   <= (INT8, INT2),
    OPERATOR    3   =  (INT8, INT2),
    OPERATOR    4   >= (INT8, INT2),
    OPERATOR    5   >  (INT8, INT2),
    FUNCTION    1   btint82cmp(INT8, INT2),

    -- INT4
    OPERATOR    1   <  (INT4, INT8),
    OPERATOR    2   <= (INT4, INT8),
    OPERATOR    3   =  (INT4, INT8),
    OPERATOR    4   >= (INT4, INT8),
    OPERATOR    5   >  (INT4, INT8),
    FUNCTION    1   btint48cmp(INT4, INT8),

    OPERATOR    1   <  (INT4, INT4),
    OPERATOR    2   <= (INT4, INT4),
    OPERATOR    3   =  (INT4, INT4),
    OPERATOR    4   >= (INT4, INT4),
    OPERATOR    5   >  (INT4, INT4),
    FUNCTION    1   btint4cmp(INT4, INT4),

    OPERATOR    1   <  (INT4, INT2),
    OPERATOR    2   <= (INT4, INT2),
    OPERATOR    3   =  (INT4, INT2),
    OPERATOR    4   >= (INT4, INT2),
    OPERATOR    5   >  (INT4, INT2),
    FUNCTION    1   btint42cmp(INT4, INT2),

    -- INT2
    OPERATOR    1   <  (INT2, INT8),
    OPERATOR    2   <= (INT2, INT8),
    OPERATOR    3   =  (INT2, INT8),
    OPERATOR    4   >= (INT2, INT8),
    OPERATOR    5   >  (INT2, INT8),
    FUNCTION    1   btint28cmp(INT2, INT8),

    OPERATOR    1   <  (INT2, INT4),
    OPERATOR    2   <= (INT2, INT4),
    OPERATOR    3   =  (INT2, INT4),
    OPERATOR    4   >= (INT2, INT4),
    OPERATOR    5   >  (INT2, INT4),
    FUNCTION    1   btint24cmp(INT2, INT4),

    OPERATOR    1   <  (INT2, INT2),
    OPERATOR    2   <= (INT2, INT2),
    OPERATOR    3   =  (INT2, INT2),
    OPERATOR    4   >= (INT2, INT2),
    OPERATOR    5   >  (INT2, INT2),
    FUNCTION    1   btint2cmp(INT2, INT2),

    -- numeric
    OPERATOR    1   <  (NUMERIC, NUMERIC),
    OPERATOR    2   <= (NUMERIC, NUMERIC),
    OPERATOR    3   =  (NUMERIC, NUMERIC),
    OPERATOR    4   >= (NUMERIC, NUMERIC),
    OPERATOR    5   >  (NUMERIC, NUMERIC),
    FUNCTION    1   numeric_cmp(NUMERIC, NUMERIC);


ALTER OPERATOR FAMILY fixeddecimal_ops USING hash ADD
    OPERATOR    1   =  (INT8, INT8),
    OPERATOR    1   =  (INT8, INT4),
    OPERATOR    1   =  (INT8, INT2),
    OPERATOR    1   =  (INT4, INT8),
    OPERATOR    1   =  (INT4, INT4),
    OPERATOR    1   =  (INT4, INT2),
    OPERATOR    1   =  (INT2, INT8),
    OPERATOR    1   =  (INT2, INT4),
    OPERATOR    1   =  (INT2, INT2),
    OPERATOR    1   =  (NUMERIC, NUMERIC),
    FUNCTION    1   hashint8(INT8),
    FUNCTION    1   hashint4(INT4),
    FUNCTION    1   hashint2(INT2),
    FUNCTION    1   hash_numeric(NUMERIC);

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
