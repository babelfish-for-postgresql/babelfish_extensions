CREATE TYPE sys.UNIQUEIDENTIFIER;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierin(cstring)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'uniqueidentifier_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierout(sys.UNIQUEIDENTIFIER)
RETURNS cstring
AS 'babelfishpg_common', 'uniqueidentifier_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifierrecv(internal)
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.uniqueidentifiersend(sys.UNIQUEIDENTIFIER)
RETURNS bytea
AS 'uuid_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.UNIQUEIDENTIFIER (
	INPUT          = sys.uniqueidentifierin,
	OUTPUT         = sys.uniqueidentifierout,
	RECEIVE        = sys.uniqueidentifierrecv,
	SEND           = sys.uniqueidentifiersend,
	INTERNALLENGTH = 16,
	ALIGNMENT      = 'int4',
	STORAGE        = 'plain',
	CATEGORY       = 'U',
	PREFERRED      = false,
	COLLATABLE     = false
);

CREATE OR REPLACE FUNCTION sys.newid()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4' -- uuid-ossp was added as dependency
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

/*
 * in tsql, NEWSEQUENTIALID() produces a new unique value
 * greater than a sequence of previous values. Since PG does not
 * have this capability, we will reuse the NEWID() functionality and be
 * aware of the functional shortcoming
 */
CREATE OR REPLACE FUNCTION sys.NEWSEQUENTIALID()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifiereq(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierne(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierlt(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierle(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifiergt(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.uniqueidentifierge(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS bool
AS 'uuid_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.uniqueidentifiereq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.uniqueidentifierne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.uniqueidentifierlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.uniqueidentifierle,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.uniqueidentifiergt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.UNIQUEIDENTIFIER,
    RIGHTARG   = sys.UNIQUEIDENTIFIER,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.uniqueidentifierge,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE FUNCTION  uniqueidentifier_cmp(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER)
RETURNS INT4
AS 'uuid_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION  uniqueidentifier_hash(sys.UNIQUEIDENTIFIER)
RETURNS INT4
AS 'uuid_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.uniqueidentifier_ops
DEFAULT FOR TYPE sys.UNIQUEIDENTIFIER USING btree AS
    OPERATOR    1   <  (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR    2   <= (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR    3   =  (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR    4   >= (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    OPERATOR    5   >  (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    FUNCTION    1   uniqueidentifier_cmp(sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER);

CREATE OPERATOR CLASS sys.uniqueidentifier_ops
DEFAULT FOR TYPE sys.UNIQUEIDENTIFIER USING hash AS
    OPERATOR    1   =  (sys.UNIQUEIDENTIFIER, sys.UNIQUEIDENTIFIER),
    FUNCTION    1   uniqueidentifier_hash(sys.UNIQUEIDENTIFIER);

CREATE FUNCTION sys.varchar2uniqueidentifier(pg_catalog.VARCHAR, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varchar2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST  (pg_catalog.VARCHAR as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varchar2uniqueidentifier(pg_catalog.VARCHAR, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.varchar2uniqueidentifier(sys.VARCHAR, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varchar2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST  (sys.VARCHAR as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varchar2uniqueidentifier(sys.VARCHAR, integer, boolean) AS ASSIGNMENT;


CREATE FUNCTION sys.varbinary2uniqueidentifier(sys.bbf_varbinary, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varbinary2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.bbf_varbinary as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.varbinary2uniqueidentifier(sys.bbf_varbinary, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.binary2uniqueidentifier(sys.bbf_binary, integer, boolean)
RETURNS sys.UNIQUEIDENTIFIER
AS 'babelfishpg_common', 'varbinary2uniqueidentifier'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.bbf_binary as sys.UNIQUEIDENTIFIER)
WITH FUNCTION sys.binary2uniqueidentifier(sys.bbf_binary, integer, boolean) AS ASSIGNMENT;

CREATE FUNCTION sys.uniqueidentifier2varbinary(sys.UNIQUEIDENTIFIER, integer, boolean)
RETURNS sys.bbf_varbinary
AS 'babelfishpg_common', 'uniqueidentifier2varbinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER as sys.bbf_varbinary)
WITH FUNCTION sys.uniqueidentifier2varbinary(sys.UNIQUEIDENTIFIER, integer, boolean) AS IMPLICIT;

CREATE FUNCTION sys.uniqueidentifier2binary(sys.UNIQUEIDENTIFIER, integer, boolean)
RETURNS sys.bbf_binary
AS 'babelfishpg_common', 'uniqueidentifier2binary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.UNIQUEIDENTIFIER as sys.bbf_binary)
WITH FUNCTION sys.uniqueidentifier2binary(sys.UNIQUEIDENTIFIER, integer, boolean) AS IMPLICIT;
