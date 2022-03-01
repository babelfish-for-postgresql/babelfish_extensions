-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '1.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

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

CREATE OR REPLACE FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, boolean)
RETURNS sys.BBF_VARBINARY
AS 'babelfishpg_common', 'varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- typmod cast for sys.BBF_VARBINARY
CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_VARBINARY)
WITH FUNCTION sys.bbfvarbinary(sys.BBF_VARBINARY, integer, BOOLEAN) AS ASSIGNMENT;

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


CREATE OR REPLACE FUNCTION sys.rowversionsysvarchar(sys.ROWVERSION)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS sys.VARCHAR)
WITH FUNCTION sys.rowversionsysvarchar (sys.ROWVERSION) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.rowversionvarchar(sys.ROWVERSION)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'varbinaryvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.ROWVERSION AS pg_catalog.VARCHAR)
WITH FUNCTION sys.rowversionvarchar (sys.ROWVERSION) AS ASSIGNMENT;

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


CREATE OR REPLACE FUNCTION sys.int8fixeddecimaldiv_money(INT8, FIXEDDECIMAL)
RETURNS sys.MONEY
AS $$
  SELECT sys.int8fixeddecimaldiv($1, $2)::sys.MONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4fixeddecimaldiv_money(INT4, FIXEDDECIMAL)
RETURNS sys.MONEY
AS $$
  SELECT sys.int4fixeddecimaldiv($1, $2)::sys.MONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int2fixeddecimaldiv_money(INT2, FIXEDDECIMAL)
RETURNS sys.MONEY
AS $$
  SELECT sys.int2fixeddecimaldiv($1, $2)::sys.MONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;


DROP OPERATOR IF EXISTS sys./ (INT8, FIXEDDECIMAL);

CREATE OPERATOR sys./ (
    LEFTARG    = INT8,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int8fixeddecimaldiv_money
);

DROP OPERATOR IF EXISTS sys./ (INT4, FIXEDDECIMAL);

CREATE OPERATOR sys./ (
    LEFTARG    = INT4,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int4fixeddecimaldiv_money
);

DROP OPERATOR IF EXISTS sys./ (INT2, FIXEDDECIMAL);

CREATE OPERATOR sys./ (
    LEFTARG    = INT2,
    RIGHTARG   = FIXEDDECIMAL,
    PROCEDURE  = int2fixeddecimaldiv_money
);

CREATE FUNCTION sys.fixeddecimalum(sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalum'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalpl(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalmi(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalmul(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimaldiv(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = fixeddecimalmi
);

CREATE OPERATOR sys.- (
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = fixeddecimalum
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = fixeddecimaldiv
);

