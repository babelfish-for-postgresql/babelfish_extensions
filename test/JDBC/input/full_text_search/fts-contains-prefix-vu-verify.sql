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

-- 7. Combination of multiple occurrences of spaces and asterisk and tab spaces in prefix phrase
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

-- 9. support for emojis
-- should throw languages other than english are not supported
SELECT * FROM prefix_rewrite_prepare_v21
GO
SELECT * FROM prefix_rewrite_prepare_v22
GO
EXEC prefix_rewrite_prepare_p21
GO
EXEC prefix_rewrite_prepare_p22
GO

-- Negative test
-- should warn about noise words, but does not
SELECT * FROM prefix_rewrite_prepare_v23
GO

-- Not a valid prefix term syntax, recognized as simple term
EXEC prefix_rewrite_prepare_p23
GO



-- 10. Sample search query using CONTAINS
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

SELECT Content, ShortDescription, Notes FROM fts_prefix_t_v1 WHERE CONTAINS((Content, ShortDescription, Notes), '"comp*"')
GO

SELECT * FROM fts_prefix_t_v2
GO


-- prefix term search over multiple columns
EXEC fts_multicol_prefix_t_p1
GO

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

-- Common Table Expressions
WITH fts_multicol_prefix_t_cte1 AS (
    SELECT *
    FROM fts_multicol_prefix_t
    WHERE CONTAINS((daily_updates,
                    industry_news,
                    local_events,
                    tech_innovations,
                    community_highlights), '"light work*"')
)
SELECT * FROM fts_multicol_prefix_t_cte1
GO

WITH fts_multicol_prefix_t_cte2 AS (
    SELECT *
    FROM fts_multicol_prefix_t
)
SELECT *
FROM fts_multicol_prefix_t_cte2
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), '"light work*"')
GO

-- tab character in prefix term search string
DECLARE @search_term nvarchar(100) = '"light work' + CHAR(9) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"light'+ CHAR(9) + 'work' + CHAR(9) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"light'+ CHAR(9) + 'work' + CHAR(9) + '*'+ CHAR(9) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '" *** ** *' + CHAR(9) + '  ** * * * ' + CHAR(9) + 'light'+ CHAR(9) + 'work' + CHAR(9) + '*'+ CHAR(9) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

-- newline character in prefix term search string
DECLARE @search_term nvarchar(100) = '"light work' + CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"light'+ CHAR(10) + 'work' + CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"light'+ CHAR(10) + 'work' + CHAR(10) + '*'+ CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

-- combination of tab and newline character in prefix term search string
DECLARE @search_term nvarchar(100) = '"light work' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"light'+ CHAR(9) + CHAR(10) + 'work' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO

DECLARE @search_term nvarchar(100) = CHAR(10) + CHAR(9) + '" * * * **** *light'+ CHAR(9) + CHAR(10) + 'work' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_multicol_prefix_t
WHERE CONTAINS((daily_updates,
                industry_news,
                local_events,
                tech_innovations,
                community_highlights), @search_term)
GO


-- Create a unique index
CREATE UNIQUE INDEX uid ON fts_char_prefix_t(id)
GO

-- Create a full-text index
CREATE FULLTEXT INDEX ON fts_char_prefix_t(
        main_story,
        industry_update,
        local_news,
        tech_highlight,
        community_event) KEY INDEX uid
GO

-- tab character in prefix term search string
DECLARE @search_term nvarchar(100) = '"coral re' + CHAR(9) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"coral'+ CHAR(9) + 're' + CHAR(9) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"cor'+ CHAR(9) + 're' + CHAR(9) + '*'+ CHAR(9) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

-- newline character in prefix term search string
DECLARE @search_term nvarchar(100) = '"cor re' + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"coral'+ CHAR(10) + 're' + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = CHAR(10) + '"coral'+ CHAR(10) + 're' + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"cor'+ CHAR(10) + 're' + CHAR(10) + '*'+ CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

-- combination of tab and newline character in prefix term search string
DECLARE @search_term nvarchar(100) = '"bor for' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"bor'+ CHAR(9) + CHAR(10) + 'for' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"bor'+ CHAR(10) + CHAR(10) + 'for' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

DECLARE @search_term nvarchar(100) = '"bor'+ CHAR(10) + CHAR(10) + CHAR(10) + 'for' + CHAR(9) + CHAR(10) + '*"';
SELECT *
FROM fts_char_prefix_t
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO

-- Common Table Expressions
DECLARE @search_term nvarchar(100) = '"bor'+ CHAR(10) + CHAR(10) + CHAR(10) + 'for' + CHAR(9) + CHAR(10) + '*"';
WITH fts_char_prefix_t_cte1 AS (
    SELECT *
    FROM fts_char_prefix_t
    WHERE CONTAINS((main_story,
                    industry_update,
                    local_news,
                    tech_highlight,
                    community_event), @search_term)
)
SELECT * FROM fts_char_prefix_t_cte1
GO

DECLARE @search_term nvarchar(100) = '"bor'+ CHAR(10) + CHAR(10) + CHAR(10) + 'for' + CHAR(9) + CHAR(10) + '*"';
WITH fts_char_prefix_t_cte2 AS (
    SELECT *
    FROM fts_char_prefix_t
)
SELECT *
FROM fts_char_prefix_t_cte2
WHERE CONTAINS((main_story,
                industry_update,
                local_news,
                tech_highlight,
                community_event), @search_term)
GO