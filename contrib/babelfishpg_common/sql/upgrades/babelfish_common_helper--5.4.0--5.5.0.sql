------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
-- \echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "5.5.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Adding operator optimization clauses so that binary/varbinary incorporate index scans when necessary
alter OPERATOR sys.= (sys.bbf_binary, sys.bbf_binary) 
set (
    NEGATOR = <>,
    JOIN = eqjoinsel
);

alter OPERATOR sys.= (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    NEGATOR = <>,
    JOIN = eqjoinsel
);

alter OPERATOR sys.<> (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = neqsel,
    NEGATOR = =,
    JOIN = neqjoinsel
);

alter OPERATOR sys.<> (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = neqsel,
    NEGATOR = =,
    JOIN = neqjoinsel
);

alter OPERATOR sys.> (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = scalargtsel,
    NEGATOR = <=,
    JOIN = scalargtjoinsel
);

alter OPERATOR sys.> (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = scalargtsel,
    NEGATOR = <=,
    JOIN = scalargtjoinsel
);

alter OPERATOR sys.>= (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = scalargesel,
    NEGATOR = <,
    JOIN = scalargejoinsel
);

alter OPERATOR sys.>= (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = scalargesel,
    NEGATOR = <,
    JOIN = scalargejoinsel
);

alter OPERATOR sys.< (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = scalarltsel,
    NEGATOR = >=,
    JOIN = scalarltjoinsel
);

alter OPERATOR sys.< (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = scalarltsel,
    NEGATOR = >=,
    JOIN = scalarltjoinsel
);

alter OPERATOR sys.<= (sys.bbf_binary, sys.bbf_binary) 
set (
    RESTRICT = scalarlesel,
    NEGATOR = >,
    JOIN = scalarlejoinsel
);

alter OPERATOR sys.<= (sys.bbf_varbinary, sys.bbf_varbinary) 
set (
    RESTRICT = scalarlesel,
    NEGATOR = >,
    JOIN = scalarlejoinsel
);

-- Adding cross operators support for comparison between binary and varbinary
-- Helper function
CREATE OR REPLACE FUNCTION get_bbf_binary_ops_count(opffamily varchar) 
RETURNS int AS $$
BEGIN
    RETURN (SELECT count(*) FROM pg_am am, pg_opfamily opf, pg_amop amop 
            WHERE opf.opfmethod = am.oid 
              AND amop.amopfamily = opf.oid 
              AND opf.opfname = opffamily);
END;
$$ LANGUAGE plpgsql;

-- Add cross-type operators for bbf_binary op bbf_varbinary
DO $$
DECLARE 
    bbf_binary_ops_c INT := (SELECT * FROM get_bbf_binary_ops_count('bbf_binary_ops'));
