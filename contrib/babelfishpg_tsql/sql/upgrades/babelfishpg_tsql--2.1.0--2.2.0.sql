-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '2.2.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops a view if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_view(schema_name varchar, view_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN
    query1 := format('alter extension babelfishpg_tsql drop view %s.%s', schema_name, view_name);
    query2 := format('drop view %s.%s', schema_name, view_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;


-- please add your SQL here

CREATE OR REPLACE FUNCTION sys.DBTS()
RETURNS sys.ROWVERSION AS
$$
DECLARE
    eh_setting text;
BEGIN
    eh_setting = (select s.setting FROM pg_catalog.pg_settings s where name = 'babelfishpg_tsql.escape_hatch_rowversion');
    IF eh_setting = 'strict' THEN
        RAISE EXCEPTION 'DBTS is not currently supported in Babelfish. please use babelfishpg_tsql.escape_hatch_rowversion to ignore';
    ELSE
        RETURN sys.get_current_full_xact_id()::sys.ROWVERSION;
    END IF;
END;
$$
STRICT
LANGUAGE plpgsql;

INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_ai', N'Estonian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_ci_as', N'Estonian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'estonian_cs_as', N'Estonian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_ai', N'Greek, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_ci_as', N'Greek, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'greek_cs_as', N'Greek, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_ai', N'Hebrew, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_ci_as', N'Hebrew, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitives');
INSERT INTO sys.babelfish_helpcollation VALUES (N'hebrew_cs_as', N'Hebrew, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_ai', N'Japanese, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_ci_as', N'Japanese, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'japanese_cs_as', N'Japanese, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_ai', N'Mongolian, case-insensitive, accent-insensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_ci_as', N'Mongolian, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'mongolian_cs_as', N'Mongolian, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_ci_as', N'Virtual, default locale, code page 874, case-insensitive, accent-sensitive, kanatype-insensitive, width-insensitive');
INSERT INTO sys.babelfish_helpcollation VALUES (N'sql_latin1_general_cp874_cs_as', N'Virtual, default locale, code page 874, case-sensitive, accent-sensitive, kanatype-insensitive, width-insensitive');

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_view(varchar, varchar);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);