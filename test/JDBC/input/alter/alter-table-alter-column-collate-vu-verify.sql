-- Collations before ALTER COLUMN
SELECT name, collation_name, max_length FROM sys.columns
WHERE object_id = OBJECT_ID('alter_col_collate_t1')
  AND name IN ('same_coll', 'cs_to_ci', 'ai_to_cs', 'bracketed', 'in_proc', 'to_db_default', 'no_collate')
ORDER BY column_id;
GO

-- Same collation as the column: only widens it (common in generated schema upgrade scripts)
ALTER TABLE alter_col_collate_t1 ALTER COLUMN same_coll varchar(20) COLLATE Latin1_General_CI_AS NULL;
GO

-- Different collation: case-sensitive to case-insensitive
ALTER TABLE alter_col_collate_t1 ALTER COLUMN cs_to_ci varchar(20) COLLATE Latin1_General_CI_AS;
GO

-- Column collation differs from the database and server collation, and so does the new one
ALTER TABLE alter_col_collate_t1 ALTER COLUMN ai_to_cs nvarchar(20) COLLATE Latin1_General_CS_AS NOT NULL;
GO

-- Bracket-quoted collation name, accepted as in CREATE TABLE
ALTER TABLE alter_col_collate_t1 ALTER COLUMN bracketed varchar(20) COLLATE [Latin1_General_CI_AS];
GO

-- Inside a procedure
CREATE PROCEDURE alter_col_collate_p AS
    ALTER TABLE alter_col_collate_t1 ALTER COLUMN in_proc varchar(20) COLLATE Latin1_General_CS_AS;
GO

EXEC alter_col_collate_p;
GO

-- COLLATE database_default
ALTER TABLE alter_col_collate_t1 ALTER COLUMN to_db_default varchar(20) COLLATE database_default;
GO

-- Without COLLATE the column gets the database default collation, as in SQL Server
ALTER TABLE alter_col_collate_t1 ALTER COLUMN no_collate varchar(20);
GO

-- Collations after ALTER COLUMN
SELECT name, collation_name, max_length FROM sys.columns
WHERE object_id = OBJECT_ID('alter_col_collate_t1')
  AND name IN ('same_coll', 'cs_to_ci', 'ai_to_cs', 'bracketed', 'in_proc')
ORDER BY column_id;
GO

SELECT c.name,
       CASE WHEN c.collation_name = r.collation_name THEN 'database default' ELSE c.collation_name END AS collation_name,
       c.max_length
FROM sys.columns c JOIN sys.columns r ON r.object_id = c.object_id AND r.name = 'ref'
WHERE c.object_id = OBJECT_ID('alter_col_collate_t1') AND c.name IN ('to_db_default', 'no_collate')
ORDER BY c.column_id;
GO

-- Comparisons use the new collations
SELECT CASE WHEN same_coll = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END AS same_coll,
       CASE WHEN cs_to_ci = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END AS cs_to_ci,
       CASE WHEN ai_to_cs = N'A' THEN 'case-insensitive' ELSE 'case-sensitive' END AS ai_to_cs,
       CASE WHEN bracketed = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END AS bracketed,
       CASE WHEN in_proc = 'A' THEN 'case-insensitive' ELSE 'case-sensitive' END AS in_proc
FROM alter_col_collate_t1;
GO

-- Indexed columns: the indexes are kept and follow the new collation
ALTER TABLE alter_col_collate_t2 ALTER COLUMN widen varchar(20) COLLATE Latin1_General_CS_AS;
GO

ALTER TABLE alter_col_collate_t2 ALTER COLUMN cs_to_ci varchar(20) COLLATE Latin1_General_CI_AS;
GO

SELECT name, collation_name, max_length FROM sys.columns
WHERE object_id = OBJECT_ID('alter_col_collate_t2') AND name IN ('widen', 'cs_to_ci')
ORDER BY column_id;
GO

SELECT name FROM sys.indexes
WHERE object_id = OBJECT_ID('alter_col_collate_t2') AND name IS NOT NULL
ORDER BY name;
GO

SELECT id FROM alter_col_collate_t2 WHERE widen = 'a' ORDER BY id;
GO

SELECT id FROM alter_col_collate_t2 WHERE cs_to_ci = 'a' ORDER BY id;
GO

-- Unknown collation: same error as in CREATE TABLE
ALTER TABLE alter_col_collate_t1 ALTER COLUMN ref varchar(20) COLLATE no_such_collation;
GO

-- COLLATE on a non-character column
ALTER TABLE alter_col_collate_t1 ALTER COLUMN num int COLLATE Latin1_General_CI_AS;
GO
