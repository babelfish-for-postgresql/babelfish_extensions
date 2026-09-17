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

-- Type 'V' (view) should ideally return NULL for a table, but OBJECT_ID type filtering
-- for temp tables is a known pre-existing limitation (returns non-NULL regardless of type)
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

-- =============================================================================
-- Test 17: Multibyte character temp table name exceeding NAMEDATALEN
-- =============================================================================
CREATE TABLE #テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト (id INT)
GO

SELECT CASE WHEN OBJECT_ID('#テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test17_multibyte_long
GO

SELECT OBJECT_NAME(OBJECT_ID('#テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト')) AS test17_object_name
GO

INSERT INTO #テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト VALUES (42)
GO

SELECT * FROM #テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト
GO

DROP TABLE #テスト用の非常に長いテンポラリテーブル名前がNAMEDATALEN制限を超える場合のテスト
GO

-- =============================================================================
-- Test 18: Bracket-delimited multibyte long temp table name
-- =============================================================================
CREATE TABLE [#マルチバイト_ブラケット_長いテンポラリテーブル名前がNAMEDATALEN制限を超えるケース] (val INT)
GO

SELECT CASE WHEN OBJECT_ID('#マルチバイト_ブラケット_長いテンポラリテーブル名前がNAMEDATALEN制限を超えるケース') IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS test18_bracket_multibyte
GO

DROP TABLE [#マルチバイト_ブラケット_長いテンポラリテーブル名前がNAMEDATALEN制限を超えるケース]
GO

-- =============================================================================
-- Test 19: Non-ENR temp table (has UDT dependency) - OBJECT_NAME shows full name
-- =============================================================================
CREATE TYPE dbo.my_udt FROM VARCHAR(100)
GO

CREATE TABLE #non_enr_long_temp_table_name_with_udt_dependency_exceeding_namedatalen_limit (id INT, val dbo.my_udt)
GO

INSERT INTO #non_enr_long_temp_table_name_with_udt_dependency_exceeding_namedatalen_limit VALUES (1, 'udt_test')
GO

SELECT * FROM #non_enr_long_temp_table_name_with_udt_dependency_exceeding_namedatalen_limit
GO

SELECT OBJECT_NAME(OBJECT_ID('#non_enr_long_temp_table_name_with_udt_dependency_exceeding_namedatalen_limit')) AS test19_object_name
GO

DROP TABLE #non_enr_long_temp_table_name_with_udt_dependency_exceeding_namedatalen_limit
GO

DROP TYPE dbo.my_udt
GO

-- =============================================================================
-- Test 20: ENR long temp table - OBJECT_NAME shows full name
-- =============================================================================
CREATE TABLE #enr_object_name_test_long_temp_table_name_exceeding_namedatalen_lim (id INT)
GO

SELECT OBJECT_NAME(OBJECT_ID('#enr_object_name_test_long_temp_table_name_exceeding_namedatalen_lim')) AS test20_object_name
GO

DROP TABLE #enr_object_name_test_long_temp_table_name_exceeding_namedatalen_lim
GO

-- =============================================================================
-- Test 21: sp_tablecollations_100 with long temp table name
-- =============================================================================
CREATE TABLE #sp_tablecoll_long_temp_table_name_exceeding_namedatalen_limit_test (id INT, name VARCHAR(50))
GO

EXEC sp_tablecollations_100 '#sp_tablecoll_long_temp_table_name_exceeding_namedatalen_limit_test'
GO

DROP TABLE #sp_tablecoll_long_temp_table_name_exceeding_namedatalen_limit_test
GO

-- =============================================================================
-- Test 22: Short temp table with mixed case - OBJECT_NAME preserves case
-- =============================================================================
CREATE TABLE #ShortMixedCase (id INT)
GO

SELECT OBJECT_NAME(OBJECT_ID('#ShortMixedCase')) AS test22_case_preserved
GO

DROP TABLE #ShortMixedCase
GO

-- =============================================================================
-- Test 23: Short bracket-delimited temp table with mixed case
-- =============================================================================
CREATE TABLE [#BracketShort_MixedCase] (id INT)
GO

SELECT OBJECT_NAME(OBJECT_ID('#BracketShort_MixedCase')) AS test23_bracket_case
GO

DROP TABLE [#BracketShort_MixedCase]
GO

-- =============================================================================
-- Test 24: Non-ENR temp table - OBJECT_NAME shows full name (second UDT)
-- =============================================================================
CREATE TYPE dbo.my_udt4 FROM INT
GO

CREATE TABLE #non_enr_sys_tables_test_long_temp_name_exceeding_namedatalen_limit (id INT, val dbo.my_udt4)
GO

SELECT OBJECT_NAME(OBJECT_ID('#non_enr_sys_tables_test_long_temp_name_exceeding_namedatalen_limit')) AS test24_object_name
GO

DROP TABLE #non_enr_sys_tables_test_long_temp_name_exceeding_namedatalen_limit
GO

DROP TYPE dbo.my_udt4
GO

-- =============================================================================
-- Test 25: Non-ENR temp table - OBJECT_NAME shows full name (third UDT)
-- =============================================================================
CREATE TYPE dbo.my_udt3 FROM VARCHAR(50)
GO

CREATE TABLE #non_enr_object_name_test_long_temp_table_exceeding_namedatalen_xx (id INT, val dbo.my_udt3)
GO

SELECT OBJECT_NAME(OBJECT_ID('#non_enr_object_name_test_long_temp_table_exceeding_namedatalen_xx')) AS test25_object_name
GO

DROP TABLE #non_enr_object_name_test_long_temp_table_exceeding_namedatalen_xx
GO

DROP TYPE dbo.my_udt3
GO

-- =============================================================================
-- Test 26: Long index name on temp table - babelfish_get_enr_list shows full name
-- =============================================================================
CREATE TABLE #idx_test_tmp (a INT, b VARCHAR(50))
GO

CREATE INDEX #very_long_index_name_on_temp_table_exceeding_namedatalen_limit_xx ON #idx_test_tmp(a)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#very_long_index%'
GO

DROP TABLE #idx_test_tmp
GO

-- =============================================================================
-- Test 27: Multiple long index names on temp table
-- =============================================================================
CREATE TABLE #idx_multi_tmp (a INT, b INT, c INT)
GO

CREATE INDEX #long_idx_first_column_name_exceeding_the_namedatalen_limit_test ON #idx_multi_tmp(a)
GO

CREATE INDEX #long_idx_second_column_name_exceeding_the_namedatalen_limit_test ON #idx_multi_tmp(b)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#long_idx_%'
GO

DROP TABLE #idx_multi_tmp
GO

-- =============================================================================
-- Test 28: Mixed case long index name on temp table
-- =============================================================================
CREATE TABLE #idx_case_tmp (a INT)
GO

CREATE INDEX MixedCase_Long_Index_Name_On_Temp_Table_Exceeding_NameDataLen_Lim ON #idx_case_tmp(a)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE 'MixedCase[_]Long[_]Index%'
GO

DROP TABLE #idx_case_tmp
GO

-- =============================================================================
-- Test 29: Multibyte long index name on temp table
-- =============================================================================
CREATE TABLE #idx_mb_tmp (a INT)
GO

CREATE INDEX インデックス名前が非常に長いテスト用のインデックスでNAMEDATALEN制限を超える ON #idx_mb_tmp(a)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE 'インデックス名前%'
GO

DROP TABLE #idx_mb_tmp
GO

-- =============================================================================
-- Test 30: Long index name on non-ENR temp table (UDT dependency)
-- =============================================================================
CREATE TYPE dbo.my_udt_idx FROM INT
GO

CREATE TABLE #non_enr_idx_test (a INT, b dbo.my_udt_idx)
GO

CREATE INDEX long_index_name_on_non_enr_temp_table_exceeding_namedatalen_limit ON #non_enr_idx_test(a)
GO

INSERT INTO #non_enr_idx_test VALUES (1, 100), (2, 200)
GO

SELECT * FROM #non_enr_idx_test WHERE a = 2
GO

-- Verify original name stored in reloptions
SELECT CASE WHEN (SELECT array_to_string(reloptions, ',') FROM pg_class WHERE relname LIKE 'long_index_name_on_non_enr%') LIKE '%bbf_original_rel_name=long_index_name_on_non_enr_temp_table_exceeding_namedatalen_limit%' THEN 'PASS' ELSE 'FAIL' END AS test30_reloption
GO

DROP TABLE #non_enr_idx_test
GO

DROP TYPE dbo.my_udt_idx
GO

-- =============================================================================
-- Test 31: SELECT INTO with long temp table name
-- =============================================================================
SELECT 1 AS id, 'hello' AS val INTO #select_into_long_temp_table_name_exceeding_namedatalen_limit_xx
GO

SELECT * FROM #select_into_long_temp_table_name_exceeding_namedatalen_limit_xx
GO

SELECT OBJECT_NAME(OBJECT_ID('#select_into_long_temp_table_name_exceeding_namedatalen_limit_xx')) AS test31_select_into
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#select_into_long%'
GO

DROP TABLE #select_into_long_temp_table_name_exceeding_namedatalen_limit_xx
GO

-- =============================================================================
-- Test 32: Cached plan - long index name on temp table via stored procedure
-- Verifies that the full original name is stored correctly across executions
-- =============================================================================
CREATE PROCEDURE sp_long_idx_cached_plan AS
BEGIN
  CREATE TABLE #cached_plan_tmp (a INT, b INT)
  CREATE INDEX #very_long_index_name_cached_plan_test_exceeding_namedatalen_lim ON #cached_plan_tmp(a)
  SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#very_long_index_name_cached%'
  DROP TABLE #cached_plan_tmp
END
GO

-- First execution
EXEC sp_long_idx_cached_plan
GO

-- Second execution (cached plan)
EXEC sp_long_idx_cached_plan
GO

-- Third execution (definitely cached plan)
EXEC sp_long_idx_cached_plan
GO

DROP PROCEDURE sp_long_idx_cached_plan
GO

-- =============================================================================
-- Test 33: sp_prepare/sp_execute - guarantees cached plan reuse for long index
-- =============================================================================
DECLARE @handle INT
EXEC sp_prepare @handle OUTPUT, NULL, N'CREATE TABLE #sp_prep_tmp (a INT); CREATE INDEX #very_long_index_name_sp_prepare_test_exceeding_namedatalen_limit ON #sp_prep_tmp(a); SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE ''#very_long_index_name_sp_prepare%''; DROP TABLE #sp_prep_tmp'
EXEC sp_execute @handle
EXEC sp_execute @handle
EXEC sp_unprepare @handle
GO

-- =============================================================================
-- Test 34: Same long index name on different long-name temp tables
-- =============================================================================
CREATE TABLE #diff_tbl_one_with_very_long_name_exceeding_namedatalen_limit_xxxxx (a INT, b INT)
GO

CREATE TABLE #diff_tbl_two_with_very_long_name_exceeding_namedatalen_limit_xxxxx (x INT, y INT)
GO

CREATE INDEX #same_long_index_name_on_different_temp_tables_exceeding_limit_x ON #diff_tbl_one_with_very_long_name_exceeding_namedatalen_limit_xxxxx(a)
GO

CREATE INDEX #same_long_index_name_on_different_temp_tables_exceeding_limit_x ON #diff_tbl_two_with_very_long_name_exceeding_namedatalen_limit_xxxxx(x)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#same_long_index%' ORDER BY relname
GO

DROP TABLE #diff_tbl_one_with_very_long_name_exceeding_namedatalen_limit_xxxxx
GO

DROP TABLE #diff_tbl_two_with_very_long_name_exceeding_namedatalen_limit_xxxxx
GO

-- =============================================================================
-- Test 35: Same short index name on different long-name temp tables
-- =============================================================================
CREATE TABLE #short_idx_tbl_one_with_very_long_name_exceeding_namedatalen_limit (a INT)
GO

CREATE TABLE #short_idx_tbl_two_with_very_long_name_exceeding_namedatalen_limit (x INT)
GO

CREATE INDEX idx_short ON #short_idx_tbl_one_with_very_long_name_exceeding_namedatalen_limit(a)
GO

CREATE INDEX idx_short ON #short_idx_tbl_two_with_very_long_name_exceeding_namedatalen_limit(x)
GO

SELECT relname FROM babelfish_get_enr_list() WHERE relname LIKE '#short_idx_tbl%' ORDER BY relname
GO

DROP TABLE #short_idx_tbl_one_with_very_long_name_exceeding_namedatalen_limit
GO

DROP TABLE #short_idx_tbl_two_with_very_long_name_exceeding_namedatalen_limit
GO
