-- CAST and related functions.
-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg TEXT)
RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS SMALLINT);
END; $BODY$
LANGUAGE plpgsql
STABLE;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT)
RETURNS SMALLINT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS SMALLINT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS SMALLINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg TEXT)
RETURNS INT
AS $BODY$ BEGIN
    RETURN CAST(arg AS INT);
END; $BODY$
LANGUAGE plpgsql
STABLE;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT)
RETURNS INT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS INT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS INT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg TEXT)
RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS BIGINT);
END; $BODY$
LANGUAGE plpgsql
STABLE;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT)
RETURNS BIGINT
AS $BODY$
DECLARE
    arg_datatype text;
    arg_datatype_oid oid;
    basetype oid;
BEGIN
    arg_datatype_oid := pg_typeof(arg)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    CASE arg_datatype
        WHEN 'numeric', 'double precision', 'real', 'decimal', 'float' THEN
            RETURN CAST(TRUNC(arg) AS BIGINT);
        WHEN 'money', 'smallmoney' THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS BIGINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql
STABLE;


-- TRY_CAST helper functions
CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_smallint(IN arg TEXT) RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_smallint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_smallint(IN arg ANYELEMENT) RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_smallint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_int(IN arg TEXT) RETURNS INT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_int(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_int(IN arg ANYELEMENT) RETURNS INT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_int(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_bigint(IN arg TEXT) RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_bigint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_floor_bigint(IN arg ANYELEMENT) RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN sys.babelfish_cast_floor_bigint(arg);
    EXCEPTION WHEN OTHERS THEN RETURN NULL;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_real(IN arg TEXT) RETURNS REAL
AS $BODY$ BEGIN
    BEGIN
        RETURN CAST(arg::sys.varchar AS REAL);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_real(IN arg ANYELEMENT) RETURNS REAL
AS $BODY$ BEGIN
    BEGIN
        RETURN CAST(arg AS REAL);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END; $BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_float(arg ANYELEMENT, p INT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
DECLARE
    v DOUBLE PRECISION;
BEGIN
    BEGIN
        v := CAST(arg AS DOUBLE PRECISION);

        IF p IS NOT NULL AND p BETWEEN 1 AND 24 THEN
            v := CAST(CAST(v AS REAL) AS DOUBLE PRECISION);
        END IF;

        RETURN v;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END; $$;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_float(arg TEXT, p INT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        RETURN sys.babelfish_try_cast_float(arg::sys.varchar, p);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
END; $$;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg TEXT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
    RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_datetime2(IN arg ANYELEMENT, IN typmod INTEGER)
RETURNS sys.DATETIME2
AS $BODY$
BEGIN
     RETURN CASE typmod
            WHEN 0 THEN CAST(arg as DATETIME2(0))
            WHEN 1 THEN CAST(arg as DATETIME2(1))
            WHEN 2 THEN CAST(arg as DATETIME2(2))
            WHEN 3 THEN CAST(arg as DATETIME2(3))
            WHEN 4 THEN CAST(arg as DATETIME2(4))
            WHEN 5 THEN CAST(arg as DATETIME2(5))
            ELSE CAST(arg as DATETIME2(6))
        END;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to datetime2.',
                                      pg_typeof(arg));
        WHEN OTHERS THEN
            RETURN NULL;
END; $BODY$
LANGUAGE plpgsql
STABLE;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg ANYELEMENT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'bytea'::regtype, 'sys.varbinary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.varbinarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		WHEN 'sys.binary'::regtype THEN
			IF lower(typename) LIKE 'nvarchar%' THEN
				RETURN (sys.binarysysnvarchar(arg, -1, true));
			ELSE
				RETURN CAST(arg AS sys.VARCHAR);
			END IF;
		ELSE
			RETURN CAST(arg AS sys.VARCHAR);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varchar(IN typename TEXT, IN arg TEXT)
RETURNS sys.VARCHAR
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.VARCHAR);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg ANYELEMENT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		CASE pg_typeof(arg)
		WHEN 'sys.nvarchar'::regtype THEN
			RETURN sys.nvarcharvarbinary(arg, -1, true);
		WHEN 'sys.nchar'::regtype THEN
			RETURN sys.ncharvarbinary(arg, -1, true);
		ELSE
			RETURN CAST(arg AS sys.varbinary);
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_varbinary(IN arg TEXT)
RETURNS sys.varbinary
AS
$BODY$
BEGIN
	BEGIN
		RETURN CAST(arg AS sys.varbinary);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN NULL;
	END;
END;
$BODY$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg ANYCOMPATIBLE, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE pg_catalog.format('SELECT CAST(CAST(%L AS %s) AS %s)', arg, format_type(pg_typeof(arg), NULL), format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN cannot_coerce THEN
            RAISE USING MESSAGE := pg_catalog.format('cannot cast type %s to %s.', pg_typeof(arg),
                                      pg_typeof(output));
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;
