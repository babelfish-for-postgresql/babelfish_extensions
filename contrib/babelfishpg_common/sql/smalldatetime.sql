CREATE TYPE sys.SMALLDATETIME;

CREATE OR REPLACE FUNCTION sys.smalldatetimein(cstring)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'smalldatetime_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimeout(sys.SMALLDATETIME)
RETURNS cstring
AS 'timestamp_out'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimerecv(internal)
RETURNS sys.SMALLDATETIME
AS 'timestamp_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetimesend(sys.SMALLDATETIME)
RETURNS bytea
AS 'timestamp_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalltypmodin(cstring[])
RETURNS integer
AS 'timestamptypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalltypmodout(integer)
RETURNS cstring
AS 'timestamptypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.SMALLDATETIME (
	INPUT          = sys.smalldatetimein,
	OUTPUT         = sys.smalldatetimeout,
	RECEIVE        = sys.smalldatetimerecv,
	SEND           = sys.smalldatetimesend,
    TYPMOD_IN      = sys.smalltypmodin,
    TYPMOD_OUT     = sys.smalltypmodout,
	INTERNALLENGTH = 8,
	ALIGNMENT      = 'double',
	STORAGE        = 'plain',
	CATEGORY       = 'D',
	PREFERRED      = false,
	COLLATABLE     = false,
    DEFAULT        = '1900-01-01 00:00',
    PASSEDBYVALUE
);

CREATE FUNCTION sys.smalldatetimeeq(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimene(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimelt(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimele(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimegt(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimege(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS bool
AS 'timestamp_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.smalldatetimeeq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.smalldatetimene,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.smalldatetimelt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.smalldatetimele,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.smalldatetimegt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.smalldatetimege,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

-- smalldate vs pg_catalog.date
CREATE FUNCTION sys.smalldatetime_eq_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_eq_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_ne_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_ne_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_lt_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_lt_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_le_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_le_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_gt_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_gt_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetime_ge_date(sys.SMALLDATETIME, pg_catalog.date)
RETURNS bool
AS 'timestamp_ge_date'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = smalldatetime_eq_date,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = smalldatetime_ne_date,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = smalldatetime_lt_date,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = smalldatetime_le_date,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = smalldatetime_gt_date,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.SMALLDATETIME,
    RIGHTARG   = pg_catalog.date,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = smalldatetime_ge_date,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

-- pg_catalog.date vs smalldate
CREATE FUNCTION sys.date_eq_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_eq_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_ne_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_ne_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_lt_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_lt_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_le_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_le_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_gt_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_gt_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.date_ge_smalldatetime(pg_catalog.date, sys.SMALLDATETIME)
RETURNS bool
AS 'date_ge_timestamp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = date_eq_smalldatetime,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = date_ne_smalldatetime,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = date_lt_smalldatetime,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = date_le_smalldatetime,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = date_gt_smalldatetime,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = pg_catalog.date,
    RIGHTARG   = sys.SMALLDATETIME,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = date_ge_smalldatetime,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);


-- smalldatetime <-> int/float operators for smalldatetime-int +/- arithmetic 
CREATE FUNCTION sys.smalldatetimeplint4(sys.smalldatetime, INT4)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_pl_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4plsmalldatetime(INT4, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'int4_pl_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.smalldatetimemiint4(sys.smalldatetime, INT4)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_mi_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4mismalldatetime(INT4, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'int4_mi_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = INT4,
    PROCEDURE  = sys.smalldatetimeplint4
);

CREATE OPERATOR sys.+ (
    LEFTARG    = INT4,
    RIGHTARG   = sys.smalldatetime,
    PROCEDURE  = sys.int4plsmalldatetime
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = INT4,
    PROCEDURE  = sys.smalldatetimemiint4
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT4,
    RIGHTARG   = sys.smalldatetime,
    PROCEDURE  = sys.int4mismalldatetime
);



CREATE FUNCTION sys.smalldatetimeplfloat8(sys.smalldatetime, float8)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_pl_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = float8,
    PROCEDURE  = sys.smalldatetimeplfloat8
);

CREATE FUNCTION sys.smalldatetimemifloat8(sys.smalldatetime, float8)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'smalldatetime_mi_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG    = sys.smalldatetime,
    RIGHTARG   = float8,
    PROCEDURE  = sys.smalldatetimemifloat8
);

CREATE FUNCTION sys.float8plsmalldatetime(float8, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'float8_pl_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG   = float8,
    RIGHTARG    = sys.smalldatetime,
    PROCEDURE  = sys.float8plsmalldatetime
);

CREATE FUNCTION sys.float8mismalldatetime(float8, sys.smalldatetime)
RETURNS sys.smalldatetime
AS 'babelfishpg_common', 'float8_mi_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG   = float8,
    RIGHTARG    = sys.smalldatetime,
    PROCEDURE  = sys.float8mismalldatetime
);



CREATE FUNCTION  smalldatetime_cmp(sys.SMALLDATETIME, sys.SMALLDATETIME)
RETURNS INT4
AS 'timestamp_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION  smalldatetime_hash(sys.SMALLDATETIME)
RETURNS INT4
AS 'timestamp_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.smalldatetime_ops
DEFAULT FOR TYPE sys.SMALLDATETIME USING btree AS
    OPERATOR    1   <  (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR    2   <= (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR    3   =  (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR    4   >= (sys.SMALLDATETIME, sys.SMALLDATETIME),
    OPERATOR    5   >  (sys.SMALLDATETIME, sys.SMALLDATETIME),
    FUNCTION    1   smalldatetime_cmp(sys.SMALLDATETIME, sys.SMALLDATETIME);

CREATE OPERATOR CLASS sys.smalldatetime_ops
DEFAULT FOR TYPE sys.SMALLDATETIME USING hash AS
    OPERATOR    1   =  (sys.SMALLDATETIME, sys.SMALLDATETIME),
    FUNCTION    1   smalldatetime_hash(sys.SMALLDATETIME);

CREATE OR REPLACE FUNCTION sys.timestamp2smalldatetime(TIMESTAMP)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2smalldatetime(DATETIME)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime22smalldatetime(DATETIME2)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamp_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date2smalldatetime(DATE)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'date_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.smalldatetime2date(SMALLDATETIME)
RETURNS DATE
AS 'timestamp_date'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.timestamptz2smalldatetime(TIMESTAMPTZ)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'timestamptz_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2timestamptz(SMALLDATETIME)
RETURNS TIMESTAMPTZ
AS 'timestamp_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.time2smalldatetime(TIME)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'time_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2time(SMALLDATETIME)
RETURNS TIME
AS 'timestamp_time'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS SMALLDATETIME)
WITH FUNCTION sys.timestamp2smalldatetime(TIMESTAMP) AS ASSIGNMENT;

CREATE CAST (DATETIME AS SMALLDATETIME)
WITH FUNCTION sys.datetime2smalldatetime(DATETIME) AS ASSIGNMENT;

CREATE CAST (DATETIME2 AS SMALLDATETIME)
WITH FUNCTION sys.datetime22smalldatetime(DATETIME2) AS ASSIGNMENT;

CREATE CAST (SMALLDATETIME AS DATETIME)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS DATETIME2)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIMESTAMP)
WITHOUT FUNCTION AS IMPLICIT;

CREATE CAST (TIMESTAMPTZ AS SMALLDATETIME)
WITH FUNCTION sys.timestamptz2smalldatetime (TIMESTAMPTZ) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIMESTAMPTZ)
WITH FUNCTION sys.smalldatetime2timestamptz (SMALLDATETIME) AS ASSIGNMENT;

CREATE CAST (DATE AS SMALLDATETIME)
WITH FUNCTION sys.date2smalldatetime (DATE) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS DATE)
WITH FUNCTION sys.smalldatetime2date (SMALLDATETIME) AS ASSIGNMENT;

