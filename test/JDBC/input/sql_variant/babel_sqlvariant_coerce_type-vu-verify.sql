-- Test: sql_variant type resolution across all common type contexts
-- Covers: CASE, ISNULL, COALESCE, UNION, INTERSECT, EXCEPT, VALUES
-- Tests sql_variant in 1st, 2nd, 3rd, and last branch positions
-- Tests NULL sql_variant in all contexts


-- 1. CASE: sql_variant in different branch positions


-- 1a. sql_variant in 1st branch (THEN), other type in ELSE
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(0 AS bit) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(0 AS int) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST('hello' AS sql_variant) ELSE CAST('world' AS varchar(50)) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(N'hello' AS sql_variant) ELSE CAST(N'world' AS nvarchar(50)) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(3.14 AS sql_variant) ELSE CAST(2.71 AS float) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(100 AS sql_variant) ELSE CAST(200.50 AS numeric(10,2)) END AS result
GO

-- 1b. sql_variant in 2nd branch (ELSE), other type in THEN
SELECT CASE WHEN 1 = 1 THEN CAST(0 AS bit) ELSE CAST(1 AS sql_variant) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(0 AS int) ELSE CAST(1 AS sql_variant) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST('world' AS varchar(50)) ELSE CAST('hello' AS sql_variant) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(2.71 AS float) ELSE CAST(3.14 AS sql_variant) END AS result
GO

-- 1c. sql_variant in 1st WHEN of multi-branch CASE
SELECT CASE 1
   WHEN 1 THEN CAST('first' AS sql_variant)
   WHEN 2 THEN CAST(0 AS bit)
   WHEN 3 THEN CAST(100 AS int)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1d. sql_variant in 2nd WHEN of multi-branch CASE
SELECT CASE 2
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST('second' AS sql_variant)
   WHEN 3 THEN CAST(100 AS int)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1e. sql_variant in 3rd WHEN of multi-branch CASE
SELECT CASE 3
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST('third' AS sql_variant)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1f. sql_variant in last branch (ELSE) of multi-branch CASE
SELECT CASE 4
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST('hello' AS varchar(50))
   ELSE CAST('last' AS sql_variant)
END AS result
GO

-- 1f2. 3 WHENs + ELSE: sql_variant in 2nd WHEN, all other types different
SELECT CASE 2
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST('middle' AS sql_variant)
   WHEN 3 THEN CAST(3.14 AS float)
   ELSE CAST(100 AS int)
END AS result
GO

-- 1f3. 4 WHENs + ELSE: sql_variant in 3rd WHEN
SELECT CASE 3
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST('third' AS sql_variant)
   WHEN 4 THEN CAST(3.14 AS float)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1f4. 5 WHENs + ELSE: sql_variant in middle (3rd) WHEN
SELECT CASE 3
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST('mid' AS sql_variant)
   WHEN 4 THEN CAST(3.14 AS float)
   WHEN 5 THEN CAST('hello' AS varchar(50))
   ELSE CAST(200.50 AS numeric(10,2))
END AS result
GO

-- 1f5. 3 WHENs + ELSE: sql_variant in ELSE, all WHENs are different types
SELECT CASE 4
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST(3.14 AS float)
   ELSE CAST('fallback' AS sql_variant)
END AS result
GO

-- 1f6. 3 WHENs + ELSE: NULL sql_variant in 2nd WHEN
SELECT CASE 2
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(NULL AS sql_variant)
   WHEN 3 THEN CAST(100 AS int)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1f7. 4 WHENs + ELSE: NULL sql_variant in 3rd WHEN
SELECT CASE 3
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST(NULL AS sql_variant)
   WHEN 4 THEN CAST(3.14 AS float)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1f8. 3 WHENs + ELSE: NULL sql_variant in ELSE
SELECT CASE 4
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   WHEN 3 THEN CAST(3.14 AS float)
   ELSE CAST(NULL AS sql_variant)
END AS result
GO

-- 1f9. Searched CASE with 3+ conditions: sql_variant in middle WHEN
SELECT CASE
   WHEN 1 = 2 THEN CAST(0 AS bit)
   WHEN 1 = 1 THEN CAST('found' AS sql_variant)
   WHEN 1 = 3 THEN CAST(100 AS int)
   ELSE CAST(3.14 AS float)
END AS result
GO

