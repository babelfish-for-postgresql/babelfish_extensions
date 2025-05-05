SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- Drop views
DROP VIEW IF EXISTS prefix_rewrite_prepare_v1
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v2
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v3
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v4
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v5
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v6
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v7
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v8
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v9
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v10
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v11
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v12
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v13
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v14
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v15
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v16
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v17
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v18
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v19
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v20
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v21
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v22
GO
DROP VIEW IF EXISTS prefix_rewrite_prepare_v23
GO
DROP VIEW IF EXISTS fts_char_prefix_t_v1
GO
DROP VIEW IF EXISTS fts_char_prefix_t_v2
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p1
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p2
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p3
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p4
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p5
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p6
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p7
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p8
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p9
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p10
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p11
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p12
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p13
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p14
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p15
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p16
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p17
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p18
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p19
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p20
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p21
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p22
GO
DROP PROCEDURE IF EXISTS prefix_rewrite_prepare_p23
GO
DROP PROCEDURE IF EXISTS fts_char_prefix_t_p1
GO

-- Drop Fulltext index
DROP FULLTEXT INDEX ON fts_char_prefix_t
GO

-- Drop tables
DROP TABLE IF EXISTS fts_char_prefix_t
GO

-- disable FULLTEXT
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'strict', 'false')
GO