-- Check column collation when we add explicit COLLATE clause for both the non-computed and computed column
CREATE TABLE babel_2765_vu_prepare_t1 (non_computed1 VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI, computed1 AS substring(non_computed1, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO


-- Check column collation when we add explicit COLLATE clause for only the computed column
CREATE TABLE babel_2765_vu_prepare_t2 (non_computed2 VARCHAR(200), computed2 AS substring(non_computed2, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO


-- Check column collation when we add explicit COLLATE clause for only the non-computed column
CREATE TABLE babel_2765_vu_prepare_t3 (non_computed3 VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI, computed3 AS substring(non_computed3, 1, 5))
GO


-- Check column collation when we don't explicit COLLATE clause for any of the columns
CREATE TABLE babel_2765_vu_prepare_t4 (non_computed4 VARCHAR(200), computed4 AS substring(non_computed4, 1, 5))
GO


-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for both the non-computed and computed column
CREATE TABLE babel_2765_vu_prepare_t5 (non_computed5 VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO


ALTER TABLE babel_2765_vu_prepare_t5 ADD computed5 AS substring(non_computed5, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AS
GO


-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for only the computed column
CREATE TABLE babel_2765_vu_prepare_t6 (non_computed6 VARCHAR(200))
GO

ALTER TABLE babel_2765_vu_prepare_t6 ADD computed6 AS substring(non_computed6, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AI
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for only the non-computed column
CREATE TABLE babel_2765_vu_prepare_t7 (non_computed7 VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO

ALTER TABLE babel_2765_vu_prepare_t7 ADD computed7 AS substring(non_computed7, 1, 5)
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we don't explicit COLLATE clause for any of the columns
CREATE TABLE babel_2765_vu_prepare_t8 (non_computed8 VARCHAR(200))
GO

ALTER TABLE babel_2765_vu_prepare_t8 ADD computed8 AS substring(non_computed8, 1, 5)
GO