-- 1f10. Searched CASE with 4 conditions: sql_variant in 3rd WHEN
SELECT CASE
   WHEN 1 = 2 THEN CAST(0 AS bit)
   WHEN 1 = 3 THEN CAST(100 AS int)
   WHEN 1 = 1 THEN CAST('found' AS sql_variant)
   WHEN 1 = 4 THEN CAST(3.14 AS float)
   ELSE CAST('default' AS varchar(50))
END AS result
GO

-- 1f11. Searched CASE: sql_variant in ELSE with 3 WHENs
SELECT CASE
   WHEN 1 = 2 THEN CAST(0 AS bit)
   WHEN 1 = 3 THEN CAST(100 AS int)
   WHEN 1 = 4 THEN CAST(3.14 AS float)
   ELSE CAST('fallback' AS sql_variant)
END AS result
GO

-- 1g. SERVERPROPERTY returns sql_variant (original reported queries)
SELECT CASE WHEN 1 = 1 THEN SERVERPROPERTY('IsFullTextInstalled') ELSE CAST(0 AS bit) END AS result
GO

SELECT CASE WHEN SERVERPROPERTY('EngineEdition') = 8 THEN SERVERPROPERTY('IsFullTextInstalled') ELSE CAST(0 AS bit) END AS test_result
GO

-- 1h. sql_variant with untyped NULL branches
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE NULL END AS result
GO

SELECT CASE WHEN 1 = 0 THEN NULL ELSE CAST(1 AS sql_variant) END AS result
GO

-- 1i. NULL sql_variant (CAST(NULL AS sql_variant)) in different positions
SELECT CASE WHEN 1 = 1 THEN CAST(NULL AS sql_variant) ELSE CAST(0 AS bit) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(0 AS bit) ELSE CAST(NULL AS sql_variant) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(NULL AS sql_variant) ELSE CAST(100 AS int) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(NULL AS sql_variant) ELSE CAST('hello' AS varchar(50)) END AS result
GO

SELECT CASE 1
   WHEN 1 THEN CAST(NULL AS sql_variant)
   WHEN 2 THEN CAST(0 AS bit)
   WHEN 3 THEN CAST(100 AS int)
END AS result
GO

SELECT CASE 3
   WHEN 1 THEN CAST(0 AS bit)
   WHEN 2 THEN CAST(100 AS int)
   ELSE CAST(NULL AS sql_variant)
END AS result
GO

-- 1j. sql_variant with string literal
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE 'literal' END AS result
GO

-- 1k. CASE using table columns with sql_variant
SELECT CASE WHEN id = 1 THEN sv_col ELSE CAST(0 AS bit) END AS result FROM babel_case_sqlvariant_t1
GO

SELECT CASE WHEN id = 1 THEN CAST(0 AS bit) ELSE sv_col END AS result FROM babel_case_sqlvariant_t1
GO

-- 1l. Views with sql_variant CASE
SELECT * FROM babel_case_sqlvariant_v1
GO

SELECT * FROM babel_case_sqlvariant_v2
GO


-- 2. ISNULL: sql_variant in different arg positions


-- 2a. sql_variant as 1st arg (check_expression), non-NULL
SELECT ISNULL(CAST(1 AS sql_variant), CAST(0 AS bit)) AS result
GO

SELECT ISNULL(CAST(1 AS sql_variant), CAST(100 AS int)) AS result
GO

SELECT ISNULL(CAST('hello' AS sql_variant), CAST('world' AS varchar(50))) AS result
GO

SELECT ISNULL(CAST(3.14 AS sql_variant), CAST(2.71 AS float)) AS result
GO

SELECT ISNULL(CAST(100 AS sql_variant), CAST(200.50 AS numeric(10,2))) AS result
GO

-- 2b. NULL sql_variant as 1st arg
SELECT ISNULL(CAST(NULL AS sql_variant), CAST(0 AS bit)) AS result
GO

SELECT ISNULL(CAST(NULL AS sql_variant), CAST(100 AS int)) AS result
GO

SELECT ISNULL(CAST(NULL AS sql_variant), CAST('hello' AS varchar(50))) AS result
GO

-- 2c. sql_variant as 2nd arg (replacement_value), non-NULL 1st arg
SELECT ISNULL(CAST(0 AS bit), CAST(1 AS sql_variant)) AS result
GO

SELECT ISNULL(CAST(100 AS int), CAST(1 AS sql_variant)) AS result
GO

SELECT ISNULL(CAST('hello' AS varchar(50)), CAST('world' AS sql_variant)) AS result
GO