BEGIN
    RAISE NOTICE 'bbf_binary_ops operator count: %', bbf_binary_ops_c;

    IF bbf_binary_ops_c = 5 THEN
        RAISE NOTICE 'Adding all cross-type operators to bbf_binary_ops (equality + comparison)';

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_eq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_eq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_neq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_neq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_lt(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_lt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_leq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_leq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_gt(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_gt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_geq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_geq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary)
        RETURNS int AS 'babelfishpg_common', 'varbinary_cmp'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_eq,
            COMMUTATOR = =,
            NEGATOR = <>,
            RESTRICT = eqsel,
            JOIN = eqjoinsel
        );

        CREATE OPERATOR sys.<> (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_neq,
            COMMUTATOR = <>,
            NEGATOR = =,
            RESTRICT = neqsel,
            JOIN = neqjoinsel
        );

        CREATE OPERATOR sys.< (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_lt,
            COMMUTATOR = >,
            NEGATOR = >=,
            RESTRICT = scalarltsel,
            JOIN = scalarltjoinsel
        );

        CREATE OPERATOR sys.<= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_leq,
            COMMUTATOR = >=,
            NEGATOR = >,
            RESTRICT = scalarlesel,
            JOIN = scalarlejoinsel
        );

        CREATE OPERATOR sys.> (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_gt,
            COMMUTATOR = <,
            NEGATOR = <=,
            RESTRICT = scalargtsel,
            JOIN = scalargtjoinsel
        );

        CREATE OPERATOR sys.>= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_geq,
            COMMUTATOR = <=,
            NEGATOR = <,
            RESTRICT = scalargesel,
            JOIN = scalargejoinsel
        );

        ALTER OPERATOR FAMILY bbf_binary_ops USING btree ADD
            OPERATOR 1 sys.< (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 2 sys.<= (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 3 sys.= (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 4 sys.>= (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 5 sys.> (sys.bbf_binary, sys.bbf_varbinary),
            FUNCTION 1 sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary);

    ELSIF bbf_binary_ops_c = 6 THEN
        RAISE NOTICE 'Adding comparison operators to bbf_binary_ops (equality already exists)';

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_neq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_neq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_lt(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_lt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_leq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_leq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_gt(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_gt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.binary_varbinary_geq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_geq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.<> (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_neq,
            COMMUTATOR = <>,
            NEGATOR = =,
            RESTRICT = neqsel,
            JOIN = neqjoinsel
        );

        CREATE OPERATOR sys.< (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_lt,
            COMMUTATOR = >,
            NEGATOR = >=,
            RESTRICT = scalarltsel,
            JOIN = scalarltjoinsel
        );

        CREATE OPERATOR sys.<= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_leq,
            COMMUTATOR = >=,
            NEGATOR = >,
            RESTRICT = scalarlesel,
            JOIN = scalarlejoinsel
        );

        CREATE OPERATOR sys.> (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_gt,
            COMMUTATOR = <,
            NEGATOR = <=,
            RESTRICT = scalargtsel,
            JOIN = scalargtjoinsel
        );

        CREATE OPERATOR sys.>= (
            LEFTARG = sys.bbf_binary,
            RIGHTARG = sys.bbf_varbinary,
            FUNCTION = sys.binary_varbinary_geq,
            COMMUTATOR = <=,
            NEGATOR = <,
            RESTRICT = scalargesel,
            JOIN = scalargejoinsel
        );

        ALTER OPERATOR FAMILY bbf_binary_ops USING btree ADD
            OPERATOR 1 sys.< (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 2 sys.<= (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 4 sys.>= (sys.bbf_binary, sys.bbf_varbinary),
            OPERATOR 5 sys.> (sys.bbf_binary, sys.bbf_varbinary);

    ELSIF bbf_binary_ops_c = 10 THEN
        RAISE NOTICE 'All cross-type operators already installed in bbf_binary_ops';

    ELSE
        RAISE EXCEPTION 'Unexpected operator count in bbf_binary_ops: %', bbf_binary_ops_c;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add cross-type operators for bbf_varbinary op bbf_binary
DO $$
DECLARE 
    bbf_varbinary_ops_c INT := (SELECT * FROM get_bbf_binary_ops_count('bbf_varbinary_ops'));
BEGIN
    RAISE NOTICE 'bbf_varbinary_ops operator count: %', bbf_varbinary_ops_c;

    IF bbf_varbinary_ops_c = 5 THEN
        RAISE NOTICE 'Adding all reverse cross-type operators to bbf_varbinary_ops';

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_eq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_eq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_neq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_neq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_lt(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_lt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_leq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_leq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_gt(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_gt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_geq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_geq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary)
        RETURNS int AS 'babelfishpg_common', 'varbinary_cmp'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_eq,
            COMMUTATOR = =,
            NEGATOR = <>,
            RESTRICT = eqsel,
            JOIN = eqjoinsel
        );

        CREATE OPERATOR sys.<> (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_neq,
            COMMUTATOR = <>,
            NEGATOR = =,
            RESTRICT = neqsel,
            JOIN = neqjoinsel
        );

        CREATE OPERATOR sys.< (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_lt,
            COMMUTATOR = >,
            NEGATOR = >=,
            RESTRICT = scalarltsel,
            JOIN = scalarltjoinsel
        );

        CREATE OPERATOR sys.<= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_leq,
            COMMUTATOR = >=,
            NEGATOR = >,
            RESTRICT = scalarlesel,
            JOIN = scalarlejoinsel
        );

        CREATE OPERATOR sys.> (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_gt,
            COMMUTATOR = <,
            NEGATOR = <=,
            RESTRICT = scalargtsel,
            JOIN = scalargtjoinsel
        );

        CREATE OPERATOR sys.>= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_geq,
            COMMUTATOR = <=,
            NEGATOR = <,
            RESTRICT = scalargesel,
            JOIN = scalargejoinsel
        );

        ALTER OPERATOR FAMILY bbf_varbinary_ops USING btree ADD
            OPERATOR 1 sys.< (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 2 sys.<= (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 3 sys.= (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 4 sys.>= (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 5 sys.> (sys.bbf_varbinary, sys.bbf_binary),
            FUNCTION 1 sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary);

    ELSIF bbf_varbinary_ops_c = 6 THEN
        RAISE NOTICE 'Adding comparison operators to bbf_varbinary_ops (equality already exists)';

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_neq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_neq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_lt(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_lt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_leq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_leq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_gt(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_gt'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OR REPLACE FUNCTION sys.varbinary_binary_geq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
        RETURNS boolean AS 'babelfishpg_common', 'varbinary_geq'
        LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

        CREATE OPERATOR sys.<> (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_neq,
            COMMUTATOR = <>,
            NEGATOR = =,
            RESTRICT = neqsel,
            JOIN = neqjoinsel
        );

        CREATE OPERATOR sys.< (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_lt,
            COMMUTATOR = >,
            NEGATOR = >=,
            RESTRICT = scalarltsel,
            JOIN = scalarltjoinsel
        );

        CREATE OPERATOR sys.<= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_leq,
            COMMUTATOR = >=,
            NEGATOR = >,
            RESTRICT = scalarlesel,
            JOIN = scalarlejoinsel
        );

        CREATE OPERATOR sys.> (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_gt,
            COMMUTATOR = <,
            NEGATOR = <=,
            RESTRICT = scalargtsel,
            JOIN = scalargtjoinsel
        );

        CREATE OPERATOR sys.>= (
            LEFTARG = sys.bbf_varbinary,
            RIGHTARG = sys.bbf_binary,
            FUNCTION = sys.varbinary_binary_geq,
            COMMUTATOR = <=,
            NEGATOR = <,
            RESTRICT = scalargesel,
            JOIN = scalargejoinsel
        );

        ALTER OPERATOR FAMILY bbf_varbinary_ops USING btree ADD
            OPERATOR 1 sys.< (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 2 sys.<= (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 4 sys.>= (sys.bbf_varbinary, sys.bbf_binary),
            OPERATOR 5 sys.> (sys.bbf_varbinary, sys.bbf_binary);

    ELSIF bbf_varbinary_ops_c = 10 THEN
        RAISE NOTICE 'All cross-type operators already installed in bbf_varbinary_ops';

    ELSE
        RAISE EXCEPTION 'Unexpected operator count in bbf_varbinary_ops: % (expected 5, 6, or 10)', bbf_varbinary_ops_c;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION get_bbf_binary_ops_count(varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