CREATE FUNCTION sys.fixeddecimalint8pl(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint8pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8mi(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint8mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8mul(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint8mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint8div(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint8div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT8,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint8pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT8,
    PROCEDURE  = fixeddecimalint8mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT8,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint8mul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT8,
    PROCEDURE  = fixeddecimalint8div
);

CREATE FUNCTION sys.fixeddecimalint4pl(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint4pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4mi(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint4mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4mul(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint4mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint4div(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint4div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT4,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint4pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT4,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint4mul
);


CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT4,
    PROCEDURE  = fixeddecimalint4div
);

CREATE FUNCTION sys.fixeddecimalint2pl(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint2pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2mi(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint2mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2mul(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint2mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.fixeddecimalint2div(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalint2div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT2,
    COMMUTATOR = +,
    PROCEDURE  = fixeddecimalint2pl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2mi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT2,
    COMMUTATOR = *,
    PROCEDURE  = fixeddecimalint2mul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = INT2,
    PROCEDURE  = fixeddecimalint2div
);


CREATE FUNCTION sys.int8fixeddecimalpl(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimalmi(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimalmul(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimaldiv(INT8, sys.SMALLMONEY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int8fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int8fixeddecimaldiv_smallmoney(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int8fixeddecimaldiv($1, $2)::sys.SMALLMONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = INT8,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = int8fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT8,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int8fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT8,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = int8fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT8,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int8fixeddecimaldiv_smallmoney
);

CREATE FUNCTION sys.int4fixeddecimalpl(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimalmi(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimalmul(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimaldiv(INT4, sys.SMALLMONEY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int4fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4fixeddecimaldiv_smallmoney(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int4fixeddecimaldiv($1, $2)::sys.SMALLMONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;


CREATE OPERATOR sys.+ (
    LEFTARG    = INT4,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = int4fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT4,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int4fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT4,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = int4fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT4,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int4fixeddecimaldiv_smallmoney
);

CREATE FUNCTION sys.int2fixeddecimalpl(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2fixeddecimalpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimalmi(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2fixeddecimalmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimalmul(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2fixeddecimalmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimaldiv(INT2, sys.SMALLMONEY)
RETURNS DOUBLE PRECISION
AS 'babelfishpg_money', 'int2fixeddecimaldiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int2fixeddecimaldiv_smallmoney(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimaldiv($1, $2)::sys.SMALLMONEY;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = INT2,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = int2fixeddecimalpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT2,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int2fixeddecimalmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = INT2,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = int2fixeddecimalmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = INT2,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = int2fixeddecimaldiv_smallmoney
);


-- tinyint operator definitions to force return type to tinyyint

CREATE FUNCTION sys.tinyintum(sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2um($1)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintpl(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2pl($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintmi(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2mi($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintmul(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2mul($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintdiv(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS $$
  SELECT int2div($1,$2)::sys.TINYINT;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = +,
    PROCEDURE  = sys.tinyintpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintmi
);

CREATE OPERATOR sys.- (
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintum
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = *,
    PROCEDURE  = sys.tinyintmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.tinyintdiv
);

CREATE FUNCTION sys.smallmoneytinyintpl(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2pl($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintmi(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2mi($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintmul(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2mul($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneytinyintdiv(sys.SMALLMONEY, sys.TINYINT)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.fixeddecimalint2div($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = +,
    PROCEDURE  = sys.smallmoneytinyintpl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.smallmoneytinyintmi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    COMMUTATOR = *,
    PROCEDURE  = sys.smallmoneytinyintmul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.SMALLMONEY,
    RIGHTARG   = sys.TINYINT,
    PROCEDURE  = sys.smallmoneytinyintdiv
);

CREATE FUNCTION sys.tinyintsmallmoneypl(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalpl($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneymi(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalmi($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneymul(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimalmul($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.tinyintsmallmoneydiv(sys.TINYINT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS $$
  SELECT sys.int2fixeddecimaldiv($1,$2)::sys.SMALLMONEY;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = +,
    PROCEDURE  = sys.tinyintsmallmoneypl
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = sys.tinyintsmallmoneymi
);

CREATE OPERATOR sys.* (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    COMMUTATOR = *,
    PROCEDURE  = sys.tinyintsmallmoneymul
);

CREATE OPERATOR sys./ (
    LEFTARG    = sys.TINYINT,
    RIGHTARG   = sys.SMALLMONEY,
    PROCEDURE  = sys.tinyintsmallmoneydiv
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper_outer(leftarg text, rightarg text) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

DROP OPERATOR IF EXISTS sys.+(text, text);

CREATE OPERATOR sys.+ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = sys.babelfish_concat_wrapper_outer
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.varchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.varchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.bpchar, rightarg sys.bpchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.bpchar,
    RIGHTARG = sys.bpchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nchar, rightarg sys.nchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nchar,
    RIGHTARG = sys.nchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

-- if one of input is nvarchar, resolve it as nvarchar. as varchar is a base type of nvarchar, we need to define this function explictly.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.varchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.varchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.varchar_larger(sys.VARCHAR, sys.VARCHAR)
RETURNS sys.VARCHAR
AS 'text_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar_smaller(sys.VARCHAR, sys.VARCHAR)
RETURNS sys.VARCHAR
AS 'text_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.VARCHAR)
(
  sfunc = sys.varchar_larger,
  stype = sys.varchar,
  combinefunc = sys.varchar_larger,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.VARCHAR)
(
  sfunc = sys.varchar_smaller,
  stype = sys.varchar,
  combinefunc = sys.varchar_smaller,
  parallel = safe
);

CREATE OR REPLACE FUNCTION sys.nvarchar_larger(sys.NVARCHAR, sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 'text_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nvarchar_smaller(sys.NVARCHAR, sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS 'text_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.NVARCHAR)
(
  sfunc = sys.nvarchar_larger,
  stype = sys.nvarchar,
  combinefunc = sys.nvarchar_larger,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.NVARCHAR)
(
  sfunc = sys.nvarchar_smaller,
  stype = sys.nvarchar,
  combinefunc = sys.nvarchar_smaller,
  parallel = safe
);

CREATE OR REPLACE FUNCTION sys.bpchar_larger(sys.BPCHAR, sys.BPCHAR)
RETURNS sys.BPCHAR
AS 'bpchar_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar_smaller(sys.BPCHAR, sys.BPCHAR)
RETURNS sys.BPCHAR
AS 'bpchar_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.BPCHAR)
(
  sfunc = sys.bpchar_larger,
  stype = sys.bpchar,
  combinefunc = sys.bpchar_larger,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.BPCHAR)
(
  sfunc = sys.bpchar_smaller,
  stype = sys.bpchar,
  combinefunc = sys.bpchar_smaller,
  parallel = safe
);

CREATE OR REPLACE FUNCTION sys.nchar_larger(sys.NCHAR, sys.NCHAR)
RETURNS sys.NCHAR
AS 'bpchar_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar_smaller(sys.NCHAR, sys.NCHAR)
RETURNS sys.NCHAR
AS 'bpchar_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.NCHAR)
(
  sfunc = sys.nchar_larger,
  stype = sys.nchar,
  combinefunc = sys.nchar_larger,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.NCHAR)
(
  sfunc = sys.nchar_smaller,
  stype = sys.nchar,
  combinefunc = sys.nchar_smaller,
  parallel = safe
);

CREATE OR REPLACE FUNCTION sys.tinyint_larger(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS 'int2larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.tinyint_smaller(sys.TINYINT, sys.TINYINT)
RETURNS sys.TINYINT
AS 'int2smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.TINYINT)
(
    sfunc = sys.tinyint_larger,
    stype = sys.tinyint,
    combinefunc = sys.tinyint_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.TINYINT)
(
    sfunc = sys.tinyint_smaller,
    stype = sys.tinyint,
    combinefunc = sys.tinyint_smaller,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.real_larger(sys.REAL, sys.REAL)
RETURNS sys.REAL
AS 'float4larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.real_smaller(sys.REAL, sys.REAL)
RETURNS sys.REAL
AS 'float4smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.REAL)
(
    sfunc = sys.real_larger,
    stype = sys.real,
    combinefunc = sys.real_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.REAL)
(
    sfunc = sys.real_smaller,
    stype = sys.real,
    combinefunc = sys.real_smaller,
    parallel = safe
);

CREATE FUNCTION sys.smallmoneylarger(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimallarger'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smallmoneysmaller(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'fixeddecimalsmaller'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE AGGREGATE sys.min(sys.smallmoney) (
    SFUNC = sys.smallmoneysmaller,
    STYPE = sys.smallmoney,
    COMBINEFUNC = sys.smallmoneysmaller,
    PARALLEL = SAFE
);

CREATE AGGREGATE sys.max(sys.smallmoney) (
    SFUNC = sys.smallmoneylarger,
    STYPE = sys.smallmoney,
    COMBINEFUNC = sys.smallmoneylarger,
    PARALLEL = SAFE
);

CREATE OR REPLACE FUNCTION sys.datetime_larger(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'timestamp_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime_smaller(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'timestamp_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIME)
(
    sfunc = sys.datetime_larger,
    stype = sys.datetime,
    combinefunc = sys.datetime_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIME)
(
    sfunc = sys.datetime_smaller,
    stype = sys.datetime,
    combinefunc = sys.datetime_smaller,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.datetime2_larger(sys.DATETIME2, sys.DATETIME2)
RETURNS sys.DATETIME2
AS 'timestamp_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2_smaller(sys.DATETIME2, sys.DATETIME2)
RETURNS sys.DATETIME2
AS 'timestamp_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIME2)
(
    sfunc = sys.datetime2_larger,
    stype = sys.datetime2,
    combinefunc = sys.datetime2_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIME2)
(
    sfunc = sys.datetime2_smaller,
    stype = sys.datetime2,
    combinefunc = sys.datetime2_smaller,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.datetimeoffset_larger(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_larger'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset_smaller(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_smaller'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIMEOFFSET)
(
    sfunc = sys.datetimeoffset_larger,
    stype = sys.datetimeoffset,
    combinefunc = sys.datetimeoffset_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIMEOFFSET)
(
    sfunc = sys.datetimeoffset_smaller,
    stype = sys.datetimeoffset,
    combinefunc = sys.datetimeoffset_smaller,
    parallel = safe
);

CREATE OR REPLACE FUNCTION sys.smalldatetime_larger(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS sys.SMALLDATETIME
AS 'timestamp_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime_smaller(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS sys.SMALLDATETIME
AS 'timestamp_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.SMALLDATETIME)
(
    sfunc = sys.smalldatetime_larger,
    stype = sys.smalldatetime,
    combinefunc = sys.smalldatetime_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.SMALLDATETIME)
(
    sfunc = sys.smalldatetime_smaller,
    stype = sys.smalldatetime,
    combinefunc = sys.smalldatetime_smaller,
    parallel = safe
);

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



CREATE OR REPLACE FUNCTION sys.translate_pg_type_to_tsql(pgoid oid) RETURNS TEXT
AS 'babelfishpg_common', 'translate_pg_type_to_tsql'
LANGUAGE C PARALLEL SAFE IMMUTABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
