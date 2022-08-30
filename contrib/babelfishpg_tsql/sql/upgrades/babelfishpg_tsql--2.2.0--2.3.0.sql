-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE FUNCTION sys.dateadd(IN datepart PG_CATALOG.TEXT, IN num INTEGER, IN startdate TEXT) RETURNS DATETIME
AS
$body$
DECLARE
    is_date INT;
BEGIN
    is_date = sys.isdate(startdate);
    IF (is_date = 1) THEN 
        RETURN sys.dateadd_internal(datepart,num,startdate::datetime);
    ELSE   
        RAISE EXCEPTION 'Conversion failed when converting date and/or time from character string.';
    END IF;
END;
$body$
LANGUAGE plpgsql IMMUTABLE;


-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);
DROP PROCEDURE sys.babelfish_remove_object_from_extension(varchar, varchar);
DROP PROCEDURE sys.babelfish_drop_deprecated_function(varchar, varchar);
DROP PROCEDURE sys.babelfish_drop_deprecated_table(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
