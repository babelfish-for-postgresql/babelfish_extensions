-- tsql full-text search configurations for Babelfish
-- Since currently we only support one language - American English, 
-- the configurations are for American English only

-- create a configuration fts_contains_simple for simple terms search
CREATE TEXT SEARCH DICTIONARY fts_contains_simple_dict (
    TEMPLATE = simple,
    STOPWORDS = tsql_contains
);

COMMENT ON TEXT SEARCH DICTIONARY fts_contains_simple_dict IS 'Babelfish T-SQL full text search CONTAINS dictionary (currently we only support American English)';

CREATE TEXT SEARCH CONFIGURATION fts_contains_simple ( COPY = simple );

COMMENT ON TEXT SEARCH CONFIGURATION fts_contains_simple IS 'Babelfish T-SQL full text search CONTAINS configuration (currently we only support American English)';

ALTER TEXT SEARCH CONFIGURATION fts_contains_simple
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH fts_contains_simple_dict;



-- Create a configuration english_inflectional_babel for inflectional search
-- first english_inflectional_babel is created as a copy of the build-in Postgres english configuration
CREATE TEXT SEARCH DICTIONARY english_stem_babel
	(TEMPLATE = snowball, Language = english , StopWords=tsql_contains);

COMMENT ON TEXT SEARCH DICTIONARY english_stem_babel IS 'snowball stemmer for english_inflectional_babel language';

CREATE TEXT SEARCH CONFIGURATION english_inflectional_babel
	(PARSER = default);

COMMENT ON TEXT SEARCH CONFIGURATION english_inflectional_babel IS 'configuration for english_inflectional_babel language';

ALTER TEXT SEARCH CONFIGURATION english_inflectional_babel ADD MAPPING
	FOR email, url, url_path, host, file, version,
	    sfloat, float, int, uint,
	    numword, hword_numpart, numhword
	WITH simple;

ALTER TEXT SEARCH CONFIGURATION english_inflectional_babel ADD MAPPING
    FOR asciiword, hword_asciipart, asciihword
	WITH english_stem_babel;

ALTER TEXT SEARCH CONFIGURATION english_inflectional_babel ADD MAPPING
    FOR word, hword_part, hword
	WITH english_stem_babel;

-- then we add irregular verbs as synonym files to english_inflectional_babel for inflectional search
CREATE TEXT SEARCH DICTIONARY irregular_verbs (
    TEMPLATE = synonym,
    SYNONYMS = irregular_verbs
);

ALTER TEXT SEARCH CONFIGURATION english_inflectional_babel
    ALTER MAPPING FOR asciiword
    WITH irregular_verbs, english_stem_babel;
