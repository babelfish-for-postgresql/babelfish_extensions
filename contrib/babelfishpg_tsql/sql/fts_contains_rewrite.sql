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
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;
