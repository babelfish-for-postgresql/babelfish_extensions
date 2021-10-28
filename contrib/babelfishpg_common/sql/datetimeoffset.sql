CREATE TYPE sys.DATETIMEOFFSET;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetin(cstring)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_in'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetout(sys.DATETIMEOFFSET)
RETURNS cstring
AS 'babelfishpg_common', 'datetimeoffset_out'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetrecv(internal)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_recv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffsetsend(sys.DATETIMEOFFSET)
RETURNS bytea
AS 'babelfishpg_common', 'datetimeoffset_send'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeofftypmodin(cstring[])
RETURNS integer
AS 'timestamptztypmodin'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeofftypmodout(integer)
RETURNS cstring
AS 'timestamptztypmodout'
LANGUAGE internal IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sys.DATETIMEOFFSET (
	INPUT          = sys.datetimeoffsetin,
	OUTPUT         = sys.datetimeoffsetout,
	RECEIVE        = sys.datetimeoffsetrecv,
	SEND           = sys.datetimeoffsetsend,
    TYPMOD_IN      = sys.datetimeofftypmodin,
    TYPMOD_OUT     = sys.datetimeofftypmodout,
	INTERNALLENGTH = 10,
	ALIGNMENT      = 'double',
	STORAGE        = 'plain',
	CATEGORY       = 'D',
	PREFERRED      = false,
    DEFAULT        = '1900-01-01 00:00+0'
);

