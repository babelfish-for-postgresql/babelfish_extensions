CREATE TYPE sys.VARCHAR;

-- Basic functions
CREATE OR REPLACE FUNCTION sys.varcharin(cstring)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varcharin'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharout(sys.VARCHAR)
RETURNS cstring
AS 'varcharout'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharrecv(internal)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varcharrecv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varcharsend(sys.VARCHAR)
RETURNS bytea
AS 'varcharsend'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.VARCHAR (
    INPUT       = sys.varcharin,
    OUTPUT      = sys.varcharout,
    RECEIVE     = sys.varcharrecv,
    SEND        = sys.varcharsend,
    TYPMOD_IN   = varchartypmodin,
    TYPMOD_OUT  = varchartypmodout,
    CATEGORY    = 'S',
    COLLATABLE  = True,
    LIKE        = pg_catalog.VARCHAR
);

-- Basic operator functions
CREATE FUNCTION sys.varchareq(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varchareq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharne(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharlt(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharlt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharle(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharle'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varchargt(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varchargt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varcharge(sys.VARCHAR, sys.VARCHAR)
RETURNS bool
AS 'babelfishpg_common', 'varcharge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- Basic operators
-- Note that if those operators are not in pg_catalog, we will see different behaviors depending on sql_dialect
CREATE OPERATOR pg_catalog.= (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    COMMUTATOR = OPERATOR(pg_catalog.=),
    NEGATOR    = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.varchareq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES,
    HASHES
);

CREATE OPERATOR pg_catalog.<> (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    NEGATOR    = OPERATOR(pg_catalog.=),
    COMMUTATOR = OPERATOR(pg_catalog.<>),
    PROCEDURE  = sys.varcharne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR pg_catalog.< (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    NEGATOR    = OPERATOR(pg_catalog.>=),
    COMMUTATOR = OPERATOR(pg_catalog.>),
    PROCEDURE  = sys.varcharlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR pg_catalog.<= (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    NEGATOR    = OPERATOR(pg_catalog.>),
    COMMUTATOR = OPERATOR(pg_catalog.>=),
    PROCEDURE  = sys.varcharle,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR pg_catalog.> (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    NEGATOR    = OPERATOR(pg_catalog.<=),
    COMMUTATOR = OPERATOR(pg_catalog.<),
    PROCEDURE  = sys.varchargt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR pg_catalog.>= (
    LEFTARG    = sys.VARCHAR,
    RIGHTARG   = sys.VARCHAR,
    NEGATOR    = OPERATOR(pg_catalog.<),
    COMMUTATOR = OPERATOR(pg_catalog.<=),
    PROCEDURE  = sys.varcharge,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

-- Operator classes
CREATE FUNCTION  sys.varcharcmp(sys.VARCHAR, sys.VARCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'varcharcmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.hashvarchar(sys.VARCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'hashvarchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS varchar_ops
    DEFAULT FOR TYPE sys.VARCHAR USING btree AS
    OPERATOR    1   pg_catalog.<  (sys.VARCHAR, sys.VARCHAR),
    OPERATOR    2   pg_catalog.<= (sys.VARCHAR, sys.VARCHAR),
    OPERATOR    3   pg_catalog.=  (sys.VARCHAR, sys.VARCHAR),
    OPERATOR    4   pg_catalog.>= (sys.VARCHAR, sys.VARCHAR),
    OPERATOR    5   pg_catalog.>  (sys.VARCHAR, sys.VARCHAR),
    FUNCTION    1   sys.varcharcmp(sys.VARCHAR, sys.VARCHAR);

CREATE OPERATOR CLASS varchar_ops
    DEFAULT FOR TYPE sys.VARCHAR USING hash AS
    OPERATOR    1   pg_catalog.=  (sys.VARCHAR, sys.VARCHAR),
    FUNCTION    1   sys.hashvarchar(sys.VARCHAR);

-- Typmode cast function
CREATE OR REPLACE FUNCTION sys.varchar(sys.VARCHAR, integer, boolean)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- To sys.VARCHAR
CREATE CAST (sys.VARCHAR AS sys.VARCHAR)
WITH FUNCTION sys.VARCHAR (sys.VARCHAR, integer, boolean) AS IMPLICIT;

CREATE CAST (pg_catalog.VARCHAR as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.TEXT as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.BPCHAR as sys.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (pg_catalog.BOOL as sys.VARCHAR)
WITH FUNCTION pg_catalog.text(pg_catalog.BOOL) AS ASSIGNMENT;

-- From sys.VARCHAR
CREATE CAST (sys.VARCHAR AS pg_catalog.VARCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.VARCHAR as pg_catalog.TEXT)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.VARCHAR as pg_catalog.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (sys.VARCHAR as sys.BPCHAR)
WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2int2(sys.VARCHAR)
RETURNS INT2
AS 'babelfishpg_common', 'varchar2int2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS INT2)
WITH FUNCTION sys.varchar2int2(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2int4(sys.VARCHAR)
RETURNS INT4
AS 'babelfishpg_common', 'varchar2int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS INT4)
WITH FUNCTION sys.varchar2int4(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2int8(sys.VARCHAR)
RETURNS INT8
AS 'babelfishpg_common', 'varchar2int8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS INT8)
WITH FUNCTION sys.varchar2int8(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2float4(sys.VARCHAR)
RETURNS FLOAT4
AS 'babelfishpg_common', 'varchar2float4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS FLOAT4)
WITH FUNCTION sys.varchar2float4(sys.VARCHAR) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.varchar2float8(sys.VARCHAR)
RETURNS FLOAT8
AS 'babelfishpg_common', 'varchar2float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS FLOAT8)
WITH FUNCTION sys.varchar2float8(sys.VARCHAR) AS IMPLICIT;

SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.NVARCHAR AS sys.VARCHAR;
RESET enable_domain_typmod;

CREATE OR REPLACE FUNCTION sys.nvarchar(sys.nvarchar, integer, boolean)
RETURNS sys.nvarchar
AS 'babelfishpg_common', 'varchar'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

SET client_min_messages = 'ERROR';
CREATE CAST (sys.nvarchar AS sys.nvarchar)
WITH FUNCTION sys.nvarchar (sys.nvarchar, integer, BOOLEAN) AS ASSIGNMENT;
SET client_min_messages = 'WARNING';
