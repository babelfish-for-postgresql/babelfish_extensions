CREATE TYPE sys.DATETIME;

CREATE OR REPLACE FUNCTION sys.datetimein(cstring)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeout(sys.DATETIME)
RETURNS cstring
AS 'babelfishpg_common', 'datetime_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimerecv(internal)
RETURNS sys.DATETIME
AS 'timestamp_recv'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimesend(sys.DATETIME)
RETURNS bytea
AS 'timestamp_send'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimetypmodin(cstring[])
RETURNS integer
AS 'timestamptypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimetypmodout(integer)
RETURNS cstring
AS 'timestamptypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATETIME (
	INPUT          = sys.datetimein,
	OUTPUT         = sys.datetimeout,
	RECEIVE        = sys.datetimerecv,
	SEND           = sys.datetimesend,
    TYPMOD_IN      = sys.datetimetypmodin,
    TYPMOD_OUT     = sys.datetimetypmodout,
	INTERNALLENGTH = 8,
	ALIGNMENT      = 'double',
	STORAGE        = 'plain',
	CATEGORY       = 'D',
	PREFERRED      = false,
	COLLATABLE     = false,
    DEFAULT        = '1900-01-01 00:00:00',
    PASSEDBYVALUE
);

CREATE FUNCTION sys.datetimeeq(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_eq'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimene(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_ne'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimelt(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_lt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimele(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_le'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimegt(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_gt'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimege(sys.DATETIME, sys.DATETIME)
RETURNS bool
AS 'timestamp_ge'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.datetimeeq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.datetimene,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.datetimelt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.datetimele,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.datetimegt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.datetimege,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

-- datetime <-> int operators for datetime-int +/- arithmetic 
CREATE FUNCTION sys.datetimeplint4(sys.DATETIME, INT4)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4pldatetime(INT4, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'int4_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimemiint4(sys.DATETIME, INT4)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_int4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.int4midatetime(INT4, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'int4_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = INT4,
    PROCEDURE  = sys.datetimeplint4
);

CREATE OPERATOR sys.+ (
    LEFTARG    = INT4,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.int4pldatetime
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = INT4,
    PROCEDURE  = sys.datetimemiint4
);

CREATE OPERATOR sys.- (
    LEFTARG    = INT4,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.int4midatetime
);



CREATE FUNCTION sys.datetimeplfloat8(sys.DATETIME, float8)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = float8,
    PROCEDURE  = sys.datetimeplfloat8
);

CREATE FUNCTION sys.datetimemifloat8(sys.DATETIME, float8)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_float8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = float8,
    PROCEDURE  = sys.datetimemifloat8
);

CREATE FUNCTION sys.float8pldatetime(float8, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'float8_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG   = float8,
    RIGHTARG    = sys.DATETIME,
    PROCEDURE  = sys.float8pldatetime
);

CREATE FUNCTION sys.float8midatetime(float8, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'float8_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.- (
    LEFTARG   = float8,
    RIGHTARG    = sys.DATETIME,
    PROCEDURE  = sys.float8midatetime
);




CREATE FUNCTION  datetime_cmp(sys.DATETIME, sys.DATETIME)
RETURNS INT4
AS 'timestamp_cmp'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION  datetime_hash(sys.DATETIME)
RETURNS INT4
AS 'timestamp_hash'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.datetime_ops
DEFAULT FOR TYPE sys.DATETIME USING btree AS
    OPERATOR    1   <  (sys.DATETIME, sys.DATETIME),
    OPERATOR    2   <= (sys.DATETIME, sys.DATETIME),
    OPERATOR    3   =  (sys.DATETIME, sys.DATETIME),
    OPERATOR    4   >= (sys.DATETIME, sys.DATETIME),
    OPERATOR    5   >  (sys.DATETIME, sys.DATETIME),
    FUNCTION    1   datetime_cmp(sys.DATETIME, sys.DATETIME);

CREATE OPERATOR CLASS sys.datetime_ops
DEFAULT FOR TYPE sys.DATETIME USING hash AS
    OPERATOR    1   =  (sys.DATETIME, sys.DATETIME),
    FUNCTION    1   datetime_hash(sys.DATETIME);

-- cast TO datetime
CREATE OR REPLACE FUNCTION sys.timestamp2datetime(TIMESTAMP)
RETURNS DATETIME
AS 'babelfishpg_common', 'timestamp_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMP AS DATETIME)
WITH FUNCTION sys.timestamp2datetime(TIMESTAMP) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.timestamptz2datetime(TIMESTAMPTZ)
RETURNS DATETIME
AS 'babelfishpg_common', 'timestamptz_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIMESTAMPTZ AS DATETIME)
WITH FUNCTION sys.timestamptz2datetime (TIMESTAMPTZ) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.date2datetime(DATE)
RETURNS DATETIME
AS 'babelfishpg_common', 'date_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATE AS DATETIME)
WITH FUNCTION sys.date2datetime (DATE) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.time2datetime(TIME)
RETURNS DATETIME
AS 'babelfishpg_common', 'time_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (TIME AS DATETIME)
WITH FUNCTION sys.time2datetime (TIME) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.varchar2datetime(sys.VARCHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'varchar_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.VARCHAR AS DATETIME)
WITH FUNCTION sys.varchar2datetime (sys.VARCHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.varchar2datetime(pg_catalog.VARCHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'varchar_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (pg_catalog.VARCHAR AS DATETIME)
WITH FUNCTION sys.varchar2datetime (pg_catalog.VARCHAR) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.char2datetime(CHAR)
RETURNS DATETIME
AS 'babelfishpg_common', 'char_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (CHAR AS DATETIME)
WITH FUNCTION sys.char2datetime (CHAR) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.bpchar2datetime(sys.BPCHAR)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'char_datetime'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.BPCHAR AS sys.DATETIME)
WITH FUNCTION sys.bpchar2datetime (sys.BPCHAR) AS ASSIGNMENT;

--  cast FROM datetime
CREATE CAST (DATETIME AS TIMESTAMP)
WITHOUT FUNCTION AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime2timestamptz(DATETIME)
RETURNS TIMESTAMPTZ
AS 'timestamp_timestamptz'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS TIMESTAMPTZ)
WITH FUNCTION sys.datetime2timestamptz (DATETIME) AS IMPLICIT;


CREATE OR REPLACE FUNCTION sys.datetime2date(DATETIME)
RETURNS DATE
AS 'timestamp_date'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS DATE)
WITH FUNCTION sys.datetime2date (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2time(DATETIME)
RETURNS TIME
AS 'timestamp_time'
LANGUAGE internal VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS TIME)
WITH FUNCTION sys.datetime2time (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2sysvarchar(DATETIME)
RETURNS sys.VARCHAR
AS 'babelfishpg_common', 'datetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS sys.VARCHAR)
WITH FUNCTION sys.datetime2sysvarchar (DATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime2varchar(DATETIME)
RETURNS pg_catalog.VARCHAR
AS 'babelfishpg_common', 'datetime_varchar'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS pg_catalog.VARCHAR)
WITH FUNCTION sys.datetime2varchar (DATETIME) AS ASSIGNMENT;


CREATE OR REPLACE FUNCTION sys.datetime2char(DATETIME)
RETURNS CHAR
AS 'babelfishpg_common', 'datetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (DATETIME AS CHAR)
WITH FUNCTION sys.datetime2char (DATETIME) AS ASSIGNMENT;

CREATE OR REPLACE FUNCTION sys.datetime2bpchar(sys.DATETIME)
RETURNS sys.BPCHAR
AS 'babelfishpg_common', 'datetime_char'
LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIME AS sys.BPCHAR)
WITH FUNCTION sys.datetime2bpchar (sys.DATETIME) AS ASSIGNMENT;
