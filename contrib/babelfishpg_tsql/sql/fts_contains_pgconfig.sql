-- Given the query string, determine the Postgres full text configuration to use
-- Currently we only support simple terms and prefix terms
-- For simple terms, we use the 'fts_contains' configuration
-- For prefix terms, we use the 'simple' configuration
-- They are the configurations that provide closest matching according to our experiments
CREATE OR REPLACE FUNCTION sys.babelfish_fts_contains_pgconfig(IN phrase text)
  RETURNS regconfig AS
$$
DECLARE
  joined_text text;
  word text;
BEGIN
  -- Prefix term
  IF (phrase COLLATE C) SIMILAR TO ('[ ]*"%\*"[ ]*' COLLATE C) THEN
    RETURN 'simple'::regconfig;
  END IF;
  -- Simple term
  RETURN 'fts_contains'::regconfig;
END;
$$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE; 