SELECT ISNULL(CAST(3.14 AS float), CAST(2.71 AS sql_variant)) AS result
GO

-- 2d. sql_variant as 2nd arg, 1st arg NULL
SELECT ISNULL(CAST(NULL AS bit), CAST(1 AS sql_variant)) AS result
GO

SELECT ISNULL(CAST(NULL AS int), CAST(1 AS sql_variant)) AS result
GO

-- 2e. NULL sql_variant as 2nd arg
SELECT ISNULL(CAST(0 AS bit), CAST(NULL AS sql_variant)) AS result
GO

SELECT ISNULL(CAST(100 AS int), CAST(NULL AS sql_variant)) AS result
GO

SELECT ISNULL(CAST('hello' AS varchar(50)), CAST(NULL AS sql_variant)) AS result
GO

-- 2f. Both args NULL sql_variant
SELECT ISNULL(CAST(NULL AS sql_variant), CAST(NULL AS sql_variant)) AS result
GO

-- 2g. NULL sql_variant as 1st arg, NULL other type as 2nd arg
SELECT ISNULL(CAST(NULL AS sql_variant), CAST(NULL AS bit)) AS result
GO

SELECT ISNULL(CAST(NULL AS sql_variant), CAST(NULL AS int)) AS result
GO

-- 2h. ISNULL with table column
SELECT ISNULL(sv_col, CAST(0 AS bit)) AS result FROM babel_case_sqlvariant_t1
GO

SELECT ISNULL(CAST(0 AS bit), sv_col) AS result FROM babel_case_sqlvariant_t1
GO


-- 3. COALESCE: sql_variant in different arg positions


-- 3a. sql_variant as 1st arg (non-NULL)
SELECT COALESCE(CAST(1 AS sql_variant), CAST(0 AS bit)) AS result
GO

SELECT COALESCE(CAST(1 AS sql_variant), CAST(100 AS int)) AS result
GO

SELECT COALESCE(CAST('hello' AS sql_variant), CAST('world' AS varchar(50))) AS result
GO

SELECT COALESCE(CAST(3.14 AS sql_variant), CAST(2.71 AS float)) AS result
GO

-- 3b. sql_variant as 2nd arg
SELECT COALESCE(CAST(0 AS bit), CAST(1 AS sql_variant)) AS result
GO

SELECT COALESCE(CAST(100 AS int), CAST(1 AS sql_variant)) AS result
GO

SELECT COALESCE(CAST('hello' AS varchar(50)), CAST('world' AS sql_variant)) AS result
GO

-- 3c. sql_variant as 3rd arg
SELECT COALESCE(CAST(0 AS bit), CAST(100 AS int), CAST(1 AS sql_variant)) AS result
GO

-- 3d. sql_variant as last arg in multi-arg COALESCE
SELECT COALESCE(CAST(0 AS bit), CAST(100 AS int), CAST('hello' AS varchar(50)), CAST(1 AS sql_variant)) AS result
GO

-- 3e. NULL non-sql_variant args, sql_variant last
SELECT COALESCE(CAST(NULL AS int), CAST(1 AS sql_variant)) AS result
GO

SELECT COALESCE(CAST(NULL AS bit), CAST(1 AS sql_variant)) AS result
GO

SELECT COALESCE(CAST(NULL AS int), CAST(NULL AS bit), CAST(1 AS sql_variant)) AS result
GO

-- 3f. NULL sql_variant as 1st arg (tests COALESCE NULL-skipping fix)
SELECT COALESCE(CAST(NULL AS sql_variant), CAST(0 AS bit)) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST(100 AS int)) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST('hello' AS varchar(50))) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST(3.14 AS float)) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST(NULL AS bit), CAST(100 AS int)) AS result
GO

-- 3g. NULL sql_variant in middle position
SELECT COALESCE(CAST(0 AS bit), CAST(NULL AS sql_variant), CAST(100 AS int)) AS result
GO

-- 3h. NULL sql_variant as last arg
SELECT COALESCE(CAST(0 AS bit), CAST(100 AS int), CAST(NULL AS sql_variant)) AS result
GO

-- 3i. All NULL sql_variant
SELECT COALESCE(CAST(NULL AS sql_variant), CAST(NULL AS sql_variant)) AS result
GO

-- 3j. NULL sql_variant with NULL other types
SELECT COALESCE(CAST(NULL AS sql_variant), CAST(NULL AS int), CAST(1 AS bit)) AS result
GO


