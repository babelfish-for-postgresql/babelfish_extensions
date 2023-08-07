-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '3.2.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

DROP CAST IF EXISTS(NUMERIC AS sys.BIT);
CREATE CAST (NUMERIC AS sys.BIT) WITH FUNCTION sys.numeric_bit (NUMERIC) AS IMPLICIT;

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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
