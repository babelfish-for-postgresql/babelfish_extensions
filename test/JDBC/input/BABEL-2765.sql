-- Check column collation when we add explicit COLLATE clause for both the non-computed and computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI, computed AS substring(non_computed, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AS)
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Check column collation when we add explicit COLLATE clause for only the computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200), computed AS substring(non_computed, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Check column collation when we add explicit COLLATE clause for only the non-computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI, computed AS substring(non_computed, 1, 5))
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Check column collation when we don't explicit COLLATE clause for any of the columns
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200), computed AS substring(non_computed, 1, 5))
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for both the non-computed and computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO

ALTER TABLE babel_2765_t1 ADD computed AS substring(non_computed, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AS
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for only the computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200))
GO

ALTER TABLE babel_2765_t1 ADD computed AS substring(non_computed, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AI
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we add explicit COLLATE clause for only the non-computed column
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AI)
GO

ALTER TABLE babel_2765_t1 ADD computed AS substring(non_computed, 1, 5)
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO

-- Adding computed column through ALTER TABLE ... ADD COLUMN
-- Check column collation when we don't explicit COLLATE clause for any of the columns
CREATE TABLE babel_2765_t1 (non_computed VARCHAR(200))
GO

ALTER TABLE babel_2765_t1 ADD computed AS substring(non_computed, 1, 5)
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed' or name = 'computed' ORDER BY name
GO

DROP TABLE babel_2765_t1
GO