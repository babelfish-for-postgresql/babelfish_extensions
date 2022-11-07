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

-- datetime +/- operators (datetime, int4, float8)
CREATE FUNCTION sys.datetime_add(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_pl_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetime_minus(sys.DATETIME, sys.DATETIME)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetime_mi_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.datetime_add
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIME,
    RIGHTARG   = sys.DATETIME,
    PROCEDURE  = sys.datetime_minus
);

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

-- cast BIT to DATETIME
CREATE OR REPLACE FUNCTION sys.bit2datetime(IN num sys.BIT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + (CASE WHEN num != 0 THEN 1 ELSE 0 END);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.BIT AS sys.DATETIME)
WITH FUNCTION sys.bit2datetime (sys.BIT) AS IMPLICIT;

-- cast NUMERIC to DATETIME & cast DECIMAL to DATETIME
CREATE OR REPLACE FUNCTION sys.numeric2datetime(IN num NUMERIC)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (NUMERIC AS sys.DATETIME)
WITH FUNCTION sys.numeric2datetime (NUMERIC) AS IMPLICIT;

-- cast FLOAT to DATETIME
CREATE OR REPLACE FUNCTION sys.float8datetime(IN num FLOAT8)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT8 AS sys.DATETIME)
WITH FUNCTION sys.float8datetime (FLOAT8) AS IMPLICIT;

-- cast REAL to DATETIME
CREATE OR REPLACE FUNCTION sys.float4datetime(IN num FLOAT4)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FLOAT4 AS sys.DATETIME)
WITH FUNCTION sys.float4datetime (FLOAT4) AS IMPLICIT;

-- cast INT to DATETIME
CREATE OR REPLACE FUNCTION sys.int2datetime(IN num INT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + num;
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (INT AS sys.DATETIME)
WITH FUNCTION sys.int2datetime (INT) AS IMPLICIT;

-- cast BIGINT to DATETIME
-- BIGINT to INT will either convert successfully if INT_MIN < num < INT_MAX, 
-- otherwise it will raise an exception for being out of bound for INT. While 
-- the error message will be different, ultimately I don't think there is much 
-- issue due to the fact that even INT_MAX/INT_MIN is far beyond the acceptable 
-- limit of what DATETIME (let alone SMALLDATETIME) can accept. Therefore, 
-- Babelfish will raise an error in the same situations as SQL Server, just with 
-- an int out of range instead of a datetime out of range error.
CREATE OR REPLACE FUNCTION sys.bigint2datetime(IN num BIGINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (BIGINT AS sys.DATETIME)
WITH FUNCTION sys.bigint2datetime (BIGINT) AS IMPLICIT;

-- cast SMALLINT to DATETIME & cast TINYINT to DATETIME
CREATE OR REPLACE FUNCTION sys.smallint2datetime(IN num SMALLINT)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS INT);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (SMALLINT AS sys.DATETIME)
WITH FUNCTION sys.smallint2datetime (SMALLINT) AS IMPLICIT;

-- cast MONEY to DATETIME & cast SMALLMONEY to DATETIME
CREATE OR REPLACE FUNCTION sys.money2datetime(IN num FIXEDDECIMAL)
RETURNS sys.DATETIME
AS $$
    SELECT CAST('1900-01-01 00:00:00.0' AS sys.DATETIME) + CAST(num AS FLOAT8);
$$
LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (FIXEDDECIMAL AS sys.DATETIME)
WITH FUNCTION sys.money2datetime (FIXEDDECIMAL) AS IMPLICIT;
