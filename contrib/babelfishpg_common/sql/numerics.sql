CREATE DOMAIN sys.TINYINT AS SMALLINT CHECK (VALUE >= 0 AND VALUE <= 255);
CREATE DOMAIN sys.INT AS INTEGER;
CREATE DOMAIN sys.BIGINT AS BIGINT;
CREATE DOMAIN sys.REAL AS REAL;
CREATE DOMAIN sys.FLOAT AS DOUBLE PRECISION;

-- Types with different default typmod behavior
SET enable_domain_typmod = TRUE;
CREATE DOMAIN sys.DECIMAL AS NUMERIC;
RESET enable_domain_typmod;

-- Domain Self Cast Functions to support Typmod Cast in Domain
CREATE OR REPLACE FUNCTION sys.decimal(sys.nchar, integer, boolean)
RETURNS sys.nchar
AS 'numeric'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.tinyintxor(leftarg sys.tinyint, rightarg sys.tinyint)
RETURNS sys.tinyint
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS sys.tinyint);
$$
LANGUAGE SQL;

CREATE OPERATOR sys.^ (
    LEFTARG = sys.tinyint,
    RIGHTARG = sys.tinyint,
    FUNCTION = sys.tinyintxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int2xor(leftarg int2, rightarg int2)
RETURNS int2
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS int2);
$$
LANGUAGE SQL;

CREATE OPERATOR sys.^ (
    LEFTARG = int2,
    RIGHTARG = int2,
    FUNCTION = sys.int2xor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.intxor(leftarg int4, rightarg int4)
RETURNS int4
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(32)),
                    CAST(rightarg AS pg_catalog.bit(32))) AS int4)
$$
LANGUAGE SQL;

CREATE OPERATOR sys.^ (
    LEFTARG = int4,
    RIGHTARG = int4,
    FUNCTION = sys.intxor,
    COMMUTATOR = ^
);

CREATE OR REPLACE FUNCTION sys.int8xor(leftarg int8, rightarg int8)
RETURNS int8
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(64)),
                    CAST(rightarg AS pg_catalog.bit(64))) AS int8)
$$
LANGUAGE SQL;

CREATE OPERATOR sys.^ (
    LEFTARG = int8,
    RIGHTARG = int8,
    FUNCTION = sys.int8xor,
    COMMUTATOR = ^
);
