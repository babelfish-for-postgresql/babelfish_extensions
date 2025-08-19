CREATE DOMAIN sys.NTEXT AS TEXT;
CREATE DOMAIN sys.SYSNAME AS sys.VARCHAR(128);

CREATE OR REPLACE FUNCTION sys.err_text_to_real(p text) RETURNS real
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'Explicit conversion from data type text to real is not allowed.'
    USING ERRCODE = '22018';  -- invalid character value for cast
END$$;

CREATE CAST (pg_catalog.text AS pg_catalog.float4)
WITH FUNCTION sys.err_text_to_real(pg_catalog.text) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.err_text_to_float8(p pg_catalog.text)
RETURNS pg_catalog.float8
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Explicit conversion from data type text to float is not allowed.'
    USING ERRCODE = '22018';
END$$;

CREATE CAST (pg_catalog.text AS pg_catalog.float8)
WITH FUNCTION sys.err_text_to_float8(pg_catalog.text) AS IMPLICIT;
