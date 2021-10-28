-- Manually initialize translation table
CREATE OR REPLACE PROCEDURE babel_coercion_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_tsql_coerce_hash_tab';
CALL babel_coercion_initializer();

-- Manually initialize translation table
CREATE OR REPLACE PROCEDURE babel_datatype_precedence_initializer()
LANGUAGE C
AS 'babelfishpg_tsql', 'init_tsql_datatype_precedence_hash_tab';
CALL babel_datatype_precedence_initializer();
