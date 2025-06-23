------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO '5.3.0'" to load this file. \quit

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- casting from bytea to binary
CREATE OR REPLACE FUNCTION sys.byteabinary(pg_catalog.BYTEA, integer, boolean)
RETURNS sys.BBF_BINARY
AS 'babelfishpg_common', 'byteabinary'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
    CREATE CAST (pg_catalog.BYTEA AS sys.BBF_BINARY)
    WITH FUNCTION sys.byteabinary(pg_catalog.BYTEA, integer, boolean) AS ASSIGNMENT;
EXCEPTION WHEN duplicate_object THEN
    -- Silently ignore if cast already exists
END;
$$;

-- casting from binary to bytea
CREATE OR REPLACE FUNCTION sys.binarybytea(sys.BBF_BINARY, integer, boolean)
RETURNS pg_catalog.BYTEA
AS 'babelfishpg_common', 'binarybytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
    CREATE CAST (sys.BBF_BINARY AS pg_catalog.BYTEA)
    WITH FUNCTION sys.binarybytea(sys.BBF_BINARY, integer, boolean) AS ASSIGNMENT;
EXCEPTION WHEN duplicate_object THEN
    -- Silently ignore if cast already exists
END;
$$;

-- Operator class for numeric_ops to incorporate various operator between numeric and int4 for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'numeric_int4_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.numeric_int4_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (numeric, int4),
            OPERATOR 2 sys.<= (numeric, int4),
            OPERATOR 3 sys.= (numeric, int4),
            OPERATOR 4 sys.>= (numeric, int4),
            OPERATOR 5 sys.> (numeric, int4),
            FUNCTION 1 sys.numeric_int4_cmp(numeric, int4);
    END IF;
END $$;

-- Operator class for numeric_ops to incorporate various operator between int4 and numeric for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'int4_numeric_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.int4_numeric_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (int4, numeric),
            OPERATOR 2 sys.<= (int4, numeric),
            OPERATOR 3 sys.= (int4, numeric),
            OPERATOR 4 sys.>= (int4, numeric),
            OPERATOR 5 sys.> (int4, numeric),
            FUNCTION 1 sys.int4_numeric_cmp(int4, numeric);
    END IF;
END $$;

-- Operator class for numeric_ops to incorporate various operator between numeric and int2 for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'numeric_int2_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.numeric_int2_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (numeric, int2),
            OPERATOR 2 sys.<= (numeric, int2),
            OPERATOR 3 sys.= (numeric, int2),
            OPERATOR 4 sys.>= (numeric, int2),
            OPERATOR 5 sys.> (numeric, int2),
            FUNCTION 1 sys.numeric_int2_cmp(numeric, int2);
    END IF;
END $$;

-- Operator class for numeric_ops to incorporate various operator between int2 and numeric for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'int2_numeric_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.int2_numeric_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (int2, numeric),
            OPERATOR 2 sys.<= (int2, numeric),
            OPERATOR 3 sys.= (int2, numeric),
            OPERATOR 4 sys.>= (int2, numeric),
            OPERATOR 5 sys.> (int2, numeric),
            FUNCTION 1 sys.int2_numeric_cmp(int2, numeric);
    END IF;
END $$;

-- Operator class for numeric_ops to incorporate various operator int8 and numeric for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'int8_numeric_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.int8_numeric_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (int8, numeric),
            OPERATOR 2 sys.<= (int8, numeric),
            OPERATOR 3 sys.= (int8, numeric),
            OPERATOR 4 sys.>= (int8, numeric),
            OPERATOR 5 sys.> (int8, numeric),
            FUNCTION 1 sys.int8_numeric_cmp(int8, numeric);
    END IF;
END $$;

-- Operator class for numeric_ops to incorporate various operator between numeric and int8 for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'numeric_int8_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.numeric_int8_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (numeric, int8),
            OPERATOR 2 sys.<= (numeric, int8),
            OPERATOR 3 sys.= (numeric, int8),
            OPERATOR 4 sys.>= (numeric, int8),
            OPERATOR 5 sys.> (numeric, int8),
            FUNCTION 1 sys.numeric_int8_cmp(numeric, int8);
    END IF;
END $$;

-- arithmetic functions where one of the 
-- operand is smallmoney

