-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '2.2.0'" to load this file. \quit

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

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);