CREATE FUNCTION sys.datetimeoffseteq(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_eq'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetne(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_ne'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetlt(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_lt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetle(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_le'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetgt(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_gt'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetge(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS bool
AS 'babelfishpg_common', 'datetimeoffset_ge'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetplinterval(sys.DATETIMEOFFSET, INTERVAL)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_pl_interval'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.intervalpldatetimeoffset(INTERVAL, sys.DATETIMEOFFSET)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'interval_pl_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetmiinterval(sys.DATETIMEOFFSET, INTERVAL)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_mi_interval'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.datetimeoffsetmi(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS INTERVAL
AS 'babelfishpg_common', 'datetimeoffset_mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    COMMUTATOR = =,
    NEGATOR    = <>,
    PROCEDURE  = sys.datetimeoffseteq,
    RESTRICT   = eqsel,
    JOIN       = eqjoinsel,
    MERGES
);

CREATE OPERATOR sys.<> (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    NEGATOR    = =,
    COMMUTATOR = <>,
    PROCEDURE  = sys.datetimeoffsetne,
    RESTRICT   = neqsel,
    JOIN       = neqjoinsel
);

CREATE OPERATOR sys.< (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    NEGATOR    = >=,
    COMMUTATOR = >,
    PROCEDURE  = sys.datetimeoffsetlt,
    RESTRICT   = scalarltsel,
    JOIN       = scalarltjoinsel
);

CREATE OPERATOR sys.<= (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    NEGATOR    = >,
    COMMUTATOR = >=,
    PROCEDURE  = sys.datetimeoffsetle,
    RESTRICT   = scalarlesel,
    JOIN       = scalarlejoinsel
);

CREATE OPERATOR sys.> (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    NEGATOR    = <=,
    COMMUTATOR = <,
    PROCEDURE  = sys.datetimeoffsetgt,
    RESTRICT   = scalargtsel,
    JOIN       = scalargtjoinsel
);

CREATE OPERATOR sys.>= (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    NEGATOR    = <,
    COMMUTATOR = <=,
    PROCEDURE  = sys.datetimeoffsetge,
    RESTRICT   = scalargesel,
    JOIN       = scalargejoinsel
);

CREATE OPERATOR sys.+ (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = interval,
    PROCEDURE  = sys.datetimeoffsetplinterval
);

CREATE OPERATOR sys.+ (
    LEFTARG    = interval,
    RIGHTARG   = sys.DATETIMEOFFSET,
    PROCEDURE  = sys.intervalpldatetimeoffset
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = interval,
    PROCEDURE  = sys.datetimeoffsetmiinterval
);

CREATE OPERATOR sys.- (
    LEFTARG    = sys.DATETIMEOFFSET,
    RIGHTARG   = sys.DATETIMEOFFSET,
    PROCEDURE  = sys.datetimeoffsetmi
);

CREATE FUNCTION  datetimeoffset_cmp(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET)
RETURNS INT4
AS 'babelfishpg_common', 'datetimeoffset_cmp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION  datetimeoffset_hash(sys.DATETIMEOFFSET)
RETURNS INT4
AS 'babelfishpg_common', 'datetimeoffset_hash'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS sys.datetimeoffset_ops
DEFAULT FOR TYPE sys.DATETIMEOFFSET USING btree AS
    OPERATOR    1   <  (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR    2   <= (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR    3   =  (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR    4   >= (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    OPERATOR    5   >  (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    FUNCTION    1   datetimeoffset_cmp(sys.DATETIMEOFFSET, sys.DATETIMEOFFSET);

CREATE OPERATOR CLASS sys.datetimeoffset_ops
DEFAULT FOR TYPE sys.DATETIMEOFFSET USING hash AS
    OPERATOR    1   =  (sys.DATETIMEOFFSET, sys.DATETIMEOFFSET),
    FUNCTION    1   datetimeoffset_hash(sys.DATETIMEOFFSET);

-- Casts
CREATE FUNCTION sys.datetimeoffsetscale(sys.DATETIMEOFFSET, INT4)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetimeoffset_scale'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.timestamp2datetimeoffset(TIMESTAMP)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'timestamp_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2timestamp(sys.DATETIMEOFFSET)
RETURNS TIMESTAMP
AS 'babelfishpg_common', 'datetimeoffset_timestamp'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.date2datetimeoffset(DATE)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'date_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2date(sys.DATETIMEOFFSET)
RETURNS DATE
AS 'babelfishpg_common', 'datetimeoffset_date'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.time2datetimeoffset(TIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'time_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2time(sys.DATETIMEOFFSET)
RETURNS TIME
AS 'babelfishpg_common', 'datetimeoffset_time'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.smalldatetime2datetimeoffset(sys.SMALLDATETIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'smalldatetime_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2smalldatetime(sys.DATETIMEOFFSET)
RETURNS sys.SMALLDATETIME
AS 'babelfishpg_common', 'datetimeoffset_smalldatetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime2datetimeoffset(sys.DATETIME)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetime_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2datetime(sys.DATETIMEOFFSET)
RETURNS sys.DATETIME
AS 'babelfishpg_common', 'datetimeoffset_datetime'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetime22datetimeoffset(sys.DATETIME2)
RETURNS sys.DATETIMEOFFSET
AS 'babelfishpg_common', 'datetime2_datetimeoffset'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.datetimeoffset2datetime2(sys.DATETIMEOFFSET)
RETURNS sys.DATETIME2
AS 'babelfishpg_common', 'datetimeoffset_datetime2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIMEOFFSET)
WITH FUNCTION datetimeoffsetscale (sys.DATETIMEOFFSET, INT4) AS ASSIGNMENT;

CREATE CAST (TIMESTAMP AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.timestamp2datetimeoffset(TIMESTAMP) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS TIMESTAMP)
WITH FUNCTION sys.datetimeoffset2timestamp(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (DATE AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.date2datetimeoffset(DATE) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS DATE)
WITH FUNCTION sys.datetimeoffset2date(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (TIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.time2datetimeoffset(TIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS TIME)
WITH FUNCTION sys.datetimeoffset2time(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.SMALLDATETIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.smalldatetime2datetimeoffset(sys.SMALLDATETIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.SMALLDATETIME)
WITH FUNCTION sys.datetimeoffset2smalldatetime(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.DATETIME AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.datetime2datetimeoffset(sys.DATETIME) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIME)
WITH FUNCTION sys.datetimeoffset2datetime(sys.DATETIMEOFFSET) AS ASSIGNMENT;

CREATE CAST (sys.DATETIME2 AS sys.DATETIMEOFFSET)
WITH FUNCTION sys.datetime22datetimeoffset(sys.DATETIME2) AS IMPLICIT;
CREATE CAST (sys.DATETIMEOFFSET AS sys.DATETIME2)
WITH FUNCTION sys.datetimeoffset2datetime2(sys.DATETIMEOFFSET) AS ASSIGNMENT;
