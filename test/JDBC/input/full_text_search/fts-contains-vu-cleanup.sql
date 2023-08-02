-- enable CONTAINS
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

DROP PROCEDURE fts_contains_vu_prepare_p1;
GO

DROP TABLE fts_contains_vu_t;
GO

DROP VIEW fts_contains_rewrite_v1
GO

DROP VIEW fts_contains_pgconfig_v1
GO

-- disable CONTAINS
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO
