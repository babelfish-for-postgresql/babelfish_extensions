CREATE TYPE sys.DATE;

CREATE OR REPLACE FUNCTION sys.datein(cstring)
RETURNS sys.DATE
AS 'babelfishpg_common', 'date_in_tsql'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.dateout(sys.DATE)
RETURNS cstring
AS 'date_out'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.daterecv(internal)
RETURNS sys.DATE
AS 'date_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datesend(sys.DATE)
RETURNS bytea
AS 'date_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATE (
	INPUT          = sys.datein,
	OUTPUT         = sys.dateout,
	RECEIVE        = sys.daterecv,
	SEND           = sys.datesend,
	INTERNALLENGTH = 3,
	ALIGNMENT      = 'double',
	STORAGE        = 'plain',
	CATEGORY       = 'D',
	PREFERRED      = false,
	COLLATABLE     = false,
    PASSEDBYVALUE
);

CREATE FUNCTION sys.dateeq(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datene(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datelt(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datele(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.dategt(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datege(sys.DATE, sys.DATE)
RETURNS bool
AS 'date_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.dateeq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.datene,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.datelt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.datele,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.dategt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.DATE,
    RIGHTARG   = sys.DATE,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.datege,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

CREATE FUNCTION  date_cmp(sys.DATE, sys.DATE)
RETURNS INT4
AS 'date_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.date_ops
DEFAULT FOR TYPE sys.DATE USING btree AS
    OPERATOR    1   <  (sys.DATE, sys.DATE),
    OPERATOR    2   <= (sys.DATE, sys.DATE),
    OPERATOR    3   =  (sys.DATE, sys.DATE),
    OPERATOR    4   >= (sys.DATE, sys.DATE),
    OPERATOR    5   >  (sys.DATE, sys.DATE),
    FUNCTION    1   date_cmp(sys.DATE, sys.DATE);

CREATE OR REPLACE FUNCTION sys.date_larger(sys.DATE, sys.DATE)
RETURNS sys.DATE
AS 'date_larger'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date_smaller(sys.DATE, sys.DATE)
RETURNS sys.DATE
AS 'date_smaller'
LANGUAGE INTERNAL IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE AGGREGATE sys.max(sys.DATE)
(
    sfunc = sys.date_larger,
    stype = sys.date,
    combinefunc = sys.date_larger,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATE)
(
    sfunc = sys.date_smaller,
    stype = sys.date,
    combinefunc = sys.date_smaller,
    parallel = safe
);

-- cast TO date
CREATE OR REPLACE FUNCTION sys.timestamp2date(TIMESTAMP)
RETURNS DATE
AS 'babelfishpg_common', 'timestamp_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS DATE)
WITH FUNCTION sys.timestamp2date(TIMESTAMP) AS ASSIGNMENT;
-- CREATE CAST (TIMESTAMP AS DATE)
-- WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.timestamptz2date(TIMESTAMPTZ)
RETURNS DATE
AS 'babelfishpg_common', 'timestamptz_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMPTZ AS DATE)
WITH FUNCTION sys.timestamptz2date (TIMESTAMPTZ) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime2date(DATETIME)
RETURNS DATE
AS 'babelfishpg_common', 'datetime_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS DATE)
WITH FUNCTION sys.datetime2date (DATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.datetime22date(DATETIME2)
RETURNS DATE
AS 'babelfishpg_common', 'datetime2_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME2 AS DATE)
WITH FUNCTION sys.datetime22date (DATETIME2) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2date(SMALLDATETIME)
RETURNS DATE
AS 'babelfishpg_common', 'smalldatetime_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS DATE)
WITH FUNCTION sys.smalldatetime2date (SMALLDATETIME) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.char2date(CHAR)
RETURNS SYS.DATE
AS 'babelfishpg_common', 'char_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS DATE)
WITH FUNCTION sys.char2date (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2date(sys.BPCHAR)
RETURNS sys.DATE
AS 'babelfishpg_common', 'char_date'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.DATE)
WITH FUNCTION sys.bpchar2date (sys.BPCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.date2timestamptz(DATE)
RETURNS TIMESTAMPTZ
AS 'date_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS TIMESTAMPTZ)
WITH FUNCTION sys.date2timestamptz (DATE) AS IMPLICIT;
