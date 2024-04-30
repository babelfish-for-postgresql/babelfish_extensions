-- create support function for int4 and numeric comparison
CREATE FUNCTION sys.int4_numeric_cmp (int4, numeric)
RETURNS int
AS 'babelfishpg_common', 'int4_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_cmp (numeric, int4)
RETURNS int
AS 'babelfishpg_common', 'numeric_int4_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_eq (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_eq (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_neq (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_neq (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_lt (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_lt (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_lte (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_lte (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_gt (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_gt (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4_numeric_gte (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_gte (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators between int and numeric
CREATE OPERATOR sys.< (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = int4,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = numeric,
    RIGHTARG = int4,
    FUNCTION = sys.numeric_int4_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.int_numeric FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (int4, numeric),
   OPERATOR 2 sys.<= (int4, numeric),
   OPERATOR 3 sys.= (int4, numeric),
   OPERATOR 4 sys.>= (int4, numeric),
   OPERATOR 5 sys.> (int4, numeric),
   FUNCTION 1 sys.int4_numeric_cmp(int4, numeric);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.numeric_int FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (numeric, int4),
   OPERATOR 2 sys.<= (numeric, int4),
   OPERATOR 3 sys.= (numeric, int4),
   OPERATOR 4 sys.>= (numeric, int4),
   OPERATOR 5 sys.> (numeric, int4),
   FUNCTION 1 sys.numeric_int4_cmp(numeric, int4);

-- create support function for int2 and numeric comparison
CREATE FUNCTION sys.int2_numeric_cmp (int2, numeric)
RETURNS int
AS 'babelfishpg_common', 'int2_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_cmp (numeric, int2)
RETURNS int
AS 'babelfishpg_common', 'numeric_int2_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_eq (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_eq (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_neq (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_neq (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_lt (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_lt (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_lte (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_lte (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_gt (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_gt (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2_numeric_gte (int2, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int2_numeric_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int2_gte (numeric, int2)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int2_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators between int and numeric
CREATE OPERATOR sys.< (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = int2,
    RIGHTARG = numeric,
    FUNCTION = sys.int2_numeric_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = numeric,
    RIGHTARG = int2,
    FUNCTION = sys.numeric_int2_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.int2_numeric FOR TYPE int2
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (int2, numeric),
   OPERATOR 2 sys.<= (int2, numeric),
   OPERATOR 3 sys.= (int2, numeric),
   OPERATOR 4 sys.>= (int2, numeric),
   OPERATOR 5 sys.> (int2, numeric),
   FUNCTION 1 sys.int2_numeric_cmp(int2, numeric);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.numeric_int2 FOR TYPE int2
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (numeric, int2),
   OPERATOR 2 sys.<= (numeric, int2),
   OPERATOR 3 sys.= (numeric, int2),
   OPERATOR 4 sys.>= (numeric, int2),
   OPERATOR 5 sys.> (numeric, int2),
   FUNCTION 1 sys.numeric_int2_cmp(numeric, int2);

-- create support function for int8 and numeric comparison
CREATE FUNCTION sys.int8_numeric_cmp (int8, numeric)
RETURNS int
AS 'babelfishpg_common', 'int8_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_cmp (numeric, int8)
RETURNS int
AS 'babelfishpg_common', 'numeric_int8_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_eq (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_eq (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_neq (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_neq (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_lt (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_lt (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_lte (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_lte (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_gt (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_gt (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8_numeric_gte (int8, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int8_numeric_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int8_gte (numeric, int8)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int8_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators between int and numeric
CREATE OPERATOR sys.< (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = int8,
    RIGHTARG = numeric,
    FUNCTION = sys.int8_numeric_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = numeric,
    RIGHTARG = int8,
    FUNCTION = sys.numeric_int8_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.int8_numeric FOR TYPE int8
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (int8, numeric),
   OPERATOR 2 sys.<= (int8, numeric),
   OPERATOR 3 sys.= (int8, numeric),
   OPERATOR 4 sys.>= (int8, numeric),
   OPERATOR 5 sys.> (int8, numeric),
   FUNCTION 1 sys.int8_numeric_cmp(int8, numeric);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.numeric_int8 FOR TYPE int8
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (numeric, int8),
   OPERATOR 2 sys.<= (numeric, int8),
   OPERATOR 3 sys.= (numeric, int8),
   OPERATOR 4 sys.>= (numeric, int8),
   OPERATOR 5 sys.> (numeric, int8),
   FUNCTION 1 sys.numeric_int8_cmp(numeric, int8);
