-- Given the query string, determine the Postgres full text configuration to use
-- Currently we only support simple terms and prefix terms
-- For simple terms, we use the 'fts_contains_simple' configuration
-- For prefix terms, we use the 'simple' configuration
-- They are the configurations that provide closest matching according to our experiments
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_pgconfig(IN phrase text)
  RETURNS regconfig AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  /* 'Prefix term (Examples: '"word1*"', '"word1 word2*"') if 
   * (1) search term is surrounded by double quotes (Counter example: 'word1*', as it doesn't have double quotes)
   * (2) last word in the search term ends with a star (Counter example: '"word1* word2"', as last word doesn't end with star)
   * (3) last word is NOT a single star (Counter example: '"*"', '"word1 word2 *"', as last word is a single star)
  */
  IF (phrase COLLATE C) SIMILAR TO ('[ ]*"%\*"[ ]*' COLLATE C) AND (NOT (phrase COLLATE C) SIMILAR TO ('[ ]*"% \*"[ ]*' COLLATE C)) AND (NOT (phrase COLLATE C) SIMILAR TO ('[ ]*"\*"[ ]*' COLLATE C)) THEN
    RETURN 'simple'::regconfig;
  END IF;

  -- Generation term, inflectional (Examples: 'FORMSOF(INFLECTIONAL, love)', 'FORMSOF(INFLECTIONAL, "move forward")', 'FORMSOF(INFLECTIONAL, play, "plan to")')
  IF UPPER(phrase COLLATE C) SIMILAR TO ('[ ]*FORMSOF\(INFLECTIONAL,%\)[ ]*' COLLATE C) THEN
    RETURN 'english_inflectional_babel'::regconfig;
  END IF;

  -- Generation term, thesaurus (Examples: 'FORMSOF(THESAURUS, love)', 'FORMSOF(THESAURUS, "move forward")', 'FORMSOF(THESAURUS, play, "plan to")')
  -- By default, SQL Server thesaurus search does not use any thesaurus files so behavior is identical to simple terms
  IF UPPER(phrase COLLATE C) SIMILAR TO ('[ ]*FORMSOF\(THESAURUS,%\)[ ]*' COLLATE C) THEN
    RETURN 'fts_contains_simple'::regconfig;
  END IF;

  -- Simple term
  RETURN 'fts_contains_simple'::regconfig;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 