-- Procedures to test #temp tables with names exceeding NAMEDATALEN (63 bytes).
-- The ENR must store the full untruncated name so subsequent lookups match.

CREATE PROCEDURE temp_long_name_enr_basic_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit (a INT, b VARCHAR(50))
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit VALUES (1, 'hello')
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit
    SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_that_exceeds%'
    SELECT CASE WHEN OBJECT_ID('tempdb..#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') IS NOT NULL THEN 'FOUND' ELSE 'NOT FOUND' END AS object_id_check
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit
    SELECT COUNT(*) AS enr_count_after_drop FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit%'
END
GO

CREATE PROCEDURE temp_long_name_enr_alter_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter (a INT)
    ALTER TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter ADD b VARCHAR(20)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter VALUES (1, 'added')
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter
    ALTER TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter DROP COLUMN b
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_alter
END
GO

CREATE PROCEDURE temp_long_name_enr_join_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_joins (id INT, val VARCHAR(10))
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_joins VALUES (1, 'aaa'), (2, 'bbb')
    SELECT t1.id, t2.val FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_joins t1 JOIN #temp_table_with_a_very_long_name_that_exceeds_namedatalen_joins t2 ON t1.id = t2.id WHERE t1.id = 1
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_joins
END
GO

CREATE PROCEDURE temp_long_name_enr_subquery_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_subqry (x INT)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_subqry VALUES (10), (20), (30)
    SELECT * FROM (SELECT x FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_subqry WHERE x > 10) sub ORDER BY x
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_subqry
END
GO

CREATE PROCEDURE temp_long_name_enr_insert_select_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_source (n INT)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_source VALUES (1), (2), (3)
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_target (n INT)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_target SELECT n FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_source WHERE n > 1
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_target ORDER BY n
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_source
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_target
END
GO

CREATE PROCEDURE temp_long_name_enr_boundary_proc
AS
BEGIN
    -- Name exactly 63 bytes (fits in NAMEDATALEN)
    CREATE TABLE #temp_table_name_exactly_at_the_namedatalen_boundary_of_63bytes (x INT)
    INSERT INTO #temp_table_name_exactly_at_the_namedatalen_boundary_of_63bytes VALUES (99)
    SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_name_exactly%'
    SELECT * FROM #temp_table_name_exactly_at_the_namedatalen_boundary_of_63bytes
    DROP TABLE #temp_table_name_exactly_at_the_namedatalen_boundary_of_63bytes

    -- Name exactly 64 bytes (exceeds NAMEDATALEN by 1)
    CREATE TABLE #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess (y INT)
    INSERT INTO #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess VALUES (100)
    SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_name_just_over%'
    SELECT * FROM #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess
    DROP TABLE #temp_table_name_just_over_the_namedatalen_boundary_of_64_bytess
END
GO

CREATE PROCEDURE temp_long_name_enr_coexist_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_coexist_first_table_in_session (a INT)
    CREATE TABLE #temp_table_with_a_very_long_name_coexist_second_table_in_session (b INT)
    SELECT relname FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_coexist%' ORDER BY relname
    INSERT INTO #temp_table_with_a_very_long_name_coexist_first_table_in_session VALUES (1)
    INSERT INTO #temp_table_with_a_very_long_name_coexist_second_table_in_session VALUES (2)
    SELECT a, b FROM #temp_table_with_a_very_long_name_coexist_first_table_in_session, #temp_table_with_a_very_long_name_coexist_second_table_in_session
    DROP TABLE #temp_table_with_a_very_long_name_coexist_first_table_in_session
    DROP TABLE #temp_table_with_a_very_long_name_coexist_second_table_in_session
END
GO

CREATE PROCEDURE temp_long_name_enr_index_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_index (id INT, val INT)
    CREATE INDEX idx_long_temp ON #temp_table_with_a_very_long_name_that_exceeds_namedatalen_index (id)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_index VALUES (1, 100), (2, 200)
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_index WHERE id = 2
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_index
END
GO

CREATE PROCEDURE temp_long_name_enr_long_index_name_proc
AS
BEGIN
    CREATE TABLE #tmp_idx (a INT, b INT)
    CREATE INDEX long_index_name_on_temp_table_exceeding_namedatalen_limit_in_proc ON #tmp_idx(a)
    SELECT relname FROM sys.babelfish_get_enr_list() WHERE relname LIKE 'long_index_name_on_temp%'
    SELECT OBJECT_NAME(reloid) FROM sys.babelfish_get_enr_list() WHERE relname LIKE '%long_index%'
    DROP TABLE #tmp_idx
END
GO

CREATE PROCEDURE temp_long_name_enr_reuse_proc
AS
BEGIN
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse (v INT)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse VALUES (1)
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse
    -- Recreate with same name
    CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse (v INT)
    INSERT INTO #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse VALUES (2)
    SELECT relname, LEN(relname) AS name_len FROM sys.babelfish_get_enr_list() WHERE relname LIKE '#temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse%'
    SELECT * FROM #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse
    DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_reuse
END
GO
