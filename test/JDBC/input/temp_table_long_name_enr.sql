-- Tests for temp tables with long identifiers (>= NAMEDATALEN / 64 chars)
-- Validates OBJECT_ID, ALTER TABLE, DML, and DDL operations

-- =============================================================================
-- Test 1: Basic OBJECT_ID lookup (direct and tempdb-prefixed)
-- =============================================================================
CREATE TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit (a INT)
GO

SELECT CASE WHEN OBJECT_ID('#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test1_object_id_direct
GO

SELECT CASE WHEN OBJECT_ID('tempdb..#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test1_object_id_tempdb
GO

-- Both should return the same OID
SELECT CASE WHEN OBJECT_ID('#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') = OBJECT_ID('tempdb..#temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit') THEN 'PASS' ELSE 'FAIL' END AS test1_oid_match
GO

DROP TABLE #temp_table_with_a_very_long_name_that_exceeds_namedatalen_limit
GO

-- =============================================================================
-- Test 2: OBJECT_ID with type argument
-- =============================================================================
CREATE TABLE #long_temp_for_typed_object_id_test_exceeding_namedatalen_limit_x (id INT)
GO

SELECT CASE WHEN OBJECT_ID('#long_temp_for_typed_object_id_test_exceeding_namedatalen_limit_x', 'U') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test2_type_U
GO

-- Type 'V' (view) should return NULL for a table
SELECT CASE WHEN OBJECT_ID('#long_temp_for_typed_object_id_test_exceeding_namedatalen_limit_x', 'V') IS NULL THEN 'PASS' ELSE 'FAIL' END AS test2_type_V_null
GO

DROP TABLE #long_temp_for_typed_object_id_test_exceeding_namedatalen_limit_x
GO

-- =============================================================================
-- Test 3: ALTER TABLE ADD COLUMN
-- =============================================================================
CREATE TABLE #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars (a INT)
GO

ALTER TABLE #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars ADD b VARCHAR(50)
GO

ALTER TABLE #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars ADD c INT DEFAULT 0
GO

INSERT INTO #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars (a, b) VALUES (1, 'hello')
GO

SELECT a, b, c FROM #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars
GO

DROP TABLE #alter_test_temp_table_with_long_name_exceeding_sixty_four_chars
GO

-- =============================================================================
-- Test 4: ALTER TABLE DROP COLUMN
-- =============================================================================
CREATE TABLE #drop_col_test_long_temp_table_name_exceeding_namedatalen_limit (a INT, b INT, c INT)
GO

ALTER TABLE #drop_col_test_long_temp_table_name_exceeding_namedatalen_limit DROP COLUMN c
GO

INSERT INTO #drop_col_test_long_temp_table_name_exceeding_namedatalen_limit VALUES (1, 2)
GO

SELECT * FROM #drop_col_test_long_temp_table_name_exceeding_namedatalen_limit
GO

DROP TABLE #drop_col_test_long_temp_table_name_exceeding_namedatalen_limit
GO

-- =============================================================================
-- Test 5: ALTER TABLE ADD CONSTRAINT
-- =============================================================================
CREATE TABLE #constraint_test_long_temp_table_name_that_exceeds_namedatalen (id INT, val INT)
GO

ALTER TABLE #constraint_test_long_temp_table_name_that_exceeds_namedatalen ADD CONSTRAINT chk_val CHECK (val > 0)
GO

-- Should succeed (val > 0)
INSERT INTO #constraint_test_long_temp_table_name_that_exceeds_namedatalen VALUES (1, 10)
GO

-- Should fail (val = 0 violates constraint)
INSERT INTO #constraint_test_long_temp_table_name_that_exceeds_namedatalen VALUES (2, 0)
GO

SELECT * FROM #constraint_test_long_temp_table_name_that_exceeds_namedatalen
GO

DROP TABLE #constraint_test_long_temp_table_name_that_exceeds_namedatalen
GO

-- =============================================================================
-- Test 6: CREATE INDEX on long-name temp table
-- =============================================================================
CREATE TABLE #index_test_long_temp_table_name_that_definitely_exceeds_namedatalen (id INT, name VARCHAR(100))
GO

CREATE INDEX idx_name ON #index_test_long_temp_table_name_that_definitely_exceeds_namedatalen (name)
GO

INSERT INTO #index_test_long_temp_table_name_that_definitely_exceeds_namedatalen VALUES (1, 'alice'), (2, 'bob')
GO

SELECT * FROM #index_test_long_temp_table_name_that_definitely_exceeds_namedatalen WHERE name = 'alice'
GO

DROP TABLE #index_test_long_temp_table_name_that_definitely_exceeds_namedatalen
GO

-- =============================================================================
-- Test 7: INSERT, UPDATE, DELETE on long-name temp table
-- =============================================================================
CREATE TABLE #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx (id INT, val VARCHAR(20))
GO

INSERT INTO #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx VALUES (1, 'one'), (2, 'two'), (3, 'three')
GO

UPDATE #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx SET val = 'TWO' WHERE id = 2
GO

DELETE FROM #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx WHERE id = 3
GO

SELECT * FROM #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx ORDER BY id
GO

DROP TABLE #dml_test_long_temp_table_name_that_exceeds_namedatalen_limit_xx
GO

-- =============================================================================
-- Test 8: IF OBJECT_ID pattern (common guard pattern)
-- =============================================================================
IF OBJECT_ID('tempdb..#guard_pattern_long_temp_table_name_exceeding_namedatalen_limit') IS NOT NULL
    DROP TABLE #guard_pattern_long_temp_table_name_exceeding_namedatalen_limit
GO

CREATE TABLE #guard_pattern_long_temp_table_name_exceeding_namedatalen_limit (x INT)
GO

-- Second time: should find it and drop
IF OBJECT_ID('tempdb..#guard_pattern_long_temp_table_name_exceeding_namedatalen_limit') IS NOT NULL
    DROP TABLE #guard_pattern_long_temp_table_name_exceeding_namedatalen_limit
GO

-- Should be gone now
SELECT CASE WHEN OBJECT_ID('tempdb..#guard_pattern_long_temp_table_name_exceeding_namedatalen_limit') IS NULL THEN 'PASS' ELSE 'FAIL' END AS test8_dropped
GO

-- =============================================================================
-- Test 9: Multiple long-name temp tables in same session
-- =============================================================================
CREATE TABLE #multi_first_long_temp_table_name_that_exceeds_namedatalen_limitx (a INT)
GO
CREATE TABLE #multi_second_long_temp_table_name_that_exceeds_namedatalen_limit (b INT)
GO

INSERT INTO #multi_first_long_temp_table_name_that_exceeds_namedatalen_limitx VALUES (1)
GO
INSERT INTO #multi_second_long_temp_table_name_that_exceeds_namedatalen_limit VALUES (2)
GO

SELECT a FROM #multi_first_long_temp_table_name_that_exceeds_namedatalen_limitx
GO
SELECT b FROM #multi_second_long_temp_table_name_that_exceeds_namedatalen_limit
GO

-- Verify OBJECT_IDs are different
SELECT CASE WHEN OBJECT_ID('#multi_first_long_temp_table_name_that_exceeds_namedatalen_limitx') != OBJECT_ID('#multi_second_long_temp_table_name_that_exceeds_namedatalen_limit') THEN 'PASS' ELSE 'FAIL' END AS test9_different_oids
GO

DROP TABLE #multi_first_long_temp_table_name_that_exceeds_namedatalen_limitx
GO
DROP TABLE #multi_second_long_temp_table_name_that_exceeds_namedatalen_limit
GO

-- =============================================================================
-- Test 10: TRUNCATE TABLE on long-name temp table
-- =============================================================================
CREATE TABLE #truncate_test_long_temp_table_name_exceeding_namedatalen_limit (id INT)
GO

INSERT INTO #truncate_test_long_temp_table_name_exceeding_namedatalen_limit VALUES (1), (2), (3)
GO

TRUNCATE TABLE #truncate_test_long_temp_table_name_exceeding_namedatalen_limit
GO

SELECT COUNT(*) AS cnt FROM #truncate_test_long_temp_table_name_exceeding_namedatalen_limit
GO

DROP TABLE #truncate_test_long_temp_table_name_exceeding_namedatalen_limit
GO

-- =============================================================================
-- Test 11: Short temp table regression (ensure no breakage)
-- =============================================================================
CREATE TABLE #short (a INT)
GO

ALTER TABLE #short ADD b INT
GO

SELECT CASE WHEN OBJECT_ID('#short') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test11_short
GO

INSERT INTO #short VALUES (1, 2)
GO

SELECT * FROM #short
GO

DROP TABLE #short
GO

-- =============================================================================
-- Test 12: Temp table name at exact NAMEDATALEN boundary (63 chars)
-- =============================================================================
CREATE TABLE #aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaA (x INT)
GO

ALTER TABLE #aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaA ADD y INT
GO

SELECT CASE WHEN OBJECT_ID('#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaA') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test12_boundary
GO

DROP TABLE #aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaA
GO

-- =============================================================================
-- Test 13: Bracket-delimited long temp table name - OBJECT_ID
-- =============================================================================
CREATE TABLE [#bracket_long_temp_table_name_that_exceeds_namedatalen_limit_test] (a INT)
GO

SELECT CASE WHEN OBJECT_ID('#bracket_long_temp_table_name_that_exceeds_namedatalen_limit_test') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test13_bracket_objid
GO

SELECT CASE WHEN OBJECT_ID('tempdb..#bracket_long_temp_table_name_that_exceeds_namedatalen_limit_test') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test13_bracket_tempdb
GO

DROP TABLE [#bracket_long_temp_table_name_that_exceeds_namedatalen_limit_test]
GO

-- =============================================================================
-- Test 14: Bracket-delimited long temp table name - ALTER TABLE
-- =============================================================================
CREATE TABLE [#bracket_alter_test_long_temp_name_exceeding_namedatalen_limit_xx] (a INT)
GO

ALTER TABLE [#bracket_alter_test_long_temp_name_exceeding_namedatalen_limit_xx] ADD b VARCHAR(50)
GO

INSERT INTO [#bracket_alter_test_long_temp_name_exceeding_namedatalen_limit_xx] VALUES (1, 'bracketed')
GO

SELECT * FROM [#bracket_alter_test_long_temp_name_exceeding_namedatalen_limit_xx]
GO

DROP TABLE [#bracket_alter_test_long_temp_name_exceeding_namedatalen_limit_xx]
GO

-- =============================================================================
-- Test 15: Bracket-delimited with mixed case (case preserved in brackets)
-- =============================================================================
CREATE TABLE [#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX] (id INT)
GO

SELECT CASE WHEN OBJECT_ID('#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test15_mixed_case
GO

ALTER TABLE [#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX] ADD val INT
GO

INSERT INTO [#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX] VALUES (1, 100)
GO

SELECT * FROM [#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX]
GO

DROP TABLE [#BracketMixedCase_LongTempName_Exceeding_NameDataLen_Limit_TestXX]
GO

-- =============================================================================
-- Test 16: OBJECT_NAME with bracket-created long temp table
-- =============================================================================
CREATE TABLE [#bracket_obj_name_test_long_temp_table_exceeding_namedatalen_limit] (a INT)
GO

SELECT OBJECT_NAME(OBJECT_ID('#bracket_obj_name_test_long_temp_table_exceeding_namedatalen_limit')) AS test16_object_name_bracket
GO

DROP TABLE [#bracket_obj_name_test_long_temp_table_exceeding_namedatalen_limit]
GO
