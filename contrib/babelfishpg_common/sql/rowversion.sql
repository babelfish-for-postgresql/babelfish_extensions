CREATE TYPE sys.ROWVERSION;

CREATE OR REPLACE FUNCTION sys.rowversionin(cstring, oid, integer)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varbinaryin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.rowversionout(sys.ROWVERSION)
RETURNS cstring
AS 'babelfishpg_common', 'varbinaryout'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.rowversionrecv(internal, oid, integer)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varbinaryrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.rowversionsend(sys.ROWVERSION)
RETURNS bytea
AS 'babelfishpg_common', 'varbinarysend'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.ROWVERSION (
    INPUT          = sys.rowversionin,
    OUTPUT         = sys.rowversionout,
    RECEIVE        = sys.rowversionrecv,
    SEND           = sys.rowversionsend,
    INTERNALLENGTH = 12,
    ALIGNMENT      = 'int4',
    STORAGE        = 'plain',
    CATEGORY       = 'U',
    PREFERRED      = false,
    COLLATABLE     = false
);

-- casting functions for sys.ROWVERSION

CREATE OR REPLACE FUNCTION sys.binaryrowversion(sys.BBF_BINARY, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varbinaryrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_BINARY AS sys.ROWVERSION)
WITH FUNCTION sys.binaryrowversion (sys.BBF_BINARY, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varbinaryrowversion(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varbinaryrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BBF_VARBINARY AS sys.ROWVERSION)
WITH FUNCTION sys.varbinaryrowversion (sys.BBF_VARBINARY, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionbinary(sys.ROWVERSION, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'rowversionbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS sys.BBF_BINARY)
WITH FUNCTION sys.rowversionbinary (sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionvarbinary(sys.ROWVERSION, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'rowversionvarbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS sys.BBF_VARBINARY)
WITH FUNCTION sys.rowversionvarbinary (sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varcharrowversion(sys.VARCHAR, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varcharrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS sys.ROWVERSION)
WITH FUNCTION sys.varcharrowversion (sys.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varcharrowversion(pg_catalog.VARCHAR, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'varcharrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS sys.ROWVERSION)
WITH FUNCTION sys.varcharrowversion (pg_catalog.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharrowversion(pg_catalog.BPCHAR, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'bpcharrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.BPCHAR AS sys.ROWVERSION)
WITH FUNCTION sys.bpcharrowversion (pg_catalog.BPCHAR, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpcharrowversion(sys.BPCHAR, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'bpcharrowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.ROWVERSION)
WITH FUNCTION sys.bpcharrowversion (sys.BPCHAR, integer, boolean) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.rowversionsysvarchar(sys.ROWVERSION, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS sys.VARCHAR)
WITH FUNCTION sys.rowversionsysvarchar(sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionvarchar(sys.ROWVERSION, integer, boolean)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS pg_catalog.VARCHAR)
WITH FUNCTION sys.rowversionvarchar (sys.ROWVERSION, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int2rowversion(INT2, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'int2rowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT2 AS sys.ROWVERSION)
WITH FUNCTION sys.int2rowversion (INT2, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.int4rowversion(INT4, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'int4rowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT4 AS sys.ROWVERSION)
WITH FUNCTION sys.int4rowversion (INT4, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.xid8rowversion(XID8, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'int8rowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (XID8 AS sys.ROWVERSION)
WITH FUNCTION sys.xid8rowversion (XID8, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.int8rowversion(INT8, integer, boolean)
RETURNS sys.ROWVERSION
AS 'babelfishpg_common', 'int8rowversion'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT8 AS sys.ROWVERSION)
WITH FUNCTION sys.int8rowversion (INT8, integer, boolean) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionint2(sys.ROWVERSION)
RETURNS INT2
AS 'babelfishpg_common', 'binaryint2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION as INT2)
WITH FUNCTION sys.rowversionint2 (sys.ROWVERSION) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionint4(sys.ROWVERSION)
RETURNS INT4
AS 'babelfishpg_common', 'binaryint4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION as INT4)
WITH FUNCTION sys.rowversionint4 (sys.ROWVERSION) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionint8(sys.ROWVERSION)
RETURNS INT8
AS 'babelfishpg_common', 'binaryint8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION as INT8)
WITH FUNCTION sys.rowversionint8 (sys.ROWVERSION) AS ASSIGNMENT;

CREATE DOMAIN sys.TIMESTAMP AS sys.ROWVERSION;

CREATE FUNCTION sys.rowversion_eq(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_eq,
    COMMUTATOR = =
);


CREATE FUNCTION sys.rowversion_neq(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_neq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_neq,
    COMMUTATOR = <>
);

CREATE FUNCTION sys.rowversion_gt(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.> (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_gt,
    COMMUTATOR = <
);

CREATE FUNCTION sys.rowversion_geq(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_geq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.>= (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_geq,
    COMMUTATOR = <=
);

CREATE FUNCTION sys.rowversion_lt(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.< (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_lt,
    COMMUTATOR = >
);

CREATE FUNCTION sys.rowversion_leq(leftarg sys.rowversion, rightarg sys.rowversion)
RETURNS boolean
AS 'babelfishpg_common', 'varbinary_leq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<= (
    LEFTARG = sys.rowversion,
    RIGHTARG = sys.rowversion,
    FUNCTION = sys.rowversion_leq,
    COMMUTATOR = >=
);

CREATE FUNCTION sys.rowversion_cmp(sys.rowversion, sys.rowversion)
RETURNS int
AS 'babelfishpg_common', 'varbinary_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.rowversion_ops
DEFAULT FOR TYPE sys.rowversion USING btree AS
    OPERATOR    1   <  (sys.rowversion, sys.rowversion),
    OPERATOR    2   <= (sys.rowversion, sys.rowversion),
    OPERATOR    3   =  (sys.rowversion, sys.rowversion),
    OPERATOR    4   >= (sys.rowversion, sys.rowversion),
    OPERATOR    5   >  (sys.rowversion, sys.rowversion),
    FUNCTION    1   sys.rowversion_cmp(sys.rowversion, sys.rowversion);

