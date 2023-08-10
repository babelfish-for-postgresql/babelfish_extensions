-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.6.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.sysdatetime() RETURNS datetime2
    AS $$select statement_timestamp()::datetime2;$$
    LANGUAGE SQL;
GRANT EXECUTE ON FUNCTION sys.sysdatetime() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.sysdatetimeoffset() RETURNS sys.datetimeoffset
    -- Casting to text as there are not type cast function from timestamptz to datetimeoffset
    AS $$select cast(cast(statement_timestamp() as text) as sys.datetimeoffset);$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysdatetimeoffset() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.sysutcdatetime() RETURNS sys.datetime2
    AS $$select (statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime2;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.sysutcdatetime() TO PUBLIC;


CREATE OR REPLACE FUNCTION sys.getdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp()::pg_catalog.timestamp)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getdate() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.getutcdate() RETURNS sys.datetime
    AS $$select date_trunc('millisecond', statement_timestamp() AT TIME ZONE 'UTC'::pg_catalog.text)::sys.datetime;$$
    LANGUAGE SQL STABLE;
GRANT EXECUTE ON FUNCTION sys.getutcdate() TO PUBLIC;

CREATE OR REPLACE FUNCTION sys.SMALLDATETIMEFROMPARTS(IN p_year INTEGER,
                                                               IN p_month INTEGER,
                                                               IN p_day INTEGER,
                                                               IN p_hour INTEGER,
                                                               IN p_minute INTEGER
                                                               )
RETURNS sys.smalldatetime
AS
$BODY$
DECLARE
    v_ressmalldatetime TIMESTAMP WITHOUT TIME ZONE;
    v_string pg_catalog.text;
    p_seconds INTEGER;
BEGIN
    IF p_year IS NULL OR p_month is NULL OR p_day IS NULL OR p_hour IS NULL OR p_minute IS NULL THEN
        RETURN NULL;
    END IF;

    -- Check if arguments are out of range
    IF ((p_year NOT BETWEEN 1900 AND 2079) OR
        (p_month NOT BETWEEN 1 AND 12) OR
        (p_day NOT BETWEEN 1 AND 31) OR
        (p_hour NOT BETWEEN 0 AND 23) OR
        (p_minute NOT BETWEEN 0 AND 59)) OR (p_year = 2079 AND (p_month > 6 or p_day > 6))
    THEN
        RAISE invalid_datetime_format;
    END IF;
    p_seconds := 0;
    v_ressmalldatetime := make_timestamp(p_year,
                                    p_month,
                                    p_day,
                                    p_hour,
                                    p_minute,
                                    p_seconds);

    v_string := v_ressmalldatetime::pg_catalog.text;
    RETURN CAST(v_string AS sys.SMALLDATETIME);
EXCEPTION   
    WHEN invalid_datetime_format THEN
        RAISE USING MESSAGE := 'Cannot construct data type smalldatetime, some of the arguments have values which are not valid.',
                    DETAIL := 'Possible use of incorrect value of date or time part (which lies outside of valid range).',
                    HINT := 'Check each input argument belongs to the valid range and try again.';
END;
$BODY$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION objectproperty(
    id INT,
    property SYS.VARCHAR
    )
RETURNS INT AS
'babelfishpg_tsql', 'objectproperty_internal'
LANGUAGE C STABLE;

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
