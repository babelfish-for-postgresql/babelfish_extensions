-- tsql full-text search configurations for Babelfish
-- Since currently we only support one language - American English, 
-- this configuration is for American English only
CREATE TEXT SEARCH DICTIONARY fts_contains_dict (
    TEMPLATE = simple,
    STOPWORDS = tsql_contains
);

COMMENT ON TEXT SEARCH DICTIONARY fts_contains_dict IS 'Babelfish T-SQL full text search CONTAINS dictionary (currently we only support American English)';

CREATE TEXT SEARCH CONFIGURATION fts_contains ( COPY = simple );

COMMENT ON TEXT SEARCH CONFIGURATION fts_contains IS 'Babelfish T-SQL full text search CONTAINS configuration (currently we only support American English)';

ALTER TEXT SEARCH CONFIGURATION fts_contains
    ALTER MAPPING FOR asciiword, asciihword, hword_asciipart,
                      word, hword, hword_part
    WITH fts_contains_dict;
