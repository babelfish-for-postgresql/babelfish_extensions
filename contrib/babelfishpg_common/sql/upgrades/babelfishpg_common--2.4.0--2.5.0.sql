-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.5.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.int4varbinarydiv(leftarg int4 , rightarg sys.bbf_varbinary)
RETURNS int4
AS 'babelfishpg_common', 'int4varbinary_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS(Select 1 from pg_operator where oprname = '/' and oprcode = 'sys.int4varbinarydiv'::regproc) THEN
CREATE OPERATOR sys./ (
    LEFTARG = int4,
    RIGHTARG = sys.bbf_varbinary,
    FUNCTION = int4varbinarydiv,
    COMMUTATOR = /
);
END IF;
END $$;

CREATE OR REPLACE FUNCTION sys.varbinaryint4div(leftarg sys.bbf_varbinary , rightarg int4)
RETURNS int4
AS 'babelfishpg_common', 'varbinaryint4_div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
IF NOT EXISTS(Select 1 from pg_operator where oprname = '/' and oprcode = 'sys.varbinaryint4div'::regproc) THEN
CREATE OPERATOR sys./ (
    LEFTARG = sys.bbf_varbinary,
    RIGHTARG = int4,
    FUNCTION = varbinaryint4div,
    COMMUTATOR = /
);
END IF;
END $$;

-- binary varbinary cast
DO $$
DECLARE 
    sys_oid Oid;
    bbf_binary_oid Oid;
    bbf_varbinary_oid Oid;
BEGIN
  sys_oid := (SELECT oid FROM pg_namespace WHERE pg_namespace.nspname ='sys');
  bbf_binary_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bbf_binary' AND typnamespace = sys_oid);
  bbf_varbinary_oid := (SELECT oid FROM pg_type WHERE pg_type.typname ='bbf_varbinary' AND typnamespace = sys_oid);  
  IF (SELECT COUNT(*) FROM pg_cast WHERE pg_cast.castsource = bbf_binary_oid AND pg_cast.castsource = bbf_varbinary_oid) = 0 THEN
      CREATE CAST (sys.BBF_BINARY AS sys.BBF_VARBINARY)
      WITHOUT FUNCTION AS IMPLICIT;
  END IF;
  IF (SELECT COUNT(*) FROM pg_cast.pg_cast WHERE castsource = bbf_binary_oid AND pg_cast.castsource = bbf_varbinary_oid) = 0 THEN
      CREATE CAST (sys.BBF_VARBINARY AS sys.BBF_BINARY)
      WITHOUT FUNCTION AS IMPLICIT;
  END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
