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
    INPUT          = sys.varbinaryin,
    OUTPUT         = sys.varbinaryout,
    RECEIVE        = sys.varbinaryrecv,
    SEND           = sys.varbinarysend,
    TYPMOD_IN      = sys.varbinarytypmodin,
    TYPMOD_OUT     = sys.varbinarytypmodout,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT      = 'int4',
    STORAGE        = 'extended',
    CATEGORY       = 'U',
    PREFERRED      = false,
    COLLATABLE     = false
);

CREATE OR REPLACE FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- typmod cast for sys.BBF_VARBINARY
CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_VARBINARY)
WITH FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, BOOLEAN) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.byteavarbinary(pg_catalog.BYTEA, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'byteavarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BYTEA AS sys.BBF_VARBINARY)
WITH FUNCTION sys.byteavarbinary(pg_catalog.BYTEA, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinarybytea(sys.BBF_VARBINARY, integer, boolean)
RETURNS pg_catalog.BYTEA
AS 'babelfishpg_common', 'byteavarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS pg_catalog.BYTEA)
WITH FUNCTION sys.varbinarybytea(sys.BBF_VARBINARY, integer, boolean) AS ASSIGNMENT;

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
WITH FUNCTION sys.varbinarysysvarchar (sys.BBF_VARBINARY, integer, boolean) AS IMPLICIT;

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

CREATE OR REPLACE FUNCTION sys.varbinaryfloat8(sys.BBF_VARBINARY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_common', 'varbinaryfloat8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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
    COMMUTATOR = =,
    RESTRICT = eqsel
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


CREATE OR REPLACE FUNCTION sys.int4varbinarydiv(leftarg int4 , rightarg sys.bbf_varbinary)
RETURNS int4
AS 'babelfishpg_common', 'int4varbinary_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR sys./ (
    LEFTARG = int4,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = int4varbinarydiv,
    COMMUTATOR = /
);

CREATE OR REPLACE FUNCTION sys.varbinaryint4div(leftarg sys.bbf_varbinary , rightarg int4)
RETURNS int4
AS 'babelfishpg_common', 'varbinaryint4_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR sys./ (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = int4,
    FUNCTION = varbinaryint4div,
    COMMUTATOR = /
);



CREATE FUNCTION sys.bbf_varbinary_cmp(sys.bbf_varbinary, sys.bbf_varbinary)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR CLASS sys.bbf_varbinary_ops
DEFAULT FOR TYPE sys.bbf_varbinary USING btree AS
    OPERATOR    1   <  (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR    2   <= (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR    3   =  (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR    4   >= (sys.bbf_varbinary, sys.bbf_varbinary),
    OPERATOR    5   >  (sys.bbf_varbinary, sys.bbf_varbinary),
    FUNCTION    1   sys.bbf_varbinary_cmp(sys.bbf_varbinary, sys.bbf_varbinary);

