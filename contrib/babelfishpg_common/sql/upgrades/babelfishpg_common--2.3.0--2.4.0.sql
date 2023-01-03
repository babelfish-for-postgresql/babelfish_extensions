-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.4.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int8(In arg sys.fixeddecimal)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT8);
END;
$$ LANGUAGE plpgsql STABLE;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int4(In arg sys.fixeddecimal)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT4);
END;
$$ LANGUAGE plpgsql STABLE;

-- fixeddecimal -> int8
CREATE OR REPLACE FUNCTION sys._round_fixeddecimal_to_int2(In arg sys.fixeddecimal)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(round(arg) AS INT2);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int8
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int8(In arg numeric)
RETURNS INT8 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT8);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int4
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int4(In arg numeric)
RETURNS INT4 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT4);
END;
$$ LANGUAGE plpgsql STABLE;

-- numeric -> int2
CREATE OR REPLACE FUNCTION sys._trunc_numeric_to_int2(In arg numeric)
RETURNS INT2 AS $$
BEGIN
  RETURN CAST(trunc(arg) AS INT2);
END;
$$ LANGUAGE plpgsql STABLE;

create or replace function sys.CHAR(x in int)returns char
AS
$body$
BEGIN
/***************************************************************
EXTENSION PACK function CHAR(x)
***************************************************************/
    if x between 1 and 255 then
        return chr(x);
    else
        return null;
    end if;
END;
$body$
language plpgsql STABLE;

-- Wrap built-in CONCAT function to accept two text arguments.
-- This is necessary because CONCAT accepts arguments of type VARIADIC "any". 
-- CONCAT also automatically handles NULL which || does not.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) RETURNS TEXT AS
$$
  SELECT
    CASE WHEN (current_setting('babelfishpg_tsql.concat_null_yields_null') = 'on') THEN
      CASE
        WHEN leftarg IS NULL OR rightarg IS NULL THEN NULL
        ELSE CONCAT(leftarg, rightarg)
      END
      ELSE
        CONCAT(leftarg, rightarg)
    END
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper_outer(leftarg text, rightarg text) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.varchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.bpchar, rightarg sys.bpchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nchar, rightarg sys.nchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- if one of input is nvarchar, resolve it as nvarchar. as varchar is a base type of nvarchar, we need to define this function explictly.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.varchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.tinyintxor(leftarg sys.tinyint, rightarg sys.tinyint)
RETURNS sys.tinyint
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS sys.tinyint);
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.int2xor(leftarg int2, rightarg int2)
RETURNS int2
AS $$
SELECT CAST(CAST(sys.bitxor(CAST(CAST(leftarg AS int4) AS pg_catalog.bit(16)),
                    CAST(CAST(rightarg AS int4) AS pg_catalog.bit(16))) AS int4) AS int2);
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.intxor(leftarg int4, rightarg int4)
RETURNS int4
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(32)),
                    CAST(rightarg AS pg_catalog.bit(32))) AS int4)
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.int8xor(leftarg int8, rightarg int8)
RETURNS int8
AS $$
SELECT CAST(sys.bitxor(CAST(leftarg AS pg_catalog.bit(64)),
                    CAST(rightarg AS pg_catalog.bit(64))) AS int8)
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.bitxor(leftarg pg_catalog.bit, rightarg pg_catalog.bit)
RETURNS pg_catalog.bit
AS $$
SELECT (leftarg & ~rightarg) | (~leftarg & rightarg);
$$
LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION sys.newid()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4' -- uuid-ossp was added as dependency
LANGUAGE C STABLE STRICT PARALLEL SAFE;

/*
 * in tsql, NEWSEQUENTIALID() produces a new unique value
 * greater than a sequence of previous values. Since PG does not
 * have this capability, we will reuse the NEWID() functionality and be
 * aware of the functional shortcoming
 */
CREATE OR REPLACE FUNCTION sys.NEWSEQUENTIALID()
RETURNS sys.UNIQUEIDENTIFIER
AS 'uuid-ossp', 'uuid_generate_v4'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.babelfish_typecode_list()
RETURNS table (
  oid int,
  pg_namespace text,
  pg_typname text,
  tsql_typname text,
  type_family_priority smallint,
  priority smallint,
  sql_variant_hdr_size smallint
) AS 'babelfishpg_common', 'typecode_list' LANGUAGE C STABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);