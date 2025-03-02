-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- leading and trailing spaces between quotes and double quotes
SELECT * FROM prefix_rewrite_prepare_v1
GO
SELECT * FROM prefix_rewrite_prepare_v2
GO
SELECT * FROM prefix_rewrite_prepare_v3
GO
SELECT * FROM prefix_rewrite_prepare_v4
GO

-- handling different cases of prefix terms
-- all are valid search strings
EXEC prefix_rewrite_prepare_p1
GO
EXEC prefix_rewrite_prepare_p2
GO
EXEC prefix_rewrite_prepare_p3
GO
EXEC prefix_rewrite_prepare_p4
GO
EXEC prefix_rewrite_prepare_p5
GO
-- negative test
-- does not give warning about noise in search string
EXEC prefix_rewrite_prepare_p6
GO

-- special characters
EXEC prefix_rewrite_prepare_p7
GO
EXEC prefix_rewrite_prepare_p8
GO
EXEC prefix_rewrite_prepare_p9
GO
EXEC prefix_rewrite_prepare_p10
GO

-- Create a unique-text index
CREATE UNIQUE INDEX uid ON ArticleSentences(id)
GO
-- Create a full-text index
CREATE FULLTEXT INDEX ON ArticleSentences(Content)
KEY INDEX uid 
GO

-- Sample search query using CONTAINS
-- 1. Basic prefix search across all text fields
SELECT * 
FROM ArticleSentences 
WHERE CONTAINS(Content, '"digi*"')
GO

SELECT * 
FROM ArticleSentences 
WHERE CONTAINS(Content, '"int*"')
GO

SELECT Content, ShortDescription 
FROM ArticleSentences 
WHERE CONTAINS(Content, '"manufac process*"')
GO