CREATE CAST (TIME AS SMALLDATETIME)
WITH FUNCTION sys.time2smalldatetime (TIME) AS IMPLICIT;

CREATE CAST (SMALLDATETIME AS TIME)
WITH FUNCTION sys.smalldatetime2time (SMALLDATETIME) AS ASSIGNMENT;

-- BABEL-1465 CAST from VARCHAR/NVARCHAR/CHAR/NCHAR to smalldatetime is VOLATILE
CREATE OR REPLACE FUNCTION sys.varchar2smalldatetime(sys.VARCHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'varchar_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS SMALLDATETIME)
WITH FUNCTION sys.varchar2smalldatetime (sys.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varchar2smalldatetime(pg_catalog.VARCHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'varchar_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS SMALLDATETIME)
WITH FUNCTION sys.varchar2smalldatetime (pg_catalog.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.char2smalldatetime(CHAR)
RETURNS SMALLDATETIME
AS 'babelfishpg_common', 'char_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS SMALLDATETIME)
WITH FUNCTION sys.char2smalldatetime (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2smalldatetime(sys.BPCHAR)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'char_smalldatetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.SMALLDATETIME)
WITH FUNCTION sys.bpchar2smalldatetime (sys.BPCHAR) AS ASSIGNMENT;

-- BABEL-1465 CAST from smalldatetime to VARCHAR/NVARCHAR/CHAR/NCHAR is VOLATILE
CREATE OR REPLACE FUNCTION sys.smalldatetime2sysvarchar(SMALLDATETIME)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'smalldatetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS sys.VARCHAR)
WITH FUNCTION sys.smalldatetime2sysvarchar (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2varchar(SMALLDATETIME)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'smalldatetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS pg_catalog.VARCHAR)
WITH FUNCTION sys.smalldatetime2varchar (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2char(SMALLDATETIME)
RETURNS CHAR
AS 'babelfishpg_common', 'smalldatetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (SMALLDATETIME AS CHAR)
WITH FUNCTION sys.smalldatetime2char (SMALLDATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.smalldatetime2bpchar(sys.SMALLDATETIME)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'smalldatetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.SMALLDATETIME AS sys.BPCHAR)
WITH FUNCTION sys.smalldatetime2bpchar (sys.SMALLDATETIME) AS ASSIGNMENT;