-- 4. UNION ALL: sql_variant in different positions


-- 4a. sql_variant in 1st SELECT
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION ALL
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION ALL
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST('hello' AS sql_variant) AS col
UNION ALL
SELECT CAST('world' AS varchar(50)) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(3.14 AS sql_variant) AS col
UNION ALL
SELECT CAST(2.71 AS float) AS col
) t ORDER BY col
GO

-- 4b. sql_variant in 2nd SELECT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION ALL
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(100 AS int) AS col
UNION ALL
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST('world' AS varchar(50)) AS col
UNION ALL
SELECT CAST('hello' AS sql_variant) AS col
) t ORDER BY col
GO

-- 4c. sql_variant in 3rd SELECT (multi-UNION)
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION ALL
SELECT CAST(100 AS int) AS col
UNION ALL
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 4d. sql_variant in 1st, other types follow
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION ALL
SELECT CAST(0 AS bit) AS col
UNION ALL
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

-- 4e. NULL sql_variant in UNION ALL
SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
UNION ALL
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION ALL
SELECT CAST(NULL AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
UNION ALL
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
UNION ALL
SELECT CAST('hello' AS varchar(50)) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION ALL
SELECT CAST(100 AS int) AS col
UNION ALL
SELECT CAST(NULL AS sql_variant) AS col
) t ORDER BY col
GO


-- 5. UNION (distinct): sql_variant in different positions


-- 5a. sql_variant in 1st SELECT
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

-- 5b. sql_variant in 2nd SELECT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(100 AS int) AS col
UNION
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 5c. sql_variant in last of multi-UNION
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION
SELECT CAST(100 AS int) AS col
UNION
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 5d. NULL sql_variant in UNION
SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
UNION
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(0 AS bit) AS col
UNION
SELECT CAST(NULL AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
UNION
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO


-- 6. INTERSECT: sql_variant in different positions


-- 6a. sql_variant in 1st SELECT
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
INTERSECT
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
INTERSECT
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

-- 6b. sql_variant in 2nd SELECT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
INTERSECT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(100 AS int) AS col
INTERSECT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 6c. sql_variant in last of multi-INTERSECT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
INTERSECT
SELECT CAST(100 AS int) AS col
INTERSECT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 6d. NULL sql_variant in INTERSECT
SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
INTERSECT
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(0 AS bit) AS col
INTERSECT
SELECT CAST(NULL AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
INTERSECT
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO


-- 7. EXCEPT: sql_variant in different positions


-- 7a. sql_variant in 1st SELECT
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
EXCEPT
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
EXCEPT
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST('hello' AS sql_variant) AS col
EXCEPT
SELECT CAST('world' AS varchar(50)) AS col
) t ORDER BY col
GO

-- 7b. sql_variant in 2nd SELECT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
EXCEPT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(100 AS int) AS col
EXCEPT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 7c. sql_variant in last of multi-EXCEPT
SELECT col FROM (
SELECT CAST(0 AS bit) AS col
EXCEPT
SELECT CAST(100 AS int) AS col
EXCEPT
SELECT CAST(1 AS sql_variant) AS col
) t ORDER BY col
GO

-- 7d. NULL sql_variant in EXCEPT
SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
EXCEPT
SELECT CAST(0 AS bit) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(0 AS bit) AS col
EXCEPT
SELECT CAST(NULL AS sql_variant) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
EXCEPT
SELECT CAST(100 AS int) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(NULL AS sql_variant) AS col
EXCEPT
SELECT CAST('hello' AS varchar(50)) AS col
) t ORDER BY col
GO


-- 8. VALUES: sql_variant in different row positions


-- 8a. sql_variant in 1st row
SELECT * FROM (VALUES
  (CAST(1 AS sql_variant)),
  (CAST(0 AS bit))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(1 AS sql_variant)),
  (CAST(100 AS int))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST('hello' AS sql_variant)),
  (CAST('world' AS varchar(50)))
) AS t(col) ORDER BY col
GO

-- 8b. sql_variant in 2nd row
SELECT * FROM (VALUES
  (CAST(0 AS bit)),
  (CAST(1 AS sql_variant))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(100 AS int)),
  (CAST(1 AS sql_variant))
) AS t(col) ORDER BY col
GO

-- 8c. sql_variant in 3rd row
SELECT * FROM (VALUES
  (CAST(0 AS bit)),
  (CAST(100 AS int)),
  (CAST(1 AS sql_variant))
) AS t(col) ORDER BY col
GO

