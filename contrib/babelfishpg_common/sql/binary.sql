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
    INPUT          = sys.binaryin,
    OUTPUT         = sys.binaryout,
    RECEIVE        = sys.binaryrecv,
    SEND           = sys.binarysend,
    TYPMOD_IN      = sys.binarytypmodin,
    TYPMOD_OUT     = sys.binarytypmodout,
    INTERNALLENGTH = VARIABLE,
    ALIGNMENT      = 'int4',
    STORAGE        = 'extended',
    CATEGORY       = 'U',
    PREFERRED      = false,
    COLLATABLE     = false
);

CREATE OR REPLACE FUNCTION sys.varbinarybinary (sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE; 

CREATE CAST (sys.BBF_BINARY AS sys.BBF_VARBINARY)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_BINARY)
WITHOUT FUNCTION AS IMPLICIT;

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


CREATE OR REPLACE FUNCTION sys.binarysysvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.VARCHAR)
WITH FUNCTION sys.binarysysvarchar (sys.BBF_BINARY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.binaryvarchar(sys.BBF_BINARY, integer, boolean)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS pg_catalog.VARCHAR)
WITH FUNCTION sys.binaryvarchar(sys.BBF_BINARY, integer, boolean) AS ASSIGNMENT;

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

CREATE OR REPLACE FUNCTION sys.binaryfloat8(sys.BBF_BINARY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_common', 'binaryfloat8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

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
    COMMUTATOR = =,
    RESTRICT = eqsel
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
AS 'babelfishpg_common', 'varbinary_lt'
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
    OPERATOR    1   <  (sys.bbf_binary, sys.bbf_binary),
    OPERATOR    2   <= (sys.bbf_binary, sys.bbf_binary),
    OPERATOR    3   =  (sys.bbf_binary, sys.bbf_binary),
    OPERATOR    4   >= (sys.bbf_binary, sys.bbf_binary),
    OPERATOR    5   >  (sys.bbf_binary, sys.bbf_binary),
    FUNCTION    1   sys.bbf_binary_cmp(sys.bbf_binary, sys.bbf_binary);

CREATE OR REPLACE FUNCTION sys.binary_varbinary_eq(leftarg sys.bbf_binary, rightarg sys.bbf_varbinary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.bbf_binary,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = sys.binary_varbinary_eq,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

alter OPERATOR family bbf_binary_ops USING btree add
    OPERATOR 3 sys.= (sys.bbf_binary, sys.bbf_varbinary),
    FUNCTION 1 sys.bbf_binary_varbinary_cmp(sys.bbf_binary, sys.bbf_varbinary);

CREATE OR REPLACE FUNCTION sys.varbinary_binary_eq(leftarg sys.bbf_varbinary, rightarg sys.bbf_binary)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = sys.bbf_binary,
    FUNCTION = sys.varbinary_binary_eq,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

alter OPERATOR family bbf_varbinary_ops USING btree add
    OPERATOR 3 sys.= (sys.bbf_varbinary, sys.bbf_binary),
    FUNCTION 1 sys.bbf_varbinary_binary_cmp(sys.bbf_varbinary, sys.bbf_binary);
