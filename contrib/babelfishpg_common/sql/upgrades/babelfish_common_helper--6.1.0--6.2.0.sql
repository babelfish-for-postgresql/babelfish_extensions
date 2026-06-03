------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '6.2.0'" to load this file. \quit

CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int8(In arg numeric)
RETURNS INT8 AS $$
BEGIN
  RETURN pg_catalog.int8(trunc(arg));
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int4(In arg numeric)
RETURNS INT4 AS $$
BEGIN
  RETURN pg_catalog.int4(trunc(arg));
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int2(In arg numeric)
RETURNS INT2 AS $$
BEGIN
  RETURN pg_catalog.int2(trunc(arg));
END;
$$ LANGUAGE plpgsql STABLE;
