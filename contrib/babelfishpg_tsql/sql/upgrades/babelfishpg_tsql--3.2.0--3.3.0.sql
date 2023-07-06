-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '3.3.0'" to load this file. \quit

-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

-- Drops an object if it does not have any dependent objects.
-- Is a temporary procedure for use by the upgrade script. Will be dropped at the end of the upgrade.
-- Please have this be one of the first statements executed in this upgrade script. 
CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar) AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
BEGIN

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s.%s', object_type, schema_name, object_name);
    query2 := pg_catalog.format('drop %s %s.%s', object_type, schema_name, object_name);

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

CREATE OR REPLACE PROCEDURE sys.sp_execute_postgresql(IN "@postgresStmt" sys.nvarchar)
AS 'babelfishpg_tsql', 'sp_execute_postgresql' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_execute_postgresql(IN sys.nvarchar) TO PUBLIC;

ALTER FUNCTION sys.parsename(VARCHAR,INT) RENAME TO parsename_deprecated_in_3_3_0;

CREATE OR REPLACE FUNCTION sys.parsename(object_name sys.VARCHAR, object_piece int)
RETURNS sys.SYSNAME
AS 'babelfishpg_tsql', 'parsename'
LANGUAGE C IMMUTABLE STRICT;

CALL sys.babelfish_drop_deprecated_object('function', 'sys', 'parsename_deprecated_in_3_3_0');

CREATE OR REPLACE FUNCTION sys.EOMONTH(date,int DEFAULT 0)
RETURNS date
AS 'babelfishpg_tsql', 'EOMONTH'
LANGUAGE C STABLE PARALLEL SAFE;

ALTER TABLE sys.babelfish_server_options ADD COLUMN IF NOT EXISTS connect_timeout INT;



-- This function performs string rewriting for the full text search CONTAINS predicate
-- in Babelfish

-- For example, a T-SQL query 
-- SELECT * FROM t WHERE CONTAINS(txt, '"good old days"')
-- is rewritten into a Postgres query 
-- SELECT * FROM t WHERE to_tsvector('fts_contains', txt) @@ to_tsquery('fts_contains', 'good <-> old <-> days')
-- In particular, the string constant '"good old days"' gets rewritten into 'good <-> old <-> days'
-- This function performs the string rewriting from '"good old days"' to 'good <-> old <-> days'

CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_rewrite(IN phrase text)
  RETURNS TEXT AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  -- Initialize the joined_text variable
  joined_text := '';

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- no rewriting is needed if the query is a single word
  IF position((' ' COLLATE C) IN (phrase COLLATE "C")) = 0 THEN
    RETURN phrase;
  END IF;

  -- rewrite phrase queries 
  -- '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'

  -- Check if the phrase is surrounded by double quotes
  IF position(('"' COLLATE "C") IN (phrase COLLATE "C") ) <> 1 OR position(('"' COLLATE "C") IN (reverse(phrase) COLLATE "C")) <> 1 THEN
    RAISE EXCEPTION 'Phrase must be surrounded by double quotes';
  END IF;

  -- Strip the double quotes from the phrase
  phrase := substring(phrase COLLATE "C", 2, length(phrase) - 2) COLLATE "C";

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- Split the phrase into an array of words
  FOREACH word IN ARRAY regexp_split_to_array(phrase COLLATE "C", '\s+' COLLATE "C") COLLATE "C" LOOP
    -- Append the word to the joined_text variable
    joined_text := joined_text || word || '<->';
  END LOOP;

  -- Remove the trailing "<->" from the joined_text
  joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 3) COLLATE "C";

  -- Return the joined_text
  RETURN joined_text;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 
-- Removing IMMUTABLE PARALLEL SAFE will disallow parallel mode for full text search


/*
 * tsql full-text search configurations for Babelfish
 */

CREATE TEXT SEARCH DICTIONARY fts_contains_dict (
    TEMPLATE = simple,
    STOPWORDS = tsql_contains
);

COMMENT ON TEXT SEARCH DICTIONARY fts_contains_dict IS 'Babelfish T-SQL full text search CONTAINS dictionary';

CREATE TEXT SEARCH CONFIGURATION fts_contains ( COPY = simple );

COMMENT ON TEXT SEARCH CONFIGURATION fts_contains IS 'Babelfish T-SQL full text search CONTAINS configuration';

ALTER TEXT SEARCH CONFIGURATION fts_contains
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH fts_contains_dict;




-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);

CREATE OR REPLACE PROCEDURE sys.sp_testlinkedserver(IN "@servername" sys.sysname)
AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal' LANGUAGE C;
GRANT EXECUTE on PROCEDURE sys.sp_testlinkedserver(IN sys.sysname) TO PUBLIC;