-- smallmoney <op> smallmoney
CREATE OR REPLACE FUNCTION sys.fixeddecimalpl(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneypl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalmi(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneymi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalmul(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneymul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimaldiv(sys.SMALLMONEY, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneydiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- smallmoney <op> int8
CREATE OR REPLACE FUNCTION sys.fixeddecimalint8pl(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint8pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint8mi(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint8mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint8mul(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint8mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint8div(sys.SMALLMONEY, INT8)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint8div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- smallmoney <op> int4
CREATE OR REPLACE FUNCTION sys.fixeddecimalint4pl(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint4pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint4mi(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint4mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint4mul(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint4mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint4div(sys.SMALLMONEY, INT4)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint4div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- smallmoney <op> int2
CREATE OR REPLACE FUNCTION sys.fixeddecimalint2pl(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint2pl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint2mi(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint2mi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint2mul(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint2mul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.fixeddecimalint2div(sys.SMALLMONEY, INT2)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'smallmoneyint2div'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- int8 <op> smallmoney
CREATE OR REPLACE FUNCTION sys.int8fixeddecimalpl(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8smallmoneypl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int8fixeddecimalmi(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8smallmoneymi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int8fixeddecimalmul(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8smallmoneymul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int8fixeddecimaldiv_smallmoney(INT8, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int8smallmoneydiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- int4 <op> smallmoney
CREATE OR REPLACE FUNCTION sys.int4fixeddecimalpl(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4smallmoneypl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4fixeddecimalmi(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4smallmoneymi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4fixeddecimalmul(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4smallmoneymul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int4fixeddecimaldiv_smallmoney(INT4, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int4smallmoneydiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;


-- int2 <op> smallmoney
CREATE OR REPLACE FUNCTION sys.int2fixeddecimalpl(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2smallmoneypl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int2fixeddecimalmi(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2smallmoneymi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int2fixeddecimalmul(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2smallmoneymul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.int2fixeddecimaldiv_smallmoney(INT2, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_money', 'int2smallmoneydiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

/**
* Arithmetic operators for bit, smallmoney
*/

CREATE OR REPLACE FUNCTION sys.bitsmallmoneymi(sys.BIT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'bitsmallmoneymi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'sys.smallmoney'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '-' and oprresult != 0) THEN

		CREATE OPERATOR sys.- (
			LEFTARG    = sys.BIT,
			RIGHTARG   = sys.SMALLMONEY,
			PROCEDURE  = sys.bitsmallmoneymi
		);

	END IF;
END $$;



CREATE OR REPLACE FUNCTION sys.bitsmallmoneypl(sys.BIT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'bitsmallmoneypl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'sys.smallmoney'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN

		CREATE OPERATOR sys.+ (
			LEFTARG    = sys.BIT,
			RIGHTARG   = sys.SMALLMONEY,
			COMMUTATOR = +,
			PROCEDURE  = sys.bitsmallmoneypl
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.bitsmallmoneymul(sys.BIT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'bitsmallmoneymul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'sys.smallmoney'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '*' and oprresult != 0) THEN

		CREATE OPERATOR sys.* (
			LEFTARG    = sys.BIT,
			RIGHTARG   = sys.SMALLMONEY,
			PROCEDURE  = sys.bitsmallmoneymul
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.bitsmallmoneydiv(sys.BIT, sys.SMALLMONEY)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'bitsmallmoneydiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'sys.smallmoney'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '/' and oprresult != 0) THEN

		CREATE OPERATOR sys./ (
			LEFTARG    = sys.BIT,
			RIGHTARG   = sys.SMALLMONEY,
			PROCEDURE  = sys.bitsmallmoneydiv
		);

	END IF;
END $$;

/**
* Arithmetic operators for smallmoney, bit
*/

CREATE OR REPLACE FUNCTION sys.smallmoneybitmi(sys.SMALLMONEY, sys.BIT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'smallmoneybitmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.smallmoney'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '-' and oprresult != 0) THEN

		CREATE OPERATOR sys.- (
			LEFTARG    = sys.SMALLMONEY,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.smallmoneybitmi
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.smallmoneybitpl(sys.SMALLMONEY, sys.BIT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'smallmoneybitpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.smallmoney'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN

		CREATE OPERATOR sys.+ (
			LEFTARG    = sys.SMALLMONEY,
			RIGHTARG   = sys.BIT,
			COMMUTATOR = +,
			PROCEDURE  = sys.smallmoneybitpl
		);

	END IF;
END $$;


CREATE OR REPLACE FUNCTION sys.smallmoneybitmul(sys.SMALLMONEY, sys.BIT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'smallmoneybitmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.smallmoney'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '*' and oprresult != 0) THEN

		CREATE OPERATOR sys.* (
			LEFTARG    = sys.SMALLMONEY,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.smallmoneybitmul
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.smallmoneybitdiv(sys.SMALLMONEY, sys.BIT)
RETURNS sys.SMALLMONEY
AS 'babelfishpg_common', 'smallmoneybitdiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
	WHERE oprleft = 'sys.smallmoney'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
	and oprnamespace = 'sys'::regnamespace and oprname = '/' and oprresult != 0) THEN

		CREATE OPERATOR sys./ (
			LEFTARG    = sys.SMALLMONEY,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.smallmoneybitdiv
		);

	END IF;
END $$;

/**
* Arithmetic operators for float, bit
*/

CREATE OR REPLACE FUNCTION sys.floatbitmi(float8, sys.BIT)
RETURNS sys.float
AS 'babelfishpg_common', 'floatbitmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'float8'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '-' and oprresult != 0) THEN
		
		CREATE OPERATOR sys.- (
			LEFTARG    = float8,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.floatbitmi
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.floatbitpl(float8, sys.BIT)
RETURNS sys.float
AS 'babelfishpg_common', 'floatbitpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'float8'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN
		
		CREATE OPERATOR sys.+ (
			LEFTARG    = float8,
			RIGHTARG   = sys.BIT,
			COMMUTATOR = +,
			PROCEDURE  = sys.floatbitpl
		);

	END IF;
END $$;




CREATE OR REPLACE FUNCTION sys.floatbitmul(float8, sys.BIT)
RETURNS sys.float
AS 'babelfishpg_common', 'floatbitmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'float8'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '*' and oprresult != 0) THEN

		CREATE OPERATOR sys.* (
			LEFTARG    = float8,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.floatbitmul
		);

	END IF;
END $$;



CREATE OR REPLACE FUNCTION sys.floatbitdiv(float8, sys.BIT)
RETURNS sys.float
AS 'babelfishpg_common', 'floatbitdiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'float8'::pg_catalog.regtype and oprright = 'sys.bit'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '/' and oprresult != 0) THEN

		CREATE OPERATOR sys./ (
			LEFTARG    = float8,
			RIGHTARG   = sys.BIT,
			PROCEDURE  = sys.floatbitdiv
		);

	END IF;
END $$;

/**
* Arithmetic operators for bit, float
*/

CREATE OR REPLACE FUNCTION sys.bitfloatmi(sys.BIT, float8)
RETURNS sys.float
AS 'babelfishpg_common', 'bitfloatmi'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'float8'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '-' and oprresult != 0) THEN

		CREATE OPERATOR sys.- (
			LEFTARG    = sys.BIT,
			RIGHTARG   = float8,
			PROCEDURE  = sys.bitfloatmi
		);

	END IF;
END $$;


CREATE OR REPLACE FUNCTION sys.bitfloatpl(sys.BIT, float8)
RETURNS sys.float
AS 'babelfishpg_common', 'bitfloatpl'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'float8'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '+' and oprresult != 0) THEN

		CREATE OPERATOR sys.+ (
			LEFTARG    = sys.BIT,
			RIGHTARG   = float8,
			COMMUTATOR = +,
			PROCEDURE  = sys.bitfloatpl
		);
		
	END IF;
END $$;



CREATE OR REPLACE FUNCTION sys.bitfloatmul(sys.BIT, float8)
RETURNS sys.float
AS 'babelfishpg_common', 'bitfloatmul'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'float8'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '*' and oprresult != 0) THEN

		CREATE OPERATOR sys.* (
			LEFTARG    = sys.BIT,
			RIGHTARG   = float8,
			PROCEDURE  = sys.bitfloatmul
		);

	END IF;
END $$;



CREATE OR REPLACE FUNCTION sys.bitfloatdiv(sys.BIT, float8)
RETURNS sys.float
AS 'babelfishpg_common', 'bitfloatdiv'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

DO $$
BEGIN
	IF NOT EXISTS(SELECT 1 FROM pg_catalog.pg_operator 
		WHERE oprleft = 'sys.bit'::pg_catalog.regtype and oprright = 'float8'::pg_catalog.regtype 
		and oprnamespace = 'sys'::regnamespace and oprname = '/' and oprresult != 0) THEN

		CREATE OPERATOR sys./ (
			LEFTARG    = sys.BIT,
			RIGHTARG   = float8,
			PROCEDURE  = sys.bitfloatdiv
		);

	END IF;
END $$;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);