-- 8d. sql_variant in 1st row, multiple other types follow
SELECT * FROM (VALUES
  (CAST(1 AS sql_variant)),
  (CAST(0 AS bit)),
  (CAST(100 AS int)),
  (CAST('hello' AS varchar(50)))
) AS t(col) ORDER BY col
GO

-- 8e. sql_variant in last row
SELECT * FROM (VALUES
  (CAST(0 AS bit)),
  (CAST(100 AS int)),
  (CAST('hello' AS varchar(50))),
  (CAST(1 AS sql_variant))
) AS t(col) ORDER BY col
GO

-- 8f. NULL sql_variant in VALUES
SELECT * FROM (VALUES
  (CAST(NULL AS sql_variant)),
  (CAST(0 AS bit))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(0 AS bit)),
  (CAST(NULL AS sql_variant))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(NULL AS sql_variant)),
  (CAST(100 AS int))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(NULL AS sql_variant)),
  (CAST('hello' AS varchar(50)))
) AS t(col) ORDER BY col
GO

SELECT * FROM (VALUES
  (CAST(0 AS bit)),
  (CAST(100 AS int)),
  (CAST(NULL AS sql_variant))
) AS t(col) ORDER BY col
GO


-- 9. Char-only CASE: verify char type precedence is unaffected


SELECT CASE WHEN 1 = 1 THEN CAST('abc' AS varchar(10)) ELSE CAST('def' AS nvarchar(10)) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST('abc' AS char(10)) ELSE CAST('def' AS nchar(10)) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST('abc' AS varchar(10)) ELSE CAST('def' AS text) END AS result
GO


-- 10. Matching types: same-type branches resolve correctly


SELECT CASE WHEN 1 = 1 THEN CAST(1 AS int) ELSE CAST(2 AS int) END AS result
GO

SELECT CAST('abc' AS varchar(10)) AS col UNION ALL SELECT CAST('def' AS varchar(10)) AS col ORDER BY col
GO


-- 11. UNION with char types: char type precedence is unaffected


SELECT col FROM (
SELECT CAST('abc' AS varchar(10)) AS col
UNION ALL
SELECT CAST('def' AS nvarchar(10)) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST('abc' AS char(10)) AS col
UNION ALL
SELECT CAST('def' AS nchar(10)) AS col
) t ORDER BY col
GO


-- 12. Incompatible types: should still error


SELECT CASE WHEN 1 = 1 THEN CAST('2025-01-01' AS date) ELSE CAST(100 AS numeric(10,2)) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST('12:00:00' AS time) ELSE CAST(100 AS numeric(10,2)) END AS result
GO


-- 13. sql_variant against additional data types


-- 13a. sql_variant with date/time types
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST('2025-01-01' AS date) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST('2025-01-01 12:00:00' AS datetime) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST('12:30:00' AS time) END AS result
GO

-- 13b. sql_variant with money types
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(100.00 AS money) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(50.00 AS smallmoney) END AS result
GO

-- 13c. sql_variant with integer subtypes
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(100 AS bigint) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(10 AS smallint) END AS result
GO

SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST(5 AS tinyint) END AS result
GO

-- 13d. sql_variant with uniqueidentifier
SELECT CASE WHEN 1 = 1 THEN CAST(1 AS sql_variant) ELSE CAST('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS uniqueidentifier) END AS result
GO

-- 13e. COALESCE with additional data types
SELECT COALESCE(CAST(NULL AS sql_variant), CAST('2025-01-01' AS date)) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST(100.00 AS money)) AS result
GO

SELECT COALESCE(CAST(NULL AS sql_variant), CAST(100 AS bigint)) AS result
GO

-- 13f. UNION with additional data types
SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION ALL
SELECT CAST(100.00 AS money) AS col
) t ORDER BY col
GO

SELECT col FROM (
SELECT CAST(1 AS sql_variant) AS col
UNION ALL
SELECT CAST('2025-01-01' AS date) AS col
) t ORDER BY col
GO


-- 14. Other system functions returning sql_variant


SELECT CASE WHEN 1 = 1 THEN SESSIONPROPERTY('ANSI_NULLS') ELSE CAST(0 AS int) END AS result
GO

SELECT COALESCE(SERVERPROPERTY('Edition'), CAST('unknown' AS varchar(50))) AS result
GO
