-- create support function for int and numeric comparison
CREATE FUNCTION sys.int4_numeric_cmp (int, numeric)
RETURNS int
AS 'babelfishpg_common', 'int4_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.numeric_int4_cmp (numeric, int)
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
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR sys.<> (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.int_numeric FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (int, numeric),
   OPERATOR 2 sys.<= (int, numeric),
   OPERATOR 3 sys.= (int, numeric),
   OPERATOR 4 sys.>= (int, numeric),
   OPERATOR 5 sys.> (int, numeric),
   FUNCTION 1 sys.int4_numeric_cmp(int, numeric);

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
CREATE OPERATOR CLASS sys.numeric_int FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (numeric, int),
   OPERATOR 2 sys.<= (numeric, int),
   OPERATOR 3 sys.= (numeric, int),
   OPERATOR 4 sys.>= (numeric, int),
   OPERATOR 5 sys.> (numeric, int),
   FUNCTION 1 sys.numeric_int4_cmp(numeric, int);

-- Update operator family for integer, integer_ops to incorporate various operator between int and numeric for Index scan
-- ALTER OPERATOR FAMILY integer_ops USING btree ADD
--    OPERATOR 1 sys.< (int, numeric),
--    OPERATOR 2 sys.<= (int, numeric),
--    OPERATOR 3 sys.= (int, numeric),
--    OPERATOR 4 sys.>= (int, numeric),
--    OPERATOR 5 sys.> (int, numeric),
--    OPERATOR 1 sys.< (numeric, int),
--    OPERATOR 2 sys.<= (numeric, int),
--    OPERATOR 3 sys.= (numeric, int),
--    OPERATOR 4 sys.>= (numeric, int),
--    OPERATOR 5 sys.> (numeric, int),
--    FUNCTION 1 sys.int4_numeric_cmp(int, numeric),
--    FUNCTION 1 sys.numeric_int4_cmp(numeric, int);