------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "4.1.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- need to conver this into IF NOT EXIST format in order to prevent it from upgrade failure
-- Operators between int and numeric 
-- create support function for int and numeric comparison
CREATE OR REPLACE FUNCTION sys.int4_numeric_cmp (int, numeric)
RETURNS int
AS 'babelfishpg_common', 'int4_numeric_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_cmp (numeric, int)
RETURNS int
AS 'babelfishpg_common', 'numeric_int4_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_eq (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_eq (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_neq (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_neq (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_lt (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_lt (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_lte (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_lte (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_lte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_gt (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_gt (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4_numeric_gte (int, numeric)
RETURNS boolean
AS 'babelfishpg_common', 'int4_numeric_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.numeric_int4_gte (numeric, int)
RETURNS boolean
AS 'babelfishpg_common', 'numeric_int4_gte'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Operators between int and numeric
DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<') THEN
CREATE OPERATOR sys.< (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<') THEN
CREATE OPERATOR sys.< (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_lt,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<=') THEN
CREATE OPERATOR sys.<= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<=') THEN
CREATE OPERATOR sys.<= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_lte,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarlesel,
    JOIN = scalarlejoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '>') THEN
CREATE OPERATOR sys.> (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '>') THEN
CREATE OPERATOR sys.> (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_gt,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '>=') THEN
CREATE OPERATOR sys.>= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '>=') THEN
CREATE OPERATOR sys.>= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_gte,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargesel,
    JOIN = scalargejoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '=') THEN
CREATE OPERATOR sys.= (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '=') THEN
CREATE OPERATOR sys.= (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_eq,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'int4'::pg_catalog.regtype and oprright = 'numeric'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<>') THEN
CREATE OPERATOR sys.<> (
    LEFTARG = int,
    RIGHTARG = numeric,
    FUNCTION = sys.int4_numeric_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);
END IF;
END $$;

DO $$
BEGIN
IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'numeric'::pg_catalog.regtype and oprright = 'int4'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '<>') THEN
CREATE OPERATOR sys.<> (
    LEFTARG = numeric,
    RIGHTARG = int,
    FUNCTION = sys.numeric_int4_neq,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);
END IF;
END $$;

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
-- DO $$
-- BEGIN
-- IF NOT EXISTS(select 1 from pg_opclass opc join pg_opfamily opf on opc.opcfamily = opf.oid where opc.opcname = 'int_numeric' and opc.opcnamespace = 'sys'::regnamespace and opf.opfname = 'integer_ops') THEN
CREATE OPERATOR CLASS sys.int_numeric FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (int, numeric),
   OPERATOR 2 sys.<= (int, numeric),
   OPERATOR 3 sys.= (int, numeric),
   OPERATOR 4 sys.>= (int, numeric),
   OPERATOR 5 sys.> (int, numeric),
   FUNCTION 1 sys.int4_numeric_cmp(int, numeric);
-- END IF;
-- END $$;

-- Opartor class for integer_ops to incorporate various operator between int and numeric for Index scan
-- DO $$
-- BEGIN
-- IF NOT EXISTS(select 1 from pg_opclass opc join pg_opfamily opf on opc.opcfamily = opf.oid where opc.opcname = 'numeric_int' and opc.opcnamespace = 'sys'::regnamespace and opf.opfname = 'integer_ops') THEN
CREATE OPERATOR CLASS sys.numeric_int FOR TYPE int4
  USING btree FAMILY integer_ops AS
   OPERATOR 1 sys.< (numeric, int),
   OPERATOR 2 sys.<= (numeric, int),
   OPERATOR 3 sys.= (numeric, int),
   OPERATOR 4 sys.>= (numeric, int),
   OPERATOR 5 sys.> (numeric, int),
   FUNCTION 1 sys.numeric_int4_cmp(numeric, int);
-- END IF;
-- END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
