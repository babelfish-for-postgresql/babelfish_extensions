-- Drop views
DROP VIEW IF EXISTS fts_rewrite_prepare_v1;
DROP VIEW IF EXISTS replace_special_chars_fts_prepare_v1;
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS fts_rewrite_prepare_p1;
DROP PROCEDURE IF EXISTS replace_special_chars_fts_prepare_p1;
GO

-- Drop functions
DROP FUNCTION IF EXISTS fts_rewrite_prepare_f1();
DROP FUNCTION IF EXISTS replace_special_chars_fts_prepare_f1();
GO