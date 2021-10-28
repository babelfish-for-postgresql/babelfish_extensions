-- CAST and related functions.
-- Duplicate functions with arg TEXT since ANYELEMNT cannot handle type unknown.


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg TEXT)
RETURNS SMALLINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS SMALLINT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_smallint(IN arg ANYELEMENT)
RETURNS SMALLINT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS SMALLINT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS SMALLINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg TEXT)
RETURNS INT
AS $BODY$ BEGIN
    RETURN CAST(arg AS INT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_int(IN arg ANYELEMENT)
RETURNS INT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS INT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS INT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg TEXT)
RETURNS BIGINT
AS $BODY$ BEGIN
    RETURN CAST(arg AS BIGINT);
END; $BODY$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION sys.babelfish_cast_floor_bigint(IN arg ANYELEMENT)
RETURNS BIGINT
AS $BODY$ BEGIN
    CASE pg_typeof(arg)
        WHEN 'numeric'::regtype, 'double precision'::regtype, 'real'::regtype THEN
            RETURN CAST(TRUNC(arg) AS BIGINT);
        WHEN 'sys.money'::regtype, 'sys.smallmoney'::regtype THEN
            RETURN CAST(ROUND(arg) AS BIGINT);
        ELSE
            RETURN CAST(arg AS BIGINT);
    END CASE;
END; $BODY$
LANGUAGE plpgsql;


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


CREATE OR REPLACE FUNCTION sys.babelfish_try_cast_to_any(IN arg TEXT, INOUT output ANYELEMENT, IN typmod INT)
RETURNS ANYELEMENT
AS $BODY$ BEGIN
    EXECUTE format('SELECT CAST(%L AS %s)', arg, format_type(pg_typeof(output), typmod)) INTO output;
    EXCEPTION
        WHEN OTHERS THEN
            -- Do nothing. Output carries NULL.
END; $BODY$
LANGUAGE plpgsql;
