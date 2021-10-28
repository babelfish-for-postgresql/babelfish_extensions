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
LANGUAGE SQL VOLATILE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = sys.babelfish_concat_wrapper
);

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
language plpgsql;

CREATE OR REPLACE FUNCTION sys.nchar(IN x INTEGER) RETURNS sys.nvarchar
AS
$body$
BEGIN
    --- 1114111 is 0x10FFFF - max value permitted as specified by documentation
    if x between 1 and 1114111 then
        return(select chr(x))::sys.nvarchar;
    else
        return null;
    end if;
END;
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.nchar(IN x varbinary) RETURNS sys.nvarchar
AS
$body$
BEGIN
    --- 1114111 is 0x10FFFF - max value permitted as specified by documentation
    if x::integer between 1 and 1114111 then
        return(select chr(x::integer))::sys.nvarchar;
    else
        return null;
    end if;
END;
$body$
LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
