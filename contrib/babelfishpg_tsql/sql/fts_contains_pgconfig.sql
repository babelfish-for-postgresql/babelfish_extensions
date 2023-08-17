-- Given the query string, determine the Postgres full text configuration to use
-- Currently we only support simple terms, so the function simply returns 'fts_contains'
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_pgconfig(IN phrase text)
  RETURNS regconfig AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  RETURN 'fts_contains'::regconfig;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 