-- Wrap built-in CONCAT function to accept two text arguments.
-- This is necessary because CONCAT accepts arguments of type VARIADIC "any". 
-- CONCAT also automatically handles NULL which || does not.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg text, rightarg text) RETURNS TEXT
AS 'babelfishpg_tsql', 'babelfish_concat_wrapper'
LANGUAGE C STABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper_outer(leftarg text, rightarg text) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = text,
    RIGHTARG = text,
    FUNCTION = sys.babelfish_concat_wrapper_outer
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.varchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.varchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.bpchar, rightarg sys.bpchar) RETURNS sys.varchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.bpchar,
    RIGHTARG = sys.bpchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nchar, rightarg sys.nchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nchar,
    RIGHTARG = sys.nchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

-- if one of input is nvarchar, resolve it as nvarchar. as varchar is a base type of nvarchar, we need to define this function explictly.
CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.varchar, rightarg sys.nvarchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.varchar,
    RIGHTARG = sys.nvarchar,
    FUNCTION = sys.babelfish_concat_wrapper
);

CREATE OR REPLACE FUNCTION sys.babelfish_concat_wrapper(leftarg sys.nvarchar, rightarg sys.varchar) RETURNS sys.nvarchar(8000) AS
$$
  SELECT sys.babelfish_concat_wrapper(cast(leftarg as text), cast(rightarg as text))
$$
LANGUAGE SQL STABLE;

-- Support strings for + operator.
CREATE OPERATOR sys.+ (
    LEFTARG = sys.nvarchar,
    RIGHTARG = sys.varchar,
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
language plpgsql STABLE;

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
