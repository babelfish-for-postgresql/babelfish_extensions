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
SELECT * FROM prefix_rewrite_prepare_v5
GO
SELECT * FROM prefix_rewrite_prepare_v6
GO
SELECT * FROM prefix_rewrite_prepare_v7
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

EXEC prefix_rewrite_prepare_p7
GO


-- special characters
EXEC prefix_rewrite_prepare_p8
GO
EXEC prefix_rewrite_prepare_p9
GO
EXEC prefix_rewrite_prepare_p10
GO
EXEC prefix_rewrite_prepare_p11
GO

-- Create a unique-text index
CREATE UNIQUE INDEX uid ON fts_prefix_t(id)
GO
-- Create a full-text index
CREATE FULLTEXT INDEX ON fts_prefix_t(Content)
KEY INDEX uid 
GO

-- Sample search query using CONTAINS
-- Prefix term search for multiple forms of passing same search string
SELECT * 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"digi*"')
GO

SELECT * 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '   "digi    *"')
GO

SELECT * 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"digi   ***  * *" ')
GO



SELECT * 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"int*"')
GO

SELECT * 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"int      * *"')
GO



SELECT Content, ShortDescription 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"manufac process*"')
GO

SELECT Content, ShortDescription 
FROM fts_prefix_t 
WHERE CONTAINS(Content, '"manufac* process*"')
GO


-- Drop existing full-text index
DROP FULLTEXT INDEX ON fts_prefix_t;

-- Create a full-text index
CREATE FULLTEXT INDEX ON fts_prefix_t(
        Content,
        Category,
        ShortDescription,
        Author,
        Tags,
        Notes) KEY INDEX uid 
GO


-- Create a unique-text index
CREATE UNIQUE INDEX uid ON fts_multicol_prefix_t(id)

-- Create a full-text index
CREATE FULLTEXT INDEX ON fts_multicol_prefix_t(
        daily_updates,
        industry_news,
        local_events,
        tech_innovations,
        community_highlights) KEY INDEX uid
GO

-- prefix term search over multiple columns
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"inter*"')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), ' "inter  *" ')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"inter *  *"  ')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"  power*"')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"light work*"')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"light* work*"')
GO

SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"light *  * *  work   * **"')
GO

