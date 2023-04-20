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
	   INPUT          = sys.bitin,
	   OUTPUT         = sys.bitout,
	   RECEIVE        = sys.bitrecv,
	   SEND           = sys.bitsend,
	   INTERNALLENGTH = 1,
	   PASSEDBYVALUE,
	   ALIGNMENT      = 'char',
	   STORAGE        = 'plain',
	   CATEGORY       = 'B',
	   PREFERRED      = true,
	   COLLATABLE     = false
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
WITH FUNCTION sys.numeric_bit (NUMERIC) AS IMPLICIT;

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

/* Operators for sys.BIT. TSQL does not support + - * / for bit */
CREATE OPERATOR sys.- (
    RIGHTARG   = sys.BIT,
    PROCEDURE  = sys.bitneg
);

CREATE OPERATOR sys.~ (
    RIGHTARG   = sys.BIT,
    PROCEDURE  = sys.bitneg
);

CREATE OPERATOR sys.= (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.biteq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.bitne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.bitlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.bitle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.bitgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.BIT,
    RIGHTARG   = sys.BIT,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.bitge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR CLASS sys.bit_ops
DEFAULT FOR TYPE sys.bit USING btree AS
    OPERATOR    1   <  (sys.bit, sys.bit),
    OPERATOR    2   <= (sys.bit, sys.bit),
    OPERATOR    3   =  (sys.bit, sys.bit),
    OPERATOR    4   >= (sys.bit, sys.bit),
    OPERATOR    5   >  (sys.bit, sys.bit),
    FUNCTION    1   sys.bit_cmp(sys.bit, sys.bit);

/* Comparison between int and bit */
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
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.int4biteq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.int4bitne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.int4bitlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.int4bitle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.int4bitgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = INT4,
    RIGHTARG   = sys.BIT,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.int4bitge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

/* Comparison between bit and int */
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
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.bitint4eq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.bitint4ne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.bitint4lt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.bitint4le,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.bitint4gt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.BIT,
    RIGHTARG   = INT4,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.bitint4ge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OR REPLACE FUNCTION sys.bitxor(leftarg pg_catalog.bit, rightarg pg_catalog.bit)
RETURNS pg_catalog.bit
AS $$
SELECT (leftarg & ~rightarg) | (~leftarg & rightarg);
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.bit_unsupported_max(IN b1 sys.BIT, IN b2 sys.BIT)
RETURNS sys.BIT
AS $$
BEGIN
   RAISE EXCEPTION 'Operand data type bit is invalid for max operator.';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.bit_unsupported_min(IN b1 sys.BIT, IN b2 sys.BIT)
RETURNS sys.BIT
AS $$
BEGIN
   RAISE EXCEPTION 'Operand data type bit is invalid for min operator.';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.bit_unsupported_sum(IN b1 sys.BIT, IN b2 sys.BIT)
RETURNS sys.BIT
AS $$
BEGIN
   RAISE EXCEPTION 'Operand data type bit is invalid for sum operator.';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION sys.bit_unsupported_avg(IN b1 sys.BIT, IN b2 sys.BIT)
RETURNS sys.BIT
AS $$
BEGIN
   RAISE EXCEPTION 'Operand data type bit is invalid for avg operator.';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE AGGREGATE sys.max(sys.BIT)
(
    sfunc = sys.bit_unsupported_max,
    stype = sys.bit,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.BIT)
(
    sfunc = sys.bit_unsupported_min,
    stype = sys.bit,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.sum(sys.BIT)
(
    sfunc = sys.bit_unsupported_sum,
    stype = sys.bit,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.avg(sys.BIT)
(
    sfunc = sys.bit_unsupported_avg,
    stype = sys.bit,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.varchar2bit(sys.VARCHAR)
RETURNS sys.BIT
AS 'babelfishpg_common', 'varchar2bit'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.BIT)
WITH FUNCTION sys.varchar2bit(sys.VARCHAR) AS IMPLICIT;
