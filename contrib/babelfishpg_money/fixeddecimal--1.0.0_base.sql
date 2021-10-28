------------------
-- FIXEDDECIMAL --
------------------

CREATE TYPE FIXEDDECIMAL;

CREATE FUNCTION fixeddecimalin(cstring, oid, int4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalin'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalout(fixeddecimal)
RETURNS cstring
AS 'babelfishpg_money', 'fixeddecimalout'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalrecv(internal)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalrecv'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalsend(FIXEDDECIMAL)
RETURNS bytea
AS 'babelfishpg_money', 'fixeddecimalsend'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimaltypmodin(_cstring)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimaltypmodin'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimaltypmodout(INT4)
RETURNS cstring
AS 'babelfishpg_money', 'fixeddecimaltypmodout'
LANGUAGE C IMMUTABLE STRICT;


CREATE TYPE FIXEDDECIMAL (
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
    PREFERRED      = true,
    COLLATABLE     = false,
	PASSEDBYVALUE -- But not always.. XXX fix that.
);

CREATE FUNCTION fixeddecimaleq(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimaleq'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalne(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalne'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimallt(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimallt'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalle(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalle'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalgt(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalgt'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalge(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS bool
AS 'babelfishpg_money', 'fixeddecimalge'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalum(FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalum'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalpl(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalmi(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalmul(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimaldiv(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION abs(FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalabs'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimallarger(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimallarger'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalsmaller(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalsmaller'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimal_cmp(FIXEDDECIMAL, FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_cmp'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimal_hash(FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimal_hash'
LANGUAGE C IMMUTABLE STRICT;

--
-- Operators.
--

CREATE OPERATOR = (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = fixeddecimaleq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR <> (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = fixeddecimalne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR < (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = fixeddecimallt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR <= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = fixeddecimalle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR >= (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = fixeddecimalge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR > (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = fixeddecimalgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR + (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalpl
);

CREATE OPERATOR - (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimalmi
);

CREATE OPERATOR - (
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimalum
);

CREATE OPERATOR * (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalmul
);

CREATE OPERATOR / (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = fixeddecimaldiv
);

CREATE OPERATOR CLASS fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING btree AS
    OPERATOR    1   <  (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    2   <= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    3   =  (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    4   >= (FIXEDDECIMAL, FIXEDDECIMAL),
    OPERATOR    5   >  (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION    1   fixeddecimal_cmp(FIXEDDECIMAL, FIXEDDECIMAL);

CREATE OPERATOR CLASS fixeddecimal_ops
DEFAULT FOR TYPE FIXEDDECIMAL USING hash AS
    OPERATOR    1   =  (FIXEDDECIMAL, FIXEDDECIMAL),
    FUNCTION    1   fixeddecimal_hash(FIXEDDECIMAL);

--
-- Cross type operators with int4
--

CREATE FUNCTION fixeddecimalint4pl(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint4pl'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint4mi(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint4mi'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint4mul(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint4mul'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint4div(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint4div'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR + (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint4pl
);

CREATE OPERATOR - (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4mi
);

CREATE OPERATOR * (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint4mul
);

CREATE OPERATOR / (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4div
);


CREATE FUNCTION int4fixeddecimalpl(INT4, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int4fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int4fixeddecimalmi(INT4, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int4fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int4fixeddecimalmul(INT4, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int4fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int4fixeddecimaldiv(INT4, FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int4fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR + (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = int4fixeddecimalpl
);

CREATE OPERATOR - (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int4fixeddecimalmi
);

CREATE OPERATOR * (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = int4fixeddecimalmul
);

CREATE OPERATOR / (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int4fixeddecimaldiv
);

--
-- Cross type operators with int2
--

CREATE FUNCTION fixeddecimalint2pl(FIXEDDECIMAL, INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint2pl'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint2mi(FIXEDDECIMAL, INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint2mi'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint2mul(FIXEDDECIMAL, INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint2mul'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint2div(FIXEDDECIMAL, INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimalint2div'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR + (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint2pl
);

CREATE OPERATOR - (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2mi
);

CREATE OPERATOR * (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint2mul
);

CREATE OPERATOR / (
    LEFTARG    = FIXEDDECIMAL,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2div
);

CREATE FUNCTION int2fixeddecimalpl(INT2, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int2fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int2fixeddecimalmi(INT2, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int2fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int2fixeddecimalmul(INT2, FIXEDDECIMAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int2fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int2fixeddecimaldiv(INT2, FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int2fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR + (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = +,
    PROCEDURE  = int2fixeddecimalpl
);

CREATE OPERATOR - (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int2fixeddecimalmi
);

CREATE OPERATOR * (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    COMMUTATOR = *,
    PROCEDURE  = int2fixeddecimalmul
);

CREATE OPERATOR / (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int2fixeddecimaldiv
);

--
-- Casts
--

CREATE FUNCTION fixeddecimal(FIXEDDECIMAL, INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'fixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int4fixeddecimal(INT4)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int4fixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint4(FIXEDDECIMAL)
RETURNS INT4
AS 'babelfishpg_money', 'fixeddecimalint4'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION int2fixeddecimal(INT2)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'int2fixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalint2(FIXEDDECIMAL)
RETURNS INT2
AS 'babelfishpg_money', 'fixeddecimalint2'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimaltod(FIXEDDECIMAL)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'fixeddecimaltod'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION dtofixeddecimal(DOUBLE PRECISION)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'dtofixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimaltof(FIXEDDECIMAL)
RETURNS REAL
AS 'babelfishpg_money', 'fixeddecimaltof'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ftofixeddecimal(REAL)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'ftofixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimal_numeric(FIXEDDECIMAL)
RETURNS NUMERIC
AS 'babelfishpg_money', 'fixeddecimal_numeric'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION numeric_fixeddecimal(NUMERIC)
RETURNS FIXEDDECIMAL
AS 'babelfishpg_money', 'numeric_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT;

CREATE CAST (FIXEDDECIMAL AS FIXEDDECIMAL)
	WITH FUNCTION fixeddecimal (FIXEDDECIMAL, INT4) AS ASSIGNMENT;

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
	WITH FUNCTION numeric_fixeddecimal (NUMERIC) AS ASSIGNMENT;
