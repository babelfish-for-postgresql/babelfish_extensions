CREATE EXTENSION "babelfishpg_tsql";

CREATE SCHEMA IF NOT EXISTS dbo;
ALTER SYSTEM SET search_path = dbo, "$user", public;
SELECT pg_reload_conf();

CREATE OR REPLACE FUNCTION dbo.stuff(src text, start int, len int, replacement text)
  RETURNS text AS 
  $$ SELECT overlay($1 PLACING $4 FROM $2 FOR $3) $$
  LANGUAGE 'sql';


CREATE FUNCTION dbo.len(arg text)
  RETURNS integer AS 
  $$ SELECT pg_catalog.length($1); $$
  LANGUAGE 'sql';
