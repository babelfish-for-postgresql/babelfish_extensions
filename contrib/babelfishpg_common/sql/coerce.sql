-- Add Missing casting functions
-- Casting functions used in catalog should use the exact type of castsource and casttarget.

-- double precision -> int8
CREATE OR REPLACE FUNCTION sys.dtrunci8(double precision)
RETURNS INT8
AS 'babelfishpg_common', 'dtrunci8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- double precision -> int4
CREATE OR REPLACE FUNCTION sys.dtrunci4(double precision)
RETURNS INT4
AS 'babelfishpg_common', 'dtrunci4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- double precision -> int2
CREATE OR REPLACE FUNCTION sys.dtrunci2(double precision)
RETURNS INT2
AS 'babelfishpg_common', 'dtrunci2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int8
CREATE OR REPLACE FUNCTION sys.ftrunci8(real)
RETURNS INT8
AS 'babelfishpg_common', 'ftrunci8'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int4
CREATE OR REPLACE FUNCTION sys.ftrunci4(real)
RETURNS INT4
AS 'babelfishpg_common', 'ftrunci4'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- real -> int2
CREATE OR REPLACE FUNCTION sys.ftrunci2(real)
RETURNS INT2
AS 'babelfishpg_common', 'ftrunci2'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--- XXX: it is desriable to use SQL (or C) rather than plpgsql. But SQL function is not working
--- if tsql is enabled for some reasons. (BABEL-766)

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

-- text -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(text)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- char -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(char)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.char_to_fixeddecimal(sys.bpchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- varchar -> fixeddecimal
CREATE FUNCTION sys.char_to_fixeddecimal(sys.varchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.char_to_fixeddecimal(pg_catalog.varchar)
RETURNS sys.FIXEDDECIMAL
AS 'babelfishpg_money', 'char_to_fixeddecimal'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- text -> name
CREATE FUNCTION sys.text_to_name(text)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- bpchar -> name
CREATE FUNCTION sys.bpchar_to_name(pg_catalog.bpchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_bpchar_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.bpchar_to_name(sys.bpchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_bpchar_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- varchar -> name
CREATE FUNCTION sys.varchar_to_name(sys.varchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.varchar_to_name(pg_catalog.varchar)
RETURNS pg_catalog.name
AS 'babelfishpg_common', 'pltsql_text_name'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- int8 -> money
CREATE FUNCTION sys.int8_to_money(INT8)
RETURNS sys.MONEY
AS 'babelfishpg_money', 'int8_to_money'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- int8 -> smallmoney
CREATE FUNCTION sys.int8_to_smallmoney(INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8_to_smallmoney'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;