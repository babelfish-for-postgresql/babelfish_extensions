-- Direct creation tests (session-level, not inside a procedure)

-- Scenario 1: Basic direct CREATE, INSERT, SELECT with ENR validation
CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit (a INT, b VARCHAR(50))
GO

SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_that_exceeds%'
GO

INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit VALUES (1, 'hello')
GO

SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit
GO

SELECT CASE WHEN OBJECT_ID('tempdb..#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') IS NOT NULL THEN 'FOUND' ELSE 'NOT FOUND' END AS object_id_check
GO

DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit
GO

SELECT COUNT(*) AS enr_count_after_drop FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit%'
GO

-- Scenario 2: Direct boundary test (64 bytes)
CREATE TABLE #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess (y INT)
GO

INSERT INTO #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess VALUES (100)
GO

SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_name_just_over%'
GO

SELECT * FROM #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess
GO

DROP TABLE #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess
GO

-- Procedure-based tests (validates behavior inside stored procedures)

-- Scenario 3: Basic CREATE, INSERT, SELECT, DROP with ENR validation
EXEC temp_long_name_enr_basic_proc
GO

-- Scenario 4: ALTER TABLE on long-name temp table
EXEC temp_long_name_enr_alter_proc
GO

-- Scenario 5: Multiple references in one batch (self-join)
EXEC temp_long_name_enr_join_proc
GO

-- Scenario 6: Subquery referencing long-name temp table
EXEC temp_long_name_enr_subquery_proc
GO

-- Scenario 7: INSERT...SELECT between two long-name temp tables
EXEC temp_long_name_enr_insert_select_proc
GO

-- Scenario 8 & 9: Boundary tests (63 bytes and 64 bytes)
EXEC temp_long_name_enr_boundary_proc
GO

-- Scenario 10: Two long-name temp tables coexisting
EXEC temp_long_name_enr_coexist_proc
GO

-- Scenario 11: CREATE INDEX on long-name temp table
EXEC temp_long_name_enr_index_proc
GO

-- Scenario 12: Recreate same long-name temp table after drop
EXEC temp_long_name_enr_reuse_proc
GO

-- Scenario 13: Long index name shows full name in get_enr_list and OBJECT_NAME
EXEC temp_long_name_enr_long_index_name_proc
GO
