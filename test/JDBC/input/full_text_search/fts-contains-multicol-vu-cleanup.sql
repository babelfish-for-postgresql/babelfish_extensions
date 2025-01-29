-- tsql user=jdbc_user password=12345678
-- enable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- Remove fulltext index
DROP FULLTEXT INDEX ON test_tb
GO

DROP FULLTEXT INDEX ON test_tb1
GO

-- Remove the table
DROP TABLE IF EXISTS test_tb
GO

DROP TABLE IF EXISTS test_tb1
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO