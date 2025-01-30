-- tsql user=jdbc_user password=12345678
-- enable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- Remove fulltext index
DROP FULLTEXT INDEX ON test_tb
GO

DROP FULLTEXT INDEX ON fts_schema.test_tb1
GO

DROP FULLTEXT INDEX ON content_table
GO

-- Remove the table
DROP TABLE IF EXISTS test_tb
GO

DROP TABLE IF EXISTS fts_schema.test_tb1
GO

DROP TABLE IF EXISTS content_table
GO

-- Remove schema
DROP SCHEMA IF EXISTS fts_schema
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO