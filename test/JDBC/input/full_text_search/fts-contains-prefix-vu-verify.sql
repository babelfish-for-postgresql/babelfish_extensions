SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- 1. rewriting single prefix term
SELECT * FROM prefix_rewrite_prepare_v1
GO
SELECT * FROM prefix_rewrite_prepare_v2
GO
EXEC prefix_rewrite_prepare_p1
GO
EXEC prefix_rewrite_prepare_p2
GO

-- 2. rewriting prefix term phrase
SELECT * FROM prefix_rewrite_prepare_v3
GO
SELECT * FROM prefix_rewrite_prepare_v4
GO
SELECT * FROM prefix_rewrite_prepare_v5
GO
EXEC prefix_rewrite_prepare_p3
GO
EXEC prefix_rewrite_prepare_p4
GO
EXEC prefix_rewrite_prepare_p5
GO

-- 3. Leading occurrences of asterisk
SELECT * FROM prefix_rewrite_prepare_v6
GO
SELECT * FROM prefix_rewrite_prepare_v7
GO
SELECT * FROM prefix_rewrite_prepare_v8
GO
EXEC prefix_rewrite_prepare_p6
GO
EXEC prefix_rewrite_prepare_p7
GO
EXEC prefix_rewrite_prepare_p8
GO

-- 4. Trailing occurrences of asterisk
SELECT * FROM prefix_rewrite_prepare_v9
GO
SELECT * FROM prefix_rewrite_prepare_v10
GO
SELECT * FROM prefix_rewrite_prepare_v11
GO
EXEC prefix_rewrite_prepare_p9
GO
EXEC prefix_rewrite_prepare_p10
GO
EXEC prefix_rewrite_prepare_p11
GO

--5. Multiple occurrences of asterisk in prefix phrase
SELECT * FROM prefix_rewrite_prepare_v12
GO
SELECT * FROM prefix_rewrite_prepare_v13
GO
EXEC prefix_rewrite_prepare_p12
GO
EXEC prefix_rewrite_prepare_p13
GO

-- 6. Multiple occurrences of spaces in prefix phrase
SELECT * FROM prefix_rewrite_prepare_v14
GO
SELECT * FROM prefix_rewrite_prepare_v15
GO
EXEC prefix_rewrite_prepare_p14
GO
EXEC prefix_rewrite_prepare_p15
GO

-- 7. Combination of multiple occurrences
SELECT * FROM prefix_rewrite_prepare_v16
GO
SELECT * FROM prefix_rewrite_prepare_v17
GO
SELECT * FROM prefix_rewrite_prepare_v18
GO
EXEC prefix_rewrite_prepare_p16
GO
EXEC prefix_rewrite_prepare_p17
GO
EXEC prefix_rewrite_prepare_p18
GO

-- 8. special characters
-- should throw not supported error
SELECT * FROM prefix_rewrite_prepare_v19
GO
SELECT * FROM prefix_rewrite_prepare_v20
GO
EXEC prefix_rewrite_prepare_p19
GO
EXEC prefix_rewrite_prepare_p20
GO

-- Negative test
-- should warn about noise words, but does not
SELECT * FROM prefix_rewrite_prepare_v21
GO

-- Not a valid prefix term syntax, recognized as simple term
EXEC prefix_rewrite_prepare_p21
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

