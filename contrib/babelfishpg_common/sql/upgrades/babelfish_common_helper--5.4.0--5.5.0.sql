------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.ncharvarbinary(sys.NCHAR, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'ncharvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varbinarysysbpchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_VARBINARY AS sys.BPCHAR)
    WITH FUNCTION sys.varbinarysysbpchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.varbinarybpchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS pg_catalog.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_VARBINARY AS pg_catalog.BPCHAR)
    WITH FUNCTION sys.varbinarybpchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.varbinarysysnchar(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'varbinarynchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ncharbinary(sys.NCHAR, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'ncharbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.binarysysbpchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_BINARY AS sys.BPCHAR)
    WITH FUNCTION sys.binarysysbpchar (sys.BBF_BINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binarybpchar(sys.BBF_BINARY, integer, boolean)
RETURNS pg_catalog.BPCHAR
AS 'babelfishpg_common', 'varbinarybpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
DECLARE
    exception_message text;
BEGIN
    CREATE CAST (sys.BBF_BINARY AS pg_catalog.BPCHAR)
    WITH FUNCTION sys.binarybpchar (sys.BBF_BINARY, integer, boolean) AS IMPLICIT;
EXCEPTION WHEN duplicate_object THEN
    GET STACKED DIAGNOSTICS
    exception_message = MESSAGE_TEXT;
    RAISE WARNING '%', exception_message;
END;
$$;

CREATE OR REPLACE FUNCTION sys.binarysysnchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.NCHAR
AS 'babelfishpg_common', 'varbinarynchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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
CREATE OR REPLACE FUNCTION sys.get_bbf_binary_ops_count(opffamily varchar) 
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
    bbf_binary_ops_c INT := (SELECT * FROM sys.get_bbf_binary_ops_count('bbf_binary_ops'));
BEGIN
    IF bbf_binary_ops_c = 6 THEN

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
        -- All cross-type operators already installed
        RAISE NOTICE 'All operators of bbf_binary_ops are installed';

    ELSE
        RAISE EXCEPTION 'Unexpected operator count in bbf_binary_ops: %', bbf_binary_ops_c;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add cross-type operators for bbf_varbinary op bbf_binary
DO $$
DECLARE 
    bbf_varbinary_ops_c INT := (SELECT * FROM sys.get_bbf_binary_ops_count('bbf_varbinary_ops'));
BEGIN

    IF bbf_varbinary_ops_c = 6 THEN

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
        -- All cross-type operators already installed
        RAISE NOTICE 'All operators of bbf_varbinary_ops are installed';

    ELSE
        RAISE EXCEPTION 'Unexpected operator count in bbf_varbinary_ops: % (expected 5, 6, or 10)', bbf_varbinary_ops_c;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION sys.get_bbf_binary_ops_count(varchar);

CREATE OR REPLACE FUNCTION sys.binaryadd(leftarg sys.BBF_BINARY, rightarg sys.BBF_BINARY)
RETURNS sys.BBF_BINARY
AS 'byteacat'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_operator WHERE oprleft = 'sys.BBF_BINARY'::pg_catalog.regtype and oprright = 'sys.BBF_BINARY'::pg_catalog.regtype and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN
CREATE OPERATOR sys.+ (
	LEFTARG    = sys.BBF_BINARY,
	RIGHTARG   = sys.BBF_BINARY,
	PROCEDURE  = sys.binaryadd
);
END IF;
END $$;
