------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "3.3.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Add SORTOP for aggregations
-- bpchar
CREATE OR REPLACE AGGREGATE sys.max(sys.BPCHAR)
(
  sfunc = sys.bpchar_larger,
  stype = sys.bpchar,
  combinefunc = sys.bpchar_larger,
  sortop = >,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.BPCHAR)
(
  sfunc = sys.bpchar_smaller,
  stype = sys.bpchar,
  combinefunc = sys.bpchar_smaller,
  sortop = <,
  parallel = safe
);

-- varchar
CREATE OR REPLACE AGGREGATE sys.max(sys.VARCHAR)
(
  sfunc = sys.varchar_larger,
  stype = sys.varchar,
  combinefunc = sys.varchar_larger,
  sortop = >,
  parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.VARCHAR)
(
  sfunc = sys.varchar_smaller,
  stype = sys.varchar,
  combinefunc = sys.varchar_smaller,
  sortop = <,
  parallel = safe
);

-- datetime
CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIME)
(
    sfunc = sys.datetime_larger,
    stype = sys.datetime,
    combinefunc = sys.datetime_larger,
    sortop = >,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIME)
(
    sfunc = sys.datetime_smaller,
    stype = sys.datetime,
    combinefunc = sys.datetime_smaller,
    sortop = <,
    parallel = safe
);

-- datetime2
CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIME2)
(
    sfunc = sys.datetime2_larger,
    stype = sys.datetime2,
    combinefunc = sys.datetime2_larger,
    sortop = >,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIME2)
(
    sfunc = sys.datetime2_smaller,
    stype = sys.datetime2,
    combinefunc = sys.datetime2_smaller,
    sortop = <,
    parallel = safe
);

-- datetimeoffset
CREATE OR REPLACE AGGREGATE sys.max(sys.DATETIMEOFFSET)
(
    sfunc = sys.datetimeoffset_larger,
    stype = sys.datetimeoffset,
    combinefunc = sys.datetimeoffset_larger,
    sortop = >,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.DATETIMEOFFSET)
(
    sfunc = sys.datetimeoffset_smaller,
    stype = sys.datetimeoffset,
    combinefunc = sys.datetimeoffset_smaller,
    sortop = <,
    parallel = safe
);

-- smalldatetime
CREATE OR REPLACE AGGREGATE sys.max(sys.SMALLDATETIME)
(
    sfunc = sys.smalldatetime_larger,
    stype = sys.smalldatetime,
    combinefunc = sys.smalldatetime_larger,
    sortop = >,
    parallel = safe
);

CREATE OR REPLACE AGGREGATE sys.min(sys.SMALLDATETIME)
(
    sfunc = sys.smalldatetime_smaller,
    stype = sys.smalldatetime,
    combinefunc = sys.smalldatetime_smaller,
    sortop = <,
    parallel = safe
);

-- binary varbinary cast
DO $$
DECLARE 
    sys_oid Oid;
    bbf_binary_oid Oid;
    bbf_varbinary_oid Oid;
BEGIN
  sys_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='sys');
  bbf_binary_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bbf_binary' AND pg_type.typnamespace = sys_oid);
  bbf_varbinary_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bbf_varbinary' AND pg_type.typnamespace = sys_oid);  
  IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = bbf_binary_oid AND pg_cast.casttarget = bbf_varbinary_oid) = 0 THEN
      CREATE CAST (sys.BBF_BINARY AS sys.BBF_VARBINARY)
      WITHOUT FUNCTION AS IMPLICIT;
  END IF;
  IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = bbf_binary_oid AND pg_cast.casttarget = bbf_varbinary_oid) = 0 THEN
      CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_BINARY)
      WITHOUT FUNCTION AS IMPLICIT;
  END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
