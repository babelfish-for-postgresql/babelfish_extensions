-- This function performs string rewriting for the full text search CONTAINS predicate
-- in Babelfish
-- For example, a T-SQL query 
-- SELECT * FROM t WHERE CONTAINS(txt, '"good old days"')
-- is rewritten into a Postgres query 
-- SELECT * FROM t WHERE to_tsvector('fts_contains', txt) @@ to_tsquery('fts_contains', 'good <-> old <-> days')
-- In particular, the string constant '"good old days"' gets rewritten into 'good <-> old <-> days'
-- This function performs the string rewriting from '"good old days"' to 'good <-> old <-> days'
-- For prefix terms, '"word1*"' is rewritten into 'word1:*', and '"word1 word2 word3*"' is rewritten into 'word1<->word2<->word3:*'
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_rewrite(IN phrase text)
  RETURNS TEXT AS
$$
BEGIN
  
  return babelfish_fts_rewrite(phrase);
  -- -- boolean operators not supported
  -- IF position(('&' COLLATE C) IN (phrase COLLATE "C")) <> 0 OR position(('|' COLLATE C) IN (phrase COLLATE "C")) <> 0 OR position(('&!' COLLATE C) IN (phrase COLLATE "C")) <> 0 THEN
  --   RAISE EXCEPTION 'Boolean operators not supported';
  -- END IF;
  
  -- IF position((' AND ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 OR position((' OR ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 OR position((' AND NOT ' COLLATE C) IN UPPER(phrase COLLATE "C")) <> 0 THEN
  --   RAISE EXCEPTION 'Boolean operators not supported';
  -- END IF;

  -- -- Generation term, inflectional
  -- IF UPPER(phrase COLLATE C) SIMILAR TO ('[ ]*FORMSOF\(INFLECTIONAL,%\)[ ]*' COLLATE C) THEN
  --   RETURN sys.babelfish_fts_contains_generation_term_helper(phrase);
  -- END IF;

  -- -- Generation term, thesaurus
  -- IF UPPER(phrase COLLATE C) SIMILAR TO ('[ ]*FORMSOF\(THESAURUS,%\)[ ]*' COLLATE C) THEN
  --   RETURN sys.babelfish_fts_contains_generation_term_helper(phrase);
  -- END IF;

  -- -- Simple term
  -- joined_text := sys.babelfish_fts_contains_phrase_helper(phrase);

  -- -- Prefix term (Examples: '"word1*"', '"word1 word2*"') if 
  -- -- (1) search term is surrounded by double quotes (Counter example: 'word1*', as it doesn't have double quotes)
  -- -- (2) last word in the search term ends with a star (Counter example: '"word1* word2"', as last word doesn't end with star)
  -- -- (3) last word is NOT a single star (Counter example: '"*"', '"word1 word2 *"', as last word is a single star)
  -- -- We need to rewrite the last word into 'lastword:*'
  -- IF (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"%\*"[ ]*' COLLATE C) AND (NOT (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"% \*"[ ]*' COLLATE C)) AND (NOT (orig_phrase COLLATE C) SIMILAR TO ('[ ]*"\*"[ ]*' COLLATE C)) THEN
  --   joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 1) || ':*';
  -- END IF;

  -- -- Return the joined_text
  -- RETURN joined_text;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 
-- Removing IMMUTABLE PARALLEL SAFE will disallow parallel mode for full text search


-- -- Helper function that takes in a word or phrase and returns the same word/phrase in Postgres format
-- -- Example: 'word' is rewritten into 'word'; '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'
-- CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_phrase_helper(IN phrase text)
--   RETURNS TEXT AS
-- $$
-- DECLARE
--   joined_text text;
--   word text;
-- BEGIN
--   -- Initialize the joined_text variable
--   joined_text := '';

--   -- Strip leading and trailing spaces from the phrase
--   phrase := trim(phrase COLLATE "C") COLLATE "C";

--   -- no rewriting is needed if the query is a single word
--   IF position((' ' COLLATE C) IN (phrase COLLATE "C")) = 0 AND position(('"' COLLATE C) IN UPPER(phrase COLLATE "C")) = 0 THEN
--     RETURN phrase;
--   END IF;

--   -- rewrite phrase queries 
--   -- '"word1 word2 word3"' is rewritten into 'word1<->word2<->word3'

--   -- Check if the phrase is surrounded by double quotes
--   IF position(('"' COLLATE "C") IN (phrase COLLATE "C") ) <> 1 OR position(('"' COLLATE "C") IN (reverse(phrase) COLLATE "C")) <> 1 THEN
--     RAISE EXCEPTION 'Phrase must be surrounded by double quotes';
--   END IF;

--   -- Strip the double quotes from the phrase
--   phrase := substring(phrase COLLATE "C", 2, length(phrase) - 2) COLLATE "C";

--   -- Strip leading and trailing spaces from the phrase
--   phrase := trim(phrase COLLATE "C") COLLATE "C";

--   -- Split the phrase into an array of words
--   FOREACH word IN ARRAY regexp_split_to_array(phrase COLLATE "C", '\s+' COLLATE "C") COLLATE "C" LOOP
--     -- Append the word to the joined_text variable
--     joined_text := joined_text || word || '<->';
--   END LOOP;

--   -- Remove the trailing "<->" from the joined_text
--   joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 3) COLLATE "C";

--   RETURN joined_text;

-- END;
-- $$
-- LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 

-- -- Helper function that takes in a generation term rewrites it into Postgres format
-- -- Example: 
-- -- 'FORMFSOF(INFLECTIONAL, word)' is rewritten into 'word'; 
-- -- 'FORMFSOF(INFLECTIONAL, "word1 word2")' is rewritten into 'word1<->word2';
-- -- 'FORMFSOF(INFLECTIONAL, word1, word2)' is rewritten into 'word1 | word2';
-- -- 'FORMFSOF(INFLECTIONAL, word1, "word2 word3")' is rewritten into 'word1 | (word2<->word3)';
-- -- Rewriting logic for THESAURUS is the same as for INFLECTIONAL
-- -- Precondition: phrase matches '[ ]*FORMSOF(INFLECTIONAL,%)[ ]%' or '[ ]*FORMSOF(THESAURUS,%)[ ]%'
-- CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_generation_term_helper(IN phrase text)
--   RETURNS TEXT AS
-- $$
-- DECLARE
--   joined_text text;
--   subterm text;
-- BEGIN
--   -- Initialize the joined_text variable
--   joined_text := '';

--   -- Strip leading and trailing spaces from the phrase
--   phrase := trim(phrase COLLATE "C") COLLATE "C";

--   -- Strip FORMSOF, INFLECTIONAL/THESAURUS, and parenthesis
--   phrase := substring(phrase COLLATE "C", position((',' COLLATE C) IN (phrase COLLATE "C")) + 1, length(phrase) - position((',' COLLATE C) IN (phrase COLLATE "C")) - 1) COLLATE "C";

--   -- Split the phrase into an array of words
--   FOREACH subterm IN ARRAY regexp_split_to_array(phrase COLLATE "C", ',' COLLATE "C") COLLATE "C" LOOP
--     -- Append the word to the joined_text variable
--     joined_text := joined_text || '(' || sys.babelfish_fts_contains_phrase_helper(subterm) || ')' || ' | ';
--   END LOOP;

--   -- Remove the trailing " | " from the joined_text
--   joined_text := substring(joined_text COLLATE "C", 1, length(joined_text) - 3) COLLATE "C";

--   RETURN joined_text;

-- END;
-- $$
-- LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 
