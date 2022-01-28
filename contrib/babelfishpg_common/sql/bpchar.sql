CREATE TYPE sys.BPCHAR;

-- Basic functions
CREATE OR REPLACE FUNCTION sys.bpcharin(cstring)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpcharin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharout(sys.BPCHAR)
RETURNS cstring
AS 'bpcharout'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharrecv(internal)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpcharrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharsend(sys.BPCHAR)
RETURNS bytea
AS 'bpcharsend'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.BPCHAR (
    INPUT       = sys.bpcharin,
    OUTPUT      = sys.bpcharout,
    RECEIVE     = sys.bpcharrecv,
    SEND        = sys.bpcharsend,
    TYPMOD_IN   = bpchartypmodin,
    TYPMOD_OUT  = bpchartypmodout,
    CATEGORY    = 'S',
    COLLATABLE  = True,
    LIKE        = pg_catalog.BPCHAR
);

-- Basic operator functions
CREATE FUNCTION sys.bpchareq(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharlt(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharlt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharle(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharle'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchargt(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpchargt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharge(sys.BPCHAR, sys.BPCHAR)
RETURNS bool
AS 'bpcharge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

-- Basic operators
-- Note that if those operators are not in pg_catalog, we will see different behaviors depending on sql_dialect
CREATE OPERATOR pg_catalog.= (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR    = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpchareq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES,
    HASHES
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpcharne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR pg_catalog.< (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.>=),
    COMMUTATOR = OPERATOR(pg_catalog.>),
    PROCEDURE  = sys.bpcharlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR pg_catalog.<= (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.>),
    COMMUTATOR = OPERATOR(pg_catalog.>=),
    PROCEDURE  = sys.bpcharle,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR pg_catalog.> (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.<=),
    COMMUTATOR = OPERATOR(pg_catalog.<),
    PROCEDURE  = sys.bpchargt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR pg_catalog.>= (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.<),
    COMMUTATOR = OPERATOR(pg_catalog.<=),
    PROCEDURE  = sys.bpcharge,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

-- Operator classes
CREATE FUNCTION  sys.bpcharcmp(sys.BPCHAR, sys.BPCHAR)
RETURNS INT4
AS 'bpcharcmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.hashbpchar(sys.BPCHAR)
RETURNS INT4
AS 'hashbpchar'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS bpchar_ops
    DEFAULT FOR TYPE sys.BPCHAR USING btree AS
    OPERATOR    1   pg_catalog.<  (sys.BPCHAR, sys.BPCHAR),
    OPERATOR    2   pg_catalog.<= (sys.BPCHAR, sys.BPCHAR),
    OPERATOR    3   pg_catalog.=  (sys.BPCHAR, sys.BPCHAR),
    OPERATOR    4   pg_catalog.>= (sys.BPCHAR, sys.BPCHAR),
    OPERATOR    5   pg_catalog.>  (sys.BPCHAR, sys.BPCHAR),
    FUNCTION    1   sys.bpcharcmp(sys.BPCHAR, sys.BPCHAR);

CREATE OPERATOR CLASS bpchar_ops
    DEFAULT FOR TYPE sys.BPCHAR USING hash AS
    OPERATOR    1   pg_catalog.=  (sys.BPCHAR, sys.BPCHAR),
    FUNCTION    1   sys.hashbpchar(sys.BPCHAR);

CREATE OR REPLACE FUNCTION sys.bpchar(sys.BPCHAR, integer, boolean)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'bpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- To sys.BPCHAR
CREATE CAST (sys.BPCHAR AS sys.BPCHAR)
WITH FUNCTION sys.BPCHAR (sys.BPCHAR, integer, boolean) AS IMPLICIT;

CREATE CAST (pg_catalog.VARCHAR as sys.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.TEXT as sys.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.BOOL as sys.BPCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

-- From sys.BPCHAR
CREATE CAST (sys.BPCHAR AS pg_catalog.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as pg_catalog.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as pg_catalog.TEXT)
WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2int2(sys.BPCHAR)
RETURNS INT2
AS 'babelfishpg_common', 'bpchar2int2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS INT2)
WITH FUNCTION sys.bpchar2int2(sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2int4(sys.BPCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'bpchar2int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS INT4)
WITH FUNCTION sys.bpchar2int4(sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2int8(sys.BPCHAR)
RETURNS INT8
AS 'babelfishpg_common', 'bpchar2int8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS INT8)
WITH FUNCTION sys.bpchar2int8(sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2float4(sys.BPCHAR)
RETURNS FLOAT4
AS 'babelfishpg_common', 'bpchar2float4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS FLOAT4)
WITH FUNCTION sys.bpchar2float4(sys.BPCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.bpchar2float8(sys.BPCHAR)
RETURNS FLOAT8
AS 'babelfishpg_common', 'bpchar2float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS FLOAT8)
WITH FUNCTION sys.bpchar2float8(sys.BPCHAR) AS IMPLICIT;

-- Operators between different types
CREATE FUNCTION sys.bpchareq(sys.BPCHAR, pg_catalog.TEXT)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchareq(pg_catalog.TEXT, sys.BPCHAR)
RETURNS bool
AS 'bpchareq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(sys.BPCHAR, pg_catalog.TEXT)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpcharne(pg_catalog.TEXT, sys.BPCHAR)
RETURNS bool
AS 'bpcharne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR pg_catalog.= (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = pg_catalog.TEXT,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR    = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpchareq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel
);

CREATE OPERATOR pg_catalog.= (
    LEFTARG    = pg_catalog.TEXT,
    RIGHTARG   = sys.BPCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR    = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpchareq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG    = sys.BPCHAR,
    RIGHTARG   = pg_catalog.TEXT,
    NEGATOR    = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpcharne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG    = pg_catalog.TEXT,
    RIGHTARG   = sys.BPCHAR,
    NEGATOR    = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.bpcharne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.NCHAR AS sys.BPCHAR;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.nchar(sys.nchar, integer, boolean)
RETURNS sys.nchar
AS 'babelfishpg_common', 'bpchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


SET client_min_messages = 'ERROR';
CREATE CAST (sys.nchar AS sys.nchar)
WITH FUNCTION sys.nchar (sys.nchar, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';