CREATE OR REPLACE PROCEDURE master_dbo.sp_testlinkedserver( IN "@servername" sys.sysname)
AS 'babelfishpg_tsql', 'sp_testlinkedserver_internal'
LANGUAGE C;

ALTER PROCEDURE master_dbo.sp_testlinkedserver OWNER TO sysadmin;

create or replace view sys.shipped_objects_not_in_sys AS
-- This portion of view retrieves information on objects that reside in a schema in one specfic database.
-- For example, 'master_dbo' schema can only exist in the 'master' database.
-- Internally stored schema name (nspname) must be provided.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('xp_qv','master_dbo','P'),
    ('xp_instance_regread','master_dbo','P'),
    ('sp_addlinkedserver', 'master_dbo', 'P'),
    ('sp_addlinkedsrvlogin', 'master_dbo', 'P'),
    ('sp_dropserver', 'master_dbo', 'P'),
    ('sp_droplinkedsrvlogin', 'master_dbo', 'P'),
    ('sp_testlinkedserver', 'master_dbo', 'P'),
    ('fn_syspolicy_is_automation_enabled', 'msdb_dbo', 'FN'),
    ('syspolicy_configuration', 'msdb_dbo', 'V'),
    ('syspolicy_system_health_state', 'msdb_dbo', 'V')
) t(name,schema_name, type)
inner join pg_catalog.pg_namespace ns on t.schema_name = ns.nspname

union all

-- This portion of view retrieves information on objects that reside in a schema in any number of databases.
-- For example, 'dbo' schema can exist in the 'master', 'tempdb', 'msdb', and any user created database.
select t.name,t.type, ns.oid as schemaid from
(
  values
    ('sysdatabases','dbo','V')
) t (name, schema_name, type)
inner join sys.babelfish_namespace_ext b on t.schema_name = b.orig_name
inner join pg_catalog.pg_namespace ns on b.nspname = ns.nspname;
GRANT SELECT ON sys.shipped_objects_not_in_sys TO PUBLIC;

-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar);


/*
 * tsql full-text search configurations for Babelfish
 */

CREATE TEXT SEARCH DICTIONARY fts_contains_dict (
    TEMPLATE = simple,
    STOPWORDS = tsql_contains
);

COMMENT ON TEXT SEARCH DICTIONARY fts_contains_dict IS 'Babelfish T-SQL full text search CONTAINS dictionary';

CREATE TEXT SEARCH CONFIGURATION fts_contains ( COPY = simple );

COMMENT ON TEXT SEARCH CONFIGURATION fts_contains IS 'Babelfish T-SQL full text search CONTAINS configuration';

ALTER TEXT SEARCH CONFIGURATION fts_contains
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH fts_contains_dict;



-- This function performs string rewriting for the full text search CONTAINS predicate
-- in Babelfish

-- For example, a T-SQL query 
-- SELECT * FROM t WHERE CONTAINS(txt, '"good old days"')
-- is rewritten into a Postgres query 
-- SELECT * FROM t WHERE to_tsvector('fts_contains', txt) @@ to_tsquery('fts_contains', 'good <-> old <-> days')
-- In particular, the string constant '"good old days"' gets rewritten into 'good <-> old <-> days'
-- This function performs the string rewriting from '"good old days"' to 'good <-> old <-> days'

CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_rewrite(IN phrase text)
  RETURNS TEXT AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  -- Initialize the joined_text variable
  joined_text := '';

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- no rewriting is needed if the query is a single word
  IF position((' ' COLLATE C) IN (phrase COLLATE "C")) = 0 THEN
    RETURN phrase;
  END IF;

  -- rewrite phrase queries 
  -- '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'

  -- Check if the phrase is surrounded by double quotes
  IF position(('"' COLLATE "C") IN (phrase COLLATE "C") ) <> 1 OR position(('"' COLLATE "C") IN (reverse(phrase) COLLATE "C")) <> 1 THEN
    RAISE EXCEPTION 'Phrase must be surrounded by double quotes';
  END IF;

  -- Strip the double quotes from the phrase
  phrase := substring(phrase COLLATE "C", 2, length(phrase) - 2) COLLATE "C";

  -- Strip leading and trailing spaces from the phrase
  phrase := trim(phrase COLLATE "C") COLLATE "C";

  -- Split the phrase into an array of words
  FOREACH word IN ARRAY regexp_split_to_array(phrase COLLATE "C", '\s+' COLLATE "C") COLLATE "C" LOOP
    -- Append the word to the joined_text variable
    joined_text := joined_text || word || '<->';
  END LOOP;

  -- Remove the trailing "<->" from the joined_text
  joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 3) COLLATE "C";

  -- Return the joined_text
  RETURN joined_text;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 
-- Removing IMMUTABLE PARALLEL SAFE will disallow parallel mode for full text search


-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);



