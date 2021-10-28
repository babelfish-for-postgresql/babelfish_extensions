--------------------------
-- FIXEDDECIMALAGGSTATE --
-------------------------

CREATE TYPE FIXEDDECIMALAGGSTATE;

CREATE FUNCTION fixeddecimalaggstatein(cstring, oid, int4)
RETURNS FIXEDDECIMALAGGSTATE
AS 'babelfishpg_money', 'fixeddecimalaggstatein'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalaggstateout(fixeddecimalaggstate)
RETURNS cstring
AS 'babelfishpg_money', 'fixeddecimalaggstateout'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalaggstaterecv(internal)
RETURNS FIXEDDECIMALAGGSTATE
AS 'babelfishpg_money', 'fixeddecimalaggstaterecv'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION fixeddecimalaggstatesend(FIXEDDECIMALAGGSTATE)
RETURNS bytea
AS 'babelfishpg_money', 'fixeddecimalaggstatesend'
LANGUAGE C IMMUTABLE STRICT;


CREATE TYPE FIXEDDECIMALAGGSTATE (
    INPUT          = fixeddecimalaggstatein,
    OUTPUT         = fixeddecimalaggstateout,
    RECEIVE        = fixeddecimalaggstaterecv,
    SEND           = fixeddecimalaggstatesend,
    INTERNALLENGTH = 8,
    ALIGNMENT      = 'double',
    STORAGE        = plain,
    CATEGORY       = 'N',
    PREFERRED      = false,
    COLLATABLE     = false,
    PASSEDBYVALUE
);

