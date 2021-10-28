CREATE OR REPLACE PROCEDURE sys.babel_type_initializer()
LANGUAGE C
AS 'babelfishpg_common', 'init_tcode_trans_tab';
CALL sys.babel_type_initializer();
DROP PROCEDURE sys.babel_type_initializer();

CREATE OR REPLACE FUNCTION sys.babelfish_typecode_list()
RETURNS table (
  oid int,
  pg_namespace text,
  pg_typname text,
  tsql_typname text,
  type_family_priority smallint,
  priority smallint,
  sql_variant_hdr_size smallint
) AS 'babelfishpg_common', 'typecode_list' LANGUAGE C;
